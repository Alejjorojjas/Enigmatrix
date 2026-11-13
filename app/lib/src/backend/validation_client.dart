/// Contrato con el servidor (backend/functions/src/index.ts, ADR-0016).
///
/// Esta capa no conoce Firebase: la implementación real vive en
/// `firebase_validation_client.dart` y los tests usan un cliente falso. La
/// respuesta del servidor nunca trae la solución ni qué casillas fallan.
library;

import 'package:flutter/foundation.dart';

/// Por qué falló una llamada al servidor.
enum ValidationFailure {
  /// Sin señal o tiempo agotado (`unavailable`, `deadline-exceeded`): se
  /// reintenta sin límite.
  network,

  /// El servidor respondió con un error (`internal`, una respuesta mal
  /// formada u otro código): se reintenta unas pocas veces seguidas y luego
  /// el envío se detiene hasta que el jugador decida.
  serverError,

  /// `failed-precondition` con "Regístrate para seguir jugando": un invitado
  /// (sesión anónima) pidió un caso que no es gratis. Reintentar no sirve: hay
  /// que invitarlo a registrarse.
  registrationRequired,

  /// `unauthenticated`, `permission-denied` o `failed-precondition` (p. ej.
  /// falta App Check): reintentar solo no lo arregla; el envío se detiene de
  /// una vez.
  blocked,

  /// `resource-exhausted`: demasiados envíos en un minuto.
  rateLimited,

  /// `failed-precondition` con `details.reason == "wrong-limit"`: el jugador
  /// ya gastó los intentos fallidos del reto de hoy. Reintentar no sirve.
  wrongLimit,

  /// `failed-precondition` con `details.reason == "email-unverified"`: la
  /// cuenta de correo no está verificada y el reto la exige.
  emailUnverified,

  /// `invalid-argument` o `not-found`: el servidor no lo aceptará nunca tal
  /// cual.
  rejected,
}

class ValidationException implements Exception {
  const ValidationException(this.kind, [this.detail = '', this.message]);

  final ValidationFailure kind;
  final String detail;

  /// Mensaje en español del servidor (`HttpsError`), si lo trae. Sirve para
  /// decirle al jugador por qué se rechazó su apodo.
  final String? message;

  @override
  String toString() => 'ValidationException(${kind.name}) $detail';
}

/// Un envío de `submitSolution`. El [submissionId] se genera una vez por
/// envío y se repite tal cual en los reintentos.
@immutable
class SubmitRequest {
  const SubmitRequest({
    required this.caseId,
    required this.positions,
    required this.clientElapsedMs,
    required this.startedOnline,
    required this.submissionId,
    this.localDate,
  });

  final String caseId;

  /// Fecha local del jugador (`YYYY-MM-DD`). Obligatoria en los retos
  /// (`reto-*`): el servidor la usa para la puerta del día.
  final String? localDate;

  /// personaje -> casilla.
  final Map<String, int> positions;
  final int clientElapsedMs;
  final bool startedOnline;
  final String submissionId;

  Map<String, Object> toCallData() => {
    'caseId': caseId,
    'positions': positions,
    'clientElapsedMs': clientElapsedMs,
    'startedOnline': startedOnline,
    'submissionId': submissionId,
    if (localDate != null) 'localDate': localDate!,
  };
}

/// Respuesta de `submitSolution`.
sealed class SubmitResponse {
  const SubmitResponse();
}

/// `{result: "solved", murdererId, lethalWeaponId, ranked}` y, si es un reto,
/// `{serverElapsedMs, errors, score, rank}`.
class SubmitSolved extends SubmitResponse {
  const SubmitSolved({
    required this.murdererId,
    required this.lethalWeaponId,
    required this.ranked,
    this.serverElapsedMs,
    this.errors,
    this.score,
    this.rank,
  });

  final String murdererId;
  final String? lethalWeaponId;
  final bool ranked;

  /// Solo en los retos: tiempo medido por el servidor, desde `startedAt`.
  final int? serverElapsedMs;

  /// Solo en los retos: errores contados por el servidor.
  final int? errors;

  /// Solo en los retos: `serverElapsedMs + errors × penalización`.
  final int? score;

  /// Solo en los retos: puesto del día, o null si no entró al ranking.
  final int? rank;
}

/// `{result: "wrong", wrongCount}`.
class SubmitWrong extends SubmitResponse {
  const SubmitWrong(this.wrongCount);

  final int wrongCount;
}

int? _intOrNull(Object? v) => v is num && v >= 0 ? v.toInt() : null;

/// Lee la respuesta cruda de `submitSolution`. Lanza [ValidationException]
/// de tipo `serverError` si no tiene la forma esperada.
SubmitResponse parseSubmitResponse(Object? raw) {
  if (raw is Map) {
    final result = raw['result'];
    if (result == 'solved') {
      final murderer = raw['murdererId'];
      final weapon = raw['lethalWeaponId'];
      // Sin asesino la victoria no se puede mostrar: respuesta mal formada.
      if (murderer is String && murderer.isNotEmpty) {
        return SubmitSolved(
          murdererId: murderer,
          lethalWeaponId: weapon is String ? weapon : null,
          ranked: raw['ranked'] == true,
          serverElapsedMs: _intOrNull(raw['serverElapsedMs']),
          errors: _intOrNull(raw['errors']),
          score: _intOrNull(raw['score']),
          rank: _intOrNull(raw['rank']),
        );
      }
    }
    if (result == 'wrong') {
      final n = raw['wrongCount'];
      if (n is num && n >= 0) return SubmitWrong(n.toInt());
    }
  }
  throw const ValidationException(
    ValidationFailure.serverError,
    'Respuesta inesperada del servidor.',
  );
}

/// Respuesta de `getDailyChallenge`: el reto que toca en esa fecha local.
@immutable
class DailyChallengeInfo {
  const DailyChallengeInfo({required this.localDate, required this.caseId});

  final String localDate;
  final String caseId;
}

/// Lee la respuesta cruda de `getDailyChallenge`.
DailyChallengeInfo parseDailyChallenge(Object? raw) {
  if (raw is Map) {
    final date = raw['localDate'];
    final id = raw['caseId'];
    if (date is String && id is String && id.isNotEmpty) {
      return DailyChallengeInfo(localDate: date, caseId: id);
    }
  }
  throw const ValidationException(
    ValidationFailure.serverError,
    'Respuesta inesperada del servidor.',
  );
}

/// Lee la respuesta cruda de `setNickname`: el apodo ya limpio.
String parseNicknameResponse(Object? raw) {
  if (raw is Map) {
    final nick = raw['nickname'];
    if (nick is String && nick.isNotEmpty) return nick;
  }
  throw const ValidationException(
    ValidationFailure.serverError,
    'Respuesta inesperada del servidor.',
  );
}

/// Fecha local en formato `YYYY-MM-DD`, como la pide el servidor.
String formatLocalDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// El servidor visto desde la app.
abstract class ValidationClient {
  /// true si la sesión es de invitado (anónima) o todavía no hay sesión;
  /// false si el usuario ya se registró (Google/Apple). Vale tras
  /// [ensureSession].
  bool get isAnonymous;

  /// Asegura la sesión anónima. No hace falta llamarla antes de las demás:
  /// cada llamada la asegura por su cuenta.
  Future<void> ensureSession();

  /// `startCase`: el servidor anota cuándo empezó el jugador. Es idempotente.
  /// [localDate] es obligatoria en los retos (`reto-*`). Devuelve `startedAt`
  /// (ms desde la época), o null si la respuesta no lo trae.
  Future<int?> startCase(String caseId, {String? localDate});

  /// `submitSolution`.
  Future<SubmitResponse> submitSolution(SubmitRequest request);

  /// `getDailyChallenge`: qué reto toca en [localDate] (`YYYY-MM-DD`).
  Future<DailyChallengeInfo> getDailyChallenge(String localDate);

  /// `setNickname`: devuelve el apodo ya limpio. El servidor lanza
  /// [ValidationFailure.rejected] (con `message`) si no cumple las reglas.
  Future<String> setNickname(String nickname);

  /// Apodo guardado en el servidor para la sesión actual (`users/{uid}`,
  /// que las reglas dejan leer a su dueño). null si no hay, o si no se pudo
  /// leer (sin señal u otro fallo): nunca lanza.
  Future<String?> fetchServerNickname();

  /// `deleteAccount`: borra la cuenta y sus datos en el servidor.
  Future<void> deleteAccount();
}

/// Cliente de un servidor al que no se pudo llegar (Firebase no arrancó):
/// todo queda como "sin conexión" y los envíos esperan en la cola. Nunca
/// valida en el teléfono.
class UnavailableValidationClient implements ValidationClient {
  const UnavailableValidationClient();

  static const _error = ValidationException(
    ValidationFailure.network,
    'El servidor no está disponible.',
  );

  @override
  bool get isAnonymous => true;

  @override
  Future<void> ensureSession() => Future.error(_error);

  @override
  Future<int?> startCase(String caseId, {String? localDate}) =>
      Future.error(_error);

  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) =>
      Future.error(_error);

  @override
  Future<DailyChallengeInfo> getDailyChallenge(String localDate) =>
      Future.error(_error);

  @override
  Future<String> setNickname(String nickname) => Future.error(_error);

  @override
  Future<String?> fetchServerNickname() async => null;

  @override
  Future<void> deleteAccount() => Future.error(_error);
}
