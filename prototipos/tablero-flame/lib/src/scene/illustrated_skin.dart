/// Piel "Ilustrada": muebles vistos desde arriba con contorno oscuro, color
/// base, luz, sombreado y sombra proyectada; un piso distinto por habitación
/// (madera, piedra, baldosa, alfombra); paredes gruesas y oscuras con el
/// nombre de cada habitación en una pastilla; y retratos provisionales en
/// marcos redondeados. Todo se dibuja por código; la paleta es propia, cálida
/// y menos blanca que un blanco de pantalla (claro) o profunda sin llegar al
/// negro (oscuro).
library;

import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import 'art_parts.dart';
import 'art_skin.dart';
import 'board_geometry.dart';
import 'floors.dart';
import 'palette.dart';

Color _dim(Color c, double k) => Color.lerp(c, const Color(0xFF000000), k)!;

class IllustratedSkin extends ArtSkin {
  IllustratedSkin({Brightness mode = Brightness.light}) : super(mode);

  static const idName = 'ilustrada';

  static const _chars = <Color>[
    Color(0xFF3E8A67), Color(0xFFC0603F), Color(0xFF3F93A0), Color(0xFFB98B2F),
    Color(0xFFA14F83), Color(0xFF5877B8), Color(0xFFC9738A), Color(0xFF6D7A8A),
  ];
  static const _bgs = <Color>[
    Color(0xFF4F9877), Color(0xFFCE7152), Color(0xFF59A3AE), Color(0xFFC9A04A),
    Color(0xFFB5679A), Color(0xFF6B89C8), Color(0xFFD48599), Color(0xFF7E8B9B),
  ];
  static const _confetti = <Color>[
    Color(0xFFF2C46B), Color(0xFFD2602B), Color(0xFF5FA9B8), Color(0xFF7DB88A),
    Color(0xFFF6ECD8),
  ];

  static SkinPalette paletteFor(Brightness mode) {
    if (mode == Brightness.light) {
      return SkinPalette(
        mode: mode,
        bg: const Color(0xFFE9DDC9),
        surface: const Color(0xFFF5ECDC),
        surfaceAlt: const Color(0xFFEADFCA),
        line: const Color(0xFF3A2D26),
        text: const Color(0xFF2A201B),
        textDim: const Color(0xFF75665A),
        accent: const Color(0xFFD2602B),
        onAccent: const Color(0xFFFFF4E6),
        danger: const Color(0xFFB5402E),
        good: const Color(0xFF3D8558),
        toolActive: const Color(0xFF2A201B),
        onToolActive: const Color(0xFFF5ECDC),
        pill: const Color(0xFF2A201B),
        onPill: const Color(0xFFF5ECDC),
        shadow: const Color(0xFF5A4636),
        paperEdge: const Color(0xFFFBF5E8),
        backdrop: const Color(0xFFDACCB4),
        backdropLow: const Color(0xFFCDBDA2),
        ink: const Color(0xFF3A2D26),
        light: const Color(0xFFFFE0A3),
        errorTint: const Color(0xFFB5402E),
        wall: const Color(0xFF3A2D26),
        labelBg: const Color(0xFFFBF3E3),
        labelText: const Color(0xFF3A2D26),
        characters: _chars,
        portraitBg: _bgs,
        confetti: _confetti,
      );
    }
    return SkinPalette(
      mode: mode,
      bg: const Color(0xFF1F1A17),
      surface: const Color(0xFF2C2521),
      surfaceAlt: const Color(0xFF37302A),
      line: const Color(0xFF54483F),
      text: const Color(0xFFF0E4D0),
      textDim: const Color(0xFFB3A391),
      accent: const Color(0xFFEE8F55),
      onAccent: const Color(0xFF2A1A10),
      danger: const Color(0xFFE2705A),
      good: const Color(0xFF7FC592),
      toolActive: const Color(0xFFF0E4D0),
      onToolActive: const Color(0xFF2A201B),
      pill: const Color(0xFF120E0C),
      onPill: const Color(0xFFF0E4D0),
      shadow: const Color(0xFF000000),
      paperEdge: const Color(0xFFD8CBB4),
      backdrop: const Color(0xFF2A221D),
      backdropLow: const Color(0xFF1B1612),
      ink: const Color(0xFFF3E7D2),
      light: const Color(0xFFFFD9A0),
      errorTint: const Color(0xFFC9503B),
      wall: const Color(0xFF130E0B),
      labelBg: const Color(0xFFE8DCC4),
      labelText: const Color(0xFF2A201B),
      characters: [for (final c in _chars) _dim(c, 0.14)],
      portraitBg: [for (final c in _bgs) _dim(c, 0.16)],
      confetti: _confetti,
    );
  }

  @override
  String get id => idName;
  @override
  String get displayName => 'Ilustrada';
  @override
  ChromeKind get chrome => ChromeKind.ink;
  @override
  late final SkinPalette palette = paletteFor(mode);

  @override
  late final PartRenderer furnitureRenderer = InkRenderer(outline: palette.wall, outlineWidth: 0.045);
  @override
  late final PartRenderer portraitRenderer = InkRenderer(outline: palette.wall, outlineWidth: 0.07);

  // ---- fondo ---------------------------------------------------------------------

  @override
  void paintBackdrop(Canvas canvas, Size size, BoardGeometry g, GameMap map) {
    final n = g.n;
    final cell = g.cell;
    final board = g.board;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backdrop, palette.backdropLow],
        ).createShader(Offset.zero & size),
    );

    final boardR = RRect.fromRectAndRadius(board, Radius.circular(cell * 0.12));
    canvas.drawRRect(
      boardR.shift(Offset(0, cell * 0.12)),
      Paint()
        ..color = Color.fromRGBO(30, 15, 6, palette.isDark ? 0.55 : 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.26),
    );

    canvas.save();
    canvas.clipRRect(boardR);

    // Pisos: uno distinto por habitación.
    final used = <FloorKind, int>{};
    for (var i = 0; i < map.areas.length; i++) {
      final a = map.areas[i];
      final kind = floorKindFor(a.nameEs, i);
      final variant = used[kind] ?? 0;
      used[kind] = variant + 1;
      paintFloor(
        canvas,
        kind: kind,
        clip: roomPath(g, a),
        bounds: roomBounds(g, a),
        cell: cell,
        base: floorTone(kind, variant, mode),
        mode: mode,
        seed: 31 + i * 17,
      );
    }

    // Cuadrícula fina: cada casilla tiene que leerse.
    final grid = Paint()
      ..color = Color.fromRGBO(30, 15, 6, palette.isDark ? 0.32 : 0.16)
      ..strokeWidth = 1;
    for (var k = 1; k < n; k++) {
      final x = board.left + k * cell;
      final y = board.top + k * cell;
      canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), grid);
      canvas.drawLine(Offset(board.left, y), Offset(board.right, y), grid);
    }

    // Sombra suave del piso pegada a cada pared.
    final aoW = cell * 0.22;
    void ao(Rect rect, Alignment from, Alignment to) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: from,
            end: to,
            colors: [
              Color.fromRGBO(30, 15, 6, palette.isDark ? 0.34 : 0.22),
              const Color(0x00000000)
            ],
          ).createShader(rect),
      );
    }

    for (var i = 0; i < n * n; i++) {
      final r = g.cellRect(i);
      final row = g.rowOf(i), col = g.colOf(i);
      final id = map.areaIdOf(i);
      if (col == 0 || map.areaIdOf(i - 1) != id) {
        ao(Rect.fromLTWH(r.left, r.top, aoW, cell), Alignment.centerLeft, Alignment.centerRight);
      }
      if (col == n - 1 || map.areaIdOf(i + 1) != id) {
        ao(Rect.fromLTWH(r.right - aoW, r.top, aoW, cell), Alignment.centerRight, Alignment.centerLeft);
      }
      if (row == 0 || map.areaIdOf(i - n) != id) {
        ao(Rect.fromLTWH(r.left, r.top, cell, aoW), Alignment.topCenter, Alignment.bottomCenter);
      }
      if (row == n - 1 || map.areaIdOf(i + n) != id) {
        ao(Rect.fromLTWH(r.left, r.bottom - aoW, cell, aoW), Alignment.bottomCenter, Alignment.topCenter);
      }
    }
    canvas.restore();

    // Muebles.
    for (final o in map.objects) {
      paintFurniture(canvas, g, o);
    }

    _paintWalls(canvas, g, map);

    // Nombres de habitación.
    paintRoomLabels(canvas, g, map);
  }

  void _paintWalls(Canvas canvas, BoardGeometry g, GameMap map) {
    final n = g.n;
    final cell = g.cell;
    final t = cell * 0.095;
    final walls = <Rect>[];

    for (var c = 1; c < n; c++) {
      int? runStart;
      for (var r = 0; r <= n; r++) {
        final isWall = r < n && map.areaIdOf(r * n + c - 1) != map.areaIdOf(r * n + c);
        if (isWall && runStart == null) runStart = r;
        if (!isWall && runStart != null) {
          final x = g.board.left + c * cell;
          walls.add(Rect.fromLTRB(x - t / 2, g.board.top + runStart * cell - t / 2,
              x + t / 2, g.board.top + r * cell + t / 2));
          runStart = null;
        }
      }
    }
    for (var r = 1; r < n; r++) {
      int? runStart;
      for (var c = 0; c <= n; c++) {
        final isWall = c < n && map.areaIdOf((r - 1) * n + c) != map.areaIdOf(r * n + c);
        if (isWall && runStart == null) runStart = c;
        if (!isWall && runStart != null) {
          final y = g.board.top + r * cell;
          walls.add(Rect.fromLTRB(g.board.left + runStart * cell - t / 2, y - t / 2,
              g.board.left + c * cell + t / 2, y + t / 2));
          runStart = null;
        }
      }
    }

    final shadow = Paint()
      ..color = Color.fromRGBO(30, 15, 6, palette.isDark ? 0.55 : 0.38)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.05);
    for (final w in walls) {
      canvas.drawRect(w.shift(Offset(cell * 0.04, cell * 0.07)), shadow);
    }
    final body = Paint()..color = palette.wall;
    final hi = Paint()..color = Color.lerp(palette.wall, const Color(0xFFFFFFFF), 0.16)!;
    for (final w in walls) {
      canvas.drawRRect(RRect.fromRectAndRadius(w, Radius.circular(t * 0.3)), body);
      final vertical = w.height > w.width;
      canvas.drawRect(
          vertical
              ? Rect.fromLTWH(w.left + w.width * 0.12, w.top + t * 0.3, w.width * 0.26, w.height - t * 0.6)
              : Rect.fromLTWH(w.left + t * 0.3, w.top + w.height * 0.12, w.width - t * 0.6, w.height * 0.26),
          hi);
    }

    // Marco exterior grueso.
    final ot = cell * 0.15;
    final outer = RRect.fromRectAndRadius(g.board.inflate(ot / 2), Radius.circular(cell * 0.15));
    canvas.drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ot
          ..color = palette.wall);
    canvas.drawRRect(
        outer.deflate(ot * 0.3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ot * 0.2
          ..color = Color.lerp(palette.wall, const Color(0xFFFFFFFF), 0.14)!);
  }
}
