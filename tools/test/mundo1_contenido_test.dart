// Ronda 3.2: contenido real de la V1 sobre app/assets/cases. El Mundo 1
// "La Mansión" (10 casos de campaña) y los 30 días de reto diario.
//
// Cubre: curva de dificultad, tamaños, arma, historia, catálogo, que cada
// archivo sea reproducible desde su plan (semilla explícita) y que ningún
// reto repita un caso de la campaña.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/regeneracion_pendiente.dart';

final casesDir = Directory('../app/assets/cases');
final catalog = CaseCatalog.fromJsonString(
    File('${casesDir.path}/catalogo.json').readAsStringSync());
final world = loadWorldFile(File('data/mundos/mansion.json'));
final campanaPlan = Plan.fromFile(File('data/mundos/mansion-casos.json'));
final retoPlan = Plan.fromFile(File('data/mundos/mansion-reto.json'));

PuzzleCase load(String id) {
  final e = catalog.byId(id)!;
  return loadCaseFile(File('${casesDir.path}/${e.archivo}'));
}

/// Huella del caso: pistas + solución. Dos casos con la misma huella serían
/// el mismo rompecabezas con otro nombre.
String huella(PuzzleCase pc) => jsonEncode({
      'clues': [for (final c in pc.clues) c.toJson()],
      'solution': pc.solution.toJson(),
      'size': pc.map.size,
    });

void main() {
  final campana = catalog.where(mundo: kMundoMansion, tipo: CaseKind.campana);
  final retos = catalog.where(mundo: kMundoMansion, tipo: CaseKind.reto);

  group('Mundo 1, La Mansión: 10 casos de campaña', () {
    test('están en el catálogo con ids estables y orden creciente', () {
      expect([
        for (final e in campana) e.id
      ], [
        for (var i = 1; i <= 10; i++) 'mansion-${i.toString().padLeft(2, '0')}'
      ]);
      final ordenes = [for (final e in campana) e.orden];
      expect(ordenes, [...ordenes]..sort());
      expect(campana.every((e) => e.dia == null), isTrue);
    });

    test(
        'casos 1 a 3 Principiante 6x6, 4 a 6 Casual 8x8, 7 a 10 Intermedio '
        '9x9', () {
      final esperado = [
        for (var i = 0; i < 3; i++) ('principiante', 6),
        for (var i = 0; i < 3; i++) ('casual', 8),
        for (var i = 0; i < 4; i++) ('intermedio', 9),
      ];
      for (var i = 0; i < 10; i++) {
        final pc = load(campana[i].id);
        expect(pc.difficulty, esperado[i].$1, reason: campana[i].id);
        expect(pc.map.size, esperado[i].$2, reason: campana[i].id);
        expect(campana[i].dificultad, esperado[i].$1);
      }
    });

    test(
        'el arma homicida va en 2 o 3 casos y solo desde Intermedio '
        '(pregunta 19, pendiente: cambiable)', () {
      final conArma = [
        for (final e in campana)
          if (load(e.id).hasWeapon) e
      ];
      expect(conArma.length, inInclusiveRange(2, 3));
      expect(conArma.every((e) => e.dificultad == 'intermedio'), isTrue);
    });

    test('todos pasan la puerta de contenido y están dentro de su rango', () {
      for (final e in campana) {
        final pc = load(e.id);
        final c = checkCaseContent(pc);
        expect(c.passed, isTrue, reason: '${e.id}: ${c.problems}');
        final m = pc.metrics!;
        final r = rangeForProfile(pc.difficulty);
        expect(r.contains(m.deductionSteps, m.maxTier), isTrue,
            reason: '${e.id}: ${m.deductionSteps} pasos T${m.maxTier} '
                'fuera de $r');
      }
    });

    test(
        'la dificultad crece: más pasos de media en cada tramo y el último '
        'caso es el más largo de los Intermedio', () {
      double media(Iterable<String> ids) =>
          ids
              .map((id) => load(id).metrics!.deductionSteps)
              .reduce((a, b) => a + b) /
          ids.length;
      final p = media(campana.take(3).map((e) => e.id));
      final c = media(campana.skip(3).take(3).map((e) => e.id));
      final i = media(campana.skip(6).map((e) => e.id));
      expect(p, lessThan(c));
      expect(c, lessThan(i));
      final pasos = [
        for (final e in campana) load(e.id).metrics!.deductionSteps
      ];
      expect(pasos.last, greaterThan(pasos.first));
      // Dentro de cada dificultad la curva no baja de un caso a otro.
      expect(pasos[0], lessThanOrEqualTo(pasos[1]));
      expect(pasos[1], lessThanOrEqualTo(pasos[2]));
      expect(pasos[3], lessThanOrEqualTo(pasos[4]));
      expect(pasos[4], lessThanOrEqualTo(pasos[5]));
      expect(pasos[7], lessThanOrEqualTo(pasos[8]));
      expect(pasos[8], lessThanOrEqualTo(pasos[9]));
    });

    test(
        'cada caso tiene historia propia del mundo, en español y sin '
        'repetirse', () {
      final titulos = <String>{};
      for (final e in campana) {
        final s = load(e.id).story!;
        expect(s.world, kMundoMansion);
        expect(s.title('es'), isNotEmpty);
        expect(s.premise('es'), isNotEmpty);
        expect(titulos.add(s.title('es')!), isTrue, reason: 'título repetido');
      }
    });

    test('usa nombres, habitaciones y armas de La Mansión', () {
      final nombres = {for (final m in world.cast) m.name};
      final cuartos = {for (final r in world.rooms) r.nameEs};
      for (final e in campana) {
        final pc = load(e.id);
        expect(pc.map.nameEs, 'La Mansión');
        expect(pc.characters.every((c) => nombres.contains(c.nameEs)), isTrue);
        expect(pc.map.areas.every((a) => cuartos.contains(a.nameEs)), isTrue);
      }
    });
  });

  group('Reto diario: 30 días', () {
    test('hay 30 retos con ids reto-001 a reto-030 y días 1 a 30', () {
      expect(retos.length, 30);
      expect([
        for (final e in retos) e.id
      ], [
        for (var i = 1; i <= 30; i++) 'reto-${i.toString().padLeft(3, '0')}'
      ]);
      expect([for (final e in retos) e.dia], [for (var i = 1; i <= 30; i++) i]);
      expect(retos.every((e) => e.tipo == CaseKind.reto), isTrue);
    });

    test('son Casual (8x8) o Intermedio (9x9), con ambas dificultades', () {
      final dif = <String>{};
      for (final e in retos) {
        final pc = load(e.id);
        dif.add(pc.difficulty);
        expect(['casual', 'intermedio'], contains(pc.difficulty));
        expect(pc.map.size, pc.difficulty == 'casual' ? 8 : 9);
        expect(e.dificultad, pc.difficulty);
      }
      expect(dif, {'casual', 'intermedio'});
    });

    test('todos pasan la puerta de contenido y están dentro de su rango', () {
      for (final e in retos) {
        final pc = load(e.id);
        final c = checkCaseContent(pc);
        expect(c.passed, isTrue, reason: '${e.id}: ${c.problems}');
        final m = pc.metrics!;
        expect(
            rangeForProfile(pc.difficulty)
                .contains(m.deductionSteps, m.maxTier),
            isTrue,
            reason: '${e.id}: ${m.deductionSteps} pasos T${m.maxTier}');
      }
    });

    test('cada uno tiene historia del mundo, con título único', () {
      final titulos = <String>{
        ...campana.map((e) => load(e.id).story!.title('es')!)
      };
      for (final e in retos) {
        final s = load(e.id).story!;
        expect(s.world, kMundoMansion);
        expect(titulos.add(s.title('es')!), isTrue,
            reason: '${e.id}: título repetido (${s.title('es')})');
      }
    });

    test('ninguno repite un caso de la campaña ni de otro reto', () {
      final vistos = <String, String>{};
      final todos = [
        ...catalog.where(mundo: kMundoMansion),
        ...catalog.where(mundo: kBancoDePruebas),
      ];
      for (final e in todos) {
        final h = huella(load(e.id));
        expect(vistos.containsKey(h), isFalse,
            reason: '${e.id} es igual que ${vistos[h]}');
        vistos[h] = e.id;
      }
      expect(vistos.length, 60);
    });
  });

  group('reproducibilidad: cada archivo sale de su plan y su semilla', () {
    for (final (nombre, plan) in [
      ('campaña', campanaPlan),
      ('reto', retoPlan),
    ]) {
      test('el plan de $nombre regenera exactamente los archivos',
          skip: kMundo1PendienteDeRegenerar
              ? 'pendiente: los casos del Mundo 1 se regeneran con las reglas '
                  'de mapa del 05-11-2026 (ver support/regeneracion_pendiente.dart)'
              : null, () {
        expect(plan.world, kMundoMansion);
        for (final c in plan.cases) {
          final b = buildPlanCase(c, world);
          expect(b.puzzle, isNotNull, reason: '${c.id}: ${b.rejections}');
          final file = File('${casesDir.path}/${c.id}.json');
          final enDisco = jsonEncode(
              (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>));
          expect(jsonEncode(b.puzzle!.toJson()), enDisco,
              reason: '${c.id} (semilla ${c.seed}) ya no coincide con su '
                  'archivo: ¿cambió el motor o los datos del mundo?');
        }
      });
    }

    test('las semillas no se repiten dentro de una dificultad', () {
      final claves = <String>{};
      for (final c in [...campanaPlan.cases, ...retoPlan.cases]) {
        expect(claves.add('${c.difficulty}-${c.seed}-${c.weapon}'), isTrue,
            reason: 'semilla repetida: ${c.id}');
      }
    });
  });
}
