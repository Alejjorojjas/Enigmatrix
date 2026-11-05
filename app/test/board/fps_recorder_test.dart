import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/fps_recorder.dart';

void main() {
  test('60 fps constantes: promedio y mínimo cerca de 60', () {
    final r = FpsRecorder()..start();
    for (var i = 0; i <= 120; i++) {
      r.addFrame(startMs: 1000 + i * (1000 / 60), spanMs: 8);
    }
    final rep = r.stop()!;
    expect(rep.frames, 120);
    expect(rep.averageFps, closeTo(60, 0.5));
    expect(rep.minFps, closeTo(60, 4));
    expect(rep.worstFrameMs, 8);
    expect(rep.slowFrames, 0);
  });

  test('una racha de cuadros lentos hunde el mínimo pero no el promedio', () {
    final r = FpsRecorder()..start();
    var t = 0.0;
    // 1 s a 60 fps, 0,5 s a 20 fps, 1,5 s a 60 fps.
    void run(double seconds, double fps) {
      final end = t + seconds * 1000;
      while (t < end) {
        r.addFrame(startMs: t, spanMs: fps < 30 ? 45 : 9);
        t += 1000 / fps;
      }
    }

    run(1, 60);
    run(0.5, 20);
    run(1.5, 60);
    final rep = r.stop()!;
    expect(rep.minFps, lessThan(30));
    expect(rep.averageFps, greaterThan(45));
    expect(rep.slowFrames, greaterThanOrEqualTo(9));
    expect(rep.worstFrameMs, 45);
  });

  test('fuera de la grabación no se acumula nada, pero el fps en vivo sí', () {
    final r = FpsRecorder();
    for (var i = 0; i < 70; i++) {
      r.addFrame(startMs: i * (1000 / 60), spanMs: 6);
    }
    expect(r.liveFps, closeTo(60, 2));
    expect(r.stop(), isNull);
  });

  test('menos de dos cuadros no da resultado', () {
    final r = FpsRecorder()..start();
    r.addFrame(startMs: 0, spanMs: 5);
    expect(r.stop(), isNull);
  });

  test('una grabación corta (menos de 0,5 s) usa el promedio como mínimo', () {
    final r = FpsRecorder()..start();
    for (var i = 0; i < 10; i++) {
      r.addFrame(startMs: i * 20.0, spanMs: 10);
    }
    final rep = r.stop()!;
    expect(rep.minFps, rep.averageFps);
  });

  test('el texto copiable lleva los números', () {
    final r = FpsRecorder()..start();
    for (var i = 0; i <= 60; i++) {
      r.addFrame(startMs: i * (1000 / 60), spanMs: 10);
    }
    final text = r.stop()!.toText();
    expect(text, contains('promedio'));
    expect(text, contains('mínimo'));
    expect(text, contains('fps'));
  });
}
