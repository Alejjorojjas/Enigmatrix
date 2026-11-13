/// Contrato nuevo del servidor (etapa 5A.3): `localDate` en los envíos, los
/// campos del reto en la respuesta y las funciones getDailyChallenge,
/// setNickname y deleteAccount. Sin red.
library;

import 'package:enigmatrix/src/backend/firebase_validation_client.dart'
    show failureForFunctionsCode;
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_service.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubmitRequest', () {
    test('sin localDate no lo manda; con localDate sí', () {
      const base = SubmitRequest(
        caseId: 'mansion-01',
        positions: {'a': 1},
        clientElapsedMs: 1000,
        startedOnline: true,
        submissionId: 'sub-12345678',
      );
      expect(base.toCallData().containsKey('localDate'), isFalse);
      const reto = SubmitRequest(
        caseId: 'reto-001',
        positions: {'a': 1},
        clientElapsedMs: 1000,
        startedOnline: true,
        submissionId: 'sub-12345678',
        localDate: '2026-11-16',
      );
      expect(reto.toCallData()['localDate'], '2026-11-16');
    });
  });

  group('respuesta de submitSolution', () {
    test('caso de campaña: sin campos de reto', () {
      final r = parseSubmitResponse({
        'result': 'solved',
        'murdererId': 'm',
        'lethalWeaponId': 'w',
        'ranked': false,
      });
      r as SubmitSolved;
      expect(r.serverElapsedMs, isNull);
      expect(r.errors, isNull);
      expect(r.score, isNull);
      expect(r.rank, isNull);
    });

    test('reto resuelto: tiempo, errores, score y puesto', () {
      final r = parseSubmitResponse({
        'result': 'solved',
        'murdererId': 'm',
        'lethalWeaponId': null,
        'ranked': true,
        'serverElapsedMs': 95000,
        'errors': 2,
        'score': 155000,
        'rank': 7,
      });
      r as SubmitSolved;
      expect(r.ranked, isTrue);
      expect(r.serverElapsedMs, 95000);
      expect(r.errors, 2);
      expect(r.score, 155000);
      expect(r.rank, 7);
    });

    test('reto resuelto sin entrar al ranking: rank null', () {
      final r =
          parseSubmitResponse({
                'result': 'solved',
                'murdererId': 'm',
                'ranked': false,
                'serverElapsedMs': 1000,
                'errors': 0,
                'score': 1000,
                'rank': null,
              })
              as SubmitSolved;
      expect(r.rank, isNull);
      expect(r.score, 1000);
    });
  });

  group('otras respuestas', () {
    test('getDailyChallenge', () {
      final d = parseDailyChallenge({
        'localDate': '2026-11-16',
        'caseId': 'reto-001',
      });
      expect(d.localDate, '2026-11-16');
      expect(d.caseId, 'reto-001');
      expect(
        () => parseDailyChallenge({'localDate': 'x'}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('setNickname', () {
      expect(parseNicknameResponse({'nickname': 'Ana'}), 'Ana');
      expect(
        () => parseNicknameResponse(null),
        throwsA(isA<ValidationException>()),
      );
    });

    test('formatLocalDate usa YYYY-MM-DD', () {
      expect(formatLocalDate(DateTime(2026, 3, 5)), '2026-03-05');
      expect(formatLocalDate(DateTime(2026, 11, 16, 23, 59)), '2026-11-16');
    });

    test('el cliente falso responde el reto y el apodo', () async {
      final client = FakeValidationClient();
      client.dailyByDate['2026-11-17'] = 'reto-002';
      expect((await client.getDailyChallenge('2026-11-17')).caseId, 'reto-002');
      expect(await client.setNickname('  Ana  '), 'Ana');
      await client.deleteAccount();
      expect(client.accountDeleted, isTrue);
    });
  });

  group('invitado sin registro', () {
    test('failed-precondition con "Regístrate" se distingue del bloqueo', () {
      expect(
        failureForFunctionsCode(
          'failed-precondition',
          'Regístrate para seguir jugando',
        ),
        ValidationFailure.registrationRequired,
      );
      // Sin ese mensaje (p. ej. falta App Check) sigue siendo un bloqueo.
      expect(
        failureForFunctionsCode('failed-precondition'),
        ValidationFailure.blocked,
      );
      expect(
        failureForFunctionsCode('failed-precondition', 'App Check'),
        ValidationFailure.blocked,
      );
      expect(
        failureForFunctionsCode('permission-denied', 'Regístrate'),
        ValidationFailure.blocked,
      );
    });

    test(
      'el servicio responde OutcomeRegistrationRequired y no encola',
      () async {
        SharedPreferences.setMockInitialValues({});
        final client = FakeValidationClient()..requiresRegistration = true;
        final s = ValidationService(client: client);
        addTearDown(s.dispose);
        final events = <ValidationEventKind>[];
        s.events.listen((e) => events.add(e.kind));
        final out = await s.submit(
          PendingSubmission(
            caseId: 'mansion-03',
            submissionId: 'sub-00000009',
            positions: const {'a': 1},
            clientElapsedMs: 1000,
            startedOnline: true,
            elapsedSeconds: 1,
            errorCount: 0,
            createdAt: DateTime.utc(2026, 11, 16),
          ),
        );
        expect(out, isA<OutcomeRegistrationRequired>());
        expect(s.pendingCaseIds, isEmpty);
        await Future<void>.delayed(Duration.zero);
        expect(events, [ValidationEventKind.registrationRequired]);
      },
    );
  });

  group('la fecha local en el servicio', () {
    late PuzzleCase pc;
    late FakeValidationClient client;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = FakeValidationClient();
      pc = loadBankCase('mansion-01');
    });

    ValidationService service() {
      final s = ValidationService(
        client: client,
        clock: () => DateTime(2026, 11, 16, 8),
      );
      addTearDown(s.dispose);
      return s;
    }

    test('startCase de un reto lleva localDate; el de campaña no', () async {
      final s = service();
      await s.ensureStarted('reto-001');
      await s.ensureStarted('mansion-01');
      expect(client.starts, ['reto-001', 'mansion-01']);
      expect(client.startDates, ['2026-11-16', null]);
    });

    test('submit de un reto agrega localDate y se conserva en el JSON', () {
      final p = PendingSubmission(
        caseId: 'reto-001',
        submissionId: 'sub-12345678',
        positions: const {'a': 1},
        clientElapsedMs: 1000,
        startedOnline: true,
        elapsedSeconds: 1,
        errorCount: 0,
        createdAt: DateTime.utc(2026, 11, 16),
        localDate: '2026-11-16',
      );
      final back = PendingSubmission.fromJson(p.toJson())!;
      expect(back.localDate, '2026-11-16');
      expect(back.toRequest().localDate, '2026-11-16');
      // Un envío viejo guardado sin localDate sigue leyéndose.
      final old = Map<String, Object?>.of(p.toJson())..remove('localDate');
      expect(PendingSubmission.fromJson(old)!.localDate, isNull);
    });

    test(
      'submit de un reto sin localDate la completa con la fecha de hoy',
      () async {
        final s = service();
        final reto = PendingSubmission(
          caseId: 'reto-001',
          submissionId: 'sub-00000001',
          positions: const {'a': 1},
          clientElapsedMs: 1000,
          startedOnline: true,
          elapsedSeconds: 1,
          errorCount: 0,
          createdAt: DateTime.utc(2026, 11, 16),
        );
        await s.submit(reto);
        expect(client.submits.single.localDate, '2026-11-16');

        final campana = PendingSubmission(
          caseId: pc.caseId,
          submissionId: 'sub-00000002',
          positions: const {'a': 1},
          clientElapsedMs: 1000,
          startedOnline: true,
          elapsedSeconds: 1,
          errorCount: 0,
          createdAt: DateTime.utc(2026, 11, 16),
        );
        client.add(pc);
        await s.submit(campana);
        expect(client.submits.last.localDate, isNull);
      },
    );

    test('resetAfterAccountDeletion vacía la cola en memoria', () async {
      final s = service();
      client.online = false;
      final p = PendingSubmission(
        caseId: pc.caseId,
        submissionId: 'sub-00000003',
        positions: const {'a': 1},
        clientElapsedMs: 1000,
        startedOnline: true,
        elapsedSeconds: 1,
        errorCount: 0,
        createdAt: DateTime.utc(2026, 11, 16),
      );
      await s.submit(p);
      expect(s.pendingCaseIds, {pc.caseId});
      await s.resetAfterAccountDeletion();
      expect(s.pendingCaseIds, isEmpty);
    });
  });
}
