/// Validador de asignaciones completas contra los invariantes del juego
/// (docs/16-spec-puzzle.md sección 2.2) y las pistas del caso.
///
/// IMPORTANTE: esta es exactamente la lógica que se portará a Cloud Functions
/// para la validación oficial. Mantenerla pura y sin dependencias.
library;

import 'clue.dart';
import 'puzzle_case.dart';

class ValidationResult {
  final bool valid;
  final List<String> errors;

  /// Deducidos por el sistema al validar correcto (doc 03):
  final String? murdererId;
  final String? lethalWeaponId;

  const ValidationResult({
    required this.valid,
    this.errors = const [],
    this.murdererId,
    this.lethalWeaponId,
  });
}

class Validator {
  /// Valida una asignación completa charId->celda contra el caso.
  /// No usa la solución almacenada: re-deriva todo de los invariantes y
  /// las pistas (así funcionará también el servidor).
  static ValidationResult validate(PuzzleCase pc, Map<String, int> positions) {
    final map = pc.map;
    final errors = <String>[];

    // Todos los personajes asignados, celdas válidas y ocupables.
    for (final ch in pc.characters) {
      final p = positions[ch.id];
      if (p == null) {
        errors.add('Personaje sin ubicar: ${ch.id}');
      } else if (p < 0 || p >= map.size * map.size) {
        errors.add('Celda fuera de grilla para ${ch.id}');
      } else if (!map.isOccupiable(p)) {
        errors.add('Celda no ocupable para ${ch.id}');
      }
    }
    if (errors.isNotEmpty) return ValidationResult(valid: false, errors: errors);

    // Exactamente una persona por fila y por columna (invariante 2).
    final rows = <int>{}, cols = <int>{}, cells = <int>{};
    for (final ch in pc.characters) {
      final p = positions[ch.id]!;
      if (!cells.add(p)) errors.add('Dos personajes en la misma celda');
      if (!rows.add(map.row(p))) errors.add('Dos personajes en la misma fila');
      if (!cols.add(map.col(p))) {
        errors.add('Dos personajes en la misma columna');
      }
    }

    // El asesino: exactamente una persona acompaña a la víctima (invariante 3).
    final victimArea = map.areaIdOf(positions[pc.victimId]!);
    final companions = [
      for (final ch in pc.characters)
        if (ch.id != pc.victimId &&
            map.areaIdOf(positions[ch.id]!) == victimArea)
          ch.id
    ];
    String? murderer;
    if (companions.length != 1) {
      errors.add('El área de la víctima tiene ${companions.length} '
          'acompañantes; debe tener exactamente 1 (el asesino)');
    } else {
      murderer = companions.single;
    }

    // Arma homicida: deducible y única (invariante 4 + spec sección 2.3).
    String? lethal;
    if (pc.hasWeapon) {
      final weaponClues = pc.clues.where(
          (c) => c is WeaponInArea || c is WeaponCat || c is WeaponExact);
      final candidates = <String>[];
      for (final w in map.weaponsInArea(victimArea)) {
        final ctx = pc.contextFor(positions, lethal: w.id);
        if (weaponClues.every((c) => c.holds(ctx))) candidates.add(w.id);
      }
      if (candidates.length != 1) {
        errors.add('Arma homicida no deducible de forma única en el área de '
            'la víctima (candidatas: ${candidates.length})');
      } else {
        lethal = candidates.single;
      }
    }

    // Todas las pistas se cumplen.
    final ctx = pc.contextFor(positions, lethal: lethal);
    for (final clue in pc.clues) {
      if (!clue.holds(ctx)) {
        errors.add('Pista incumplida: ${clue.toJson()}');
      }
    }

    return ValidationResult(
      valid: errors.isEmpty,
      errors: errors,
      murdererId: errors.isEmpty ? murderer : null,
      lethalWeaponId: errors.isEmpty ? lethal : null,
    );
  }
}
