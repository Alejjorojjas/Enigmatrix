import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/feedback/feedback_event.dart';
import 'package:enigmatrix/src/board/feedback/reveal_timeline.dart';

RevealData data(int n, List<int> innocents) => RevealData(
  gridSize: n,
  murdererCell: 14,
  victimCell: 3,
  murdererId: 'c2',
  murdererName: 'Bruno',
  innocentCells: innocents,
);

void main() {
  for (final (n, innocents) in [
    (6, [0, 9, 20, 29]),
    (8, [1, 10, 22, 35, 40, 61]),
  ]) {
    group('secuencia de ${n}x$n', () {
      final tl = RevealTimeline.build(data(n, innocents));
      final kinds = tl.moments.map((m) => m.kind).toList();

      test('tiene todos los momentos en orden de tiempo', () {
        for (var i = 1; i < tl.moments.length; i++) {
          expect(tl.moments[i].atMs >= tl.moments[i - 1].atMs, isTrue);
        }
        expect(kinds.where((k) => k == RevealBeatKind.waveRow), hasLength(n));
        expect(
          kinds.where((k) => k == RevealBeatKind.cascade),
          hasLength(innocents.length),
        );
        expect(kinds.where((k) => k == RevealBeatKind.zoomHit), hasLength(1));
        expect(kinds.where((k) => k == RevealBeatKind.star), hasLength(3));
        expect(kinds.where((k) => k == RevealBeatKind.fanfare), hasLength(1));
        expect(kinds.last, RevealBeatKind.end);
      });

      test('la ola recorre las filas de arriba abajo', () {
        final rows = tl.moments
            .where((m) => m.kind == RevealBeatKind.waveRow)
            .map((m) => m.index)
            .toList();
        expect(rows, [for (var r = 0; r < n; r++) r]);
      });

      test('los inocentes saltan en cascada de izquierda a derecha', () {
        final cols = tl.moments
            .where((m) => m.kind == RevealBeatKind.cascade)
            .map((m) => m.cell! % n)
            .toList();
        final sorted = [...cols]..sort();
        expect(cols, sorted);
      });

      test('el golpe llega después de la cascada y antes de las estrellas', () {
        final zoom = tl.moments.firstWhere(
          (m) => m.kind == RevealBeatKind.zoomHit,
        );
        final lastHop = tl.moments
            .where((m) => m.kind == RevealBeatKind.cascade)
            .last;
        final firstStar = tl.moments.firstWhere(
          (m) => m.kind == RevealBeatKind.star,
        );
        expect(zoom.atMs > lastHop.atMs, isTrue);
        expect(firstStar.atMs > zoom.atMs, isTrue);
        expect(zoom.cell, 14);
      });

      test('dura entre 3 y 4,5 s y se puede saltar desde 1 s', () {
        expect(tl.totalMs, inInclusiveRange(3000, 4500));
        expect(RevealTimeline.skipAfterMs, 1000);
        // A 1 s todavía no se acabó casi nada.
        expect(
          tl.moments.where((m) => m.atMs <= 1000).length < tl.moments.length,
          isTrue,
        );
      });

      test(
        'recorrerla por cuadros de 16 ms entrega cada momento una sola vez',
        () {
          var seen = 0;
          for (var t = -16.0; t < tl.totalMs + 32; t += 16) {
            seen += tl.between(t, t + 16).length;
          }
          expect(seen, tl.moments.length);
        },
      );
    });
  }
}
