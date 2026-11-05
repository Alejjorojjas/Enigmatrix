/// Pisos por habitación: madera, piedra, baldosa y alfombra. Son texturas
/// procedurales sutiles con una paleta propia; en modo oscuro se atenúan. Las
/// dos pieles nuevas (Ilustrada y Papel) los usan.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

enum FloorKind { madera, piedra, baldosa, alfombra }

/// Quita tildes y pasa a minúsculas, para buscar palabras en el nombre.
String normalizeRoomName(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunaeiouun';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch.toLowerCase());
  }
  return b.toString();
}

/// Tipo de piso según el nombre de la habitación; si el nombre no dice nada,
/// según su índice en el mapa.
FloorKind floorKindFor(String nameEs, int index) {
  final n = normalizeRoomName(nameEs);
  bool has(List<String> words) => words.any(n.contains);
  if (has(const ['bano', 'cocina', 'lavander', 'restaurante', 'despensa', 'aseo'])) {
    return FloorKind.baldosa;
  }
  if (has(const [
    'terraza', 'pasillo', 'patio', 'galeria', 'cripta', 'recepcion', 'entrada',
    'jardin', 'sotano', 'garaje', 'vestibulo', 'porche', 'corredor', 'hall'
  ])) {
    return FloorKind.piedra;
  }
  if (has(const ['dormitorio', 'salon', 'sala', 'evento', 'suite', 'camarote', 'teatro'])) {
    return FloorKind.alfombra;
  }
  if (has(const ['biblioteca', 'estudio', 'comedor', 'despacho', 'habitacion', 'oficina'])) {
    return FloorKind.madera;
  }
  return FloorKind.values[index % FloorKind.values.length];
}

/// Tonos base de cada piso (3 variantes por tipo).
const _tones = <FloorKind, List<int>>{
  FloorKind.madera: [0xFFD9A869, 0xFFC18651, 0xFFE6C48E],
  FloorKind.piedra: [0xFFCBC5BA, 0xFFB3B8BD, 0xFFD9CDB4],
  FloorKind.baldosa: [0xFFDDD3B9, 0xFFB9CCC8, 0xFFE4CBB9],
  FloorKind.alfombra: [0xFFC99088, 0xFFA2B6A2, 0xFFB9A7C5],
};

/// Color base del piso. En modo oscuro se atenúa y se calienta.
Color floorTone(FloorKind kind, int variant, Brightness mode) {
  final c = Color(_tones[kind]![variant % 3]);
  if (mode == Brightness.light) return c;
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness * 0.50).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
      .toColor();
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Pinta el piso de una habitación. [clip] es la unión de sus casillas;
/// [bounds] el rectángulo que las contiene (alineado a la cuadrícula, así las
/// tablas y baldosas continúan de una casilla a otra).
void paintFloor(
  Canvas canvas, {
  required FloorKind kind,
  required Path clip,
  required Rect bounds,
  required double cell,
  required Color base,
  required Brightness mode,
  int seed = 1,
  bool paper = false,
}) {
  final rnd = math.Random(seed);
  final dark = const Color(0xFF2A1A0E);
  final lite = const Color(0xFFFFFFFF);
  final hair = math.max(0.8, cell * 0.012);
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = hair;

  canvas.save();
  canvas.clipPath(clip);
  canvas.drawRect(bounds, Paint()..color = base);

  switch (kind) {
    case FloorKind.madera:
      final ph = cell * 0.25;
      var row = 0;
      for (var y = bounds.top; y < bounds.bottom; y += ph, row++) {
        // Cada fila es una tira de tablas con juntas escalonadas.
        var x = bounds.left - rnd.nextDouble() * cell * 0.8;
        while (x < bounds.right) {
          final len = cell * (0.7 + rnd.nextDouble() * 0.9);
          final tone = (rnd.nextDouble() - 0.5) * 0.10;
          final r = Rect.fromLTWH(x, y, len, ph);
          canvas.drawRect(
              r, Paint()..color = _mix(base, tone > 0 ? lite : dark, tone.abs()));
          // Veta.
          if (rnd.nextDouble() < 0.7) {
            final gy = y + ph * (0.3 + rnd.nextDouble() * 0.4);
            canvas.drawLine(Offset(x + len * 0.1, gy), Offset(x + len * 0.55, gy),
                line..color = dark.withValues(alpha: 0.10));
          }
          // Junta entre tablas.
          canvas.drawLine(Offset(x, y), Offset(x, y + ph),
              line..color = dark.withValues(alpha: 0.22));
          x += len;
        }
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y),
            line..color = dark.withValues(alpha: 0.24));
      }
    case FloorKind.piedra:
      // Losas irregulares sobre una junta más oscura.
      canvas.drawRect(bounds, Paint()..color = _mix(base, dark, 0.16));
      final gap = cell * 0.022;
      var y = bounds.top;
      while (y < bounds.bottom) {
        final h = cell * (0.46 + rnd.nextDouble() * 0.24);
        var x = bounds.left - rnd.nextDouble() * cell * 0.6;
        while (x < bounds.right) {
          final w = cell * (0.55 + rnd.nextDouble() * 0.5);
          final tone = (rnd.nextDouble() - 0.5) * 0.12;
          final r = RRect.fromRectAndRadius(
              Rect.fromLTWH(x + gap, y + gap, w - 2 * gap, h - 2 * gap),
              Radius.circular(cell * 0.05));
          canvas.drawRRect(
              r, Paint()..color = _mix(base, tone > 0 ? lite : dark, tone.abs()));
          // Brillo en el borde de arriba y motas.
          canvas.drawLine(Offset(r.left + cell * 0.05, r.top + gap),
              Offset(r.right - cell * 0.05, r.top + gap),
              line..color = lite.withValues(alpha: 0.18));
          for (var k = 0; k < 2; k++) {
            if (rnd.nextDouble() < 0.7) {
              canvas.drawOval(
                  Rect.fromCenter(
                      center: Offset(r.left + rnd.nextDouble() * r.width,
                          r.top + rnd.nextDouble() * r.height),
                      width: cell * (0.05 + rnd.nextDouble() * 0.07),
                      height: cell * 0.04),
                  Paint()..color = dark.withValues(alpha: 0.13));
            }
          }
          x += w;
        }
        y += h;
      }
    case FloorKind.baldosa:
      final t = cell * 0.5;
      var j = 0;
      for (var y = bounds.top; y < bounds.bottom; y += t, j++) {
        var i = 0;
        for (var x = bounds.left; x < bounds.right; x += t, i++) {
          final alt = (i + j).isOdd;
          canvas.drawRect(Rect.fromLTWH(x, y, t, t),
              Paint()..color = alt ? _mix(base, dark, 0.07) : _mix(base, lite, 0.05));
          canvas.drawLine(Offset(x + t * 0.14, y + t * 0.2), Offset(x + t * 0.34, y + t * 0.2),
              line..color = lite.withValues(alpha: 0.28));
        }
      }
      line.color = dark.withValues(alpha: 0.20);
      for (var y = bounds.top; y <= bounds.bottom; y += t) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), line);
      }
      for (var x = bounds.left; x <= bounds.right; x += t) {
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), line);
      }
    case FloorKind.alfombra:
      // Tejido: líneas finas cruzadas y motas.
      final step = cell * 0.07;
      line.color = dark.withValues(alpha: 0.07);
      for (var y = bounds.top; y < bounds.bottom; y += step) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), line);
      }
      line.color = lite.withValues(alpha: 0.07);
      for (var x = bounds.left; x < bounds.right; x += step) {
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), line);
      }
      final n = (bounds.width * bounds.height / (cell * cell) * 14).round();
      for (var k = 0; k < n; k++) {
        canvas.drawCircle(
            Offset(bounds.left + rnd.nextDouble() * bounds.width,
                bounds.top + rnd.nextDouble() * bounds.height),
            cell * 0.014,
            Paint()..color = (rnd.nextBool() ? lite : dark).withValues(alpha: 0.13));
      }
  }

  if (paper) {
    // Fibra de papel sobre el piso.
    final n = (bounds.width * bounds.height / (cell * cell) * 22).round();
    final f = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.7, cell * 0.010)
      ..color = lite.withValues(alpha: 0.10);
    for (var k = 0; k < n; k++) {
      final x = bounds.left + rnd.nextDouble() * bounds.width;
      final y = bounds.top + rnd.nextDouble() * bounds.height;
      final a = rnd.nextDouble() * math.pi;
      final l = cell * (0.08 + rnd.nextDouble() * 0.12);
      canvas.drawLine(Offset(x, y), Offset(x + math.cos(a) * l, y + math.sin(a) * l), f);
    }
  }
  canvas.restore();
}
