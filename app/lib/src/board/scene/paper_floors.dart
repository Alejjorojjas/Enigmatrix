/// Pisos de la piel Papel: cartulina de colores lisos con un estampado simple
/// de papel de regalo (rayas, lunares, cuadros o zigzag). Nada de madera ni
/// piedra realistas: se tiene que ver que es papel. El estampado sale del tipo
/// de piso de la habitación, así que sigue habiendo variedad entre habitaciones.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import 'floors.dart';

enum PaperPattern { rayas, lunares, cuadros, zigzag }

PaperPattern paperPatternFor(FloorKind kind) => switch (kind) {
      FloorKind.madera => PaperPattern.rayas,
      FloorKind.piedra => PaperPattern.lunares,
      FloorKind.baldosa => PaperPattern.cuadros,
      FloorKind.alfombra => PaperPattern.zigzag,
    };

/// Cartulinas (claras): mostaza, menta, coral, azul cielo, lila, rosa, lima y
/// naranja.
const _cardstock = <int>[
  0xFFF0C14B, 0xFF7FC4A8, 0xFFE9806A, 0xFF7DB4D9,
  0xFFB79BD9, 0xFFEFA3B8, 0xFFA9C95B, 0xFFF2A65A,
];

/// Color de la cartulina de la habitación [index]. En modo oscuro se apaga y
/// se calienta, sin llegar al negro.
Color cardstockTone(int index, Brightness mode) {
  final c = Color(_cardstock[index % _cardstock.length]);
  if (mode == Brightness.light) return c;
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness * 0.52).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
      .toColor();
}

/// Pinta la cartulina de una habitación. [clip] es el recorte irregular,
/// [bounds] el rectángulo que lo contiene (el estampado continúa de una casilla
/// a otra) y [cell] el tamaño de una casilla.
void paintCardstock(
  Canvas canvas, {
  required PaperPattern pattern,
  required Path clip,
  required Rect bounds,
  required double cell,
  required Color base,
  required Brightness mode,
  required int seed,
}) {
  final dark = mode == Brightness.dark;
  final rnd = math.Random(seed);
  final ink = Color.lerp(base, const Color(0xFFFFFFFF), dark ? 0.16 : 0.42)!;
  final shade = Color.lerp(base, const Color(0xFF3A1E08), dark ? 0.30 : 0.16)!;

  canvas.save();
  canvas.clipPath(clip);
  canvas.drawRect(bounds.inflate(cell * 0.2), Paint()..color = base);

  switch (pattern) {
    case PaperPattern.rayas:
      // Rayas verticales anchas, como papel de regalo.
      final w = cell * 0.16;
      final paint = Paint()..color = ink.withValues(alpha: 0.75);
      for (var x = bounds.left + cell * 0.09; x < bounds.right; x += cell * 0.32) {
        canvas.drawRect(Rect.fromLTWH(x, bounds.top - cell * 0.1, w, bounds.height + cell * 0.2), paint);
      }
    case PaperPattern.lunares:
      final r = cell * 0.075;
      final paint = Paint()..color = ink.withValues(alpha: 0.85);
      final gap = cell * 0.34;
      var row = 0;
      for (var y = bounds.top + gap / 2; y < bounds.bottom + gap; y += gap * 0.86, row++) {
        for (var x = bounds.left + (row.isOdd ? gap : gap / 2); x < bounds.right + gap; x += gap) {
          canvas.drawCircle(Offset(x, y), r, paint);
        }
      }
    case PaperPattern.cuadros:
      // Cuadros de mantel: bandas cruzadas más oscuras, el cruce aún más.
      final band = cell * 0.2;
      final pitch = cell * 0.4;
      final paint = Paint()..color = shade.withValues(alpha: 0.30);
      for (var x = bounds.left; x < bounds.right; x += pitch) {
        canvas.drawRect(Rect.fromLTWH(x, bounds.top - cell * 0.1, band, bounds.height + cell * 0.2), paint);
      }
      for (var y = bounds.top; y < bounds.bottom; y += pitch) {
        canvas.drawRect(Rect.fromLTWH(bounds.left - cell * 0.1, y, bounds.width + cell * 0.2, band), paint);
      }
    case PaperPattern.zigzag:
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = cell * 0.06
        ..color = ink.withValues(alpha: 0.9);
      final amp = cell * 0.09;
      final half = cell * 0.12;
      for (var y = bounds.top + cell * 0.12; y < bounds.bottom + cell * 0.2; y += cell * 0.26) {
        final p = Path()..moveTo(bounds.left - half, y);
        var up = true;
        for (var x = bounds.left - half; x < bounds.right + half; x += half) {
          p.lineTo(x + half, y + (up ? -amp : amp));
          up = !up;
        }
        canvas.drawPath(p, paint);
      }
  }

  // Fibra de papel bien visible y motitas de grano.
  final area = bounds.width * bounds.height / (cell * cell);
  final fiberLight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(0.9, cell * 0.014)
    ..color = const Color(0xFFFFFFFF).withValues(alpha: dark ? 0.16 : 0.42);
  final fiberDark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(0.8, cell * 0.012)
    ..color = const Color(0xFF3A1E08).withValues(alpha: dark ? 0.26 : 0.12);
  final n = (area * 34).round();
  for (var k = 0; k < n; k++) {
    final x = bounds.left + rnd.nextDouble() * bounds.width;
    final y = bounds.top + rnd.nextDouble() * bounds.height;
    final a = rnd.nextDouble() * math.pi;
    final l = cell * (0.10 + rnd.nextDouble() * 0.22);
    final dx = math.cos(a) * l, dy = math.sin(a) * l;
    final p = Path()
      ..moveTo(x, y)
      ..quadraticBezierTo(x + dx * 0.5 + dy * 0.2, y + dy * 0.5 - dx * 0.2, x + dx, y + dy);
    canvas.drawPath(p, k.isEven ? fiberLight : fiberDark);
  }
  final speck = Paint()..color = const Color(0xFF3A1E08).withValues(alpha: dark ? 0.30 : 0.14);
  for (var k = 0; k < (area * 26).round(); k++) {
    canvas.drawCircle(
        Offset(bounds.left + rnd.nextDouble() * bounds.width,
            bounds.top + rnd.nextDouble() * bounds.height),
        math.max(0.5, cell * 0.008),
        speck);
  }
  canvas.restore();
}
