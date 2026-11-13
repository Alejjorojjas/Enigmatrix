/// Pantalla de registro, apodo tras registrarse, Configuración para invitados
/// y registrados, y candado en la lista de casos (ronda F2a). Autenticación y
/// servidor falsos, sin red.
library;

import 'package:enigmatrix/main.dart' show appRedirect;
import 'package:enigmatrix/src/auth/auth_providers.dart';
import 'package:enigmatrix/src/auth/auth_service.dart';
import 'package:enigmatrix/src/auth/registration_gate.dart';
import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/nickname_service.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/home_sheets.dart';
import 'package:enigmatrix/src/ui/nickname_screen.dart';
import 'package:enigmatrix/src/ui/registration_screen.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/fake_auth_service.dart';
import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;
import 'support/l10n.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('INICIO FALSO'),
          TextButton(
            onPressed: () => openSettingsSheet(context),
            child: const Text('ABRIR AJUSTES'),
          ),
          TextButton(
            onPressed: () => context.push('/registro'),
            child: const Text('IR A REGISTRO'),
          ),
        ],
      ),
    ),
  );
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required FakeAuthService auth,
  FakeValidationClient? client,
  String initial = '/home',
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const _Home()),
      GoRoute(path: '/apodo', builder: (_, _) => const NicknameScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistrationScreen()),
      GoRoute(path: '/casos', builder: (_, _) => const CaseListScreen()),
      GoRoute(
        path: '/play/:id',
        builder: (_, s) => Text('JUGANDO ${s.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        backendModeProvider.overrideWithValue(BackendMode.emulator),
        validationClientProvider.overrideWithValue(
          client ?? FakeValidationClient(),
        ),
        authServiceProvider.overrideWithValue(auth),
        initialSettingsProvider.overrideWithValue(
          const AppSettings(skinId: 'ilustrada'),
        ),
        ...extra,
      ],
      child: MaterialApp.router(
        localizationsDelegates: kL10nDelegates,
        supportedLocales: kL10nLocales,
        locale: kL10nLocale,
        routerConfig: router,
        theme: SkinUi.theme('ilustrada', Brightness.light),
      ),
    ),
  );
  await _settle(tester);
  return router;
}

Future<void> _tap(WidgetTester tester, String label) async {
  final f = find.text(label.toUpperCase());
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
  await _settle(tester);
}

Future<void> _fill(WidgetTester tester, String email, String pass) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), pass);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pantalla de registro', () {
    testWidgets('muestra Google y correo; Apple solo si está disponible', (
      tester,
    ) async {
      await _pump(tester, auth: FakeAuthService(), initial: '/registro');
      expect(find.text(l10nEs.registerGoogle.toUpperCase()), findsOneWidget);
      expect(find.text(l10nEs.registerApple.toUpperCase()), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('en iPhone aparece "Continuar con Apple"', (tester) async {
      final auth = FakeAuthService(apple: true);
      await _pump(tester, auth: auth, initial: '/registro');
      expect(find.text(l10nEs.registerApple.toUpperCase()), findsOneWidget);
      await _tap(tester, l10nEs.registerApple);
      expect(auth.calls, ['apple']);
    });

    testWidgets('correo mal escrito o contraseña corta: avisa sin llamar', (
      tester,
    ) async {
      final auth = FakeAuthService();
      await _pump(tester, auth: auth, initial: '/registro');

      await _fill(tester, 'no-es-correo', '12345678');
      await _tap(tester, l10nEs.registerSubmitCreate);
      expect(find.text(l10nEs.registerErrEmailInvalid), findsOneWidget);

      await _fill(tester, 'ana@correo.com', '1234567');
      await _tap(tester, l10nEs.registerSubmitCreate);
      expect(find.text(l10nEs.registerErrPasswordShort), findsOneWidget);

      expect(auth.calls, isEmpty);
    });

    testWidgets('error de Firebase: se muestra traducido', (tester) async {
      final auth = FakeAuthService()
        ..nextOutcome = const AuthFailed(AuthProblem.emailInUse);
      await _pump(tester, auth: auth, initial: '/registro');
      await _fill(tester, 'ana@correo.com', '12345678');
      await _tap(tester, l10nEs.registerSubmitCreate);
      expect(find.text(l10nEs.authErrEmailInUse), findsOneWidget);
      expect(auth.calls, ['create:ana@correo.com']);
    });

    testWidgets('cerrar la ventana de Google no muestra error', (tester) async {
      final auth = FakeAuthService()..nextOutcome = const AuthCancelled();
      await _pump(tester, auth: auth, initial: '/registro');
      await _tap(tester, l10nEs.registerGoogle);
      expect(find.byKey(const Key('registerError')), findsNothing);
      expect(find.text(l10nEs.registerTitle), findsOneWidget);
    });

    testWidgets('iniciar sesión pide la contraseña y ofrece recuperarla', (
      tester,
    ) async {
      final auth = FakeAuthService();
      await _pump(tester, auth: auth, initial: '/registro');
      await tester.tap(find.text(l10nEs.registerModeSignIn));
      await _settle(tester);
      expect(find.text(l10nEs.registerForgot), findsOneWidget);

      // Sin correo: pide escribirlo.
      await tester.tap(find.text(l10nEs.registerForgot));
      await _settle(tester);
      expect(find.text(l10nEs.registerResetNeedsEmail), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'ana@correo.com');
      await tester.tap(find.text(l10nEs.registerForgot));
      await _settle(tester);
      expect(auth.calls, ['reset:ana@correo.com']);
      expect(find.text(l10nEs.registerResetSent), findsOneWidget);
    });

    testWidgets('sin apodo: tras registrarse se muestra la pantalla de apodo', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..nextOutcome = const AuthSignedIn(
          linked: true,
          verificationSent: true,
        );
      final router = await _pump(tester, auth: auth, initial: '/registro');
      await _fill(tester, 'ana@correo.com', '12345678');
      await _tap(tester, l10nEs.registerSubmitCreate);
      // Primero el aviso de verificación; el apodo viene después.
      expect(find.text(l10nEs.emailVerifyTitle), findsOneWidget);
      expect(router.state.uri.path, '/registro');
      expect(
        find.textContaining(l10nEs.registerVerificationSent),
        findsOneWidget,
      );
      await tester.tap(find.text(l10nEs.emailVerifyLater));
      await _settle(tester);
      expect(router.state.uri.path, '/apodo');
      expect(find.text(l10nEs.nickScreenTitle), findsOneWidget);
    });

    testWidgets('verificación: reenviar, "Ya lo verifiqué" y seguir', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..signedVerified = false
        ..nextOutcome = const AuthSignedIn(
          linked: true,
          verificationSent: true,
        );
      final router = await _pump(tester, auth: auth, initial: '/registro');
      await _fill(tester, 'ana@correo.com', '12345678');
      await _tap(tester, l10nEs.registerSubmitCreate);
      expect(find.text(l10nEs.emailVerifyTitle), findsOneWidget);
      expect(
        find.textContaining('ana@correo.com', findRichText: true),
        findsWidgets,
      );

      await _tap(tester, l10nEs.emailVerifyResend);
      expect(auth.resends, 1);
      expect(find.text(l10nEs.emailVerifyResent), findsOneWidget);

      // Todavía sin verificar: avisa y se queda.
      await _tap(tester, l10nEs.emailVerifyDone);
      expect(auth.refreshes, 1);
      expect(find.text(l10nEs.emailVerifyNotYet), findsOneWidget);
      expect(router.state.uri.path, '/registro');

      // Ya verificado: sigue al apodo.
      auth.verifiesOnRefresh = true;
      await _tap(tester, l10nEs.emailVerifyDone);
      expect(auth.refreshes, 2);
      expect(router.state.uri.path, '/apodo');
    });

    testWidgets('cuenta con apodo en el servidor: no pide /apodo', (
      tester,
    ) async {
      final client = FakeValidationClient()
        ..anonymous = false
        ..serverNickname = 'Sherlock';
      final auth = FakeAuthService();
      final router = await _pump(
        tester,
        auth: auth,
        client: client,
        initial: '/registro',
      );
      await _tap(tester, l10nEs.registerGoogle);
      expect(router.state.uri.path, '/home');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profile:nick'), 'Sherlock');
    });

    testWidgets('el apodo guardado tras registrarse lleva al inicio', (
      tester,
    ) async {
      final client = FakeValidationClient();
      final auth = FakeAuthService();
      final router = await _pump(
        tester,
        auth: auth,
        client: client,
        initial: '/registro',
      );
      await _tap(tester, l10nEs.registerGoogle);
      expect(router.state.uri.path, '/apodo');
      await tester.enterText(find.byType(TextField), 'Sherlock');
      await _tap(tester, l10nEs.nickContinue);
      expect(client.serverNickname, 'Sherlock');
      expect(router.state.uri.path, '/home');
    });

    testWidgets('con apodo ya guardado vuelve a donde estaba', (tester) async {
      final auth = FakeAuthService();
      final router = await _pump(
        tester,
        auth: auth,
        prefs: {kNickKey: 'Watson'},
      );
      await _tap(tester, 'IR A REGISTRO'.toLowerCase());
      expect(router.state.uri.path, '/registro');
      await _tap(tester, l10nEs.registerGoogle);
      expect(router.state.uri.path, '/home');
    });

    testWidgets('cuenta que ya existía: avisa que lo de invitado no pasó', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..nextOutcome = const AuthSignedIn(replacedGuest: true);
      await _pump(
        tester,
        auth: auth,
        initial: '/registro',
        prefs: {kNickKey: 'Watson'},
      );
      await _tap(tester, l10nEs.registerGoogle);
      expect(find.text(l10nEs.registerReplacedGuest), findsOneWidget);
    });
  });

  group('Configuración', () {
    testWidgets('invitado: "Iniciar sesión / Registrarse" abre /registro', (
      tester,
    ) async {
      final router = await _pump(tester, auth: FakeAuthService());
      await _tap(tester, 'ABRIR AJUSTES'.toLowerCase());
      expect(find.text(l10nEs.settingsSignIn.toUpperCase()), findsOneWidget);
      expect(find.text(l10nEs.settingsSignOut.toUpperCase()), findsNothing);
      expect(find.text(l10nEs.settingsChangeNick.toUpperCase()), findsNothing);
      await _tap(tester, l10nEs.settingsSignIn);
      expect(router.state.uri.path, '/registro');
    });

    testWidgets('registrado: correo, cambiar apodo, cerrar sesión y borrar', (
      tester,
    ) async {
      final auth = FakeAuthService(guest: false);
      auth.nextOutcome = null;
      await _pump(
        tester,
        auth: auth,
        client: FakeValidationClient()..anonymous = false,
        prefs: {kNickKey: 'Watson'},
      );
      // La sesión de la prueba ya trae correo.
      auth.signedEmail = 'ana@correo.com';
      await auth.signInWithGoogle();
      await _tap(tester, 'ABRIR AJUSTES'.toLowerCase());
      expect(
        find.text(l10nEs.settingsSignedInAs('ana@correo.com')),
        findsOneWidget,
      );
      expect(find.text(l10nEs.settingsSignIn.toUpperCase()), findsNothing);
      expect(
        find.text(l10nEs.settingsChangeNick.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
        findsOneWidget,
      );

      await _tap(tester, l10nEs.settingsSignOut);
      await tester.tap(find.text(l10nEs.settingsSignOut));
      await _settle(tester);
      expect(auth.signOuts, 1);
      final prefs = await SharedPreferences.getInstance();
      // El apodo era de la cuenta que se fue.
      expect(prefs.getString(kNickKey), isNull);
      // Y la hoja vuelve a ofrecer registrarse.
      expect(find.text(l10nEs.settingsSignIn.toUpperCase()), findsOneWidget);
    });
  });

  group('lista de casos', () {
    List<Override> content() => [
      ...contentOverrides([
        for (final n in ['01', '02', '03']) loadBankCase('mansion-$n'),
      ]),
      // contentOverrides fija none; esta lista usa el modo servidor.
      backendModeProvider.overrideWithValue(BackendMode.emulator),
    ];

    testWidgets('invitado: el caso 3 lleva candado y manda a /registro', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        auth: FakeAuthService(),
        initial: '/casos',
        prefs: {'tutorial:v2:done': true},
        extra: content(),
      );
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      // La ficha 3 es la última: abre su hoja.
      final lock = find.byIcon(Icons.lock_rounded).first;
      await tester.ensureVisible(lock);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(lock);
      await _settle(tester);
      expect(
        find.text(l10nEs.caseListRegisterToContinue.toUpperCase()),
        findsOneWidget,
      );
      await _tap(tester, l10nEs.caseListRegisterToContinue);
      expect(router.state.uri.path, '/registro');
    });

    testWidgets('registrado: sin candados y el caso 3 se juega', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        auth: FakeAuthService(guest: false),
        client: FakeValidationClient()..anonymous = false,
        initial: '/casos',
        prefs: {'tutorial:v2:done': true},
        extra: content(),
      );
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(router.state.uri.path, '/casos');
    });
  });

  group('invitación a registrarse', () {
    testWidgets('el servidor pide registro: se muestra la invitación', (
      tester,
    ) async {
      final router = await _pump(tester, auth: FakeAuthService());
      final context = tester.element(find.text('INICIO FALSO'));
      final future = showRegistrationInvite(context);
      await _settle(tester);
      expect(find.text(l10nEs.registerInviteTitle), findsOneWidget);
      await tester.tap(find.text(l10nEs.registerInviteAction));
      await _settle(tester);
      expect(await future, isTrue);
      expect(router.state.uri.path, '/registro');
    });

    testWidgets('"Ahora no" la cierra sin ir a /registro', (tester) async {
      final router = await _pump(tester, auth: FakeAuthService());
      final context = tester.element(find.text('INICIO FALSO'));
      final future = showRegistrationInvite(context);
      await _settle(tester);
      await tester.tap(find.text(l10nEs.registerInviteLater));
      await _settle(tester);
      expect(await future, isFalse);
      expect(router.state.uri.path, '/home');
    });
  });

  test('la ruta /play/<caso> manda al invitado a /registro', () {
    String? go(String path) => appRedirect(
      Uri.parse(path),
      devTools: () => false,
      needsRegistration: requiresRegistration,
    );
    expect(go('/play/mansion-05'), '/registro');
    expect(go('/play/reto-001'), '/registro');
    expect(go('/play/mansion-01'), isNull);
    expect(go('/play/caso-casual-s1'), isNull);
    expect(go('/home'), isNull);
  });
}
