import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/scene/particles.dart';

void main() {
  const colors = [Color(0xFFFFFFFF), Color(0xFFFF0000)];

  test('una ráfaga lanza lo pedido si cabe en el tope', () {
    final p = ParticlePool();
    final n = p.burst(const Offset(10, 10), 7, colors, cap: 40);
    expect(n, 7);
    expect(p.active, 7);
  });

  test('el tope de partículas vivas se respeta entre ráfagas', () {
    final p = ParticlePool();
    p.burst(Offset.zero, 15, colors, cap: 20);
    final n = p.burst(Offset.zero, 15, colors, cap: 20);
    expect(n, 5);
    expect(p.active, 20);
  });

  test('con tope 0 no sale nada', () {
    final p = ParticlePool();
    expect(p.burst(Offset.zero, 10, colors, cap: 0), 0);
    expect(p.active, 0);
  });

  test('las partículas mueren con el tiempo y liberan sitio', () {
    final p = ParticlePool();
    p.burst(Offset.zero, 10, colors, cap: 40, life: 0.5);
    for (var i = 0; i < 60; i++) {
      p.update(1 / 60);
    }
    expect(p.active, 0);
    expect(p.burst(Offset.zero, 10, colors, cap: 10), 10);
  });

  test('nunca pasa de la capacidad del arreglo', () {
    final p = ParticlePool(capacity: 12);
    expect(p.burst(Offset.zero, 50, colors, cap: 150), 12);
  });

  test('dibujar y limpiar no falla', () {
    final p = ParticlePool();
    p.burst(const Offset(50, 50), 20, colors, cap: 40);
    p.update(0.05);
    final rec = PictureRecorder();
    p.render(Canvas(rec));
    rec.endRecording().dispose();
    p.clear();
    expect(p.active, 0);
  });
}
