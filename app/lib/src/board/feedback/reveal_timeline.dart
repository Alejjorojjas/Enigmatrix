/// Reloj de la secuencia de resolver y revelar. Es un dato puro: una lista de
/// momentos con su hora en milisegundos. La escena lo recorre y, en cada
/// momento, le avisa al director de feedback.
///
/// Orden: viñeta y redoble -> ola de luz fila por fila -> inocentes en
/// cascada -> pausa -> zoom al asesino con golpe -> estrellas -> fanfarria.
/// Dura de 3,5 a 4 s. Se puede saltar después de [skipAfterMs].
library;

import 'feedback_event.dart';

class RevealMoment {
  final double atMs;
  final RevealBeatKind kind;
  final int index;
  final int? cell;
  const RevealMoment(this.atMs, this.kind, {this.index = 0, this.cell});
}

class RevealTimeline {
  /// Se puede saltar a partir de 1 s (regla del informe gráfico).
  static const skipAfterMs = 1000.0;

  /// Cuánto dura el redoble y la viñeta de entrada antes de la ola.
  static const waveStartMs = 200.0;
  static const waveSpanMs = 1000.0;
  static const cascadeStartMs = 1150.0;
  static const cascadeStepMs = 90.0;
  static const hopMs = 360.0;
  static const pauseMs = 200.0;
  static const starCount = 3;

  final RevealData reveal;
  final List<RevealMoment> moments;

  RevealTimeline._(this.reveal, this.moments);

  factory RevealTimeline.build(RevealData reveal) {
    final n = reveal.gridSize;
    final moments = <RevealMoment>[];

    // Ola fila por fila.
    for (var r = 0; r < n; r++) {
      moments.add(RevealMoment(
        waveStartMs + r * (waveSpanMs / n),
        RevealBeatKind.waveRow,
        index: r,
      ));
    }

    // Inocentes en cascada: de izquierda a derecha.
    final innocents = [...reveal.innocentCells]
      ..sort((a, b) {
        final c = (a % n).compareTo(b % n);
        return c != 0 ? c : a.compareTo(b);
      });
    for (var i = 0; i < innocents.length; i++) {
      moments.add(RevealMoment(
        cascadeStartMs + i * cascadeStepMs,
        RevealBeatKind.cascade,
        index: i,
        cell: innocents[i],
      ));
    }

    final cascadeEnd =
        cascadeStartMs + innocents.length * cascadeStepMs + hopMs * 0.7;
    final zoomAt = cascadeEnd + pauseMs;
    moments.add(RevealMoment(zoomAt, RevealBeatKind.zoomHit,
        cell: reveal.murdererCell));
    for (var s = 0; s < starCount; s++) {
      moments.add(RevealMoment(zoomAt + 600 + s * 250, RevealBeatKind.star,
          index: s));
    }
    final fanfareAt = zoomAt + 600 + (starCount - 1) * 250;
    moments.add(RevealMoment(fanfareAt, RevealBeatKind.fanfare));
    moments.add(RevealMoment(fanfareAt + 600, RevealBeatKind.end));

    moments.sort((a, b) => a.atMs.compareTo(b.atMs));
    return RevealTimeline._(reveal, moments);
  }

  double get totalMs => moments.last.atMs;

  /// Momentos con hora en (fromMs, toMs].
  List<RevealMoment> between(double fromMs, double toMs) => [
        for (final m in moments)
          if (m.atMs > fromMs && m.atMs <= toMs) m
      ];

  RevealBeat beatFor(RevealMoment m) =>
      RevealBeat(m.kind, reveal, index: m.index, cell: m.cell);
}
