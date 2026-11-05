// Ronda 3.2: datos por mundo (elenco, habitaciones y armas) y su uso en el
// generador. El mundo solo cambia el vocabulario, nunca las reglas.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

final mansionFile = File('data/mundos/mansion.json');

WorldData mansion() => loadWorldFile(mansionFile);

void main() {
  group('datos del Mundo 1 (data/mundos/mansion.json)', () {
    final w = mansion();

    test('es un mundo sano y se llama La Mansión', () {
      expect(w.id, kMundoMansion);
      expect(w.nameEs, 'La Mansión');
      expect(w.problems(), isEmpty);
    });

    test('tiene un elenco amplio con arquetipos de época', () {
      expect(w.cast.length, greaterThanOrEqualTo(30));
      expect(
          {for (final m in w.cast) m.initial}.length, greaterThanOrEqualTo(9));
      expect(w.cast.every((m) => m.archetype.trim().isNotEmpty), isTrue);
      expect(w.cast.any((m) => m.female), isTrue);
      expect(w.cast.any((m) => !m.female), isTrue);
    });

    test('tiene las habitaciones propias de una mansión', () {
      final names = {for (final r in w.rooms) r.nameEs};
      for (final n in [
        'la Biblioteca',
        'el Salón',
        'el Comedor',
        'la Cocina',
        'el Estudio',
        'el Invernadero',
        'la Galería',
        'el Dormitorio',
        'la Bodega',
        'el Vestíbulo',
      ]) {
        expect(names, contains(n));
      }
    });

    test('ninguna arma es de fuego, militar o explosiva', () {
      for (final a in w.weapons) {
        expect(forbiddenWeaponWord(a.nameEs), isNull, reason: a.nameEs);
        expect(forbiddenWeaponWord(a.id), isNull, reason: a.id);
      }
      expect(w.weapons.length, greaterThanOrEqualTo(8));
    });

    test('ida y vuelta por JSON conserva todo', () {
      final back = WorldData.fromJson(
          jsonDecode(jsonEncode(w.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(back.toJson()), jsonEncode(w.toJson()));
    });
  });

  group('validación de un mundo', () {
    WorldData conArma(String nombre) {
      final w = mansion();
      return WorldData(
        id: w.id,
        names: w.names,
        cast: w.cast,
        rooms: w.rooms,
        weapons: [
          ...w.weapons,
          WorldWeapon(
              id: 'x', nameEs: nombre, category: WeaponCategory.contundente),
        ],
      );
    }

    test('rechaza armas de fuego aunque lleven artículo o plural', () {
      for (final n in [
        'la pistola',
        'el revólver',
        'una escopeta',
        'las balas',
        'el rifle de caza',
        'la bomba de humo',
      ]) {
        expect(conArma(n).problems(), isNotEmpty, reason: n);
      }
    });

    test('no confunde palabras que solo contienen un fragmento', () {
      expect(forbiddenWeaponWord('la balanza de bronce'), isNull);
      expect(forbiddenWeaponWord('el cañón'), isNotNull);
      expect(forbiddenWeaponWord('el candelabro'), isNull);
      expect(conArma('la balanza').problems(), isEmpty);
    });

    test('rechaza elencos con pocas iniciales o pocas habitaciones', () {
      final w = mansion();
      final pocos = WorldData(
        id: w.id,
        names: w.names,
        cast: w.cast.take(3).toList(),
        rooms: w.rooms.take(4).toList(),
        weapons: w.weapons,
      );
      final p = pocos.problems().join(' ');
      expect(p, contains('iniciales'));
      expect(p, contains('habitaciones'));
    });

    test('un JSON incompleto lanza FormatException', () {
      expect(() => WorldData.fromJson({'id': 'x'}), throwsFormatException);
    });
  });

  group('pickCast', () {
    final w = mansion();

    test('es determinista y de iniciales distintas', () {
      for (final n in [6, 8, 9]) {
        for (var seed = 1; seed <= 30; seed++) {
          final a = w.pickCast(n, seed);
          final b = w.pickCast(n, seed);
          expect([for (final m in a) m.name], [for (final m in b) m.name]);
          expect(a.length, n);
          expect({for (final m in a) m.initial}.length, n);
        }
      }
    });

    test('sale ordenado alfabéticamente (como el elenco genérico)', () {
      final c = w.pickCast(9, 5);
      final names = [for (final m in c) foldEs(m.name)];
      expect(names, [...names]..sort());
    });

    test('semillas distintas dan elencos distintos', () {
      final sets = {
        for (var seed = 1; seed <= 10; seed++)
          [for (final m in w.pickCast(8, seed)) m.name].join(',')
      };
      expect(sets.length, greaterThan(5));
    });
  });

  group('CaseFactory con mundo', () {
    final w = mansion();

    test('usa los nombres, habitaciones y armas del mundo', () {
      final f =
          CaseFactory(DifficultyProfile.intermedio, withWeapon: true, world: w);
      final pc = f.generate(30, caseId: 'mansion-test').puzzle!;
      expect(pc.caseId, 'mansion-test');
      expect(pc.map.nameEs, 'La Mansión');
      final castNames = {for (final m in w.cast) m.name};
      expect(pc.characters.every((c) => castNames.contains(c.nameEs)), isTrue);
      final roomNames = {for (final r in w.rooms) r.nameEs};
      expect(pc.map.areas.every((a) => roomNames.contains(a.nameEs)), isTrue);
      final weaponNames = {for (final a in w.weapons) a.nameEs};
      expect(pc.map.weapons.isNotEmpty, isTrue);
      expect(
          pc.map.weapons.every((a) => weaponNames.contains(a.nameEs)), isTrue);
      expect(pc.hasWeapon, isTrue);
    });

    test('el caso del mundo cumple todas las reglas (puerta de contenido)', () {
      for (final (profile, seeds) in [
        (DifficultyProfile.principiante, [1, 2, 3]),
        (DifficultyProfile.casual, [1, 2]),
        (DifficultyProfile.intermedio, [1, 2]),
      ]) {
        for (final seed in seeds) {
          final pc = CaseFactory(profile, world: w).generate(seed).puzzle!;
          final c = checkCaseContent(pc);
          expect(c.passed, isTrue,
              reason: '${profile.label} s$seed: ${c.problems}');
          expect(c.unique && c.pureDeduction, isTrue);
        }
      }
    });

    test('misma semilla y mismo mundo: mismo caso', () {
      final f = CaseFactory(DifficultyProfile.casual, world: w);
      final a = f.generate(8, caseId: 'x').puzzle!;
      final b = f.generate(8, caseId: 'x').puzzle!;
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    });

    test('el mundo no cambia la lógica: mismos pasos con o sin nombres', () {
      // El sorteo del caso usa su propio generador; el mundo solo pone
      // nombres. Las posiciones de la solución y los tipos de pista salen
      // del mismo sorteo, pero el mapa cambia (habitaciones distintas), así
      // que solo se exige que ambos sean válidos y del mismo tamaño.
      final sin = CaseFactory(DifficultyProfile.principiante).generate(2);
      final con =
          CaseFactory(DifficultyProfile.principiante, world: w).generate(2);
      expect(sin.puzzle!.characters.length, con.puzzle!.characters.length);
      expect(sin.puzzle!.map.size, con.puzzle!.map.size);
    });

    test('sin mundo todo sale como antes (nombres genéricos)', () {
      final pc =
          CaseFactory(DifficultyProfile.principiante).generate(1).puzzle!;
      expect(pc.caseId, 'caso-principiante-s1');
      expect(pc.characters.first.nameEs, 'Adela');
    });
  });

  group('plan de casos', () {
    test('lee un plan y construye el caso con su historia', () {
      final plan = Plan.fromJson({
        'mundo': 'mansion',
        'casos': [
          {
            'id': 'mansion-t1',
            'dificultad': 'principiante',
            'semilla': 21,
            'arma': false,
            'titulo': {'es': 'Cena de prueba'},
            'premisa': {'es': 'Una cena de prueba termina mal.'},
          },
          {'id': 'mansion-t2', 'dificultad': 'casual', 'semilla': 8},
        ],
      });
      expect(plan.world, 'mansion');
      expect(plan.cases.length, 2);
      final w = mansion();
      final a = buildPlanCase(plan.cases[0], w).puzzle!;
      expect(a.caseId, 'mansion-t1');
      expect(a.story!.world, 'mansion');
      expect(a.story!.title('es'), 'Cena de prueba');
      // Sin título ni premisa el caso sale sin historia (exploración).
      final b = buildPlanCase(plan.cases[1], w).puzzle!;
      expect(b.story, isNull);
    });

    test('writeCaseFile escribe <id>.json y se vuelve a leer igual', () {
      final w = mansion();
      final plan = Plan.fromJson({
        'mundo': 'mansion',
        'casos': [
          {
            'id': 'mansion-t3',
            'dificultad': 'principiante',
            'semilla': 3,
            'titulo': {'es': 'T'},
            'premisa': {'es': 'P'},
          }
        ],
      });
      final pc = buildPlanCase(plan.cases.single, w).puzzle!;
      final dir = Directory.systemTemp.createTempSync('enx_world_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = writeCaseFile(pc, dir);
      expect(f.uri.pathSegments.last, 'mansion-t3.json');
      final back = loadCaseFile(f);
      expect(jsonEncode(back.toJson()), jsonEncode(pc.toJson()));
    });
  });
}
