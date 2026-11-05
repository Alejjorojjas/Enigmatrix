/// Fondo de la vista de NOTAS: la cuadrícula con las marcas, sin muebles ni
/// nombres de habitación (doc 03). Se ve igual en las dos pieles; solo cambia
/// la paleta. Las paredes entre habitaciones se mantienen para poder repasar
/// filas, columnas y habitaciones, y las casillas con mueble que bloquea se
/// rayan para que se vea que no se pueden ocupar.
library;

import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import 'board_geometry.dart';
import 'palette.dart';

void paintNotesBackdrop(
  Canvas canvas,
  Size size,
  BoardGeometry g,
  GameMap map,
  SkinPalette p,
) {
  final n = g.n;
  final cell = g.cell;
  final board = g.board;

  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [p.backdrop, p.backdropLow],
      ).createShader(Offset.zero & size),
  );

  final boardR = RRect.fromRectAndRadius(board, Radius.circular(cell * 0.08));
  canvas.drawRRect(
    boardR.shift(Offset(0, cell * 0.08)),
    Paint()
      ..color = p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.2),
  );
  canvas.drawRRect(boardR, Paint()..color = p.surface);

  canvas.save();
  canvas.clipRRect(boardR);

  // Una tinta suave por habitación (también hay paredes: la tinta es refuerzo).
  for (var i = 0; i < n * n; i++) {
    final a = map.areas.indexWhere((x) => x.id == map.areaIdOf(i));
    final tint = p.portraitBg[(a < 0 ? 0 : a) % p.portraitBg.length];
    canvas.drawRect(
      g.cellRect(i),
      Paint()..color = tint.withValues(alpha: p.isDark ? 0.22 : 0.26),
    );
  }

  // Casillas que no se pueden ocupar: rayado.
  final hatch = Paint()
    ..color = p.ink.withValues(alpha: 0.32)
    ..strokeWidth = 1.4;
  for (var i = 0; i < n * n; i++) {
    if (map.isOccupiable(i)) continue;
    final r = g.cellRect(i).deflate(2);
    canvas.save();
    canvas.clipRect(r);
    for (var d = -r.height; d < r.width; d += cell * 0.22) {
      canvas.drawLine(
        Offset(r.left + d, r.bottom),
        Offset(r.left + d + r.height, r.top),
        hatch,
      );
    }
    canvas.restore();
  }

  // Cuadrícula fina.
  final grid = Paint()
    ..color = p.line.withValues(alpha: 0.45)
    ..strokeWidth = 1;
  for (var k = 1; k < n; k++) {
    final x = board.left + k * cell;
    final y = board.top + k * cell;
    canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), grid);
    canvas.drawLine(Offset(board.left, y), Offset(board.right, y), grid);
  }

  // Paredes entre habitaciones.
  final wall = Paint()
    ..color = p.wall
    ..strokeWidth = cell * 0.07
    ..strokeCap = StrokeCap.square;
  for (var i = 0; i < n * n; i++) {
    final r = g.cellRect(i);
    final row = g.rowOf(i), col = g.colOf(i);
    final id = map.areaIdOf(i);
    if (col + 1 < n && map.areaIdOf(i + 1) != id) {
      canvas.drawLine(r.topRight, r.bottomRight, wall);
    }
    if (row + 1 < n && map.areaIdOf(i + n) != id) {
      canvas.drawLine(r.bottomLeft, r.bottomRight, wall);
    }
  }
  canvas.restore();

  canvas.drawRRect(
    boardR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.07
      ..color = p.wall,
  );
}
