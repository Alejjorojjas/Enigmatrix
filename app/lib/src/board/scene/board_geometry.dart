/// Dónde cae cada casilla en pantalla. Puro (sin Flame): se prueba solo.
library;

import 'dart:math' as math;
import 'dart:ui';

/// Margen horizontal y vertical con que la escena ajusta el tablero al área de
/// juego. La capa de semántica usa los mismos para caer justo sobre cada
/// casilla.
const double kSceneMargin = 12;
const double kSceneMarginY = 2;

class BoardGeometry {
  /// Lado de la cuadrícula (6 u 8).
  final int n;

  /// Cuadrado del tablero en coordenadas de la escena.
  final Rect board;

  const BoardGeometry(this.n, this.board);

  /// Ajusta el tablero al área de juego. El margen horizontal ([margin], por
  /// omisión 14) deja ver la mesa y la sombra a los lados; el vertical
  /// ([marginY], por omisión igual al horizontal) puede ser menor para que el
  /// tablero ocupe todo el ancho disponible aunque el área sea baja.
  factory BoardGeometry.fit(int n, Size area,
      {double margin = 14, double? marginY}) {
    final my = marginY ?? margin;
    final side = math.max(
        0.0, math.min(area.width - 2 * margin, area.height - 2 * my));
    final left = (area.width - side) / 2;
    final top = (area.height - side) / 2;
    return BoardGeometry(n, Rect.fromLTWH(left, top, side, side));
  }

  double get cell => board.width / n;

  int rowOf(int index) => index ~/ n;
  int colOf(int index) => index % n;

  Rect cellRect(int index) => Rect.fromLTWH(
        board.left + colOf(index) * cell,
        board.top + rowOf(index) * cell,
        cell,
        cell,
      );

  Offset cellCenter(int index) => cellRect(index).center;

  /// Casilla bajo el punto, o null si cae fuera del tablero.
  int? cellAt(Offset p) {
    if (!board.contains(p)) return null;
    final c = ((p.dx - board.left) / cell).floor().clamp(0, n - 1);
    final r = ((p.dy - board.top) / cell).floor().clamp(0, n - 1);
    return r * n + c;
  }
}
