/// Ronda 5A.2, correcciones de QA y seguridad: envío detenido tras errores
/// seguidos del servidor (Reintentar o Cancelar envío), `submit()` que nunca
/// deja el tablero esperando, `solve()` local prohibido para casos de
/// servidor y partidas guardadas sin registro de inicio.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/backend/validation_service.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart';
import 'support/l10n.dart';

late PuzzleCase pc;

PendingSubmission _pending({String id = 'sub-detenido-01'}) =>
    PendingSubmission(
      caseId: pc.caseId,
      submissionId: id,
      positions: Map.of(pc.solution.positions),
      clientElapsedMs: 5000,
      startedOnline: true,
      elapsedSeconds: 5,
      errorCount: 0,
      createdAt: DateTime.utc(2026, 11, 7, 10),
    );

ValidationService _service(FakeValidationClient client, {int limit = 3}) {
  final s = ValidationService(
    client: client,
    retryEvery: const Duration(minutes: 10),
    serverErrorRetryLimit: limit,
  );
  addTearDown(s.dispose);
  return s;
}

ProviderContainer _container(FakeValidationClient client) {
  final c = ProviderContainer(
    overrides: [
      gameTickerEnabledProvider.overrideWithValue(false),
      backendModeProvider.overrideWithValue(BackendMode.emulator),
      validationClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<GameController> _open(ProviderContainer c) async {
  c.listen(gameControllerProvider(pc), (_, _) {});
  final controller = c.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  return controller;
}

void _place(GameController c) {
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => pc = loadBankCase('mansion-01'));

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeValidationClient()..add(pc);
  });

  group('errores seguidos del servidor', () {
    test('se reintenta hasta el tope y luego el envío se detiene', () async {
      client.submitFailure = ValidationFailure.serverError;
      final service = _service(client);
      expect(await service.submit(_pending()), isA<OutcomeQueued>());
      expect(service.isStalled(pc.caseId), isFalse);

      await service.flush(); // 2.º error seguido
      expect(service.isStalled(pc.caseId), isFalse);
      final events = <ValidationEvent>[];
      service.events.listen(events.add);
      await service.flush(); // 3.º: tope
      await Future<void>.delayed(Duration.zero);

      expect(service.isStalled(pc.caseId), isTrue);
      expect(events.single.kind, ValidationEventKind.stalled);
      expect(client.submits, hasLength(3));

      // Detenido: ya no se reintenta solo.
      await service.flush();
      await service.flush();
      expect(client.submits, hasLength(3));
      // Y sigue en la cola, guardado.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPendingKey), contains('"stalled":true'));
    });

    test('el tope sale de la configuración', () async {
      client.submitFailure = ValidationFailure.serverError;
      final service = _service(client, limit: 1);
      expect(await service.submit(_pending()), isA<OutcomeStalled>());
    });

    test('la falta de señal en medio corta la racha', () async {
      client.submitFailure = ValidationFailure.serverError;
      final service = _service(client);
      await service.submit(_pending());
      await service.flush();
      client.submitFailure = null;
      client.online = false;
      await service.flush(); // sin señal: la racha vuelve a cero
      client.online = true;
      client.submitFailure = ValidationFailure.serverError;
      await service.flush();
      await service.flush();
      expect(service.isStalled(pc.caseId), isFalse);
      await service.flush();
      expect(service.isStalled(pc.caseId), isTrue);
    });

    test(
      'unauthenticated, permission-denied y failed-precondition: de una vez',
      () async {
        client.submitFailure = ValidationFailure.blocked;
        final service = _service(client);
        expect(await service.submit(_pending()), isA<OutcomeStalled>());
        expect(service.isStalled(pc.caseId), isTrue);
        expect(client.submits, hasLength(1));
      },
    );

    test(
      'Reintentar usa el mismo submissionId y la respuesta llega por events',
      () async {
        client.submitFailure = ValidationFailure.blocked;
        final service = _service(client);
        await service.submit(_pending(id: 'sub-reintento-9'));
        final events = <ValidationEvent>[];
        service.events.listen(events.add);

        client.submitFailure = null;
        await service.retryStalled(pc.caseId);
        await Future<void>.delayed(Duration.zero);

        expect(client.submits.last.submissionId, 'sub-reintento-9');
        expect(events.single.kind, ValidationEventKind.solved);
        expect(service.pendingCaseIds, isEmpty);
      },
    );

    test('Cancelar quita el envío de la cola, también del disco', () async {
      client.submitFailure = ValidationFailure.blocked;
      final service = _service(client);
      await service.submit(_pending());
      await service.cancel(pc.caseId);
      expect(service.pendingCaseIds, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(kPendingKey), isFalse);
    });

    test('el envío detenido sobrevive a reiniciar y sigue detenido', () async {
      client.submitFailure = ValidationFailure.blocked;
      final first = _service(client);
      await first.submit(_pending());
      final raw = (await SharedPreferences.getInstance()).getString(
        kPendingKey,
      )!;
      first.dispose();
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({kPendingKey: raw});
      client.submitFailure = null;
      final second = _service(client);
      await second.start();
      expect(second.isStalled(pc.caseId), isTrue);
      expect(client.submits, hasLength(1)); // no se reintentó solo
    });
  });

  group('submit() nunca deja el tablero esperando', () {
    test(
      'si el almacenamiento falla devuelve la cola y libera el envío',
      () async {
        final service = ValidationService(
          client: client,
          loadPrefs: () => Future<SharedPreferences>.error(StateError('disco')),
        );
        addTearDown(service.dispose);
        final out = await service.submit(_pending());
        expect(out, isA<OutcomeQueued>());
      },
    );
  });

  group('controlador con envío detenido', () {
    test('queda en pausa esperando la decisión y se puede cancelar', () async {
      client.submitFailure = ValidationFailure.blocked;
      final c = _container(client);
      final ctl = await _open(c);
      _place(ctl);
      expect(await ctl.solveOnline(), ActionFeedback.pendingValidation);
      var s = c.read(gameControllerProvider(pc));
      expect(s.pendingValidation, isTrue);
      expect(s.validationStalled, isTrue);

      await ctl.cancelValidation();
      s = c.read(gameControllerProvider(pc));
      expect(s.pendingValidation, isFalse);
      expect(s.validationStalled, isFalse);
      expect(s.submitting, isFalse);
      expect(c.read(validationServiceProvider)!.pendingCaseIds, isEmpty);
      // Tablero otra vez editable.
      final cell = pc.solution.positions.values.first;
      ctl.eraseCell(cell);
      expect(
        c.read(gameControllerProvider(pc)).board.cell(cell).confirmed,
        isNull,
      );
    });

    test('Reintentar sin el fallo resuelve el caso', () async {
      client.submitFailure = ValidationFailure.blocked;
      final c = _container(client);
      final ctl = await _open(c);
      _place(ctl);
      await ctl.solveOnline();
      client.submitFailure = null;
      ctl.retryValidation();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final s = c.read(gameControllerProvider(pc));
      expect(s.solved, isTrue);
      expect(s.validationStalled, isFalse);
    });
  });

  group('solve() local no valida casos de servidor (B1)', () {
    test('no hace nada aunque el tablero esté bien', () async {
      final c = _container(client);
      final ctl = await _open(c);
      _place(ctl);
      ActionFeedback? fb;
      try {
        fb = ctl.solve();
      } on AssertionError {
        fb = null; // en debug el assert avisa del uso indebido
      }
      expect(fb, anyOf(isNull, ActionFeedback.ok));
      final s = c.read(gameControllerProvider(pc));
      expect(s.solved, isFalse);
      expect(s.errorCount, 0);
      expect(client.submits, isEmpty);
    });
  });

  group('partida guardada sin registro de inicio (B2)', () {
    Map<String, Object> saved(int elapsed) => {
      SavedGame.keyFor(pc.caseId): SavedGame(
        elapsed: elapsed,
        errors: 0,
        savedAt: DateTime.utc(2026, 11, 6, 9),
        board: BoardState.empty(),
        clueMarks: List.filled(pc.clues.length, 0),
        autoX: true,
        mapMode: true,
      ).encode(),
    };

    test(
      'con tiempo jugado: se guarda "sin conexión" y no llama a startCase',
      () async {
        SharedPreferences.setMockInitialValues(saved(120));
        final c = _container(client);
        await _open(c);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('started:${pc.caseId}'), '0');
        expect(client.starts, isEmpty);
      },
    );

    test('con registro de inicio previo se respeta', () async {
      SharedPreferences.setMockInitialValues({
        ...saved(120),
        'started:${pc.caseId}': '1',
      });
      final c = _container(client);
      await _open(c);
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('started:${pc.caseId}'), '1');
      expect(client.starts, isEmpty);
    });

    test('una partida nueva (sin tiempo) sí avisa a startCase', () async {
      final c = _container(client);
      await _open(c);
      await Future<void>.delayed(Duration.zero);
      expect(client.starts, [pc.caseId]);
    });
  });

  testWidgets('pantalla: envío detenido ofrece Reintentar y Cancelar envío', (
    tester,
  ) async {
    client.submitFailure = ValidationFailure.blocked;
    final rig = await pumpGameScreen(
      tester,
      pc,
      extraOverrides: [
        backendModeProvider.overrideWithValue(BackendMode.emulator),
        validationClientProvider.overrideWithValue(client),
        campaignProvider.overrideWith((ref, _) async => [pc]),
        dailyChallengesProvider.overrideWith((_) async => const []),
      ],
    );
    final ctl = rig.container.read(gameControllerProvider(pc).notifier);
    _place(ctl);
    await settle(tester, 2);

    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 6);

    expect(find.text(l10nEs.validationStalledBody), findsOneWidget);
    expect(find.byKey(const ValueKey('envio-reintentar')), findsOneWidget);
    expect(find.byKey(const ValueKey('envio-cancelar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('envio-cancelar')));
    await settle(tester, 6);

    final s = rig.container.read(gameControllerProvider(pc));
    expect(s.pendingValidation, isFalse);
    expect(s.validationStalled, isFalse);
    expect(find.text(l10nEs.validationStalledTitle), findsNothing);
    rig.container.read(validationServiceProvider)!.dispose();
    await tester.pump(const Duration(seconds: 3));
  });
}
