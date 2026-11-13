/// Registro e inicio de sesión (etapa 5A.3, ronda F2a).
///
/// Esta capa no conoce Firebase: la implementación real vive en
/// `backend/firebase_auth_service.dart` y los tests usan una autenticación
/// falsa. El jugador entra como invitado (sesión anónima) y puede registrarse
/// con Google, Apple (solo iPhone) o correo y contraseña. Al registrarse
/// desde invitado se VINCULA la credencial a la cuenta anónima para conservar
/// el mismo uid; si esa credencial ya era de otra cuenta, se inicia sesión en
/// ella (lo jugado como invitado se pierde, y se le avisa).
library;

import 'package:flutter/foundation.dart';

/// Cómo se ve la sesión desde la app.
@immutable
class AuthUserInfo {
  const AuthUserInfo({
    required this.isAnonymous,
    this.email,
    this.emailVerified = false,
  });

  /// Todavía no hay sesión (se trata como invitado).
  static const AuthUserInfo guest = AuthUserInfo(isAnonymous: true);

  final bool isAnonymous;
  final String? email;
  final bool emailVerified;

  /// Cuenta con correo todavía sin verificar: el reto pide verificarlo.
  /// (Google y Apple traen el correo ya verificado.)
  bool get needsEmailVerification =>
      !isAnonymous && email != null && !emailVerified;

  @override
  bool operator ==(Object other) =>
      other is AuthUserInfo &&
      other.isAnonymous == isAnonymous &&
      other.email == email &&
      other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(isAnonymous, email, emailVerified);
}

/// Motivo por el que falló un registro o inicio de sesión.
enum AuthProblem {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  userDisabled,
  network,
  tooManyRequests,
  notAllowed,
  unavailable,
  unknown,
}

/// Traduce un código de `FirebaseAuthException` a un [AuthProblem].
AuthProblem authProblemFromCode(String code) => switch (code) {
  'invalid-email' || 'missing-email' => AuthProblem.invalidEmail,
  'wrong-password' ||
  'invalid-credential' ||
  'user-not-found' ||
  'invalid-login-credentials' => AuthProblem.wrongCredentials,
  'email-already-in-use' ||
  'credential-already-in-use' ||
  'account-exists-with-different-credential' => AuthProblem.emailInUse,
  'weak-password' => AuthProblem.weakPassword,
  'user-disabled' => AuthProblem.userDisabled,
  'network-request-failed' => AuthProblem.network,
  'too-many-requests' => AuthProblem.tooManyRequests,
  'operation-not-allowed' || 'app-not-authorized' => AuthProblem.notAllowed,
  _ => AuthProblem.unknown,
};

/// Resultado de un intento de registro o inicio de sesión.
sealed class AuthOutcome {
  const AuthOutcome();
}

/// Entró. [linked]: la credencial se vinculó a la cuenta de invitado (mismo
/// uid). [replacedGuest]: se inició sesión en una cuenta que ya existía y lo
/// jugado como invitado no pasa a ella. [verificationSent]: se envió el correo
/// de verificación.
class AuthSignedIn extends AuthOutcome {
  const AuthSignedIn({
    this.linked = false,
    this.replacedGuest = false,
    this.verificationSent = false,
  });

  final bool linked;
  final bool replacedGuest;
  final bool verificationSent;

  AuthSignedIn withVerification() => AuthSignedIn(
    linked: linked,
    replacedGuest: replacedGuest,
    verificationSent: true,
  );
}

/// El jugador cerró la ventana del proveedor: no es un error.
class AuthCancelled extends AuthOutcome {
  const AuthCancelled();
}

class AuthFailed extends AuthOutcome {
  const AuthFailed(this.problem);
  final AuthProblem problem;
}

/// Contraseña mínima (la misma que se pide en pantalla).
const int kPasswordMinLength = 8;

bool isValidEmail(String raw) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw.trim());

abstract class AuthService {
  /// Sesión de ahora mismo.
  AuthUserInfo get current;

  /// Cambios de sesión (registro, vinculación, cierre).
  Stream<AuthUserInfo> get changes;

  /// true si se ofrece "Continuar con Apple" (solo iPhone).
  bool get appleAvailable;

  Future<AuthOutcome> signInWithGoogle();

  Future<AuthOutcome> signInWithApple();

  /// Crea la cuenta con correo y contraseña y envía la verificación.
  Future<AuthOutcome> createAccountWithEmail(String email, String password);

  Future<AuthOutcome> signInWithEmail(String email, String password);

  /// "Ya lo verifiqué": recarga al usuario y renueva el token (para que el
  /// servidor vea `email_verified`). Nunca lanza; devuelve la sesión ya
  /// actualizada.
  Future<AuthUserInfo> refreshVerification();

  /// "Reenviar correo" de verificación. null si salió bien.
  Future<AuthProblem?> resendVerification();

  /// Envía el correo para cambiar la contraseña. null si salió bien.
  Future<AuthProblem?> sendPasswordReset(String email);

  /// Cierra la sesión y vuelve a invitado anónimo.
  Future<void> signOut();
}
