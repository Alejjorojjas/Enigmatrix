/// Implementación del [ValidationClient] con Firebase (Auth anónimo y Cloud
/// Functions). Es el único archivo de la app que conoce `firebase_auth` y
/// `cloud_functions`; el resto habla con la interfaz.
library;

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'validation_client.dart';

/// Traduce el código de una [FirebaseFunctionsException] al tipo de fallo:
///  - sin señal o tiempo agotado: se reintenta sin límite;
///  - `invalid-argument` y `not-found`: el servidor no lo aceptará nunca;
///  - `unauthenticated`, `permission-denied` y `failed-precondition` (lo que
///    pasa si falta App Check): el envío se detiene de una vez;
///  - cualquier otro código (`internal`...): el servidor respondió con un
///    error, se reintenta unas pocas veces.
ValidationFailure failureForFunctionsCode(String code) => switch (code) {
  'resource-exhausted' => ValidationFailure.rateLimited,
  'invalid-argument' || 'not-found' => ValidationFailure.rejected,
  'unavailable' || 'deadline-exceeded' => ValidationFailure.network,
  'unauthenticated' ||
  'permission-denied' ||
  'failed-precondition' => ValidationFailure.blocked,
  _ => ValidationFailure.serverError,
};

class FirebaseValidationClient implements ValidationClient {
  FirebaseValidationClient({
    required FirebaseAuth auth,
    required FirebaseFunctions functions,
    required this.timeout,
  }) : _auth = auth,
       _functions = functions;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  /// Tiempo máximo de cada llamada (sale de la configuración del juego).
  final Duration timeout;

  Future<void>? _session;

  /// Una sola sesión anónima, compartida: dos llamadas a la vez esperan al
  /// mismo trabajo. Si falla, la siguiente vuelve a intentarlo.
  @override
  Future<void> ensureSession() => _session ??= () async {
    try {
      await _restoreOrSignIn();
    } on Object {
      _session = null;
      rethrow;
    }
  }();

  /// En web `currentUser` es null hasta que se restaura la sesión guardada: se
  /// espera el primer estado de `authStateChanges` antes de decidir si hace
  /// falta iniciar una sesión anónima nueva.
  Future<void> _restoreOrSignIn() async {
    try {
      final restored = await _auth.authStateChanges().first.timeout(timeout);
      final user = restored ?? _auth.currentUser;
      if (user == null) {
        await _auth.signInAnonymously();
        return;
      }
      // Una sesión guardada puede haber dejado de existir (p. ej. el emulador
      // se reinició): se comprueba el token y, si ya no sirve, se empieza otra.
      try {
        await user.getIdToken();
      } on FirebaseAuthException catch (e) {
        const stale = {
          'user-not-found',
          'user-token-expired',
          'invalid-user-token',
          'user-disabled',
        };
        if (!stale.contains(e.code)) rethrow;
        await _auth.signOut();
        await _auth.signInAnonymously();
      }
    } on TimeoutException {
      throw const ValidationException(
        ValidationFailure.network,
        'auth-restore-timeout',
      );
    } on FirebaseAuthException catch (e) {
      // Sin red se reintenta sin límite; otro motivo cuenta como error del
      // servidor.
      throw ValidationException(
        e.code == 'network-request-failed'
            ? ValidationFailure.network
            : ValidationFailure.serverError,
        e.code,
      );
    }
  }

  Future<Object?> _call(String name, Map<String, Object> data) async {
    await ensureSession();
    try {
      final callable = _functions.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call<Object?>(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw ValidationException(failureForFunctionsCode(e.code), e.code);
    } on ValidationException {
      rethrow;
    } catch (e) {
      // Fallos de red fuera de Firebase (p. ej. el navegador).
      throw ValidationException(ValidationFailure.network, '$e');
    }
  }

  @override
  Future<void> startCase(String caseId) async {
    await _call('startCase', {'caseId': caseId});
  }

  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) async =>
      parseSubmitResponse(await _call('submitSolution', request.toCallData()));
}

/// Arranca Firebase según el modo y devuelve el cliente del servidor, o null
/// si el modo es [BackendMode.none]: en ese caso no se toca Firebase ni la red.
///
/// En modo emulador usa opciones escritas a mano para `demo-enigmatrix`: no
/// hace falta `google-services.json`. El modo `firebase` (proyecto real) llega
/// en la ronda de corte; hasta entonces intenta la configuración nativa y, si
/// no existe, deja un cliente "sin conexión" (nunca valida en el teléfono).
Future<ValidationClient?> bootstrapBackend(
  BackendMode mode, {
  required Duration timeout,
}) async {
  // En un build de release el emulador no existe: se comporta como `none`.
  final effective = effectiveBackendMode(mode, releaseMode: kReleaseMode);
  if (effective == BackendMode.none) return null;
  try {
    switch (effective) {
      case BackendMode.none:
        return null;
      case BackendMode.emulator:
        final app = await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'demo-api-key',
            appId: '1:000000000000:web:0000000000000000',
            messagingSenderId: '000000000000',
            projectId: kEmulatorProjectId,
          ),
        );
        final host = resolveEmulatorHost(platform: defaultTargetPlatform);
        final auth = FirebaseAuth.instanceFor(app: app);
        await auth.useAuthEmulator(host, kAuthEmulatorPort);
        final functions = FirebaseFunctions.instanceFor(
          app: app,
          region: kFunctionsRegion,
        );
        functions.useFunctionsEmulator(host, kFunctionsEmulatorPort);
        return FirebaseValidationClient(
          auth: auth,
          functions: functions,
          timeout: timeout,
        );
      case BackendMode.firebase:
        final app = await Firebase.initializeApp();
        return FirebaseValidationClient(
          auth: FirebaseAuth.instanceFor(app: app),
          functions: FirebaseFunctions.instanceFor(
            app: app,
            region: kFunctionsRegion,
          ),
          timeout: timeout,
        );
    }
  } catch (e) {
    debugPrint('No se pudo arrancar el servidor ($mode): $e');
    return const UnavailableValidationClient();
  }
}
