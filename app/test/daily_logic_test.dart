/// Reto diario y ranking (ronda F2b): fórmula del reto del día, formato del
/// tiempo, score, orden del ranking y progreso guardado. Sin red.
library;

import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/daily/daily_logic.dart';
import 'package:enigmatrix/src/daily/daily_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RankingEntry _e(String uid, int score, {int at = 0, int errors = 0}) =>
    RankingEntry(
      uid: uid,
      nickname: 'Nick-$uid',
      serverElapsedMs: score - errors * 30000,
      errors: errors,
      score: score,
      solvedAtMs: at,
    );

void main() {
  group('reto del día (misma fórmula que el servidor)', () {
    test('el día de inicio toca reto-001', () {
      expect(dailyCaseIdForLocalDate('2026-11-16'), 'reto-001');
    });

    test('avanza un reto por día y cierra el ciclo en reto-030', () {
      expect(dailyCaseIdForLocalDate('2026-11-17'), 'reto-002');
      expect(dailyCaseIdForLocalDate('2026-11-25'), 'reto-010');
      expect(dailyCaseIdForLocalDate('2026-12-15'), 'reto-030');
    });

    test('a los 30 días vuelve a reto-001 (ciclo)', () {
      expect(dailyCaseIdForLocalDate('2026-12-16'), 'reto-001');
      expect(dailyCaseIdForLocalDate('2027-01-15'), 'reto-001');
      expect(dailyCaseIdForLocalDate('2027-02-01'), 'reto-018');
    });

    test('fechas antes del inicio siguen el ciclo hacia atrás', () {
      expect(dailyCaseIdForLocalDate('2026-11-15'), 'reto-030');
      expect(dailyCaseIdForLocalDate('2026-11-01'), 'reto-016');
      expect(dailyCaseIdForLocalDate('2026-10-17'), 'reto-001');
      expect(dailyCaseIdForLocalDate('2025-01-01'), startsWith('reto-'));
    });

    test('respeta un inicio y un ciclo distintos', () {
      expect(
        dailyCaseIdForLocalDate(
          '2026-11-03',
          startDate: '2026-11-01',
          cycleDays: 5,
        ),
        'reto-003',
      );
      expect(
        dailyCaseIdForLocalDate(
          '2026-11-06',
          startDate: '2026-11-01',
          cycleDays: 5,
        ),
        'reto-001',
      );
    });

    test('el día del ciclo es el número del reto', () {
      expect(dailyDayForLocalDate('2026-11-16'), 1);
      expect(dailyDayForLocalDate('2026-12-15'), 30);
    });

    test('una fecha mal escrita falla en claro', () {
      expect(
        () => dailyCaseIdForLocalDate('16-11-2026'),
        throwsFormatException,
      );
    });

    test('formatLocalDate arma YYYY-MM-DD con ceros', () {
      expect(formatLocalDate(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });
  });

  group('tiempo y score', () {
    test('formatElapsedMs da mm:ss y trunca los milisegundos', () {
      expect(formatElapsedMs(0), '00:00');
      expect(formatElapsedMs(999), '00:00');
      expect(formatElapsedMs(61000), '01:01');
      expect(formatElapsedMs(95999), '01:35');
      expect(formatElapsedMs(5400000), '90:00');
      expect(formatElapsedMs(-5), '00:00');
    });

    test('score = tiempo + 30 s por error', () {
      expect(dailyScore(95000, 0), 95000);
      expect(dailyScore(95000, 2), 155000);
      expect(dailyScore(1000, 1, penaltyMs: 10000), 11000);
    });

    test('elapsedSince nunca es negativo', () {
      expect(elapsedSince(1000, 4500), 3500);
      expect(elapsedSince(5000, 1000), 0);
    });
  });

  group('orden del ranking', () {
    test('gana el menor score; en empate, quien resolvió primero', () {
      final list = [
        _e('c', 90000, at: 30),
        _e('a', 90000, at: 10),
        _e('b', 80000, at: 99),
      ]..sort(compareRanking);
      expect([for (final e in list) e.uid], ['b', 'a', 'c']);
    });

    test('la fila propia fuera del top se agrega aparte', () {
      final top = [for (var i = 0; i < 50; i++) _e('u$i', 60000 + i)];
      final me = _e('yo', 900000);
      final d = RankingData(top: top, own: me, ownRank: 73, ownUid: 'yo');
      expect(d.ownInTop, isFalse);
      expect(d.ownOutsideTop, me);
      expect(d.resolvedOwnRank, 73);
    });

    test('la fila propia dentro del top no se repite y da su posición', () {
      final top = [_e('a', 1), _e('yo', 2), _e('c', 3)];
      final d = RankingData(top: top, own: top[1], ownUid: 'yo');
      expect(d.ownInTop, isTrue);
      expect(d.ownOutsideTop, isNull);
      expect(d.resolvedOwnRank, 2);
    });

    test('sin filas ni fila propia está vacío', () {
      expect(const RankingData(top: []).isEmpty, isTrue);
      expect(RankingData(top: [_e('a', 1)]).isEmpty, isFalse);
    });

    test('RankingEntry.fromMap omite documentos incompletos', () {
      expect(RankingEntry.fromMap('x', {'nickname': 'Ana'}), isNull);
      // El documento no trae `uid`: la fila se identifica por el id.
      final e = RankingEntry.fromMap('u1', {
        'nickname': 'Ana',
        'serverElapsedMs': 90000,
        'errors': 1,
        'score': 120000,
        'solvedAt': 77,
      })!;
      expect(e.uid, 'u1');
      expect(e.score, 120000);
      expect(e.solvedAtMs, 77);
    });

    test('RankingEntry.fromMap usa el id aunque el dato traiga otro uid', () {
      final e = RankingEntry.fromMap('u1', {
        'uid': 'otro',
        'nickname': 'Ana',
        'serverElapsedMs': 1,
        'errors': 0,
        'score': 1,
      })!;
      expect(e.uid, 'u1');
    });
  });

  group('respuesta del servidor y progreso guardado', () {
    test('dailyResultFromSolved toma tiempo, errores, score y puesto', () {
      const r = SubmitSolved(
        murdererId: 'm',
        lethalWeaponId: null,
        ranked: true,
        serverElapsedMs: 95000,
        errors: 1,
        score: 125000,
        rank: 4,
      );
      final d = dailyResultFromSolved(r, '2026-11-16')!;
      expect(d.serverElapsedMs, 95000);
      expect(d.errors, 1);
      expect(d.score, 125000);
      expect(d.rank, 4);
      expect(DailyResult.fromJson(d.toJson())!.rank, 4);
    });

    test('un caso sin datos de reto no da resultado', () {
      const r = SubmitSolved(
        murdererId: 'm',
        lethalWeaponId: null,
        ranked: false,
      );
      expect(dailyResultFromSolved(r, '2026-11-16'), isNull);
    });

    test('el resultado de otro día no cuenta como resuelto hoy', () async {
      SharedPreferences.setMockInitialValues({
        'done:reto-001':
            '{"time":90,"errors":0,"localDate":"2026-10-17",'
            '"serverElapsedMs":90000,"serverErrors":0,"score":90000,"rank":2}',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(readDailyProgress(prefs, 'reto-001', '2026-11-16').result, isNull);
      expect(
        readDailyProgress(prefs, 'reto-001', '2026-10-17').result!.rank,
        2,
      );
    });

    test('lee el inicio de hoy y descarta el de otro día', () async {
      SharedPreferences.setMockInitialValues({
        'startedAt:reto-001': '{"date":"2026-11-16","at":1700000000000}',
        'startedAt:reto-002': '{"date":"2026-11-10"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final a = readDailyProgress(prefs, 'reto-001', '2026-11-16');
      expect(a.started, isTrue);
      expect(a.startedAt, 1700000000000);
      expect(
        readDailyProgress(prefs, 'reto-002', '2026-11-16').started,
        isFalse,
      );
    });

    test('displayDate pasa a dd-mm-aaaa', () {
      expect(displayDate('2026-11-16'), '16-11-2026');
    });
  });
}
