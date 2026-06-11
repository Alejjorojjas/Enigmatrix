import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Generator', () {
    test('determinismo: misma semilla, mismo caso', () {
      final g = Generator(cabana, DifficultyProfile.principiante);
      final a = g.generate(7).puzzle!;
      final b = g.generate(7).puzzle!;
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    });

    test('semillas distintas: casos distintos', () {
      final g = Generator(cabana, DifficultyProfile.principiante);
      final a = g.generate(1).puzzle!;
      final b = g.generate(2).puzzle!;
      expect(jsonEncode(a.solution.toJson()),
          isNot(jsonEncode(b.solution.toJson())));
    });

    for (final (label, map) in [
      ('principiante', cabana),
      ('casual', mansion),
      ('intermedio', hotel),
    ]) {
      test('$label: lote de casos válidos, únicos y de deducción pura', () {
        final g = Generator(map, DifficultyProfile.byLabel(label));
        for (var seed = 1; seed <= 5; seed++) {
          final result = g.generate(seed);
          final pc = result.puzzle;
          expect(pc, isNotNull, reason: 'semilla $seed sin caso');

          final v = Validator.validate(pc!, pc.solution.positions);
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

    test('caso con arma: el arma queda deducible de forma única', () {
      final g = Generator(mansion, DifficultyProfile.casual, withWeapon: true);
      final pc = g.generate(11).puzzle!;
      expect(pc.hasWeapon, isTrue);
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

    test('conjunto de pistas irreducible: quitar cualquiera rompe la deducción',
        () {
      final pc = Generator(mansion, DifficultyProfile.casual)
          .generate(3)
          .puzzle!;
      for (var i = 0; i < pc.clues.length; i++) {
        final reduced = PuzzleCase(
          caseId: pc.caseId,
          map: pc.map,
          characters: pc.characters,
          victimId: pc.victimId,
          clues: [
            for (var j = 0; j < pc.clues.length; j++)
              if (j != i) pc.clues[j]
          ],
          hasWeapon: pc.hasWeapon,
          difficulty: pc.difficulty,
          solution: pc.solution,
        );
        expect(DeductionEngine(reduced).run().status,
            isNot(DeductionStatus.solved),
            reason: 'la pista ${pc.clues[i].toJson()} sobra');
      }
    });
  });
}
