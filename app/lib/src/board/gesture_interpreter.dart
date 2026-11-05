/// Interpreta el dedo sobre el tablero: toque corto = candidato, mantener
/// oprimido = confirmar. Lógica pura con la hora que le pasan (milisegundos),
/// así se prueba sin pantalla.
///
/// El toque se resuelve al SOLTAR (si no, no se podría distinguir de un
/// mantener oprimido); lo que sí responde de inmediato es el anillo de
/// progreso que se ve al apretar.
library;

import 'dart:ui';

sealed class CellGesture {
  final int cell;
  const CellGesture(this.cell);
}

class TapGesture extends CellGesture {
  const TapGesture(super.cell);
}

class HoldGesture extends CellGesture {
  const HoldGesture(super.cell);
}

class CellGestureInterpreter {
  CellGestureInterpreter({this.holdMs = 380, this.slopPx = 14});

  /// Cuánto hay que mantener oprimido para confirmar.
  final double holdMs;

  /// Cuánto se puede mover el dedo antes de cancelar el gesto.
  final double slopPx;

  int? _pointer;
  int? _cell;
  Offset _origin = Offset.zero;
  double _downAtMs = 0;
  bool _fired = false;

  /// Casilla bajo el dedo (null si no hay gesto en curso).
  int? get pressedCell => _cell;

  bool get active => _pointer != null && _cell != null;

  /// 0..1: avance hacia el mantener oprimido (para dibujar el anillo).
  double progressAt(double nowMs) {
    if (!active || _fired) return 0;
    return ((nowMs - _downAtMs) / holdMs).clamp(0.0, 1.0);
  }

  /// [cell] es la casilla bajo el dedo (null si cayó fuera del tablero).
  void down(int pointer, Offset position, int? cell, double nowMs) {
    if (_pointer != null) return; // solo seguimos el primer dedo
    if (cell == null) return;
    _pointer = pointer;
    _cell = cell;
    _origin = position;
    _downAtMs = nowMs;
    _fired = false;
  }

  void move(int pointer, Offset position) {
    if (pointer != _pointer) return;
    if ((position - _origin).distance > slopPx) cancel(pointer);
  }

  /// Se llama en cada cuadro. Devuelve el "mantener oprimido" en el momento
  /// exacto en que se cumple el tiempo, aunque el dedo siga abajo.
  CellGesture? update(double nowMs) {
    if (!active || _fired) return null;
    if (nowMs - _downAtMs >= holdMs) {
      _fired = true;
      return HoldGesture(_cell!);
    }
    return null;
  }

  /// Devuelve el toque si el dedo se soltó a tiempo.
  CellGesture? up(int pointer, double nowMs) {
    if (pointer != _pointer) return null;
    final cell = _cell!;
    final wasFired = _fired;
    _reset();
    if (wasFired) return null;
    return TapGesture(cell);
  }

  void cancel(int pointer) {
    if (pointer != _pointer) return;
    _reset();
  }

  void _reset() {
    _pointer = null;
    _cell = null;
    _fired = false;
  }
}
