/// Pantalla de apodo del primer arranque y filas de Configuración (etapa
/// 5A.3). Servidor falso, sin red.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/nickname_service.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/ui/home_sheets.dart';
import 'package:enigmatrix/src/ui/nickname_screen.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/l10n.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required FakeValidationClient client,
  required String initial,
  BackendMode mode = BackendMode.emulator,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/apodo', builder: (_, _) => const NicknameScreen()),
      GoRoute(path: '/home', builder: (_, _) => const _FakeHome()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        backendModeProvider.overrideWithValue(mode),
        validationClientProvider.overrideWithValue(client),
        initialSettingsProvider.overrideWithValue(
          const AppSettings(skinId: 'ilustrada'),
        ),
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

/// Inicio de mentira: un botón que abre la hoja de Configuración.
class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => openSettingsSheet(context),
          child: const Text('ABRIR AJUSTES'),
        ),
      ),
    ),
  );
}

Finder get _field => find.byType(TextField);

Future<void> _tapButton(WidgetTester tester, String label) async {
  final f = find.text(label.toUpperCase());
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pantalla de apodo', () {
    testWidgets('muestra el título y las reglas', (tester) async {
      await _pump(tester, client: FakeValidationClient(), initial: '/apodo');
      expect(find.text(l10nEs.nickScreenTitle), findsOneWidget);
      expect(find.text(l10nEs.nickHelper), findsOneWidget);
    });

    testWidgets('apodo corto o con símbolos: avisa y no llama al servidor', (
      tester,
    ) async {
      final client = FakeValidationClient();
      await _pump(tester, client: client, initial: '/apodo');

      await tester.enterText(_field, 'ab');
      await _tapButton(tester, l10nEs.nickContinue);
      expect(find.text(l10nEs.nickTooShort), findsOneWidget);

      await tester.enterText(_field, 'Ana!!');
      await _tapButton(tester, l10nEs.nickContinue);
      expect(find.text(l10nEs.nickInvalidChars), findsOneWidget);

      expect(client.nicknameCalls, isEmpty);
      expect(find.text('ABRIR AJUSTES'), findsNothing);
    });

    testWidgets('apodo válido: se guarda y entra al inicio', (tester) async {
      final client = FakeValidationClient();
      final router = await _pump(tester, client: client, initial: '/apodo');
      await tester.enterText(_field, '  Sherlock  ');
      await _tapButton(tester, l10nEs.nickContinue);
      expect(client.serverNickname, 'Sherlock');
      expect(router.state.uri.path, '/home');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Sherlock');
    });

    testWidgets('el servidor lo rechaza: muestra su motivo y no avanza', (
      tester,
    ) async {
      final client = FakeValidationClient();
      final router = await _pump(tester, client: client, initial: '/apodo');
      await tester.enterText(_field, 'Groseria');
      await _tapButton(tester, l10nEs.nickContinue);
      expect(find.text('Ese apodo no está permitido.'), findsOneWidget);
      expect(router.state.uri.path, '/apodo');
    });

    testWidgets('sin conexión: se guarda en el teléfono y entra al inicio', (
      tester,
    ) async {
      final client = FakeValidationClient()..online = false;
      final router = await _pump(tester, client: client, initial: '/apodo');
      await tester.enterText(_field, 'Watson');
      await _tapButton(tester, l10nEs.nickContinue);
      expect(router.state.uri.path, '/home');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Watson');
      expect(prefs.getString(kNickPendingKey), '1');
    });
  });

  group('Configuración', () {
    testWidgets('invitado: sin Cambiar apodo, con Borrar mi cuenta', (
      tester,
    ) async {
      await _pump(tester, client: FakeValidationClient(), initial: '/home');
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      expect(find.text(l10nEs.settingsChangeNick.toUpperCase()), findsNothing);
      await tester.ensureVisible(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
      );
      expect(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('registrado: Cambiar apodo y Borrar mi cuenta', (tester) async {
      await _pump(
        tester,
        client: FakeValidationClient()..anonymous = false,
        initial: '/home',
        prefs: {kNickKey: 'Ana'},
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      await tester.ensureVisible(
        find.text(l10nEs.settingsChangeNick.toUpperCase()),
      );
      expect(
        find.text(l10nEs.settingsChangeNick.toUpperCase()),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
      );
      expect(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('sin servidor (modo none) no aparecen', (tester) async {
      await _pump(
        tester,
        client: FakeValidationClient(),
        initial: '/home',
        mode: BackendMode.none,
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      expect(find.text(l10nEs.settingsChangeNick.toUpperCase()), findsNothing);
      expect(
        find.text(l10nEs.settingsDeleteAccount.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('cambiar apodo desde el diálogo', (tester) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        client: client,
        initial: '/home',
        prefs: {kNickKey: 'Ana'},
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      await _tapButton(tester, l10nEs.settingsChangeNick);
      // El diálogo trae el apodo actual.
      expect(find.widgetWithText(TextField, 'Ana'), findsOneWidget);
      await tester.enterText(_field, 'Nuevo Apodo');
      await _tapButton(tester, l10nEs.nickSaveChange);
      expect(client.serverNickname, 'Nuevo Apodo');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Nuevo Apodo');
    });

    testWidgets('borrar la cuenta: confirma, llama al servidor y limpia', (
      tester,
    ) async {
      final client = FakeValidationClient();
      final router = await _pump(
        tester,
        client: client,
        initial: '/home',
        prefs: {
          kNickKey: 'Ana',
          'done:mansion-01': '{}',
          'game:mansion-02': '{}',
          'started:mansion-02': '1',
          'tutorial:v2:done': true,
        },
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      await _tapButton(tester, l10nEs.settingsDeleteAccount);
      expect(find.text(l10nEs.deleteAccountTitle), findsOneWidget);
      expect(client.deleteCalls, 0);
      await tester.tap(find.text(l10nEs.deleteAccountConfirm));
      await _settle(tester);
      expect(client.deleteCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'tutorial:v2:done'});
      // Vuelve a pedir el apodo.
      expect(router.state.uri.path, '/apodo');
    });

    testWidgets('cancelar la confirmación no borra nada', (tester) async {
      final client = FakeValidationClient();
      await _pump(
        tester,
        client: client,
        initial: '/home',
        prefs: {kNickKey: 'Ana'},
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      await _tapButton(tester, l10nEs.settingsDeleteAccount);
      await tester.tap(find.text(l10nEs.sheetCancel));
      await _settle(tester);
      expect(client.deleteCalls, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Ana');
    });

    testWidgets('borrar sin conexión avisa y conserva los datos', (
      tester,
    ) async {
      final client = FakeValidationClient()..online = false;
      final router = await _pump(
        tester,
        client: client,
        initial: '/home',
        prefs: {kNickKey: 'Ana', 'done:mansion-01': '{}'},
      );
      await tester.tap(find.text('ABRIR AJUSTES'));
      await _settle(tester);
      await _tapButton(tester, l10nEs.settingsDeleteAccount);
      await tester.tap(find.text(l10nEs.deleteAccountConfirm));
      await _settle(tester);
      expect(find.text(l10nEs.deleteAccountFailed), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Ana');
      expect(prefs.containsKey('done:mansion-01'), isTrue);
      expect(router.state.uri.path, '/home');
    });
  });
}
