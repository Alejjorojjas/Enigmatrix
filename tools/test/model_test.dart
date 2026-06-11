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

    test('rechaza dos objetos en la misma celda', () {
      expect(
        () => GameMap(
          id: 'malo',
          nameEs: 'Malo',
          size: 2,
          areas: const [
            Area(id: 'x', nameEs: 'X', cells: [0, 1, 2, 3]),
          ],
          objects: const [
            MapObject(id: 'a', type: ObjectType.mesa, cells: [0]),
            MapObject(id: 'b', type: ObjectType.silla, cells: [0]),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('muebles bloqueantes vs pisables (modelo Murdoku)', () {
      expect(cabana.isOccupiable(6), isFalse); // mesa
      expect(cabana.isOccupiable(8), isFalse); // planta
      expect(cabana.isOccupiable(11), isFalse); // tv
      expect(cabana.isOccupiable(12), isTrue); // cama (pisable)
      expect(cabana.isOccupiable(1), isTrue); // alfombra (pisable)
      expect(cabana.occupiableCells, isNot(contains(6)));
    });

    test('objetos multi-celda: la cama cubre dos celdas', () {
      expect(cabana.objectAt(12)!.id, 'cama-dorm');
      expect(cabana.objectAt(13)!.id, 'cama-dorm');
      expect(cabana.objectAt(9), isNull);
    });

    test('estar sobre un grupo de mueble', () {
      expect(cabana.isOnGroup(12, 'cama'), isTrue);
      expect(cabana.isOnGroup(13, 'cama'), isTrue);
      expect(cabana.isOnGroup(9, 'cama'), isFalse);
      expect(cabana.isOnGroup(1, 'alfombra'), isTrue);
      expect(cabana.cellsOnGroup('alfombra'), {1, 15});
    });

    test('estar junto a un grupo: ortogonal, misma área, no encima', () {
      // 9 (dormitorio) es vecino de la cama (13).
      expect(cabana.isBesideGroup(9, 'cama'), isTrue);
      // Encima de la cama no cuenta como "junto a" la cama.
      expect(cabana.isBesideGroup(12, 'cama'), isFalse);
      // 10 (estudio) es vecino de la TV (11).
      expect(cabana.isBesideGroup(10, 'tv'), isTrue);
      // 2 (cocina) es vecino de la mesa (6); 7 también.
      expect(cabana.isBesideGroup(2, 'mesa'), isTrue);
      expect(cabana.isBesideGroup(7, 'mesa'), isTrue);
      // 5 (salón) NO: la mesa está en otra área aunque sea adyacente.
      expect(cabana.isBesideGroup(5, 'mesa'), isFalse);
    });

    test('grupos: planta y arbusto comparten grupo "planta"', () {
      expect(ObjectType.arbusto.group, 'planta');
      // Hotel: 3 plantas + 1 arbusto = 4 muebles del grupo planta.
      expect(hotel.countOfGroup('planta'), 4);
      expect(cabana.countOfGroup('alfombra'), 2);
      expect(cabana.countOfGroup('silla'), 1);
    });

    test('junto a: adyacencia ortogonal Y misma área (personas)', () {
      expect(cabana.besideInArea(0, 4), isTrue);
      expect(cabana.besideInArea(1, 2), isFalse); // áreas distintas
      expect(cabana.besideInArea(0, 5), isFalse); // diagonal
    });
  });
}
