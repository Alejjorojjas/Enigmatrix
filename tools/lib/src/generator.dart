/// Generador procedural de casos — formato Murdoku (decidido 2026-06-11):
/// UNA pista por personaje (tarjeta) + extras sueltas solo en dificultades
/// altas. Vocabulario: áreas, muebles y personas; sin pistas mecánicas.
///
/// Algoritmo por intento:
///   1. Sortea posiciones (una por fila/columna) y pareja víctima-asesino.
///   2. Construye pistas candidatas VERDADERAS por personaje.
///   3. Elige una por personaje (la víctima intenta primero el relleno
///      "última casilla libre") y repara: si la deducción se atasca,
///      endurece la pista del personaje más ambiguo.
///   4. Pule (¿puede la víctima quedar con relleno?), valida arma única,
///      verifica deducción pura y unicidad real.
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

  /// Tamaño de grilla (= número de personajes). Mapeo Murdoku,
  /// decidido 2026-06-11: 6 · 8 · 9 · 12 · 16.
  final int size;

  /// Permite pistas vagas ("no estaba con...").
  final bool allowVague;

  /// Pistas sueltas adicionales permitidas (área vacía / arma).
  final int maxExtras;

  const DifficultyProfile({
    required this.label,
    required this.size,
    required this.allowVague,
    required this.maxExtras,
  });

  static const principiante = DifficultyProfile(
      label: 'principiante', size: 6, allowVague: false, maxExtras: 0);
  static const casual = DifficultyProfile(
      label: 'casual', size: 8, allowVague: true, maxExtras: 0);
  static const intermedio = DifficultyProfile(
      label: 'intermedio', size: 9, allowVague: true, maxExtras: 2);
  static const experto = DifficultyProfile(
      label: 'experto', size: 12, allowVague: true, maxExtras: 2);
  static const elite = DifficultyProfile(
      label: 'elite', size: 16, allowVague: true, maxExtras: 3);

  static DifficultyProfile byLabel(String label) => switch (label) {
        'principiante' => principiante,
        'casual' => casual,
        'intermedio' => intermedio,
        'experto' => experto,
        'elite' => elite,
        _ => throw ArgumentError('Perfil desconocido: $label'),
      };
}

class GenerationResult {
  final PuzzleCase? puzzle;
  final int attempts;
  final Map<String, int> rejections;
  final int extrasUsed;

  const GenerationResult({
    required this.puzzle,
    required this.attempts,
    required this.rejections,
    required this.extrasUsed,
  });
}

/// (nombre, género femenino) — iniciales únicas A-P, alternados.
const _namePool = [
  ('Adela', true),
  ('Bruno', false),
  ('Clara', true),
  ('Dario', false),
  ('Elena', true),
  ('Franco', false),
  ('Greta', true),
  ('Hugo', false),
  ('Irene', true),
  ('Javier', false),
  ('Karla', true),
  ('Lucas', false),
  ('Marta', true),
  ('Nico', false),
  ('Olivia', true),
  ('Pablo', false),
];

/// Pista candidata para una tarjeta, con su poder de poda estimado.
class _Cand {
  final Clue clue;

  /// Celdas permitidas para el sujeto (null si es relacional).
  final Set<int>? allowed;

  /// Tamaño efectivo para ordenar por fuerza (menor = más fuerte).
  final int strength;

  /// Preferencia narrativa (mayor = más sabrosa).
  final double flavor;

  const _Cand(this.clue, this.allowed, this.strength, this.flavor);
}

class Generator {
  final GameMap map;
  final DifficultyProfile profile;
  final bool withWeapon;
  final int maxAttempts;

  /// Identificador del caso (por defecto derivado del mapa y la semilla).
  final String? caseIdOverride;

  Generator(
    this.map,
    this.profile, {
    this.withWeapon = false,
    this.maxAttempts = 300,
    this.caseIdOverride,
  }) {
    if (map.size > _namePool.length) {
      throw ArgumentError('Mapa demasiado grande para el pool de nombres');
    }
    if (withWeapon && map.weapons.isEmpty) {
      throw ArgumentError('El mapa ${map.id} no tiene armas definidas');
    }
  }

  GenerationResult generate(int seed) => generateWith(Random(seed), seed);

  GenerationResult generateWith(Random rng, int seed) {
    final rejections = <String, int>{};
    void reject(String reason) =>
        rejections.update(reason, (v) => v + 1, ifAbsent: () => 1);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final pc = _attempt(rng, seed, reject);
      if (pc != null) {
        return GenerationResult(
          puzzle: pc,
          attempts: attempt,
          rejections: rejections,
          extrasUsed: pc.extraClues.length,
        );
      }
    }
    return GenerationResult(
        puzzle: null,
        attempts: maxAttempts,
        rejections: rejections,
        extrasUsed: 0);
  }

  PuzzleCase? _attempt(Random rng, int seed, void Function(String) reject) {
    final n = map.size;
    final characters = [
      for (var i = 0; i < n; i++)
        Character(
            id: 'c${i + 1}',
            nameEs: _namePool[i].$1,
            female: _namePool[i].$2),
    ];

    // 1. Posiciones: una persona por fila y por columna, solo celdas
    //    ocupables. Sorteo con backtracking para que los muebles
    //    bloqueantes no desperdicien intentos.
    final cols = _samplePermutation(rng);
    if (cols == null) {
      reject('mapa sin permutación ocupable');
      return null;
    }
    final cells = [for (var r = 0; r < n; r++) map.cellAt(r, cols[r])];
    final positions = {for (var i = 0; i < n; i++) characters[i].id: cells[i]};

    // 2. Pareja víctima-asesino: un área con exactamente 2 ocupantes.
    //    Con arma y sin presupuesto de extras, el área debe tener UNA sola
    //    arma (para que sea deducible sin pista de arma).
    final occupants = <String, List<String>>{};
    for (final e in positions.entries) {
      occupants.putIfAbsent(map.areaIdOf(e.value), () => []).add(e.key);
    }
    final pairAreas = [
      for (final e in occupants.entries)
        if (e.value.length == 2 &&
            (!withWeapon ||
                (profile.maxExtras > 0
                    ? map.weaponsInArea(e.key).isNotEmpty
                    : map.weaponsInArea(e.key).length == 1)))
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

    final solution = Solution(
      positions: positions,
      murdererId: murdererId,
      lethalWeaponId: lethal?.id,
    );

    // 3. Candidatas por personaje, ordenadas por fuerza (menor dominio
    //    permitido = más fuerte). La selección inicial prefiere sabor.
    final candsByChar = <String, List<_Cand>>{
      for (final ch in characters)
        ch.id: _candidatesFor(ch.id, characters, positions, victimId,
            murdererId, occupants, rng)
    };
    for (final list in candsByChar.values) {
      if (list.isEmpty) {
        reject('personaje sin pistas candidatas');
        return null;
      }
      list.sort((a, b) => a.strength.compareTo(b.strength));
    }

    // Selección inicial: con sabor, no con fuerza. La víctima arranca con
    // el relleno (decisión 2026-06-11: relleno si se puede).
    final selection = <String, _Cand>{};
    for (final ch in characters) {
      if (ch.id == victimId) {
        selection[ch.id] = _Cand(
            LastFreeCell(victimId), null, 1 << 20, 0); // sin información
        continue;
      }
      final byFlavor = [...candsByChar[ch.id]!]..sort((a, b) =>
          (b.flavor + rng.nextDouble()).compareTo(a.flavor + rng.nextDouble()));
      selection[ch.id] = byFlavor.first;
    }

    final extras = <Clue>[];
    final extrasPool = _extrasPool(occupants, lethal);

    PuzzleCase build() => PuzzleCase(
          caseId: caseIdOverride ?? '${map.id}-${profile.label}-s$seed',
          map: map,
          characters: characters,
          victimId: victimId,
          clues: [
            for (final ch in characters) selection[ch.id]!.clue,
            ...extras,
          ],
          hasWeapon: withWeapon,
          difficulty: profile.label,
          solution: solution,
        );

    // 4. Reparación: endurece la pista del personaje más ambiguo hasta que
    //    el caso se resuelva por deducción pura.
    DeductionResult result = DeductionEngine(build()).run();
    var repairs = 0;
    while (result.status != DeductionStatus.solved && repairs < 4 * n + 8) {
      repairs++;
      if (result.status == DeductionStatus.contradiction) {
        reject('contradicción inesperada (revisar motor)');
        return null;
      }
      final domains = result.stuckDomains!;
      // Personajes reparables, del dominio más grande al más chico.
      final fixable = [
        for (final ch in characters)
          if ((domains[ch.id]?.length ?? 0) > 1 &&
              _stronger(candsByChar[ch.id]!, selection[ch.id]!) != null)
            ch.id
      ]..sort(
          (a, b) => domains[b]!.length.compareTo(domains[a]!.length));
      if (fixable.isEmpty) {
        if (extras.length < profile.maxExtras && extrasPool.isNotEmpty) {
          extras.add(extrasPool.removeAt(rng.nextInt(extrasPool.length)));
        } else {
          reject('sin reparaciones posibles');
          return null;
        }
      } else {
        final chId = fixable.first;
        selection[chId] = _stronger(candsByChar[chId]!, selection[chId]!)!;
      }
      result = DeductionEngine(build()).run();
    }
    if (result.status != DeductionStatus.solved) {
      reject('reparación agotada');
      return null;
    }

    // 5. Pulido: si la víctima terminó con pista real, ¿puede volver al
    //    relleno? (momento "última casilla libre")
    if (selection[victimId]!.clue is! LastFreeCell) {
      final backup = selection[victimId]!;
      selection[victimId] = _Cand(LastFreeCell(victimId), null, 1 << 20, 0);
      if (DeductionEngine(build()).run().status != DeductionStatus.solved) {
        selection[victimId] = backup;
      }
    }

    var candidate = build();

    // 6. Arma deducible de forma única.
    if (withWeapon && !Validator.validate(candidate, positions).valid) {
      if (extras.length >= profile.maxExtras) {
        reject('arma ambigua sin presupuesto de extras');
        return null;
      }
      final inArea = map.weaponsInArea(pairArea);
      final byCat = inArea.where((w) => w.category == lethal!.category).length;
      extras.add(byCat == 1
          ? WeaponCat(lethal!.category)
          : WeaponExact(lethal!.id));
      candidate = build();
    }

    // 7. Verificación final: validador + deducción pura + unicidad real.
    if (!Validator.validate(candidate, positions).valid) {
      reject('validación final fallida');
      return null;
    }
    final deduction = DeductionEngine(candidate).run();
    if (deduction.status != DeductionStatus.solved ||
        !_samePositions(deduction.assignment!, positions)) {
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
      solution: solution,
      metrics: CaseMetrics(
        deductionSteps: deduction.deductionSteps,
        maxTier: deduction.maxTier,
        clueCount: candidate.clues.length,
      ),
    );
  }

  bool _samePositions(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// Permutación aleatoria fila->columna evitando celdas bloqueadas.
  List<int>? _samplePermutation(Random rng) {
    final n = map.size;
    final colsByRow = List<int>.filled(n, -1);
    final used = List<bool>.filled(n, false);
    bool place(int r) {
      if (r == n) return true;
      final options = [
        for (var c = 0; c < n; c++)
          if (!used[c] && map.isOccupiable(map.cellAt(r, c))) c
      ]..shuffle(rng);
      for (final c in options) {
        used[c] = true;
        colsByRow[r] = c;
        if (place(r + 1)) return true;
        used[c] = false;
      }
      return false;
    }

    return place(0) ? colsByRow : null;
  }

  /// Siguiente candidata estrictamente más fuerte que la actual.
  _Cand? _stronger(List<_Cand> sorted, _Cand current) {
    for (final c in sorted) {
      if (c.strength < current.strength) return c;
    }
    return null;
  }

  List<Clue> _extrasPool(
      Map<String, List<String>> occupants, WeaponDef? lethal) {
    final pool = <Clue>[
      for (final a in map.areas)
        if (!occupants.containsKey(a.id)) AreaEmpty(a.id),
    ];
    if (lethal != null) {
      pool.add(WeaponInArea(lethal.areaId));
      pool.add(WeaponCat(lethal.category));
    }
    return pool;
  }

  /// Pistas candidatas VERDADERAS para la tarjeta de un personaje.
  List<_Cand> _candidatesFor(
    String chId,
    List<Character> characters,
    Map<String, int> positions,
    String victimId,
    String murdererId,
    Map<String, List<String>> occupants,
    Random rng,
  ) {
    final pos = positions[chId]!;
    final areaId = map.areaIdOf(pos);
    final occupiableCount = map.occupiableCells.length;
    final cands = <_Cand>[];

    void addUnary(Clue clue, Set<int> allowed, double flavor) {
      final filtered = allowed.where(map.isOccupiable).toSet();
      if (filtered.isEmpty) return;
      cands.add(_Cand(clue, filtered, filtered.length, flavor));
    }

    // Área.
    final areaCells = Set.of(map.area(areaId).cells);
    addUnary(InArea(chId, areaId), areaCells, 2.5);

    // Sobre un mueble pisable.
    final on = map.objectAt(pos);
    if (on != null && on.type.standable) {
      final g = on.type.group;
      addUnary(OnObjectGroup(chId, g), map.cellsOnGroup(g), 5);
      // ¿Única persona sobre ese grupo? Solo aporta (y suena natural)
      // cuando hay varios muebles del grupo en el mapa.
      final othersOn = positions.entries
          .any((e) => e.key != chId && map.isOnGroup(e.value, g));
      if (!othersOn && map.countOfGroup(g) > 1) {
        addUnary(OnlyOneOnGroup(chId, g), map.cellsOnGroup(g), 6);
      }
    }

    // Junto a muebles.
    for (final g in map.objectGroups) {
      if (map.isBesideGroup(pos, g)) {
        addUnary(BesideObjectGroup(chId, g), map.cellsBesideGroup(g), 4.5);
      }
    }

    // Compuestas: combinaciones de 2 condiciones que reducen de verdad.
    final unaryCands = [
      for (final c in cands)
        if (c.clue is InArea ||
            c.clue is OnObjectGroup ||
            c.clue is BesideObjectGroup)
          c
    ];
    for (var i = 0; i < unaryCands.length; i++) {
      for (var j = i + 1; j < unaryCands.length; j++) {
        final a = unaryCands[i], b = unaryCands[j];
        final inter = a.allowed!.intersection(b.allowed!);
        if (inter.isNotEmpty &&
            inter.length < a.allowed!.length &&
            inter.length < b.allowed!.length) {
          cands.add(_Cand(
            CompoundClue(chId, [a.clue, b.clue]),
            inter,
            inter.length,
            5.5,
          ));
        }
      }
    }

    // Relaciones con otras personas. Nunca conectar víctima y asesino con
    // una relación de "misma área" (delataría al asesino).
    bool revealsPair(String other) =>
        (chId == victimId && other == murdererId) ||
        (chId == murdererId && other == victimId);
    for (final other in characters) {
      if (other.id == chId) continue;
      final otherPos = positions[other.id]!;
      final sameArea = map.sameArea(pos, otherPos);
      if (sameArea && !revealsPair(other.id)) {
        cands.add(_Cand(SameArea(chId, other.id), null,
            map.area(areaId).cells.length, 3));
        if (map.besideInArea(pos, otherPos)) {
          cands.add(_Cand(BesideChar(chId, other.id), null, 5, 4));
        }
        if (occupants[areaId]!.length == 2) {
          cands.add(_Cand(AloneWith(chId, other.id), null,
              map.area(areaId).cells.length, 3.5));
        }
      }
      if (!sameArea && profile.allowVague) {
        cands.add(_Cand(NotSameArea(chId, other.id), null,
            occupiableCount - 2, 1));
      }
    }

    // Solo en su área.
    if (occupants[areaId]!.length == 1) {
      cands.add(_Cand(Alone(chId), null, occupiableCount - 2, 2));
    }

    // Negativas de área (vagas).
    if (profile.allowVague) {
      for (final a in map.areas) {
        if (a.id == areaId) continue;
        addUnary(
            NotInArea(chId, a.id),
            {
              for (final c in map.occupiableCells)
                if (map.areaIdOf(c) != a.id) c
            },
            1);
      }
    }

    return cands;
  }
}
