import 'dart:async';

import 'package:enigmatrix_engine/enigmatrix_engine.dart' show kMundoMansion;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'src/board/audio/audio_service.dart';
import 'src/data/case_repository.dart';
import 'src/game/app_settings.dart';
import 'src/game/dev_tools.dart';
import 'src/game/feedback_providers.dart';
import 'src/game/game_config.dart';
import 'src/game/game_controller.dart';
import 'src/ui/bank_screen.dart';
import 'src/ui/case_list_screen.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/home_shell.dart';
import 'src/ui/skin_theme.dart';
import 'src/ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las opciones se leen antes del primer cuadro para que la piel y el modo
  // no parpadeen al arrancar.
  final settings = await AppSettings.load();
  // Los valores de juego se leen del asset junto con las opciones (H-65).
  final config = await GameConfig.load();
  // El audio carga los sonidos en segundo plano: hasta que termina, la
  // partida simplemente no suena.
  final audio = SoloudSoundService();
  unawaited(audio.init());
  runApp(
    ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(settings),
        gameConfigProvider.overrideWithValue(config),
        soundSinkProvider.overrideWithValue(audio),
      ],
      child: const EnigmatrixApp(),
    ),
  );
}

/// Rutas de la app. Las herramientas de desarrollo (`/banco`) solo existen
/// con la bandera ENX_DEV (H-66): sin ella la ruta redirige a `/home`.
GoRouter buildAppRouter({required bool Function() devTools}) => GoRouter(
  redirect: (_, state) {
    if (state.uri.path == '/banco' && !devTools()) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
    GoRoute(path: '/casos', builder: (_, __) => const CaseListScreen()),
    // Banco de pruebas (desarrollo): se abre desde Configuración.
    GoRoute(path: '/banco', builder: (_, __) => const BankScreen()),
    // Tutorial (regla 11): caso propio, aparte del banco de casos.
    GoRoute(
      path: '/tutorial',
      builder: (_, __) =>
          const GameScreen(caseId: kTutorialCaseId, tutorial: true),
    ),
    GoRoute(
      path: '/play/:id',
      builder: (_, state) => GameScreen(
        caseId: state.pathParameters['id']!,
        tutorial: state.uri.queryParameters['tutorial'] == '1',
      ),
    ),
  ],
);

class EnigmatrixApp extends ConsumerStatefulWidget {
  const EnigmatrixApp({super.key});

  @override
  ConsumerState<EnigmatrixApp> createState() => _EnigmatrixAppState();
}

/// Publica el ciclo de vida de la app: la partida en pantalla se pausa y se
/// guarda al pasar a segundo plano (regla 10 del ADR-0012).
class _EnigmatrixAppState extends ConsumerState<EnigmatrixApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = buildAppRouter(
    devTools: () => ref.read(devToolsProvider),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }

  @override
  Widget build(BuildContext context) {
    // Precarga del Mundo 1 y del reto diario al arrancar. El banco de pruebas
    // (desarrollo) se carga solo cuando se abre desde Configuración.
    ref.watch(campaignProvider(kMundoMansion));
    ref.watch(dailyChallengesProvider);
    // Un solo tema para toda la app: la piel y el modo que el jugador elige
    // en Configuración (Sistema sigue al teléfono).
    final skinId = ref.watch(settingsProvider.select((s) => s.skinId));
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      // Solo español por ahora: la app fuerza el idioma (sumar otro es
      // agregar su .arb y su Locale en supportedLocales).
      locale: kAppLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      themeMode: mode,
      theme: SkinUi.theme(skinId, Brightness.light),
      darkTheme: SkinUi.theme(skinId, Brightness.dark),
    );
  }
}
