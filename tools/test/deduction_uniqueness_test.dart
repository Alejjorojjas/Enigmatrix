import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

PuzzleCase makeCase(List<Clue> clues) => PuzzleCase(
      caseId: 'test',
      map: cabana,
      characters: const [
        Character(id: 'c1', nameEs: 'Adela'),
        Character(id: 'c2', nameEs: 'Bruno'),
        Character(id: 'c3', nameEs: 'Clara'),
        Character(id: 'c4', nameEs: 'Dario'),
      ],
      victimId: 'c4',
      clues: clues,
      hasWeapon: false,
      difficulty: 'test',
      solution: Solution(
        positions: {'c1': 0, 'c2': 5, 'c3': 10, 'c4': 15},
        murdererId: 'c3',
      ),
    );

/// Pistas que fijan cada personaje en su celda exacta (fila + columna).
const fullPin = <Clue>[
  InRow('c1', 0), InCol('c1', 0),
  InRow('c2', 1), InCol('c2', 1),
  InRow('c3', 2), InCol('c3', 2),
  InRow('c4', 3), InCol('c4', 3),
];

/// Pistas SOLO a nivel de área: no pueden distinguir el intercambio de dos
/// personas dentro de la misma área.
const areaOnly = <Clue>[
  InArea('c1', 'salon'),
  InArea('c2', 'salon'),
  InArea('c3', 'estudio'),
  InArea('c4', 'estudio'),
];

void main() {
  group('UniquenessChecker', () {
    test('pistas exactas: exactamente una solución', () {
      expect(UniquenessChecker.countSolutions(makeCase(fullPin)), 1);
    });

    test(
        'HALLAZGO DE DISEÑO: pistas solo de área SIEMPRE dejan ≥2 soluciones '
        '(la pareja víctima-asesino comparte área y es intercambiable)', () {
      expect(UniquenessChecker.countSolutions(makeCase(areaOnly), limit: 5),
          greaterThanOrEqualTo(2));
    });
  });

  group('DeductionEngine', () {
    test('caso con pistas exactas: resuelto, asignación correcta', () {
      final r = DeductionEngine(makeCase(fullPin)).run();
      expect(r.status, DeductionStatus.solved);
      expect(r.assignment, {'c1': 0, 'c2': 5, 'c3': 10, 'c4': 15});
      expect(r.deductionSteps, greaterThan(0));
    });

    test('caso ambiguo: se atasca (= requeriría adivinar, se rechaza)', () {
      final r = DeductionEngine(makeCase(areaOnly)).run();
      expect(r.status, DeductionStatus.stuck);
    });

    test('pistas contradictorias: contradicción detectada', () {
      final r = DeductionEngine(makeCase(const [
        InArea('c1', 'salon'),
        NotInArea('c1', 'salon'),
        ...fullPin,
      ])).run();
      expect(r.status, DeductionStatus.contradiction);
    });

    test('deducción indirecta: resuelve sin pistas de celda exacta del asesino',
        () {
      // Sin fila/columna de c3: su posición sale por descarte
      // (exclusión fila/columna + regla del asesino).
      final r = DeductionEngine(makeCase(const [
        InRow('c1', 0), InCol('c1', 0),
        InRow('c2', 1), InCol('c2', 1),
        InRow('c4', 3), InCol('c4', 3),
        InArea('c3', 'estudio'),
      ])).run();
      expect(r.status, DeductionStatus.solved);
      expect(r.assignment!['c3'], 10);
    });
  });
}
