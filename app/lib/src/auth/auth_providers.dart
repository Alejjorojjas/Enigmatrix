/// Proveedores de la sesión y de la puerta para invitados (ronda F2a).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_config.dart';
import '../backend/validation_providers.dart';
import 'auth_service.dart';
import 'registration_gate.dart';

/// Autenticación. `main.dart` la sobreescribe con la de Firebase cuando el
/// modo no es `none`; los tests, con una falsa. Null = sin registro.
final authServiceProvider = Provider<AuthService?>((ref) => null);

/// Sesión actual (se actualiza al registrarse, vincular o cerrar sesión).
final authInfoProvider = StreamProvider<AuthUserInfo>((ref) async* {
  final service = ref.watch(authServiceProvider);
  if (service == null) {
    yield AuthUserInfo.guest;
    return;
  }
  yield service.current;
  yield* service.changes;
});

/// true si la sesión es de invitado. Sin servicio de autenticación se usa lo
/// que diga el cliente del servidor.
final isGuestProvider = Provider<bool>((ref) {
  final service = ref.watch(authServiceProvider);
  if (service == null) {
    return ref.watch(validationClientProvider)?.isAnonymous ?? true;
  }
  final info = ref.watch(authInfoProvider).valueOrNull ?? service.current;
  return info.isAnonymous;
});

/// Correo de la cuenta registrada (null para invitados o sin correo).
final accountEmailProvider = Provider<String?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (service == null) return null;
  final info = ref.watch(authInfoProvider).valueOrNull ?? service.current;
  return info.isAnonymous ? null : info.email;
});

/// true si ESTE jugador, ahora, debe registrarse para abrir [caseId]: hay
/// servidor, es invitado y el caso no es gratis.
final needsRegistrationProvider = Provider.family<bool, String>((ref, caseId) {
  if (!ref.watch(backendModeProvider).usesServer) return false;
  return requiresRegistration(caseId) && ref.watch(isGuestProvider);
});
