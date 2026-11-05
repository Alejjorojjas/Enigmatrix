/// Ayudas para probar la pantalla de partida con el tablero de Flame: montar
/// la pantalla con los mismos proveedores que main.dart, y tocar casillas por
/// su posición en la escena.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/board/feedback/feedback_director.dart';
import 'package:enigmatrix/src/board/feedback/feedback_plan.dart';
import 'package:enigmatrix/src/board/scene/board_game.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/feedback_providers.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/ui/game_screen.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carga un caso real del banco por su nombre de archivo (sin .json).
PuzzleCase loadBankCase(String name) => PuzzleCase.fromJson(
  (jsonDecode(
            File(
              'assets/cases/$name.json',
            ).readAsStringSync().replaceFirst('\uFEFF', ''),
          )
          as Map)
      .cast<String, dynamic>(),
);

/// Sonidos que se pidieron (en vez de sonar).
class RecordingSound implements SoundSink {
  final List<SoundId> played = [];
  int stops = 0;
  @override
  void play(SoundCue cue) => played.add(cue.id);
  @override
  void stopLong() => stops++;
}

/// Vibraciones que se pidieron.
class RecordingHaptics implements HapticSink {
  final List<HapticKind> pulses = [];
  @override
  void pulse(HapticKind kind) => pulses.add(kind);
}

class FakeRinger implements RingerProbe {
  FakeRinger(this.mode);
  RingerMode mode;
  @override
  Future<RingerMode> read() async => mode;
}

/// Todo lo que una prueba necesita de la partida en pantalla.
class GameRig {
  GameRig(this.container, this.router, this.sound, this.haptics);
  final ProviderContainer container;
  final GoRouter router;
  final RecordingSound sound;
  final RecordingHaptics haptics;
}

/// Monta `/play/<id>` (o `/tutorial`) con relojes y almacenamiento de prueba.
Future<GameRig> pumpGameScreen(
  WidgetTester tester,
  PuzzleCase pc, {
  Size size = const Size(360, 740),
  AppSettings settings = AppSettings.defaults,
  Brightness platformBrightness = Brightness.light,
  RingerMode ringer = RingerMode.normal,
  Map<String, Object> prefs = const {},
  bool tutorial = false,
  Future<List<PuzzleCase>> Function()? bank,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final sound = RecordingSound();
  final haptics = RecordingHaptics();
  final container = ProviderContainer(
    overrides: [
      gameTickerEnabledProvider.overrideWithValue(false),
      casesProvider.overrideWith((_) => (bank ?? () async => [pc])()),
      tutorialCaseProvider.overrideWith((_) async => pc),
      initialSettingsProvider.overrideWithValue(settings),
      soundSinkProvider.overrideWithValue(sound),
      hapticSinkProvider.overrideWithValue(haptics),
      ringerProbeProvider.overrideWithValue(FakeRinger(ringer)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: tutorial ? '/tutorial' : '/play/${pc.caseId}',
    routes: [
      GoRoute(
        path: '/casos',
        builder: (_, _) => const Scaffold(body: Text('LISTA DE CASOS')),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (_, _) =>
            const GameScreen(caseId: kTutorialCaseId, tutorial: true),
      ),
      GoRoute(
        path: '/play/:id',
        builder: (_, s) => GameScreen(caseId: s.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
  return GameRig(container, router, sound, haptics);
}

/// Deja pasar unos cuadros (carga de la escena, avisos y animaciones cortas).
Future<void> settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

final gameFinder = find.byWidgetPredicate((w) => w is GameWidget);

BoardGame gameOf(WidgetTester tester) =>
    (tester.widget(gameFinder) as GameWidget).game! as BoardGame;

/// Centro de una casilla en coordenadas de pantalla.
Offset cellPoint(WidgetTester tester, int cell) =>
    tester.getTopLeft(gameFinder) + gameOf(tester).geometry.cellCenter(cell);

Future<void> tapCell(WidgetTester tester, int cell) async {
  await tester.tapAt(cellPoint(tester, cell));
  // Los pulsos de vibración tardíos (hasta 140 ms) también tienen que caer.
  await settle(tester, 5);
}

/// Mantener oprimida una casilla: el reloj del gesto es el real, así que se
/// espera de verdad medio segundo con el dedo abajo.
Future<void> holdCell(WidgetTester tester, int cell) async {
  final g = await tester.startGesture(cellPoint(tester, cell));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 460)),
  );
  await tester.pump(const Duration(milliseconds: 40));
  await tester.pump(const Duration(milliseconds: 40));
  await g.up();
  await settle(tester, 5);
}

Future<void> pickSuspect(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('retrato-$id')));
  await settle(tester, 2);
}

Future<void> pickTool(WidgetTester tester, ToolMode mode) async {
  await tester.tap(find.byKey(ValueKey('herramienta-${mode.name}')));
  await settle(tester, 2);
}

/// Primera casilla que acepta personas (sin mueble que la bloquee).
int firstFreeCell(PuzzleCase pc) => [
  for (var i = 0; i < pc.map.size * pc.map.size; i++)
    if (pc.map.isOccupiable(i)) i,
].first;

/// En las pruebas Flutter dibuja con una letra de cuadrados (Ahem), más ancha
/// que la real. Para medir la interfaz de verdad se carga Roboto, que viene
/// con el SDK de Flutter. Si no se encuentra, sigue la letra de cuadrados.
Future<bool> loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/Flutter/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final files = [
    '$dir/roboto-regular.ttf',
    '$dir/roboto-medium.ttf',
    '$dir/roboto-bold.ttf',
    '$dir/roboto-black.ttf',
  ];
  if (!files.every((f) => File(f).existsSync())) return false;
  final loader = FontLoader('Roboto');
  for (final f in files) {
    loader.addFont(Future.value(File(f).readAsBytesSync().buffer.asByteData()));
  }
  await loader.load();
  return true;
}
