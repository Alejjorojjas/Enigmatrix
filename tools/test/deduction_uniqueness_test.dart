import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

/// Fixture sobre la cabaña:
///   c1 Adela en 1 (Salón, alfombra) · c2 Bruno en 4 (Salón, silla)
///   c3 Clara en 10 (Estudio) · c4 Dario en 15 (Estudio, alfombra) — víctima
PuzzleCase makeCase(List<Clue> clues) => PuzzleCase(
      caseId: 'test',
      map: cabana,
      characters: const [
        Character(id: 'c1', nameEs: 'Adela', female: true),
        Character(id: 'c2', nameEs: 'Bruno', female: false),
        Character(id: 'c3', nameEs: 'Clara', female: true),
        Character(id: 'c4', nameEs: 'Dario', female: false),
      ],
      victimId: 'c4',
      clues: clues,
      hasWeapon: false,
      difficulty: 'test',
      solution: Solution(
        positions: {'c1': 1, 'c2': 4, 'c3': 10, 'c4': 15},
        murdererId: 'c3',
      ),
    );

/// Pistas de mueble que fijan el caso por completo (estilo Murdoku).
const murdokuPin = <Clue>[
  CompoundClue(
      'c1', [InArea('c1', 'salon'), OnObjectGroup('c1', 'alfombra')]),
  OnObjectGroup('c2', 'silla'),
  BesideObjectGroup('c3', 'tv'),
  CompoundClue(
      'c4', [InArea('c4', 'estudio'), OnObjectGroup('c4', 'alfombra')]),
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
    test('pistas de mueble bien puestas: exactamente una solución', () {
      expect(UniquenessChecker.countSolutions(makeCase(murdokuPin)), 1);
    });

    test(
        'HALLAZGO DE DISEÑO: pistas solo de área SIEMPRE dejan ≥2 soluciones '
        '(la pareja víctima-asesino comparte área y es intercambiable)', () {
      expect(UniquenessChecker.countSolutions(makeCase(areaOnly), limit: 5),
          greaterThanOrEqualTo(2));
    });
  });

  group('DeductionEngine', () {
    test('caso al estilo Murdoku: resuelto, asignación correcta', () {
      final r = DeductionEngine(makeCase(murdokuPin)).run();
      expect(r.status, DeductionStatus.solved);
      expect(r.assignment, {'c1': 1, 'c2': 4, 'c3': 10, 'c4': 15});
      expect(r.deductionSteps, greaterThan(0));
    });

    test('caso ambiguo: se atasca (= requeriría adivinar, se rechaza)', () {
      final r = DeductionEngine(makeCase(areaOnly)).run();
      expect(r.status, DeductionStatus.stuck);
      expect(r.stuckDomains, isNotNull);
      expect(r.stuckDomains!['c1']!.length, greaterThan(1));
    });

    test('pistas contradictorias: contradicción detectada', () {
      final r = DeductionEngine(makeCase(const [
        InArea('c1', 'salon'),
        NotInArea('c1', 'salon'),
        ...murdokuPin,
      ])).run();
      expect(r.status, DeductionStatus.contradiction);
    });

    test('deducción indirecta: sin pista de la asesina, sale por descarte '
        '(filas/columnas tachadas, como en el video)', () {
      final r = DeductionEngine(makeCase(const [
        CompoundClue(
            'c1', [InArea('c1', 'salon'), OnObjectGroup('c1', 'alfombra')]),
        OnObjectGroup('c2', 'silla'),
        CompoundClue(
            'c4', [InArea('c4', 'estudio'), OnObjectGroup('c4', 'alfombra')]),
      ])).run();
      expect(r.status, DeductionStatus.solved);
      expect(r.assignment!['c3'], 10);
    });

    test('"única persona sobre una alfombra" excluye a los demás del grupo',
        () {
      // c1 única sobre alfombra: c4 (también en alfombra en la solución
      // original) ahora debe estar en otra celda -> contradicción con el
      // resto del pin original.
      final r = DeductionEngine(makeCase(const [
        OnlyOneOnGroup('c1', 'alfombra'),
        OnObjectGroup('c2', 'silla'),
        BesideObjectGroup('c3', 'tv'),
        CompoundClue(
            'c4', [InArea('c4', 'estudio'), OnObjectGroup('c4', 'alfombra')]),
      ])).run();
      expect(r.status, DeductionStatus.contradiction);
    });
  });
}
