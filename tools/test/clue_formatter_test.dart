// H-63: la redacción de las pistas vive en un formateador por idioma y el
// texto de hoy no cambia. El archivo fixtures/clue_texts_golden.json se
// generó con el motor ANTES de separar el formateador (27 casos congelados
// más los 16 tipos de pista sobre dos mapas); aquí se compara contra él.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

String _type(Clue c) => c.toJson()['type'] as String;

void main() {
  final golden = jsonDecode(File('test/fixtures/clue_texts_golden.json')
      .readAsStringSync()) as Map<String, dynamic>;
  final cases = (golden['cases'] as Map).cast<String, dynamic>();
  final synthetic = (golden['synthetic'] as Map).cast<String, dynamic>();

  group('ClueFormatterEs: mismo texto que antes de separarlo', () {
    test('el golden cubre los 20 casos, el tutorial y los casos con arma', () {
      expect(cases.keys.where((k) => k.startsWith('app/assets/cases/')).length,
          20);
      expect(cases.keys.where((k) => k.startsWith('app/assets/tutorial/')),
          hasLength(1));
      expect(
          cases.keys.where((k) => k.contains('cases_armas')), hasLength(6));
    });

    for (final e in cases.entries) {
      test('texto de las pistas de ${e.key}', () {
        final path = e.key.startsWith('tools/')
            ? e.key.substring('tools/'.length)
            : '../${e.key}';
        final pc = PuzzleCase.fromJson(
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>);
        final expected = (e.value as List).cast<List>();
        expect(pc.clues.length, expected.length);
        const f = ClueFormatterEs.instance;
        for (var i = 0; i < pc.clues.length; i++) {
          final c = pc.clues[i];
          final exp = expected[i].cast<String>();
          expect(_type(c), exp[0]);
          // Por los métodos que usa la app (delegan) ...
          expect(c.predicateEs(pc.map, pc.names), exp[1], reason: 'pista $i');
          expect(c.textEs(pc.map, pc.names), exp[2], reason: 'pista $i');
          expect(c.cardTextEs(pc.map, pc.names), exp[3], reason: 'pista $i');
          // ... y directo por el formateador.
          expect(f.predicate(c, pc.map, pc.names), exp[1]);
          expect(f.text(c, pc.map, pc.names), exp[2]);
          expect(f.cardText(c, pc.map, pc.names), exp[3]);
        }
      });
    }

    test('los 16 tipos de pista sobre dos mapas dan el mismo texto', () {
      final names = ClueNames(
          nameOf: (id) => {'c1': 'Adela', 'c2': 'Bruno', 'c3': 'La víctima'}[id]!,
          isFemale: (id) => id == 'c1' || id == 'c3');
      final clues = <Clue>[];
      for (final m in [cabana, mansion]) {
        for (final g in m.objectGroups) {
          clues.addAll([
            OnObjectGroup('c1', g),
            OnObjectGroup('c2', g),
            BesideObjectGroup('c1', g),
            OnlyOneOnGroup('c1', g),
            OnlyOneOnGroup('c2', g),
          ]);
        }
      }
      for (final m in [cabana, mansion]) {
        final ar = m.areas.first.id;
        clues.addAll([
          InArea('c1', ar),
          NotInArea('c2', ar),
          AreaEmpty(ar),
          WeaponInArea(ar),
        ]);
      }
      clues.addAll([
        const SameArea('c1', 'c2'),
        const NotSameArea('c2', 'c1'),
        const BesideChar('c1', 'c3'),
        const Alone('c1'),
        const Alone('c2'),
        const AloneWith('c1', 'c2'),
        const LastFreeCell('c3'),
        const WeaponCat(WeaponCategory.cortante),
        const WeaponCat(WeaponCategory.contundente),
        const WeaponCat(WeaponCategory.veneno),
        const WeaponCat(WeaponCategory.asfixia),
        const WeaponExact('cuchillo'),
        CompoundClue('c1',
            [InArea('c1', 'salon'), const BesideObjectGroup('c1', 'planta')]),
        CompoundClue('c2', [
          const OnObjectGroup('c2', 'silla'),
          const BesideObjectGroup('c2', 'mesa'),
          InArea('c2', 'salon'),
        ]),
      ]);
      expect({for (final c in clues) _type(c)}.length, 16);
      for (final m in [cabana, mansion]) {
        final expected = (synthetic[m.id] as List).cast<List>();
        expect(clues.length, expected.length);
        for (var i = 0; i < clues.length; i++) {
          final exp = expected[i].cast<String>();
          expect(clues[i].predicateEs(m, names), exp[1],
              reason: '${m.id} #$i ${exp[0]}');
          expect(clues[i].textEs(m, names), exp[2]);
          expect(clues[i].cardTextEs(m, names), exp[3]);
        }
      }
    });
  });

  group('Registro de idiomas', () {
    test('es existe y devuelve el formateador en español', () {
      final f = ClueFormatter.forLanguage('es');
      expect(f.languageCode, 'es');
      expect(f, same(ClueFormatterEs.instance));
      expect(ClueFormatter.supportedLanguages, ['es']);
    });

    test('un idioma sin formateador (en, todavía) falla con mensaje claro', () {
      expect(() => ClueFormatter.forLanguage('en'),
          throwsA(isA<ArgumentError>()));
    });

    test('un formateador nuevo puede heredar las reglas de frase y tarjeta',
        () {
      // Prueba de que el lugar para EN está listo: solo hay que redactar
      // predicate(); text() y cardText() se heredan.
      const f = _FakeEn();
      const names = ClueNames(nameOf: _nameOf, isFemale: _isFemale);
      expect(f.text(const InArea('c1', 'salon'), cabana, names),
          'Adela was in salon.');
      expect(f.cardText(const InArea('c1', 'salon'), cabana, names),
          'Was in salon.');
    });
  });
}

String _nameOf(String id) => 'Adela';
bool _isFemale(String id) => true;

class _FakeEn extends ClueFormatter {
  const _FakeEn();
  @override
  String get languageCode => 'en';
  @override
  String predicate(Clue clue, GameMap map, ClueNames names) =>
      'was in ${(clue as InArea).areaId}';
}
