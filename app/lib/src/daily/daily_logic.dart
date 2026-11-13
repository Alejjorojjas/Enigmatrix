/// Lógica pura del reto diario con ranking (ronda F2b, plan 5A.3): qué reto
/// toca cada día, formato del tiempo, score y modelos del ranking. Sin
/// Flutter, sin Firebase y sin reloj propio: la fecha entra como parámetro.
library;

import 'package:flutter/foundation.dart';

import '../backend/validation_client.dart' show SubmitSolved;
import '../game/game_config.dart'
    show kDefaultChallengeDays, kDefaultChallengeStartDate;

/// Penalización por error en el ranking (`config/server.errorPenaltyMs`, por
/// defecto 30 000 ms). Solo se usa para recalcular o explicar el total: el
/// score oficial lo calcula el servidor.
const int kDefaultErrorPenaltyMs = 30000;

/// Máximo de filas del ranking que se muestran.
const int kRankingLimit = 50;

/// Prefijo de los casos del reto diario.
bool isDailyCaseId(String caseId) => caseId.startsWith('reto-');

int _dayNumber(String date) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(date);
  if (m == null) throw FormatException('Fecha inválida: $date');
  final ms = DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  return ms.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// Reto que toca en [localDate] (`YYYY-MM-DD`): misma fórmula que el
/// servidor, `(díasEntre(inicio, fecha) mod 30) + 1`. Las fechas anteriores
/// al inicio siguen el ciclo hacia atrás.
String dailyCaseIdForLocalDate(
  String localDate, {
  String startDate = kDefaultChallengeStartDate,
  int cycleDays = kDefaultChallengeDays,
}) {
  final diff = _dayNumber(localDate) - _dayNumber(startDate);
  final idx = ((diff % cycleDays) + cycleDays) % cycleDays;
  return 'reto-${(idx + 1).toString().padLeft(3, '0')}';
}

/// Número de día (1 a [cycleDays]) del reto de [localDate].
int dailyDayForLocalDate(
  String localDate, {
  String startDate = kDefaultChallengeStartDate,
  int cycleDays = kDefaultChallengeDays,
}) => int.parse(
  dailyCaseIdForLocalDate(
    localDate,
    startDate: startDate,
    cycleDays: cycleDays,
  ).substring(5),
);

/// `mm:ss` de una duración en milisegundos (los segundos se truncan). Los
/// minutos no se limitan a 59: una hora y media se ve `90:00`.
String formatElapsedMs(int ms) {
  final total = (ms < 0 ? 0 : ms) ~/ 1000;
  final m = total ~/ 60;
  final s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Total del ranking: tiempo del servidor más la penalización por error.
int dailyScore(
  int serverElapsedMs,
  int errors, {
  int penaltyMs = kDefaultErrorPenaltyMs,
}) => serverElapsedMs + errors * penaltyMs;

/// Tiempo transcurrido desde `startedAt` (ms desde la época) hasta [nowMs].
/// Nunca es negativo (un reloj del teléfono atrasado no da tiempos < 0).
int elapsedSince(int startedAtMs, int nowMs) {
  final d = nowMs - startedAtMs;
  return d < 0 ? 0 : d;
}

/// Resultado del reto del día guardado en el teléfono (cache de lo que dijo
/// el servidor): vive dentro del JSON de `done:<caso>`.
@immutable
class DailyResult {
  const DailyResult({
    required this.localDate,
    required this.serverElapsedMs,
    required this.errors,
    required this.score,
    required this.rank,
  });

  /// Fecha local del reto resuelto.
  final String localDate;
  final int serverElapsedMs;
  final int errors;
  final int score;

  /// Puesto del día, o null si no entró al ranking.
  final int? rank;

  Map<String, Object?> toJson() => {
    'localDate': localDate,
    'serverElapsedMs': serverElapsedMs,
    'serverErrors': errors,
    'score': score,
    'rank': rank,
  };

  /// Null si el dato no trae lo necesario.
  static DailyResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = json['localDate'];
    final ms = json['serverElapsedMs'];
    final errors = json['serverErrors'];
    final score = json['score'];
    final rank = json['rank'];
    if (date is! String || ms is! int || errors is! int || score is! int) {
      return null;
    }
    return DailyResult(
      localDate: date,
      serverElapsedMs: ms,
      errors: errors,
      score: score,
      rank: rank is int ? rank : null,
    );
  }
}

/// Resultado oficial de una respuesta `solved` del servidor; null si no es un
/// reto (la respuesta no trae tiempo y score).
DailyResult? dailyResultFromSolved(SubmitSolved r, String localDate) {
  final ms = r.serverElapsedMs;
  final score = r.score;
  if (ms == null || score == null) return null;
  return DailyResult(
    localDate: localDate,
    serverElapsedMs: ms,
    errors: r.errors ?? 0,
    score: score,
    rank: r.rank,
  );
}

/// Una fila del ranking del día (`dailyRankings/{fecha}/entries/{uid}`).
@immutable
class RankingEntry {
  const RankingEntry({
    required this.uid,
    required this.nickname,
    required this.serverElapsedMs,
    required this.errors,
    required this.score,
    this.solvedAtMs = 0,
  });

  final String uid;
  final String nickname;
  final int serverElapsedMs;
  final int errors;
  final int score;
  final int solvedAtMs;

  /// Lee un documento; null si le falta algo (la fila se omite).
  static RankingEntry? fromMap(String id, Map<String, Object?> data) {
    final nick = data['nickname'];
    final ms = data['serverElapsedMs'];
    final errors = data['errors'];
    final score = data['score'];
    final solvedAt = data['solvedAt'];
    if (nick is! String || ms is! num || errors is! num || score is! num) {
      return null;
    }
    final uid = data['uid'];
    return RankingEntry(
      uid: uid is String && uid.isNotEmpty ? uid : id,
      nickname: nick,
      serverElapsedMs: ms.toInt(),
      errors: errors.toInt(),
      score: score.toInt(),
      solvedAtMs: solvedAt is num ? solvedAt.toInt() : 0,
    );
  }
}

/// Orden del ranking: menor score; si empatan, quien resolvió primero.
int compareRanking(RankingEntry a, RankingEntry b) {
  final c = a.score.compareTo(b.score);
  return c != 0 ? c : a.solvedAtMs.compareTo(b.solvedAtMs);
}

/// Lo que dibuja la pantalla del ranking.
@immutable
class RankingData {
  const RankingData({required this.top, this.own, this.ownRank, this.ownUid});

  /// Los mejores del día, en orden (máximo [kRankingLimit]).
  final List<RankingEntry> top;

  /// La entrada propia, si ya resolvió el reto de hoy con apodo.
  final RankingEntry? own;

  /// Puesto propio, si se conoce.
  final int? ownRank;
  final String? ownUid;

  bool get isEmpty => top.isEmpty && own == null;

  /// true si la fila propia ya está dentro de [top].
  bool get ownInTop => ownUid != null && top.any((e) => e.uid == ownUid);

  /// La fila propia que se agrega aparte, debajo del top: solo si existe y
  /// no está ya en el top.
  RankingEntry? get ownOutsideTop => (own != null && !ownInTop) ? own : null;

  /// Puesto de la fila propia: su posición en el top o el puesto conocido.
  int? get resolvedOwnRank {
    if (ownUid != null) {
      final i = top.indexWhere((e) => e.uid == ownUid);
      if (i >= 0) return i + 1;
    }
    return ownRank;
  }
}
