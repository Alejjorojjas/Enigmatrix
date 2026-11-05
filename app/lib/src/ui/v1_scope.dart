/// Alcance de la V1 en la interfaz (ADR-0014) y títulos de los casos.
///
/// - Dificultades de la V1: Principiante, Casual e Intermedio. Experto y Élite
///   se muestran "Próximamente" y no se pueden abrir.
/// - Mundos: solo "La Mansión" está disponible; los demás son "Próximamente".
/// - Mundo 1 y reto: salen de la campaña "mansion" y de los 30 retos del
///   catálogo (el banco de pruebas queda aparte, en Configuración).
/// - Título del caso: el de la historia (`story`) si existe y, si no, el
///   nombre del mapa de hoy.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

import '../data/case_repository.dart' show DailyChallenge;

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

/// Primer día del reto diario: el 01-11-2026 es el día 1.
final DateTime kChallengeStart = DateTime(2026, 11, 1);

/// Cuántos días tiene el ciclo de retos (después vuelve al día 1).
const kChallengeDays = 30;

/// Día del reto (1 a 30) que corresponde a una fecha local:
/// `((días desde el 01-11-2026) mod 30) + 1`. Se cuentan días de calendario
/// (no bloques de 24 horas) para que el cambio de hora no mueva el día. La
/// hora oficial de cambio de día está pendiente (pregunta 7): hoy es la
/// medianoche del teléfono y el reto sigue marcado DEMO.
int challengeDayFor(DateTime now) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final start = DateTime.utc(
    kChallengeStart.year,
    kChallengeStart.month,
    kChallengeStart.day,
  );
  return today.difference(start).inDays % kChallengeDays + 1;
}

/// El reto del día entre los retos cargados, o null si ese día no está.
DailyChallenge? todaysChallenge(List<DailyChallenge> all, DateTime now) {
  final day = challengeDayFor(now);
  for (final c in all) {
    if (c.day == day) return c;
  }
  return null;
}

/// A dónde se vuelve al salir de una partida: el reto diario vuelve al
/// Inicio, el banco de pruebas (desarrollo) a su lista y el Mundo 1 a su
/// lista de casos.
String exitRouteFor(String caseId) {
  if (caseId.startsWith('reto-')) return '/home';
  if (caseId.startsWith('caso-')) return '/banco';
  return '/casos';
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
