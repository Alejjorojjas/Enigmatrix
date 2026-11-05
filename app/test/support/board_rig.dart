/// Ayudas para probar el tablero y el director de feedback sin pantalla:
/// destinos que anotan lo que reciben, opciones que se pueden cambiar a mano
/// y un director con relojes y temporizadores falsos.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/board/board_settings.dart';
import 'package:enigmatrix/src/board/feedback/feedback_director.dart';
import 'package:enigmatrix/src/board/feedback/feedback_plan.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';

/// Opciones del tablero que cambian en el medio de la prueba.
class GameSettings implements BoardSettings {
  GameSettings({
    this.soundOn = true,
    this.hapticsOn = true,
    this.reduceMotion = false,
    this.particleCap = 40,
  });

  @override
  bool soundOn;
  @override
  bool hapticsOn;
  @override
  bool reduceMotion;
  @override
  int particleCap;
}

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

/// Caso real del banco de la app (assets/cases).
PuzzleCase loadCase(String name) {
  final text = File('assets/cases/$name.json').readAsStringSync(encoding: utf8);
  return PuzzleCase.fromJson(
    (jsonDecode(text.replaceFirst('﻿', '')) as Map).cast<String, dynamic>(),
  );
}
