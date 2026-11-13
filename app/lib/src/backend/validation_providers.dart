/// Proveedores de Riverpod de la capa de validación. Con el modo `none` no
/// hay cliente, no hay servicio y la app valida en el teléfono como siempre.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_config.dart';
import 'backend_config.dart';
import 'nickname_service.dart';
import 'validation_client.dart';
import 'validation_service.dart';

/// El servidor visto desde la app. `main.dart` lo sobreescribe cuando el modo
/// no es `none`; los tests, con un cliente falso.
final validationClientProvider = Provider<ValidationClient?>((ref) => null);

/// Casos con un envío "por validar" (la lista de casos pone la marca).
final pendingCaseIdsProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Servicio de validación con su cola. Null si el modo es `none` (o no hay
/// cliente): entonces nada de esto existe.
final validationServiceProvider = Provider<ValidationService?>((ref) {
  final mode = ref.watch(backendModeProvider);
  final client = ref.watch(validationClientProvider);
  if (!mode.usesServer || client == null) return null;
  final config = ref.read(gameConfigProvider);
  var disposed = false;
  final service = ValidationService(
    client: client,
    retryEvery: Duration(seconds: config.pendingRetrySeconds),
    serverErrorRetryLimit: config.serverErrorRetryLimit,
    onPendingChanged: (ids) {
      // Fuera del turno actual: el cambio puede llegar mientras se construye.
      Future.microtask(() {
        if (!disposed) ref.read(pendingCaseIdsProvider.notifier).state = ids;
      });
    },
  );
  ref.onDispose(() {
    disposed = true;
    service.dispose();
  });
  return service;
});

/// Apodo y borrado de cuenta. Null si el modo es `none` (o no hay cliente):
/// entonces no hay apodo, ni pantalla de apodo, ni borrado de cuenta.
final nicknameServiceProvider = Provider<NicknameService?>((ref) {
  final mode = ref.watch(backendModeProvider);
  final client = ref.watch(validationClientProvider);
  if (!mode.usesServer || client == null) return null;
  return NicknameService(
    client: client,
    onAccountDeleted: () async =>
        ref.read(validationServiceProvider)?.resetAfterAccountDeletion(),
  );
});
