import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Generator (formato Murdoku: una pista por tarjeta)', () {
    test('determinismo: misma semilla, mismo caso', () {
      final g = Generator(cabana, DifficultyProfile.principiante);
      final a = g.generate(7).puzzle!;
      final b = g.generate(7).puzzle!;
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    });

    test('semillas distintas: variedad de casos', () {
      // En un 4×4 hay pocas distribuciones válidas: dos semillas pueden
      // coincidir en posiciones. Exigimos variedad en el lote, no en pares.
      final g = Generator(cabana, DifficultyProfile.principiante);
      final solutions = {
        for (var seed = 1; seed <= 6; seed++)
          jsonEncode(g.generate(seed).puzzle!.solution.toJson())
      };
      final clueSets = {
        for (var seed = 1; seed <= 6; seed++)
          jsonEncode(
              [for (final c in g.generate(seed).puzzle!.clues) c.toJson()])
      };
      expect(solutions.length, greaterThanOrEqualTo(3));
      expect(clueSets.length, greaterThanOrEqualTo(4));
    });

    for (final (label, map) in [
      ('principiante', cabana),
      ('casual', mansion),
      ('intermedio', hotel),
    ]) {
      test('$label: lote de casos válidos, únicos y de deducción pura', () {
        final profile = DifficultyProfile.byLabel(label);
        final g = Generator(map, profile);
        for (var seed = 1; seed <= 5; seed++) {
          final result = g.generate(seed);
          final pc = result.puzzle;
          expect(pc, isNotNull,
              reason: 'semilla $seed sin caso: ${result.rejections}');

          // Formato Murdoku: exactamente una pista por personaje.
          for (final ch in pc!.characters) {
            final card = pc.clues.where((c) => c.subjectId == ch.id);
            expect(card.length, 1,
                reason: 'semilla $seed: ${ch.id} tiene ${card.length} pistas');
          }
          expect(pc.extraClues.length, lessThanOrEqualTo(profile.maxExtras),
              reason: 'semilla $seed: demasiadas pistas extra');

          final v = Validator.validate(pc, pc.solution.positions);
          expect(v.valid, isTrue, reason: 'semilla $seed: ${v.errors}');
          expect(v.murdererId, pc.solution.murdererId);

          final d = DeductionEngine(pc).run();
          expect(d.status, DeductionStatus.solved,
              reason: 'semilla $seed no es de deducción pura');
          expect(d.assignment, pc.solution.positions);

          expect(UniquenessChecker.countSolutions(pc), 1,
              reason: 'semilla $seed sin solución única');
        }
      });
    }

    test('caso con arma en casual (sin extras): el área de la pareja tiene '
        'una sola arma y queda deducible', () {
      final g = Generator(mansion, DifficultyProfile.casual, withWeapon: true);
      final result = g.generate(11);
      final pc = result.puzzle!;
      expect(pc.hasWeapon, isTrue);
      expect(pc.extraClues.whereType<WeaponInArea>(), isEmpty);
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isTrue, reason: v.errors.join('; '));
      expect(v.lethalWeaponId, pc.solution.lethalWeaponId);
    });

    test('REGLA DE ORO: el payload del cliente no contiene la solución', () {
      final pc = Generator(cabana, DifficultyProfile.principiante)
          .generate(1)
          .puzzle!;
      final client = pc.toClientJson();
      expect(client.containsKey('solution'), isFalse);
      expect(client.containsKey('metrics'), isFalse);
      expect(jsonEncode(client), isNot(contains('murderer')));
      expect(jsonEncode(client), isNot(contains('lethal')));
    });

    test('las pistas generadas son del vocabulario Murdoku (sin mecánicas)',
        () {
      for (var seed = 1; seed <= 6; seed++) {
        final pc = Generator(mansion, DifficultyProfile.casual)
            .generate(seed)
            .puzzle!;
        for (final clue in pc.clues) {
          // El switch sellado garantiza que solo existen estos tipos;
          // verificamos que las tarjetas tengan sujeto.
          if (clue is AreaEmpty ||
              clue is WeaponInArea ||
              clue is WeaponCat ||
              clue is WeaponExact) {
            continue;
          }
          expect(clue.subjectId, isNotNull);
        }
      }
    });

    test('el relleno de la víctima aparece cuando el caso lo permite', () {
      var fillers = 0;
      for (var seed = 1; seed <= 10; seed++) {
        final pc = Generator(cabana, DifficultyProfile.principiante)
            .generate(seed)
            .puzzle!;
        if (pc.clueFor(pc.victimId) is LastFreeCell) fillers++;
      }
      // No exigimos un número exacto (depende del sorteo), pero el momento
      // "última casilla libre" debe existir en el contenido generado.
      expect(fillers, greaterThan(0));
    });
  });

  group('CaseFactory (mapa único por caso, tamaños Murdoku)', () {
    test('determinismo: misma semilla, mismo caso con mismo mapa', () {
      final f = CaseFactory(DifficultyProfile.principiante);
      expect(jsonEncode(f.generate(3).puzzle!.toJson()),
          jsonEncode(f.generate(3).puzzle!.toJson()));
    });

    test('cada caso tiene SU mapa: habitaciones distintas entre semillas', () {
      final f = CaseFactory(DifficultyProfile.principiante);
      final layouts = {
        for (var seed = 1; seed <= 4; seed++)
          jsonEncode(
              [for (final a in f.generate(seed).puzzle!.map.areas) a.cells])
      };
      expect(layouts.length, 4);
    });

    test('JSON con mapa embebido: ida y vuelta completa', () {
      final pc =
          CaseFactory(DifficultyProfile.principiante).generate(5).puzzle!;
      final back = PuzzleCase.fromJson(pc.toJson());
      expect(jsonEncode(back.toJson()), jsonEncode(pc.toJson()));
      // El payload del cliente también lleva el mapa (sin solución).
      final client = pc.toClientJson();
      expect(client['map'], isNotNull);
      expect(client.containsKey('solution'), isFalse);
    });

    for (final (label, seeds) in [
      ('principiante', 3),
      ('casual', 2),
      ('intermedio', 2),
    ]) {
      test('$label (${DifficultyProfile.byLabel(label).size}×'
          '${DifficultyProfile.byLabel(label).size}): casos válidos y únicos',
          () {
        final profile = DifficultyProfile.byLabel(label);
        final f = CaseFactory(profile);
        for (var seed = 1; seed <= seeds; seed++) {
          final result = f.generate(seed);
          final pc = result.puzzle;
          expect(pc, isNotNull,
              reason: 'semilla $seed sin caso: ${result.rejections}');
          expect(pc!.map.size, profile.size);
          expect(pc.characters.length, profile.size);
          for (final ch in pc.characters) {
            expect(pc.clues.where((c) => c.subjectId == ch.id).length, 1);
          }
          final v = Validator.validate(pc, pc.solution.positions);
          expect(v.valid, isTrue, reason: 'semilla $seed: ${v.errors}');
          expect(DeductionEngine(pc).run().status, DeductionStatus.solved);
          expect(UniquenessChecker.countSolutions(pc), 1);
        }
      });
    }

    test('con arma: el área del crimen tiene una sola arma (casual)', () {
      final f = CaseFactory(DifficultyProfile.casual, withWeapon: true);
      final pc = f.generate(7).puzzle!;
      expect(pc.hasWeapon, isTrue);
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isTrue, reason: v.errors.join('; '));
      expect(v.lethalWeaponId, pc.solution.lethalWeaponId);
    });
  });
}
