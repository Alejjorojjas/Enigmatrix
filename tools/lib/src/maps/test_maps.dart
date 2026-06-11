/// Mapas de prueba de la Fase 0. No son contenido final: existen para
/// validar el motor. Los mapas reales se autoran en Fase 2+ (doc 05).
library;

import '../model.dart';

/// 4×4 — Principiante (4 personajes). Cuatro cuadrantes.
///   a a b b
///   a a b b
///   c c d d
///   c c d d
final cabana = GameMap(
  id: 'cabana-test',
  nameEs: 'Cabaña de prueba',
  size: 4,
  areas: const [
    Area(id: 'salon', nameEs: 'el Salón', cells: [0, 1, 4, 5]),
    Area(id: 'cocina', nameEs: 'la Cocina', cells: [2, 3, 6, 7]),
    Area(id: 'dormitorio', nameEs: 'el Dormitorio', cells: [8, 9, 12, 13]),
    Area(id: 'estudio', nameEs: 'el Estudio', cells: [10, 11, 14, 15]),
  ],
  objects: const [
    MapObject(id: 'mesa', nameEs: 'la mesa', cell: 6),
  ],
  weapons: const [
    WeaponDef(
        id: 'cuchillo',
        nameEs: 'el cuchillo de cocina',
        category: WeaponCategory.cortante,
        areaId: 'cocina'),
    WeaponDef(
        id: 'candelabro',
        nameEs: 'el candelabro',
        category: WeaponCategory.contundente,
        areaId: 'salon'),
    WeaponDef(
        id: 'tijeras',
        nameEs: 'las tijeras',
        category: WeaponCategory.cortante,
        areaId: 'estudio'),
    WeaponDef(
        id: 'abrecartas',
        nameEs: 'el abrecartas',
        category: WeaponCategory.cortante,
        areaId: 'estudio'),
  ],
);

/// 5×5 — Casual (5 personajes).
///   a a b b b
///   a a b b b
///   c c d d e
///   c c d d e
///   c c d d e
final mansion = GameMap(
  id: 'mansion-test',
  nameEs: 'Mansión de prueba',
  size: 5,
  areas: const [
    Area(id: 'salon', nameEs: 'el Salón', cells: [0, 1, 5, 6]),
    Area(id: 'biblioteca', nameEs: 'la Biblioteca', cells: [2, 3, 4, 7, 8, 9]),
    Area(id: 'cocina', nameEs: 'la Cocina', cells: [10, 11, 15, 16, 20, 21]),
    Area(id: 'comedor', nameEs: 'el Comedor', cells: [12, 13, 17, 18, 22, 23]),
    Area(id: 'pasillo', nameEs: 'el Pasillo', cells: [14, 19, 24]),
  ],
  objects: const [
    MapObject(id: 'piano', nameEs: 'el piano', cell: 5),
    MapObject(id: 'mesa', nameEs: 'la mesa del comedor', cell: 17),
  ],
  weapons: const [
    WeaponDef(
        id: 'candelabro',
        nameEs: 'el candelabro',
        category: WeaponCategory.contundente,
        areaId: 'salon'),
    WeaponDef(
        id: 'abrecartas',
        nameEs: 'el abrecartas',
        category: WeaponCategory.cortante,
        areaId: 'biblioteca'),
    WeaponDef(
        id: 'cuchillo',
        nameEs: 'el cuchillo de cocina',
        category: WeaponCategory.cortante,
        areaId: 'cocina'),
    WeaponDef(
        id: 'veneno',
        nameEs: 'el frasco de veneno',
        category: WeaponCategory.veneno,
        areaId: 'comedor'),
    WeaponDef(
        id: 'cuerda',
        nameEs: 'la cuerda',
        category: WeaponCategory.asfixia,
        areaId: 'pasillo'),
  ],
);

/// 6×6 — Intermedio (6 personajes).
///   a a a b b b
///   a a a b b b
///   c c d d e e
///   c c d d e e
///   f f f f e e
///   f f f f e e
final hotel = GameMap(
  id: 'hotel-test',
  nameEs: 'Hotel de prueba',
  size: 6,
  areas: const [
    Area(id: 'recepcion', nameEs: 'la Recepción', cells: [0, 1, 2, 6, 7, 8]),
    Area(id: 'restaurante',
        nameEs: 'el Restaurante', cells: [3, 4, 5, 9, 10, 11]),
    Area(id: 'lavanderia', nameEs: 'la Lavandería', cells: [12, 13, 18, 19]),
    Area(id: 'habitacion',
        nameEs: 'la Habitación 101', cells: [14, 15, 20, 21]),
    Area(id: 'pasillo',
        nameEs: 'el Pasillo', cells: [16, 17, 22, 23, 28, 29, 34, 35]),
    Area(id: 'eventos',
        nameEs: 'el Salón de Eventos', cells: [24, 25, 26, 27, 30, 31, 32, 33]),
  ],
  objects: const [
    MapObject(id: 'barra', nameEs: 'la barra', cell: 9),
    MapObject(id: 'carrito', nameEs: 'el carrito de lavandería', cell: 19),
    MapObject(id: 'tarima', nameEs: 'la tarima', cell: 31),
  ],
  weapons: const [
    WeaponDef(
        id: 'botella',
        nameEs: 'la botella rota',
        category: WeaponCategory.cortante,
        areaId: 'restaurante'),
    WeaponDef(
        id: 'cable',
        nameEs: 'el cable',
        category: WeaponCategory.asfixia,
        areaId: 'lavanderia'),
    WeaponDef(
        id: 'martillo',
        nameEs: 'el martillo de servicio',
        category: WeaponCategory.contundente,
        areaId: 'eventos'),
    WeaponDef(
        id: 'veneno',
        nameEs: 'el frasco de veneno',
        category: WeaponCategory.veneno,
        areaId: 'habitacion'),
    WeaponDef(
        id: 'cuerda',
        nameEs: 'la cuerda',
        category: WeaponCategory.asfixia,
        areaId: 'pasillo'),
  ],
);

final allTestMaps = [cabana, mansion, hotel];

GameMap mapById(String id) => allTestMaps.firstWhere(
      (m) => m.id == id,
      orElse: () => throw ArgumentError('Mapa desconocido: $id'),
    );

GameMap mapForDifficulty(String label) => switch (label) {
      'principiante' => cabana,
      'casual' => mansion,
      'intermedio' => hotel,
      _ => throw ArgumentError('Dificultad sin mapa de prueba: $label'),
    };
