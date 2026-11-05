/// Muebles vistos desde arriba, dibujados por código como listas de piezas
/// ([Part]). Medidas en casillas: la pieza canónica es horizontal (ancho
/// mayor o igual que el alto) y la piel la gira 90 grados si el mueble ocupa
/// casillas en vertical. Diseño propio de Enigmatrix; se parte de los tamaños
/// y la lógica del antiguo `furniture_painters.dart` (retirado en la ronda 4.1) con
/// otro acabado.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart' show HSLColor;

import 'art_parts.dart';

/// Un mueble listo para pintar.
class FurnitureModel {
  const FurnitureModel(this.parts, {this.shadow = 1.0});

  final List<Part> parts;

  /// Cuánta sombra proyecta (la alfombra casi nada).
  final double shadow;

  /// Siluetas que proyectan sombra.
  Iterable<Path> get silhouettes =>
      parts.where((p) => p.role == PartRole.base).map((p) => p.path);
}

/// Giro del lienzo cuando el mueble es vertical. Los sofás miran con el
/// respaldo a la izquierda; las camas, con la cabecera arriba.
bool rotatesClockwise(ObjectType t) => t != ObjectType.sofa && t != ObjectType.sillon;

/// Arma el mueble [type] para una pieza de [w] x [h] casillas (w >= h).
/// En modo oscuro los colores se atenúan un poco.
FurnitureModel buildFurniture(
    ObjectType type, double w, double h, Brightness mode) {
  final b = _Builder(mode, w, h);
  return switch (type) {
    ObjectType.mesa => b.mesa(),
    ObjectType.silla => b.silla(),
    ObjectType.sofa => b.sofa(seats: w > h * 1.5 ? 2 : 1, plum: false),
    ObjectType.sillon => b.sillon(),
    ObjectType.cama => b.cama(),
    ObjectType.alfombra => b.alfombra(),
    ObjectType.planta => b.planta(),
    ObjectType.arbusto => b.arbusto(),
    ObjectType.tv => b.tv(),
    ObjectType.armario => b.armario(),
    ObjectType.caja => b.caja(),
    ObjectType.lavadora => b.lavadora(),
    ObjectType.piano => b.piano(),
    ObjectType.barra => b.barra(),
  };
}

class _Builder {
  _Builder(this.mode, this.w, this.h);
  final Brightness mode;
  final double w, h;

  /// Atenúa un color en modo oscuro (menos luz y un poco menos de saturación).
  Color c(int argb) {
    final col = Color(argb);
    if (mode == Brightness.light) return col;
    final hsl = HSLColor.fromColor(col);
    return hsl
        .withLightness((hsl.lightness * 0.80).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.92).clamp(0.0, 1.0))
        .toColor();
  }

  Color a(Color col, double alpha) => col.withValues(alpha: alpha);

  // ---- mesa ------------------------------------------------------------------

  FurnitureModel mesa() {
    final wood = c(0xFFC48A56), woodD = c(0xFF8A5530), woodL = c(0xFFD9A06C);
    final topH = h - 0.17;
    return FurnitureModel([
      Part(rrP(0.05, h - 0.24, 0.12, 0.24, 0.03), woodD, shade: 0.3),
      Part(rrP(w - 0.17, h - 0.24, 0.12, 0.24, 0.03), woodD, shade: 0.3),
      Part(rrP(0.02, h - 0.22, w - 0.04, 0.14, 0.02), woodD, shade: 0.2),
      Part(rrP(0, 0, w, topH, 0.07), wood, role: PartRole.base, shade: 0.7),
      for (var i = 1; i <= 2; i++)
        Part(lineP(0.07, topH * i / 3, w - 0.07, topH * i / 3), a(woodD, 0.5),
            role: PartRole.line, width: 0.014),
      Part(lineP(w * 0.34, 0.03, w * 0.34, topH / 3 - 0.02), a(woodD, 0.4),
          role: PartRole.line, width: 0.012),
      Part(lineP(w * 0.7, topH / 3 + 0.02, w * 0.7, topH * 2 / 3 - 0.02),
          a(woodD, 0.4),
          role: PartRole.line, width: 0.012),
      Part(ovalP(w * 0.22, topH * 0.5, 0.035, 0.022), a(woodD, 0.5),
          role: PartRole.detail),
      Part(lineP(0.1, 0.045, w - 0.1, 0.045), a(woodL, 0.8),
          role: PartRole.line, width: 0.018),
    ]);
  }

  // ---- silla -----------------------------------------------------------------
  // Vista desde arriba: el respaldo es una media luna de madera oscura (lo que
  // más delata una silla), el asiento es un cuadrado de madera clara con un
  // cojín mostaza al centro y las cuatro patas asoman en las esquinas. Es
  // chica y deja ver el piso alrededor, así no se confunde con el sillón
  // (morado, grande, con brazos) ni con el sofá (verde azulado, largo).

  FurnitureModel silla() {
    final wood = c(0xFFD2A266), woodD = c(0xFF6B3F22), woodM = c(0xFF8F5A33);
    final cushion = c(0xFFEBDDBD), cushionD = c(0xFFB59A6A);
    final s = math.min(w, h);
    return FurnitureModel([
      // Patas delanteras (asoman bajo el asiento).
      Part(rrP(0.02, s - 0.14, 0.11, 0.14, 0.03), woodD, shade: 0.2),
      Part(rrP(s - 0.13, s - 0.14, 0.11, 0.14, 0.03), woodD, shade: 0.2),
      // Asiento de madera.
      Part(rrP(0.04, 0.17, s - 0.08, s - 0.25, 0.1), wood, role: PartRole.base, shade: 0.6),
      // Cojín con ribete y botón.
      Part(rrP(0.12, 0.27, s - 0.24, s - 0.45, 0.09), cushion, shade: 0.7),
      Part(rrP(0.16, 0.31, s - 0.32, s - 0.53, 0.07), cushionD.withValues(alpha: 0.6),
          role: PartRole.line, width: 0.014),
      Part(circleP(s / 2, 0.27 + (s - 0.45) / 2, 0.024), cushionD, role: PartRole.detail),
      // Montantes del respaldo (suben por los lados del asiento).
      Part(rrP(0.0, 0.0, 0.1, 0.36, 0.045), woodD, shade: 0.3),
      Part(rrP(s - 0.1, 0.0, 0.1, 0.36, 0.045), woodD, shade: 0.3),
      // Travesaño del respaldo, más ancho que el asiento.
      Part(rrP(0.0, 0.0, s, 0.2, 0.09), woodD, role: PartRole.base, shade: 0.5),
      Part(rrP(0.12, 0.045, s - 0.24, 0.1, 0.04), woodM, shade: 0.6),
      Part(lineP(0.15, 0.05, s - 0.15, 0.05), a(const Color(0xFFFFFFFF), 0.28),
          role: PartRole.line, width: 0.014),
    ]);
  }

  // ---- sofá y sillón ---------------------------------------------------------

  FurnitureModel sofa({required int seats, required bool plum}) {
    final base = plum ? c(0xFF9A4B7B) : c(0xFF2F7F8C);
    final deep = shadeColor(base, 0.28);
    final soft = lightenColor(base, 0.16);
    final armW = seats > 1 ? 0.2 : 0.18;
    final bodyH = h - 0.04;
    final inner = w - 2 * armW;
    final cw = (inner - (seats - 1) * 0.025) / seats;
    final cy = 0.27, ch = bodyH - cy - 0.05;
    return FurnitureModel([
      Part(rrP(0.08, h - 0.08, 0.1, 0.08, 0.02), c(0xFF4A2F1E), shade: 0),
      Part(rrP(w - 0.18, h - 0.08, 0.1, 0.08, 0.02), c(0xFF4A2F1E), shade: 0),
      Part(rrP(0, 0, w, bodyH, 0.17), deep, role: PartRole.base, shade: 0.7),
      Part(rrP(0.035, 0.025, w - 0.07, 0.3, 0.12), base, shade: 0.8),
      // Botones del respaldo.
      for (var i = 0; i < seats * 2; i++)
        Part(circleP(armW + inner * (i + 0.5) / (seats * 2), 0.16, 0.035), shadeColor(base, 0.3),
            role: PartRole.detail),
      for (var i = 0; i < seats; i++)
        Part(rrP(armW + i * (cw + 0.025), cy, cw, ch, 0.09), soft, shade: 0.8),
      for (var i = 0; i < seats; i++)
        Part(lineP(armW + i * (cw + 0.025) + 0.08, cy + 0.06,
                armW + i * (cw + 0.025) + cw - 0.08, cy + 0.06),
            a(const Color(0xFFFFFFFF), 0.3),
            role: PartRole.line, width: 0.016),
      Part(rrP(0, 0.1, armW, bodyH - 0.12, 0.1), base, shade: 0.8),
      Part(rrP(w - armW, 0.1, armW, bodyH - 0.12, 0.1), base, shade: 0.8),
    ]);
  }

  // ---- sillón ----------------------------------------------------------------
  // Butaca morada, redonda y gorda: respaldo alto, brazos abultados, cojín
  // grande y un cojincito mostaza en diagonal. No se parece a la silla (de
  // madera, con patas) ni al sofá (largo, verde azulado).

  FurnitureModel sillon() {
    final base = c(0xFF9A4B7B);
    final deep = shadeColor(base, 0.3);
    final soft = lightenColor(base, 0.2);
    final mustard = c(0xFFE0A93C);
    final bodyH = h - 0.04;
    final cx = w / 2;
    return FurnitureModel([
      Part(rrP(0.1, h - 0.08, 0.1, 0.08, 0.02), c(0xFF4A2F1E), shade: 0),
      Part(rrP(w - 0.2, h - 0.08, 0.1, 0.08, 0.02), c(0xFF4A2F1E), shade: 0),
      Part(rrP(0, 0, w, bodyH, 0.26), deep, role: PartRole.base, shade: 0.7),
      // Respaldo alto con botones.
      Part(rrP(0.05, 0.03, w - 0.1, 0.34, 0.16), base, shade: 0.8),
      for (var i = 0; i < 3; i++)
        Part(circleP(0.2 + (w - 0.4) * i / 2, 0.19, 0.03), deep, role: PartRole.detail),
      // Cojín del asiento.
      Part(rrP(0.2, 0.34, w - 0.4, bodyH - 0.42, 0.12), soft, shade: 0.8),
      // Brazos abultados.
      Part(rrP(0, 0.14, 0.24, bodyH - 0.16, 0.12), base, shade: 0.8),
      Part(rrP(w - 0.24, 0.14, 0.24, bodyH - 0.16, 0.12), base, shade: 0.8),
      // Cojincito en diagonal.
      Part(
          polyP([
            Offset(cx + 0.02, 0.4),
            Offset(cx + 0.17, 0.46),
            Offset(cx + 0.11, 0.6),
            Offset(cx - 0.04, 0.54),
          ]),
          mustard,
          shade: 0.6),
    ]);
  }

  // ---- cama ------------------------------------------------------------------

  FurnitureModel cama() {
    final frame = c(0xFF9A6338), frameD = c(0xFF6C4122);
    final sheet = c(0xFFF1E9DA), blanket = c(0xFF4F8E87), fold = c(0xFF72AFA6);
    final pillowH = (h - 0.3) / 2;
    return FurnitureModel([
      Part(rrP(0, 0, w, h, 0.1), frame, role: PartRole.base, shade: 0.5),
      Part(rrP(0, 0, 0.13, h, 0.06), frameD, shade: 0.3),
      Part(rrP(0.11, 0.06, w - 0.17, h - 0.12, 0.08), sheet, shade: 0.4),
      Part(rrP(w * 0.38, 0.06, w * 0.62 - 0.06, h - 0.12, 0.07), blanket, shade: 0.7),
      Part(rrP(w * 0.38, 0.06, 0.15, h - 0.12, 0.05), fold, shade: 0.3),
      for (var i = 1; i <= 2; i++)
        Part(lineP(w * 0.38 + 0.15 + (w * 0.62 - 0.27) * i / 3, 0.12,
                w * 0.38 + 0.15 + (w * 0.62 - 0.27) * i / 3, h - 0.12),
            a(shadeColor(blanket, 0.35), 0.6),
            role: PartRole.line, width: 0.014),
      Part(rrP(0.18, 0.1, w * 0.19, pillowH, 0.08), const Color(0xFFFFFFFF), shade: 0.5),
      Part(rrP(0.18, h - 0.1 - pillowH, w * 0.19, pillowH, 0.08), const Color(0xFFFFFFFF),
          shade: 0.5),
    ]);
  }

  // ---- alfombra --------------------------------------------------------------

  FurnitureModel alfombra() {
    final rug = c(0xFFA9503F), field = c(0xFF8A3B31), cream = c(0xFFE9D4A4);
    final cx = w / 2, cy = h / 2;
    final m = math.min(w, h);
    return FurnitureModel([
      Part(rrP(0, 0, w, h, 0.05), rug, role: PartRole.base, shade: 0.0),
      Part(rrP(0.07, 0.07, w - 0.14, h - 0.14, 0.03), a(cream, 0.9),
          role: PartRole.line, width: 0.03),
      Part(rrP(0.12, 0.12, w - 0.24, h - 0.24, 0.02), field, role: PartRole.detail),
      Part(
          polyP([
            Offset(cx, cy - m * 0.3),
            Offset(cx + m * 0.3, cy),
            Offset(cx, cy + m * 0.3),
            Offset(cx - m * 0.3, cy),
          ]),
          cream,
          role: PartRole.detail),
      Part(
          polyP([
            Offset(cx, cy - m * 0.16),
            Offset(cx + m * 0.16, cy),
            Offset(cx, cy + m * 0.16),
            Offset(cx - m * 0.16, cy),
          ]),
          rug,
          role: PartRole.detail),
      // Flecos en los extremos cortos.
      for (var y = 0.1; y < h - 0.05; y += 0.1) ...[
        Part(lineP(0, y, -0.05, y), a(cream, 0.9), role: PartRole.line, width: 0.016),
        Part(lineP(w, y, w + 0.05, y), a(cream, 0.9), role: PartRole.line, width: 0.016),
      ],
    ], shadow: 0.12);
  }

  // ---- plantas ---------------------------------------------------------------

  FurnitureModel planta() {
    final R = math.min(w, h) / 2;
    final cx = w / 2, cy = h / 2;
    final g1 = c(0xFF3E8F55), g2 = c(0xFF5BAE68), g3 = c(0xFF7CC37E);
    final parts = <Part>[
      Part(circleP(cx, cy, R * 0.8), c(0xFFBF6540), role: PartRole.base, shade: 0.6),
      Part(circleP(cx, cy, R * 0.55), c(0xFF4A3125), shade: 0),
    ];
    for (var k = 0; k < 8; k++) {
      final ang = k * math.pi / 4 + 0.2;
      parts.add(Part(leafP(cx, cy, R * 1.02, R * 0.34, ang), k.isEven ? g1 : g2));
    }
    for (var k = 0; k < 6; k++) {
      final ang = k * math.pi / 3 + 0.55;
      final leaf = leafP(cx, cy, R * 0.62, R * 0.26, ang);
      parts.add(Part(leaf, g3, shade: 0.4));
    }
    parts.add(Part(circleP(cx, cy, R * 0.1), c(0xFFF3D36B), role: PartRole.detail));
    return FurnitureModel(parts);
  }

  FurnitureModel arbusto() {
    final R = math.min(w, h) / 2;
    final cx = w / 2, cy = h / 2;
    final dark = c(0xFF2C7344), mid = c(0xFF3F9556), lite = c(0xFF63B86F);
    final blobs = <(double, double, double, Color)>[
      (-0.52, 0.08, 0.5, dark),
      (0.52, 0.08, 0.5, dark),
      (0.0, -0.46, 0.5, dark),
      (-0.28, 0.4, 0.46, mid),
      (0.3, 0.38, 0.46, mid),
      (0.0, -0.02, 0.56, lite),
    ];
    // La silueta es la unión de todos los bultos (un solo contorno y un solo
    // borde de recorte); cada bulto va encima como pieza interior.
    var union = Path();
    for (final (dx, dy, r, _) in blobs) {
      union = Path.combine(
          PathOperation.union, union, circleP(cx + dx * R, cy + dy * R, r * R));
    }
    return FurnitureModel([
      Part(union, dark, role: PartRole.base, shade: 0.5),
      for (final (dx, dy, r, col) in blobs)
        Part(circleP(cx + dx * R, cy + dy * R, r * R), col, shade: 0.6),
      for (final (dx, dy) in const [
        (-0.3, -0.2), (0.25, -0.12), (0.05, 0.25), (-0.12, 0.05), (0.38, 0.3)
      ])
        Part(circleP(cx + dx * R, cy + dy * R, R * 0.09), c(0xFFD9475C), role: PartRole.detail),
    ]);
  }

  // ---- TV --------------------------------------------------------------------

  FurnitureModel tv() {
    final frame = c(0xFF24262B), stand = c(0xFF8B5B38);
    final scr = c(0xFF3F7F98), scrD = c(0xFF1E3C4C);
    final bodyH = h - 0.14;
    return FurnitureModel([
      Part(rrP(w * 0.28, h - 0.18, w * 0.44, 0.18, 0.04), stand, shade: 0.4),
      Part(rrP(0, 0, w, bodyH, 0.06), frame, role: PartRole.base, shade: 0.5),
      Part(rrP(0.05, 0.05, w - 0.1, bodyH - 0.1, 0.03), scrD, shade: 0),
      Part(rrP(0.05, 0.05, w - 0.1, (bodyH - 0.1) * 0.62, 0.03), scr, role: PartRole.detail),
      Part(
          polyP([
            Offset(0.08, bodyH - 0.07),
            Offset(w * 0.4, 0.07),
            Offset(w * 0.55, 0.07),
            Offset(w * 0.23, bodyH - 0.07),
          ]),
          a(const Color(0xFFFFFFFF), 0.16),
          role: PartRole.detail),
      Part(circleP(w / 2, bodyH - 0.026, 0.014), const Color(0xFFE05A47),
          role: PartRole.detail),
    ]);
  }

  // ---- armario ---------------------------------------------------------------

  FurnitureModel armario() {
    final body = c(0xFF7B4F30), door = c(0xFF946038), crown = c(0xFFA87245);
    final twoDoors = w > h * 1.5;
    final doors = twoDoors ? 4 : 2;
    final dw = (w - 0.1 - (doors - 1) * 0.02) / doors;
    return FurnitureModel([
      Part(rrP(0.05, h - 0.06, 0.1, 0.06, 0.02), c(0xFF3F2616), shade: 0),
      Part(rrP(w - 0.15, h - 0.06, 0.1, 0.06, 0.02), c(0xFF3F2616), shade: 0),
      Part(rrP(0, 0, w, h - 0.03, 0.05), body, role: PartRole.base, shade: 0.6),
      Part(rrP(0, 0, w, 0.15, 0.04), crown, shade: 0.5),
      for (var i = 0; i < doors; i++)
        Part(rrP(0.05 + i * (dw + 0.02), 0.19, dw, h - 0.27, 0.03), door, shade: 0.6),
      for (var i = 0; i < doors; i++)
        Part(rrP(0.05 + i * (dw + 0.02) + dw * 0.14, 0.19 + (h - 0.27) * 0.13, dw * 0.72,
                (h - 0.27) * 0.74, 0.02),
            a(shadeColor(door, 0.3), 0.6),
            role: PartRole.line, width: 0.014),
      for (var i = 0; i < doors; i += 2) ...[
        Part(circleP(0.05 + i * (dw + 0.02) + dw - 0.035, h * 0.55, 0.028),
            c(0xFFEBD28E), role: PartRole.detail),
        Part(circleP(0.05 + (i + 1) * (dw + 0.02) + 0.035, h * 0.55, 0.028),
            c(0xFFEBD28E), role: PartRole.detail),
      ],
    ]);
  }

  // ---- caja ------------------------------------------------------------------

  FurnitureModel caja() {
    final kraft = c(0xFFC79A63), kraftD = c(0xFFA77B47), tape = c(0xFFE9D7A8);
    final s = math.min(w, h);
    return FurnitureModel([
      Part(rrP(0, 0, s, s, 0.05), kraft, role: PartRole.base, shade: 0.6),
      Part(rrP(0.03, 0.03, s / 2 - 0.03, s - 0.06, 0.03), lightenColor(kraft, 0.08), shade: 0.5),
      Part(rrP(s / 2, 0.03, s / 2 - 0.03, s - 0.06, 0.03), kraftD, shade: 0.5),
      Part(rrP(s / 2 - 0.07, 0, 0.14, s, 0.01), tape, shade: 0.2),
      // Etiqueta con flecha.
      Part(rrP(s * 0.12, s * 0.58, s * 0.26, s * 0.24, 0.02), const Color(0xFFF7F3EA),
          role: PartRole.detail),
      Part(polyP([
        Offset(s * 0.25, s * 0.2),
        Offset(s * 0.34, s * 0.34),
        Offset(s * 0.16, s * 0.34),
      ]), shadeColor(kraft, 0.5), role: PartRole.detail),
      Part(lineP(s * 0.16, s * 0.65, s * 0.34, s * 0.65), a(const Color(0xFF000000), 0.4),
          role: PartRole.line, width: 0.012),
      Part(lineP(s * 0.16, s * 0.72, s * 0.3, s * 0.72), a(const Color(0xFF000000), 0.4),
          role: PartRole.line, width: 0.012),
    ]);
  }

  // ---- lavadora --------------------------------------------------------------

  FurnitureModel lavadora() {
    final body = c(0xFFE8ECEF), panel = c(0xFFCBD2D8);
    final s = math.min(w, h);
    final dc = Offset(s / 2, 0.2 + (s - 0.2) / 2);
    final dr = (s - 0.2) * 0.4;
    return FurnitureModel([
      Part(rrP(0, 0, s, s, 0.07), body, role: PartRole.base, shade: 0.5),
      Part(rrP(0.03, 0.03, s - 0.06, 0.15, 0.04), panel, shade: 0.3),
      Part(circleP(0.14, 0.105, 0.04), c(0xFF6E7C88), role: PartRole.detail),
      Part(rrP(s * 0.45, 0.075, s * 0.3, 0.06, 0.02), c(0xFF3F5B70), role: PartRole.detail),
      Part(circleP(s - 0.12, 0.105, 0.022), c(0xFFE05A47), role: PartRole.detail),
      Part(circleP(dc.dx, dc.dy, dr), c(0xFF9DAAB6), shade: 0.5),
      Part(circleP(dc.dx, dc.dy, dr * 0.74), c(0xFF3F6075), shade: 0.6),
      Part(ovalP(dc.dx - dr * 0.25, dc.dy - dr * 0.3, dr * 0.22, dr * 0.12),
          a(const Color(0xFFFFFFFF), 0.4), role: PartRole.detail),
    ]);
  }

  // ---- piano -----------------------------------------------------------------

  FurnitureModel piano() {
    final black = c(0xFF26231F);
    final keysY = h - 0.27, keysH = 0.2;
    final keysX = 0.08, keysW = w - 0.16;
    final nWhite = math.max(7, (keysW / 0.1).round());
    final kw = keysW / nWhite;
    return FurnitureModel([
      Part(rrP(0, 0, w, h, 0.07), black, role: PartRole.base, shade: 0.5),
      Part(rrP(0.07, 0.07, w - 0.14, keysY - 0.1, 0.04), lightenColor(black, 0.1), shade: 0.4),
      Part(rrP(0.12, 0.1, w - 0.24, 0.07, 0.03), a(const Color(0xFFFFFFFF), 0.22),
          role: PartRole.detail),
      Part(rrP(keysX, keysY, keysW, keysH, 0.015), const Color(0xFFF3EFE6), shade: 0.2),
      for (var i = 1; i < nWhite; i++)
        Part(lineP(keysX + kw * i, keysY, keysX + kw * i, keysY + keysH),
            a(const Color(0xFF000000), 0.35),
            role: PartRole.line, width: 0.008),
      for (var i = 0; i < nWhite - 1; i++)
        if (i % 7 != 2 && i % 7 != 6)
          Part(rrP(keysX + kw * (i + 1) - kw * 0.28, keysY, kw * 0.56, keysH * 0.6, 0.008),
              const Color(0xFF15130F),
              role: PartRole.detail),
    ]);
  }

  // ---- barra -----------------------------------------------------------------

  FurnitureModel barra() {
    final top = c(0xFF8C5B3B), lip = c(0xFF5E3B25), rim = c(0xFFB57E55);
    final long = w > 1.2;
    return FurnitureModel([
      Part(rrP(0, h - 0.24, w, 0.24, 0.05), lip, shade: 0.4),
      Part(rrP(0, 0, w, h - 0.12, 0.08), top, role: PartRole.base, shade: 0.7),
      Part(rrP(0.05, 0.05, w - 0.1, h - 0.22, 0.05), a(rim, 0.7),
          role: PartRole.line, width: 0.02),
      // Botellas.
      for (var i = 0; i < (long ? 2 : 1); i++) ...[
        Part(circleP(0.2 + i * 0.2, (h - 0.12) * 0.36, 0.085),
            i == 0 ? c(0xFF3C8A5A) : c(0xFFC98B2C), shade: 0.6),
        Part(circleP(0.2 + i * 0.2, (h - 0.12) * 0.36, 0.03), c(0xFFE9E1CE),
            role: PartRole.detail),
      ],
      // Vasos.
      for (var i = 0; i < (long ? 3 : 1); i++) ...[
        Part(circleP((long ? w * 0.5 : w * 0.66) + i * 0.22, (h - 0.12) * 0.55, 0.07),
            a(const Color(0xFFDDEFF5), 0.9), shade: 0.4),
        Part(circleP((long ? w * 0.5 : w * 0.66) + i * 0.22, (h - 0.12) * 0.55, 0.04),
            a(const Color(0xFF9ACBDA), 0.8), role: PartRole.detail),
      ],
      Part(lineP(w * 0.12, 0.07, w * 0.88, 0.07), a(const Color(0xFFFFFFFF), 0.25),
          role: PartRole.line, width: 0.016),
    ]);
  }
}
