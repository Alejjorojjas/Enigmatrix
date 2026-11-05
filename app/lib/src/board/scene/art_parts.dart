/// Arte provisional hecho por código: un dibujo es una lista de "piezas"
/// ([Part]) en unidades propias (la casilla para los muebles, el radio para
/// los retratos). Cada piel sabe pintar esa misma lista a su manera:
///  - [InkRenderer] (piel Ilustrada): contorno oscuro, color base, luz y
///    sombreado.
///  - [PaperRenderer] (piel Papel): recortes de papel con grosor, borde blanco
///    y fibra.
/// Así los muebles y los retratos se escriben una vez y se ven distintos en
/// cada piel.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

/// Papel que juega cada pieza.
enum PartRole {
  /// Silueta principal: proyecta sombra y, en papel, lleva borde blanco.
  base,

  /// Pieza interior con contorno (cojines, puertas, mechones).
  face,

  /// Detalle pequeño, relleno liso y sin contorno.
  detail,

  /// Solo trazo (vetas, costuras).
  line,
}

class Part {
  const Part(
    this.path,
    this.color, {
    this.role = PartRole.face,
    this.width = 0.02,
    this.shade = 0.5,
  });

  final Path path;
  final Color color;
  final PartRole role;

  /// Grosor del trazo cuando [role] es [PartRole.line].
  final double width;

  /// Cuánto degradado de luz y sombra lleva (0 = liso).
  final double shade;
}

// -----------------------------------------------------------------------------
// Constructores de formas (todo en unidades de la pieza)
// -----------------------------------------------------------------------------

Path rrP(double x, double y, double w, double h, [double r = 0.06]) => Path()
  ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h), Radius.circular(math.min(r, math.min(w, h) / 2))));

Path ovalP(double cx, double cy, double rx, double ry) =>
    Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));

Path circleP(double cx, double cy, double r) => ovalP(cx, cy, r, r);

Path lineP(double x1, double y1, double x2, double y2) =>
    Path()..moveTo(x1, y1)..lineTo(x2, y2);

Path polyP(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// Hoja alargada que sale de ([cx], [cy]) hacia el ángulo [ang].
Path leafP(double cx, double cy, double len, double wid, double ang) {
  final ca = math.cos(ang), sa = math.sin(ang);
  Offset t(double x, double y) =>
      Offset(cx + x * ca - y * sa, cy + x * sa + y * ca);
  final tip = t(len, 0);
  final c1 = t(len * 0.35, -wid);
  final c2 = t(len * 0.35, wid);
  return Path()
    ..moveTo(cx, cy)
    ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
    ..quadraticBezierTo(c2.dx, c2.dy, cx, cy)
    ..close();
}

Color shadeColor(Color c, double towardBlack) =>
    Color.lerp(c, const Color(0xFF000000), towardBlack.clamp(0.0, 1.0))!;
Color lightenColor(Color c, double towardWhite) =>
    Color.lerp(c, const Color(0xFFFFFFFF), towardWhite.clamp(0.0, 1.0))!;

// -----------------------------------------------------------------------------
// Fibra de papel
// -----------------------------------------------------------------------------

/// Trazos cortos y casi invisibles, siempre los mismos para una misma
/// [seed] (no parpadean de un cuadro a otro).
void paintFibers(Canvas canvas, Rect bounds, int seed, Color color,
    {int count = 18, double len = 0.12, double width = 0.012}) {
  final rnd = math.Random(seed);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width
    ..color = color;
  for (var i = 0; i < count; i++) {
    final x = bounds.left + rnd.nextDouble() * bounds.width;
    final y = bounds.top + rnd.nextDouble() * bounds.height;
    final a = rnd.nextDouble() * math.pi;
    final l = len * (0.5 + rnd.nextDouble());
    final dx = math.cos(a) * l, dy = math.sin(a) * l;
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + dx * 0.5 + dy * 0.25, y + dy * 0.5 - dx * 0.25,
            x + dx, y + dy),
      paint,
    );
  }
}

// -----------------------------------------------------------------------------
// Pintores
// -----------------------------------------------------------------------------

abstract class PartRenderer {
  const PartRenderer();

  /// Pinta [parts] en unidades de la pieza (el canvas ya está escalado).
  /// [unit] es el tamaño de una unidad en píxeles: sirve para no dejar
  /// trazos más finos que un píxel. [rotation] es el giro del lienzo (la
  /// profundidad del papel siempre cae hacia abajo en pantalla).
  void paint(Canvas canvas, List<Part> parts,
      {double unit = 1, double rotation = 0});
}

/// Ilustrada: contorno oscuro, luz arriba a la izquierda y sombreado abajo.
class InkRenderer extends PartRenderer {
  const InkRenderer({required this.outline, this.outlineWidth = 0.05});

  final Color outline;

  /// Grosor del contorno en unidades de la pieza.
  final double outlineWidth;

  @override
  void paint(Canvas canvas, List<Part> parts,
      {double unit = 1, double rotation = 0}) {
    final ow = math.max(outlineWidth, 1.3 / unit);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final p in parts) {
      switch (p.role) {
        case PartRole.line:
          canvas.drawPath(
              p.path,
              stroke
                ..strokeWidth = math.max(p.width, 0.9 / unit)
                ..color = p.color);
        case PartRole.detail:
          canvas.drawPath(p.path, Paint()..color = p.color);
        case PartRole.base:
        case PartRole.face:
          final fill = Paint();
          if (p.shade > 0) {
            final b = p.path.getBounds();
            fill.shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lightenColor(p.color, 0.20 * p.shade),
                p.color,
                shadeColor(p.color, 0.20 * p.shade),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(b);
          } else {
            fill.color = p.color;
          }
          canvas.drawPath(p.path, fill);
          if (p.shade > 0 && p.role == PartRole.base) {
            // Filo de luz por dentro, arriba y a la izquierda.
            canvas.save();
            canvas.clipPath(p.path);
            canvas.drawPath(
                p.path.shift(Offset(ow * 0.9, ow * 0.9)),
                stroke
                  ..strokeWidth = ow * 0.9
                  ..color = const Color(0x2EFFFFFF));
            canvas.restore();
          }
          final base = p.role == PartRole.base ? 1.0 : 0.72;
          canvas.drawPath(
              p.path,
              stroke
                ..strokeWidth = ow * base
                ..color = p.role == PartRole.base
                    ? outline
                    : Color.lerp(p.color, outline, 0.82)!);
      }
    }
  }
}

/// Papel: cada pieza es un recorte con grosor (capa inferior más oscura
/// desplazada hacia abajo), las siluetas llevan borde blanco y fibra.
class PaperRenderer extends PartRenderer {
  const PaperRenderer({
    required this.edge,
    this.depth = 0.05,
    this.border = 0.03,
    this.fibers = 14,
    this.seed = 7,
    this.fiberColor = const Color(0x22FFFFFF),
  });

  final Color edge;

  /// Desplazamiento de la capa inferior (grosor del papel), en unidades.
  final double depth;

  /// Ancho del borde blanco de recorte, en unidades.
  final double border;

  /// Cantidad de fibras por silueta (0 = sin textura).
  final int fibers;
  final int seed;
  final Color fiberColor;

  @override
  void paint(Canvas canvas, List<Part> parts,
      {double unit = 1, double rotation = 0}) {
    final d = math.max(depth, 1.2 / unit);
    final sx = math.sin(rotation), sy = math.cos(rotation);
    final bw = math.max(border, 0.9 / unit);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    var k = 0;
    for (final p in parts) {
      k++;
      switch (p.role) {
        case PartRole.line:
          canvas.drawPath(
              p.path,
              stroke
                ..strokeWidth = math.max(p.width, 0.8 / unit)
                ..color = p.color);
        case PartRole.detail:
          canvas.drawPath(p.path, Paint()..color = p.color);
        case PartRole.face:
          canvas.drawPath(p.path.shift(Offset(d * 0.55 * sx, d * 0.55 * sy)),
              Paint()..color = shadeColor(p.color, 0.36));
          canvas.drawPath(p.path, Paint()..color = p.color);
        case PartRole.base:
          canvas.drawPath(p.path.shift(Offset(d * sx, d * sy)),
              Paint()..color = shadeColor(p.color, 0.38));
          canvas.drawPath(
              p.path,
              stroke
                ..strokeWidth = bw * 2
                ..color = edge);
          canvas.drawPath(p.path, Paint()..color = p.color);
          if (fibers > 0) {
            canvas.save();
            canvas.clipPath(p.path);
            paintFibers(canvas, p.path.getBounds(), seed + k * 31, fiberColor,
                count: fibers, len: 0.16, width: math.max(0.01, 0.8 / unit));
            canvas.restore();
          }
      }
    }
  }
}
