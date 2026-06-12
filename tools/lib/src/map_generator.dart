/// Generador procedural de mapas (decisión 2026-06-11): cada caso tiene su
/// propio mapa — distribución de habitaciones, muebles y armas única.
/// El arte temático por mundo se aplicará encima en Fase 2 (mockups).
library;

import 'dart:math';

import 'model.dart';

const _roomNamePool = [
  ('salon', 'el Salón'),
  ('cocina', 'la Cocina'),
  ('dormitorio', 'el Dormitorio'),
  ('biblioteca', 'la Biblioteca'),
  ('comedor', 'el Comedor'),
  ('estudio', 'el Estudio'),
  ('bano', 'el Baño'),
  ('pasillo', 'el Pasillo'),
  ('vestibulo', 'el Vestíbulo'),
  ('jardin', 'el Jardín'),
  ('porche', 'el Porche'),
  ('atico', 'el Ático'),
  ('bodega', 'la Bodega'),
  ('terraza', 'la Terraza'),
];

const _venueNames = [
  'La Mansión',
  'El Hotel',
  'La Cabaña',
  'El Museo',
  'La Posada',
  'El Teatro',
  'La Galería',
  'El Club',
  'La Villa',
  'El Casino',
];

const _weaponPool = [
  ('candelabro', 'el candelabro', WeaponCategory.contundente),
  ('abrecartas', 'el abrecartas', WeaponCategory.cortante),
  ('cuerda', 'la cuerda', WeaponCategory.asfixia),
  ('veneno', 'el frasco de veneno', WeaponCategory.veneno),
  ('tijeras', 'las tijeras', WeaponCategory.cortante),
  ('botella', 'la botella rota', WeaponCategory.cortante),
  ('cable', 'el cable', WeaponCategory.asfixia),
  ('martillo', 'el martillo', WeaponCategory.contundente),
  ('jeringa', 'la jeringa', WeaponCategory.veneno),
  ('cuchillo', 'el cuchillo de cocina', WeaponCategory.cortante),
];

const _standableTypes = [
  ObjectType.silla,
  ObjectType.sillon,
  ObjectType.sofa,
  ObjectType.cama,
  ObjectType.alfombra,
];

const _blockingTypes = [
  ObjectType.mesa,
  ObjectType.tv,
  ObjectType.planta,
  ObjectType.arbusto,
  ObjectType.armario,
  ObjectType.caja,
  ObjectType.lavadora,
  ObjectType.piano,
  ObjectType.barra,
];

/// Tipos que pueden ocupar 2 celdas adyacentes.
const _twoCellTypes = {
  ObjectType.cama,
  ObjectType.sofa,
  ObjectType.mesa,
  ObjectType.alfombra,
  ObjectType.barra,
};

class MapGenerator {
  final int size;
  final Random rng;
  final String id;

  MapGenerator({required this.size, required this.rng, required this.id});

  int get _roomCount =>
      switch (size) {
        <= 6 => 4,
        <= 8 => 5,
        <= 9 => 6,
        <= 12 => 7,
        _ => 8,
      } +
      rng.nextInt(2);

  /// Genera un mapa válido o null si no lo logró en sus intentos internos.
  GameMap? build() {
    for (var attempt = 0; attempt < 30; attempt++) {
      final map = _tryBuild();
      if (map != null) return map;
    }
    return null;
  }

  GameMap? _tryBuild() {
    final total = size * size;

    // 1. Partición en habitaciones por crecimiento de regiones:
    //    contiguas e irregulares, como los mapas de Murdoku.
    final k = _roomCount;
    final areaOf = List<int>.filled(total, -1);
    final seeds = _spreadSeeds(k);
    final cellsByArea = [
      for (var a = 0; a < k; a++) <int>[seeds[a]],
    ];
    for (var a = 0; a < k; a++) {
      areaOf[seeds[a]] = a;
    }
    var assigned = k;
    while (assigned < total) {
      // Crece primero la habitación más pequeña que tenga frontera.
      final order = List<int>.generate(k, (a) => a)
        ..sort((x, y) => cellsByArea[x].length.compareTo(cellsByArea[y].length));
      var grew = false;
      for (final a in order) {
        final frontier = <int>[];
        for (final c in cellsByArea[a]) {
          for (final n in _orthNeighbors(c)) {
            if (areaOf[n] == -1) frontier.add(n);
          }
        }
        if (frontier.isEmpty) continue;
        final cell = frontier[rng.nextInt(frontier.length)];
        areaOf[cell] = a;
        cellsByArea[a].add(cell);
        assigned++;
        grew = true;
        break;
      }
      if (!grew) return null; // no debería pasar (grilla conexa)
    }
    final minRoom = (total / k / 3).ceil().clamp(2, 6);
    if (cellsByArea.any((c) => c.length < minRoom)) return null;

    // 2. Nombres de habitaciones y del lugar.
    final roomNames = [..._roomNamePool]..shuffle(rng);
    final areas = [
      for (var a = 0; a < k; a++)
        Area(
          id: roomNames[a].$1,
          nameEs: roomNames[a].$2,
          cells: cellsByArea[a]..sort(),
        ),
    ];

    // 3. Muebles: pisables y bloqueantes, algunos de 2 celdas, con tipos
    //    repetidos a propósito (la ambigüedad "una silla" es la dificultad).
    final objects = <MapObject>[];
    final occupiedByObject = <int>{};
    final blockedCount = List<int>.filled(size, 0); // por fila
    final blockedCols = List<int>.filled(size, 0);

    bool rowColSafe(List<int> cells) {
      // Ninguna fila/columna puede quedar con menos de 2 celdas libres.
      final byRow = <int, int>{}, byCol = <int, int>{};
      for (final c in cells) {
        byRow.update(c ~/ size, (v) => v + 1, ifAbsent: () => 1);
        byCol.update(c % size, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final e in byRow.entries) {
        if (size - (blockedCount[e.key] + e.value) < 2) return false;
      }
      for (final e in byCol.entries) {
        if (size - (blockedCols[e.key] + e.value) < 2) return false;
      }
      return true;
    }

    void registerBlocked(List<int> cells) {
      for (final c in cells) {
        blockedCount[c ~/ size]++;
        blockedCols[c % size]++;
      }
    }

    List<int>? findSpot(bool twoCells) {
      for (var tries = 0; tries < 25; tries++) {
        final cell = rng.nextInt(total);
        if (occupiedByObject.contains(cell)) continue;
        if (!twoCells) return [cell];
        final partners = [
          for (final n in _orthNeighbors(cell))
            if (!occupiedByObject.contains(n) && areaOf[n] == areaOf[cell]) n
        ];
        if (partners.isEmpty) continue;
        return [cell, partners[rng.nextInt(partners.length)]];
      }
      return null;
    }

    var objSeq = 0;
    void place(List<ObjectType> pool, int count, {required bool blocking}) {
      final used = <ObjectType>[];
      for (var i = 0; i < count; i++) {
        // 40% de probabilidad de repetir un tipo ya usado (ambigüedad).
        final type = used.isNotEmpty && rng.nextInt(10) < 4
            ? used[rng.nextInt(used.length)]
            : pool[rng.nextInt(pool.length)];
        final twoCells = _twoCellTypes.contains(type) && rng.nextInt(10) < 4;
        final cells = findSpot(twoCells);
        if (cells == null) continue;
        if (blocking && !rowColSafe(cells)) continue;
        objects.add(MapObject(
            id: '${type.name}-${++objSeq}', type: type, cells: cells));
        occupiedByObject.addAll(cells);
        if (blocking) registerBlocked(cells);
        used.add(type);
      }
    }

    final standables = size - 2 + rng.nextInt(2);
    final blockings = size - 2 + rng.nextInt(3);
    place(_standableTypes, standables, blocking: false);
    place(_blockingTypes, blockings, blocking: true);

    // 4. Armas potenciales en áreas distintas (así en Casual el área del
    //    crimen siempre tiene una sola arma).
    final weaponCount = (2 + rng.nextInt(2)).clamp(0, k);
    final weaponAreas = List<int>.generate(k, (a) => a)..shuffle(rng);
    final weaponsShuffled = [..._weaponPool]..shuffle(rng);
    final weapons = [
      for (var i = 0; i < weaponCount; i++)
        WeaponDef(
          id: weaponsShuffled[i].$1,
          nameEs: weaponsShuffled[i].$2,
          category: weaponsShuffled[i].$3,
          areaId: areas[weaponAreas[i]].id,
        ),
    ];

    final map = GameMap(
      id: id,
      nameEs: _venueNames[rng.nextInt(_venueNames.length)],
      size: size,
      areas: areas,
      objects: objects,
      weapons: weapons,
    );

    // 5. Viabilidad: debe existir al menos una distribución válida de
    //    personas (una por fila/columna en celdas ocupables) y al menos
    //    dos áreas capaces de alojar a la pareja víctima-asesino.
    if (!_hasValidPermutation(map)) return null;
    var pairCapable = 0;
    for (final area in areas) {
      final free = [for (final c in area.cells) if (map.isOccupiable(c)) c];
      var found = false;
      for (var i = 0; i < free.length && !found; i++) {
        for (var j = i + 1; j < free.length && !found; j++) {
          if (map.row(free[i]) != map.row(free[j]) &&
              map.col(free[i]) != map.col(free[j])) {
            found = true;
          }
        }
      }
      if (found) pairCapable++;
    }
    if (pairCapable < 2) return null;

    return map;
  }

  List<int> _spreadSeeds(int k) {
    // Semillas separadas entre sí para habitaciones repartidas.
    final all = List<int>.generate(size * size, (i) => i)..shuffle(rng);
    final seeds = <int>[];
    final minDist = (size / 3).floor().clamp(1, 4);
    for (final c in all) {
      final r = c ~/ size, col = c % size;
      final farEnough = seeds.every((s) {
        final sr = s ~/ size, sc = s % size;
        return (r - sr).abs() + (col - sc).abs() >= minDist;
      });
      if (farEnough) {
        seeds.add(c);
        if (seeds.length == k) return seeds;
      }
    }
    // Relleno si la dispersión no alcanzó.
    for (final c in all) {
      if (!seeds.contains(c)) {
        seeds.add(c);
        if (seeds.length == k) break;
      }
    }
    return seeds;
  }

  List<int> _orthNeighbors(int cell) {
    final r = cell ~/ size, c = cell % size;
    return [
      if (r > 0) cell - size,
      if (r < size - 1) cell + size,
      if (c > 0) cell - 1,
      if (c < size - 1) cell + 1,
    ];
  }

  bool _hasValidPermutation(GameMap map) {
    final used = List<bool>.filled(size, false);
    bool place(int r) {
      if (r == size) return true;
      for (var c = 0; c < size; c++) {
        if (used[c] || !map.isOccupiable(r * size + c)) continue;
        used[c] = true;
        if (place(r + 1)) return true;
        used[c] = false;
      }
      return false;
    }

    return place(0);
  }
}
