// Carga de casos por catálogo (H-43, H-50): el catálogo manda el orden, el
// índice heredado sigue funcionando como respaldo y la carga es tolerante.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _C = ({String id, String diff});

String _raw(String id, String diff) =>
    jsonEncode({'caseId': id, 'difficulty': diff});

_C _parse(Map<String, dynamic> j) =>
    (id: j['caseId'] as String, diff: j['difficulty'] as String);

String _catalog(List<(String id, int orden, String file)> items) => jsonEncode({
  'version': 1,
  'casos': [
    for (final (id, orden, file) in items)
      {
        'id': id,
        'mundo': 'banco-de-pruebas',
        'tipo': 'campana',
        'dificultad': 'casual',
        'orden': orden,
        'archivo': file,
      },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveCaseSource', () {
    test('con catálogo válido usa sus archivos y su orden', () {
      final s = resolveCaseSource(
        catalogRaw: _catalog([('b', 2, 'b.json'), ('a', 1, 'a.json')]),
        indexRaw: '["x.json"]',
      );
      expect(s.fromCatalog, isTrue);
      expect(s.files, ['a.json', 'b.json']);
      expect(s.orderById, {'a': 1, 'b': 2});
    });

    test('sin catálogo cae al índice heredado', () {
      final s = resolveCaseSource(
        indexRaw: '["a.json","index.json","catalogo.json","b.json"]',
      );
      expect(s.fromCatalog, isFalse);
      expect(s.files, ['a.json', 'b.json']);
      expect(s.orderById, isEmpty);
    });

    test('catálogo dañado cae al índice y deja un aviso', () {
      final s = resolveCaseSource(
        catalogRaw: '{esto no es json',
        indexRaw: '["a.json"]',
      );
      expect(s.fromCatalog, isFalse);
      expect(s.files, ['a.json']);
      expect(s.warnings.join(' '), contains('Catálogo'));
    });

    test('catálogo sin entradas válidas cae al índice', () {
      final s = resolveCaseSource(
        catalogRaw: jsonEncode({
          'version': 1,
          'casos': [
            {'id': 'roto'},
          ],
        }),
        indexRaw: '["a.json"]',
      );
      expect(s.fromCatalog, isFalse);
      expect(s.files, ['a.json']);
    });

    test('entradas inválidas del catálogo se saltan y se avisan', () {
      final raw = jsonEncode({
        'version': 1,
        'casos': [
          {
            'id': 'a',
            'mundo': 'm',
            'tipo': 'campana',
            'dificultad': 'casual',
            'orden': 1,
            'archivo': 'a.json',
          },
          {'id': 'roto'},
        ],
      });
      final s = resolveCaseSource(catalogRaw: raw);
      expect(s.files, ['a.json']);
      expect(s.warnings, hasLength(1));
    });

    test('sin catálogo ni índice utilizables lanza un error claro', () {
      expect(() => resolveCaseSource(), throwsStateError);
      expect(
        () => resolveCaseSource(catalogRaw: 'x', indexRaw: 'y'),
        throwsStateError,
      );
    });
  });

  group('orden por catálogo', () {
    List<_C> load(Map<String, String> raws, Map<String, int>? order) =>
        parseCasesTolerant<_C>(
          raws,
          parse: _parse,
          idOf: (c) => c.id,
          difficultyOf: (c) => c.diff,
          orderOf: order,
        );

    test(
      'manda el orden del catálogo aunque contradiga dificultad y número',
      () {
        final raws = {
          'a.json': _raw('caso-casual-s1', 'casual'),
          'b.json': _raw('caso-principiante-s9', 'principiante'),
          'c.json': _raw('caso-casual-s20', 'casual'),
        };
        final r = load(raws, {
          'caso-casual-s20': 1,
          'caso-casual-s1': 2,
          'caso-principiante-s9': 3,
        });
        expect(r.map((c) => c.id), [
          'caso-casual-s20',
          'caso-casual-s1',
          'caso-principiante-s9',
        ]);
      },
    );

    test(
      'lo que no está en el catálogo va después, con el orden de siempre',
      () {
        final raws = {
          'a.json': _raw('caso-casual-s2', 'casual'),
          'b.json': _raw('caso-casual-s10', 'casual'),
          'c.json': _raw('suelto', 'principiante'),
        };
        final r = load(raws, {'caso-casual-s10': 1});
        expect(r.first.id, 'caso-casual-s10');
        // El resto, por dificultad: principiante antes que casual.
        expect(r.skip(1).map((c) => c.id), ['suelto', 'caso-casual-s2']);
      },
    );

    test('sin orderOf se conserva el comportamiento anterior', () {
      final raws = {
        for (final n in [21, 3, 20, 1])
          'a$n.json': _raw('caso-casual-s$n', 'casual'),
      };
      expect(load(raws, null).map((c) => c.id), [
        'caso-casual-s1',
        'caso-casual-s3',
        'caso-casual-s20',
        'caso-casual-s21',
      ]);
    });

    test('un JSON roto se omite aunque haya catálogo', () {
      final errors = <String>[];
      final r = parseCasesTolerant<_C>(
        {'a.json': _raw('a', 'casual'), 'roto.json': '{no'},
        parse: _parse,
        idOf: (c) => c.id,
        difficultyOf: (c) => c.diff,
        orderOf: {'a': 1},
        onError: errors.add,
      );
      expect(r.map((c) => c.id), ['a']);
      expect(errors, hasLength(1));
    });
  });

  group('assets reales', () {
    test('catalogo.json: los 20 del banco de pruebas son campaña, orden 1 a '
        '20, mismo orden que mostraba la lista antes', () {
      final cat = CaseCatalog.fromJsonString(
        File('assets/cases/catalogo.json').readAsStringSync(),
      );
      final banco = cat.where(mundo: kBancoDePruebas);
      expect(banco, hasLength(20));
      expect(banco.every((e) => e.tipo == CaseKind.campana), isTrue);
      expect(banco.map((e) => e.orden), [for (var i = 1; i <= 20; i++) i]);
    });

    test('CaseRepository.loadAll carga los 20 en el orden del catálogo y con '
        'los ids de siempre (claves done:/game: sin cambios)', () async {
      final cases = await CaseRepository.loadAll();
      final expected = [
        for (var i = 1; i <= 8; i++) 'caso-principiante-s$i',
        for (final i in [1, 2, 3, 4, 5, 20, 21]) 'caso-casual-s$i',
        for (var i = 1; i <= 5; i++) 'caso-intermedio-s$i',
      ];
      expect(cases.map((c) => c.caseId), expected);
    });

    test('index.json solo lista los 20 del banco de pruebas', () {
      final idx =
          (jsonDecode(File('assets/cases/index.json').readAsStringSync())
                  as List)
              .cast<String>();
      expect(idx, hasLength(20));
      expect(
        idx.any((n) => n.startsWith('mansion-') || n.startsWith('reto-')),
        isFalse,
      );
    });

    test('el orden del catálogo coincide con el del respaldo por índice', () {
      final idx =
          (jsonDecode(File('assets/cases/index.json').readAsStringSync())
                  as List)
              .cast<String>();
      final raws = {
        for (final n in idx) n: File('assets/cases/$n').readAsStringSync(),
      };
      final byIndex = parseCasesTolerant<PuzzleCase>(
        raws,
        parse: PuzzleCase.fromJson,
        idOf: (c) => c.caseId,
        difficultyOf: (c) => c.difficulty,
      ).map((c) => c.caseId).toList();
      final cat = CaseCatalog.fromJsonString(
        File('assets/cases/catalogo.json').readAsStringSync(),
      );
      expect(cat.where(mundo: kBancoDePruebas).map((e) => e.id), byIndex);
    });

    test('el tutorial no está en el catálogo', () {
      final cat = CaseCatalog.fromJsonString(
        File('assets/cases/catalogo.json').readAsStringSync(),
      );
      expect(cat.byId(kTutorialCaseId), isNull);
      expect(cat.files.any((f) => f.contains('tutorial')), isFalse);
      // y el asset del tutorial sigue cargando por su ruta propia
      expect(rootBundle.loadString(kTutorialAsset), completes);
    });
  });
}
