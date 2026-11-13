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
      _set(AuthUserInfo(isAnonymous: false, email: signedEmail));
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
