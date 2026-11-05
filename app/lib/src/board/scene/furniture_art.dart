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
    ObjectType.perchero => b.perchero(),
    ObjectType.banera => b.banera(),
    ObjectType.nevera => b.nevera(),
    ObjectType.chimenea => b.chimenea(),
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
  // Vista desde arriba: es una silla de comedor, toda de madera. Respaldo
  // recto con tres listones verticales, asiento de tablas (sin cojín) y las
  // patas asomando por delante. Es chica y deja ver el piso alrededor, así no
  // se confunde con el sillón (morado, tapizado, con brazos) ni con el sofá
  // (verde azulado, largo, de dos plazas).

  FurnitureModel silla() {
    final wood = c(0xFFD2A266), woodD = c(0xFF6B3F22), woodM = c(0xFF8F5A33);
    final s = math.min(w, h);
    return FurnitureModel([
      // Patas delanteras (asoman bajo el asiento).
      Part(rrP(0.02, s - 0.14, 0.11, 0.14, 0.03), woodD, shade: 0.2),
      Part(rrP(s - 0.13, s - 0.14, 0.11, 0.14, 0.03), woodD, shade: 0.2),
      // Asiento de tablas, sin cojín.
      Part(rrP(0.04, 0.17, s - 0.08, s - 0.25, 0.05), wood, role: PartRole.base, shade: 0.6),
      Part(lineP(s * 0.36, 0.3, s * 0.36, s - 0.14), a(woodD, 0.5),
          role: PartRole.line, width: 0.016),
      Part(lineP(s * 0.64, 0.3, s * 0.64, s - 0.14), a(woodD, 0.5),
          role: PartRole.line, width: 0.016),
      Part(lineP(0.1, s - 0.12, s - 0.1, s - 0.12), a(woodD, 0.55),
          role: PartRole.line, width: 0.018),
      // Montantes del respaldo (suben por los lados del asiento).
      Part(rrP(0.0, 0.0, 0.1, 0.36, 0.03), woodD, shade: 0.3),
      Part(rrP(s - 0.1, 0.0, 0.1, 0.36, 0.03), woodD, shade: 0.3),
      // Respaldo recto: travesaño con tres listones verticales.
      Part(rrP(0.0, 0.0, s, 0.22, 0.04), woodD, role: PartRole.base, shade: 0.5),
      for (var i = 0; i < 3; i++)
        Part(rrP(0.14 + i * (s - 0.28 - 0.1) / 2, 0.035, 0.1, 0.15, 0.015), woodM, shade: 0.6),
      Part(lineP(0.14, 0.03, s - 0.14, 0.03), a(const Color(0xFFFFFFFF), 0.28),
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
  // Tapete tejido: campo rojo con medallón, guarda de triángulos y flecos en
  // los extremos cortos. Es plano, sin marco ni almohadas, para que nadie lo
  // lea como una cama.

  FurnitureModel alfombra() {
    final rug = c(0xFFA9503F), field = c(0xFF8A3B31), cream = c(0xFFE9D4A4);
    final teal = c(0xFF3F7F86);
    final cx = w / 2, cy = h / 2;
    final m = math.min(w, h);
    return FurnitureModel([
      Part(rrP(0, 0, w, h, 0.05), rug, role: PartRole.base, shade: 0.0),
      Part(rrP(0.07, 0.07, w - 0.14, h - 0.14, 0.03), a(cream, 0.9),
          role: PartRole.line, width: 0.03),
      Part(rrP(0.12, 0.12, w - 0.24, h - 0.24, 0.02), field, role: PartRole.detail),
      // Guarda de triángulos a lo largo de los dos bordes largos.
      for (var x = 0.2; x < w - 0.2; x += 0.15) ...[
        Part(polyP([Offset(x, 0.14), Offset(x + 0.1, 0.14), Offset(x + 0.05, 0.24)]),
            a(cream, 0.85),
            role: PartRole.detail),
        Part(polyP([Offset(x, h - 0.14), Offset(x + 0.1, h - 0.14), Offset(x + 0.05, h - 0.24)]),
            a(cream, 0.85),
            role: PartRole.detail),
      ],
      // Medallón central.
      Part(
          polyP([
            Offset(cx, cy - m * 0.26),
            Offset(cx + m * 0.26, cy),
            Offset(cx, cy + m * 0.26),
            Offset(cx - m * 0.26, cy),
          ]),
          cream,
          role: PartRole.detail),
      Part(
          polyP([
            Offset(cx, cy - m * 0.17),
            Offset(cx + m * 0.17, cy),
            Offset(cx, cy + m * 0.17),
            Offset(cx - m * 0.17, cy),
          ]),
          teal,
          role: PartRole.detail),
      Part(circleP(cx, cy, m * 0.06), cream, role: PartRole.detail),
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
  // Mostrador: tapa de piedra gris azulada (nada de colores de cama ni de
  // madera clara como la mesa), frente de madera con riel de latón, fregadero
  // de acero en las barras largas y botellas y vasos encima.

  FurnitureModel barra() {
    final top = c(0xFF4A5662), topL = c(0xFF73818E), lip = c(0xFF6B4528);
    final brass = c(0xFFD9B25A), steel = c(0xFFBCC8D1), steelD = c(0xFF7F8E99);
    final long = w > 1.2;
    final th = h - 0.12; // alto de la tapa
    final bx = long ? 0.62 : 0.22; // dónde empiezan las botellas
    final gx = long ? 1.1 : 0.56; // dónde empiezan los vasos
    return FurnitureModel([
      Part(rrP(0, h - 0.24, w, 0.24, 0.05), lip, shade: 0.4),
      Part(lineP(0.08, h - 0.07, w - 0.08, h - 0.07), brass, role: PartRole.line, width: 0.026),
      Part(rrP(0, 0, w, th, 0.08), top, role: PartRole.base, shade: 0.7),
      Part(rrP(0.05, 0.05, w - 0.1, th - 0.1, 0.05), a(topL, 0.7),
          role: PartRole.line, width: 0.018),
      // Fregadero de acero con su grifo (solo en las barras largas).
      if (long) ...[
        Part(rrP(0.12, 0.1, 0.34, th - 0.2, 0.05), steel, shade: 0.6),
        Part(rrP(0.17, 0.15, 0.24, th - 0.3, 0.04), steelD, shade: 0.5),
        Part(circleP(0.29, th * 0.5, 0.022), steel, role: PartRole.detail),
        Part(rrP(0.26, 0.06, 0.06, 0.05, 0.02), brass, role: PartRole.detail),
      ],
      // Botellas.
      for (var i = 0; i < (long ? 2 : 1); i++) ...[
        Part(circleP(bx + i * 0.2, th * 0.4, 0.085), i == 0 ? c(0xFF3C8A5A) : c(0xFFC98B2C),
            shade: 0.6),
        Part(circleP(bx + i * 0.2, th * 0.4, 0.03), c(0xFFE9E1CE), role: PartRole.detail),
      ],
      // Vasos.
      for (var i = 0; i < (long ? 3 : 1); i++) ...[
        Part(circleP(gx + i * 0.22, th * 0.62, 0.07), a(const Color(0xFFDDEFF5), 0.9), shade: 0.4),
        Part(circleP(gx + i * 0.22, th * 0.62, 0.04), a(const Color(0xFF9ACBDA), 0.8),
            role: PartRole.detail),
      ],
      Part(lineP(w * 0.12, 0.07, w * 0.88, 0.07), a(const Color(0xFFFFFFFF), 0.18),
          role: PartRole.line, width: 0.016),
    ]);
  }

  // ---- perchero --------------------------------------------------------------
  // Dibujado de frente (como el armario y la tele): poste de madera con base
  // redonda, perilla de latón y dos pares de ganchos. De los ganchos cuelgan
  // un sombrero (arriba a la derecha), un abrigo rojo (abajo a la izquierda)
  // y una bufanda a rayas (abajo a la derecha).

  FurnitureModel perchero() {
    final wood = c(0xFF8A5A36), woodD = c(0xFF5A3720), woodL = c(0xFFB27C4E);
    final brass = c(0xFFE0B04A);
    final coat = c(0xFFC0473B), scarf = c(0xFF3F8F9C), scarfS = c(0xFFF0E2B8);
    final hat = c(0xFF3A3F4A), band = c(0xFFE0A93C);
    final s = math.min(w, h);
    final cx = s / 2;
    // Ganchos: de cada altura salen dos brazos curvos hacia arriba.
    final hookTips = <Offset>[
      Offset(cx - 0.19, 0.15), Offset(cx + 0.19, 0.15),
      Offset(cx - 0.21, 0.3), Offset(cx + 0.21, 0.3),
    ];
    final coatPath = Path()
      ..moveTo(cx - 0.3, 0.33)
      ..quadraticBezierTo(cx - 0.2, 0.29, cx - 0.1, 0.33)
      ..lineTo(cx - 0.04, 0.36)
      ..lineTo(cx - 0.02, 0.66)
      ..lineTo(cx - 0.4, 0.66)
      ..lineTo(cx - 0.38, 0.4)
      ..close();
    return FurnitureModel([
      // Base redonda y poste (la silueta que proyecta sombra).
      Part(ovalP(cx, 0.69, 0.31, 0.085), wood, role: PartRole.base, shade: 0.6),
      Part(rrP(cx - 0.045, 0.07, 0.09, 0.62, 0.03), wood, role: PartRole.base, shade: 0.7),
      Part(lineP(cx - 0.016, 0.12, cx - 0.016, 0.65), a(woodL, 0.8),
          role: PartRole.line, width: 0.02),
      // Ganchos.
      for (final y in [0.22, 0.37]) ...[
        Part(lineP(cx, y, cx - (y == 0.22 ? 0.19 : 0.21), y - 0.07), woodD,
            role: PartRole.line, width: 0.06),
        Part(lineP(cx, y, cx + (y == 0.22 ? 0.19 : 0.21), y - 0.07), woodD,
            role: PartRole.line, width: 0.06),
      ],
      for (final o in hookTips) Part(circleP(o.dx, o.dy, 0.05), brass, shade: 0.5),
      // Abrigo rojo: cuerpo con solapa y botones, y una manga.
      Part(coatPath, coat, shade: 0.7),
      Part(rrP(cx - 0.42, 0.37, 0.08, 0.25, 0.04), shadeColor(coat, 0.18), shade: 0.4),
      Part(lineP(cx - 0.21, 0.33, cx - 0.21, 0.66), a(shadeColor(coat, 0.5), 0.8),
          role: PartRole.line, width: 0.016),
      Part(circleP(cx - 0.17, 0.45, 0.016), brass, role: PartRole.detail),
      Part(circleP(cx - 0.17, 0.53, 0.016), brass, role: PartRole.detail),
      // Bufanda a rayas.
      Part(rrP(cx + 0.14, 0.31, 0.11, 0.3, 0.045), scarf, shade: 0.6),
      for (var i = 0; i < 3; i++)
        Part(lineP(cx + 0.14, 0.4 + i * 0.09, cx + 0.25, 0.4 + i * 0.09), scarfS,
            role: PartRole.line, width: 0.026),
      // Sombrero: ala ancha, copa y cinta.
      Part(rrP(cx + 0.03, 0.11, 0.34, 0.06, 0.03), hat, shade: 0.5),
      Part(rrP(cx + 0.1, 0.0, 0.2, 0.14, 0.07), lightenColor(hat, 0.1), shade: 0.6),
      Part(lineP(cx + 0.1, 0.11, cx + 0.3, 0.11), band, role: PartRole.line, width: 0.034),
      // Perilla del poste.
      Part(circleP(cx, 0.075, 0.055), brass, shade: 0.5),
    ]);
  }

  // ---- bañera ----------------------------------------------------------------
  // Tina alargada de porcelana blanca vista desde arriba: borde ancho, cubeta
  // con el agua celeste, burbujas, un patito, el desagüe y, en el extremo
  // izquierdo, el grifo cromado con sus llaves roja y azul.

  FurnitureModel banera() {
    final porcelain = c(0xFFF3F5F6), rim = c(0xFFD6DEE3);
    final water = c(0xFF86CBE0), waterD = c(0xFF4F9CB8);
    final chrome = c(0xFFB5C3CC);
    final s = math.min(w, h);
    const top = 0.09;
    final bh = s - 2 * top; // alto del cuerpo
    final my = s / 2;
    return FurnitureModel([
      Part(rrP(0, top, s, bh, 0.26), porcelain, role: PartRole.base, shade: 0.5),
      Part(rrP(0.19, top + 0.07, s - 0.26, bh - 0.14, 0.18), rim, shade: 0.4),
      Part(rrP(0.22, top + 0.1, s - 0.32, bh - 0.2, 0.15), water, shade: 0.6),
      Part(rrP(0.22, top + 0.1, s - 0.32, bh - 0.2, 0.15), a(waterD, 0.8),
          role: PartRole.line, width: 0.018),
      // Brillos del agua.
      Part(lineP(0.3, top + 0.2, 0.42, top + 0.2), a(const Color(0xFFFFFFFF), 0.6),
          role: PartRole.line, width: 0.022),
      Part(lineP(0.46, top + bh - 0.2, 0.58, top + bh - 0.2), a(const Color(0xFFFFFFFF), 0.6),
          role: PartRole.line, width: 0.022),
      // Burbujas.
      Part(circleP(0.32, my + 0.06, 0.05), a(const Color(0xFFFFFFFF), 0.9),
          role: PartRole.detail),
      Part(circleP(0.4, my - 0.03, 0.035), a(const Color(0xFFFFFFFF), 0.9),
          role: PartRole.detail),
      Part(circleP(0.27, my - 0.07, 0.025), a(const Color(0xFFFFFFFF), 0.9),
          role: PartRole.detail),
      // Patito de hule.
      Part(circleP(0.53, my + 0.02, 0.07), c(0xFFF2C23C), shade: 0.6),
      Part(circleP(0.58, my - 0.04, 0.04), c(0xFFF2C23C), shade: 0.4),
      Part(
          polyP([
            Offset(0.615, my - 0.065),
            Offset(0.68, my - 0.04),
            Offset(0.615, my - 0.015),
          ]),
          c(0xFFE5772B),
          role: PartRole.detail),
      Part(circleP(0.585, my - 0.055, 0.01), const Color(0xFF26231F), role: PartRole.detail),
      // Desagüe.
      Part(circleP(s - 0.15, my + 0.1, 0.024), a(chrome, 0.95), role: PartRole.detail),
      // Grifo (en el extremo izquierdo) con dos llaves.
      Part(rrP(0.03, my - 0.035, 0.2, 0.07, 0.03), chrome, shade: 0.6),
      Part(circleP(0.08, my - 0.17, 0.037), c(0xFFD9475C), role: PartRole.detail),
      Part(circleP(0.08, my + 0.17, 0.037), c(0xFF3F7FC0), role: PartRole.detail),
    ]);
  }

  // ---- nevera ----------------------------------------------------------------
  // Cuerpo alto en verde menta con dos puertas apiladas (congelador arriba,
  // nevera abajo), tiradores verticales oscuros y una nota con imanes. El
  // color y las puertas apiladas la separan de la lavadora (gris claro, con
  // ventana redonda) y del armario (madera, puertas lado a lado).

  FurnitureModel nevera() {
    final body = c(0xFF86C4B6), door = c(0xFFA9DACD), top = c(0xFFC7E8DF);
    final handle = c(0xFF4A5A63);
    final s = math.min(w, h);
    final split = s * 0.4;
    return FurnitureModel([
      Part(rrP(0.08, s - 0.06, 0.1, 0.06, 0.02), c(0xFF3C4A50), shade: 0),
      Part(rrP(s - 0.18, s - 0.06, 0.1, 0.06, 0.02), c(0xFF3C4A50), shade: 0),
      Part(rrP(0, 0, s, s - 0.03, 0.09), body, role: PartRole.base, shade: 0.6),
      Part(rrP(0.03, 0.03, s - 0.06, 0.09, 0.05), top, shade: 0.5),
      // Congelador (arriba) y nevera (abajo).
      Part(rrP(0.05, 0.15, s - 0.1, split - 0.17, 0.05), door, shade: 0.6),
      Part(rrP(0.05, split + 0.02, s - 0.1, s - split - 0.1, 0.05), door, shade: 0.6),
      // Tiradores verticales.
      Part(rrP(s - 0.17, 0.19, 0.05, split - 0.25, 0.025), handle, shade: 0.4),
      Part(rrP(s - 0.17, split + 0.07, 0.05, 0.2, 0.025), handle, shade: 0.4),
      // Nota con dos imanes.
      Part(rrP(0.12, split + 0.13, 0.22, 0.2, 0.01), const Color(0xFFFBF6E8),
          role: PartRole.detail),
      Part(lineP(0.15, split + 0.22, 0.31, split + 0.22), a(const Color(0xFF000000), 0.35),
          role: PartRole.line, width: 0.012),
      Part(lineP(0.15, split + 0.28, 0.27, split + 0.28), a(const Color(0xFF000000), 0.35),
          role: PartRole.line, width: 0.012),
      Part(circleP(0.17, split + 0.15, 0.025), c(0xFFD9475C), role: PartRole.detail),
      Part(circleP(0.29, split + 0.15, 0.025), c(0xFF3F7FC0), role: PartRole.detail),
    ]);
  }

  // ---- chimenea --------------------------------------------------------------
  // Frente de piedra con repisa clara arriba, hogar oscuro de arco y un fuego
  // de tres llamas sobre dos troncos. Estática (sin animación).

  FurnitureModel chimenea() {
    final stone = c(0xFF9A9088), stoneL = c(0xFFBDB3A8), stoneD = c(0xFF6E655E);
    final dark = c(0xFF2A1D19), glow = c(0xFF5A2A18);
    final flame1 = c(0xFFE0561F), flame2 = c(0xFFF39A2B), flame3 = c(0xFFFFE27A);
    final log = c(0xFF6B4423);
    final s = math.min(w, h);
    const fx = 0.17;
    final fw = s - 2 * fx, fy = 0.22, fh = s - fy - 0.05;
    final cx = s / 2, by = fy + fh - 0.08;
    return FurnitureModel([
      Part(rrP(0, 0, s, s, 0.05), stone, role: PartRole.base, shade: 0.5),
      // Hiladas de piedra.
      for (var i = 0; i < 5; i++)
        Part(lineP(0.03, 0.27 + i * 0.12, s - 0.03, 0.27 + i * 0.12), a(stoneD, 0.55),
            role: PartRole.line, width: 0.014),
      for (var i = 0; i < 5; i++)
        for (final x in [i.isEven ? 0.09 : 0.06, s - (i.isEven ? 0.09 : 0.12)])
          Part(lineP(x, 0.27 + i * 0.12, x, 0.27 + (i + 1) * 0.12), a(stoneD, 0.55),
              role: PartRole.line, width: 0.014),
      // Repisa.
      Part(rrP(-0.02, 0, s + 0.04, 0.15, 0.04), stoneL, shade: 0.6),
      // Hogar de arco.
      Part(archP(fx, fy, fw, fh), dark, shade: 0.4),
      Part(ovalP(cx, by - 0.02, fw * 0.42, fh * 0.34), a(glow, 0.9), role: PartRole.detail),
      // Troncos cruzados.
      Part(lineP(cx - 0.16, by + 0.05, cx + 0.16, by + 0.0), log,
          role: PartRole.line, width: 0.05),
      Part(lineP(cx - 0.16, by + 0.0, cx + 0.16, by + 0.05), shadeColor(log, 0.2),
          role: PartRole.line, width: 0.05),
      // Fuego.
      Part(flameP(cx - 0.11, by + 0.03, 0.15, 0.2), flame1, shade: 0.4),
      Part(flameP(cx + 0.11, by + 0.03, 0.15, 0.18), flame1, shade: 0.4),
      Part(flameP(cx, by + 0.03, 0.22, 0.31), flame2, shade: 0.4),
      Part(flameP(cx, by + 0.03, 0.11, 0.17), flame3, role: PartRole.detail),
    ]);
  }
}

/// Barra (rectángulo girado) de largo [len] y ancho [wid], centrada en
/// ([cx], [cy]) con el ángulo [ang].
Path barP(double cx, double cy, double len, double wid, double ang) {
  final ca = math.cos(ang), sa = math.sin(ang);
  Offset t(double x, double y) => Offset(cx + x * ca - y * sa, cy + x * sa + y * ca);
  return polyP([
    t(-len / 2, -wid / 2),
    t(len / 2, -wid / 2),
    t(len / 2, wid / 2),
    t(-len / 2, wid / 2),
  ]);
}

/// Hueco de chimenea: base recta y remate de medio círculo.
Path archP(double x, double y, double w, double h) {
  final r = w / 2;
  return Path()
    ..moveTo(x, y + h)
    ..lineTo(x, y + r)
    ..arcToPoint(Offset(x + w, y + r), radius: Radius.circular(r))
    ..lineTo(x + w, y + h)
    ..close();
}

/// Llama: gota con la punta arriba. Su base centrada queda en ([cx], [by]).
Path flameP(double cx, double by, double fw, double fh) => Path()
  ..moveTo(cx, by - fh)
  ..cubicTo(cx + fw * 0.1, by - fh * 0.65, cx + fw * 0.5, by - fh * 0.55, cx + fw * 0.5,
      by - fh * 0.25)
  ..cubicTo(cx + fw * 0.5, by - fh * 0.05, cx + fw * 0.25, by, cx, by)
  ..cubicTo(cx - fw * 0.25, by, cx - fw * 0.5, by - fh * 0.05, cx - fw * 0.5, by - fh * 0.25)
  ..cubicTo(cx - fw * 0.5, by - fh * 0.55, cx - fw * 0.1, by - fh * 0.65, cx, by - fh)
  ..close();
