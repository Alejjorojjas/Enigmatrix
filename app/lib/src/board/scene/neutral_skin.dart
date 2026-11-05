/// Piel "neutra": arte provisional hecho por código. Formas, sombras y
/// degradados sobrios; no imita a ningún juego. Sirve para medir fluidez y
/// sensación al tocar, no para decidir el estilo.
library;

import 'dart:math' as math;
import 'dart:ui' show Brightness;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart';

import 'board_geometry.dart';
import 'palette.dart';
import 'room_labels.dart';
import 'skin.dart';

class NeutralSkin extends BoardSkin {
  NeutralSkin({this.mode = Brightness.dark});

  static const idName = 'neutra';

  @override
  final Brightness mode;

  @override
  String get id => idName;
  @override
  ChromeKind get chrome => ChromeKind.flat;

  // ---- paleta -------------------------------------------------------------------

  static SkinPalette paletteFor(Brightness mode) {
    if (mode == Brightness.light) {
      return SkinPalette(
        mode: mode,
        bg: const Color(0xFFE3E6EA),
        surface: const Color(0xFFF1F3F5),
        surfaceAlt: const Color(0xFFE6E9ED),
        line: const Color(0xFFB6BCC6),
        text: const Color(0xFF1F2229),
        textDim: const Color(0xFF5E6573),
        accent: const Color(0xFF2F6FB5),
        onAccent: const Color(0xFFFFFFFF),
        danger: const Color(0xFFB3412F),
        good: const Color(0xFF2F7449),
        toolActive: const Color(0xFF2F6FB5),
        onToolActive: const Color(0xFFFFFFFF),
        pill: const Color(0xFF2A2D34),
        onPill: const Color(0xFFF1EEE6),
        shadow: const Color(0xFF3A4150),
        paperEdge: const Color(0xFFF1F3F5),
        backdrop: const Color(0xFFCDD2D9),
        backdropLow: const Color(0xFFBCC3CC),
        ink: const Color(0xFF2A2D34),
        light: const Color(0xFFFFE9B8),
        errorTint: const Color(0xFFB3412F),
        wall: const Color(0xFF3A3F4A),
        labelBg: const Color(0xFFF1EEE6),
        labelText: const Color(0xFF22252B),
        characters: _characters,
        portraitBg: _characters,
        confetti: _confetti,
      );
    }
    return SkinPalette(
      mode: mode,
      bg: const Color(0xFF14161B),
      surface: const Color(0xFF1E2128),
      surfaceAlt: const Color(0xFF2A2E37),
      line: const Color(0xFF3A3F4A),
      text: const Color(0xFFF1EEE6),
      textDim: const Color(0xFFA7ACB7),
      accent: const Color(0xFFFFE9B8),
      onAccent: const Color(0xFF2A2D34),
      danger: const Color(0xFFE2634C),
      good: const Color(0xFF7FCB93),
      toolActive: const Color(0xFFFFE9B8),
      onToolActive: const Color(0xFF2A2D34),
      pill: const Color(0xFF0E1014),
      onPill: const Color(0xFFF1EEE6),
      shadow: const Color(0xFF000000),
      paperEdge: const Color(0xFFF1EEE6),
      backdrop: const Color(0xFF1B1E24),
      backdropLow: const Color(0xFF16181D),
      ink: const Color(0xFF2A2D34),
      light: const Color(0xFFFFE9B8),
      errorTint: const Color(0xFFB3412F),
      wall: const Color(0xFF3A3F4A),
      labelBg: const Color(0xFFF1EEE6),
      labelText: const Color(0xFF22252B),
      characters: _characters,
      portraitBg: _characters,
      confetti: _confetti,
    );
  }

  @override
  late final SkinPalette palette = paletteFor(mode);

  @override
  Color get backdrop => palette.backdrop;
  @override
  Color get ink => palette.ink;
  @override
  Color get light => palette.light;
  @override
  Color get errorTint => palette.errorTint;

  static const _confetti = <Color>[
    Color(0xFFF2D58A),
    Color(0xFFE2634C),
    Color(0xFF6FB6D8),
    Color(0xFF8FCB9B),
    Color(0xFFF4EFE4),
  ];

  static const _characters = <Color>[
    Color(0xFFE2634C), // bermellón
    Color(0xFF2F6FB5), // azul
    Color(0xFF3E9A6A), // verde
    Color(0xFFE0A526), // ámbar
    Color(0xFF8A55B8), // violeta
    Color(0xFF1F9AA8), // turquesa
    Color(0xFFD6567F), // rosa
    Color(0xFF5B6575), // pizarra
  ];

  static const _floors = <Color>[
    Color(0xFFD3C7B1), // arena
    Color(0xFFB9C6C4), // gris azulado
    Color(0xFFC8CFB4), // salvia
    Color(0xFFD4BDB3), // arcilla
    Color(0xFFC0BACF), // lavanda
    Color(0xFFCFC9A6), // paja
    Color(0xFFADC1CD), // acero claro
    Color(0xFFD3C5C5), // rosa polvo
  ];

  @override
  Color characterColor(int index) => _characters[index % _characters.length];

  @override
  List<Color> get confettiColors => _confetti;

  // ---- texto con caché ----------------------------------------------------------

  final Map<String, TextPainter> _glyphs = {};

  TextPainter _glyph(String text, double size, Color color,
      {FontWeight weight = FontWeight.w800}) {
    final key = '$text|${size.toStringAsFixed(1)}|${color.toARGB32()}|${weight.value}';
    return _glyphs.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            color: color,
            fontWeight: weight,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  void _drawGlyph(Canvas c, String text, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w800}) {
    final tp = _glyph(text, size, color, weight: weight);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  Color _onColor(Color bg) =>
      bg.computeLuminance() > 0.42 ? const Color(0xFF22252B) : const Color(0xFFFFFFFF);

  // ---- capa fija ----------------------------------------------------------------

  @override
  void paintBackdrop(Canvas canvas, Size size, BoardGeometry g, GameMap map) {
    final n = g.n;
    final cell = g.cell;
    final board = g.board;

    // Fondo con un degradado muy suave.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: mode == Brightness.dark
              ? const [Color(0xFF242932), Color(0xFF16181D)]
              : [palette.backdrop, palette.backdropLow],
        ).createShader(Offset.zero & size),
    );

    // Sombra proyectada del tablero entero.
    final boardR = RRect.fromRectAndRadius(board, Radius.circular(cell * 0.12));
    canvas.drawRRect(
      boardR.shift(Offset(0, cell * 0.14)),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.30),
    );

    // Piso por habitación, con una leve variación de cuadro para dar textura.
    final areaIndex = <String, int>{
      for (var i = 0; i < map.areas.length; i++) map.areas[i].id: i
    };
    canvas.save();
    canvas.clipRRect(boardR);
    for (var i = 0; i < n * n; i++) {
      final r = g.cellRect(i);
      final base = _floors[areaIndex[map.areaIdOf(i)]! % _floors.length];
      final alt = ((g.rowOf(i) + g.colOf(i)) & 1) == 1;
      canvas.drawRect(
        r,
        Paint()
          ..color = alt
              ? Color.lerp(base, const Color(0xFF000000), 0.05)!
              : base,
      );
    }
    // Líneas de cuadrícula finas: la casilla tiene que leerse.
    final grid = Paint()
      ..color = const Color(0x1F000000)
      ..strokeWidth = 1;
    for (var k = 1; k < n; k++) {
      final x = board.left + k * cell;
      final y = board.top + k * cell;
      canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), grid);
      canvas.drawLine(Offset(board.left, y), Offset(board.right, y), grid);
    }

    // Oclusión ambiental: sombra suave del piso pegada a cada pared.
    final aoW = cell * 0.26;
    void ao(Rect rect, Alignment from, Alignment to) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: from,
            end: to,
            colors: const [Color(0x3A000000), Color(0x00000000)],
          ).createShader(rect),
      );
    }

    for (var i = 0; i < n * n; i++) {
      final r = g.cellRect(i);
      final row = g.rowOf(i), col = g.colOf(i);
      final id = map.areaIdOf(i);
      // Vecino de la izquierda / arriba / derecha / abajo.
      if (col == 0 || map.areaIdOf(i - 1) != id) {
        ao(Rect.fromLTWH(r.left, r.top, aoW, cell), Alignment.centerLeft,
            Alignment.centerRight);
      }
      if (col == n - 1 || map.areaIdOf(i + 1) != id) {
        ao(Rect.fromLTWH(r.right - aoW, r.top, aoW, cell),
            Alignment.centerRight, Alignment.centerLeft);
      }
      if (row == 0 || map.areaIdOf(i - n) != id) {
        ao(Rect.fromLTWH(r.left, r.top, cell, aoW), Alignment.topCenter,
            Alignment.bottomCenter);
      }
      if (row == n - 1 || map.areaIdOf(i + n) != id) {
        ao(Rect.fromLTWH(r.left, r.bottom - aoW, cell, aoW),
            Alignment.bottomCenter, Alignment.topCenter);
      }
    }
    canvas.restore();

    // Nombres de habitación (11 px o más, sin montarse).
    for (final l in layoutRoomLabels(g, map,
        (t, fs) => _glyph(t, fs, const Color(0xFF22252B), weight: FontWeight.w700).width)) {
      final pill = RRect.fromRectAndRadius(l.pill, Radius.circular(l.pill.height / 2));
      canvas.drawRRect(pill, Paint()..color = palette.labelBg.withValues(alpha: 0.85));
      _drawGlyph(canvas, l.text, l.pill.center, l.fontSize, palette.labelText,
          weight: FontWeight.w700);
    }

    // Muebles.
    for (final o in map.objects) {
      _paintFurniture(canvas, g, o);
    }

    // Paredes con sombra.
    _paintWalls(canvas, g, map);
  }

  void _paintWalls(Canvas canvas, BoardGeometry g, GameMap map) {
    final n = g.n;
    final cell = g.cell;
    final t = cell * 0.085; // grosor de pared interior

    // Segmentos verticales y horizontales fusionados.
    final vertical = <Rect>[];
    final horizontal = <Rect>[];

    for (var c = 1; c < n; c++) {
      int? runStart;
      for (var r = 0; r <= n; r++) {
        final isWall = r < n &&
            map.areaIdOf(r * n + c - 1) != map.areaIdOf(r * n + c);
        if (isWall && runStart == null) runStart = r;
        if (!isWall && runStart != null) {
          final x = g.board.left + c * cell;
          vertical.add(Rect.fromLTRB(x - t / 2, g.board.top + runStart * cell - t / 2,
              x + t / 2, g.board.top + r * cell + t / 2));
          runStart = null;
        }
      }
    }
    for (var r = 1; r < n; r++) {
      int? runStart;
      for (var c = 0; c <= n; c++) {
        final isWall = c < n &&
            map.areaIdOf((r - 1) * n + c) != map.areaIdOf(r * n + c);
        if (isWall && runStart == null) runStart = c;
        if (!isWall && runStart != null) {
          final y = g.board.top + r * cell;
          horizontal.add(Rect.fromLTRB(g.board.left + runStart * cell - t / 2, y - t / 2,
              g.board.left + c * cell + t / 2, y + t / 2));
          runStart = null;
        }
      }
    }
    final walls = [...vertical, ...horizontal];

    // Sombra proyectada de las paredes (luz desde arriba a la izquierda).
    final shadow = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06);
    for (final w in walls) {
      canvas.drawRect(w.shift(Offset(cell * 0.05, cell * 0.08)), shadow);
    }

    final body = Paint()..color = const Color(0xFF3A3F4A);
    final topLight = Paint()..color = const Color(0xFF666C79);
    for (final w in walls) {
      canvas.drawRRect(RRect.fromRectAndRadius(w, Radius.circular(t * 0.3)), body);
      // Filo claro arriba/izquierda: da volumen.
      final isVertical = w.height > w.width;
      final hl = isVertical
          ? Rect.fromLTWH(w.left, w.top, w.width * 0.35, w.height)
          : Rect.fromLTWH(w.left, w.top, w.width, w.height * 0.35);
      canvas.drawRect(hl, topLight);
    }

    // Marco exterior.
    final ot = cell * 0.13;
    final outer = RRect.fromRectAndRadius(
        g.board.inflate(ot / 2), Radius.circular(cell * 0.14));
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ot
        ..color = const Color(0xFF30343E),
    );
    canvas.drawRRect(
      outer.deflate(ot * 0.32),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ot * 0.28
        ..color = const Color(0xFF5B616E),
    );
  }

  // ---- muebles ------------------------------------------------------------------

  void _paintFurniture(Canvas canvas, BoardGeometry g, MapObject o) {
    final cell = g.cell;
    var rect = g.cellRect(o.cells.first);
    for (final c in o.cells.skip(1)) {
      rect = rect.expandToInclude(g.cellRect(c));
    }
    final r = rect.deflate(cell * 0.11);
    final wide = r.width >= r.height;
    final rad = Radius.circular(cell * 0.10);

    void shadow(Rect rr, {double depth = 1.0}) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rr, rad).shift(Offset(cell * 0.05 * depth, cell * 0.08 * depth)),
        Paint()
          ..color = const Color(0x59000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06 * depth),
      );
    }

    Paint fill(Color c) => Paint()..color = c;
    Paint grad(Rect rr, Color a, Color b) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ).createShader(rr);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x40000000);

    void box(Rect rr, Color a, Color b, {double radiusK = 1}) {
      final rrect = RRect.fromRectAndRadius(rr, Radius.circular(rad.x * radiusK));
      canvas.drawRRect(rrect, grad(rr, a, b));
      canvas.drawRRect(rrect, edge);
    }

    switch (o.type) {
      case ObjectType.alfombra:
        final rr = rect.deflate(cell * 0.06);
        final rrect = RRect.fromRectAndRadius(rr, Radius.circular(cell * 0.12));
        canvas.drawRRect(rrect, fill(const Color(0xFF9A4A45)));
        canvas.drawRRect(rrect.deflate(cell * 0.07),
            Paint()..style = PaintingStyle.stroke..strokeWidth = cell * 0.035..color = const Color(0xFFE6D3A5));
        canvas.drawRRect(rrect.deflate(cell * 0.15),
            Paint()..color = const Color(0xFF7E3834));
      case ObjectType.silla:
        final seat = r.deflate(cell * 0.06);
        shadow(seat);
        box(seat, const Color(0xFFA98159), const Color(0xFF86623F), radiusK: 0.8);
        final back = Rect.fromLTWH(seat.left, seat.top, seat.width, seat.height * 0.26);
        box(back, const Color(0xFF8B6742), const Color(0xFF6F4F31), radiusK: 0.6);
      case ObjectType.sillon:
      case ObjectType.sofa:
        shadow(r);
        box(r, const Color(0xFF5E7A8C), const Color(0xFF455C6C), radiusK: 1.4);
        // Respaldo y brazos.
        final k = cell * 0.17;
        if (wide) {
          box(Rect.fromLTWH(r.left, r.top, r.width, k * 1.1), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          box(Rect.fromLTWH(r.left, r.top, k, r.height), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          box(Rect.fromLTWH(r.right - k, r.top, k, r.height), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          if (r.width > cell * 1.4) {
            canvas.drawLine(Offset(r.center.dx, r.top + k * 1.2),
                Offset(r.center.dx, r.bottom - k * 0.4), edge);
          }
        } else {
          box(Rect.fromLTWH(r.left, r.top, k * 1.1, r.height), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          box(Rect.fromLTWH(r.left, r.top, r.width, k), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          box(Rect.fromLTWH(r.left, r.bottom - k, r.width, k), const Color(0xFF6F8CA0), const Color(0xFF51697A));
          if (r.height > cell * 1.4) {
            canvas.drawLine(Offset(r.left + k * 1.2, r.center.dy),
                Offset(r.right - k * 0.4, r.center.dy), edge);
          }
        }
      case ObjectType.cama:
        shadow(r, depth: 0.8);
        box(r, const Color(0xFFE9E4DA), const Color(0xFFCFC8BA), radiusK: 1.2);
        final blanket = wide
            ? Rect.fromLTWH(r.left + r.width * 0.30, r.top, r.width * 0.70, r.height)
            : Rect.fromLTWH(r.left, r.top + r.height * 0.30, r.width, r.height * 0.70);
        box(blanket, const Color(0xFF6B8EA8), const Color(0xFF527188), radiusK: 1.0);
        final pillow = wide
            ? Rect.fromLTWH(r.left + r.width * 0.05, r.top + r.height * 0.14, r.width * 0.2, r.height * 0.72)
            : Rect.fromLTWH(r.left + r.width * 0.14, r.top + r.height * 0.05, r.width * 0.72, r.height * 0.2);
        box(pillow, const Color(0xFFFFFFFF), const Color(0xFFE6E1D6), radiusK: 1.2);
      case ObjectType.mesa:
        shadow(r, depth: 1.2);
        box(r, const Color(0xFFB48B5E), const Color(0xFF946D45), radiusK: 1.1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.deflate(cell * 0.06), Radius.circular(rad.x * 0.7)),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x33FFFFFF),
        );
      case ObjectType.tv:
        shadow(r);
        box(r, const Color(0xFF2B2F38), const Color(0xFF1B1E24), radiusK: 0.8);
        final screen = r.deflate(cell * 0.07);
        canvas.drawRRect(
          RRect.fromRectAndRadius(screen, Radius.circular(rad.x * 0.5)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F7C93), Color(0xFF1F3340)],
            ).createShader(screen),
        );
      case ObjectType.planta:
      case ObjectType.arbusto:
        final c = r.center;
        final rr = math.min(r.width, r.height) / 2;
        canvas.drawOval(
          Rect.fromCenter(center: c + Offset(rr * 0.25, rr * 0.45), width: rr * 1.7, height: rr * 1.0),
          Paint()
            ..color = const Color(0x59000000)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06),
        );
        canvas.drawCircle(c + Offset(0, rr * 0.45), rr * 0.5, fill(const Color(0xFF8C5A3C)));
        for (final d in const [
          Offset(-0.38, -0.05), Offset(0.38, -0.05), Offset(0, -0.4), Offset(0, 0.05),
        ]) {
          final p = c + d * rr;
          canvas.drawCircle(p, rr * 0.55,
              Paint()..shader = const RadialGradient(
                colors: [Color(0xFF6FB07A), Color(0xFF3F7E52)],
              ).createShader(Rect.fromCircle(center: p, radius: rr * 0.55)));
        }
      case ObjectType.armario:
        shadow(r, depth: 1.3);
        box(r, const Color(0xFF7D6249), const Color(0xFF5B4532), radiusK: 0.6);
        if (wide) {
          canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), edge);
        } else {
          canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), edge);
        }
        for (final s in const [-1.0, 1.0]) {
          final k = wide
              ? Offset(r.center.dx + s * cell * 0.08, r.center.dy)
              : Offset(r.center.dx, r.center.dy + s * cell * 0.08);
          canvas.drawCircle(k, cell * 0.025, fill(const Color(0xFFD9C79A)));
        }
      case ObjectType.caja:
        final b = r.deflate(cell * 0.05);
        shadow(b);
        box(b, const Color(0xFFC9A06A), const Color(0xFFA67F4C), radiusK: 0.5);
        canvas.drawLine(Offset(b.center.dx, b.top), Offset(b.center.dx, b.bottom),
            Paint()..strokeWidth = cell * 0.07..color = const Color(0x66E8D7B0));
      case ObjectType.lavadora:
        shadow(r);
        box(r, const Color(0xFFEDEFF2), const Color(0xFFC8CCD3), radiusK: 0.7);
        final dc = Offset(r.center.dx, r.center.dy + cell * 0.04);
        canvas.drawCircle(dc, r.width * 0.30, fill(const Color(0xFF8EA2B3)));
        canvas.drawCircle(dc, r.width * 0.22, fill(const Color(0xFF51677A)));
      case ObjectType.piano:
        shadow(r, depth: 1.2);
        box(r, const Color(0xFF22252B), const Color(0xFF101216), radiusK: 0.7);
        final keys = wide
            ? Rect.fromLTWH(r.left + r.width * 0.06, r.bottom - r.height * 0.36, r.width * 0.88, r.height * 0.26)
            : Rect.fromLTWH(r.right - r.width * 0.36, r.top + r.height * 0.06, r.width * 0.26, r.height * 0.88);
        canvas.drawRect(keys, fill(const Color(0xFFF1EEE6)));
      case ObjectType.barra:
        shadow(r, depth: 1.2);
        box(r, const Color(0xFF7E5A3F), const Color(0xFF5A3F2A), radiusK: 0.7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.deflate(cell * 0.05), Radius.circular(rad.x * 0.6)),
          Paint()..style = PaintingStyle.stroke..strokeWidth = cell * 0.03..color = const Color(0x55E8C99A),
        );
      case ObjectType.perchero:
        final c = r.center;
        final rr = math.min(r.width, r.height) / 2;
        canvas.drawCircle(c + Offset(rr * 0.1, rr * 0.2), rr * 0.7,
            Paint()..color = const Color(0x59000000)..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06));
        canvas.drawCircle(c, rr * 0.7, fill(const Color(0xFF7D6249)));
        canvas.drawCircle(c, rr * 0.28, fill(const Color(0xFFD9C79A)));
      case ObjectType.banera:
        shadow(r);
        box(r, const Color(0xFFF1F3F5), const Color(0xFFCDD3D8), radiusK: 1.6);
        canvas.drawOval(r.deflate(cell * 0.1), fill(const Color(0xFF86B8CC)));
      case ObjectType.nevera:
        shadow(r);
        box(r, const Color(0xFFB5D8CF), const Color(0xFF8DBBB0), radiusK: 0.8);
        canvas.drawLine(Offset(r.left, r.top + r.height * 0.4),
            Offset(r.right, r.top + r.height * 0.4), edge);
        canvas.drawLine(Offset(r.right - cell * 0.12, r.top + r.height * 0.5),
            Offset(r.right - cell * 0.12, r.top + r.height * 0.75),
            Paint()..strokeWidth = cell * 0.04..color = const Color(0xFF4A5A63));
      case ObjectType.chimenea:
        shadow(r);
        box(r, const Color(0xFF9A9088), const Color(0xFF6E655E), radiusK: 0.6);
        final hearth = Rect.fromLTWH(
            r.left + r.width * 0.2, r.top + r.height * 0.28, r.width * 0.6, r.height * 0.62);
        canvas.drawRRect(
            RRect.fromRectAndRadius(hearth, Radius.circular(cell * 0.1)),
            fill(const Color(0xFF2A1D19)));
        canvas.drawCircle(hearth.center + Offset(0, hearth.height * 0.15), cell * 0.1,
            fill(const Color(0xFFF39A2B)));
    }
  }

  // ---- capa interactiva ---------------------------------------------------------

  @override
  void paintTokenShadow(Canvas canvas, Offset center, double radius,
      {double lift = 0, double alpha = 1}) {
    // Falso desenfoque con tres óvalos concéntricos: barato por cuadro.
    final cx = center.dx + radius * 0.18;
    final cy = center.dy + radius * 0.92 + lift * 0.4;
    final a = (1 - (lift / (radius * 2)).clamp(0.0, 0.6)) * alpha;
    for (var i = 0; i < 3; i++) {
      final k = 1.0 + i * 0.22;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: radius * 1.9 * k,
            height: radius * 0.62 * k),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.12 * a),
      );
    }
  }

  @override
  void paintToken(Canvas canvas, Offset center, double radius, TokenStyle s) {
    final R = radius;
    final base = s.victim ? const Color(0xFFE9E4D8) : characterColor(s.charIndex);
    final dark = Color.lerp(base, const Color(0xFF000000), 0.38)!;
    final lite = Color.lerp(base, const Color(0xFFFFFFFF), 0.30)!;
    final a = s.alpha.clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (a < 1) {
      canvas.saveLayer(
          Rect.fromLTWH(-R * 1.4, -R * 1.4, R * 2.8, R * 2.8),
          Paint()..color = Color.fromRGBO(255, 255, 255, a));
    }

    // Cuerpo (campana) y base.
    final body = Path()
      ..moveTo(-0.95 * R, 0.92 * R)
      ..cubicTo(-0.95 * R, 0.36 * R, -0.46 * R, 0.22 * R, -0.36 * R, -0.08 * R)
      ..lineTo(0.36 * R, -0.08 * R)
      ..cubicTo(0.46 * R, 0.22 * R, 0.95 * R, 0.36 * R, 0.95 * R, 0.92 * R)
      ..close();
    final bodyRect = Rect.fromLTRB(-R, -0.1 * R, R, 0.95 * R);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lite, base, dark],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(bodyRect),
    );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, R * 0.075)
      ..strokeJoin = StrokeJoin.round
      ..color = s.victim ? const Color(0xFF2A2D34) : dark;
    canvas.drawPath(body, outline);

    // Cabeza.
    final headC = Offset(0, -0.52 * R);
    final headR = 0.54 * R;
    final headRect = Rect.fromCircle(center: headC, radius: headR);
    canvas.drawCircle(
      headC,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [lite, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(headRect),
    );
    canvas.drawCircle(headC, headR, outline);

    // Ojos: parpadean (o son cruces en la víctima).
    final eyeDx = headR * 0.40;
    final eyeY = headC.dy + headR * 0.05;
    final eyeInk = Paint()..color = const Color(0xFF22252B);
    if (s.victim) {
      final st = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, R * 0.07)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF22252B);
      final e = headR * 0.15;
      for (final sx in const [-1.0, 1.0]) {
        final c = Offset(sx * eyeDx, eyeY);
        canvas.drawLine(c + Offset(-e, -e), c + Offset(e, e), st);
        canvas.drawLine(c + Offset(-e, e), c + Offset(e, -e), st);
      }
    } else {
      final er = headR * 0.17;
      final open = s.eyeOpen.clamp(0.05, 1.0);
      for (final sx in const [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(sx * eyeDx, eyeY),
              width: er * 2,
              height: er * 2 * open),
          eyeInk,
        );
      }
    }

    // Brillo suave en la cabeza.
    canvas.drawOval(
      Rect.fromCenter(
          center: headC + Offset(-headR * 0.38, -headR * 0.5),
          width: headR * 0.55,
          height: headR * 0.32),
      Paint()..color = const Color(0x40FFFFFF),
    );

    // Inicial en el pecho: letra, nunca solo color.
    _drawGlyph(canvas, s.initial, Offset(0, 0.52 * R), R * 0.74,
        s.victim ? const Color(0xFF22252B) : _onColor(base));

    if (a < 1) canvas.restore();
    canvas.restore();
  }

  @override
  void paintCandidate(Canvas canvas, Offset center, double size, TokenStyle s,
      double alpha) {
    final base = characterColor(s.charIndex);
    final r = size / 2;
    final a = alpha.clamp(0.0, 1.0);
    canvas.drawCircle(
        center + Offset(0, r * 0.12), r, Paint()..color = Color.fromRGBO(0, 0, 0, 0.18 * a));
    canvas.drawCircle(center, r,
        Paint()..color = base.withValues(alpha: 0.92 * a));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.fromRGBO(255, 255, 255, 0.7 * a),
    );
    _drawGlyph(canvas, s.initial, center, size * 0.62,
        _onColor(base).withValues(alpha: a));
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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell.width * 0.055
      ..color = ink.withValues(alpha: (automatic ? 0.42 : 0.65) * alpha.clamp(0.0, 1.0));
    // Primer trazo de 0 a 0,5 y segundo de 0,5 a 1: se "dibuja" a mano.
    final p1 = (p / 0.5).clamp(0.0, 1.0);
    final p2 = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
    canvas.drawLine(a, Offset.lerp(a, b, p1)!, paint);
    if (p2 > 0) canvas.drawLine(c, Offset.lerp(c, d, p2)!, paint);
  }

  @override
  void paintCellGlow(Canvas canvas, Rect cell, double strength) {
    if (strength <= 0) return;
    canvas.drawRect(
      cell.deflate(1),
      Paint()..color = light.withValues(alpha: (strength * 0.5).clamp(0.0, 1.0)),
    );
  }

  @override
  void paintHoldRing(Canvas canvas, Offset center, double radius,
      double progress, double alpha) {
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.16
        ..color = Color.fromRGBO(0, 0, 0, 0.18 * alpha),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.16
        ..color = const Color(0xFFFFF3CF).withValues(alpha: alpha),
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
    canvas.drawPath(
      path.shift(Offset(0, radius * 0.08)),
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.3 * alpha),
    );
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
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF9A6A12).withValues(alpha: alpha),
    );
  }

  // ---- bandeja ------------------------------------------------------------------

  @override
  void paintPortrait(Canvas canvas, Rect frame, TokenStyle s,
      {bool selected = false}) {
    final rr = RRect.fromRectAndRadius(frame, Radius.circular(frame.width * 0.22));
    final base = s.victim ? const Color(0xFFE9E4D8) : characterColor(s.charIndex);
    canvas.drawRRect(rr, Paint()..color = base.withValues(alpha: 0.28));
    canvas.save();
    canvas.clipRRect(rr);
    paintToken(canvas, frame.center, frame.width * 0.34, s);
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3 : 1.2
        ..color = selected ? palette.accent : palette.line,
    );
  }
}
