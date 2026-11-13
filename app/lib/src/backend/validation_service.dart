/// Validación contra el servidor con cola de envíos pendientes (ADR-0016,
/// punto 1): sin señal se juega, pero Resolver espera la señal.
///
/// El servicio no conoce Firebase ni widgets: habla con un [ValidationClient]
/// y guarda la cola en SharedPreferences (clave `pending:submissions`), así que
/// se prueba sin red con un cliente falso. Cada envío lleva un `submissionId`
/// que se genera una sola vez y se repite tal cual en cada reintento; el
/// servidor devuelve la misma respuesta sin sumar otro intento ni error.
///
/// SharedPreferences es solo cache de lo que el jugador ya hizo: la verdad
/// oficial la tiene el servidor.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/saved_game.dart';
import 'validation_client.dart';

/// Clave de la cola de envíos pendientes.
const kPendingKey = 'pending:submissions';

String _startedKey(String caseId) => 'started:$caseId';

/// Inicio oficial de un reto del día (`startedAt` del servidor): JSON
/// `{date, at}` con la fecha local del reto y los ms desde la época (`at`
/// falta si el inicio fue sin conexión). Es cache: la verdad la tiene el
/// servidor.
String startedAtKey(String caseId) => 'startedAt:$caseId';
String _doneKey(String caseId) => 'done:$caseId';

/// Tamaño del id de cada envío (el servidor pide de 8 a 64 caracteres).
const _kSubmissionIdLength = 28;
const _kIdChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Campos del resultado oficial de un reto para guardar en `done:<caso>`:
/// vacío si no es un reto o el servidor no devolvió tiempo y score.
Map<String, Object?> dailyResultJson(PendingSubmission p, SubmitSolved r) {
  final ms = r.serverElapsedMs;
  final score = r.score;
  final localDate = p.localDate;
  if (!p.caseId.startsWith('reto-') ||
      ms == null ||
      score == null ||
      localDate == null) {
    return const {};
  }
  return {
    'localDate': localDate,
    'serverElapsedMs': ms,
    'serverErrors': r.errors ?? p.errorCount,
    'score': score,
    'rank': r.rank,
  };
}

/// Un envío de Resolver que aún no tiene respuesta del servidor.
@immutable
class PendingSubmission {
  const PendingSubmission({
    required this.caseId,
    required this.submissionId,
    required this.positions,
    required this.clientElapsedMs,
    required this.startedOnline,
    required this.elapsedSeconds,
    required this.errorCount,
    required this.createdAt,
    this.serverErrors = 0,
    this.stalled = false,
    this.localDate,
  });

  final String caseId;
  final String submissionId;

  /// Fecha local (`YYYY-MM-DD`) con que se envía un reto (`reto-*`). Se fija al
  /// enviar y se repite igual en los reintentos.
  final String? localDate;
  final Map<String, int> positions;
  final int clientElapsedMs;
  final bool startedOnline;

  /// Tiempo y errores de la partida en el momento de resolver: son los datos
  /// de la pantalla de victoria si la respuesta llega cuando el jugador ya no
  /// está en el caso.
  final int elapsedSeconds;
  final int errorCount;
  final DateTime createdAt;

  /// Errores del servidor seguidos en los reintentos (no cuenta la falta de
  /// señal).
  final int serverErrors;

  /// El envío se detuvo: no se reintenta solo hasta que el jugador decida
  /// reintentar o cancelar.
  final bool stalled;

  PendingSubmission copyWith({
    int? serverErrors,
    bool? stalled,
    String? localDate,
  }) => PendingSubmission(
    caseId: caseId,
    submissionId: submissionId,
    positions: positions,
    clientElapsedMs: clientElapsedMs,
    startedOnline: startedOnline,
    elapsedSeconds: elapsedSeconds,
    errorCount: errorCount,
    createdAt: createdAt,
    serverErrors: serverErrors ?? this.serverErrors,
    stalled: stalled ?? this.stalled,
    localDate: localDate ?? this.localDate,
  );

  SubmitRequest toRequest() => SubmitRequest(
    caseId: caseId,
    localDate: localDate,
    positions: positions,
    clientElapsedMs: clientElapsedMs,
    startedOnline: startedOnline,
    submissionId: submissionId,
  );

  Map<String, Object> toJson() => {
    'caseId': caseId,
    'submissionId': submissionId,
    'positions': positions,
    'clientElapsedMs': clientElapsedMs,
    'startedOnline': startedOnline,
    'elapsedSeconds': elapsedSeconds,
    'errorCount': errorCount,
    'createdAt': createdAt.toIso8601String(),
    'serverErrors': serverErrors,
    'stalled': stalled,
    if (localDate != null) 'localDate': localDate!,
  };

  /// Null si el dato está dañado.
  static PendingSubmission? fromJson(Object? json) {
    if (json is! Map) return null;
    try {
      final positions = json['positions'];
      if (positions is! Map) return null;
      final caseId = json['caseId'];
      final id = json['submissionId'];
      final clientMs = json['clientElapsedMs'];
      final started = json['startedOnline'];
      final secs = json['elapsedSeconds'];
      final errors = json['errorCount'];
      final created = json['createdAt'];
      final serverErrors = json['serverErrors'];
      final stalled = json['stalled'];
      final localDate = json['localDate'];
      if (caseId is! String || id is! String) return null;
      if (clientMs is! int || started is! bool) return null;
      if (secs is! int || errors is! int || created is! String) return null;
      return PendingSubmission(
        caseId: caseId,
        submissionId: id,
        positions: {
          for (final e in positions.entries) e.key as String: e.value as int,
        },
        clientElapsedMs: clientMs,
        startedOnline: started,
        elapsedSeconds: secs,
        errorCount: errors,
        createdAt: DateTime.parse(created),
        serverErrors: serverErrors is int && serverErrors >= 0
            ? serverErrors
            : 0,
        stalled: stalled == true,
        localDate: localDate is String ? localDate : null,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

/// Resultado de un envío hecho desde la partida.
sealed class SubmitOutcome {
  const SubmitOutcome();
}

class OutcomeSolved extends SubmitOutcome {
  const OutcomeSolved(this.response);
  final SubmitSolved response;
}

class OutcomeWrong extends SubmitOutcome {
  const OutcomeWrong(this.response);
  final SubmitWrong response;
}

/// Sin señal (o error del servidor): el envío queda en la cola, "por validar".
class OutcomeQueued extends SubmitOutcome {
  const OutcomeQueued();
}

/// Demasiados envíos en un minuto.
class OutcomeRateLimited extends SubmitOutcome {
  const OutcomeRateLimited();
}

/// El servidor no aceptará este envío nunca (entrada inválida o caso
/// inexistente).
class OutcomeRejected extends SubmitOutcome {
  const OutcomeRejected();
}

/// Un invitado pidió un caso que no es gratis: hay que invitarlo a registrarse.
/// El envío no se guarda en la cola.
class OutcomeRegistrationRequired extends SubmitOutcome {
  const OutcomeRegistrationRequired();
}

/// Ya no quedan intentos fallidos del reto de hoy. El envío no se guarda.
class OutcomeWrongLimit extends SubmitOutcome {
  const OutcomeWrongLimit();
}

/// La cuenta de correo no está verificada y el reto lo exige. El envío no se
/// guarda en la cola.
class OutcomeEmailUnverified extends SubmitOutcome {
  const OutcomeEmailUnverified();
}

/// El servidor respondió con errores seguidos (o falta algo que reintentar no
/// arregla): el envío se detiene y el jugador elige Reintentar o Cancelar.
class OutcomeStalled extends SubmitOutcome {
  const OutcomeStalled();
}

enum ValidationEventKind {
  solved,
  wrong,
  rejected,
  stalled,
  registrationRequired,
  wrongLimit,
  emailUnverified,
}

/// Respuesta de un envío que estaba en la cola (el jugador ya no esperaba).
@immutable
class ValidationEvent {
  const ValidationEvent(this.kind, this.submission, [this.response]);

  final ValidationEventKind kind;
  final PendingSubmission submission;

  /// [SubmitSolved] o [SubmitWrong]; null si el envío fue rechazado o se
  /// detuvo.
  final SubmitResponse? response;

  String get caseId => submission.caseId;
}

class ValidationService {
  ValidationService({
    required this.client,
    Future<SharedPreferences> Function()? loadPrefs,
    this.retryEvery = const Duration(seconds: 60),
    this.serverErrorRetryLimit = 3,
    this.onPendingChanged,
    String Function()? newId,
    DateTime Function()? clock,
  }) : _loadPrefs = loadPrefs ?? SharedPreferences.getInstance,
       _newId = newId ?? _randomId,
       _clock = clock ?? DateTime.now;

  final ValidationClient client;
  final Duration retryEvery;

  /// Errores seguidos del servidor que se reintentan antes de detener el
  /// envío.
  final int serverErrorRetryLimit;

  /// Se llama cada vez que cambia el conjunto de casos "por validar".
  final void Function(Set<String> caseIds)? onPendingChanged;

  final Future<SharedPreferences> Function() _loadPrefs;
  final String Function() _newId;
  final DateTime Function() _clock;

  final Map<String, PendingSubmission> _queue = {};
  final Set<String> _inFlight = {};
  final Map<String, Future<bool>> _starts = {};
  final Map<String, SubmitSolved> _solved = {};
  final StreamController<ValidationEvent> _events =
      StreamController<ValidationEvent>.broadcast();

  Future<SharedPreferences>? _prefsFuture;
  Future<void>? _ready;
  Future<void>? _sessionFuture;
  Timer? _timer;
  bool _flushing = false;
  bool _disposed = false;

  Future<SharedPreferences> _prefs() => _prefsFuture ??= _loadPrefs();

  /// Respuestas que llegan de la cola.
  Stream<ValidationEvent> get events => _events.stream;

  /// Casos cuya partida está abierta en pantalla: su controlador recibe las
  /// respuestas de la cola y no hace falta un aviso aparte.
  final Set<String> activeCases = {};

  /// Casos con un envío esperando respuesta (vale tras [ready]).
  Set<String> get pendingCaseIds => Set.unmodifiable(_queue.keys);

  bool isPending(String caseId) => _queue.containsKey(caseId);

  /// Última respuesta "resuelto" del servidor para [caseId] en esta sesión
  /// (la pantalla de victoria muestra de ahí el tiempo, el score y el puesto
  /// de un reto). Null si no hubo.
  SubmitSolved? solvedResponse(String caseId) => _solved[caseId];

  /// El envío de este caso se detuvo y espera la decisión del jugador.
  bool isStalled(String caseId) => _queue[caseId]?.stalled ?? false;

  /// Se completa cuando la cola guardada ya se leyó.
  Future<void> get ready => _ready ??= _loadQueue();

  /// Id nuevo para un envío.
  String newSubmissionId() => _newId();

  DateTime now() => _clock();

  static String _randomId() {
    final r = math.Random.secure();
    return 'sub-${String.fromCharCodes([for (var i = 0; i < _kSubmissionIdLength; i++) _kIdChars.codeUnitAt(r.nextInt(_kIdChars.length))])}';
  }

  // ---- sesión -----------------------------------------------------------------

  /// La sesión anónima, compartida: una sola llamada a [ValidationClient.ensureSession]
  /// a la vez, y ninguna llamada a una función sale antes de que termine. Si
  /// falla, la siguiente llamada vuelve a intentarlo.
  Future<void> _session() => _sessionFuture ??= () async {
    try {
      await client.ensureSession();
    } on Object {
      _sessionFuture = null;
      rethrow;
    }
  }();

  // ---- arranque ---------------------------------------------------------------

  /// Lee la cola guardada, inicia la sesión (si hay red) y reintenta lo que
  /// quedó pendiente. Nunca lanza.
  Future<void> start() async {
    await ready;
    try {
      await _session();
    } on Object catch (e) {
      debugPrint('Sin sesión por ahora: $e');
    }
    await flush();
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(kPendingKey);
      if (raw != null) {
        final json = jsonDecode(raw);
        final items = json is Map ? json['items'] : null;
        if (items is List) {
          for (final item in items) {
            final p = PendingSubmission.fromJson(item);
            if (p != null) _queue[p.caseId] = p;
          }
        }
      }
    } on Object catch (e) {
      debugPrint('Cola de envíos ilegible, se empieza vacía: $e');
    }
    _syncTimer();
    _notify();
  }

  Future<void> _persist() async {
    final prefs = await _prefs();
    if (_queue.isEmpty) {
      await prefs.remove(kPendingKey);
    } else {
      await prefs.setString(
        kPendingKey,
        jsonEncode({
          'v': 1,
          'items': [for (final p in _queue.values) p.toJson()],
        }),
      );
    }
  }

  void _notify() => onPendingChanged?.call(pendingCaseIds);

  void _syncTimer() {
    if (_disposed) return;
    // Los envíos detenidos no se reintentan solos.
    if (_queue.values.every((p) => p.stalled)) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(retryEvery, (_) => unawaited(flush()));
    }
  }

  // ---- inicio de partida --------------------------------------------------------

  /// Avisa al servidor de que el jugador empezó el caso (`startCase`) y dice
  /// si fue con conexión. No lanza: sin red devuelve false. La respuesta se
  /// guarda por caso, así que reabrir el caso a mitad de partida no cambia si
  /// empezó con conexión (ADR-0016, punto 5).
  ///
  /// Solo se llama al abrir el caso. Si falla por un error del servidor no
  /// guarda nada y se vuelve a probar en una apertura posterior, siempre que
  /// la partida siga sin tiempo jugado ([alreadyPlayed] false).
  ///
  /// [alreadyPlayed] es para una partida guardada con tiempo que no tiene
  /// registro de cómo empezó: se da por empezada sin conexión (sin ranking) y
  /// no se llama a `startCase`, porque un inicio tardío haría pasar por
  /// recién empezada una partida vieja.
  Future<bool> ensureStarted(String caseId, {bool alreadyPlayed = false}) =>
      _starts[caseId] ??= _startOnce(caseId, alreadyPlayed);

  /// `startedAt` del servidor (ms desde la época) de un reto empezado HOY con
  /// conexión; null si no hay (sin red, otro día o dato dañado). Espera al
  /// aviso de inicio si todavía está en vuelo. Nunca llama a `startCase`.
  Future<int?> serverStartedAtMs(String caseId) async {
    final inFlight = _starts[caseId];
    if (inFlight != null) await inFlight;
    try {
      final prefs = await _prefs();
      final rec = _readStartedAt(prefs, caseId);
      if (rec == null || rec.$1 != formatLocalDate(_clock())) return null;
      return rec.$2;
    } on Object {
      return null;
    }
  }

  /// Si la partida empezó con conexión, para decidir `startedOnline` al
  /// enviar. Solo lee lo guardado (`started:<id>` == '1'): NUNCA llama a
  /// `startCase`, porque un inicio justo antes del envío fijaría la hora de
  /// inicio a milisegundos de la solución y daría un tiempo oficial casi cero.
  /// Si el aviso de inicio todavía está en vuelo, espera su resultado.
  Future<bool> startedOnlineForSubmit(String caseId) async {
    final inFlight = _starts[caseId];
    if (inFlight != null) await inFlight;
    try {
      final prefs = await _prefs();
      return prefs.getString(_startedKey(caseId)) == '1';
    } on Object {
      return false;
    }
  }

  Future<bool> _startOnce(String caseId, bool alreadyPlayed) async {
    try {
      final prefs = await _prefs();
      final isReto = caseId.startsWith('reto-');
      final today = isReto ? formatLocalDate(_clock()) : null;
      if (isReto) {
        // Un inicio guardado de otro día (el ciclo repite los retos cada 30
        // días) ya no vale: se empieza de nuevo.
        final rec = _readStartedAt(prefs, caseId);
        if (rec != null && rec.$1 != today) {
          await prefs.remove(_startedKey(caseId));
          await prefs.remove(startedAtKey(caseId));
        }
      }
      final stored = prefs.getString(_startedKey(caseId));
      if (stored == '1') return true;
      if (stored == '0') return false;
      if (alreadyPlayed) {
        await prefs.setString(_startedKey(caseId), '0');
        return false;
      }
      try {
        await _session();
        final startedAt = await client.startCase(caseId, localDate: today);
        if (today != null) {
          await prefs.setString(
            startedAtKey(caseId),
            jsonEncode({'date': today, 'at': ?startedAt}),
          );
        }
      } on ValidationException catch (e) {
        if (e.kind == ValidationFailure.network) {
          // De verdad empezó sin conexión: no entra al ranking y se recuerda.
          debugPrint('startCase sin conexión ($caseId): $e');
          await prefs.setString(_startedKey(caseId), '0');
          if (today != null) {
            await prefs.setString(
              startedAtKey(caseId),
              jsonEncode({'date': today}),
            );
          }
        } else {
          // El servidor respondió con un error: no se sabe nada de cómo empezó
          // el jugador. No se guarda nada y la próxima vez que abra el caso se
          // vuelve a probar.
          debugPrint('startCase falló en el servidor ($caseId): $e');
          _starts.remove(caseId);
        }
        return false;
      }
      await prefs.setString(_startedKey(caseId), '1');
      return true;
    } on Object catch (e) {
      debugPrint('startCase falló ($caseId): $e');
      _starts.remove(caseId);
      return false;
    }
  }

  /// `(fecha local, startedAt en ms o null)` guardado para un reto.
  static (String, int?)? _readStartedAt(SharedPreferences prefs, String id) {
    final raw = prefs.getString(startedAtKey(id));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['date'] is String) {
        final at = json['at'];
        return (json['date'] as String, at is int ? at : null);
      }
    } on FormatException {
      // dato dañado: se ignora
    }
    return null;
  }

  Future<void> _forgetStart(String caseId) async {
    _starts.remove(caseId);
    final prefs = await _prefs();
    await prefs.remove(_startedKey(caseId));
    // El inicio oficial se conserva hasta la fecha: la pantalla del reto lo
    // usa para saber que hoy ya se empezó; el resultado vive en `done:`.
  }

  // ---- envío desde la partida -------------------------------------------------------

  /// Envía el tablero. Si hay respuesta, la devuelve. Si no hay señal, el
  /// envío queda en la cola ([OutcomeQueued]) y se reintenta solo.
  ///
  /// El resultado se aplica al progreso y se publica en [events] igual que el
  /// de la cola: si el jugador salió de la partida (o volvió a entrar) mientras
  /// el envío estaba en vuelo, quien esté mirando el caso se entera. Nunca
  /// lanza.
  Future<SubmitOutcome> submit(PendingSubmission submission) async {
    await ready;
    // Los retos llevan la fecha local del jugador (puerta del día en el
    // servidor).
    if (submission.localDate == null && submission.caseId.startsWith('reto-')) {
      submission = submission.copyWith(localDate: formatLocalDate(_clock()));
    }
    if (_queue.containsKey(submission.caseId)) return const OutcomeQueued();
    _queue[submission.caseId] = submission;
    _inFlight.add(submission.submissionId);
    try {
      await _persist();
      _notify();
      final out = await _attempt(submission, direct: true);
      await _deliver(submission, out);
      return out;
    } on Object catch (e) {
      // Si algo falla (p. ej. el almacenamiento), el envío sigue en la cola en
      // memoria y se reintenta: el tablero nunca queda esperando para siempre.
      debugPrint('Envío de ${submission.caseId} no se pudo cerrar: $e');
      _notify();
      return const OutcomeQueued();
    } finally {
      _inFlight.remove(submission.submissionId);
      _syncTimer();
    }
  }

  Future<SubmitOutcome> _attempt(
    PendingSubmission p, {
    required bool direct,
  }) async {
    try {
      await _session();
      final response = await client.submitSolution(p.toRequest());
      await _drop(p);
      return switch (response) {
        SubmitSolved() => OutcomeSolved(response),
        SubmitWrong() => OutcomeWrong(response),
      };
    } on ValidationException catch (e) {
      switch (e.kind) {
        case ValidationFailure.network:
          // Sin señal no cuenta como error del servidor: se corta la racha.
          if (p.serverErrors != 0) await _update(p.copyWith(serverErrors: 0));
          return const OutcomeQueued();
        case ValidationFailure.serverError:
          return _recordServerError(p, immediate: false);
        case ValidationFailure.blocked:
          return _recordServerError(p, immediate: true);
        case ValidationFailure.rateLimited:
          // Desde la partida el jugador lo vuelve a intentar con otro envío;
          // desde la cola se conserva y se reintenta más tarde.
          if (direct) await _drop(p);
          return const OutcomeRateLimited();
        case ValidationFailure.rejected:
          await _drop(p);
          return const OutcomeRejected();
        case ValidationFailure.registrationRequired:
          await _drop(p);
          return const OutcomeRegistrationRequired();
        case ValidationFailure.wrongLimit:
          await _drop(p);
          return const OutcomeWrongLimit();
        case ValidationFailure.emailUnverified:
          await _drop(p);
          return const OutcomeEmailUnverified();
      }
    } on Object catch (e) {
      // Un error que no viene del servidor tampoco debe perder el envío.
      debugPrint('Envío de ${p.caseId} falló, queda en la cola: $e');
      return const OutcomeQueued();
    } finally {
      _inFlight.remove(p.submissionId);
    }
  }

  /// Cuenta un error del servidor. Al llegar al tope (o de una vez si es
  /// [immediate]) el envío se detiene.
  Future<SubmitOutcome> _recordServerError(
    PendingSubmission p, {
    required bool immediate,
  }) async {
    final n = p.serverErrors + 1;
    final stall = immediate || n >= serverErrorRetryLimit;
    await _update(p.copyWith(serverErrors: n, stalled: stall));
    return stall ? const OutcomeStalled() : const OutcomeQueued();
  }

  Future<void> _update(PendingSubmission p) async {
    if (_queue[p.caseId]?.submissionId != p.submissionId) return;
    _queue[p.caseId] = p;
    await _persist();
  }

  Future<void> _drop(PendingSubmission p) async {
    if (_queue[p.caseId]?.submissionId != p.submissionId) return;
    _queue.remove(p.caseId);
    await _persist();
    _notify();
  }

  /// Aplica el resultado de un envío al progreso local y lo publica en
  /// [events] (para el controlador de la partida y para el aviso discreto).
  Future<void> _deliver(PendingSubmission p, SubmitOutcome out) async {
    switch (out) {
      case OutcomeSolved(:final response):
        _solved[p.caseId] = response;
        await _applySolved(p, response);
        _emit(ValidationEvent(ValidationEventKind.solved, p, response));
      case OutcomeWrong(:final response):
        await _applyWrong(p);
        _emit(ValidationEvent(ValidationEventKind.wrong, p, response));
      case OutcomeRejected():
        _emit(ValidationEvent(ValidationEventKind.rejected, p));
      case OutcomeStalled():
        _emit(ValidationEvent(ValidationEventKind.stalled, p));
      case OutcomeRegistrationRequired():
        _emit(ValidationEvent(ValidationEventKind.registrationRequired, p));
      case OutcomeWrongLimit():
        _emit(ValidationEvent(ValidationEventKind.wrongLimit, p));
      case OutcomeEmailUnverified():
        _emit(ValidationEvent(ValidationEventKind.emailUnverified, p));
      case OutcomeRateLimited():
      case OutcomeQueued():
        break;
    }
  }

  // ---- decisión del jugador sobre un envío detenido ----------------------------------

  /// Reintentar: el envío detenido vuelve a probarse ya, con su mismo
  /// `submissionId`. La respuesta llega por [events].
  Future<void> retryStalled(String caseId) async {
    await ready;
    final p = _queue[caseId];
    if (p == null || !p.stalled || _inFlight.contains(p.submissionId)) return;
    final fresh = p.copyWith(serverErrors: 0, stalled: false);
    _inFlight.add(fresh.submissionId);
    try {
      await _update(fresh);
      final out = await _attempt(fresh, direct: false);
      await _deliver(fresh, out);
    } on Object catch (e) {
      debugPrint('Reintento de $caseId falló: $e');
    } finally {
      _inFlight.remove(fresh.submissionId);
      _syncTimer();
    }
  }

  /// Cancelar el envío: sale de la cola y el tablero se desbloquea.
  Future<void> cancel(String caseId) async {
    await ready;
    if (_queue.remove(caseId) == null) return;
    try {
      await _persist();
    } on Object catch (e) {
      debugPrint('No se pudo guardar la cancelación de $caseId: $e');
    }
    _notify();
    _syncTimer();
  }

  // ---- reintentos de la cola -----------------------------------------------------------

  /// Al volver a la app.
  void onResumed() => unawaited(flush());

  /// Reintenta los envíos pendientes con su mismo `submissionId`. Las
  /// respuestas se publican en [events] y el progreso local (`done:`,
  /// `game:`) se actualiza aunque el jugador ya no esté en el caso. Los envíos
  /// detenidos no se reintentan.
  Future<void> flush() async {
    await ready;
    if (_flushing || _disposed) return;
    _flushing = true;
    try {
      for (final p in List.of(_queue.values)) {
        if (p.stalled || _inFlight.contains(p.submissionId)) continue;
        _inFlight.add(p.submissionId);
        final out = await _attempt(p, direct: false);
        if (_disposed) return;
        await _deliver(p, out);
        if (out is OutcomeQueued) return; // sin señal: el resto tampoco llegará
      }
    } finally {
      _flushing = false;
      _syncTimer();
    }
  }

  void _emit(ValidationEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  /// Caso resuelto por una respuesta tardía: queda marcado como resuelto en el
  /// progreso local y se borra la partida guardada.
  Future<void> _applySolved(PendingSubmission p, SubmitSolved r) async {
    try {
      final prefs = await _prefs();
      final fresh = dailyResultJson(p, r);
      if (!prefs.containsKey(_doneKey(p.caseId)) ||
          _isStaleDaily(prefs.getString(_doneKey(p.caseId)), fresh)) {
        await prefs.setString(
          _doneKey(p.caseId),
          jsonEncode({
            'time': p.elapsedSeconds,
            'errors': p.errorCount,
            'date': _clock().toIso8601String().substring(0, 16),
            ...fresh,
          }),
        );
      }
      await SavedGame.clear(prefs, p.caseId);
      await _forgetStart(p.caseId);
    } on Object catch (e) {
      debugPrint('No se pudo guardar el progreso de ${p.caseId}: $e');
    }
  }

  /// El `done:` guardado es de otro día del mismo reto (el ciclo los repite
  /// cada 30 días): el de hoy lo reemplaza.
  static bool _isStaleDaily(String? raw, Map<String, Object?> fresh) {
    final date = fresh['localDate'];
    if (raw == null || date == null) return false;
    try {
      final json = jsonDecode(raw);
      return json is Map && json['localDate'] != date;
    } on FormatException {
      return true;
    }
  }

  /// Respuesta tardía "incorrecto": la partida guardada suma el error.
  Future<void> _applyWrong(PendingSubmission p) async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(SavedGame.keyFor(p.caseId));
      if (raw == null) return;
      final saved = SavedGame.decode(raw);
      if (saved == null) return;
      await SavedGame.write(
        prefs,
        p.caseId,
        SavedGame(
          elapsed: saved.elapsed,
          errors: saved.errors + 1,
          savedAt: saved.savedAt,
          board: saved.board,
          clueMarks: saved.clueMarks,
          autoX: saved.autoX,
          mapMode: saved.mapMode,
        ),
      );
    } on Object catch (e) {
      debugPrint('No se pudo guardar el error de ${p.caseId}: $e');
    }
  }

  /// Tras borrar la cuenta: olvida la cola, los inicios y la sesión en
  /// memoria (lo guardado en SharedPreferences lo limpia quien llama). La
  /// próxima llamada inicia una sesión anónima nueva.
  Future<void> resetAfterAccountDeletion() async {
    _queue.clear();
    _starts.clear();
    _inFlight.clear();
    _sessionFuture = null;
    _timer?.cancel();
    _timer = null;
    _notify();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    unawaited(_events.close());
  }
}
