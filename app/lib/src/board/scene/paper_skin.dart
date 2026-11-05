/// Piel "Papel": papel recortado tipo maqueta. Las habitaciones, los muebles
/// y los retratos son recortes con grosor (una capa inferior más oscura
/// desplazada hacia abajo), un borde blanco de recorte, una sombra suave y una
/// textura de fibra procedural. Luz cálida con viñeta. Usa los mismos datos y
/// la misma interacción que la piel Ilustrada.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart' show Alignment, LinearGradient, RadialGradient;

import 'art_parts.dart';
import 'art_skin.dart';
import 'board_geometry.dart';
import 'floors.dart';
import 'paper_edges.dart';
import 'paper_floors.dart';
import 'palette.dart';

Color _dim(Color c, double k) => Color.lerp(c, const Color(0xFF000000), k)!;

class PaperSkin extends ArtSkin {
  PaperSkin({Brightness mode = Brightness.light}) : super(mode);

  static const idName = 'papel';

  /// Grosor visible del papel (la capa más oscura debajo de cada pieza), en
  /// píxeles: de 2 a 3 px aunque cambie el tamaño de la casilla.
  static double pieceDepth(double cell) => (cell * 0.07).clamp(2.6, 3.2).toDouble();

  static const _chars = <Color>[
    Color(0xFF5C9E80), Color(0xFFD27A58), Color(0xFF63A8B2), Color(0xFFD2A64A),
    Color(0xFFB6709F), Color(0xFF7B97CF), Color(0xFFD68A9E), Color(0xFF8793A1),
  ];
  static const _confetti = <Color>[
    Color(0xFFF2D58A), Color(0xFFD27A58), Color(0xFF63A8B2), Color(0xFF8FCB9B),
    Color(0xFFFBF5E8),
  ];

  static SkinPalette paletteFor(Brightness mode) {
    if (mode == Brightness.light) {
      return SkinPalette(
        mode: mode,
        bg: const Color(0xFFDCC8A2),
        surface: const Color(0xFFF2E8D3),
        surfaceAlt: const Color(0xFFE8DCC4),
        line: const Color(0xFF8C7A62),
        text: const Color(0xFF2D241D),
        textDim: const Color(0xFF76675A),
        // Verde azulado algo más hondo: con texto claro da 4,6:1 o más (AA).
        accent: const Color(0xFF287770),
        onAccent: const Color(0xFFF6F0E2),
        danger: const Color(0xFFB5402E),
        good: const Color(0xFF35754D),
        toolActive: const Color(0xFF287770),
        onToolActive: const Color(0xFFF6F0E2),
        pill: const Color(0xFF3A2F27),
        onPill: const Color(0xFFF2E8D3),
        shadow: const Color(0xFF6A5640),
        paperEdge: const Color(0xFFFCF8EE),
        backdrop: const Color(0xFFC39E68),
        backdropLow: const Color(0xFFB08A55),
        ink: const Color(0xFF3A2F27),
        light: const Color(0xFFFFE3AE),
        errorTint: const Color(0xFFB5402E),
        wall: const Color(0xFF3A2F27),
        labelBg: const Color(0xFFFCF6E8),
        labelText: const Color(0xFF3A2F27),
        characters: _chars,
        portraitBg: _chars,
        confetti: _confetti,
      );
    }
    return SkinPalette(
      mode: mode,
      bg: const Color(0xFF2A2420),
      surface: const Color(0xFF3A322C),
      surfaceAlt: const Color(0xFF453C35),
      line: const Color(0xFF5C5048),
      text: const Color(0xFFF0E5D2),
      textDim: const Color(0xFFB8A998),
      accent: const Color(0xFF52B3AA),
      onAccent: const Color(0xFF10302D),
      danger: const Color(0xFFE2705A),
      good: const Color(0xFF7FC592),
      toolActive: const Color(0xFF52B3AA),
      onToolActive: const Color(0xFF10302D),
      pill: const Color(0xFF17120F),
      onPill: const Color(0xFFF0E5D2),
      shadow: const Color(0xFF000000),
      paperEdge: const Color(0xFFC9BCA6),
      backdrop: const Color(0xFF5C4631),
      backdropLow: const Color(0xFF45331F),
      ink: const Color(0xFFF3E7D2),
      light: const Color(0xFFFFD9A0),
      errorTint: const Color(0xFFC9503B),
      wall: const Color(0xFF17120F),
      labelBg: const Color(0xFFE5D8C0),
      labelText: const Color(0xFF2D241D),
      characters: [for (final c in _chars) _dim(c, 0.16)],
      portraitBg: [for (final c in _chars) _dim(c, 0.18)],
      confetti: _confetti,
    );
  }

  @override
  String get id => idName;
  @override
  String get displayName => 'Papel';
  @override
  ChromeKind get chrome => ChromeKind.paper;
  @override
  late final SkinPalette palette = paletteFor(mode);

  @override
  late final PartRenderer furnitureRenderer = PaperRenderer(
    edge: palette.paperEdge,
    depth: 0.07,
    border: 0.05,
    fibers: 16,
    seed: 11,
    fiberColor: const Color(0x55FFFFFF),
  );
  @override
  late final PartRenderer portraitRenderer = PaperRenderer(
    edge: palette.paperEdge,
    depth: 0.06,
    border: 0.0,
    fibers: 0,
    seed: 5,
  );

  // ---- fondo ---------------------------------------------------------------------

  @override
  void paintBackdrop(Canvas canvas, Size size, BoardGeometry g, GameMap map) {
    final cell = g.cell;
    final board = g.board;
    final full = Offset.zero & size;
    final dark = palette.isDark;

    // Mesa de papel kraft: marrón de embalaje con fibras largas bien visibles,
    // motas y una luz cálida con viñeta.
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backdrop, palette.backdropLow],
        ).createShader(full),
    );
    paintFibers(canvas, full, 91, Color.fromRGBO(255, 240, 210, dark ? 0.10 : 0.34),
        count: (size.width * size.height / 520).round(), len: 22, width: 1.1);
    paintFibers(canvas, full, 17, Color.fromRGBO(70, 40, 10, dark ? 0.34 : 0.20),
        count: (size.width * size.height / 760).round(), len: 18, width: 0.9);
    final speck = Paint()..color = Color.fromRGBO(70, 40, 10, dark ? 0.40 : 0.22);
    final rs = math.Random(4);
    for (var i = 0; i < (size.width * size.height / 260).round(); i++) {
      canvas.drawCircle(Offset(rs.nextDouble() * size.width, rs.nextDouble() * size.height),
          0.5 + rs.nextDouble() * 0.7, speck);
    }
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.6),
          radius: 1.1,
          colors: [palette.light.withValues(alpha: dark ? 0.10 : 0.26), const Color(0x00000000)],
        ).createShader(full),
    );
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            Color.fromRGBO(30, 15, 6, dark ? 0.46 : 0.26),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(full),
    );

    // Lámina de cartón bajo las habitaciones.
    final slab = RRect.fromRectAndRadius(board.inflate(cell * 0.08), Radius.circular(cell * 0.12));
    canvas.drawRRect(
      slab.shift(Offset(0, cell * 0.1)),
      Paint()
        ..color = Color.fromRGBO(30, 15, 6, dark ? 0.6 : 0.40)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.2),
    );
    final slabColor = Color.lerp(palette.wall, palette.backdropLow, 0.45)!;
    canvas.drawRRect(slab.shift(const Offset(0, 3)), Paint()..color = _dim(slabColor, 0.4));
    canvas.drawRRect(
        slab,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = palette.paperEdge);
    canvas.drawRRect(slab, Paint()..color = slabColor);

    // Habitaciones: cartulina de color con estampado, borde rasgado, un borde
    // blanco de papel y 3 px de grosor más oscuro debajo de cada pieza.
    final rooms = <_PaperRoom>[];
    for (var i = 0; i < map.areas.length; i++) {
      final a = map.areas[i];
      final kind = floorKindFor(a.nameEs, i);
      final loops = gridOutline(a.cells, g.n);
      final origin = board.topLeft;
      final piece =
          tornPath(loops, origin: origin, cell: cell, seed: 7 + i * 29, amp: 1.2, step: 5.5);
      final fringe =
          tornPath(loops, origin: origin, cell: cell, seed: 211 + i * 31, amp: 1.9, step: 4.0);
      rooms.add(_PaperRoom(
        index: i,
        piece: piece,
        fringe: fringe,
        bounds: roomBounds(g, a),
        pattern: paperPatternFor(kind),
        tone: cardstockTone(i, mode),
        lowRow: a.cells.map(g.rowOf).reduce(math.max),
      ));
    }
    // Primero las de abajo: el grosor de una pieza cae sobre la que tiene
    // debajo, como si estuviera encima.
    rooms.sort((x, y) => y.lowRow.compareTo(x.lowRow));

    final depth = pieceDepth(cell);
    final soft = Paint()
      ..color = Color.fromRGBO(30, 15, 6, dark ? 0.55 : 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    for (final r in rooms) {
      canvas.drawPath(r.piece.shift(Offset(1.5, depth + 2.5)), soft);
    }
    for (final r in rooms) {
      // Grosor: la misma pieza más oscura, 3 px más abajo.
      canvas.drawPath(r.piece.shift(Offset(0, depth)), Paint()..color = _dim(r.tone, 0.5));
      canvas.drawPath(r.fringe, Paint()..color = palette.paperEdge);
      paintCardstock(
        canvas,
        pattern: r.pattern,
        clip: r.piece,
        bounds: r.bounds,
        cell: cell,
        base: r.tone,
        mode: mode,
        seed: 53 + r.index * 13,
      );
    }

    // Pliegues muy suaves entre casillas.
    final grid = Paint()
      ..color = Color.fromRGBO(30, 15, 6, dark ? 0.24 : 0.12)
      ..strokeWidth = 1;
    for (var k = 1; k < g.n; k++) {
      final x = board.left + k * cell;
      final y = board.top + k * cell;
      canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), grid);
      canvas.drawLine(Offset(board.left, y), Offset(board.right, y), grid);
    }

    for (final o in map.objects) {
      paintFurniture(canvas, g, o);
    }
    paintRoomLabels(canvas, g, map);
    // Un poco de luz rasante sobre todo el tablero.
    canvas.drawRRect(
      slab,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.light.withValues(alpha: dark ? 0.05 : 0.12),
            const Color(0x00000000),
            Color.fromRGBO(30, 15, 6, math.min(0.18, dark ? 0.2 : 0.08)),
          ],
        ).createShader(board),
    );
  }
}

class _PaperRoom {
  _PaperRoom({
    required this.index,
    required this.piece,
    required this.fringe,
    required this.bounds,
    required this.pattern,
    required this.tone,
    required this.lowRow,
  });
  final int index;
  final Path piece;
  final Path fringe;
  final Rect bounds;
  final PaperPattern pattern;
  final Color tone;
  final int lowRow;
}
