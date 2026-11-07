/// Ronda 5A.2, carrera de arranque: abrir la app directamente en un caso, con
/// la sesión anónima todavía restaurándose. Ninguna llamada a una función sale
/// antes que la sesión, la sesión es una sola, y `started:<id>` solo dice "sin
/// conexión" cuando de verdad no hubo red.
library;

import 'dart:async';

import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_service.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

late PuzzleCase pc;

ValidationService _service(FakeValidationClient client) {
  final s = ValidationService(
    client: client,
    retryEvery: const Duration(minutes: 10),
  );
  addTearDown(s.dispose);
  return s;
}

PendingSubmission _pending() => PendingSubmission(
  caseId: pc.caseId,
  submissionId: 'sub-carrera-0001',
  positions: Map.of(pc.solution.positions),
  clientElapsedMs: 1000,
  startedOnline: true,
  elapsedSeconds: 1,
  errorCount: 0,
  createdAt: DateTime.utc(2026, 11, 7, 10),
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => pc = loadBankCase('mansion-01'));

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeValidationClient()..add(pc);
  });

  group('la sesión va primero y es una sola', () {
    test(
      'startCase espera a la sesión lenta; start() y startCase la comparten',
      () async {
        client.sessionGate = Completer<void>();
        final service = _service(client);

        // Como al recargar en un caso: el arranque (start) y la partida
        // (ensureStarted) piden lo mismo a la vez, con la sesión sin restaurar.
        final started = service.start();
        final online = service.ensureStarted(pc.caseId);
        for (var i = 0; i < 5; i++) {
          await _pump();
        }

        expect(client.log, ['session:begin']); // aún ninguna función
        expect(client.starts, isEmpty);
        expect(client.sessions, 1); // una sola sesión en marcha

        client.sessionGate!.complete();
        expect(await online, isTrue);
        await started;

        expect(client.sessions, 1);
        expect(client.log.take(3), [
          'session:begin',
          'session:end',
          'start:${pc.caseId}',
        ]);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('started:${pc.caseId}'), '1');
      },
    );

    test('un envío tampoco sale antes que la sesión', () async {
      client.sessionGate = Completer<void>();
      final service = _service(client);
      final out = service.submit(_pending());
      for (var i = 0; i < 5; i++) {
        await _pump();
      }
      expect(client.submits, isEmpty);

      client.sessionGate!.complete();
      expect(await out, isA<OutcomeSolved>());
      expect(
        client.log.indexOf('session:end'),
        lessThan(client.log.indexOf('submit:${pc.caseId}')),
      );
    });

    test(
      'si la sesión falla, la siguiente llamada la vuelve a intentar',
      () async {
        client.sessionFails = true;
        final service = _service(client);
        expect(await service.ensureStarted(pc.caseId), isFalse);
        expect(client.sessions, 1);

        client.sessionFails = false;
        await service.flush();
        // Nueva sesión para el siguiente intento (no se quedó el fallo guardado).
        await service.submit(_pending());
        expect(client.sessions, 2);
      },
    );
  });

  group('started:<id> solo dice "sin conexión" si no hubo red', () {
    test('fallo de red: se guarda 0 y no se reintenta', () async {
      client.online = false;
      final service = _service(client);
      expect(await service.ensureStarted(pc.caseId), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('started:${pc.caseId}'), '0');
    });

    test(
      'error del servidor: no se guarda nada y se vuelve a probar',
      () async {
        client.startFailure = ValidationFailure.serverError;
        final service = _service(client);
        expect(await service.ensureStarted(pc.caseId), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('started:${pc.caseId}'), isFalse);

        // El jugador vuelve a abrir el caso y el servidor ya responde.
        client.startFailure = null;
        expect(await service.ensureStarted(pc.caseId), isTrue);
        expect(prefs.getString('started:${pc.caseId}'), '1');
        expect(client.starts, [pc.caseId]);
      },
    );

    test('otros errores del servidor (blocked) tampoco guardan nada', () async {
      client.startFailure = ValidationFailure.blocked;
      final service = _service(client);
      expect(await service.ensureStarted(pc.caseId), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('started:${pc.caseId}'), isFalse);
    });
  });
}
