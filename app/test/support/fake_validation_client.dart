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

  /// `localDate` con que llegó cada `startCase` (null si no se envió).
  final List<String?> startDates = [];

  /// Lo que contestaría `getDailyChallenge` (por fecha); si falta, `reto-001`.
  final Map<String, String> dailyByDate = {};

  /// `startedAt` que devuelve `startCase` (ms desde la época).
  int startedAtMs = 1700000000000;

  /// Respuesta de un reto resuelto: tiempo del servidor, penalización por
  /// error (30 s) y puesto. `retoRank` null = no entró al ranking.
  int retoElapsedMs = 95000;
  int? retoRank = 3;
  int retoErrors = 1;

  /// false = usuario registrado (Google/Apple); true = invitado.
  bool anonymous = true;

  @override
  bool get isAnonymous => anonymous;

  /// true = `submitSolution` responde "Regístrate para seguir jugando".
  bool requiresRegistration = false;

  /// Apodo guardado en el "servidor" y palabras que el filtro rechaza.
  String? serverNickname;
  final Set<String> blockedWords = {'groseria'};
  final List<String> nicknameCalls = [];
  bool accountDeleted = false;
  int deleteCalls = 0;
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
  Future<int?> startCase(String caseId, {String? localDate}) async {
    log.add('start:$caseId');
    _checkNetwork();
    final failure = startFailure;
    if (failure != null) throw ValidationException(failure, 'falla');
    starts.add(caseId);
    startDates.add(localDate);
    return startedAtMs;
  }

  @override
  Future<DailyChallengeInfo> getDailyChallenge(String localDate) async {
    log.add('daily:$localDate');
    _checkNetwork();
    return DailyChallengeInfo(
      localDate: localDate,
      caseId: dailyByDate[localDate] ?? 'reto-001',
    );
  }

  @override
  Future<String> setNickname(String nickname) async {
    log.add('nick');
    nicknameCalls.add(nickname);
    _checkNetwork();
    final clean = nickname.trim();
    final lower = clean.toLowerCase();
    if (blockedWords.any(lower.contains)) {
      throw const ValidationException(
        ValidationFailure.rejected,
        'invalid-argument',
        'Ese apodo no está permitido.',
      );
    }
    if (clean.length < 3 || clean.length > 16) {
      throw const ValidationException(
        ValidationFailure.rejected,
        'invalid-argument',
        'El apodo debe tener entre 3 y 16 caracteres.',
      );
    }
    serverNickname = clean;
    return clean;
  }

  @override
  Future<void> deleteAccount() async {
    log.add('delete');
    deleteCalls++;
    _checkNetwork();
    accountDeleted = true;
    serverNickname = null;
  }

  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) async {
    log.add('submit:${request.caseId}');
    submits.add(request); // se anota también si falla: cuenta los intentos
    _checkNetwork();
    final failure = submitFailure;
    if (failure != null) throw ValidationException(failure, 'falla');
    if (requiresRegistration) {
      throw const ValidationException(
        ValidationFailure.registrationRequired,
        'failed-precondition',
        'Regístrate para seguir jugando',
      );
    }
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
        // Solo los retos traen tiempo del servidor, score y puesto.
        serverElapsedMs: request.caseId.startsWith('reto-')
            ? retoElapsedMs
            : null,
        errors: request.caseId.startsWith('reto-') ? retoErrors : null,
        score: request.caseId.startsWith('reto-')
            ? retoElapsedMs + retoErrors * 30000
            : null,
        rank: request.caseId.startsWith('reto-') ? retoRank : null,
      );
    } else {
      response = SubmitWrong(wrong);
    }
    _seen[request.submissionId] = response;
    return response;
  }
}
