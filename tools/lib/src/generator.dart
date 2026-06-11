/// Generador procedural de casos (spec 16, sección 6.3).
/// Entrada: mapa autorado + perfil de dificultad + semilla.
/// Salida: caso candidato validado (única solución, deducción pura).
library;

import 'dart:math';

import 'clue.dart';
import 'deduction.dart';
import 'model.dart';
import 'puzzle_case.dart';
import 'uniqueness.dart';
import 'validator.dart';

class DifficultyProfile {
  final String label;
  final bool Function(Clue) allowClue;
  final int minClues;
  final int maxClues;

  const DifficultyProfile({
    required this.label,
    required this.allowClue,
    required this.minClues,
    required this.maxClues,
  });

  /// Perfiles V1. Nota de diseño: TODOS los perfiles permiten pistas a nivel
  /// de celda (junto a, fila/columna, esquina) porque con pistas solo de
  /// área la unicidad es imposible: intercambiar dos personas de la misma
  /// área produce siempre una segunda solución válida (víctima y asesino
  /// comparten área SIEMPRE). Ver docs/16-spec-puzzle.md sección 3.2.
  static final principiante = DifficultyProfile(
    label: 'principiante',
    minClues: 4,
    maxClues: 6,
    allowClue: (c) =>
        c is InArea ||
        c is NotInArea ||
        c is SameArea ||
        c is BesideChar ||
        c is BesideObject ||
        c is CornerClue ||
        c is InRow ||
        c is InCol,
  );

  // Rangos recalibrados con datos reales del generador (Fase 0): el conjunto
  // irreducible de un 5×5 ronda 8-9 pistas y el de un 6×6 ronda 10-12.
  // Los rangos del doc 05 (5-7 / 7-9) quedaron cortos; ver spec 16 §3.2.
  static final casual = DifficultyProfile(
    label: 'casual',
    minClues: 7,
    maxClues: 10,
    allowClue: (_) => true,
  );

  static final intermedio = DifficultyProfile(
    label: 'intermedio',
    minClues: 9,
    maxClues: 13,
    allowClue: (_) => true,
  );

  static DifficultyProfile byLabel(String label) => switch (label) {
        'principiante' => principiante,
        'casual' => casual,
        'intermedio' => intermedio,
        _ => throw ArgumentError('Perfil desconocido: $label'),
      };
}

class GenerationResult {
  final PuzzleCase? puzzle;
  final int attempts;
  final Map<String, int> rejections;
  final bool clueCountInRange;

  const GenerationResult({
    required this.puzzle,
    required this.attempts,
    required this.rejections,
    required this.clueCountInRange,
  });
}

const _namePool = [
  'Adela', 'Bruno', 'Clara', 'Dario', 'Elena', 'Franco', 'Greta', 'Hugo',
];

class Generator {
  final GameMap map;
  final DifficultyProfile profile;
  final bool withWeapon;
  final int maxAttempts;

  Generator(
    this.map,
    this.profile, {
    this.withWeapon = false,
    this.maxAttempts = 200,
  }) {
    if (map.size > _namePool.length) {
      throw ArgumentError('Mapa demasiado grande para el pool de nombres');
    }
    if (withWeapon && map.weapons.isEmpty) {
      throw ArgumentError('El mapa ${map.id} no tiene armas definidas');
    }
  }

  GenerationResult generate(int seed) {
    final rng = Random(seed);
    final rejections = <String, int>{};
    void reject(String reason) =>
        rejections.update(reason, (v) => v + 1, ifAbsent: () => 1);

    PuzzleCase? bestEffort;
    var bestDistance = 1 << 30;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final candidate = _attempt(rng, seed, reject);
      if (candidate == null) continue;

      final count = candidate.clues.length;
      final inRange = count >= profile.minClues && count <= profile.maxClues;
      if (inRange) {
        return GenerationResult(
          puzzle: candidate,
          attempts: attempt,
          rejections: rejections,
          clueCountInRange: true,
        );
      }
      final distance = count < profile.minClues
          ? profile.minClues - count
          : count - profile.maxClues;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestEffort = candidate;
      }
      reject('pistas fuera de rango ($count)');
    }

    return GenerationResult(
      puzzle: bestEffort,
      attempts: maxAttempts,
      rejections: rejections,
      clueCountInRange: false,
    );
  }

  PuzzleCase? _attempt(Random rng, int seed, void Function(String) reject) {
    final n = map.size;
    final characters = [
      for (var i = 0; i < n; i++)
        Character(id: 'c${i + 1}', nameEs: _namePool[i]),
    ];

    // 1. Posiciones: una persona por fila y por columna, celdas ocupables.
    final cols = List<int>.generate(n, (i) => i)..shuffle(rng);
    final cells = [for (var r = 0; r < n; r++) map.cellAt(r, cols[r])];
    if (cells.any((c) => !map.isOccupiable(c))) {
      reject('celda bloqueada en el sorteo');
      return null;
    }
    final positions = {
      for (var i = 0; i < n; i++) characters[i].id: cells[i],
    };

    // 2. Pareja víctima-asesino: un área con exactamente 2 ocupantes
    //    (y con arma disponible si el caso lleva arma).
    final occupants = <String, List<String>>{};
    for (final e in positions.entries) {
      occupants.putIfAbsent(map.areaIdOf(e.value), () => []).add(e.key);
    }
    final pairAreas = [
      for (final e in occupants.entries)
        if (e.value.length == 2 &&
            (!withWeapon || map.weaponsInArea(e.key).isNotEmpty))
          e.key
    ]..sort();
    if (pairAreas.isEmpty) {
      reject('sin pareja víctima-asesino viable');
      return null;
    }
    final pairArea = pairAreas[rng.nextInt(pairAreas.length)];
    final pair = occupants[pairArea]!;
    final victimId = pair[rng.nextInt(2)];
    final murdererId = pair.firstWhere((id) => id != victimId);

    WeaponDef? lethal;
    if (withWeapon) {
      final options = map.weaponsInArea(pairArea);
      lethal = options[rng.nextInt(options.length)];
    }

    // 3. Pool de pistas verdaderas.
    final pool = _buildPool(characters, positions, victimId, lethal)
        .where(profile.allowClue)
        .toList();

    final base = PuzzleCase(
      caseId: '${map.id}-${profile.label}-s$seed',
      map: map,
      characters: characters,
      victimId: victimId,
      clues: pool,
      hasWeapon: withWeapon,
      difficulty: profile.label,
      solution: Solution(
        positions: positions,
        murdererId: murdererId,
        lethalWeaponId: lethal?.id,
      ),
    );

    // Sanidad: el pool completo (incluye fila+columna de cada personaje)
    // debe resolverse por deducción pura.
    if (DeductionEngine(base).run().status != DeductionStatus.solved) {
      reject('pool completo no deducible (revisar motor)');
      return null;
    }

    // 4. Minimización: intenta quitar primero las pistas más directas;
    //    sobreviven solo las necesarias (conjunto irreducible).
    final order = pool.toList()
      ..shuffle(rng)
      ..sort((a, b) => _directness(b).compareTo(_directness(a)));
    var kept = pool.toList();
    for (final clue in order) {
      if (kept.length <= 2) break;
      final tentative = [for (final c in kept) if (!identical(c, clue)) c];
      final result = DeductionEngine(_withClues(base, tentative)).run();
      if (result.status == DeductionStatus.solved) kept = tentative;
    }

    var candidate = _withClues(base, kept);

    // 5. Arma deducible de forma única (si el conjunto quedó ambiguo,
    //    se añade la pista de arma menos reveladora que la distinga).
    if (withWeapon &&
        !Validator.validate(candidate, positions).valid) {
      final inArea = map.weaponsInArea(pairArea);
      final byCat =
          inArea.where((w) => w.category == lethal!.category).length;
      final fix = byCat == 1
          ? WeaponCat(lethal!.category)
          : WeaponExact(lethal!.id);
      candidate = _withClues(candidate, [...kept, fix]);
    }

    // 6. Verificación final: validador + deducción pura + unicidad real.
    if (!Validator.validate(candidate, positions).valid) {
      reject('validación final fallida');
      return null;
    }
    final deduction = DeductionEngine(candidate).run();
    if (deduction.status != DeductionStatus.solved) {
      reject('caso final no deducible');
      return null;
    }
    if (UniquenessChecker.countSolutions(candidate) != 1) {
      reject('solución no única (revisar motor)');
      return null;
    }

    return PuzzleCase(
      caseId: candidate.caseId,
      map: map,
      characters: characters,
      victimId: victimId,
      clues: candidate.clues,
      hasWeapon: withWeapon,
      difficulty: profile.label,
      solution: candidate.solution,
      metrics: CaseMetrics(
        deductionSteps: deduction.deductionSteps,
        maxTier: deduction.maxTier,
        clueCount: candidate.clues.length,
      ),
    );
  }

  PuzzleCase _withClues(PuzzleCase pc, List<Clue> clues) => PuzzleCase(
        caseId: pc.caseId,
        map: pc.map,
        characters: pc.characters,
        victimId: pc.victimId,
        clues: clues,
        hasWeapon: pc.hasWeapon,
        difficulty: pc.difficulty,
        solution: pc.solution,
      );

  /// Cuanto más directa la pista, antes se intenta eliminar (las difíciles
  /// de reemplazar sobreviven y el caso queda más deductivo).
  int _directness(Clue c) => switch (c) {
        InRow() || InCol() => 6,
        InArea() => 5,
        WeaponInArea() || WeaponCat() || WeaponExact() => 5,
        CornerClue(:final areaId) => areaId != null ? 4 : 1,
        BesideObject() => 4,
        AloneWith() || BesideChar() || SameArea() => 3,
        Alone() || AreaEmpty() || Cardinal() => 2,
        NotInArea() || NotSameArea() => 1,
      };

  List<Clue> _buildPool(
    List<Character> characters,
    Map<String, int> positions,
    String victimId,
    WeaponDef? lethal,
  ) {
    final pool = <Clue>[];
    final occupantsByArea = <String, List<String>>{};
    for (final e in positions.entries) {
      occupantsByArea.putIfAbsent(map.areaIdOf(e.value), () => []).add(e.key);
    }

    for (final ch in characters) {
      final p = positions[ch.id]!;
      final areaId = map.areaIdOf(p);
      pool.add(InArea(ch.id, areaId));
      for (final a in map.areas) {
        if (a.id != areaId) pool.add(NotInArea(ch.id, a.id));
      }
      pool.add(InRow(ch.id, map.row(p)));
      pool.add(InCol(ch.id, map.col(p)));
      if (map.isCorner(p)) {
        pool.add(CornerClue(ch.id, areaId));
        pool.add(CornerClue(ch.id, null));
      }
      for (final obj in map.objects) {
        if (map.sameArea(p, obj.cell) &&
            map.orthNeighbors(obj.cell).contains(p)) {
          pool.add(BesideObject(ch.id, obj.id));
        }
      }
      if (occupantsByArea[areaId]!.length == 1) pool.add(Alone(ch.id));
    }

    for (var i = 0; i < characters.length; i++) {
      for (var j = i + 1; j < characters.length; j++) {
        final a = characters[i].id, b = characters[j].id;
        final pa = positions[a]!, pb = positions[b]!;
        if (map.sameArea(pa, pb)) {
          pool.add(SameArea(a, b));
          // "A solas con la víctima" delata al asesino: fuera del pool V1.
          if (a != victimId &&
              b != victimId &&
              occupantsByArea[map.areaIdOf(pa)]!.length == 2) {
            pool.add(AloneWith(a, b));
          }
        } else {
          pool.add(NotSameArea(a, b));
        }
        if (map.besideInArea(pa, pb)) pool.add(BesideChar(a, b));
        pool.add(map.col(pa) < map.col(pb)
            ? Cardinal(a, b, Direction.west)
            : Cardinal(a, b, Direction.east));
        pool.add(map.row(pa) < map.row(pb)
            ? Cardinal(a, b, Direction.north)
            : Cardinal(a, b, Direction.south));
      }
    }

    for (final a in map.areas) {
      if (!occupantsByArea.containsKey(a.id)) pool.add(AreaEmpty(a.id));
    }

    if (lethal != null) {
      pool.add(WeaponInArea(lethal.areaId));
      pool.add(WeaponCat(lethal.category));
      pool.add(WeaponExact(lethal.id));
    }

    return pool;
  }
}
