// Casos pequeños sobre la cabaña para las pruebas de la puerta de contenido,
// los rangos y los topes del solver. No es una prueba (no termina en _test).
import 'package:enigmatrix_engine/enigmatrix_engine.dart';

/// c1 Adela en 1 (Salón, alfombra) · c2 Bruno en 4 (Salón, silla)
/// c3 Clara en 10 (Estudio) · c4 Dario en 15 (Estudio, alfombra) — víctima.
PuzzleCase cabanaCase(List<Clue> clues, {String caseId = 'test'}) =>
    PuzzleCase(
      caseId: caseId,
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

/// Pistas de mueble que fijan el caso por completo: solución única y
/// deducción pura.
const cabanaPin = <Clue>[
  CompoundClue(
      'c1', [InArea('c1', 'salon'), OnObjectGroup('c1', 'alfombra')]),
  OnObjectGroup('c2', 'silla'),
  BesideObjectGroup('c3', 'tv'),
  CompoundClue(
      'c4', [InArea('c4', 'estudio'), OnObjectGroup('c4', 'alfombra')]),
];

/// Solo pistas de área: deja 2 o más soluciones y la deducción se atasca.
const cabanaAreaOnly = <Clue>[
  InArea('c1', 'salon'),
  InArea('c2', 'salon'),
  InArea('c3', 'estudio'),
  InArea('c4', 'estudio'),
];
