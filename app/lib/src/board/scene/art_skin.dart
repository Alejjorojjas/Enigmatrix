/// Base común de las pieles con arte propio ("Ilustrada" y "Papel"): fichas
/// con retrato, notas, X, muebles, etiquetas de habitación y estrella. Cada
/// piel agrega su fondo (pisos, paredes o recortes) y su manera de pintar las
/// piezas ([PartRenderer]); los datos y la interacción son los mismos.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart'
    show Alignment, FontWeight, LinearGradient, TextDirection, TextPainter, TextSpan, TextStyle;

import 'art_parts.dart';
import 'board_geometry.dart';
import 'furniture_art.dart';
import 'palette.dart';
import 'portrait_art.dart';
import 'room_labels.dart';
import 'skin.dart';

abstract class ArtSkin extends BoardSkin {
  ArtSkin(this.mode);

  @override
  final Brightness mode;

  bool get paper => chrome == ChromeKind.paper;

  /// Pinta los muebles y los marcos de los retratos.
  PartRenderer get furnitureRenderer;
  PartRenderer get portraitRenderer;

  @override
  double get tokenScale => 1.2;

  // ---- paleta --------------------------------------------------------------------

  @override
  Color get backdrop => palette.backdrop;
  @override
  Color get ink => palette.ink;
  @override
  Color get light => palette.light;
  @override
  Color get errorTint => palette.errorTint;
  @override
  Color characterColor(int index) =>
      palette.characters[index % palette.characters.length];
  @override
  List<Color> get confettiColors => palette.confetti;

  Color _portraitBg(TokenStyle s) => s.victim
      ? (palette.isDark ? const Color(0xFF6E757D) : const Color(0xFF9AA1A9))
      : palette.portraitBg[s.charIndex % palette.portraitBg.length];

  /// Contorno oscuro de la piel.
  Color get outline => palette.wall;

  Color onColor(Color bg) => bg.computeLuminance() > 0.42
      ? const Color(0xFF22252B)
      : const Color(0xFFFFFFFF);

  // ---- recortes de papel ---------------------------------------------------------

  /// Giro pequeño (hasta +-1,5 grados) y siempre el mismo para una misma
  /// clave: los recortes de papel nunca quedan perfectamente derechos.
  static double cutoutTilt(String key, {double maxDegrees = 1.5}) {
    var h = 2166136261; // FNV-1a y una mezcla final para repartir bien
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0xffffffff;
    }
    h ^= h >> 15;
    h = (h * 2246822519) & 0xffffffff;
    h ^= h >> 13;
    final u = (h % 2001) / 1000.0 - 1.0; // -1 a 1
    return u * maxDegrees * math.pi / 180;
  }

  // ---- texto con caché -----------------------------------------------------------

  final Map<String, TextPainter> _glyphs = {};

  TextPainter glyph(String text, double size, Color color,
      {FontWeight weight = FontWeight.w800}) {
    final key =
        '$text|${size.toStringAsFixed(1)}|${color.toARGB32()}|${weight.value}';
    return _glyphs.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size, color: color, fontWeight: weight, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void drawGlyph(Canvas c, String text, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w800}) {
    final tp = glyph(text, size, color, weight: weight);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ---- retratos ------------------------------------------------------------------

  final Map<String, List<Part>> _bustCache = {};

  List<Part> _bust(TokenStyle s) {
    final open = (s.eyeOpen.clamp(0.0, 1.0) * 4).round() / 4;
    final key = '${s.charIndex}|${s.female}|${s.victim}|$open';
    return _bustCache.putIfAbsent(
        key,
        () => buildBust(
              PortraitSpec.forCharacter(s.charIndex, female: s.female),
              victim: s.victim,
              eyeOpen: open,
              mode: mode,
            ));
  }

  @override
  void paintPortrait(Canvas canvas, Rect frame, TokenStyle s,
      {bool selected = false}) {
    final rr = RRect.fromRectAndRadius(frame, Radius.circular(frame.width * 0.24));
    final bg = _portraitBg(s);
    final depth = frame.width * 0.055;
    if (paper) {
      canvas.drawRRect(rr.shift(Offset(0, depth)), Paint()..color = shadeColor(bg, 0.4));
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = frame.width * 0.07
            ..color = palette.paperEdge);
    }
    canvas.drawRRect(rr, Paint()..color = bg);
    canvas.save();
    canvas.clipRRect(rr);
    if (paper) {
      canvas.save();
      canvas.translate(frame.left, frame.top);
      paintFibers(canvas, Offset.zero & frame.size, 3 + s.charIndex,
          const Color(0x1FFFFFFF),
          count: 26, len: frame.width * 0.2, width: 0.8);
      canvas.restore();
    }
    canvas.translate(frame.center.dx, frame.center.dy + frame.height * 0.07);
    final unit = frame.width * 0.52;
    canvas.scale(unit);
    portraitRenderer.paint(canvas, _bust(s), unit: unit);
    canvas.restore();
    if (!paper) {
      canvas.drawRRect(
          rr.deflate(frame.width * 0.02),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = frame.width * 0.05
            ..color = outline);
    }
    if (selected) {
      canvas.drawRRect(
          rr.inflate(frame.width * 0.04),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = frame.width * 0.07
            ..color = palette.accent);
    }
  }

  // ---- ficha en el tablero (medallón con retrato) -------------------------------

  @override
  void paintTokenShadow(Canvas canvas, Offset center, double radius,
      {double lift = 0, double alpha = 1}) {
    final cx = center.dx + radius * 0.14;
    final cy = center.dy + radius * 1.0 + lift * 0.4;
    final a = (1 - (lift / (radius * 2)).clamp(0.0, 0.6)) * alpha;
    final dark = palette.isDark ? 0.34 : 0.17;
    for (var i = 0; i < 3; i++) {
      final k = 1.0 + i * 0.22;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy), width: radius * 1.9 * k, height: radius * 0.58 * k),
        Paint()..color = Color.fromRGBO(20, 10, 4, dark * a),
      );
    }
  }

  @override
  void paintToken(Canvas canvas, Offset center, double radius, TokenStyle s) {
    final R = radius;
    final a = s.alpha.clamp(0.0, 1.0);
    final bg = _portraitBg(s);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (paper) canvas.rotate(cutoutTilt('ficha${s.charIndex}'));
    if (a < 1) {
      canvas.saveLayer(Rect.fromLTWH(-R * 1.6, -R * 1.6, R * 3.2, R * 3.2),
          Paint()..color = Color.fromRGBO(255, 255, 255, a));
    }
    if (paper) {
      canvas.drawCircle(Offset(0, R * 0.16), R, Paint()..color = shadeColor(bg, 0.5));
      canvas.drawCircle(
          Offset.zero,
          R,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = R * 0.26
            ..color = palette.paperEdge);
    }
    canvas.drawCircle(Offset.zero, R, Paint()..color = bg);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: R)));
    canvas.translate(0, R * 0.08);
    canvas.scale(R);
    portraitRenderer.paint(canvas, _bust(s), unit: R);
    canvas.restore();
    if (!paper) {
      canvas.drawCircle(
          Offset.zero,
          R * 0.96,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = R * 0.11
            ..color = outline);
    }
    // Insignia con la inicial: la ficha nunca se distingue solo por color.
    final bc = Offset(R * 0.74, R * 0.78);
    final br = R * 0.36;
    final badge = s.victim ? const Color(0xFF59616D) : characterColor(s.charIndex);
    if (paper) {
      canvas.drawCircle(bc + Offset(0, br * 0.18), br, Paint()..color = shadeColor(badge, 0.4));
      canvas.drawCircle(
          bc,
          br,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = br * 0.34
            ..color = palette.paperEdge);
    }
    canvas.drawCircle(bc, br, Paint()..color = badge);
    if (!paper) {
      canvas.drawCircle(
          bc,
          br,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = br * 0.24
            ..color = outline);
    }
    drawGlyph(canvas, s.initial, bc, br * 1.15 * initialScale(s.initial), onColor(badge));
    if (a < 1) canvas.restore();
    canvas.restore();
  }

  // ---- notas, X, destellos --------------------------------------------------------

  @override
  void paintCandidate(Canvas canvas, Offset center, double size, TokenStyle s,
      double alpha) {
    final base = characterColor(s.charIndex);
    final r = size / 2;
    final a = alpha.clamp(0.0, 1.0);
    if (paper) {
      canvas.drawCircle(center + Offset(0, r * 0.16), r,
          Paint()..color = shadeColor(base, 0.4).withValues(alpha: a));
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.3
            ..color = palette.paperEdge.withValues(alpha: a));
    } else {
      canvas.drawCircle(center + Offset(0, r * 0.12), r,
          Paint()..color = Color.fromRGBO(20, 10, 4, 0.22 * a));
    }
    canvas.drawCircle(center, r, Paint()..color = base.withValues(alpha: a));
    if (!paper) {
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, r * 0.16)
            ..color = outline.withValues(alpha: 0.9 * a));
    }
    drawGlyph(canvas, s.initial, center, size * 0.62 * initialScale(s.initial), onColor(base).withValues(alpha: a));
  }

  @override
  void paintCross(Canvas canvas, Rect cell, double progress,
      {bool automatic = true, double alpha = 1}) {
    if (progress <= 0 || alpha <= 0) return;
    final p = progress.clamp(0.0, 1.0);
    final inset = cell.width * 0.30;
    final a = Offset(cell.left + inset, cell.top + inset);
    final b = Offset(cell.right - inset, cell.bottom - inset);
    final c = Offset(cell.right - inset, cell.top + inset);
    final d = Offset(cell.left + inset, cell.bottom - inset);
    final k = (automatic ? 0.5 : 0.85) * alpha.clamp(0.0, 1.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell.width * (automatic ? 0.055 : 0.07)
      ..color = ink.withValues(alpha: k);
    final p1 = (p / 0.5).clamp(0.0, 1.0);
    final p2 = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
    canvas.drawLine(a, Offset.lerp(a, b, p1)!, paint);
    if (p2 > 0) canvas.drawLine(c, Offset.lerp(c, d, p2)!, paint);
  }

  @override
  void paintCellGlow(Canvas canvas, Rect cell, double strength) {
    if (strength <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cell.deflate(1), Radius.circular(cell.width * 0.08)),
      Paint()..color = light.withValues(alpha: (strength * 0.5).clamp(0.0, 1.0)),
    );
  }

  @override
  void paintHoldRing(Canvas canvas, Offset center, double radius, double progress,
      double alpha) {
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18
        ..color = Color.fromRGBO(20, 10, 4, 0.22 * alpha),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.18
        ..color = palette.accent.withValues(alpha: alpha),
    );
  }

  @override
  void paintStar(Canvas canvas, Offset center, double radius, double alpha) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? radius : radius * 0.46;
      final p = Offset(center.dx + math.cos(ang) * rr, center.dy + math.sin(ang) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawPath(path.shift(Offset(0, radius * 0.1)),
        Paint()..color = Color.fromRGBO(20, 10, 4, 0.32 * alpha));
    if (paper) {
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.22
            ..strokeJoin = StrokeJoin.round
            ..color = palette.paperEdge.withValues(alpha: alpha));
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFE27A).withValues(alpha: alpha),
            const Color(0xFFE5A92B).withValues(alpha: alpha),
          ],
        ).createShader(rect),
    );
    if (!paper) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.1
          ..strokeJoin = StrokeJoin.round
          ..color = outline.withValues(alpha: alpha),
      );
    }
  }

  // ---- utilidades de fondo -------------------------------------------------------

  /// Unión de las casillas de una habitación (contorno limpio, sin las
  /// líneas internas entre casillas).
  Path roomPath(BoardGeometry g, Area a) {
    var path = Path();
    for (final c in a.cells) {
      path = Path.combine(PathOperation.union, path, Path()..addRect(g.cellRect(c)));
    }
    return path;
  }

  /// Rectángulo que contiene a la habitación, alineado a la cuadrícula.
  Rect roomBounds(BoardGeometry g, Area a) {
    var r = g.cellRect(a.cells.first);
    for (final c in a.cells.skip(1)) {
      r = r.expandToInclude(g.cellRect(c));
    }
    return r;
  }

  /// Rótulos de las habitaciones ya colocados (11 px o más, dentro de casillas
  /// libres de su habitación, abreviados si no caben).
  List<RoomLabel> roomLabels(BoardGeometry g, GameMap map) => layoutRoomLabels(
      g,
      map,
      (text, fs) => glyph(text, fs, palette.labelText, weight: FontWeight.w800).width);

  /// Pinta el nombre de cada habitación en una pastilla.
  void paintRoomLabels(Canvas canvas, BoardGeometry g, GameMap map) {
    for (final l in roomLabels(g, map)) {
      final tp = glyph(l.text, l.fontSize, palette.labelText, weight: FontWeight.w800);
      final pill = RRect.fromRectAndRadius(l.pill, Radius.circular(l.pill.height / 2));
      if (paper) {
        canvas.drawRRect(
            pill.shift(const Offset(0, 2.2)), Paint()..color = const Color(0x66000000));
        canvas.drawRRect(
            pill,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6
              ..color = palette.paperEdge);
      } else {
        canvas.drawRRect(
            pill.shift(const Offset(0, 1.5)),
            Paint()
              ..color = const Color(0x44000000)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
      }
      canvas.drawRRect(pill, Paint()..color = palette.labelBg);
      if (!paper) {
        canvas.drawRRect(
            pill,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1
              ..color = outline.withValues(alpha: 0.55));
      }
      tp.paint(canvas, l.pill.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// Un mueble, con su sombra proyectada.
  void paintFurniture(Canvas canvas, BoardGeometry g, MapObject o) {
    final cell = g.cell;
    var rect = g.cellRect(o.cells.first);
    for (final c in o.cells.skip(1)) {
      rect = rect.expandToInclude(g.cellRect(c));
    }
    final isRug = o.type == ObjectType.alfombra;
    final r = rect.deflate(cell * (isRug ? 0.06 : 0.11));
    final vertical = r.height > r.width + 0.5;
    final lw = (vertical ? r.height : r.width) / cell;
    final lh = (vertical ? r.width : r.height) / cell;
    final model = buildFurniture(o.type, lw, lh, mode);

    final theta = vertical ? (rotatesClockwise(o.type) ? math.pi / 2 : -math.pi / 2) : 0.0;
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    // Recorte de papel: un pequeño giro al azar (+-1,5 grados).
    if (paper) canvas.rotate(cutoutTilt(o.id));
    canvas.rotate(theta);
    canvas.translate(-lw * cell / 2, -lh * cell / 2);
    canvas.scale(cell);

    // Sombra: luz arriba a la izquierda, siempre hacia abajo y a la derecha en
    // pantalla (se convierte al giro de la pieza).
    if (model.shadow > 0) {
      const dx = 0.05, dy = 0.085;
      final lx = dx * math.cos(theta) + dy * math.sin(theta);
      final ly = -dx * math.sin(theta) + dy * math.cos(theta);
      final dark = palette.isDark ? 0.5 : 0.30;
      final shadow = Paint()
        ..color = Color.fromRGBO(30, 15, 6, dark * model.shadow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, paper ? 0.035 : 0.05);
      for (final p in model.silhouettes) {
        canvas.drawPath(p.shift(Offset(lx, ly)), shadow);
      }
    }
    furnitureRenderer.paint(canvas, model.parts, unit: cell, rotation: theta);
    canvas.restore();
  }
}
