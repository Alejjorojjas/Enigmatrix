import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/feedback/feedback_director.dart';
import 'package:tablero_flame/src/feedback/feedback_event.dart';
import 'package:tablero_flame/src/feedback/feedback_plan.dart';
import 'package:tablero_flame/src/settings.dart';

import 'helpers.dart';

const reveal = RevealData(
  gridSize: 6,
  murdererCell: 14,
  victimCell: 3,
  murdererId: 'c2',
  murdererName: 'Bruno',
  innocentCells: [0, 9, 20, 29],
);

List<int> gaps(List<HapticPulse> pulses) {
  final d = pulses.map((p) => p.delayMs).toList();
  return [for (var i = 1; i < d.length; i++) d[i] - d[i - 1]];
}

void main() {
  group('tocar un sospechoso', () {
    test('elegirlo: pulso visual, tick suave y vibración mínima', () {
      final r = Rig();
      final p = r.director.plan(const SuspectTapped('c1', selected: true));
      expect(p.hasVisual(VisualKind.selectPulse), isTrue);
      expect(p.sounds.map((s) => s.id), [SoundId.tick]);
      expect(p.haptics.map((h) => h.kind), [HapticKind.selection]);
    });

    test('soltarlo no dispara nada', () {
      final r = Rig();
      final p = r.director.plan(const SuspectTapped('c1', selected: false));
      expect(p.visuals, isEmpty);
      expect(p.sounds, isEmpty);
      expect(p.haptics, isEmpty);
    });
  });

  group('anotar un candidato', () {
    test('marca de lápiz sin partículas y sonidos que rotan en 3 variantes', () {
      final r = Rig();
      final ids = <SoundId>[];
      for (var i = 0; i < 4; i++) {
        r.nowMs += 200;
        final p = r.director.plan(const CandidateNoted(5, 'c1'));
        expect(p.hasVisual(VisualKind.pencilMark), isTrue);
        expect(p.hasVisual(VisualKind.confetti), isFalse);
        expect(p.hasVisual(VisualKind.flash), isFalse);
        ids.add(p.sounds.single.id);
      }
      expect(ids,
          [SoundId.lapiz1, SoundId.lapiz2, SoundId.lapiz3, SoundId.lapiz1]);
    });

    test('la vibración de lápiz sale como mucho cada 80 ms', () {
      final r = Rig();
      r.nowMs = 1000;
      expect(
          r.director.plan(const CandidateNoted(1, 'c1')).haptics, hasLength(1));
      r.nowMs = 1050; // 50 ms después: se omite
      expect(r.director.plan(const CandidateNoted(2, 'c1')).haptics, isEmpty);
      r.nowMs = 1080; // 80 ms después de la última que sí salió
      expect(
          r.director.plan(const CandidateNoted(3, 'c1')).haptics, hasLength(1));
    });
  });

  group('confirmar', () {
    test(
        'versión normal: caída, onda, 6-8 partículas, destello y golpe de cámara',
        () {
      final r = Rig();
      final p = r.director.plan(const Confirmed(7, 'c1'));
      expect(p.hasVisual(VisualKind.confirmDrop), isTrue);
      expect(p.hasVisual(VisualKind.ripple), isTrue);
      expect(p.hasVisual(VisualKind.flash), isTrue);
      expect(p.hasVisual(VisualKind.cameraPunch), isTrue);
      final n = p.visualsOf(VisualKind.confetti).single.count;
      expect(n, inInclusiveRange(6, 8));
      expect(p.sounds.map((s) => s.id), [SoundId.sello]);
      // Clic y golpe leve, separados al menos 50 ms.
      expect(p.haptics.map((h) => h.kind),
          [HapticKind.selection, HapticKind.light]);
      expect(gaps(p.haptics).every((g) => g >= 50), isTrue);
    });

    test('el tope de partículas recorta el confeti', () {
      final r = Rig(settings: GameSettings(particleCap: 3));
      expect(
          r.director
              .plan(const Confirmed(7, 'c1'))
              .visualsOf(VisualKind.confetti)
              .single
              .count,
          3);
      r.settings.particleCap = 0;
      r.nowMs += 1000;
      expect(r.director.plan(const Confirmed(7, 'c1')).hasVisual(VisualKind.confetti),
          isFalse);
    });

    test(
        'versión reducida: solo fundidos, sin sacudidas ni destellos ni partículas',
        () {
      final r = Rig(settings: GameSettings(reduceMotion: true));
      final p = r.director.plan(const Confirmed(7, 'c1'));
      expect(p.hasVisual(VisualKind.confirmFade), isTrue);
      expect(p.hasVisual(VisualKind.fadeGlow), isTrue);
      for (final k in [
        VisualKind.confirmDrop,
        VisualKind.ripple,
        VisualKind.confetti,
        VisualKind.flash,
        VisualKind.cameraPunch,
      ]) {
        expect(p.hasVisual(k), isFalse, reason: '$k no debe salir en reducido');
      }
      // El sonido y la vibración siguen (tienen su propio interruptor).
      expect(p.sounds, isNotEmpty);
    });

    test('máximo 3 destellos por segundo: el siguiente se cambia por fundido',
        () {
      final r = Rig();
      r.nowMs = 5000;
      expect(r.director.plan(const Confirmed(1, 'c1')).hasVisual(VisualKind.flash),
          isTrue);
      r.nowMs = 5200; // 200 ms después
      final p2 = r.director.plan(const Confirmed(2, 'c2'));
      expect(p2.hasVisual(VisualKind.flash), isFalse);
      expect(p2.hasVisual(VisualKind.fadeGlow), isTrue);
      r.nowMs = 5000 + FeedbackDirector.flashMinGapMs;
      expect(r.director.plan(const Confirmed(3, 'c3')).hasVisual(VisualKind.flash),
          isTrue);
    });
  });

  group('tachar fila y columna en ola', () {
    test('normal: ola con arpegio y pulsos separados', () {
      final r = Rig();
      final p = r.director.plan(const LinesCrossed(7, [6, 8, 1, 13]));
      final v = p.visualsOf(VisualKind.crossWave).single;
      expect(v.cells, [6, 8, 1, 13]);
      expect(v.cell, 7);
      expect(p.sounds.map((s) => s.id), [SoundId.arpegio]);
      expect(gaps(p.haptics).every((g) => g >= 50), isTrue);
    });

    test('reducida: fundido en vez de ola', () {
      final r = Rig(settings: GameSettings(reduceMotion: true));
      final p = r.director.plan(const LinesCrossed(7, [6, 8]));
      expect(p.hasVisual(VisualKind.crossFade), isTrue);
      expect(p.hasVisual(VisualKind.crossWave), isFalse);
    });

    test('sin casillas nuevas no dispara nada', () {
      final r = Rig();
      final p = r.director.plan(const LinesCrossed(7, []));
      expect(p.visuals, isEmpty);
      expect(p.sounds, isEmpty);
    });
  });

  group('tachar una casilla a mano', () {
    test('una sola X con lápiz y vibración mínima', () {
      final r = Rig();
      final p = r.director.plan(const CrossMarked(9));
      final v = p.visualsOf(VisualKind.crossWave).single;
      expect(v.cell, 9);
      expect(v.cells, [9]);
      expect(p.sounds.map((s) => s.id), [SoundId.lapiz2]);
      expect(p.haptics.map((h) => h.kind), [HapticKind.selection]);
    });

    test('con reducir movimiento es un fundido', () {
      final r = Rig(settings: GameSettings(reduceMotion: true));
      final p = r.director.plan(const CrossMarked(9));
      expect(p.hasVisual(VisualKind.crossFade), isTrue);
      expect(p.hasVisual(VisualKind.crossWave), isFalse);
    });
  });

  group('error al resolver', () {
    test('normal: sacudida amortiguada, texto, zumbido grave y dos pulsos', () {
      final r = Rig();
      final p = r.director.plan(const SolveFailed(3));
      expect(p.hasVisual(VisualKind.shake), isTrue);
      expect(p.visualsOf(VisualKind.errorText).single.text,
          '3 casillas no cuadran');
      expect(p.sounds.map((s) => s.id), [SoundId.zumbido]);
      expect(p.haptics, hasLength(2));
      expect(gaps(p.haptics).every((g) => g >= 50), isTrue);
    });

    test('singular', () {
      final r = Rig();
      expect(
          r.director
              .plan(const SolveFailed(1))
              .visualsOf(VisualKind.errorText)
              .single
              .text,
          '1 casilla no cuadra');
    });

    test('reducida: fundido de error y texto, sin sacudida', () {
      final r = Rig(settings: GameSettings(reduceMotion: true));
      final p = r.director.plan(const SolveFailed(2));
      expect(p.hasVisual(VisualKind.errorFade), isTrue);
      expect(p.hasVisual(VisualKind.shake), isFalse);
      expect(p.visualsOf(VisualKind.errorText).single.text,
          '2 casillas no cuadran');
    });
  });

  group('avisos', () {
    test('tocar sin sospechoso: "Elige primero a un sospechoso"', () {
      final r = Rig();
      final p = r.director
          .plan(const PlacementRejected(PlacementProblem.noSuspect, cell: 4));
      expect(p.visualsOf(VisualKind.message).single.text,
          'Elige primero a un sospechoso');
      expect(p.sounds, isEmpty);
    });

    test('resolver con el tablero incompleto', () {
      final r = Rig();
      final p = r.director.plan(const SolveIncomplete(2));
      expect(p.visualsOf(VisualKind.message).single.text,
          'Faltan 2 personajes por ubicar');
    });
  });

  group('resolver y revelar', () {
    test('al resolver: viñeta de inicio y redoble', () {
      final r = Rig();
      final p = r.director.plan(const SolveSucceeded(reveal));
      expect(p.hasVisual(VisualKind.revealStart), isTrue);
      expect(p.sounds.map((s) => s.id), [SoundId.redoble]);
    });

    test('golpe al zoom: normal con golpe de cámara; reducida sin él', () {
      final r = Rig();
      final p =
          r.director.plan(const RevealBeat(RevealBeatKind.zoomHit, reveal));
      expect(p.hasVisual(VisualKind.revealZoom), isTrue);
      expect(p.hasVisual(VisualKind.cameraPunch), isTrue);
      expect(p.sounds.map((s) => s.id), [SoundId.golpe]);
      expect(p.haptics.single.kind, HapticKind.heavy);

      r.settings.reduceMotion = true;
      final q =
          r.director.plan(const RevealBeat(RevealBeatKind.zoomHit, reveal));
      expect(q.hasVisual(VisualKind.cameraPunch), isFalse);
      expect(q.visualsOf(VisualKind.revealZoom).single.reduced, isTrue);
    });

    test('las estrellas suenan cada vez más agudas', () {
      final r = Rig();
      final speeds = [
        for (var i = 0; i < 3; i++)
          r.director
              .plan(RevealBeat(RevealBeatKind.star, reveal, index: i))
              .sounds
              .single
              .speed
      ];
      expect(speeds[0] < speeds[1] && speeds[1] < speeds[2], isTrue);
    });

    test('fanfarria: confeti según el tope y ninguno en reducido', () {
      final r = Rig(settings: GameSettings(particleCap: 20));
      var p = r.director.plan(const RevealBeat(RevealBeatKind.fanfare, reveal));
      expect(p.visualsOf(VisualKind.revealConfetti).single.count, 20);
      expect(p.sounds.map((s) => s.id), [SoundId.fanfarria]);
      r.settings.reduceMotion = true;
      p = r.director.plan(const RevealBeat(RevealBeatKind.fanfare, reveal));
      expect(p.hasVisual(VisualKind.revealConfetti), isFalse);
    });

    test('la ola y la cascada llevan su tic y su efecto', () {
      final r = Rig();
      final row = r.director
          .plan(const RevealBeat(RevealBeatKind.waveRow, reveal, index: 2));
      expect(row.visualsOf(VisualKind.revealRow).single.count, 2);
      final hop = r.director.plan(
          const RevealBeat(RevealBeatKind.cascade, reveal, index: 1, cell: 9));
      expect(hop.visualsOf(VisualKind.revealHop).single.cell, 9);
    });

    test('saltar corta los sonidos largos', () {
      final r = Rig();
      final p = r.director.plan(const RevealSkipped(reveal));
      expect(p.stopSounds, isTrue);
      expect(p.hasVisual(VisualKind.revealSkip), isTrue);
    });
  });

  group('interruptores', () {
    test('sin sonido no suena nada, con sus efectos visuales intactos', () {
      final r = Rig(settings: GameSettings(soundOn: false));
      final p = r.director.plan(const Confirmed(1, 'c1'));
      expect(p.sounds, isEmpty);
      expect(p.haptics, isNotEmpty);
      expect(p.hasVisual(VisualKind.confirmDrop), isTrue);
    });

    test('sin vibración no vibra nada', () {
      final r = Rig(settings: GameSettings(hapticsOn: false));
      final p = r.director.plan(const Confirmed(1, 'c1'));
      expect(p.haptics, isEmpty);
      expect(p.sounds, isNotEmpty);
    });
  });

  group('handle: animación, sonido y vibración en la misma llamada', () {
    test('confirmar lanza los tres destinos a la vez', () {
      final r = Rig();
      r.director.handle(const Confirmed(7, 'c1'));
      expect(r.visual.played, isNotEmpty);
      expect(r.sound.played.map((s) => s.id), [SoundId.sello]);
      // El primer pulso sale en el acto; el segundo queda agendado a 60 ms.
      expect(r.haptic.pulses, [HapticKind.selection]);
      expect(r.scheduled.single.$1, 60);
      r.runScheduled();
      expect(r.haptic.pulses, [HapticKind.selection, HapticKind.light]);
    });

    test('saltar la secuencia manda cortar el audio', () {
      final r = Rig();
      r.director.handle(const RevealSkipped(reveal));
      expect(r.sound.stops, 1);
    });
  });
}
