/// Resolver con el servidor (etapa 5A.2): el controlador de la partida usa la
/// capa de validación en la campaña y el reto, y valida en el teléfono el
/// tutorial, el banco `caso-*` y todo el modo `none`. Sin red, con un servidor
/// falso.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/firebase_validation_client.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;
import 'support/l10n.dart';

late PuzzleCase campaign; // mansion-01: va al servidor
late PuzzleCase bank; // caso-principiante-s1: valida en el teléfono
late PuzzleCase tutorial; // el tutorial: valida en el teléfono

PuzzleCase _loadTutorial() => PuzzleCase.fromJson(
  (jsonDecode(File(kTutorialAsset).readAsStringSync().replaceFirst('﻿', ''))
          as Map)
      .cast<String, dynamic>(),
);

/// Contenedor con el reloj apagado. [mode] y [client] son la bandera de
/// compilación y el servidor.
ProviderContainer _container(
  FakeValidationClient? client, {
  BackendMode mode = BackendMode.emulator,
}) {
  final c = ProviderContainer(
    overrides: [
      gameTickerEnabledProvider.overrideWithValue(false),
      backendModeProvider.overrideWithValue(mode),
      validationClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

final Map<PuzzleCase, ProviderSubscription<GameState>> _open_ = {};

/// El jugador sale de la partida: se suelta el controlador (autoDispose).
Future<void> _leave(PuzzleCase pc) async {
  _open_.remove(pc)?.close();
  await _settle();
}

Future<GameController> _open(ProviderContainer c, PuzzleCase pc) async {
  _open_[pc] = c.listen(gameControllerProvider(pc), (_, _) {});
  final controller = c.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  return controller;
}

void _placeSolution(GameController c, PuzzleCase pc) {
  for (final e in pc.solution.positions.entries) {
    expect(
      c.placeSuspect(e.value, charId: e.key, confirm: true),
      ActionFeedback.ok,
    );
  }
}

/// Todos confirmados, con los dos primeros intercambiados (2 mal).
void _placeSwapped(GameController c, PuzzleCase pc) {
  final entries = pc.solution.positions.entries.toList();
  final a = entries[0], b = entries[1];
  c.toggleAutoX();
  c.placeSuspect(b.value, charId: a.key, confirm: true);
  c.placeSuspect(a.value, charId: b.key, confirm: true);
  for (final e in entries.skip(2)) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    campaign = loadBankCase('mansion-01');
    bank = loadBankCase('caso-principiante-s1');
    tutorial = _loadTutorial();
  });

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeValidationClient()..add(campaign);
  });

  group('banderas', () {
    test('sin bandera el modo es none', () {
      expect(kEnxBackendRaw, 'none');
      expect(parseBackendMode(kEnxBackendRaw), BackendMode.none);
      expect(ProviderContainer().read(backendModeProvider), BackendMode.none);
    });

    test('se leen los tres modos y lo desconocido cae en none', () {
      expect(parseBackendMode('none'), BackendMode.none);
      expect(parseBackendMode('emulator'), BackendMode.emulator);
      expect(parseBackendMode(' Firebase '), BackendMode.firebase);
      expect(parseBackendMode(''), BackendMode.none);
      expect(parseBackendMode('prod'), BackendMode.none);
    });

    test('host del emulador: el pedido, o el de cada plataforma', () {
      expect(resolveEmulatorHost(requested: '192.168.1.5'), '192.168.1.5');
      expect(resolveEmulatorHost(requested: '', isWeb: true), 'localhost');
      expect(
        resolveEmulatorHost(
          requested: '',
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        '10.0.2.2',
      );
      expect(
        resolveEmulatorHost(
          requested: '',
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        'localhost',
      );
    });

    test('en release el emulador se comporta como none (M3)', () {
      expect(
        effectiveBackendMode(BackendMode.emulator, releaseMode: true),
        BackendMode.none,
      );
      expect(
        effectiveBackendMode(BackendMode.emulator, releaseMode: false),
        BackendMode.emulator,
      );
      expect(
        effectiveBackendMode(BackendMode.none, releaseMode: true),
        BackendMode.none,
      );
      expect(
        effectiveBackendMode(BackendMode.firebase, releaseMode: true),
        BackendMode.firebase,
      );
      expect(
        effectiveBackendMode(BackendMode.firebase, releaseMode: false),
        BackendMode.firebase,
      );
    });

    test('solo la campaña y el reto van al servidor', () {
      expect(isServerCaseId('mansion-01'), isTrue);
      expect(isServerCaseId('reto-017'), isTrue);
      expect(isServerCaseId('caso-casual-s4'), isFalse);
      expect(isServerCaseId(kTutorialCaseId), isFalse);
    });

    test('los códigos del servidor se traducen al tipo de fallo', () {
      expect(
        failureForFunctionsCode('resource-exhausted'),
        ValidationFailure.rateLimited,
      );
      expect(
        failureForFunctionsCode('invalid-argument'),
        ValidationFailure.rejected,
      );
      expect(failureForFunctionsCode('not-found'), ValidationFailure.rejected);
      for (final code in ['unavailable', 'deadline-exceeded']) {
        expect(failureForFunctionsCode(code), ValidationFailure.network);
      }
      // Lo que pasa si falta App Check: el envío se detiene de una vez.
      for (final code in [
        'unauthenticated',
        'permission-denied',
        'failed-precondition',
      ]) {
        expect(failureForFunctionsCode(code), ValidationFailure.blocked);
      }
      // El servidor respondió con un error: se reintenta unas pocas veces.
      for (final code in ['internal', 'unknown', 'aborted', 'data-loss']) {
        expect(failureForFunctionsCode(code), ValidationFailure.serverError);
      }
    });

    test(
      'la respuesta del servidor se lee, y una mal formada se reintenta',
      () {
        final solved = parseSubmitResponse({
          'result': 'solved',
          'murdererId': 'ana',
          'lethalWeaponId': null,
          'ranked': true,
        });
        expect((solved as SubmitSolved).murdererId, 'ana');
        expect(solved.lethalWeaponId, isNull);
        expect(
          (parseSubmitResponse({'result': 'wrong', 'wrongCount': 3})
                  as SubmitWrong)
              .wrongCount,
          3,
        );
        for (final bad in [
          null,
          'x',
          {'result': 'solved'},
          {'result': 'wrong'},
        ]) {
          expect(
            () => parseSubmitResponse(bad),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.kind,
                'kind',
                ValidationFailure.serverError,
              ),
            ),
          );
        }
      },
    );
  });

  group('modo none: igual que hoy', () {
    test('no hay servicio ni se usa la red aunque haya un cliente', () async {
      final c = _container(client, mode: BackendMode.none);
      expect(c.read(validationServiceProvider), isNull);
      final controller = await _open(c, campaign);
      expect(controller.usesServer, isFalse);
      _placeSolution(controller, campaign);
      expect(controller.solve(), ActionFeedback.solvedOk);
      expect(client.starts, isEmpty);
      expect(client.submits, isEmpty);
      expect(client.sessions, 0);
    });

    test(
      'Firebase no arranca: no hay cliente y no se toca la plataforma',
      () async {
        // Si tocara Firebase, el canal de la plataforma fallaría en esta prueba.
        final client = await bootstrapBackend(
          BackendMode.none,
          timeout: const Duration(seconds: 1),
        );
        expect(client, isNull);
      },
    );

    test('Resolver incorrecto cuenta con la solución local', () async {
      final c = _container(null, mode: BackendMode.none);
      final controller = await _open(c, campaign);
      _placeSwapped(controller, campaign);
      expect(await controller.solveOnline(), ActionFeedback.wrongSolution);
      final s = c.read(gameControllerProvider(campaign));
      expect(s.errorCount, 1);
      expect(s.wrongCount, 2);
      expect(s.locked, isTrue);
    });
  });

  group('el tutorial y el banco validan en el teléfono', () {
    test('banco caso-*: no llama al servidor', () async {
      final c = _container(client);
      final controller = await _open(c, bank);
      expect(controller.usesServer, isFalse);
      _placeSolution(controller, bank);
      expect(await controller.solveOnline(), ActionFeedback.solvedOk);
      expect(c.read(gameControllerProvider(bank)).solved, isTrue);
      expect(client.starts, isEmpty);
      expect(client.submits, isEmpty);
    });

    test('tutorial: no llama al servidor', () async {
      final c = _container(client);
      final controller = await _open(c, tutorial);
      expect(controller.usesServer, isFalse);
      _placeSwapped(controller, tutorial);
      expect(await controller.solveOnline(), ActionFeedback.wrongSolution);
      expect(client.starts, isEmpty);
      expect(client.submits, isEmpty);
    });
  });

  group('campaña y reto con el servidor', () {
    test('al abrir el caso avisa startCase sin frenar la partida', () async {
      final c = _container(client);
      final controller = await _open(c, campaign);
      expect(controller.usesServer, isTrue);
      await _settle();
      expect(client.starts, [campaign.caseId]);
      expect(c.read(gameControllerProvider(campaign)).loading, isFalse);
    });

    test('si startCase falla la partida sigue', () async {
      client.online = false;
      final c = _container(client);
      final controller = await _open(c, campaign);
      await _settle();
      expect(c.read(gameControllerProvider(campaign)).loading, isFalse);
      controller.tick();
      expect(c.read(gameControllerProvider(campaign)).elapsedSeconds, 1);
    });

    test('correcto: la victoria la decide el servidor', () async {
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSolution(controller, campaign);
      controller.tick();
      controller.tick();
      expect(await controller.solveOnline(), ActionFeedback.solvedOk);
      final s = c.read(gameControllerProvider(campaign));
      expect(s.solved, isTrue);
      expect(s.murdererId, isNotNull);
      expect(client.submits, hasLength(1));
      final sent = client.submits.single;
      expect(sent.caseId, campaign.caseId);
      expect(sent.startedOnline, isTrue);
      expect(sent.clientElapsedMs, 2000);
      expect(sent.positions, campaign.solution.positions);
      expect(sent.submissionId.length, inInclusiveRange(8, 64));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(sent.submissionId), isTrue);
    });

    test(
      'incorrecto: el conteo lo da el servidor y el tablero se bloquea',
      () async {
        final c = _container(client);
        final controller = await _open(c, campaign);
        _placeSwapped(controller, campaign);
        expect(await controller.solveOnline(), ActionFeedback.wrongSolution);
        final s = c.read(gameControllerProvider(campaign));
        expect(s.solved, isFalse);
        expect(s.errorCount, 1);
        expect(s.wrongCount, 2);
        expect(s.locked, isTrue);
        expect(s.errorCells, isEmpty); // no dice cuáles
        expect(s.pendingValidation, isFalse);
      },
    );

    test('tablero incompleto: ni siquiera se envía', () async {
      final c = _container(client);
      final controller = await _open(c, campaign);
      final first = campaign.solution.positions.entries.first;
      controller.placeSuspect(first.value, charId: first.key, confirm: true);
      expect(await controller.solveOnline(), ActionFeedback.incompleteBoard);
      expect(client.submits, isEmpty);
    });

    test('demasiados intentos: avisa y el tablero queda libre', () async {
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSolution(controller, campaign);
      client.rateLimited = true;
      expect(await controller.solveOnline(), ActionFeedback.rateLimited);
      final s = c.read(gameControllerProvider(campaign));
      expect(s.pendingValidation, isFalse);
      expect(s.submitting, isFalse);
      expect(s.errorCount, 0);
      client.rateLimited = false;
      expect(await controller.solveOnline(), ActionFeedback.solvedOk);
    });

    test('sin red: queda "por validar" y el tablero no se toca', () async {
      client.online = false;
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSolution(controller, campaign);
      expect(await controller.solveOnline(), ActionFeedback.pendingValidation);
      final s = c.read(gameControllerProvider(campaign));
      expect(s.pendingValidation, isTrue);
      expect(s.solved, isFalse);
      expect(s.errorCount, 0);
      // La partida no empezó con conexión: no entra al ranking.
      expect(client.submits.single.startedOnline, isFalse);
      await _settle();
      expect(c.read(pendingCaseIdsProvider), {campaign.caseId});

      // Mientras espera, el tablero no cambia y el reloj no corre.
      final before = s.board;
      controller.eraseCell(campaign.solution.positions.values.first);
      controller.tick();
      final after = c.read(gameControllerProvider(campaign));
      expect(identical(after.board, before), isTrue);
      expect(after.elapsedSeconds, 0);
    });

    test('la respuesta llega con la partida abierta: victoria', () async {
      client.online = false;
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSolution(controller, campaign);
      await controller.solveOnline();

      client.online = true;
      await c.read(validationServiceProvider)!.flush();
      await _settle();

      final s = c.read(gameControllerProvider(campaign));
      expect(s.pendingValidation, isFalse);
      expect(s.solved, isTrue);
      expect(s.murdererId, isNotNull);
      expect(c.read(pendingCaseIdsProvider), isEmpty);
      // El reintento usó el mismo submissionId.
      expect(client.submits.map((r) => r.submissionId).toSet(), hasLength(1));
    });

    test('la respuesta llega con la partida abierta: no cuadra', () async {
      client.online = false;
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSwapped(controller, campaign);
      await controller.solveOnline();

      client.online = true;
      await c.read(validationServiceProvider)!.flush();
      await _settle();

      final s = c.read(gameControllerProvider(campaign));
      expect(s.pendingValidation, isFalse);
      expect(s.solved, isFalse);
      expect(s.errorCount, 1);
      expect(s.wrongCount, 2);
      expect(s.locked, isTrue);
    });

    test(
      'la respuesta llega con la partida cerrada: queda resuelto en el progreso',
      () async {
        client.online = false;
        final c = _container(client);
        final controller = await _open(c, campaign);
        _placeSolution(controller, campaign);
        controller.tick();
        await controller.solveOnline();
        await controller.saveNow();

        // El jugador sale de la partida.
        await _leave(campaign);

        client.online = true;
        await c.read(validationServiceProvider)!.flush();
        await _settle();

        final prefs = await SharedPreferences.getInstance();
        final done =
            jsonDecode(prefs.getString('done:${campaign.caseId}')!) as Map;
        expect(done['time'], 1);
        expect(done['errors'], 0);
        expect(prefs.containsKey(SavedGame.keyFor(campaign.caseId)), isFalse);
        expect(c.read(pendingCaseIdsProvider), isEmpty);
      },
    );

    test('al volver a abrir un caso por validar sigue por validar', () async {
      client.online = false;
      final c = _container(client);
      final controller = await _open(c, campaign);
      _placeSolution(controller, campaign);
      await controller.solveOnline();
      await controller.saveNow();
      await _leave(campaign);

      final reopened = await _open(c, campaign);
      await reopened.ready;
      final s = c.read(gameControllerProvider(campaign));
      expect(s.pendingValidation, isTrue);
      expect(s.board.confirmedCells, isNotEmpty); // el tablero que se envió
    });
  });

  group('marca "Por validar" en la lista de casos', () {
    testWidgets('el caso con el envío esperando lleva la marca', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final world = [
        for (var i = 1; i <= 10; i++)
          loadBankCase('mansion-${i.toString().padLeft(2, '0')}'),
      ];
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const CaseListScreen())],
      );
      final container = ProviderContainer(overrides: contentOverrides(world));
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: kL10nDelegates,
            supportedLocales: kL10nLocales,
            locale: kL10nLocale,
            routerConfig: router,
            theme: SkinUi.theme('ilustrada', Brightness.light),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Por validar'), findsNothing);

      container.read(pendingCaseIdsProvider.notifier).state = {
        world.first.caseId,
      };
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Por validar'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });
  });
}
