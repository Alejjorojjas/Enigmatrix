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

  /// `unauthenticated`, `permission-denied` o `failed-precondition` (p. ej.
  /// falta App Check): reintentar solo no lo arregla; el envío se detiene de
  /// una vez.
  blocked,

  /// `resource-exhausted`: demasiados envíos en un minuto.
  rateLimited,

  /// `invalid-argument` o `not-found`: el servidor no lo aceptará nunca tal
  /// cual.
  rejected,
}

class ValidationException implements Exception {
  const ValidationException(this.kind, [this.detail = '']);

  final ValidationFailure kind;
  final String detail;

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
  });

  final String caseId;

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
  };
}

/// Respuesta de `submitSolution`.
sealed class SubmitResponse {
  const SubmitResponse();
}

/// `{result: "solved", murdererId, lethalWeaponId, ranked}`.
class SubmitSolved extends SubmitResponse {
  const SubmitSolved({
    required this.murdererId,
    required this.lethalWeaponId,
    required this.ranked,
  });

  final String murdererId;
  final String? lethalWeaponId;
  final bool ranked;
}

/// `{result: "wrong", wrongCount}`.
class SubmitWrong extends SubmitResponse {
  const SubmitWrong(this.wrongCount);

  final int wrongCount;
}

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

/// El servidor visto desde la app.
abstract class ValidationClient {
  /// Asegura la sesión anónima. No hace falta llamarla antes de las demás:
  /// cada llamada la asegura por su cuenta.
  Future<void> ensureSession();

  /// `startCase`: el servidor anota cuándo empezó el jugador. Es idempotente.
  Future<void> startCase(String caseId);

  /// `submitSolution`.
  Future<SubmitResponse> submitSolution(SubmitRequest request);
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
  Future<void> ensureSession() => Future.error(_error);

  @override
  Future<void> startCase(String caseId) => Future.error(_error);

  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) =>
      Future.error(_error);
}
