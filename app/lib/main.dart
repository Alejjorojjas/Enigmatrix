import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/board/audio/audio_service.dart';
import 'src/data/case_repository.dart';
import 'src/game/app_settings.dart';
import 'src/game/feedback_providers.dart';
import 'src/game/game_controller.dart';
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
  // El audio carga los sonidos en segundo plano: hasta que termina, la
  // partida simplemente no suena.
  final audio = SoloudSoundService();
  unawaited(audio.init());
  runApp(
    ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(settings),
        soundSinkProvider.overrideWithValue(audio),
      ],
      child: const EnigmatrixApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
    GoRoute(path: '/casos', builder: (_, __) => const CaseListScreen()),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }

  @override
  Widget build(BuildContext context) {
    // Precarga de casos al arrancar.
    ref.watch(casesProvider);
    // Un solo tema para toda la app: la piel y el modo que el jugador elige
    // en Configuración (Sistema sigue al teléfono).
    final skinId = ref.watch(settingsProvider.select((s) => s.skinId));
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Enigmatrix',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: mode,
      theme: SkinUi.theme(skinId, Brightness.light),
      darkTheme: SkinUi.theme(skinId, Brightness.dark),
    );
  }
}
