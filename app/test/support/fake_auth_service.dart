/// Autenticación falsa para probar el registro sin red ni Firebase.
library;

import 'dart:async';

import 'package:enigmatrix/src/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({bool guest = true, this.apple = false})
    : _current = AuthUserInfo(isAnonymous: guest);

  AuthUserInfo _current;
  final bool apple;
  final StreamController<AuthUserInfo> _ctl = StreamController.broadcast();

  /// Lo que responderá el próximo intento (se consume).
  AuthOutcome? nextOutcome;

  /// Correo de la cuenta tras un registro con éxito.
  String signedEmail = 'ana@correo.com';

  /// Orden de las llamadas: `google`, `apple`, `create:<correo>`, ...
  final List<String> calls = [];
  int signOuts = 0;
  AuthProblem? resetProblem;

  /// Si la cuenta que crea el próximo registro llega con el correo verificado
  /// (Google/Apple sí; el correo y contraseña, no).
  bool signedVerified = true;

  /// true = "Ya lo verifiqué" encuentra el correo verificado.
  bool verifiesOnRefresh = false;
  AuthProblem? resendProblem;
  int refreshes = 0;
  int resends = 0;

  @override
  AuthUserInfo get current => _current;

  @override
  Stream<AuthUserInfo> get changes => _ctl.stream;

  @override
  bool get appleAvailable => apple;

  void _set(AuthUserInfo i) {
    _current = i;
    _ctl.add(i);
  }

  AuthOutcome _resolve() {
    final o = nextOutcome ?? const AuthSignedIn(linked: true);
    nextOutcome = null;
    if (o is AuthSignedIn) {
      _set(
        AuthUserInfo(
          isAnonymous: false,
          email: signedEmail,
          emailVerified: signedVerified,
        ),
      );
    }
    return o;
  }

  @override
  Future<AuthOutcome> signInWithGoogle() async {
    calls.add('google');
    return _resolve();
  }

  @override
  Future<AuthOutcome> signInWithApple() async {
    calls.add('apple');
    return _resolve();
  }

  @override
  Future<AuthOutcome> createAccountWithEmail(String e, String p) async {
    calls.add('create:$e');
    return _resolve();
  }

  @override
  Future<AuthOutcome> signInWithEmail(String e, String p) async {
    calls.add('signin:$e');
    return _resolve();
  }

  @override
  Future<AuthUserInfo> refreshVerification() async {
    refreshes++;
    calls.add('refresh');
    if (verifiesOnRefresh) {
      _set(
        AuthUserInfo(
          isAnonymous: false,
          email: _current.email,
          emailVerified: true,
        ),
      );
    }
    return _current;
  }

  @override
  Future<AuthProblem?> resendVerification() async {
    resends++;
    calls.add('resend');
    return resendProblem;
  }

  @override
  Future<AuthProblem?> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    return resetProblem;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    _set(const AuthUserInfo(isAnonymous: true));
  }
}
