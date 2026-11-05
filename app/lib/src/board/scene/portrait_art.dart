/// Retratos provisionales dibujados por código: cara, peinado y ropa distintos
/// por personaje. Son un busto en un círculo de radio 1 (centro en el origen);
/// la piel decide si va dentro de un marco redondeado, de un medallón en el
/// tablero o de un recorte de papel. Diseño propio y a propósito sencillo: se
/// ve provisional pero agradable.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'art_parts.dart';

enum HairStyle { long, bob, bun, curly, short, side, cap, bald }

class PortraitSpec {
  const PortraitSpec({
    required this.skin,
    required this.hair,
    required this.clothes,
    required this.style,
    required this.glasses,
    required this.earrings,
    required this.tie,
  });

  final Color skin;
  final Color hair;
  final Color clothes;
  final HairStyle style;
  final bool glasses;
  final bool earrings;
  final bool tie;

  static const _skins = <int>[
    0xFFF2CBA8, 0xFFD9A57F, 0xFFB67B57, 0xFF8C5A3C,
    0xFFF5D6BC, 0xFFC68D68, 0xFFE4B48D, 0xFF7B4B33,
  ];
  static const _hairs = <int>[
    0xFF4A2A1B, 0xFF1D1818, 0xFF8E3C21, 0xFFE0B357,
    0xFFB9B3AB, 0xFF70462A, 0xFF2B2220, 0xFFC8632B,
  ];
  static const _clothes = <int>[
    0xFFC98A32, 0xFF3E6FA3, 0xFF2A2D33, 0xFF2D4C7C,
    0xFFB04A72, 0xFF4F8A62, 0xFF7C4DA0, 0xFFD2673F,
  ];
  static const _feminine = [
    HairStyle.long, HairStyle.bob, HairStyle.bun, HairStyle.curly
  ];
  static const _masculine = [
    HairStyle.short, HairStyle.side, HairStyle.cap, HairStyle.bald
  ];

  /// Rasgos de un personaje: salen del índice y del género del caso.
  factory PortraitSpec.forCharacter(int index, {required bool female}) {
    final i = index < 0 ? 0 : index;
    final styles = female ? _feminine : _masculine;
    return PortraitSpec(
      skin: Color(_skins[i % 8]),
      hair: Color(_hairs[i % 8]),
      clothes: Color(_clothes[i % 8]),
      style: styles[(i ~/ 2) % 4],
      glasses: const {1, 4, 6}.contains(i % 8),
      earrings: female && (i % 4 == 0 || i % 4 == 2),
      tie: !female && const {3, 7}.contains(i % 8),
    );
  }
}

const double _hy = -0.14; // altura del centro de la cabeza

Path _headRel(Path p) => p.shift(const Offset(0, _hy));

/// Arma el busto. [eyeOpen] va de 0 (cerrados) a 1 (abiertos). La víctima
/// lleva cruces en los ojos, boca recta y piel pálida.
List<Part> buildBust(
  PortraitSpec s, {
  bool victim = false,
  double eyeOpen = 1,
  Brightness mode = Brightness.light,
}) {
  final skin = victim ? Color.lerp(s.skin, const Color(0xFFC9CDC2), 0.55)! : s.skin;
  final skinD = shadeColor(skin, 0.14);
  final hairC = s.hair;
  final clothes = victim ? const Color(0xFF6C7480) : s.clothes;
  const ink = Color(0xFF2A1D18);
  final parts = <Part>[];

  // --- pelo de atrás ---
  switch (s.style) {
    case HairStyle.long:
      parts.add(Part(rrP(-0.54, -0.55 + _hy + 0.14, 1.08, 1.5, 0.46), hairC, shade: 0.4));
    case HairStyle.bob:
      parts.add(Part(rrP(-0.5, -0.5 + _hy + 0.12, 1.0, 0.98, 0.42), hairC, shade: 0.4));
    case HairStyle.curly:
      for (var k = 0; k <= 8; k++) {
        final a = math.pi + k * math.pi / 8;
        parts.add(Part(
            circleP(0.46 * math.cos(a), -0.02 + _hy + 0.46 * math.sin(a), 0.2), hairC,
            shade: 0.3));
      }
      parts.add(Part(circleP(-0.44, 0.12 + _hy, 0.17), hairC, shade: 0.3));
      parts.add(Part(circleP(0.44, 0.12 + _hy, 0.17), hairC, shade: 0.3));
    default:
      break;
  }

  // --- torso, cuello y ropa ---
  parts.add(Part(
      Path()
        ..moveTo(-1.25, 1.3)
        ..lineTo(-1.25, 0.95)
        ..cubicTo(-1.05, 0.62, -0.6, 0.58, -0.22, 0.5)
        ..lineTo(0.22, 0.5)
        ..cubicTo(0.6, 0.58, 1.05, 0.62, 1.25, 0.95)
        ..lineTo(1.25, 1.3)
        ..close(),
      clothes,
      shade: 0.7));
  parts.add(Part(rrP(-0.15, 0.16, 0.3, 0.42, 0.08), skinD, shade: 0.2));
  // Escote en V y cuello de camisa.
  parts.add(Part(polyP(const [Offset(-0.2, 0.5), Offset(0, 0.8), Offset(0.2, 0.5)]),
      skinD,
      role: PartRole.detail));
  if (s.tie) {
    parts.add(Part(polyP(const [Offset(-0.24, 0.5), Offset(-0.02, 0.6), Offset(-0.2, 0.8)]),
        const Color(0xFFF4EFE4), role: PartRole.detail));
    parts.add(Part(polyP(const [Offset(0.24, 0.5), Offset(0.02, 0.6), Offset(0.2, 0.8)]),
        const Color(0xFFF4EFE4), role: PartRole.detail));
    parts.add(Part(polyP(const [Offset(-0.06, 0.6), Offset(0.06, 0.6), Offset(0.11, 1.05), Offset(-0.11, 1.05)]),
        const Color(0xFFB8402F), shade: 0.3));
  } else {
    parts.add(Part(lineP(-0.22, 0.52, -0.34, 1.05), shadeColor(clothes, 0.3),
        role: PartRole.line, width: 0.035));
    parts.add(Part(lineP(0.22, 0.52, 0.34, 1.05), shadeColor(clothes, 0.3),
        role: PartRole.line, width: 0.035));
  }

  // --- orejas y cabeza ---
  parts.add(Part(ovalP(-0.4, -0.04 + _hy + 0.08, 0.07, 0.1), skinD, shade: 0.2));
  parts.add(Part(ovalP(0.4, -0.04 + _hy + 0.08, 0.07, 0.1), skinD, shade: 0.2));
  parts.add(Part(ovalP(0, _hy, 0.4, 0.46), skin, shade: 0.55));

  // --- barba (calvo) ---
  if (s.style == HairStyle.bald) {
    parts.add(Part(
        _headRel(Path()
          ..moveTo(-0.4, 0.04)
          ..cubicTo(-0.42, 0.56, 0.42, 0.56, 0.4, 0.04)
          ..cubicTo(0.26, 0.22, -0.26, 0.22, -0.4, 0.04)
          ..close()),
        hairC,
        shade: 0.3));
  }

  // --- pelo de adelante ---
  switch (s.style) {
    case HairStyle.long:
    case HairStyle.bob:
      parts.add(Part(
          _headRel(Path()
            ..moveTo(-0.43, -0.02)
            ..cubicTo(-0.50, -0.74, 0.50, -0.74, 0.43, -0.02)
            ..cubicTo(0.36, -0.26, 0.10, -0.40, -0.06, -0.36)
            ..cubicTo(-0.22, -0.32, -0.36, -0.18, -0.43, -0.02)
            ..close()),
          hairC,
          shade: 0.5));
    case HairStyle.bun:
      parts.add(Part(circleP(0, -0.62 + _hy, 0.2), hairC, shade: 0.4));
      parts.add(Part(
          _headRel(Path()
            ..moveTo(-0.43, -0.02)
            ..cubicTo(-0.50, -0.74, 0.50, -0.74, 0.43, -0.02)
            ..cubicTo(0.36, -0.26, 0.10, -0.40, -0.06, -0.36)
            ..cubicTo(-0.22, -0.32, -0.36, -0.18, -0.43, -0.02)
            ..close()),
          hairC,
          shade: 0.5));
    case HairStyle.curly:
      for (var k = 0; k < 4; k++) {
        parts.add(Part(circleP(-0.27 + k * 0.18, -0.36 + _hy, 0.13), hairC, shade: 0.3));
      }
    case HairStyle.short:
      parts.add(Part(
          _headRel(Path()
            ..moveTo(-0.42, -0.06)
            ..cubicTo(-0.48, -0.68, 0.48, -0.68, 0.42, -0.06)
            ..cubicTo(0.34, -0.22, -0.28, -0.26, -0.42, -0.06)
            ..close()),
          hairC,
          shade: 0.5));
    case HairStyle.side:
      parts.add(Part(
          _headRel(Path()
            ..moveTo(-0.44, -0.02)
            ..cubicTo(-0.54, -0.8, 0.5, -0.82, 0.44, -0.02)
            ..cubicTo(0.40, -0.24, 0.16, -0.40, -0.12, -0.30)
            ..cubicTo(-0.28, -0.24, -0.38, -0.14, -0.44, -0.02)
            ..close()),
          hairC,
          shade: 0.5));
    case HairStyle.cap:
      final capC = victim ? const Color(0xFF59616D) : s.clothes == const Color(0xFFD2673F) ? const Color(0xFF2D4C7C) : const Color(0xFFD2673F);
      parts.add(Part(
          _headRel(Path()
            ..moveTo(-0.46, -0.12)
            ..cubicTo(-0.46, -0.72, 0.46, -0.72, 0.46, -0.12)
            ..close()),
          capC,
          shade: 0.6));
      parts.add(Part(rrP(-0.36, -0.2 + _hy + 0.04, 0.72, 0.11, 0.05), shadeColor(capC, 0.22), shade: 0.4));
    case HairStyle.bald:
      break;
  }

  // --- rostro ---
  final e = eyeOpen.clamp(0.05, 1.0);
  for (final sx in const [-1.0, 1.0]) {
    if (victim) {
      const d = 0.05;
      final c = Offset(sx * 0.16, 0.02 + _hy + 0.0);
      parts.add(Part(
          Path()
            ..moveTo(c.dx - d, c.dy - d)
            ..lineTo(c.dx + d, c.dy + d)
            ..moveTo(c.dx - d, c.dy + d)
            ..lineTo(c.dx + d, c.dy - d),
          ink,
          role: PartRole.line,
          width: 0.04));
    } else {
      parts.add(Part(ovalP(sx * 0.16, 0.02 + _hy, 0.055, 0.075 * e), ink, role: PartRole.detail));
      if (e > 0.5) {
        parts.add(Part(circleP(sx * 0.16 - 0.016, -0.012 + _hy, 0.016),
            const Color(0xFFFFFFFF), role: PartRole.detail));
      }
    }
    // Cejas.
    parts.add(Part(
        Path()
          ..moveTo(sx * 0.09, -0.12 + _hy)
          ..quadraticBezierTo(sx * 0.17, -0.17 + _hy + (victim ? 0.04 : 0), sx * 0.25, -0.12 + _hy),
        shadeColor(hairC, 0.15),
        role: PartRole.line,
        width: 0.035));
    if (!victim) {
      parts.add(Part(ovalP(sx * 0.25, 0.14 + _hy, 0.07, 0.045), const Color(0x33E0525A),
          role: PartRole.detail));
    }
  }
  // Nariz y boca.
  parts.add(Part(
      Path()
        ..moveTo(0, 0.07 + _hy)
        ..lineTo(-0.03, 0.14 + _hy)
        ..lineTo(0.03, 0.14 + _hy),
      shadeColor(skin, 0.28),
      role: PartRole.line,
      width: 0.025));
  parts.add(Part(
      victim
          ? lineP(-0.08, 0.24 + _hy, 0.08, 0.24 + _hy)
          : (Path()
            ..moveTo(-0.11, 0.21 + _hy)
            ..quadraticBezierTo(0, 0.31 + _hy, 0.11, 0.21 + _hy)),
      const Color(0xFF8E3B33),
      role: PartRole.line,
      width: 0.04));
  if (s.style == HairStyle.bald) {
    parts.add(Part(ovalP(0, 0.17 + _hy, 0.13, 0.03), hairC, role: PartRole.detail));
  }

  // --- accesorios ---
  if (s.glasses) {
    for (final sx in const [-1.0, 1.0]) {
      parts.add(Part(circleP(sx * 0.17, 0.02 + _hy, 0.115), const Color(0x22FFFFFF),
          role: PartRole.detail));
      parts.add(Part(circleP(sx * 0.17, 0.02 + _hy, 0.115), const Color(0xFF2A1D18),
          role: PartRole.line, width: 0.03));
    }
    parts.add(Part(lineP(-0.055, 0.02 + _hy, 0.055, 0.02 + _hy), const Color(0xFF2A1D18),
        role: PartRole.line, width: 0.03));
  }
  if (s.earrings) {
    for (final sx in const [-1.0, 1.0]) {
      parts.add(Part(circleP(sx * 0.4, 0.2 + _hy, 0.045), const Color(0xFFF1C453),
          role: PartRole.detail));
    }
  }
  return parts;
}
