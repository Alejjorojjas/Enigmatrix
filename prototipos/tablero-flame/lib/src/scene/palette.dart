/// Paleta de una piel en un modo (claro u oscuro). Todos los colores de la
/// interfaz y del tablero salen de aquí, nunca de valores sueltos en los
/// widgets. Cada piel entrega dos paletas: la clara (cálida, menos blanca que
/// un blanco de pantalla) y la oscura (cálida y profunda, nunca negro puro).
library;

import 'dart:ui';

/// Cómo se dibujan los botones y paneles de la interfaz de Flutter.
enum ChromeKind {
  /// Plano con una línea fina (piel neutra).
  flat,

  /// Contorno oscuro grueso y sombra suave (piel ilustrada).
  ink,

  /// Recorte de papel: capa inferior desplazada, borde blanco y sombra
  /// (piel papel).
  paper,
}

class SkinPalette {
  const SkinPalette({
    required this.mode,
    // Interfaz.
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.text,
    required this.textDim,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.good,
    required this.toolActive,
    required this.onToolActive,
    required this.pill,
    required this.onPill,
    required this.shadow,
    required this.paperEdge,
    // Tablero.
    required this.backdrop,
    required this.backdropLow,
    required this.ink,
    required this.light,
    required this.errorTint,
    required this.wall,
    required this.labelBg,
    required this.labelText,
    required this.characters,
    required this.portraitBg,
    required this.confetti,
  });

  /// Modo al que pertenece esta paleta.
  final Brightness mode;

  // ---- interfaz ------------------------------------------------------------
  final Color bg;
  final Color surface;
  final Color surfaceAlt;

  /// Contorno de botones y tarjetas.
  final Color line;
  final Color text;
  final Color textDim;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color good;

  /// Botón de herramienta activo (relleno) y su texto.
  final Color toolActive;
  final Color onToolActive;

  /// Pastilla del cronómetro y su texto.
  final Color pill;
  final Color onPill;

  /// Color de las sombras proyectadas de la interfaz.
  final Color shadow;

  /// Borde de recorte de la piel papel.
  final Color paperEdge;

  // ---- tablero -------------------------------------------------------------
  final Color backdrop;
  final Color backdropLow;

  /// Trazo de las X y de los textos sobre el piso.
  final Color ink;

  /// Luz cálida de la viñeta y de los destellos.
  final Color light;
  final Color errorTint;

  /// Paredes entre habitaciones.
  final Color wall;
  final Color labelBg;
  final Color labelText;

  /// Color de cada personaje (insignias y notas).
  final List<Color> characters;

  /// Fondo del marco de cada retrato.
  final List<Color> portraitBg;
  final List<Color> confetti;

  bool get isDark => mode == Brightness.dark;

  /// Todos los colores con nombre, para comprobar que los dos modos existen.
  List<Color> get all => [
        bg, surface, surfaceAlt, line, text, textDim, accent, onAccent, danger,
        good, toolActive, onToolActive, pill, onPill, shadow, paperEdge,
        backdrop, backdropLow, ink, light, errorTint, wall, labelBg,
        labelText, ...characters, ...portraitBg, ...confetti,
      ];
}
