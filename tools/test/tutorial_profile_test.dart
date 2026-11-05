import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Perfil tutorial (5×5)', () {
    test('byLabel devuelve el perfil: 5×5, sin extras ni vagas', () {
      final p = DifficultyProfile.byLabel('tutorial');
      expect(p.label, 'tutorial');
      expect(p.size, 5);
      expect(p.maxExtras, 0);
      expect(p.allowVague, isFalse);
    });

    test('genera casos válidos, únicos y de deducción pura (semillas 1-20)',
        () {
      final f = CaseFactory(DifficultyProfile.tutorial);
      for (var seed = 1; seed <= 20; seed++) {
        final result = f.generate(seed);
        final pc = result.puzzle;
        expect(pc, isNotNull,
            reason: 'semilla $seed sin caso: ${result.rejections}');
        expect(pc!.characters.length, 5);
        expect(pc.map.size, 5);
        expect(pc.hasWeapon, isFalse);
        expect(pc.extraClues, isEmpty);
        expect(pc.clues.length, 5);
        expect(Validator.validate(pc, pc.solution.positions).valid, isTrue);
        expect(DeductionEngine(pc).run().status, DeductionStatus.solved,
            reason: 'semilla $seed');
        expect(UniquenessChecker.countSolutions(pc), 1,
            reason: 'semilla $seed');
      }
    });

    test('determinismo: misma semilla, mismo caso', () {
      final f = CaseFactory(DifficultyProfile.tutorial);
      expect(jsonEncode(f.generate(192).puzzle!.toJson()),
          jsonEncode(f.generate(192).puzzle!.toJson()));
    });
  });

  group('caso-tutorial.json', () {
    final file = File('../app/assets/tutorial/caso-tutorial.json');

    test('pasa el validador: única, deducción pura, sin filtrar solución', () {
      final pc = PuzzleCase.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
      expect(pc.caseId, 'tutorial');
      expect(pc.map.size, 5);
      expect(pc.characters.length, 5);
      expect(pc.hasWeapon, isFalse);
      expect(Validator.validate(pc, pc.solution.positions).valid, isTrue);
      final d = DeductionEngine(pc).run();
      expect(d.status, DeductionStatus.solved);
      // Enseña la X: exige al menos un paso de exclusión fila/columna.
      expect(d.steps.any((s) => s.technique == 'exclusión fila/columna'),
          isTrue);
      expect(d.maxTier, lessThanOrEqualTo(2));
      expect(UniquenessChecker.countSolutions(pc), 1);
      final client = pc.toClientJson();
      expect(client.containsKey('solution'), isFalse);
    });

    test('no figura en el índice de casos', () {
      final index = jsonDecode(
          File('../app/assets/cases/index.json').readAsStringSync()) as List;
      expect(index.any((e) => e.toString().contains('tutorial')), isFalse);
    });
  });
}
