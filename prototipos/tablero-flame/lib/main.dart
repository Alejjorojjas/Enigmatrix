import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/audio/audio_service.dart';
import 'src/game/case_library.dart';
import 'src/game/fps_recorder.dart';
import 'src/settings.dart';
import 'src/strings.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/prototype_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final cases = await CaseLibrary.load();
  final audio = SoloudSoundService();
  await audio.init();
  final fps = FpsMonitor();

  runApp(PrototypeApp(
    cases: cases,
    audio: audio,
    fps: fps,
    settings: GameSettings(),
  ));
}

class PrototypeApp extends StatelessWidget {
  const PrototypeApp({
    super.key,
    required this.cases,
    required this.audio,
    required this.fps,
    required this.settings,
  });

  final List<CaseEntry> cases;
  final SoloudSoundService audio;
  final FpsMonitor fps;
  final GameSettings settings;

  @override
  Widget build(BuildContext context) {
    // El tema depende de la piel y del modo elegidos en Opciones. Con el modo
    // "Sistema" el teléfono decide entre el tema claro y el oscuro.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: Strings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: Ui.theme(settings.skinId, Brightness.light),
        darkTheme: Ui.theme(settings.skinId, Brightness.dark),
        themeMode: settings.themeMode,
        home: GameScreen(
          cases: cases,
          settings: settings,
          audio: audio,
          fps: fps,
        ),
      ),
    );
  }
}
