/// Verificador de unicidad: cuenta por búsqueda exhaustiva cuántas
/// asignaciones completas satisfacen el caso (spec 16, sección 6.1.2).
/// Una "solución" es toda asignación que pasa el Validator (la misma
/// definición que usará el servidor).
library;

import 'clue.dart';
import 'puzzle_case.dart';
import 'validator.dart';

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
  static int countSolutions(PuzzleCase pc, {int limit = 2}) {
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

    void search(int i) {
      if (found >= limit) return;
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
        if (partialOk()) search(i + 1);
        positions.remove(charId);
        usedRows.remove(r);
        usedCols.remove(c);
        if (found >= limit) return;
      }
    }

    search(0);
    return found;
  }
}
