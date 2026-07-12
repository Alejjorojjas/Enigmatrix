/// Ilustraciones vectoriales top-down de los muebles (pase 2026-07-12,
/// feedback: "la cama es solo un rectángulo — quiero ver los objetos de
/// verdad"). Cada mueble se dibuja como una pieza cartoon reconocible:
/// cama con almohada y cobija, sofá con cojines y brazos, planta con hojas,
/// mesa con veta de madera, etc. Sin assets externos: todo CustomPainter.
library;

import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';

/// Pintor de un mueble completo (1 o 2 celdas). Dibuja en orientación
/// canónica horizontal (ancho >= alto); si la pieza es vertical, rota el
/// lienzo 90 grados para que la ilustración siga la forma del mueble.
class FurniturePainter extends CustomPainter {
  final ObjectType type;

  const FurniturePainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    var w = size.width, h = size.height;
    canvas.save();
    if (h > w) {
      // Vertical: rotar para dibujar como horizontal.
      canvas.translate(w / 2, h / 2);
      canvas.rotate(math.pi / 2);
      canvas.translate(-h / 2, -w / 2);
      final t = w;
      w = h;
      h = t;
    }

    // Sombra suave bajo la pieza (profundidad de tablero).
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .03, h * .06, w * .94, h * .92),
            Radius.circular(h * .16)),
        shadow);

    switch (type) {
      case ObjectType.cama:
        _bed(canvas, w, h);
      case ObjectType.sofa:
        _sofa(canvas, w, h, seats: 2);
      case ObjectType.sillon:
        _sofa(canvas, w, h, seats: 1);
      case ObjectType.silla:
        _chair(canvas, w, h);
      case ObjectType.mesa:
        _table(canvas, w, h);
      case ObjectType.barra:
        _counter(canvas, w, h);
      case ObjectType.alfombra:
        _rug(canvas, w, h);
      case ObjectType.planta:
        _plant(canvas, w, h);
      case ObjectType.arbusto:
        _bush(canvas, w, h);
      case ObjectType.tv:
        _tv(canvas, w, h);
      case ObjectType.armario:
        _wardrobe(canvas, w, h);
      case ObjectType.caja:
        _box(canvas, w, h);
      case ObjectType.lavadora:
        _washer(canvas, w, h);
      case ObjectType.piano:
        _piano(canvas, w, h);
    }
    canvas.restore();
  }

  // ---------- utilidades ----------

  Paint _fill(Color c) => Paint()..color = c;

  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;

  double _line(double h) => (h * .045).clamp(1.4, 3.0);

  RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  // ---------- muebles ----------

  /// Cama: marco de madera, colchón, almohada a la cabecera y cobija con
  /// doblez cubriendo el resto.
  void _bed(Canvas c, double w, double h) {
    final ln = _line(h);
    const frame = Color(0xFF9C6B43);
    const mattress = Color(0xFFF2EDE4);
    const blanket = Color(0xFF6E93C4);
    const blanketDark = Color(0xFF54779F);

    c.drawRRect(_rr(0, 0, w, h, h * .14), _fill(frame));
    c.drawRRect(_rr(0, 0, w, h, h * .14),
        _stroke(const Color(0xFF6B4527), ln));
    // Colchón.
    c.drawRRect(
        _rr(w * .05, h * .09, w * .90, h * .82, h * .10), _fill(mattress));
    // Cobija: desde el 30% hasta los pies.
    c.drawRRect(
        _rr(w * .30, h * .09, w * .65, h * .82, h * .10), _fill(blanket));
    // Doblez de la cobija.
    c.drawRect(Rect.fromLTWH(w * .30, h * .09, w * .07, h * .82),
        _fill(blanketDark));
    // Pliegues sutiles.
    final crease = _stroke(blanketDark.withValues(alpha: .55), ln * .7);
    c.drawLine(Offset(w * .55, h * .12), Offset(w * .55, h * .88), crease);
    c.drawLine(Offset(w * .75, h * .12), Offset(w * .75, h * .88), crease);
    // Almohada.
    c.drawRRect(
        _rr(w * .08, h * .18, w * .16, h * .64, h * .12), _fill(Colors.white));
    c.drawRRect(_rr(w * .08, h * .18, w * .16, h * .64, h * .12),
        _stroke(const Color(0xFFCFC6B8), ln * .8));
  }

  /// Sofá o sillón: base, respaldo arriba, brazos a los lados y cojines.
  void _sofa(Canvas c, double w, double h, {required int seats}) {
    final ln = _line(h);
    const body = Color(0xFFC96F52);
    const cushion = Color(0xFFDB8B6C);
    const dark = Color(0xFF8F4A35);

    c.drawRRect(_rr(0, 0, w, h, h * .18), _fill(body));
    c.drawRRect(_rr(0, 0, w, h, h * .18), _stroke(dark, ln));
    // Respaldo (banda superior).
    c.drawRRect(_rr(w * .04, h * .05, w * .92, h * .22, h * .10),
        _fill(dark.withValues(alpha: .45)));
    // Brazos.
    c.drawRRect(_rr(w * .02, h * .08, w * .09, h * .84, h * .10),
        _fill(cushion));
    c.drawRRect(_rr(w * .89, h * .08, w * .09, h * .84, h * .10),
        _fill(cushion));
    // Cojines de asiento.
    final seatW = seats == 1 ? w * .70 : w * .36;
    for (var i = 0; i < seats; i++) {
      final x = w * .14 + i * (seatW + w * .02);
      c.drawRRect(
          _rr(x, h * .32, seatW, h * .58, h * .12), _fill(cushion));
      c.drawRRect(_rr(x, h * .32, seatW, h * .58, h * .12),
          _stroke(dark.withValues(alpha: .6), ln * .7));
    }
  }

  /// Silla: asiento de madera con respaldo de barrotes en el borde superior.
  void _chair(Canvas c, double w, double h) {
    final ln = _line(h);
    const seat = Color(0xFFC08F5F);
    const dark = Color(0xFF7C5433);

    c.drawRRect(_rr(w * .12, h * .14, w * .76, h * .74, h * .14), _fill(seat));
    c.drawRRect(
        _rr(w * .12, h * .14, w * .76, h * .74, h * .14), _stroke(dark, ln));
    // Cojincito.
    c.drawRRect(_rr(w * .24, h * .30, w * .52, h * .46, h * .10),
        _fill(const Color(0xFFD9B084)));
    // Respaldo: barra superior con 3 barrotes.
    c.drawRRect(_rr(w * .10, h * .04, w * .80, h * .12, h * .06), _fill(dark));
    final rod = _stroke(dark, ln);
    for (final fx in [.28, .50, .72]) {
      c.drawLine(Offset(w * fx, h * .14), Offset(w * fx, h * .26), rod);
    }
  }

  /// Mesa: tablón de madera con veta y borde biselado.
  void _table(Canvas c, double w, double h) {
    final ln = _line(h);
    const top = Color(0xFFB07B4A);
    const dark = Color(0xFF77502C);

    c.drawRRect(_rr(0, 0, w, h, h * .16), _fill(dark));
    c.drawRRect(_rr(w * .03, h * .05, w * .94, h * .88, h * .13), _fill(top));
    c.drawRRect(_rr(0, 0, w, h, h * .16), _stroke(dark, ln));
    // Veta de madera.
    final grain = _stroke(dark.withValues(alpha: .35), ln * .6);
    for (final fy in [.30, .52, .74]) {
      final path = Path()
        ..moveTo(w * .10, h * fy)
        ..quadraticBezierTo(w * .5, h * (fy - .06), w * .90, h * fy);
      c.drawPath(path, grain);
    }
  }

  /// Barra: encimera de piedra sobre base de madera.
  void _counter(Canvas c, double w, double h) {
    final ln = _line(h);
    const stone = Color(0xFFC7CDD4);
    const stoneDark = Color(0xFF8F98A3);
    const base = Color(0xFF8F6238);

    c.drawRRect(_rr(0, 0, w, h, h * .12), _fill(base));
    c.drawRRect(_rr(w * .02, h * .06, w * .96, h * .70, h * .10), _fill(stone));
    c.drawRRect(_rr(0, 0, w, h, h * .12), _stroke(const Color(0xFF5E3F22), ln));
    // Motas de la piedra.
    final fleck = _fill(stoneDark.withValues(alpha: .5));
    for (final (fx, fy) in [(.2, .3), (.4, .5), (.6, .25), (.8, .45), (.5, .2)]) {
      c.drawCircle(Offset(w * fx, h * fy), ln * .8, fleck);
    }
  }

  /// Alfombra: tejido con cenefa, rombo central y flecos en los extremos.
  void _rug(Canvas c, double w, double h) {
    final ln = _line(h);
    const base = Color(0xFFAE86C8);
    const band = Color(0xFF8A63A6);
    const light = Color(0xFFD3BCE4);

    c.drawRRect(_rr(w * .04, h * .06, w * .92, h * .88, h * .10), _fill(base));
    c.drawRRect(_rr(w * .04, h * .06, w * .92, h * .88, h * .10),
        _stroke(band, ln));
    // Cenefa interior.
    c.drawRRect(_rr(w * .10, h * .18, w * .80, h * .64, h * .08),
        _stroke(light, ln));
    // Rombo central.
    final cx = w / 2, cy = h / 2;
    final diamond = Path()
      ..moveTo(cx, cy - h * .18)
      ..lineTo(cx + w * .09, cy)
      ..lineTo(cx, cy + h * .18)
      ..lineTo(cx - w * .09, cy)
      ..close();
    c.drawPath(diamond, _fill(light));
    // Flecos.
    final fringe = _stroke(light, ln * .8);
    for (var i = 0; i < 5; i++) {
      final fy = h * (.18 + i * .16);
      c.drawLine(Offset(w * .015, fy), Offset(w * .04, fy), fringe);
      c.drawLine(Offset(w * .96, fy), Offset(w * .985, fy), fringe);
    }
  }

  /// Planta: matera de barro con hojas radiales en dos tonos.
  void _plant(Canvas c, double w, double h) {
    final ln = _line(h);
    final cx = w / 2, cy = h / 2;
    final r = math.min(w, h);
    const pot = Color(0xFFC1663B);
    const leafDark = Color(0xFF4C8A3F);
    const leafMid = Color(0xFF5E9F4D);
    const leafLight = Color(0xFF79B865);

    // Matera.
    c.drawCircle(Offset(cx, cy), r * .30, _fill(pot));
    c.drawCircle(
        Offset(cx, cy), r * .30, _stroke(const Color(0xFF8A4527), ln));
    // Hojas: dos coronas de elipses rotadas.
    void leaves(double radius, double len, double wid, Color color) {
      for (var i = 0; i < 7; i++) {
        final ang = i * 2 * math.pi / 7;
        c.save();
        c.translate(cx + math.cos(ang) * radius, cy + math.sin(ang) * radius);
        c.rotate(ang);
        c.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: len, height: wid),
            _fill(color));
        c.restore();
      }
    }

    leaves(r * .27, r * .34, r * .16, leafDark);
    leaves(r * .18, r * .28, r * .13, leafMid);
    c.drawCircle(Offset(cx, cy), r * .10, _fill(leafLight));
  }

  /// Arbusto: racimo de copas verdes con puntitos de brillo.
  void _bush(Canvas c, double w, double h) {
    final cx = w / 2, cy = h / 2;
    final r = math.min(w, h);
    const dark = Color(0xFF3F7A35);
    const mid = Color(0xFF4C8A3F);
    const light = Color(0xFF6BAF58);

    c.drawCircle(Offset(cx - r * .16, cy + r * .08), r * .26, _fill(dark));
    c.drawCircle(Offset(cx + r * .18, cy + r * .05), r * .24, _fill(mid));
    c.drawCircle(Offset(cx, cy - r * .12), r * .28, _fill(mid));
    c.drawCircle(Offset(cx - r * .02, cy + r * .02), r * .20, _fill(light));
    final dot = _fill(Colors.white.withValues(alpha: .35));
    for (final (fx, fy) in [(-.12, -.16), (.10, -.06), (-.04, .12)]) {
      c.drawCircle(Offset(cx + r * fx, cy + r * fy), r * .035, dot);
    }
  }

  /// TV: pantalla con reflejo diagonal sobre mueble bajo.
  void _tv(Canvas c, double w, double h) {
    final ln = _line(h);
    const bezel = Color(0xFF2E3238);
    const screen = Color(0xFF44546B);
    const stand = Color(0xFF6B4F33);

    // Mueble bajo.
    c.drawRRect(_rr(w * .06, h * .62, w * .88, h * .30, h * .10), _fill(stand));
    // Pantalla.
    c.drawRRect(_rr(w * .10, h * .08, w * .80, h * .58, h * .08), _fill(bezel));
    c.drawRRect(
        _rr(w * .14, h * .14, w * .72, h * .46, h * .06), _fill(screen));
    // Reflejo.
    final gleam = Path()
      ..moveTo(w * .20, h * .60)
      ..lineTo(w * .38, h * .14)
      ..lineTo(w * .50, h * .14)
      ..lineTo(w * .32, h * .60)
      ..close();
    c.drawPath(gleam, _fill(Colors.white.withValues(alpha: .18)));
    c.drawRRect(_rr(w * .10, h * .08, w * .80, h * .58, h * .08),
        _stroke(Colors.black.withValues(alpha: .6), ln));
  }

  /// Armario: dos puertas de madera con manijas.
  void _wardrobe(Canvas c, double w, double h) {
    final ln = _line(h);
    const body = Color(0xFF8F6238);
    const door = Color(0xFFA97142);
    const dark = Color(0xFF5E3F22);

    c.drawRRect(_rr(0, 0, w, h, h * .10), _fill(body));
    c.drawRRect(_rr(0, 0, w, h, h * .10), _stroke(dark, ln));
    // Puertas.
    c.drawRRect(_rr(w * .06, h * .08, w * .42, h * .84, h * .06), _fill(door));
    c.drawRRect(_rr(w * .52, h * .08, w * .42, h * .84, h * .06), _fill(door));
    final panel = _stroke(dark.withValues(alpha: .5), ln * .7);
    c.drawRRect(_rr(w * .11, h * .18, w * .32, h * .64, h * .05), panel);
    c.drawRRect(_rr(w * .57, h * .18, w * .32, h * .64, h * .05), panel);
    // Manijas.
    final handle = _fill(const Color(0xFFE8D9A0));
    c.drawCircle(Offset(w * .455, h * .5), ln * 1.6, handle);
    c.drawCircle(Offset(w * .545, h * .5), ln * 1.6, handle);
  }

  /// Caja de cartón: solapas cruzadas y cinta.
  void _box(Canvas c, double w, double h) {
    final ln = _line(h);
    const card = Color(0xFFC9995B);
    const dark = Color(0xFF8F6534);
    const tape = Color(0xFFE4D28F);

    c.drawRRect(_rr(w * .10, h * .10, w * .80, h * .80, h * .06), _fill(card));
    c.drawRRect(
        _rr(w * .10, h * .10, w * .80, h * .80, h * .06), _stroke(dark, ln));
    // Solapas (diagonales hacia el centro).
    final flap = _stroke(dark.withValues(alpha: .7), ln * .8);
    c.drawLine(Offset(w * .10, h * .10), Offset(w * .5, h * .5), flap);
    c.drawLine(Offset(w * .90, h * .10), Offset(w * .5, h * .5), flap);
    c.drawLine(Offset(w * .10, h * .90), Offset(w * .5, h * .5), flap);
    c.drawLine(Offset(w * .90, h * .90), Offset(w * .5, h * .5), flap);
    // Cinta central.
    c.drawRect(Rect.fromLTWH(w * .44, h * .10, w * .12, h * .80), _fill(tape));
    c.drawRect(Rect.fromLTWH(w * .44, h * .10, w * .12, h * .80),
        _stroke(dark.withValues(alpha: .4), ln * .6));
  }

  /// Lavadora: cuerpo blanco, panel de controles y ojo de buey.
  void _washer(Canvas c, double w, double h) {
    final ln = _line(h);
    const body = Color(0xFFDCE3E8);
    const panel = Color(0xFFAEB9C2);
    const ring = Color(0xFF8FA0AC);
    const glass = Color(0xFF5E7686);

    c.drawRRect(_rr(w * .08, h * .06, w * .84, h * .88, h * .10), _fill(body));
    c.drawRRect(_rr(w * .08, h * .06, w * .84, h * .88, h * .10),
        _stroke(ring, ln));
    // Panel superior con perillas.
    c.drawRRect(_rr(w * .12, h * .10, w * .76, h * .16, h * .05), _fill(panel));
    final knob = _fill(Colors.white);
    c.drawCircle(Offset(w * .22, h * .18), ln * 1.6, knob);
    c.drawCircle(Offset(w * .32, h * .18), ln * 1.6, knob);
    // Ojo de buey.
    final cx = w / 2, cy = h * .60;
    final r = math.min(w, h) * .24;
    c.drawCircle(Offset(cx, cy), r, _fill(ring));
    c.drawCircle(Offset(cx, cy), r * .72, _fill(glass));
    c.drawCircle(Offset(cx - r * .2, cy - r * .2), r * .18,
        _fill(Colors.white.withValues(alpha: .35)));
  }

  /// Piano: cuerpo oscuro con teclado a lo largo del borde inferior.
  void _piano(Canvas c, double w, double h) {
    final ln = _line(h);
    const body = Color(0xFF3A3A44);
    const dark = Color(0xFF23232B);

    c.drawRRect(_rr(0, 0, w, h, h * .12), _fill(body));
    c.drawRRect(_rr(0, 0, w, h, h * .12), _stroke(dark, ln));
    // Teclado.
    final keysRect = Rect.fromLTWH(w * .06, h * .58, w * .88, h * .30);
    c.drawRRect(RRect.fromRectAndRadius(keysRect, Radius.circular(h * .05)),
        _fill(Colors.white));
    final sep = _stroke(dark.withValues(alpha: .5), ln * .5);
    const whites = 10;
    for (var i = 1; i < whites; i++) {
      final x = keysRect.left + keysRect.width * i / whites;
      c.drawLine(Offset(x, keysRect.top), Offset(x, keysRect.bottom), sep);
    }
    // Teclas negras.
    final black = _fill(dark);
    for (var i = 0; i < whites - 1; i++) {
      if (i % 7 == 2 || i % 7 == 6) continue;
      final x = keysRect.left + keysRect.width * (i + 1) / whites;
      c.drawRect(
          Rect.fromCenter(
              center: Offset(x, keysRect.top + keysRect.height * .3),
              width: keysRect.width / whites * .5,
              height: keysRect.height * .6),
          black);
    }
  }

  @override
  bool shouldRepaint(covariant FurniturePainter old) => old.type != type;
}
