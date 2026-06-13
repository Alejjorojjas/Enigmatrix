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

/// Tipos que SIEMPRE ocupan 2 celdas adyacentes (decisión 2026-06-12).
/// Si no hay un par libre, ese mueble no se coloca.
const _twoCellTypes = {
  ObjectType.cama,
  ObjectType.sofa,
  ObjectType.mesa,
  ObjectType.alfombra,
  ObjectType.barra,
};

/// Coherencia temática (2026-06-12): qué muebles tienen sentido en cada
/// tipo de habitación. Una cama nunca aparece en un baño. Las claves son
/// los ids de habitación de [_roomNamePool].
const _furnitureByRoom = <String, List<ObjectType>>{
  'salon': [
    ObjectType.sofa,
    ObjectType.sillon,
    ObjectType.alfombra,
    ObjectType.tv,
    ObjectType.piano,
    ObjectType.mesa,
    ObjectType.planta,
  ],
  'cocina': [
    ObjectType.mesa,
    ObjectType.silla,
    ObjectType.barra,
    ObjectType.planta,
  ],
  'dormitorio': [
    ObjectType.cama,
    ObjectType.armario,
    ObjectType.alfombra,
    ObjectType.silla,
    ObjectType.tv,
    ObjectType.planta,
  ],
  'biblioteca': [
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.mesa,
    ObjectType.alfombra,
    ObjectType.planta,
    ObjectType.armario,
  ],
  'comedor': [
    ObjectType.mesa,
    ObjectType.silla,
    ObjectType.alfombra,
    ObjectType.planta,
  ],
  'estudio': [
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.mesa,
    ObjectType.armario,
    ObjectType.planta,
    ObjectType.alfombra,
  ],
  'bano': [
    ObjectType.planta,
    ObjectType.alfombra,
  ],
  'pasillo': [
    ObjectType.planta,
    ObjectType.alfombra,
    ObjectType.armario,
    ObjectType.silla,
  ],
  'vestibulo': [
    ObjectType.planta,
    ObjectType.alfombra,
    ObjectType.armario,
    ObjectType.silla,
    ObjectType.sillon,
  ],
  'jardin': [
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.silla,
    ObjectType.sofa,
  ],
  'porche': [
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.sofa,
  ],
  'atico': [
    ObjectType.caja,
    ObjectType.armario,
    ObjectType.alfombra,
    ObjectType.silla,
  ],
  'bodega': [
    ObjectType.caja,
    ObjectType.armario,
    ObjectType.lavadora,
  ],
  'terraza': [
    ObjectType.silla,
    ObjectType.sofa,
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.mesa,
  ],
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

    // 3. Muebles POR HABITACIÓN (coherencia temática 2026-06-12): cada
    //    habitación solo recibe muebles de su lista permitida, y los tipos
    //    de [_twoCellTypes] siempre ocupan 2 celdas. La repetición de tipos
    //    entre habitaciones (sillas en cocina, comedor, estudio...) da la
    //    ambigüedad que necesitan las pistas ("una silla").
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

    // Celdas libres en un área; para muebles de 2 celdas, busca un par
    // ortogonal libre dentro de la MISMA área.
    List<int>? findSpotInArea(List<int> areaCells, bool twoCells) {
      final free = [
        for (final c in areaCells)
          if (!occupiedByObject.contains(c)) c
      ]..shuffle(rng);
      for (final cell in free) {
        if (!twoCells) return [cell];
        final partners = [
          for (final n in _orthNeighbors(cell))
            if (!occupiedByObject.contains(n) && areaCells.contains(n)) n
        ];
        if (partners.isNotEmpty) {
          return [cell, partners[rng.nextInt(partners.length)]];
        }
      }
      return null;
    }

    var objSeq = 0;
    for (final area in areas) {
      final allowed = _furnitureByRoom[area.id] ??
          const [ObjectType.silla, ObjectType.planta];
      // ~1 mueble por cada 3 celdas de la habitación, entre 1 y 4.
      final count = (area.cells.length / 3).round().clamp(1, 4);
      for (var i = 0; i < count; i++) {
        // Hasta 4 intentos con tipos distintos (un mueble de 2 celdas que
        // no quepa cede el turno a otro tipo en vez de forzarse a 1 celda).
        for (var t = 0; t < 4; t++) {
          final type = allowed[rng.nextInt(allowed.length)];
          final twoCells = _twoCellTypes.contains(type);
          final cells = findSpotInArea(area.cells, twoCells);
          if (cells == null) continue;
          final blocking = _blockingTypes.contains(type);
          if (blocking && !rowColSafe(cells)) continue;
          objects.add(MapObject(
              id: '${type.name}-${++objSeq}', type: type, cells: cells));
          occupiedByObject.addAll(cells);
          if (blocking) registerBlocked(cells);
          break;
        }
      }
    }

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
