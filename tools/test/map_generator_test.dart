import 'dart:convert';
import 'dart:math';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

GameMap buildMap(int size, int seed) =>
    MapGenerator(size: size, rng: Random(seed), id: 'm-$seed').build()!;

void main() {
  group('MapGenerator (mapas únicos por caso)', () {
    test('determinismo: misma semilla, mismo mapa', () {
      expect(jsonEncode(buildMap(6, 5).toJson()),
          jsonEncode(buildMap(6, 5).toJson()));
    });

    test('semillas distintas: distribuciones de habitaciones distintas', () {
      final layouts = {
        for (var seed = 1; seed <= 6; seed++)
          jsonEncode([
            for (final a in buildMap(6, seed).areas) a.cells
          ])
      };
      expect(layouts.length, 6,
          reason: 'todos los mapas deben tener habitaciones distintas');
    });

    for (final size in [6, 8, 9]) {
      test('$size×$size: válido, habitaciones contiguas y jugable', () {
        for (var seed = 1; seed <= 4; seed++) {
          final map = buildMap(size, seed);
          expect(map.size, size);
          // Toda celda en exactamente un área (lo valida el constructor) y
          // cada área contigua.
          for (final area in map.areas) {
            final cells = area.cells.toSet();
            final visited = {cells.first};
            final queue = [cells.first];
            while (queue.isNotEmpty) {
              final c = queue.removeLast();
              for (final n in map.orthNeighbors(c)) {
                if (cells.contains(n) && visited.add(n)) queue.add(n);
              }
            }
            expect(visited.length, cells.length,
                reason: 'área ${area.id} no contigua (seed $seed)');
          }
          // Hay muebles pisables y bloqueantes.
          expect(map.objects.where((o) => o.blocks), isNotEmpty);
          expect(map.objects.where((o) => !o.blocks), isNotEmpty);
          // Armas en áreas distintas (clave para casos con arma en casual).
          final weaponAreas = map.weapons.map((w) => w.areaId).toList();
          expect(weaponAreas.toSet().length, weaponAreas.length);
          // Cada fila y columna conserva al menos 2 celdas libres.
          for (var i = 0; i < size; i++) {
            final rowFree = [
              for (var c = 0; c < size; c++)
                if (map.isOccupiable(map.cellAt(i, c))) 1
            ].length;
            expect(rowFree, greaterThanOrEqualTo(2),
                reason: 'fila $i sin espacio (seed $seed)');
          }
        }
      });
    }

    test('serialización del mapa: ida y vuelta', () {
      final map = buildMap(6, 9);
      final back = GameMap.fromJson(map.toJson());
      expect(jsonEncode(back.toJson()), jsonEncode(map.toJson()));
    });
  });
}
