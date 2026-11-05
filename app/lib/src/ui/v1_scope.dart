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

import '../../l10n/l10n.dart';
import '../data/case_repository.dart' show DailyChallenge;
import '../game/game_config.dart';

/// Todas las dificultades, de menor a mayor.
const kAllDifficulties = [
  'principiante',
  'casual',
  'intermedio',
  'experto',
  'elite',
];

/// Si una dificultad ya se puede jugar. Cuáles son las jugables lo dice la
/// configuración ([GameConfig.v1Difficulties], H-65); sin configuración
/// explícita valen los valores por defecto.
bool isV1Difficulty(
  String difficulty, {
  GameConfig config = const GameConfig(),
}) => config.isV1Difficulty(difficulty);

/// Los casos que el jugador puede abrir hoy (sin Experto ni Élite).
List<PuzzleCase> playableCases(
  List<PuzzleCase> all, {
  GameConfig config = const GameConfig(),
}) => [
  for (final c in all)
    if (config.isV1Difficulty(c.difficulty)) c,
];

/// Título que ve el jugador: el de la historia si existe, si no el nombre del
/// mapa (los casos sin historia siguen funcionando).
String caseTitle(PuzzleCase pc) {
  final t = pc.story?.title('es');
  return (t == null || t.trim().isEmpty) ? pc.map.nameEs : t;
}

/// Mundos del juego: id, nombre (ya traducido) y si ya está disponible.
class WorldInfo {
  const WorldInfo(this.id, this.name, this.available);

  final String id;
  final String name;
  final bool available;
}

/// Nombre visible de un mundo (los textos viven en el .arb); si el id no
/// tiene nombre conocido se muestra el propio id.
String worldName(AppLocalizations l10n, String id) => switch (id) {
  'mansion' => l10n.worldMansion,
  'hotel' => l10n.worldHotel,
  'museo' => l10n.worldMuseum,
  'tren' => l10n.worldTrain,
  'hospital' => l10n.worldHospital,
  _ => id,
};

/// Los mundos en el orden de la configuración, con su nombre visible.
List<WorldInfo> worldsFor(GameConfig config, AppLocalizations l10n) => [
  for (final w in config.worlds)
    WorldInfo(w.id, worldName(l10n, w.id), w.available),
];

/// Día del reto (1 a [GameConfig.challengeDays]) que corresponde a una fecha
/// local: `((días desde el inicio del reto) mod días del ciclo) + 1`. Con los
/// valores por defecto el inicio es el 01-11-2026 y el ciclo de 30 días. Se
/// cuentan días de calendario (no bloques de 24 horas) para que el cambio de
/// hora no mueva el día. La hora oficial de cambio de día está pendiente
/// (pregunta 7): hoy es la medianoche del teléfono y el reto sigue marcado
/// DEMO.
int challengeDayFor(DateTime now, {GameConfig config = const GameConfig()}) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final first = config.challengeStart;
  final start = DateTime.utc(first.year, first.month, first.day);
  return today.difference(start).inDays % config.challengeDays + 1;
}

/// El reto del día entre los retos cargados, o null si ese día no está.
DailyChallenge? todaysChallenge(
  List<DailyChallenge> all,
  DateTime now, {
  GameConfig config = const GameConfig(),
}) {
  final day = challengeDayFor(now, config: config);
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
String difficultyName(AppLocalizations l10n, String d) => switch (d) {
  'principiante' => l10n.difficultyBeginner,
  'casual' => l10n.difficultyCasual,
  'intermedio' => l10n.difficultyIntermediate,
  'experto' => l10n.difficultyExpert,
  'elite' => l10n.difficultyElite,
  _ => d,
};
