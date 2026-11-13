/// Puerta para invitados, vinculación de la cuenta anónima y errores de
/// registro traducidos (ronda F2a). Sin red.
library;

import 'package:enigmatrix/src/auth/auth_providers.dart';
import 'package:enigmatrix/src/auth/auth_service.dart';
import 'package:enigmatrix/src/auth/registration_gate.dart';
import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/firebase_auth_service.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/ui/registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_validation_client.dart';
import 'support/l10n.dart';

void main() {
  group('requiresRegistration', () {
    test('mansion-01 y mansion-02 son gratis', () {
      expect(requiresRegistration('mansion-01'), isFalse);
      expect(requiresRegistration('mansion-02'), isFalse);
    });
    test('el resto de la campaña y el reto exigen cuenta', () {
      expect(requiresRegistration('mansion-03'), isTrue);
      expect(requiresRegistration('mansion-10'), isTrue);
      expect(requiresRegistration('reto-001'), isTrue);
    });
    test('el tutorial y el banco no pasan por el servidor', () {
      expect(requiresRegistration('tutorial'), isFalse);
      expect(requiresRegistration('caso-casual-s1'), isFalse);
    });
  });

  group('needsRegistrationProvider', () {
    ProviderContainer make({
      required BackendMode mode,
      required bool guest,
      bool withService = true,
    }) {
      final fake = FakeAuthService(guest: guest);
      final client = FakeValidationClient()..anonymous = guest;
      final c = ProviderContainer(
        overrides: [
          backendModeProvider.overrideWithValue(mode),
          if (withService) authServiceProvider.overrideWithValue(fake),
          validationClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sin servidor (modo none) nunca se pide registro', () {
      final c = make(mode: BackendMode.none, guest: true);
      expect(c.read(needsRegistrationProvider('mansion-05')), isFalse);
    });
    test('invitado con servidor: solo los casos que no son gratis', () {
      final c = make(mode: BackendMode.emulator, guest: true);
      expect(c.read(needsRegistrationProvider('mansion-01')), isFalse);
      expect(c.read(needsRegistrationProvider('mansion-03')), isTrue);
      expect(c.read(needsRegistrationProvider('reto-004')), isTrue);
    });
    test('registrado: nada exige registro', () {
      final c = make(mode: BackendMode.emulator, guest: false);
      expect(c.read(needsRegistrationProvider('mansion-03')), isFalse);
    });
    test('sin servicio de autenticación usa lo que dice el cliente', () {
      final c = make(
        mode: BackendMode.emulator,
        guest: true,
        withService: false,
      );
      expect(c.read(isGuestProvider), isTrue);
    });
  });

  group('errores de Firebase traducidos a español', () {
    test('códigos conocidos', () {
      expect(authProblemFromCode('invalid-email'), AuthProblem.invalidEmail);
      expect(
        authProblemFromCode('wrong-password'),
        AuthProblem.wrongCredentials,
      );
      expect(
        authProblemFromCode('invalid-credential'),
        AuthProblem.wrongCredentials,
      );
      expect(
        authProblemFromCode('email-already-in-use'),
        AuthProblem.emailInUse,
      );
      expect(authProblemFromCode('weak-password'), AuthProblem.weakPassword);
      expect(authProblemFromCode('user-disabled'), AuthProblem.userDisabled);
      expect(
        authProblemFromCode('network-request-failed'),
        AuthProblem.network,
      );
      expect(
        authProblemFromCode('too-many-requests'),
        AuthProblem.tooManyRequests,
      );
      expect(
        authProblemFromCode('operation-not-allowed'),
        AuthProblem.notAllowed,
      );
      expect(authProblemFromCode('algo-raro'), AuthProblem.unknown);
    });

    test('cada problema tiene un texto en español, sin código técnico', () {
      for (final p in AuthProblem.values) {
        final t = authProblemText(l10nEs, p);
        expect(t.trim(), isNotEmpty, reason: '$p');
        expect(t, isNot(contains('auth/')), reason: '$p');
      }
    });
  });

  group('validaciones de formulario', () {
    test('correo', () {
      expect(isValidEmail('ana@correo.com'), isTrue);
      expect(isValidEmail(' ana@correo.com '), isTrue);
      expect(isValidEmail('ana@correo'), isFalse);
      expect(isValidEmail('ana correo.com'), isFalse);
      expect(isValidEmail(''), isFalse);
    });
    test('contraseña mínima de 8', () => expect(kPasswordMinLength, 8));
  });

  group('linkOrSignIn (vincular la cuenta de invitado)', () {
    FirebaseAuthException err(String code, {AuthCredential? credential}) =>
        FirebaseAuthException(code: code, credential: credential);

    test('invitado: vincula y conserva el uid (sin iniciar sesión)', () async {
      var signIns = 0;
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async {},
        signIn: (_) async => signIns++,
      );
      o as AuthSignedIn;
      expect(o.linked, isTrue);
      expect(o.replacedGuest, isFalse);
      expect(signIns, 0);
    });

    test('credencial de otra cuenta: inicia sesión en ella y avisa', () async {
      final other = GoogleAuthProvider.credential(idToken: 'x');
      AuthCredential? used;
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async =>
            throw err('credential-already-in-use', credential: other),
        signIn: (c) async => used = c,
      );
      o as AuthSignedIn;
      expect(o.replacedGuest, isTrue);
      expect(o.linked, isFalse);
      expect(used, same(other));
    });

    test('correo ya usado: inicia sesión en esa cuenta', () async {
      var signedIn = false;
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async => throw err('email-already-in-use'),
        signIn: (_) async => signedIn = true,
      );
      expect(signedIn, isTrue);
      expect((o as AuthSignedIn).replacedGuest, isTrue);
    });

    test('correo ya usado con otra contraseña: "ya tiene cuenta"', () async {
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async => throw err('email-already-in-use'),
        signIn: (_) async => throw err('invalid-credential'),
      );
      expect((o as AuthFailed).problem, AuthProblem.emailInUse);
    });

    test('contraseña débil al vincular: error traducido', () async {
      var signIns = 0;
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async => throw err('weak-password'),
        signIn: (_) async => signIns++,
      );
      expect((o as AuthFailed).problem, AuthProblem.weakPassword);
      expect(signIns, 0);
    });

    test('sin ser invitado solo inicia sesión', () async {
      var linked = false;
      final o = await linkOrSignIn(
        isGuest: false,
        link: () async => linked = true,
        signIn: (_) async {},
      );
      expect(linked, isFalse);
      expect((o as AuthSignedIn).linked, isFalse);
    });

    test('un error inesperado no lanza: vuelve como fallo', () async {
      final o = await linkOrSignIn(
        isGuest: true,
        link: () async => throw StateError('boom'),
        signIn: (_) async {},
      );
      expect((o as AuthFailed).problem, AuthProblem.unknown);
    });
  });
}
