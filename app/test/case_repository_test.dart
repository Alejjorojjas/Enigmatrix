import 'dart:convert';

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _C = ({String id, String diff});

String _raw(String id, String diff) =>
    jsonEncode({'caseId': id, 'difficulty': diff});

_C _parse(Map<String, dynamic> j) =>
    (id: j['caseId'] as String, diff: j['difficulty'] as String);

List<_C> _load(Map<String, String> raws, [List<String>? errors]) =>
    parseCasesTolerant<_C>(
      raws,
      parse: _parse,
      idOf: (c) => c.id,
      difficultyOf: (c) => c.diff,
      onError: errors?.add,
    );

void main() {
  test('caseNumberOf lee el número final', () {
    expect(caseNumberOf('caso-casual-s20'), 20);
    expect(caseNumberOf('caso-casual-s3'), 3);
    expect(caseNumberOf('tutorial'), isNull);
  });

  test('orden numérico s1, s2, s3, s20, s21 (no alfabético)', () {
    final raws = {
      for (final n in [21, 3, 20, 1, 2])
        'a$n.json': _raw('caso-casual-s$n', 'casual'),
    };
    expect(_load(raws).map((c) => c.id).toList(), [
      'caso-casual-s1',
      'caso-casual-s2',
      'caso-casual-s3',
      'caso-casual-s20',
      'caso-casual-s21',
    ]);
  });

  test('dificultad primero; ids sin número al final, alfabéticos', () {
    final raws = {
      'a': _raw('extra-b', 'casual'),
      'b': _raw('extra-a', 'casual'),
      'c': _raw('caso-casual-s2', 'casual'),
      'd': _raw('caso-p-s10', 'principiante'),
      'e': _raw('caso-e-s1', 'experto'),
    };
    expect(_load(raws).map((c) => c.id).toList(), [
      'caso-p-s10',
      'caso-casual-s2',
      'extra-a',
      'extra-b',
      'caso-e-s1',
    ]);
  });

  test('un JSON roto se omite y se registra; los demás cargan', () {
    final errors = <String>[];
    final raws = {
      'bien.json': _raw('caso-casual-s1', 'casual'),
      'roto.json': '{no es json',
      'incompleto.json': '{"caseId": 5}',
      'bom.json': '﻿${_raw('caso-casual-s2', 'casual')}',
    };
    final r = _load(raws, errors);
    expect(r.map((c) => c.id), ['caso-casual-s1', 'caso-casual-s2']);
    expect(errors.length, 2);
    expect(errors.any((e) => e.contains('roto.json')), isTrue);
  });

  test('si no carga ninguno, error claro', () {
    expect(() => _load({'x.json': 'basura'}), throwsA(isA<StateError>()));
    expect(() => _load({}), throwsA(isA<StateError>()));
  });

  test('buildFeedbackReport: versión, fecha y abiertos sin terminar', () {
    final report = buildFeedbackReport(
      version: '0.2.0+2',
      now: DateTime(2026, 11, 4),
      cases: [
        FeedbackCaseData(
          caseId: 'caso-casual-s1',
          difficulty: 'casual',
          doneRaw: jsonEncode({'time': 90, 'errors': 1, 'date': 'hoy'}),
        ),
        FeedbackCaseData(
          caseId: 'caso-casual-s2',
          difficulty: 'casual',
          gameRaw: jsonEncode({'v': 1, 'elapsed': 125, 'errors': 2}),
        ),
        const FeedbackCaseData(caseId: 'caso-casual-s3', difficulty: 'casual'),
      ],
    );
    expect(report.split('\n')[1], 'Versión: 0.2.0+2');
    expect(report, contains('Fecha: 04-11-2026'));
    expect(report, contains('tiempo: 90s · errores: 1'));
    expect(
      report,
      contains('abierto sin terminar · tiempo: 125s · errores: 2'),
    );
    expect(report, isNot(contains('s3')));
  });

  test('formatElapsed y SavedGameInfo tolerante', () {
    expect(formatElapsed(125), '2:05');
    expect(formatElapsed(3725), '1:02:05');
    expect(formatElapsed(null), '--:--');
    expect(SavedGameInfo.fromRaw('basura').elapsed, isNull);
    expect(SavedGameInfo.fromRaw('{"elapsed":7,"errors":1}').elapsed, 7);
  });
}
