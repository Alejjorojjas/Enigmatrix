// Ronda 3.2: carga del Mundo 1 "La Mansión" y del reto diario por catálogo.
// Lo que la app muestra hoy (CaseRepository.loadAll) no cambia: sigue siendo
// el banco de pruebas de 20 casos, en el mismo orden.
import 'dart:convert';

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _catalog(List<Map<String, Object>> casos) =>
    jsonEncode({'version': 1, 'casos': casos});

Map<String, Object> _entry(
  String id,
  int orden, {
  String mundo = 'mansion',
  String tipo = 'campana',
  int? dia,
}) => {
  'id': id,
  'mundo': mundo,
  'tipo': tipo,
  'dificultad': 'casual',
  'orden': orden,
  'archivo': '$id.json',
  if (dia != null) 'dia': dia,
};

final _mixed = _catalog([
  _entry('b1', 1, mundo: 'banco-de-pruebas'),
  _entry('m2', 3),
  _entry('m1', 2),
  _entry('r2', 5, tipo: 'reto', dia: 2),
  _entry('r1', 4, tipo: 'reto', dia: 1),
]);

PuzzleCase _tiny(String id, {CaseStory? story}) => PuzzleCase(
  caseId: id,
  map: cabana,
  characters: const [
    Character(id: 'c1', nameEs: 'Adela', female: true),
    Character(id: 'c2', nameEs: 'Bruno', female: false),
    Character(id: 'c3', nameEs: 'Clara', female: true),
    Character(id: 'c4', nameEs: 'Dario', female: false),
  ],
  victimId: 'c4',
  clues: const [],
  hasWeapon: false,
  difficulty: 'casual',
  solution: Solution(
    positions: {'c1': 1, 'c2': 4, 'c3': 10, 'c4': 15},
    murdererId: 'c3',
  ),
  story: story,
);

String _tinyRaw(String id, {CaseStory? story}) =>
    jsonEncode(_tiny(id, story: story).toJson());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveCaseSource con mundo y tipo', () {
    test('sin filtros devuelve todo, como antes', () {
      final s = resolveCaseSource(catalogRaw: _mixed);
      expect(s.files, ['b1.json', 'm1.json', 'm2.json', 'r1.json', 'r2.json']);
    });

    test('mundo limita a las entradas de ese mundo, en orden', () {
      final s = resolveCaseSource(
        catalogRaw: _mixed,
        mundo: 'banco-de-pruebas',
      );
      expect(s.files, ['b1.json']);
      expect(s.orderById, {'b1': 1});
      expect(s.fromCatalog, isTrue);
    });

    test('mundo y tipo se combinan', () {
      final s = resolveCaseSource(
        catalogRaw: _mixed,
        mundo: 'mansion',
        tipo: CaseKind.campana,
      );
      expect(s.files, ['m1.json', 'm2.json']);
    });

    test('si el mundo pedido no tiene casos cae al índice heredado', () {
      final s = resolveCaseSource(
        catalogRaw: _mixed,
        indexRaw: '["x.json"]',
        mundo: 'no-existe',
      );
      expect(s.fromCatalog, isFalse);
      expect(s.files, ['x.json']);
    });
  });

  group('selectCatalogEntries', () {
    test('filtra por mundo y tipo y conserva el orden del catálogo', () {
      expect(
        selectCatalogEntries(
          _mixed,
          mundo: 'mansion',
          tipo: CaseKind.campana,
        ).map((e) => e.id),
        ['m1', 'm2'],
      );
      expect(
        selectCatalogEntries(_mixed, tipo: CaseKind.reto).map((e) => e.dia),
        [1, 2],
      );
      expect(selectCatalogEntries(_mixed, mundo: 'otro'), isEmpty);
    });

    test('sin catálogo o con un catálogo ilegible lanza un error claro', () {
      expect(() => selectCatalogEntries(null), throwsStateError);
      expect(() => selectCatalogEntries('{no es json'), throwsStateError);
    });
  });

  group('pairEntriesWithCases', () {
    final entries = selectCatalogEntries(
      _mixed,
      mundo: 'mansion',
      tipo: CaseKind.campana,
    );

    test('une cada entrada con su caso y conserva el orden', () {
      final r = pairEntriesWithCases(entries, {
        'm1.json': _tinyRaw('m1'),
        'm2.json': _tinyRaw('m2'),
      });
      expect(r.map((p) => p.puzzle.caseId), ['m1', 'm2']);
      expect(r.map((p) => p.entry.orden), [2, 3]);
    });

    test('salta lo que falta, lo roto y lo que tiene otro id', () {
      final errores = <String>[];
      final r = pairEntriesWithCases(entries, {
        'm1.json': '{no',
        'm2.json': _tinyRaw('otro-id'),
      }, onError: errores.add);
      expect(r, isEmpty);
      expect(errores, hasLength(2));
      expect(errores.last, contains('otro-id'));

      final e2 = <String>[];
      final r2 = pairEntriesWithCases(entries, {
        'm2.json': _tinyRaw('m2'),
      }, onError: e2.add);
      expect(r2.map((p) => p.puzzle.caseId), ['m2']);
      expect(e2, hasLength(1));
    });

    test('lee un caso con historia', () {
      final story = CaseStory(
        world: 'mansion',
        title: {'es': 'Cena'},
        premise: {'es': 'Una cena.'},
      );
      final r = pairEntriesWithCases(entries, {
        'm1.json': _tinyRaw('m1', story: story),
      });
      expect(r.single.puzzle.story?.title('es'), 'Cena');
    });

    test('un caso sin historia sigue funcionando', () {
      expect(_tiny('m1').story, isNull);
      expect(_tiny('m1').story?.title('es'), isNull);
    });
  });

  test('sortChallenges ordena por día sin tocar la lista original', () {
    final a = DailyChallenge(day: 3, puzzle: _tiny('a'));
    final b = DailyChallenge(day: 1, puzzle: _tiny('b'));
    final original = [a, b];
    expect(sortChallenges(original).map((c) => c.day), [1, 3]);
    expect(original.first.day, 3);
  });

  group('assets reales', () {
    test(
      'loadAll sigue devolviendo los mismos 20 casos, en el mismo orden',
      () async {
        final cases = await CaseRepository.loadAll();
        expect(cases.map((c) => c.caseId), [
          for (var i = 1; i <= 8; i++) 'caso-principiante-s$i',
          for (final i in [1, 2, 3, 4, 5, 20, 21]) 'caso-casual-s$i',
          for (var i = 1; i <= 5; i++) 'caso-intermedio-s$i',
        ]);
      },
    );

    test(
      'loadCampaign("mansion") trae los 10 casos del Mundo 1 en orden',
      () async {
        final cases = await CaseRepository.loadCampaign(kMundoMansion);
        expect(cases.map((c) => c.caseId), [
          for (var i = 1; i <= 10; i++)
            'mansion-${i.toString().padLeft(2, '0')}',
        ]);
        expect(cases.map((c) => c.difficulty), [
          'principiante',
          'principiante',
          'principiante',
          'casual',
          'casual',
          'casual',
          'intermedio',
          'intermedio',
          'intermedio',
          'intermedio',
        ]);
        for (final c in cases) {
          expect(c.story, isNotNull, reason: c.caseId);
          expect(c.story!.world, kMundoMansion);
          expect(c.story!.title('es'), isNotEmpty);
          expect(c.story!.premise('es'), isNotEmpty);
        }
        // El arma homicida solo en Intermedio (pregunta 19, pendiente).
        final conArma = cases.where((c) => c.hasWeapon).toList();
        expect(conArma.length, inInclusiveRange(2, 3));
        expect(conArma.every((c) => c.difficulty == 'intermedio'), isTrue);
      },
    );

    test(
      'loadCampaign de un mundo que no existe devuelve lista vacía',
      () async {
        expect(await CaseRepository.loadCampaign('no-existe'), isEmpty);
      },
    );

    test(
      'el banco de pruebas no se mezcla con la campaña del Mundo 1',
      () async {
        final banco = (await CaseRepository.loadAll()).map((c) => c.caseId);
        final mundo1 = (await CaseRepository.loadCampaign(
          kMundoMansion,
        )).map((c) => c.caseId);
        expect(banco.toSet().intersection(mundo1.toSet()), isEmpty);
        expect(banco.any((id) => id.startsWith('mansion-')), isFalse);
      },
    );

    test(
      'loadDailyChallenges trae 30 retos, días 1 a 30, Casual e Intermedio',
      () async {
        final retos = await CaseRepository.loadDailyChallenges();
        expect(retos.map((r) => r.day), [for (var i = 1; i <= 30; i++) i]);
        expect(retos.map((r) => r.puzzle.caseId), [
          for (var i = 1; i <= 30; i++) 'reto-${i.toString().padLeft(3, '0')}',
        ]);
        expect(
          retos.every(
            (r) => ['casual', 'intermedio'].contains(r.puzzle.difficulty),
          ),
          isTrue,
        );
        expect(retos.every((r) => r.puzzle.story != null), isTrue);
      },
    );

    test('ningún reto repite un caso de la campaña ni del banco', () async {
      final ids = <String>{
        ...(await CaseRepository.loadAll()).map((c) => c.caseId),
        ...(await CaseRepository.loadCampaign(
          kMundoMansion,
        )).map((c) => c.caseId),
      };
      final retos = await CaseRepository.loadDailyChallenges();
      expect(retos.every((r) => !ids.contains(r.puzzle.caseId)), isTrue);
      // Y entre sí, el rompecabezas (mapa y pistas) de cada reto es distinto.
      // Los retos publicados ya no traen la solución en los assets.
      expect(retos.every((r) => !r.puzzle.hasSolution), isTrue);
      final firmas = retos
          .map(
            (r) => jsonEncode({
              'map': r.puzzle.map.toJson(),
              'clues': [for (final c in r.puzzle.clues) c.toJson()],
            }),
          )
          .toSet();
      expect(firmas.length, 30);
    });

    test('loadDailyChallenge devuelve el del día o null', () async {
      expect((await CaseRepository.loadDailyChallenge(1))!.caseId, 'reto-001');
      expect((await CaseRepository.loadDailyChallenge(30))!.caseId, 'reto-030');
      expect(await CaseRepository.loadDailyChallenge(0), isNull);
      expect(await CaseRepository.loadDailyChallenge(31), isNull);
    });

    test(
      'los proveedores exponen cada lista sin tocar casesProvider',
      () async {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        expect((await c.read(casesProvider.future)).length, 20);
        expect(
          (await c.read(campaignProvider(kMundoMansion).future)).length,
          10,
        );
        expect((await c.read(dailyChallengesProvider.future)).length, 30);
      },
    );
  });
}
