/// Cola de envíos "por validar" (ADR-0016): correcto, incorrecto, sin red,
/// reintento con el mismo submissionId y cola que sobrevive a reiniciar. Todo
/// con un servidor falso, sin red.
library;

import 'dart:convert';

import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_service.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

late PuzzleCase pc;

/// Tablero correcto del caso.
Map<String, int> _right() => Map.of(pc.solution.positions);

/// Tablero con los dos primeros personajes intercambiados (2 mal).
Map<String, int> _swapped() {
  final m = _right();
  final keys = m.keys.toList();
  final a = keys[0], b = keys[1];
  final t = m[a]!;
  m[a] = m[b]!;
  m[b] = t;
  return m;
}

PendingSubmission _pending(
  Map<String, int> positions, {
  String id = 'sub-prueba-0001',
  bool startedOnline = true,
  int errors = 1,
  int seconds = 95,
}) => PendingSubmission(
  caseId: pc.caseId,
  submissionId: id,
  positions: positions,
  clientElapsedMs: seconds * 1000,
  startedOnline: startedOnline,
  elapsedSeconds: seconds,
  errorCount: errors,
  createdAt: DateTime.utc(2026, 11, 7, 10),
);

ValidationService _service(
  FakeValidationClient client, {
  Duration retry = const Duration(minutes: 10),
  void Function(Set<String>)? onPending,
}) {
  final s = ValidationService(
    client: client,
    retryEvery: retry,
    onPendingChanged: onPending,
    clock: () => DateTime.utc(2026, 11, 7, 12, 30),
  );
  addTearDown(s.dispose);
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => pc = loadBankCase('mansion-01'));

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeValidationClient()..add(pc);
  });

  group('respuestas directas', () {
    test('tablero correcto: victoria con el asesino del servidor', () async {
      final service = _service(client);
      final out = await service.submit(_pending(_right()));
      expect(out, isA<OutcomeSolved>());
      final r = (out as OutcomeSolved).response;
      expect(r.murdererId, isNotEmpty);
      expect(r.ranked, isTrue);
      expect(service.pendingCaseIds, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(kPendingKey), isFalse);
    });

    test('tablero incorrecto: cuántos no cuadran, y nada en la cola', () async {
      final service = _service(client);
      final out = await service.submit(_pending(_swapped()));
      expect(out, isA<OutcomeWrong>());
      expect((out as OutcomeWrong).response.wrongCount, 2);
      expect(service.pendingCaseIds, isEmpty);
    });

    test('el envío no lleva la solución, solo el tablero', () async {
      final service = _service(client);
      await service.submit(_pending(_swapped()));
      // Lo único que sale del servidor es un conteo.
      final req = client.submits.single.toCallData();
      expect(req.keys, contains('submissionId'));
      expect(jsonEncode(req), isNot(contains('solution')));
    });

    test('sin red: el envío queda en la cola y "por validar"', () async {
      client.online = false;
      final seen = <Set<String>>[];
      final service = _service(client, onPending: seen.add);
      final out = await service.submit(_pending(_right()));
      expect(out, isA<OutcomeQueued>());
      expect(service.pendingCaseIds, {pc.caseId});
      expect(service.isPending(pc.caseId), isTrue);
      expect(seen.last, {pc.caseId});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPendingKey), contains('sub-prueba-0001'));
    });

    test(
      'un segundo Resolver con el primero pendiente no envía otro',
      () async {
        client.online = false;
        final service = _service(client);
        await service.submit(_pending(_right()));
        final out = await service.submit(
          _pending(_right(), id: 'sub-otro-0002'),
        );
        expect(out, isA<OutcomeQueued>());
        expect(client.submits, hasLength(1));
      },
    );

    test('demasiados intentos: no queda en la cola', () async {
      client.rateLimited = true;
      final service = _service(client);
      final out = await service.submit(_pending(_right()));
      expect(out, isA<OutcomeRateLimited>());
      expect(service.pendingCaseIds, isEmpty);
    });

    test('envío rechazado: se descarta', () async {
      client.rejects = true;
      final service = _service(client);
      final out = await service.submit(_pending(_right()));
      expect(out, isA<OutcomeRejected>());
      expect(service.pendingCaseIds, isEmpty);
    });
  });

  group('reintentos de la cola', () {
    test('al volver la señal reintenta con el MISMO submissionId', () async {
      client.online = false;
      final service = _service(client);
      await service.submit(_pending(_right(), id: 'sub-mismo-id-01'));
      final events = <ValidationEvent>[];
      service.events.listen(events.add);

      client.online = true;
      await service.flush();
      await Future<void>.delayed(Duration.zero);

      expect(client.submits.map((r) => r.submissionId).toSet(), {
        'sub-mismo-id-01',
      });
      expect(client.submits, hasLength(2));
      expect(events, hasLength(1));
      expect(events.single.kind, ValidationEventKind.solved);
      expect(service.pendingCaseIds, isEmpty);
    });

    test(
      'respuesta tardía "resuelto": queda resuelto en el progreso',
      () async {
        client.online = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          SavedGame.keyFor(pc.caseId),
          SavedGame(
            elapsed: 90,
            errors: 1,
            savedAt: DateTime.utc(2026, 11, 7, 9),
            board: BoardState.empty(),
            clueMarks: List.filled(pc.clues.length, 0),
            autoX: true,
            mapMode: true,
          ).encode(),
        );
        final service = _service(client);
        await service.submit(_pending(_right(), seconds: 95, errors: 1));

        client.online = true;
        await service.flush();

        final done = jsonDecode(prefs.getString('done:${pc.caseId}')!) as Map;
        expect(done['time'], 95);
        expect(done['errors'], 1);
        expect(done['date'], '2026-11-07T12:30');
        expect(prefs.containsKey(SavedGame.keyFor(pc.caseId)), isFalse);
        expect(prefs.containsKey(kPendingKey), isFalse);
      },
    );

    test('respuesta tardía "incorrecto": suma el error a la partida', () async {
      client.online = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SavedGame.keyFor(pc.caseId),
        SavedGame(
          elapsed: 90,
          errors: 1,
          savedAt: DateTime.utc(2026, 11, 7, 9),
          board: BoardState.empty(),
          clueMarks: List.filled(pc.clues.length, 0),
          autoX: true,
          mapMode: true,
        ).encode(),
      );
      final service = _service(client);
      await service.submit(_pending(_swapped()));
      final events = <ValidationEvent>[];
      service.events.listen(events.add);

      client.online = true;
      await service.flush();
      await Future<void>.delayed(Duration.zero);

      expect(events.single.kind, ValidationEventKind.wrong);
      expect((events.single.response as SubmitWrong).wrongCount, 2);
      final saved = SavedGame.read(prefs, pc.caseId)!;
      expect(saved.errors, 2);
      expect(prefs.containsKey('done:${pc.caseId}'), isFalse);
      expect(service.pendingCaseIds, isEmpty);
    });

    test('sin señal el reintento deja todo igual', () async {
      client.online = false;
      final service = _service(client);
      await service.submit(_pending(_right()));
      await service.flush();
      expect(service.pendingCaseIds, {pc.caseId});
      expect(client.submits, hasLength(2));
    });

    test('limitado en la cola: se conserva para más tarde', () async {
      client.online = false;
      final service = _service(client);
      await service.submit(_pending(_right()));
      client.online = true;
      client.rateLimited = true;
      await service.flush();
      expect(service.pendingCaseIds, {pc.caseId});
      client.rateLimited = false;
      await service.flush();
      expect(service.pendingCaseIds, isEmpty);
    });

    test('al volver a la app se reintenta', () async {
      client.online = false;
      final service = _service(client);
      await service.submit(_pending(_right()));
      client.online = true;
      final solved = service.events.first;
      service.onResumed();
      expect((await solved).kind, ValidationEventKind.solved);
    });

    test('periódico: reintenta solo mientras hay cola', () async {
      client.online = false;
      final service = _service(client, retry: const Duration(milliseconds: 30));
      await service.submit(_pending(_right()));
      final solved = service.events.first;
      client.online = true;
      final e = await solved.timeout(const Duration(seconds: 3));
      expect(e.kind, ValidationEventKind.solved);
    });

    test('al iniciar reintenta lo que quedó de la sesión anterior', () async {
      client.online = false;
      final first = _service(client);
      await first.submit(_pending(_right(), id: 'sub-reinicio-01'));
      final raw = (await SharedPreferences.getInstance()).getString(
        kPendingKey,
      )!;
      first.dispose();

      // "Reiniciar": la memoria se pierde, solo queda lo guardado.
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({kPendingKey: raw});
      client.online = true;
      final second = _service(client);
      await second.ready;
      expect(second.pendingCaseIds, {pc.caseId});

      await second.start();
      expect(client.submits.last.submissionId, 'sub-reinicio-01');
      expect(client.sessions, greaterThan(0));
      expect(second.pendingCaseIds, isEmpty);
    });
  });

  group('la cola sobrevive a reiniciar', () {
    test('se guarda con todo lo necesario y se lee igual', () async {
      client.online = false;
      final service = _service(client);
      final sent = _pending(_swapped(), id: 'sub-guardado-01', errors: 3);
      await service.submit(sent);
      final raw = (await SharedPreferences.getInstance()).getString(
        kPendingKey,
      )!;

      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({kPendingKey: raw});
      final again = _service(client);
      await again.ready;
      expect(again.pendingCaseIds, {pc.caseId});

      client.online = true;
      await again.flush();
      final last = client.submits.last;
      expect(last.submissionId, 'sub-guardado-01');
      expect(last.positions, sent.positions);
      expect(last.clientElapsedMs, sent.clientElapsedMs);
      expect(last.startedOnline, sent.startedOnline);
    });

    test('una cola dañada no rompe el arranque', () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({kPendingKey: '{no es json'});
      final service = _service(client);
      await service.ready;
      expect(service.pendingCaseIds, isEmpty);
    });
  });

  group('inicio de partida (startCase)', () {
    test('con señal avisa una vez y lo recuerda', () async {
      final service = _service(client);
      expect(await service.ensureStarted(pc.caseId), isTrue);
      expect(await service.ensureStarted(pc.caseId), isTrue);
      expect(client.starts, [pc.caseId]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('started:${pc.caseId}'), '1');
    });

    test('sin señal no falla: la partida no entra al ranking', () async {
      client.online = false;
      final service = _service(client);
      expect(await service.ensureStarted(pc.caseId), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('started:${pc.caseId}'), '0');
      // Reabrir el caso con señal no la convierte en rankeable.
      client.online = true;
      final reopened = _service(client);
      expect(await reopened.ensureStarted(pc.caseId), isFalse);
      expect(client.starts, isEmpty);
    });
  });
}
