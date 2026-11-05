/// Verificador de unicidad: cuenta por búsqueda exhaustiva cuántas
/// asignaciones completas satisfacen el caso (spec 16, sección 6.1.2).
/// Una "solución" es toda asignación que pasa el Validator (la misma
/// definición que usará el servidor).
library;

import 'clue.dart';
import 'puzzle_case.dart';
import 'validator.dart';

/// Tope del solver (H-42): evita que un caso grande cuelgue la generación.
/// Los nodos son deterministas (úsalos en los tests); el tiempo no (úsalo
/// como red de seguridad en producción).
class SolverLimits {
  /// Máximo de asignaciones parciales exploradas. Null = sin tope.
  final int? maxNodes;

  /// Máximo de tiempo de una verificación. Null = sin tope.
  final Duration? maxTime;

  const SolverLimits({this.maxNodes, this.maxTime});

  static const unlimited = SolverLimits();

  /// Tope por defecto. PROVISIONAL: se ajusta con las mediciones
  /// (production/revisiones/2026-11-05-medicion-12x12-16x16.md).
  static const standard = SolverLimits(
    maxNodes: kDefaultSolverMaxNodes,
    maxTime: Duration(seconds: 30),
  );
}

/// Tope de nodos por defecto del verificador de unicidad.
const kDefaultSolverMaxNodes = 5000000;

/// Motivo de descarte cuando el solver supera su tope.
const rejectSolverCap = 'tope';

/// Se lanza cuando la búsqueda supera el tope y se pidió un conteo exacto.
class SolverLimitExceeded implements Exception {
  /// 'nodos' o 'tiempo'.
  final String kind;
  final int nodes;
  const SolverLimitExceeded(this.kind, this.nodes);

  @override
  String toString() =>
      'SolverLimitExceeded: tope de $kind superado tras $nodes nodos';
}

/// Resultado de una verificación de unicidad con tope.
class UniquenessResult {
  /// Soluciones encontradas (hasta el límite pedido). Si [capped] es true,
  /// es solo un mínimo: no se pudo decidir la unicidad.
  final int solutions;

  /// Nodos explorados.
  final int nodes;

  /// true si la búsqueda se cortó por el tope.
  final bool capped;

  /// 'nodos' o 'tiempo' cuando [capped]; null si no.
  final String? capKind;

  const UniquenessResult({
    required this.solutions,
    required this.nodes,
    required this.capped,
    this.capKind,
  });
}

/// Personajes referenciados por una pista (para poda parcial).
Set<String> _subjectsOf(Clue c) => switch (c) {
      InArea(:final subject) => {subject},
      NotInArea(:final subject) => {subject},
      SameArea(:final a, :final b) => {a, b},
      NotSameArea(:final a, :final b) => {a, b},
      BesideChar(:final a, :final b) => {a, b},
      OnObjectGroup(:final subject) => {subject},
      BesideObjectGroup(:final subject) => {subject},
      // Poda sonora con solo el sujeto asignado: si el sujeto no está sobre
      // el grupo (permanente) o si otro asignado ya está sobre él
      // (permanente), la pista nunca podrá cumplirse.
      OnlyOneOnGroup(:final subject) => {subject},
      CompoundClue(:final subject) => {subject},
      LastFreeCell() => const {},
      Alone(:final subject) => {subject},
      AloneWith(:final a, :final b) => {a, b},
      AreaEmpty() => const {},
      WeaponInArea() || WeaponCat() || WeaponExact() => const {},
    };

class UniquenessChecker {
  /// Cuenta soluciones hasta [limit] (2 basta para decidir unicidad).
  /// Lanza [SolverLimitExceeded] si se supera el tope [limits] (por defecto
  /// [SolverLimits.standard]); para no lanzar, usa [analyze].
  static int countSolutions(PuzzleCase pc,
      {int limit = 2, SolverLimits limits = SolverLimits.standard}) {
    final r = analyze(pc, limit: limit, limits: limits);
    if (r.capped) throw SolverLimitExceeded(r.capKind!, r.nodes);
    return r.solutions;
  }

  /// Como [countSolutions] pero con tope: si se supera devuelve un
  /// resultado con `capped = true` en vez de colgarse o lanzar.
  static UniquenessResult analyze(PuzzleCase pc,
      {int limit = 2, SolverLimits limits = SolverLimits.standard}) {
    final map = pc.map;
    // Víctima primero: activa antes la poda de "exactamente un acompañante".
    final order = [
      pc.victimId,
      for (final ch in pc.characters)
        if (ch.id != pc.victimId) ch.id,
    ];
    // Pistas posicionales (las de arma no podan posiciones parcialmente).
    final positional = [
      for (final c in pc.clues)
        if (c is! WeaponInArea && c is! WeaponCat && c is! WeaponExact) c
    ];

    final positions = <String, int>{};
    final usedRows = <int>{}, usedCols = <int>{};
    var found = 0;
    var nodes = 0;
    String? capKind;
    final clock = limits.maxTime == null ? null : (Stopwatch()..start());
    final maxNodes = limits.maxNodes;

    // Poda sobre asignación parcial. Solo poda violaciones PERMANENTES:
    // todas las pistas evaluadas aquí, una vez violadas con un subconjunto,
    // siguen violadas con cualquier superconjunto (ver tests de unicidad).
    bool partialOk() {
      final ctx = ClueContext(
        map: map,
        positions: positions,
        victimId: pc.victimId,
      );
      for (final clue in positional) {
        final subs = _subjectsOf(clue);
        if (subs.every(positions.containsKey) && !clue.holds(ctx)) {
          return false;
        }
      }
      // Acompañantes de la víctima: nunca más de 1.
      final vp = positions[pc.victimId];
      if (vp != null) {
        final vArea = map.areaIdOf(vp);
        var companions = 0;
        for (final e in positions.entries) {
          if (e.key != pc.victimId && map.areaIdOf(e.value) == vArea) {
            companions++;
          }
        }
        if (companions > 1) return false;
      }
      return true;
    }

    // true si hay que cortar (tope de nodos o de tiempo).
    bool overCap() {
      if (capKind != null) return true;
      if (maxNodes != null && nodes > maxNodes) {
        capKind = 'nodos';
      } else if (clock != null &&
          (nodes & 0xFFF) == 0 &&
          clock.elapsed > limits.maxTime!) {
        capKind = 'tiempo';
      }
      return capKind != null;
    }

    void search(int i) {
      if (found >= limit || capKind != null) return;
      if (i == order.length) {
        if (Validator.validate(pc, positions).valid) found++;
        return;
      }
      final charId = order[i];
      for (final cell in map.occupiableCells) {
        final r = map.row(cell), c = map.col(cell);
        if (usedRows.contains(r) || usedCols.contains(c)) continue;
        positions[charId] = cell;
        usedRows.add(r);
        usedCols.add(c);
        nodes++;
        if (!overCap() && partialOk()) search(i + 1);
        positions.remove(charId);
        usedRows.remove(r);
        usedCols.remove(c);
        if (found >= limit || capKind != null) return;
      }
    }

    search(0);
    return UniquenessResult(
      solutions: found,
      nodes: nodes,
      capped: capKind != null,
      capKind: capKind,
    );
  }
}
