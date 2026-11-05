import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/scene/board_geometry.dart';

void main() {
  final g = BoardGeometry.fit(6, const Size(360, 500));

  test('el tablero es cuadrado y queda centrado', () {
    expect(g.board.width, g.board.height);
    expect(g.board.center.dx, closeTo(180, 1e-9));
    expect(g.board.center.dy, closeTo(250, 1e-9));
    expect(g.board.width, lessThan(360));
  });

  test('cada casilla se encuentra en su centro', () {
    for (var i = 0; i < 36; i++) {
      expect(g.cellAt(g.cellCenter(i)), i);
    }
  });

  test('fuera del tablero no hay casilla', () {
    expect(g.cellAt(const Offset(2, 2)), isNull);
    expect(g.cellAt(const Offset(180, 10)), isNull);
    expect(g.cellAt(g.board.bottomRight + const Offset(5, 5)), isNull);
  });

  test('fila y columna', () {
    expect(g.rowOf(13), 2);
    expect(g.colOf(13), 1);
    final r = g.cellRect(13);
    expect(r.width, closeTo(g.cell, 1e-9));
    expect(r.left, closeTo(g.board.left + g.cell, 1e-9));
  });

  test('un área mínima no rompe el cálculo', () {
    final tiny = BoardGeometry.fit(8, const Size(10, 10));
    expect(tiny.board.width, 0);
  });
}
