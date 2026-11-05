/// Rangos aceptables de dificultad por perfil (H-40/ronda 3.1).
///
/// PROVISIONAL: los valores de [kDifficultyRanges] se propusieron midiendo
/// los 20 casos del banco de pruebas y lotes de 30 semillas por perfil (ver
/// production/revisiones/2026-11-05-medicion-12x12-16x16.md, sección
/// "Rangos de dificultad propuestos"). Se fijarán DEFINITIVAMENTE
/// con los datos de la prueba de juego (tiempo real y errores de los
/// jugadores por caso). Hasta entonces no son una promesa de dificultad:
/// solo evitan los extremos (casos casi triviales o de cadena excesiva).
///
/// Es configuración, no lógica: cambiar un número aquí no toca el generador.
library;

/// Rango aceptable de un perfil: pasos de deducción y técnica máxima.
/// Técnica: 1 = lectura directa · 2 = exclusión fila/columna ·
/// 3 = soporte entre pares / singles ocultos / confinamiento ·
/// 4 = conteo de áreas, regla del asesino, cadena del arma.
class DifficultyRange {
  final int minSteps;
  final int maxSteps;
  final int minTier;
  final int maxTier;

  const DifficultyRange({
    required this.minSteps,
    required this.maxSteps,
    required this.minTier,
    required this.maxTier,
  });

  /// Sin restricción (para pruebas o para medir sin descartar).
  static const any =
      DifficultyRange(minSteps: 0, maxSteps: 1 << 30, minTier: 1, maxTier: 4);

  /// Null si [steps] y [tier] caen dentro del rango; si no, el motivo de
  /// descarte (clave estable para el registro del generador).
  String? violation(int steps, int tier) {
    if (steps < minSteps) return rejectStepsBelow;
    if (steps > maxSteps) return rejectStepsAbove;
    if (tier < minTier) return rejectTierBelow;
    if (tier > maxTier) return rejectTierAbove;
    return null;
  }

  bool contains(int steps, int tier) => violation(steps, tier) == null;

  @override
  String toString() =>
      'pasos $minSteps-$maxSteps, técnica T$minTier-T$maxTier';
}

/// Motivos de descarte por rango (claves del registro de descartes).
const rejectStepsBelow = 'pasos por debajo del rango';
const rejectStepsAbove = 'pasos por encima del rango';
const rejectTierBelow = 'técnica por debajo del rango';
const rejectTierAbove = 'técnica por encima del rango';

/// PROVISIONAL (ver el encabezado). Por etiqueta de perfil.
const Map<String, DifficultyRange> kDifficultyRanges = {
  'tutorial':
      DifficultyRange(minSteps: 2, maxSteps: 8, minTier: 2, maxTier: 4),
  'principiante':
      DifficultyRange(minSteps: 3, maxSteps: 12, minTier: 2, maxTier: 4),
  'casual': DifficultyRange(minSteps: 4, maxSteps: 14, minTier: 2, maxTier: 4),
  'intermedio':
      DifficultyRange(minSteps: 4, maxSteps: 16, minTier: 3, maxTier: 4),
  'experto': DifficultyRange(minSteps: 6, maxSteps: 40, minTier: 3, maxTier: 4),
  'elite': DifficultyRange(minSteps: 8, maxSteps: 80, minTier: 3, maxTier: 4),
};

/// Rango del perfil por etiqueta. Si no hay uno configurado devuelve
/// [DifficultyRange.any] (nunca descarta por rango).
DifficultyRange rangeForProfile(String label) =>
    kDifficultyRanges[label] ?? DifficultyRange.any;
