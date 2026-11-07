/// Servidor falso para probar la validación sin red. Imita el contrato de
/// backend/functions/src/index.ts: compara con una solución que da la prueba,
/// responde `solved` o `wrong` con el conteo, y repite la misma respuesta si
/// llega el mismo `submissionId`.
library;

import 'dart:async';

import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';

class FakeValidationClient implements ValidationClient {
  /// Solución por caso (solo vive en la prueba, como en el servidor).
  final Map<String, PuzzleCase> cases = {};

  /// false = sin señal: toda llamada falla con [ValidationFailure.network].
  bool online = true;

  /// true = el servidor responde `resource-exhausted`.
  bool rateLimited = false;

  /// true = el servidor responde `invalid-argument`.
  bool rejects = false;

  /// Si no es null, `submitSolution` falla con este tipo de error (el
  /// servidor responde con un error, o falta algo como App Check).
  ValidationFailure? submitFailure;

  /// Si no es null, `startCase` falla con este tipo de error.
  ValidationFailure? startFailure;

  /// Si no es null, `ensureSession` espera a que la prueba lo complete (una
  /// sesión lenta, como al restaurarla en web).
  Completer<void>? sessionGate;

  /// true = no se puede iniciar ni restaurar la sesión.
  bool sessionFails = false;

  /// Orden en que se hicieron las llamadas: `session:begin`, `session:end`,
  /// `start:<caso>`, `submit:<caso>`.
  final List<String> log = [];

  final List<SubmitRequest> submits = [];
  final List<String> starts = [];
  int sessions = 0;
  final Map<String, SubmitResponse> _seen = {};

  void add(PuzzleCase pc) => cases[pc.caseId] = pc;

  void _checkNetwork() {
    if (!online) {
      throw const ValidationException(ValidationFailure.network, 'sin señal');
    }
  }

  @override
  Future<void> ensureSession() async {
    sessions++;
    log.add('session:begin');
    final gate = sessionGate;
    if (gate != null) await gate.future;
    // Una sesión ya guardada se restaura sin red: solo falla si la prueba lo pide.
    if (sessionFails) {
      throw const ValidationException(ValidationFailure.network, 'sin señal');
    }
    log.add('session:end');
  }

  @override
  Future<void> startCase(String caseId) async {
    log.add('start:$caseId');
    _checkNetwork();
    final failure = startFailure;
    if (failure != null) throw ValidationException(failure, 'falla');
    starts.add(caseId);
  }

  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) async {
    log.add('submit:${request.caseId}');
    submits.add(request); // se anota también si falla: cuenta los intentos
    _checkNetwork();
    final failure = submitFailure;
    if (failure != null) throw ValidationException(failure, 'falla');
    final seen = _seen[request.submissionId];
    if (seen != null) return seen;
    if (rejects) {
      throw const ValidationException(ValidationFailure.rejected, 'invalid');
    }
    if (rateLimited) {
      throw const ValidationException(ValidationFailure.rateLimited, 'limit');
    }
    final pc = cases[request.caseId];
    if (pc == null) {
      throw const ValidationException(ValidationFailure.rejected, 'not-found');
    }
    var wrong = 0;
    for (final e in request.positions.entries) {
      if (pc.solution.positions[e.key] != e.value) wrong++;
    }
    final SubmitResponse response;
    if (wrong == 0) {
      final v = Validator.validate(pc, request.positions);
      response = SubmitSolved(
        murdererId: v.murdererId!,
        lethalWeaponId: v.lethalWeaponId,
        ranked: request.startedOnline,
      );
    } else {
      response = SubmitWrong(wrong);
    }
    _seen[request.submissionId] = response;
    return response;
  }
}
