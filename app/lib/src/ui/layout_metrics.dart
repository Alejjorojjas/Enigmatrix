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
///
/// Con el texto del sistema agrandado (hasta 1,3 en la partida) los bloques que
/// llevan texto crecen lo justo (título, retratos y pista) y el tablero cede
/// ese alto: así nada desborda. A escala 1 las medidas son las de siempre.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextScaler;

/// Mayor escala de texto que respeta la pantalla de partida (la interfaz de
/// juego tiene alturas medidas; más allá de esto se queda en 1,3).
const double kGameMaxTextScale = 1.3;

class ScreenMetrics {
  const ScreenMetrics._({
    required this.compact,
    required this.boardSide,
    required this.stageHeight,
    required this.titleRowHeight,
    required this.portraitRowHeight,
    required this.hintMaxHeight,
    required this.hintCompactHeight,
  });

  /// true = distribución compacta (pantalla baja).
  final bool compact;

  /// Lado que tendrá el tablero (el ancho menos los márgenes).
  final double boardSide;

  /// Alto del escenario: el tablero más su margen vertical.
  final double stageHeight;

  /// Alto de la fila del título (con el texto del sistema ya aplicado).
  final double titleRowHeight;

  /// Alto de la bandeja de retratos (retrato y nombre).
  final double portraitRowHeight;

  /// Tope de la pista de 3 líneas (distribución normal).
  final double hintMaxHeight;

  /// Alto de la pista de una línea (distribución compacta).
  final double hintCompactHeight;

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

  // ---- bloques que crecen con el texto del sistema ------------------------------

  /// Píxeles de reserva cuando el texto del sistema está agrandado.
  static const double textScaleSlack = 6;

  /// Fila del título: dos líneas (17 y 13 px, interlineado 1,15).
  static double titleRowFor(TextScaler s, {required bool compact}) => math.max(
    compact ? headerRow2Compact : headerRow2Normal,
    s.scale(34.5) + 1,
  );

  /// Bandeja de retratos: retrato, 2 px y el nombre (13 px, interlineado 1,15).
  static double portraitRowFor(TextScaler s) =>
      math.max(portraitRow, portraitBox + 2 + s.scale(14.95) + 1);

  /// Pista de 3 líneas (15 px, interlineado 1,2) más su recuadro.
  static double hintMaxFor(TextScaler s) =>
      math.max(hintMaxNormal, s.scale(18) * 3 + 25);

  /// Pista de una línea más su recuadro.
  static double hintCompactFor(TextScaler s) =>
      math.max(hintCompact, s.scale(18) + 22);

  /// Distribución compacta si lo que queda de alto no alcanza para la normal
  /// con la pista de 3 líneas.
  static double normalNeeded(
    double side, {
    double titleRow = headerRow2Normal,
    double portraits = portraitRow,
    double hintMax = hintMaxNormal,
  }) =>
      headerTopNormal +
      headerRow1 +
      headerGapNormal +
      titleRow +
      gapNormal +
      side +
      2 * stageMarginNormal +
      gapNormal +
      toolbarNormal +
      gapNormal +
      portraits +
      4 +
      hintMax +
      gapNormal +
      resolveNormal +
      gapNormal;

  /// Alto que piden, como mínimo, todos los bloques de abajo en la compacta.
  static double bottomCompactMinFor({
    double portraits = portraitRow,
    double hint = hintCompact,
  }) =>
      toolbarCompact + gapCompact + portraits + gapCompact + hint + gapCompact;

  factory ScreenMetrics.of(
    Size box, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final titleNormal = titleRowFor(textScaler, compact: false);
    final titleCompact = titleRowFor(textScaler, compact: true);
    final portraits = portraitRowFor(textScaler);
    final hintMax = hintMaxFor(textScaler);
    final hintCompactH = hintCompactFor(textScaler);
    // Con el texto agrandado se reservan unos píxeles para el borde de las
    // pieles y el redondeo de las líneas de texto.
    final slack = textScaler.scale(1) > 1 ? textScaleSlack : 0.0;
    // En pantallas anchas y bajas el tablero se achica para que quepa todo.
    final maxSide = box.height -
        (headerTopCompact + headerRow1 + titleCompact + headerGapCompact) -
        2 * stageMarginCompact -
        bottomCompactMinFor(portraits: portraits, hint: hintCompactH) -
        slack;
    final side = math.max(0.0, math.min(box.width - 2 * sidePad, maxSide));
    final needed = normalNeeded(
      side,
      titleRow: titleNormal,
      portraits: portraits,
      hintMax: hintMax,
    ) +
        slack;
    final compact = box.height < needed;
    final margin = compact ? stageMarginCompact : stageMarginNormal;
    // Si sobra alto en la distribución normal, el escenario lo aprovecha para
    // mostrar más mesa alrededor del tablero (hasta 24 px de más).
    final extra = compact ? 0.0 : math.min(24.0, math.max(0.0, box.height - needed));
    return ScreenMetrics._(
      compact: compact,
      boardSide: side,
      stageHeight: side + 2 * margin + extra,
      titleRowHeight: compact ? titleCompact : titleNormal,
      portraitRowHeight: portraits,
      hintMaxHeight: hintMax,
      hintCompactHeight: hintCompactH,
    );
  }

  /// Margen vertical entre el borde del escenario y el tablero.
  double get stageMargin => compact ? stageMarginCompact : stageMarginNormal;

  double get toolbarHeight => compact ? toolbarCompact : toolbarNormal;
  double get gap => compact ? gapCompact : gapNormal;
}
