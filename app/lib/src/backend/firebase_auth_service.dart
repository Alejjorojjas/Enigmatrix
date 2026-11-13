/// Implementación de [AuthService] con Firebase Auth, Google y Apple. Junto
/// con `firebase_validation_client.dart` son los únicos archivos que conocen
/// `firebase_auth`.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../auth/auth_service.dart';

const _inUseCodes = {'credential-already-in-use', 'email-already-in-use'};

/// Vincula la credencial a la cuenta de invitado ([link]) y, si ya era de otra
/// cuenta, inicia sesión en esa ([signIn]). Con una sesión que no es de
/// invitado solo inicia sesión. Nunca lanza: todo fallo vuelve como
/// [AuthFailed]. Se separa de [FirebaseAuthService] para probarla sin red.
Future<AuthOutcome> linkOrSignIn({
  required bool isGuest,
  required Future<void> Function() link,
  required Future<void> Function(AuthCredential? replacement) signIn,
}) async {
  if (!isGuest) {
    try {
      await signIn(null);
      return const AuthSignedIn();
    } on FirebaseAuthException catch (e) {
      return AuthFailed(authProblemFromCode(e.code));
    } on Object {
      return const AuthFailed(AuthProblem.unknown);
    }
  }
  try {
    await link();
    return const AuthSignedIn(linked: true);
  } on FirebaseAuthException catch (e) {
    if (!_inUseCodes.contains(e.code)) {
      return AuthFailed(authProblemFromCode(e.code));
    }
    try {
      await signIn(e.credential);
      return const AuthSignedIn(replacedGuest: true);
    } on FirebaseAuthException catch (f) {
      var problem = authProblemFromCode(f.code);
      // El correo ya tiene cuenta y la contraseña no es la suya.
      if (e.code == 'email-already-in-use' &&
          problem == AuthProblem.wrongCredentials) {
        problem = AuthProblem.emailInUse;
      }
      return AuthFailed(problem);
    } on Object {
      return const AuthFailed(AuthProblem.unknown);
    }
  } on Object {
    return const AuthFailed(AuthProblem.unknown);
  }
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, {GoogleSignIn? google, bool? appleAvailable})
    : _google = google,
      _appleAvailable =
          appleAvailable ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final FirebaseAuth _auth;
  final GoogleSignIn? _google;
  final bool _appleAvailable;
  Future<void>? _googleReady;

  @override
  bool get appleAvailable => _appleAvailable;

  static AuthUserInfo _info(User? u) {
    if (u == null) return AuthUserInfo.guest;
    final email =
        u.email ??
        u.providerData.map((p) => p.email).whereType<String>().firstOrNull;
    return AuthUserInfo(
      isAnonymous: u.isAnonymous,
      email: email,
      emailVerified: u.emailVerified,
    );
  }

  @override
  AuthUserInfo get current => _info(_auth.currentUser);

  @override
  Stream<AuthUserInfo> get changes => _auth.userChanges().map(_info);

  bool get _isGuest {
    final u = _auth.currentUser;
    return u != null && u.isAnonymous;
  }

  Future<AuthOutcome> _withCredential(AuthCredential credential) {
    final user = _auth.currentUser;
    return linkOrSignIn(
      isGuest: _isGuest,
      link: () => user!.linkWithCredential(credential),
      signIn: (replacement) =>
          _auth.signInWithCredential(replacement ?? credential),
    );
  }

  GoogleSignIn get _googleSignIn => _google ?? GoogleSignIn.instance;

  @override
  Future<AuthOutcome> signInWithGoogle() async {
    try {
      _googleReady ??= _googleSignIn.initialize();
      await _googleReady;
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return const AuthFailed(AuthProblem.unknown);
      return _withCredential(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthCancelled();
      }
      debugPrint('Google: ${e.code}');
      return const AuthFailed(AuthProblem.unknown);
    } on Object catch (e) {
      debugPrint('Google: $e');
      return const AuthFailed(AuthProblem.unknown);
    }
  }

  @override
  Future<AuthOutcome> signInWithApple() async {
    if (!_appleAvailable) return const AuthFailed(AuthProblem.unavailable);
    try {
      final raw = _nonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      final token = apple.identityToken;
      if (token == null) return const AuthFailed(AuthProblem.unknown);
      return _withCredential(
        OAuthProvider('apple.com').credential(
          idToken: token,
          accessToken: apple.authorizationCode,
          rawNonce: raw,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthCancelled();
      }
      debugPrint('Apple: ${e.code}');
      return const AuthFailed(AuthProblem.unknown);
    } on Object catch (e) {
      debugPrint('Apple: $e');
      return const AuthFailed(AuthProblem.unknown);
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Future<AuthOutcome> createAccountWithEmail(
    String email,
    String password,
  ) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final outcome = _isGuest
        ? await _withCredential(credential)
        : await _createPlain(email.trim(), password);
    if (outcome is! AuthSignedIn || outcome.replacedGuest) return outcome;
    // Cuenta nueva: se envía la verificación (si falla, la cuenta ya existe).
    try {
      await _auth.currentUser?.sendEmailVerification();
      return outcome.withVerification();
    } on Object catch (e) {
      debugPrint('No se pudo enviar la verificación: $e');
      return outcome;
    }
  }

  Future<AuthOutcome> _createPlain(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const AuthSignedIn();
    } on FirebaseAuthException catch (e) {
      return AuthFailed(authProblemFromCode(e.code));
    } on Object {
      return const AuthFailed(AuthProblem.unknown);
    }
  }

  @override
  Future<AuthOutcome> signInWithEmail(String email, String password) async {
    final wasGuest = _isGuest;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSignedIn(replacedGuest: wasGuest);
    } on FirebaseAuthException catch (e) {
      return AuthFailed(authProblemFromCode(e.code));
    } on Object {
      return const AuthFailed(AuthProblem.unknown);
    }
  }

  @override
  Future<AuthProblem?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      // Por privacidad no se revela si el correo existe.
      if (e.code == 'user-not-found') return null;
      return authProblemFromCode(e.code);
    } on Object {
      return AuthProblem.unknown;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } on Object catch (e) {
      debugPrint('Google signOut: $e');
    }
    await _auth.signOut();
    // Vuelve a invitado: el cliente del servidor ya no reinicia la sesión solo.
    await _auth.signInAnonymously();
  }
}
