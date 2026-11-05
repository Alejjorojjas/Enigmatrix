/// Bordes de papel recortado o rasgado para la piel Papel. Se parte del
/// contorno exacto de una habitación (las casillas que la forman) y se le
/// agrega un temblor irregular, siempre el mismo para una misma semilla (no
/// parpadea de un cuadro a otro). Es puro y se prueba solo.
library;

import 'dart:math' as math;
import 'dart:ui';

/// Casillas de una habitación → contornos cerrados, en vértices de la
/// cuadrícula (columna, fila). Las esquinas son exactas; los tramos rectos se
/// fusionan. El interior queda a la derecha del recorrido (sentido horario).
List<List<Offset>> gridOutline(Iterable<int> cells, int n) {
  final set = cells.toSet();
  bool has(int r, int c) => r >= 0 && c >= 0 && r < n && c < n && set.contains(r * n + c);

  // Aristas dirigidas: de un vértice a otro.
  final out = <(int, int), List<(int, int)>>{};
  void edge((int, int) a, (int, int) b) => out.putIfAbsent(a, () => []).add(b);
  for (final cell in set) {
    final r = cell ~/ n, c = cell % n;
    if (!has(r - 1, c)) edge((c, r), (c + 1, r));
    if (!has(r, c + 1)) edge((c + 1, r), (c + 1, r + 1));
    if (!has(r + 1, c)) edge((c + 1, r + 1), (c, r + 1));
    if (!has(r, c - 1)) edge((c, r + 1), (c, r));
  }

  final loops = <List<Offset>>[];
  while (out.isNotEmpty) {
    final start = out.keys.first;
    var cur = start;
    var prev = start;
    final pts = <(int, int)>[start];
    var guard = 0;
    while (guard++ < 10000) {
      final nexts = out[cur];
      if (nexts == null || nexts.isEmpty) break;
      // En un vértice donde se tocan dos casillas en diagonal hay dos salidas:
      // se toma la que gira más a la derecha respecto de la llegada.
      var pick = 0;
      if (nexts.length > 1) {
        final inDx = cur.$1 - prev.$1, inDy = cur.$2 - prev.$2;
        var bestTurn = -1e9;
        for (var i = 0; i < nexts.length; i++) {
          final dx = nexts[i].$1 - cur.$1, dy = nexts[i].$2 - cur.$2;
          final cross = inDx * dy - inDy * dx; // >0 = gira a la derecha (y hacia abajo)
          if (cross > bestTurn) {
            bestTurn = cross.toDouble();
            pick = i;
          }
        }
      }
      final next = nexts.removeAt(pick);
      if (nexts.isEmpty) out.remove(cur);
      prev = cur;
      cur = next;
      if (cur == start) break;
      pts.add(cur);
    }
    if (pts.length >= 3) {
      // Quita los vértices intermedios de los tramos rectos.
      final m = <(int, int)>[];
      for (var i = 0; i < pts.length; i++) {
        final a = pts[(i - 1 + pts.length) % pts.length];
        final b = pts[i];
        final c = pts[(i + 1) % pts.length];
        final straight = (b.$1 - a.$1) * (c.$2 - b.$2) == (b.$2 - a.$2) * (c.$1 - b.$1);
        if (!straight) m.add(b);
      }
      loops.add([for (final v in m) Offset(v.$1.toDouble(), v.$2.toDouble())]);
    }
  }
  return loops;
}

/// Contorno irregular, como recortado a mano o rasgado, de los [loops] de una
/// habitación. [origin] y [cell] pasan de vértices de la cuadrícula a píxeles.
/// [amp] es el temblor máximo en píxeles y [step] la distancia entre puntos.
Path tornPath(
  List<List<Offset>> loops, {
  required Offset origin,
  required double cell,
  required int seed,
  double amp = 1.5,
  double step = 5.5,
}) {
  final rnd = math.Random(seed);
  final path = Path()..fillType = PathFillType.nonZero;
  for (final loop in loops) {
    final pts = <Offset>[];
    for (var i = 0; i < loop.length; i++) {
      final a = loop[i], b = loop[(i + 1) % loop.length];
      final pa = origin + a * cell, pb = origin + b * cell;
      final d = pb - pa;
      final len = d.distance;
      final dir = d / len;
      final normal = Offset(-dir.dy, dir.dx);
      final k = math.max(1, (len / step).round());
      var drift = 0.0;
      for (var j = 0; j < k; j++) {
        final base = pa + d * (j / k);
        if (j == 0) {
          // Esquina: se corre un poco en las dos direcciones.
          pts.add(base +
              Offset((rnd.nextDouble() - 0.5) * amp * 1.4,
                  (rnd.nextDouble() - 0.5) * amp * 1.4));
        } else {
          // Deriva suave con algún mordisco ocasional (borde rasgado).
          drift = drift * 0.5 + (rnd.nextDouble() * 2 - 1) * amp;
          if (rnd.nextDouble() < 0.14) drift += (rnd.nextBool() ? 1 : -1) * amp * 0.9;
          drift = drift.clamp(-amp * 1.7, amp * 1.7);
          pts.add(base + normal * drift);
        }
      }
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
  }
  return path;
}
