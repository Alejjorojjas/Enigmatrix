import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/gesture_interpreter.dart';

void main() {
  test('toque corto = candidato, se resuelve al soltar', () {
    final g = CellGestureInterpreter();
    g.down(1, const Offset(10, 10), 5, 0);
    expect(g.update(100), isNull);
    final r = g.up(1, 120);
    expect(r, isA<TapGesture>());
    expect(r!.cell, 5);
    expect(g.active, isFalse);
  });

  test(
    'mantener oprimido = confirmar, en el cuadro en que se cumple el tiempo',
    () {
      final g = CellGestureInterpreter(holdMs: 380);
      g.down(1, Offset.zero, 7, 1000);
      expect(g.update(1379), isNull);
      final h = g.update(1380);
      expect(h, isA<HoldGesture>());
      expect(h!.cell, 7);
      // No se repite y al soltar no cuenta como toque.
      expect(g.update(1500), isNull);
      expect(g.up(1, 1600), isNull);
    },
  );

  test('mover el dedo más allá del margen cancela', () {
    final g = CellGestureInterpreter(slopPx: 14);
    g.down(1, Offset.zero, 3, 0);
    g.move(1, const Offset(5, 5)); // dentro del margen
    expect(g.active, isTrue);
    g.move(1, const Offset(30, 0));
    expect(g.active, isFalse);
    expect(g.up(1, 50), isNull);
  });

  test('solo se sigue el primer dedo', () {
    final g = CellGestureInterpreter();
    g.down(1, Offset.zero, 2, 0);
    g.down(2, const Offset(50, 50), 9, 10);
    expect(g.pressedCell, 2);
    expect(g.up(2, 20), isNull);
    expect(g.up(1, 30), isA<TapGesture>());
  });

  test('un dedo que cae fuera del tablero no inicia nada', () {
    final g = CellGestureInterpreter();
    g.down(1, Offset.zero, null, 0);
    expect(g.active, isFalse);
  });

  test('progreso del anillo de mantener oprimido', () {
    final g = CellGestureInterpreter(holdMs: 400);
    expect(g.progressAt(0), 0);
    g.down(1, Offset.zero, 1, 100);
    expect(g.progressAt(100), 0);
    expect(g.progressAt(300), closeTo(0.5, 1e-9));
    expect(g.progressAt(900), 1);
  });

  test('después de un gesto se puede empezar otro de inmediato', () {
    final g = CellGestureInterpreter();
    g.down(1, Offset.zero, 1, 0);
    expect(g.up(1, 50), isA<TapGesture>());
    g.down(2, Offset.zero, 4, 60);
    expect(g.up(2, 100)!.cell, 4);
  });
}
