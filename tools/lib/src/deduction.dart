/// Motor de deducción: resuelve el caso como lo haría un jugador humano,
/// aplicando siempre la técnica más simple disponible (spec 16, sección 6).
///
/// Si llega a una asignación completa, la solución es ÚNICA (la propagación
/// solo elimina celdas imposibles, nunca la verdadera). Si se atasca, el
/// caso requiere adivinanza y debe rechazarse (pillar 1: deducción pura).
library;

import 'clue.dart';
import 'model.dart';
import 'puzzle_case.dart';
import 'validator.dart';

enum DeductionStatus { solved, stuck, contradiction }

class InferenceStep {
  final String technique;

  /// 1 = lectura directa de pista · 2 = exclusión fila/columna
  /// 3 = soporte entre pares / singles ocultos · 4 = conteo de áreas y arma
  final int tier;
  final int prunedCells;

  const InferenceStep(this.technique, this.tier, this.prunedCells);
}

class DeductionResult {
  final DeductionStatus status;
  final List<InferenceStep> steps;
  final Map<String, int>? assignment;

  const DeductionResult(this.status, this.steps, this.assignment);

  int get deductionSteps => steps.length;
  int get maxTier =>
      steps.isEmpty ? 1 : steps.map((s) => s.tier).reduce((a, b) => a > b ? a : b);
}

class DeductionEngine {
  final PuzzleCase pc;
  late final GameMap map = pc.map;

  /// charId -> celdas posibles.
  late final Map<String, Set<int>> dom;

  /// Armas que aún podrían ser la homicida (solo casos con arma).
  late final Set<String> lethalCands;

  final List<InferenceStep> _steps = [];

  DeductionEngine(this.pc);

  DeductionResult run() {
    dom = {
      for (final ch in pc.characters) ch.id: Set.of(map.occupiableCells),
    };
    lethalCands = pc.hasWeapon
        ? {for (final w in map.weapons) w.id}
        : <String>{};

    while (true) {
      if (dom.values.any((d) => d.isEmpty) ||
          (pc.hasWeapon && lethalCands.isEmpty)) {
        return DeductionResult(DeductionStatus.contradiction, _steps, null);
      }
      if (dom.values.every((d) => d.length == 1)) {
        final positions = {for (final e in dom.entries) e.key: e.value.single};
        final v = Validator.validate(pc, positions);
        return v.valid
            ? DeductionResult(DeductionStatus.solved, _steps, positions)
            : DeductionResult(DeductionStatus.contradiction, _steps, null);
      }
      if (!_applyNextTechnique()) {
        return DeductionResult(DeductionStatus.stuck, _steps, null);
      }
    }
  }

  /// Aplica la PRIMERA técnica (en orden de simplicidad) que pode algo.
  /// Cada aplicación con poda real cuenta como un paso de deducción.
  bool _applyNextTechnique() {
    final techniques = <(String, int, int Function())>[
      ('pista directa', 1, _unaryClues),
      ('exclusión fila/columna', 2, _eliminationFromAssigned),
      ('soporte entre pares', 3, _binarySupport),
      ('single oculto fila/columna', 3, _hiddenSingles),
      ('confinamiento fila/columna', 3, _claiming),
      ('conteo de áreas', 4, _areaCounting),
      ('regla del asesino', 4, _murdererRule),
      ('cadena del arma', 4, _weaponChain),
    ];
    for (final (name, tier, fn) in techniques) {
      final pruned = fn();
      if (pruned > 0) {
        _steps.add(InferenceStep(name, tier, pruned));
        return true;
      }
    }
    return false;
  }

  /// ¿El personaje está forzado a estar dentro del área?
  bool _confinedToArea(String charId, String areaId) =>
      dom[charId]!.isNotEmpty &&
      dom[charId]!.every((p) => map.areaIdOf(p) == areaId);

  int _pruneWhere(String charId, bool Function(int) bad) {
    final d = dom[charId]!;
    final before = d.length;
    d.removeWhere(bad);
    return before - d.length;
  }

  // ---- T1: lectura directa de pistas unarias -------------------------------

  int _unaryClues() {
    var pruned = 0;
    for (final clue in pc.clues) {
      switch (clue) {
        case InArea(:final subject, :final areaId):
          pruned += _pruneWhere(subject, (p) => map.areaIdOf(p) != areaId);
        case NotInArea(:final subject, :final areaId):
          pruned += _pruneWhere(subject, (p) => map.areaIdOf(p) == areaId);
        case InRow(:final subject, :final index):
          pruned += _pruneWhere(subject, (p) => map.row(p) != index);
        case InCol(:final subject, :final index):
          pruned += _pruneWhere(subject, (p) => map.col(p) != index);
        case CornerClue(:final subject, :final areaId):
          pruned += _pruneWhere(
              subject,
              (p) =>
                  !map.isCorner(p) ||
                  (areaId != null && map.areaIdOf(p) != areaId));
        case BesideObject(:final subject, :final objectId):
          final objCell = map.objectById(objectId).cell;
          final valid = map
              .orthNeighbors(objCell)
              .where((n) => map.sameArea(n, objCell))
              .toSet();
          pruned += _pruneWhere(subject, (p) => !valid.contains(p));
        case AreaEmpty(:final areaId):
          for (final ch in pc.characters) {
            pruned += _pruneWhere(ch.id, (p) => map.areaIdOf(p) == areaId);
          }
        case WeaponInArea(:final areaId):
          pruned += _pruneLethal((w) => w.areaId != areaId);
        case WeaponCat(:final category):
          pruned += _pruneLethal((w) => w.category != category);
        case WeaponExact(:final weaponId):
          pruned += _pruneLethal((w) => w.id != weaponId);
        default:
          break;
      }
    }
    return pruned;
  }

  int _pruneLethal(bool Function(WeaponDef) bad) {
    if (!pc.hasWeapon) return 0;
    final before = lethalCands.length;
    lethalCands.removeWhere((id) => bad(map.weapons.firstWhere((w) => w.id == id)));
    return before - lethalCands.length;
  }

  // ---- T2: exclusión por personajes ya ubicados ----------------------------

  int _eliminationFromAssigned() {
    var pruned = 0;
    for (final ch in pc.characters) {
      final d = dom[ch.id]!;
      if (d.length != 1) continue;
      final cell = d.single;
      final r = map.row(cell), c = map.col(cell);
      for (final other in pc.characters) {
        if (other.id == ch.id) continue;
        pruned += _pruneWhere(
            other.id, (p) => p == cell || map.row(p) == r || map.col(p) == c);
      }
    }
    return pruned;
  }

  // ---- T3: soporte entre pares (consistencia de arco) ----------------------

  /// Para una pista relacional rel(a,b): una celda p de a sobrevive solo si
  /// existe q en dom(b) compatible (q != p, fila y columna distintas, y la
  /// relación se cumple). Sonido porque la solución real cumple todo eso.
  int _binarySupport() {
    var pruned = 0;
    for (final clue in pc.clues) {
      final rel = _relationOf(clue);
      if (rel == null) continue;
      final (a, b, test) = rel;
      pruned += _revise(a, b, test);
      pruned += _revise(b, a, (p, q) => test(q, p));
    }
    return pruned;
  }

  (String, String, bool Function(int, int))? _relationOf(Clue clue) =>
      switch (clue) {
        SameArea(:final a, :final b) => (a, b, (p, q) => map.sameArea(p, q)),
        NotSameArea(:final a, :final b) =>
          (a, b, (p, q) => !map.sameArea(p, q)),
        BesideChar(:final a, :final b) =>
          (a, b, (p, q) => map.besideInArea(p, q)),
        AloneWith(:final a, :final b) => (a, b, (p, q) => map.sameArea(p, q)),
        Cardinal(:final subject, :final other, :final dir) => (
            subject,
            other,
            (p, q) => switch (dir) {
                  Direction.west => map.col(p) < map.col(q),
                  Direction.east => map.col(p) > map.col(q),
                  Direction.north => map.row(p) < map.row(q),
                  Direction.south => map.row(p) > map.row(q),
                }
          ),
        _ => null,
      };

  int _revise(String a, String b, bool Function(int p, int q) test) =>
      _pruneWhere(a, (p) {
        for (final q in dom[b]!) {
          if (q == p) continue;
          if (map.row(q) == map.row(p) || map.col(q) == map.col(p)) continue;
          if (test(p, q)) return false; // tiene soporte
        }
        return true; // sin soporte: se elimina
      });

  // ---- T3: single oculto — cada fila/columna tiene exactamente una persona -

  int _hiddenSingles() {
    var pruned = 0;
    for (var line = 0; line < map.size; line++) {
      for (final byRow in [true, false]) {
        final able = [
          for (final ch in pc.characters)
            if (dom[ch.id]!
                .any((p) => (byRow ? map.row(p) : map.col(p)) == line))
              ch.id
        ];
        if (able.length == 1) {
          pruned += _pruneWhere(
              able.single, (p) => (byRow ? map.row(p) : map.col(p)) != line);
        }
      }
    }
    return pruned;
  }

  // ---- T3: confinamiento — si X solo puede estar en la fila r, nadie más ---

  int _claiming() {
    var pruned = 0;
    for (final ch in pc.characters) {
      final d = dom[ch.id]!;
      if (d.length <= 1) continue;
      final rows = d.map(map.row).toSet();
      if (rows.length == 1) {
        final r = rows.single;
        for (final other in pc.characters) {
          if (other.id == ch.id) continue;
          pruned += _pruneWhere(other.id, (p) => map.row(p) == r);
        }
      }
      final cols = d.map(map.col).toSet();
      if (cols.length == 1) {
        final c = cols.single;
        for (final other in pc.characters) {
          if (other.id == ch.id) continue;
          pruned += _pruneWhere(other.id, (p) => map.col(p) == c);
        }
      }
    }
    return pruned;
  }

  // ---- T4: conteo de áreas (a solas / a solas con) -------------------------

  int _areaCounting() {
    var pruned = 0;
    for (final clue in pc.clues) {
      switch (clue) {
        case Alone(:final subject):
          // Nadie puede compartir área con un personaje "a solas".
          for (final other in pc.characters) {
            if (other.id == subject) continue;
            pruned += _pruneWhere(
                other.id, (q) => _confinedToArea(subject, map.areaIdOf(q)));
          }
          pruned += _pruneWhere(subject, (p) {
            final areaId = map.areaIdOf(p);
            return pc.characters.any(
                (y) => y.id != subject && _confinedToArea(y.id, areaId));
          });
        case AloneWith(:final a, :final b):
          // Solo {a, b} en esa área: terceros excluidos.
          for (final other in pc.characters) {
            if (other.id == a || other.id == b) continue;
            pruned += _pruneWhere(
                other.id,
                (q) =>
                    _confinedToArea(a, map.areaIdOf(q)) ||
                    _confinedToArea(b, map.areaIdOf(q)));
          }
          for (final s in [a, b]) {
            pruned += _pruneWhere(s, (p) {
              final areaId = map.areaIdOf(p);
              return pc.characters.any((y) =>
                  y.id != a && y.id != b && _confinedToArea(y.id, areaId));
            });
          }
        default:
          break;
      }
    }
    return pruned;
  }

  // ---- T4: regla del asesino (invariante 3) --------------------------------

  int _murdererRule() {
    var pruned = 0;
    final victim = pc.victimId;
    final suspects = [
      for (final ch in pc.characters)
        if (ch.id != victim) ch.id
    ];

    // Filtra celdas de la víctima por conteo de sospechosos en el área.
    pruned += _pruneWhere(victim, (p) {
      final areaId = map.areaIdOf(p);
      var forced = 0, can = 0;
      for (final s in suspects) {
        if (_confinedToArea(s, areaId)) forced++;
        if (dom[s]!.any((q) => map.areaIdOf(q) == areaId)) can++;
      }
      return forced >= 2 || can == 0;
    });

    // Si la víctima está confinada a un área, razona sobre el asesino.
    final vAreas = dom[victim]!.map(map.areaIdOf).toSet();
    if (vAreas.length == 1) {
      final areaId = vAreas.single;
      final forced = [for (final s in suspects) if (_confinedToArea(s, areaId)) s];
      final can = [
        for (final s in suspects)
          if (dom[s]!.any((q) => map.areaIdOf(q) == areaId)) s
      ];
      if (forced.length == 1) {
        // El asesino está identificado: los demás no entran al área.
        for (final s in suspects) {
          if (s == forced.single) continue;
          pruned += _pruneWhere(s, (q) => map.areaIdOf(q) == areaId);
        }
      } else if (forced.isEmpty && can.length == 1) {
        // Solo un sospechoso puede acompañar a la víctima: debe hacerlo.
        pruned += _pruneWhere(can.single, (q) => map.areaIdOf(q) != areaId);
      }
    }
    return pruned;
  }

  // ---- T4: cadena del arma --------------------------------------------------

  int _weaponChain() {
    if (!pc.hasWeapon) return 0;
    var pruned = 0;
    // La víctima está en el área de alguna arma candidata.
    final candAreas = {
      for (final id in lethalCands)
        map.weapons.firstWhere((w) => w.id == id).areaId
    };
    pruned +=
        _pruneWhere(pc.victimId, (p) => !candAreas.contains(map.areaIdOf(p)));
    // Las candidatas deben estar en algún área posible de la víctima.
    final vAreas = dom[pc.victimId]!.map(map.areaIdOf).toSet();
    pruned += _pruneLethal((w) => !vAreas.contains(w.areaId));
    return pruned;
  }
}
