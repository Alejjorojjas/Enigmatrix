import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  group('GameMap', () {
    test('los mapas de prueba son válidos (toda celda en exactamente un área)',
        () {
      for (final m in allTestMaps) {
        expect(m.size * m.size,
            m.areas.fold<int>(0, (s, a) => s + a.cells.length));
      }
    });

    test('rechaza mapa con celda en dos áreas', () {
      expect(
        () => GameMap(
          id: 'malo',
          nameEs: 'Malo',
          size: 2,
          areas: const [
            Area(id: 'x', nameEs: 'X', cells: [0, 1, 2]),
            Area(id: 'y', nameEs: 'Y', cells: [2, 3]),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rechaza mapa con celda sin área', () {
      expect(
        () => GameMap(
          id: 'malo',
          nameEs: 'Malo',
          size: 2,
          areas: const [
            Area(id: 'x', nameEs: 'X', cells: [0, 1, 2]),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('celda con objeto que bloquea no es ocupable', () {
      expect(cabana.isOccupiable(6), isFalse); // mesa
      expect(cabana.isOccupiable(5), isTrue);
      expect(cabana.occupiableCells, isNot(contains(6)));
    });

    test('junto a: adyacencia ortogonal Y misma área', () {
      // 0=(f1,c1) y 4=(f2,c1): ambas Salón, adyacentes verticales.
      expect(cabana.besideInArea(0, 4), isTrue);
      // 1=(f1,c2) Salón y 2=(f1,c3) Cocina: adyacentes pero áreas distintas.
      expect(cabana.besideInArea(1, 2), isFalse);
      // 0 y 5: misma área pero diagonal.
      expect(cabana.besideInArea(0, 5), isFalse);
    });

    test('esquinas: pared vertical + pared horizontal', () {
      // En un área 2×2 toda celda es esquina.
      expect(cabana.isCorner(0), isTrue);
      expect(cabana.isCorner(5), isTrue);
      // Mansión: biblioteca (f1-f2 × c3-c5). Celda 8=(f2,c4): solo pared sur.
      expect(mansion.isCorner(8), isFalse);
      // Celda 2=(f1,c3): pared norte (borde) + pared oeste (Salón).
      expect(mansion.isCorner(2), isTrue);
    });
  });
}
