/// Director de feedback: UNA sola clase recibe los eventos del juego y, en
/// el mismo cuadro, dispara animación, sonido y vibración.
///
/// Se divide en dos pasos para poder probarlo:
///  1. [plan]: decisión pura. Dado un evento y las opciones, devuelve QUÉ
///     efectos corresponden (incluida la versión reducida, el tope de
///     partículas, los interruptores de sonido y vibración y los límites
///     de seguridad: máximo 3 destellos por segundo, vibración de lápiz
///     como mucho cada 80 ms).
///  2. [handle]: ejecuta el plan sobre los tres destinos a la vez.
///
/// Ninguna animación bloquea el siguiente toque: este código nunca espera a
/// que termine nada; solo lanza y vuelve.
library;

import 'dart:async';

import '../settings.dart';
import '../strings.dart';
import 'feedback_event.dart';
import 'feedback_plan.dart';

/// Destino de las animaciones (escena de Flame, bandeja, avisos...).
abstract class VisualSink {
  void play(VisualEffect effect);
}

/// Destino de los sonidos.
abstract class SoundSink {
  void play(SoundCue cue);
  void stopLong();
}

/// Destino de la vibración.
abstract class HapticSink {
  void pulse(HapticKind kind);
}

class FeedbackDirector {
  FeedbackDirector({
    required this.settings,
    required this.visuals,
    required this.sounds,
    required this.haptics,
    int Function()? nowMs,
    void Function(Duration, void Function())? schedule,
  })  : _nowMs = nowMs ?? _defaultNow,
        _schedule = schedule ?? ((d, f) => Timer(d, f));

  final GameSettings settings;
  final VisualSink visuals;
  final SoundSink sounds;
  final HapticSink haptics;
  final int Function() _nowMs;
  final void Function(Duration, void Function()) _schedule;

  /// Mínimo entre destellos: 3 por segundo como máximo (criterio de
  /// accesibilidad del informe gráfico).
  static const flashMinGapMs = 334;

  /// Mínimo entre vibraciones de lápiz.
  static const pencilHapticGapMs = 80;

  /// Confeti de la confirmación: de 6 a 8 trozos.
  static const confirmConfettiCount = 7;

  /// Confeti de la fanfarria final.
  static const revealConfettiCount = 40;

  static final _clock = Stopwatch()..start();
  static int _defaultNow() => _clock.elapsedMilliseconds;

  int _pencilVariant = 0;
  int _lastFlashMs = -100000;
  int _lastPencilHapticMs = -100000;

  /// Recibe un evento y lo ejecuta de inmediato. Devuelve el plan (útil
  /// para pruebas y depuración).
  FeedbackPlan handle(FeedbackEvent event) {
    final p = plan(event);
    _dispatch(p);
    return p;
  }

  void _dispatch(FeedbackPlan plan) {
    if (plan.stopSounds) sounds.stopLong();
    // Los tres destinos se lanzan seguidos, en la misma llamada.
    for (final v in plan.visuals) {
      visuals.play(v);
    }
    for (final s in plan.sounds) {
      sounds.play(s);
    }
    for (final h in plan.haptics) {
      if (h.delayMs <= 0) {
        haptics.pulse(h.kind);
      } else {
        _schedule(
            Duration(milliseconds: h.delayMs), () => haptics.pulse(h.kind));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Decisión pura
  // ---------------------------------------------------------------------------

  FeedbackPlan plan(FeedbackEvent event) {
    final raw = _rawPlan(event);
    // Interruptores globales de sonido y vibración.
    return FeedbackPlan(
      visuals: raw.visuals,
      sounds: settings.soundOn ? raw.sounds : const [],
      haptics: settings.hapticsOn ? raw.haptics : const [],
      stopSounds: raw.stopSounds,
    );
  }

  bool get _reduced => settings.reduceMotion;

  int _confetti(int wanted) => wanted.clamp(0, settings.particleCap);

  FeedbackPlan _rawPlan(FeedbackEvent e) {
    switch (e) {
      case SuspectTapped():
        if (!e.selected) return FeedbackPlan.empty;
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.selectPulse,
                charId: e.charId, reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.tick)],
          haptics: const [HapticPulse(HapticKind.selection)],
        );

      case CandidateNoted():
        final now = _nowMs();
        final hapticOk = now - _lastPencilHapticMs >= pencilHapticGapMs;
        if (hapticOk) _lastPencilHapticMs = now;
        final variant =
            SoundId.values[SoundId.lapiz1.index + _pencilVariant % 3];
        _pencilVariant++;
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.pencilMark,
                cell: e.cell, charId: e.charId, reduced: _reduced),
          ],
          sounds: [SoundCue(variant)],
          haptics: hapticOk ? const [HapticPulse(HapticKind.light)] : const [],
        );

      case Confirmed():
        const sounds = [SoundCue(SoundId.sello)];
        const haptics = [
          HapticPulse(HapticKind.selection),
          HapticPulse(HapticKind.light, delayMs: 60),
        ];
        if (_reduced) {
          return FeedbackPlan(
            visuals: [
              VisualEffect(VisualKind.confirmFade,
                  cell: e.cell, charId: e.charId, reduced: true),
              VisualEffect(VisualKind.fadeGlow, cell: e.cell, reduced: true),
            ],
            sounds: sounds,
            haptics: haptics,
          );
        }
        final now = _nowMs();
        final flashOk = now - _lastFlashMs >= flashMinGapMs;
        if (flashOk) _lastFlashMs = now;
        final n = _confetti(confirmConfettiCount);
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.confirmDrop,
                cell: e.cell, charId: e.charId),
            VisualEffect(VisualKind.ripple, cell: e.cell),
            if (n > 0)
              VisualEffect(VisualKind.confetti, cell: e.cell, count: n),
            if (flashOk)
              VisualEffect(VisualKind.flash, cell: e.cell)
            else
              VisualEffect(VisualKind.fadeGlow, cell: e.cell, reduced: true),
            const VisualEffect(VisualKind.cameraPunch, strength: 1.0),
          ],
          sounds: sounds,
          haptics: haptics,
        );

      case LinesCrossed():
        if (e.cells.isEmpty) return FeedbackPlan.empty;
        return FeedbackPlan(
          visuals: [
            VisualEffect(
                _reduced ? VisualKind.crossFade : VisualKind.crossWave,
                cell: e.origin,
                cells: e.cells,
                reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.arpegio)],
          // Tres pulsos suaves separados 70 ms (mínimo 50 ms).
          haptics: const [
            HapticPulse(HapticKind.light),
            HapticPulse(HapticKind.light, delayMs: 70),
            HapticPulse(HapticKind.light, delayMs: 140),
          ],
        );

      case CrossMarked():
        return FeedbackPlan(
          visuals: [
            VisualEffect(
                _reduced ? VisualKind.crossFade : VisualKind.crossWave,
                cell: e.cell,
                cells: [e.cell],
                reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.lapiz2)],
          haptics: const [HapticPulse(HapticKind.selection)],
        );

      case Erased():
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.erasePuff,
                cell: e.cell, reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.borrar)],
          haptics: const [HapticPulse(HapticKind.selection)],
        );

      case PlacementRejected():
        final text = switch (e.problem) {
          PlacementProblem.noSuspect => Strings.pickSuspectFirst,
          PlacementProblem.cellHasConfirmed => Strings.cellHasConfirmed,
          PlacementProblem.cellHasX => Strings.cellHasX,
          PlacementProblem.alreadyPlaced => Strings.alreadyPlaced,
          PlacementProblem.blocked => Strings.blockedCell,
        };
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.message, text: text),
            if (!_reduced && e.cell != null)
              VisualEffect(VisualKind.rejectNudge, cell: e.cell),
          ],
          haptics: const [HapticPulse(HapticKind.light)],
        );

      case SolveFailed():
        final text = Strings.wrongCells(e.wrongCells);
        return FeedbackPlan(
          visuals: [
            if (_reduced)
              const VisualEffect(VisualKind.errorFade, reduced: true)
            else
              const VisualEffect(VisualKind.shake, strength: 7),
            VisualEffect(VisualKind.errorText, text: text, reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.zumbido)],
          // Dos pulsos cortos, separados más de 50 ms.
          haptics: const [
            HapticPulse(HapticKind.medium),
            HapticPulse(HapticKind.medium, delayMs: 220),
          ],
        );

      case SolveIncomplete():
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.message,
                text: Strings.missingSuspects(e.missing)),
          ],
          haptics: const [HapticPulse(HapticKind.light)],
        );

      case SolveSucceeded():
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealStart,
                reveal: e.reveal, reduced: _reduced),
          ],
          sounds: const [SoundCue(SoundId.redoble)],
          haptics: const [HapticPulse(HapticKind.light)],
        );

      case RevealBeat():
        return _beatPlan(e);

      case RevealSkipped():
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealSkip,
                reveal: e.reveal, reduced: _reduced),
          ],
          stopSounds: true,
        );
    }
  }

  FeedbackPlan _beatPlan(RevealBeat b) {
    final r = b.reveal;
    switch (b.kind) {
      case RevealBeatKind.waveRow:
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealRow,
                count: b.index, reduced: _reduced),
          ],
          // Un tic cada vez más agudo: la ola "sube".
          sounds: [
            SoundCue(SoundId.tick, speed: 0.9 + 0.07 * b.index, volume: 0.4),
          ],
        );
      case RevealBeatKind.cascade:
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealHop,
                cell: b.cell, count: b.index, reduced: _reduced),
          ],
          sounds: [
            SoundCue(SoundId.tick, speed: 1.25 + 0.05 * b.index, volume: 0.45),
          ],
        );
      case RevealBeatKind.zoomHit:
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealZoom,
                cell: r.murdererCell, reduced: _reduced),
            if (!_reduced)
              const VisualEffect(VisualKind.cameraPunch, strength: 2.2),
          ],
          sounds: const [SoundCue(SoundId.golpe)],
          haptics: const [HapticPulse(HapticKind.heavy)],
        );
      case RevealBeatKind.star:
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealStar,
                count: b.index, reduced: _reduced),
          ],
          sounds: [SoundCue(SoundId.estrella, speed: 1.0 + 0.12 * b.index)],
          haptics: const [HapticPulse(HapticKind.light)],
        );
      case RevealBeatKind.fanfare:
        final n = _reduced ? 0 : _confetti(revealConfettiCount);
        return FeedbackPlan(
          visuals: [
            if (n > 0)
              VisualEffect(VisualKind.revealConfetti,
                  cell: r.murdererCell, count: n),
          ],
          sounds: const [SoundCue(SoundId.fanfarria)],
          haptics: const [
            HapticPulse(HapticKind.medium),
            HapticPulse(HapticKind.light, delayMs: 120),
          ],
        );
      case RevealBeatKind.end:
        return FeedbackPlan(
          visuals: [
            VisualEffect(VisualKind.revealEnd, reveal: r, reduced: _reduced),
          ],
        );
    }
  }
}
