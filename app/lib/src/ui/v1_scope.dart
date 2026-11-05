/// Alcance de la V1 en la interfaz (ADR-0014) y títulos de los casos.
///
/// - Dificultades de la V1: Principiante, Casual e Intermedio. Experto y Élite
///   se muestran "Próximamente" y no se pueden abrir.
/// - Mundos: solo "La Mansión" está disponible; los demás son "Próximamente".
/// - Título del caso: el de la historia (`story`) si existe y, si no, el
///   nombre del mapa de hoy.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

/// Todas las dificultades, de menor a mayor.
const kAllDifficulties = [
  'principiante',
  'casual',
  'intermedio',
  'experto',
  'elite',
];

/// Dificultades que ya se pueden jugar.
const kV1Difficulties = ['principiante', 'casual', 'intermedio'];

bool isV1Difficulty(String difficulty) => kV1Difficulties.contains(difficulty);

/// Los casos que el jugador puede abrir hoy (sin Experto ni Élite).
List<PuzzleCase> playableCases(List<PuzzleCase> all) => [
  for (final c in all)
    if (isV1Difficulty(c.difficulty)) c,
];

/// Título que ve el jugador: el de la historia si existe, si no el nombre del
/// mapa (los casos sin historia siguen funcionando).
String caseTitle(PuzzleCase pc) {
  final t = pc.story?.title('es');
  return (t == null || t.trim().isEmpty) ? pc.map.nameEs : t;
}

/// Mundos del juego: id, nombre y si ya está disponible.
class WorldInfo {
  const WorldInfo(this.id, this.name, this.available);

  final String id;
  final String name;
  final bool available;
}

const kWorlds = [
  WorldInfo('mansion', 'La Mansión', true),
  WorldInfo('hotel', 'El Hotel', false),
  WorldInfo('museo', 'El Museo', false),
  WorldInfo('tren', 'El Tren', false),
  WorldInfo('hospital', 'El Hospital', false),
];

/// Caso del reto diario de hoy: determinista por fecha (simulación local
/// mientras no hay servidor) y solo entre los casos jugables.
PuzzleCase? todaysChallenge(List<PuzzleCase> all, DateTime now) {
  final playable = playableCases(all);
  if (playable.isEmpty) return null;
  final day = now.difference(DateTime(2026, 1, 1)).inDays;
  return playable[day % playable.length];
}

/// Nombre de una dificultad para mostrar ("principiante" -> "Principiante").
String difficultyName(String d) => switch (d) {
  'principiante' => 'Principiante',
  'casual' => 'Casual',
  'intermedio' => 'Intermedio',
  'experto' => 'Experto',
  'elite' => 'Élite',
  _ => d,
};
