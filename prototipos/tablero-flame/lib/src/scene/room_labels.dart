/// Dónde y cómo se escribe el nombre de cada habitación. Es una función pura
/// (sin dibujar nada) para poder probarla: los rótulos
///  - miden 11 px o más;
///  - van dentro de las casillas libres (sin mueble) de su propia habitación,
///    así que nunca se montan entre sí ni salen del borde del tablero;
///  - si el nombre no cabe, se abrevia ("Biblio.").
/// Las tres pieles usan este mismo cálculo y cada una pinta la pastilla a su
/// manera.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

import 'board_geometry.dart';

/// Un rótulo ya colocado.
class RoomLabel {
  const RoomLabel({
    required this.areaId,
    required this.text,
    required this.fontSize,
    required this.pill,
    required this.abbreviated,
  });

  final String areaId;
  final String text;
  final double fontSize;

  /// Pastilla que contiene el texto, en coordenadas de la escena.
  final Rect pill;
  final bool abbreviated;
}

/// Tamaño mínimo de letra de un rótulo, en píxeles.
const double kRoomLabelMinFont = 11;

/// Nombre sin el artículo ("el Comedor" pasa a "Comedor").
String roomLabelText(String nameEs) {
  final t = nameEs.trim();
  final parts = t.split(' ');
  if (parts.length > 1 &&
      const {'el', 'la', 'los', 'las'}.contains(parts.first.toLowerCase())) {
    return parts.sublist(1).join(' ');
  }
  return t;
}

/// Letra de los rótulos para una casilla de [cell] píxeles.
double roomLabelFont(double cell) =>
    (cell * 0.24).clamp(kRoomLabelMinFont, 14.0);

/// Versiones del nombre de la más larga a la más corta.
List<String> _variants(String full) {
  final out = <String>[full];
  for (var len = full.length - 1; len >= 3; len--) {
    final t = full.substring(0, len).trimRight();
    if (t.length >= 3) out.add('$t.');
  }
  return out;
}

/// Coloca el rótulo de cada habitación. [measure] devuelve el ancho del texto
/// con ese tamaño de letra.
List<RoomLabel> layoutRoomLabels(
  BoardGeometry g,
  GameMap map,
  double Function(String text, double fontSize) measure,
) {
  final cell = g.cell;
  final fs = roomLabelFont(cell);
  final padX = fs * 0.55;
  final pillH = fs + 7;
  final occupied = <int>{for (final o in map.objects) ...o.cells};
  final result = <RoomLabel>[];

  for (final area in map.areas) {
    final full = roomLabelText(area.nameEs);
    final variants = _variants(full);

    // Tramos horizontales de casillas consecutivas (de la misma habitación).
    List<List<int>> runsOf(Iterable<int> cells) {
      final byRow = <int, List<int>>{};
      for (final c in cells) {
        byRow.putIfAbsent(g.rowOf(c), () => []).add(c);
      }
      final runs = <List<int>>[];
      for (final row in byRow.values) {
        row.sort();
        var run = <int>[row.first];
        for (final c in row.skip(1)) {
          if (c == run.last + 1) {
            run.add(c);
          } else {
            runs.add(run);
            run = [c];
          }
        }
        runs.add(run);
      }
      return runs;
    }

    final free = area.cells.where((c) => !occupied.contains(c));
    var runs = runsOf(free);
    if (runs.isEmpty) runs = runsOf(area.cells);

    final cx = area.cells.map(g.colOf).reduce((a, b) => a + b) / area.cells.length;

    RoomLabel? best;
    var bestScore = -1e18;
    for (final run in runs) {
      final first = g.cellRect(run.first), last = g.cellRect(run.last);
      final left = first.left + 2, right = last.right - 2;
      final capacity = right - left;
      for (var vi = 0; vi < variants.length; vi++) {
        final text = variants[vi];
        final w = measure(text, fs) + 2 * padX;
        if (w > capacity) continue;
        final row = g.rowOf(run.first);
        final midCol = (g.colOf(run.first) + g.colOf(run.last)) / 2;
        // Más largo es mejor; a igual largo, una fila baja y centrada.
        final score = text.length * 100.0 + row * 3 - (midCol - cx).abs();
        if (score > bestScore) {
          bestScore = score;
          final centerX = ((left + right) / 2)
              .clamp(left + w / 2, right - w / 2)
              .toDouble();
          final centerY = first.bottom - pillH / 2 - 3;
          best = RoomLabel(
            areaId: area.id,
            text: text,
            fontSize: fs,
            pill: Rect.fromCenter(
                center: Offset(centerX, centerY), width: w, height: pillH),
            abbreviated: vi > 0,
          );
        }
        break; // la primera versión que cabe es la más larga
      }
    }

    best ??= () {
      // Ningún tramo alcanza (casillas diminutas): tres letras en la primera.
      final r = g.cellRect(runs.first.first);
      final text = full.substring(0, math.min(3, full.length));
      final w = math.min(measure(text, fs) + 2 * padX, r.width - 2);
      return RoomLabel(
        areaId: area.id,
        text: text,
        fontSize: fs,
        pill: Rect.fromCenter(
            center: Offset(r.center.dx, r.bottom - pillH / 2 - 3),
            width: w,
            height: pillH),
        abbreviated: true,
      );
    }();
    result.add(best);
  }
  return result;
}
