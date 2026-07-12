/// Logo de Enigmatrix (2026-07-12, dirección elegida: "lupa de papel").
/// Lupa recortada en capas de papel sobre kraft, con hilo carmesí del
/// tablero de evidencias. CustomPainter puro: escala a cualquier tamaño
/// (splash, header, icono).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class PaperLogo extends StatelessWidget {
  final double size;

  /// Si true dibuja la placa kraft redondeada de fondo (para icono/splash);
  /// si false, solo la lupa (para headers sobre fondo ya kraft).
  final bool withPlate;

  const PaperLogo({super.key, required this.size, this.withPlate = true});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PaperLogoPainter(withPlate: withPlate),
      );
}

class _PaperLogoPainter extends CustomPainter {
  final bool withPlate;
  const _PaperLogoPainter({required this.withPlate});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Paint fill(Color c) => Paint()..color = c;
    Paint hardShadow() => Paint()
      ..color = const Color(0xFF473418).withValues(alpha: .35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .008);

    if (withPlate) {
      // Placa kraft con borde de cartón.
      final plate = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, s, s), Radius.circular(s * .22));
      canvas.drawRRect(plate, fill(const Color(0xFFE9DCBE)));
      canvas.drawRRect(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .025
            ..color = const Color(0xFFC9B48A));
      // Esquinas cosidas (puntadas).
      final stitch = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8A7A5C).withValues(alpha: .6);
      for (final (cx, cy) in [(.13, .13), (.87, .13), (.13, .87), (.87, .87)]) {
        canvas.drawLine(Offset(s * (cx - .03), s * cy),
            Offset(s * (cx + .03), s * cy), stitch);
      }
    }

    final c = Offset(s * .44, s * .42);
    final r = s * .26;

    // Sombra dura de la lupa completa.
    canvas.save();
    canvas.translate(s * .012, s * .028);
    canvas.drawCircle(c, r * 1.22, hardShadow());
    canvas.restore();

    // Mango de papel (rotado 45°, hacia abajo-derecha).
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    final handle = RRect.fromRectAndRadius(
        Rect.fromLTWH(r * .95, -r * .17, r * 1.35, r * .34),
        Radius.circular(r * .17));
    canvas.drawRRect(
        handle.shift(Offset(r * .04, r * .09)), hardShadow());
    canvas.drawRRect(handle, fill(const Color(0xFF8A5C2E)));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r * .95, -r * .17, r * 1.35, r * .13),
            Radius.circular(r * .06)),
        fill(const Color(0xFFA0703C)));
    canvas.restore();

    // Aro exterior de la lupa: papel dorado en dos capas.
    canvas.drawCircle(c, r * 1.22, fill(const Color(0xFFB3821F)));
    canvas.drawCircle(c, r * 1.08, fill(const Color(0xFFF0B429)));
    // Cristal: papel azulado claro con brillo recortado.
    canvas.drawCircle(c, r * .88, fill(const Color(0xFFCFE3E6)));
    final gleam = Path()
      ..moveTo(c.dx - r * .5, c.dy + r * .55)
      ..lineTo(c.dx - r * .05, c.dy - r * .7)
      ..lineTo(c.dx + r * .28, c.dy - r * .7)
      ..lineTo(c.dx - r * .18, c.dy + r * .55)
      ..close();
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * .88)));
    canvas.drawPath(gleam, fill(Colors.white.withValues(alpha: .55)));
    canvas.restore();

    // Signo de interrogación vectorial dentro del cristal (sin fuentes,
    // para poder rasterizar el icono en tests).
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .17
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3D2F1C);
    final qc = Offset(c.dx, c.dy - r * .22);
    final qr = r * .26;
    final qPath = Path()
      ..addArc(Rect.fromCircle(center: qc, radius: qr), math.pi * .85,
          math.pi * 1.4)
      ..moveTo(c.dx + qr * math.cos(math.pi * .25),
          qc.dy + qr * math.sin(math.pi * .25));
    canvas.drawPath(qPath, ink);
    // Tallo y punto.
    canvas.drawLine(Offset(c.dx + qr * .7, qc.dy + qr * .7),
        Offset(c.dx, c.dy + r * .18), ink);
    canvas.drawCircle(Offset(c.dx, c.dy + r * .52), r * .10,
        Paint()..color = const Color(0xFF3D2F1C));

    // Hilo carmesí: entra por la esquina, da una vuelta y sale.
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .022
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB3452E);
    final path = Path()
      ..moveTo(s * .06, s * .70)
      ..quadraticBezierTo(s * .18, s * .88, s * .34, s * .80)
      ..quadraticBezierTo(s * .46, s * .74, s * .60, s * .84)
      ..quadraticBezierTo(s * .76, s * .94, s * .92, s * .80);
    // Punteado manual sobre la curva.
    for (final metric in path.computeMetrics()) {
      double d = 0;
      final dash = s * .045, gap = s * .03;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), thread);
        d += dash + gap;
      }
    }
    // Chincheta donde empieza el hilo.
    canvas.drawCircle(Offset(s * .06, s * .70), s * .035,
        fill(const Color(0xFFB3452E)));
    canvas.drawCircle(Offset(s * .05, s * .69), s * .012,
        fill(Colors.white.withValues(alpha: .5)));
  }

  @override
  bool shouldRepaint(covariant _PaperLogoPainter old) =>
      old.withPlate != withPlate;
}
