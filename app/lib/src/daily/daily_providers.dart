/// Estado del reto diario y del ranking en modo servidor (ronda F2b). Con el
/// modo `none` nada de esto se usa.
library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_providers.dart';
import '../backend/backend_config.dart';
import '../backend/firebase_validation_client.dart';
import '../backend/validation_client.dart';
import '../backend/validation_providers.dart';
import '../backend/validation_service.dart' show startedAtKey;
import 'daily_logic.dart';
import 'ranking_source.dart';

/// Reloj del reto (la fecha local sale de aquí). Los tests lo sobreescriben.
final dailyClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Punto de extensión: qué pasa cuando un invitado pide registrarse desde el
/// reto o el ranking. Por defecto abre la ruta `/registro`; `main.dart` o los
/// tests pueden sobreescribirlo.
final onRegistrationRequestedProvider = Provider<void Function(BuildContext)>(
  (ref) =>
      (context) => context.push('/registro'),
);

/// Fuente del ranking: Firestore en modo servidor; null si no hay (modo
/// `none`, Firebase no arrancó o cliente que no es el de Firebase). Los tests
/// la sobreescriben con una falsa.
final dailyRankingSourceProvider = Provider<DailyRankingSource?>((ref) {
  final mode = ref.watch(backendModeProvider);
  final client = ref.watch(validationClientProvider);
  if (!mode.usesServer || client is! FirebaseValidationClient) return null;
  return FirestoreRankingSource.forMode(
    mode,
    () => FirebaseAuth.instance.currentUser?.uid,
  );
});

/// Cómo se consultó el reto de hoy.
enum DailyConnection {
  /// El servidor dijo qué reto toca: la partida entra al ranking.
  online,

  /// Sin señal: se usa la fórmula local y la partida no entra al ranking.
  offline,

  /// El servidor respondió con un error (p. ej. la fecha del teléfono no
  /// coincide): igual que sin conexión.
  error,
}

class DailyTabState {
  const DailyTabState({
    required this.localDate,
    required this.caseId,
    required this.connection,
    this.guest = false,
    this.errorMessage,
    this.result,
    this.startedToday = false,
    this.startedAtMs,
  });

  /// Fecha local de hoy (`YYYY-MM-DD`).
  final String localDate;

  /// Reto que toca hoy.
  final String caseId;
  final DailyConnection connection;

  /// Sesión de invitado: debe registrarse para jugar el reto.
  final bool guest;

  /// Mensaje en español del servidor, si lo trajo.
  final String? errorMessage;

  /// Resultado de hoy si ya lo resolvió.
  final DailyResult? result;

  /// Ya empezó el reto de hoy (aviso de inicio guardado).
  final bool startedToday;

  /// `startedAt` del servidor (ms desde la época); null si empezó sin
  /// conexión o no se sabe.
  final int? startedAtMs;

  bool get solved => result != null;
  bool get ranked => connection == DailyConnection.online;
}

/// Lee de SharedPreferences si el reto de hoy ya se resolvió o empezó.
({DailyResult? result, bool started, int? startedAt}) readDailyProgress(
  SharedPreferences prefs,
  String caseId,
  String localDate,
) {
  DailyResult? result;
  final done = prefs.getString('done:$caseId');
  if (done != null) {
    try {
      final r = DailyResult.fromJson(jsonDecode(done));
      if (r != null && r.localDate == localDate) result = r;
    } on FormatException {
      // dato dañado: se ignora
    }
  }
  var started = false;
  int? startedAt;
  final rec = prefs.getString(startedAtKey(caseId));
  if (rec != null) {
    try {
      final json = jsonDecode(rec);
      if (json is Map && json['date'] == localDate) {
        started = true;
        final at = json['at'];
        if (at is int) startedAt = at;
      }
    } on FormatException {
      // dato dañado: se ignora
    }
  }
  return (result: result, started: started, startedAt: startedAt);
}

/// Estado de la pestaña Reto: consulta el reto de hoy al servidor (con la
/// fórmula local de respaldo) y lee el progreso guardado.
final dailyTabProvider = FutureProvider.autoDispose<DailyTabState>((ref) async {
  final clock = ref.watch(dailyClockProvider);
  final localDate = formatLocalDate(clock());
  final localCase = dailyCaseIdForLocalDate(localDate);
  final client = ref.watch(validationClientProvider);
  final prefs = await SharedPreferences.getInstance();

  Future<DailyTabState> build(
    String caseId,
    DailyConnection connection, {
    String? message,
    bool guest = false,
  }) async {
    final p = readDailyProgress(prefs, caseId, localDate);
    return DailyTabState(
      localDate: localDate,
      caseId: caseId,
      connection: connection,
      guest: guest,
      errorMessage: message,
      result: p.result,
      startedToday: p.started,
      startedAtMs: p.startedAt,
    );
  }

  if (client == null || !ref.watch(backendModeProvider).usesServer) {
    return build(localCase, DailyConnection.offline);
  }
  DailyConnection failure = DailyConnection.offline;
  String? message;
  try {
    await client.ensureSession();
    if (ref.read(isGuestProvider)) {
      return build(localCase, DailyConnection.online, guest: true);
    }
    final info = await client.getDailyChallenge(localDate);
    return build(info.caseId, DailyConnection.online);
  } on ValidationException catch (e) {
    failure = e.kind == ValidationFailure.network
        ? DailyConnection.offline
        : DailyConnection.error;
    message = e.kind == ValidationFailure.registrationRequired
        ? null
        : e.message;
    if (e.kind == ValidationFailure.registrationRequired) {
      return build(localCase, DailyConnection.online, guest: true);
    }
  }
  return build(localCase, failure, message: message);
});

/// Ranking de hoy.
final dailyRankingProvider = FutureProvider.autoDispose<RankingData>((
  ref,
) async {
  final source = ref.watch(dailyRankingSourceProvider);
  if (source == null) {
    throw const ValidationException(
      ValidationFailure.serverError,
      'sin-fuente-de-ranking',
    );
  }
  final localDate = formatLocalDate(ref.watch(dailyClockProvider)());
  await ref.watch(validationClientProvider)?.ensureSession();
  final data = await source.load(localDate, ownUid: source.currentUid);
  // Puesto propio guardado al resolver, por si la fila queda fuera del top.
  final prefs = await SharedPreferences.getInstance();
  final caseId = dailyCaseIdForLocalDate(localDate);
  final stored = readDailyProgress(prefs, caseId, localDate).result?.rank;
  return RankingData(
    top: data.top,
    own: data.own,
    ownUid: data.ownUid,
    ownRank: stored,
  );
});

/// Fecha `YYYY-MM-DD` como `dd-mm-aaaa` para mostrarla.
String displayDate(String localDate) {
  final p = localDate.split('-');
  return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : localDate;
}
