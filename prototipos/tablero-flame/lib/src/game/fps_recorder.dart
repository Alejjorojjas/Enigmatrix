/// Medidor de cuadros por segundo. La parte de cálculo es pura (recibe las
/// marcas de tiempo de cada cuadro); [FpsMonitor] la conecta al motor de
/// Flutter.
///
/// Definiciones (iguales en pantalla, en el texto copiado y en el README):
///  - Promedio: cuadros / duración total de la grabación.
///  - Mínimo: el peor tramo de 0,5 s (cuadros del tramo / 0,5). Un solo
///    cuadro lento no lo hunde, pero una racha de cuadros lentos sí.
///  - Peor cuadro: la mayor duración de construir + dibujar un cuadro.
///  - Cuadros lentos: los que tardaron más de 20 ms en construirse y dibujarse
///    (no caben en 60 fps con margen).
library;

import 'dart:collection';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class FpsReport {
  final int frames;
  final double durationMs;
  final double averageFps;
  final double minFps;
  final double worstFrameMs;
  final int slowFrames;

  const FpsReport({
    required this.frames,
    required this.durationMs,
    required this.averageFps,
    required this.minFps,
    required this.worstFrameMs,
    required this.slowFrames,
  });

  String toText({String label = 'Secuencia de resolver'}) =>
      '$label: promedio ${averageFps.toStringAsFixed(1)} fps, '
      'mínimo ${minFps.toStringAsFixed(1)} fps (tramos de 0,5 s), '
      'peor cuadro ${worstFrameMs.toStringAsFixed(1)} ms, '
      'cuadros lentos (>20 ms) $slowFrames de $frames, '
      'duración ${(durationMs / 1000).toStringAsFixed(2)} s';
}

class FpsRecorder {
  static const windowMs = 500.0;
  static const slowFrameMs = 20.0;

  bool _recording = false;
  final List<double> _stamps = []; // inicio de cada cuadro, en ms
  double _worst = 0;
  int _slow = 0;
  FpsReport? _last;

  // Fps en vivo: cuadros de la última ventana de 1 s.
  final Queue<double> _live = Queue<double>();
  double _liveFps = 0;

  bool get recording => _recording;
  FpsReport? get lastReport => _last;
  double get liveFps => _liveFps;

  void start() {
    _recording = true;
    _stamps.clear();
    _worst = 0;
    _slow = 0;
  }

  /// Termina la grabación y devuelve el resultado (null si no hubo cuadros).
  FpsReport? stop() {
    if (!_recording) return _last;
    _recording = false;
    _last = _build();
    return _last;
  }

  /// [startMs]: marca de tiempo del cuadro. [spanMs]: cuánto tardó en
  /// construirse y dibujarse.
  void addFrame({required double startMs, required double spanMs}) {
    _live.addLast(startMs);
    while (_live.isNotEmpty && startMs - _live.first > 1000) {
      _live.removeFirst();
    }
    _liveFps = _live.length > 1
        ? (_live.length - 1) * 1000 / (startMs - _live.first)
        : 0;

    if (!_recording) return;
    // El primer cuadro solo marca el inicio: no cuenta como cuadro medido.
    if (_stamps.isNotEmpty) {
      if (spanMs > _worst) _worst = spanMs;
      if (spanMs > slowFrameMs) _slow++;
    }
    _stamps.add(startMs);
  }

  FpsReport? _build() {
    if (_stamps.length < 2) return null;
    final t0 = _stamps.first;
    final duration = _stamps.last - t0;
    if (duration <= 0) return null;
    final frames = _stamps.length - 1;
    final avg = frames * 1000 / duration;

    var minFps = avg;
    if (duration >= windowMs) {
      final windows = (duration / windowMs).floor();
      final counts = List<int>.filled(windows, 0);
      for (var i = 1; i < _stamps.length; i++) {
        final w = ((_stamps[i] - t0) / windowMs).floor();
        if (w < windows) counts[w]++;
      }
      minFps = counts.reduce((a, b) => a < b ? a : b) * 1000 / windowMs;
    }
    return FpsReport(
      frames: frames,
      durationMs: duration,
      averageFps: avg,
      minFps: minFps,
      worstFrameMs: _worst,
      slowFrames: _slow,
    );
  }
}

/// Conecta el [FpsRecorder] con el motor: cada cuadro real que Flutter
/// termina de dibujar se anota con su hora y su duración.
class FpsMonitor extends ChangeNotifier {
  FpsMonitor() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  final FpsRecorder recorder = FpsRecorder();

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      recorder.addFrame(
        startMs: t.timestampInMicroseconds(FramePhase.vsyncStart) / 1000.0,
        spanMs: t.totalSpan.inMicroseconds / 1000.0,
      );
    }
    notifyListeners();
  }

  void startRecording() {
    recorder.start();
    notifyListeners();
  }

  FpsReport? stopRecording() {
    final r = recorder.stop();
    notifyListeners();
    return r;
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }
}
