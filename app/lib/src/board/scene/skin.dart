/// Interfaz de "piel": todo lo que se ve del tablero (colores, texturas,
/// formas) vive detrás de esta interfaz. La escena, el director y las reglas
/// no saben cómo se dibuja nada; solo piden "pinta esta ficha" o "pinta el
/// fondo".
///
/// Hay tres pieles: "Ilustrada" (muebles con contorno oscuro, pisos por
/// habitación y retratos), "Papel" (recortes de papel tipo maqueta) y la
/// "neutra" (formas sobrias, la prueba técnica original). Cada una entrega su
/// paleta clara y oscura. Para sumar otra se escribe una clase que implemente
/// esta interfaz y se agrega a [SkinRegistry]; no hay que tocar la escena.
library;

import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

import 'board_geometry.dart';
import 'palette.dart';

/// Datos para dibujar una ficha o una nota.
class TokenStyle {
  /// Posición del personaje en el caso (decide el color).
  final int charIndex;

  /// Letra que lleva (inicial del nombre).
  final String initial;

  /// La víctima se dibuja distinta (forma y ojos), no solo otro color.
  final bool victim;

  /// 1 = ojos abiertos, 0 = cerrados (parpadeo).
  final double eyeOpen;
  final double alpha;

  /// Género del personaje en el caso (decide el peinado del retrato).
  final bool female;

  const TokenStyle({
    required this.charIndex,
    required this.initial,
    this.victim = false,
    this.eyeOpen = 1,
    this.alpha = 1,
    this.female = false,
  });
}

abstract class BoardSkin {
  String get id;
  String get displayName;

  /// Modo (claro u oscuro) con el que se construyó esta piel.
  Brightness get mode;

  /// Colores de la interfaz y del tablero en este modo.
  SkinPalette get palette;

  /// Cómo se dibujan los botones y paneles de Flutter con esta piel.
  ChromeKind get chrome;

  /// Cuánto se agranda la ficha respecto de la base (1 = tamaño original).
  double get tokenScale => 1.0;

  // ---- paleta (tokens de color de la piel) -----------------------------------

  /// Fondo detrás del tablero.
  Color get backdrop;

  /// Color de los trazos de tinta (X, textos).
  Color get ink;

  /// Luz cálida de la viñeta y de los destellos.
  Color get light;

  /// Tinte del error.
  Color get errorTint;

  /// Color del personaje [index].
  Color characterColor(int index);

  /// Colores del confeti.
  List<Color> get confettiColors;

  // ---- capa fija --------------------------------------------------------------

  /// Piso, paredes con sombra, muebles y nombres de habitación. Se dibuja una
  /// sola vez y la escena guarda el resultado como imagen.
  void paintBackdrop(Canvas canvas, Size size, BoardGeometry g, GameMap map);

  // ---- capa interactiva -------------------------------------------------------

  /// Ficha confirmada. El origen es el centro de la casilla; la escena ya
  /// aplicó respiración, aplastamiento y estiramiento con el canvas.
  void paintToken(Canvas canvas, Offset center, double radius, TokenStyle s);

  /// Sombra proyectada de la ficha. [lift] > 0 la separa y aclara (ficha en
  /// el aire durante la caída o el salto).
  void paintTokenShadow(Canvas canvas, Offset center, double radius,
      {double lift = 0, double alpha = 1});

  /// Nota (candidato) con su letra.
  void paintCandidate(Canvas canvas, Offset center, double size, TokenStyle s,
      double alpha);

  /// X de descarte, dibujada con trazo animado ([progress] de 0 a 1).
  void paintCross(Canvas canvas, Rect cell, double progress,
      {bool automatic = true, double alpha = 1});

  /// Resplandor leve sobre una casilla (candidatas, destello, fundido).
  void paintCellGlow(Canvas canvas, Rect cell, double strength);

  /// Anillo de progreso del mantener oprimido.
  void paintHoldRing(Canvas canvas, Offset center, double radius,
      double progress, double alpha);

  /// Estrella de la revelación.
  void paintStar(Canvas canvas, Offset center, double radius, double alpha);

  // ---- bandeja ----------------------------------------------------------------

  /// Retrato dentro de [frame] (el marco redondeado de la bandeja). El
  /// seleccionado lleva un borde de acento.
  void paintPortrait(Canvas canvas, Rect frame, TokenStyle s,
      {bool selected = false});
}
