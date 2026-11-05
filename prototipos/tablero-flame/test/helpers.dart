import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:tablero_flame/src/feedback/feedback_director.dart';
import 'package:tablero_flame/src/feedback/feedback_event.dart';
import 'package:tablero_flame/src/feedback/feedback_plan.dart';
import 'package:tablero_flame/src/game/game_session.dart';
import 'package:tablero_flame/src/settings.dart';

class RecVisual implements VisualSink {
  final List<VisualEffect> played = [];
  @override
  void play(VisualEffect effect) => played.add(effect);
}

class RecSound implements SoundSink {
  final List<SoundCue> played = [];
  int stops = 0;
  @override
  void play(SoundCue cue) => played.add(cue);
  @override
  void stopLong() => stops++;
}

class RecHaptic implements HapticSink {
  final List<HapticKind> pulses = [];
  @override
  void pulse(HapticKind kind) => pulses.add(kind);
}

/// Director con relojes y temporizadores falsos, para pruebas deterministas.
class Rig {
  Rig({GameSettings? settings}) : settings = settings ?? GameSettings();

  final GameSettings settings;
  final visual = RecVisual();
  final sound = RecSound();
  final haptic = RecHaptic();
  int nowMs = 0;
  final List<(int, void Function())> scheduled = [];

  late final FeedbackDirector director = FeedbackDirector(
    settings: settings,
    visuals: visual,
    sounds: sound,
    haptics: haptic,
    nowMs: () => nowMs,
    schedule: (d, f) => scheduled.add((d.inMilliseconds, f)),
  );

  void runScheduled() {
    final all = [...scheduled];
    scheduled.clear();
    for (final s in all) {
      s.$2();
    }
  }
}

PuzzleCase loadCase(String name) {
  final text = File('assets/cases/$name.json').readAsStringSync(encoding: utf8);
  return PuzzleCase.fromJson((jsonDecode(text) as Map).cast<String, dynamic>());
}

/// Rig que además anota los eventos que recibe el director (para probar la
/// sesión de juego).
class LoggingRig extends Rig {
  LoggingRig({super.settings});

  final List<FeedbackEvent> events = [];

  late final FeedbackDirector logging = _LoggingDirector(this);

  GameSession session(PuzzleCase pc) =>
      GameSession(pc: pc, director: logging, settings: settings);

  Iterable<T> eventsOf<T extends FeedbackEvent>() => events.whereType<T>();
}

class _LoggingDirector extends FeedbackDirector {
  _LoggingDirector(LoggingRig rig)
      : _rig = rig,
        super(
          settings: rig.settings,
          visuals: rig.visual,
          sounds: rig.sound,
          haptics: rig.haptic,
          nowMs: () => rig.nowMs,
          schedule: (d, f) => rig.scheduled.add((d.inMilliseconds, f)),
        );

  final LoggingRig _rig;

  @override
  FeedbackPlan handle(FeedbackEvent event) {
    _rig.events.add(event);
    return super.handle(event);
  }
}

/// En las pruebas, Flutter dibuja todo con una letra de cuadrados (Ahem), más
/// ancha que la real. Para medir la interfaz de verdad se carga Roboto, que
/// viene con Flutter (carpeta del SDK). Si no se encuentra, las pruebas siguen
/// con la letra de cuadrados.
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
