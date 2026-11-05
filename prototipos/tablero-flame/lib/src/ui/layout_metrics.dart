/// Medidas de la pantalla de juego, en un solo sitio y sin dibujar nada (se
/// prueban solas). La regla es: el tablero ocupa el ancho disponible menos un
/// margen de 12 px a cada lado y nada se desplaza.
///
/// Hay dos distribuciones:
///  - normal (teléfonos de 700 px de alto o más): la pista crece con el texto
///    hasta 3 líneas y el botón Resolver va en su propia fila;
///  - compacta (pantallas más bajas, por ejemplo 360x640): se prioriza el
///    tablero. La pista queda en una sola línea que se expande al tocarla (flota
///    sobre la interfaz, sin empujar nada) y Resolver va al lado de la pista.
library;

import 'dart:math' as math;
import 'dart:ui';

class ScreenMetrics {
  const ScreenMetrics._({
    required this.compact,
    required this.boardSide,
    required this.stageHeight,
  });

  /// true = distribución compacta (pantalla baja).
  final bool compact;

  /// Lado que tendrá el tablero (el ancho menos los márgenes).
  final double boardSide;

  /// Alto del escenario: el tablero más su margen vertical.
  final double stageHeight;

  /// Margen lateral de la interfaz y del tablero, en píxeles.
  static const double sidePad = 12;

  // ---- alturas de cada bloque (distribución normal) ----------------------------
  static const double headerTopNormal = 4;
  static const double headerRow1 = 48; // opciones, cronómetro, deshacer, piel, modo
  static const double headerRow2Normal = 40; // título y selector de caso
  static const double headerGapNormal = 2;
  static const double toolbarNormal = 56;
  static const double resolveNormal = 46;
  static const double gapNormal = 6;
  static const double stageMarginNormal = 4;

  /// Lo que mide la bandeja de retratos (retrato de 54 px + nombre).
  static const double portraitBox = 54;
  static const double portraitRow = 74;

  /// Tope de la pista en la distribución normal (3 líneas).
  static const double hintMaxNormal = 78;

  // ---- distribución compacta ---------------------------------------------------
  static const double headerTopCompact = 4;
  static const double headerRow2Compact = 38;
  static const double headerGapCompact = 4;
  static const double toolbarCompact = 52;
  static const double resolveCompact = 46;
  static const double gapCompact = 4;
  static const double stageMarginCompact = 6;
  static const double hintCompact = 46;

  /// Distribución compacta si lo que queda de alto no alcanza para la normal
  /// con la pista de 3 líneas.
  static double normalNeeded(double side) =>
      headerTopNormal +
      headerRow1 +
      headerGapNormal +
      headerRow2Normal +
      gapNormal +
      side +
      2 * stageMarginNormal +
      gapNormal +
      toolbarNormal +
      gapNormal +
      portraitRow +
      4 +
      hintMaxNormal +
      gapNormal +
      resolveNormal +
      gapNormal;

  /// Alto que piden, como mínimo, todos los bloques de abajo en la compacta.
  static const double bottomCompactMin = toolbarCompact +
      gapCompact +
      portraitRow +
      gapCompact +
      hintCompact +
      gapCompact;

  factory ScreenMetrics.of(Size box) {
    // En pantallas anchas y bajas el tablero se achica para que quepa todo.
    final maxSide = box.height -
        (headerTopCompact + headerRow1 + headerRow2Compact + headerGapCompact) -
        2 * stageMarginCompact -
        bottomCompactMin;
    final side = math.max(0.0, math.min(box.width - 2 * sidePad, maxSide));
    final compact = box.height < normalNeeded(side);
    final margin = compact ? stageMarginCompact : stageMarginNormal;
    // Si sobra alto en la distribución normal, el escenario lo aprovecha para
    // mostrar más mesa alrededor del tablero (hasta 24 px de más).
    final extra = compact ? 0.0 : math.min(24.0, math.max(0.0, box.height - normalNeeded(side)));
    return ScreenMetrics._(
      compact: compact,
      boardSide: side,
      stageHeight: side + 2 * margin + extra,
    );
  }

  /// Margen vertical entre el borde del escenario y el tablero.
  double get stageMargin => compact ? stageMarginCompact : stageMarginNormal;

  double get toolbarHeight => compact ? toolbarCompact : toolbarNormal;
  double get gap => compact ? gapCompact : gapNormal;
}
