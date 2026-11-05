/// Lo que el director decide para un evento: qué animar, qué sonar y qué
/// vibrar. Es un dato puro (sin Flutter), por eso se puede probar sin pantalla.
library;

import 'feedback_event.dart';

/// Los 12 sonidos propios generados por tool/generar_sonidos.py.
enum SoundId {
  tick,
  lapiz1,
  lapiz2,
  lapiz3,
  borrar,
  sello,
  arpegio,
  zumbido,
  redoble,
  golpe,
  estrella,
  fanfarria;

  String get asset => 'assets/sonidos/$name.wav';

  /// Sonidos largos que se cortan si el jugador salta la secuencia.
  bool get isLong =>
      this == redoble || this == golpe || this == fanfarria || this == estrella;
}

class SoundCue {
  final SoundId id;
  final double speed;
  final double volume;
  const SoundCue(this.id, {this.speed = 1.0, this.volume = 1.0});

  @override
  String toString() => 'SoundCue($id x$speed)';
}

enum HapticKind { selection, light, medium, heavy }

class HapticPulse {
  final HapticKind kind;

  /// 0 = en el mismo cuadro del evento. Los demás pulsos van separados por
  /// 50 ms o más para que se distingan.
  final int delayMs;
  const HapticPulse(this.kind, {this.delayMs = 0});

  @override
  String toString() => 'HapticPulse($kind @$delayMs)';
}

enum VisualKind {
  // Tocar y anotar.
  selectPulse,
  pencilMark,
  erasePuff,
  rejectNudge,
  // Confirmar (versión normal).
  confirmDrop,
  ripple,
  confetti,
  flash,
  cameraPunch,
  // Confirmar (versión reducida: solo fundidos).
  confirmFade,
  fadeGlow,
  // Tachar en ola.
  crossWave,
  crossFade,
  // Error.
  shake,
  errorFade,
  errorText,
  // Aviso corto en pantalla.
  message,
  // Revelar.
  revealStart,
  revealRow,
  revealHop,
  revealZoom,
  revealStar,
  revealConfetti,
  revealEnd,
  revealSkip,
}

class VisualEffect {
  final VisualKind kind;
  final int? cell;
  final String? charId;
  final int count;
  final List<int> cells;
  final String? text;

  /// Fuerza (golpe de cámara, amplitud de sacudida en píxeles, etc.).
  final double strength;

  /// Para efectos que se ven distinto en movimiento reducido (selectPulse,
  /// pencilMark, revealStart...).
  final bool reduced;
  final RevealData? reveal;

  const VisualEffect(
    this.kind, {
    this.cell,
    this.charId,
    this.count = 0,
    this.cells = const [],
    this.text,
    this.strength = 1.0,
    this.reduced = false,
    this.reveal,
  });

  @override
  String toString() => 'Visual($kind${cell != null ? ' cell=$cell' : ''}'
      '${count > 0 ? ' n=$count' : ''}${reduced ? ' reduced' : ''})';
}

class FeedbackPlan {
  final List<VisualEffect> visuals;
  final List<SoundCue> sounds;
  final List<HapticPulse> haptics;

  /// Cortar los sonidos largos que estén sonando (saltar la secuencia).
  final bool stopSounds;

  const FeedbackPlan({
    this.visuals = const [],
    this.sounds = const [],
    this.haptics = const [],
    this.stopSounds = false,
  });

  static const empty = FeedbackPlan();

  bool hasVisual(VisualKind k) => visuals.any((v) => v.kind == k);
  Iterable<VisualEffect> visualsOf(VisualKind k) =>
      visuals.where((v) => v.kind == k);
}
