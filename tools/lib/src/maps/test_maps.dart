/// Mapas de prueba de la Fase 0/1, amueblados al estilo Murdoku
/// (decisión 2026-06-11): muebles pisables y bloqueantes, multi-celda,
/// repetidos para que las pistas de mueble exijan deducción.
/// No son contenido final: los mapas reales se autoran en Fase 2+ (doc 05).
library;

import '../model.dart';

/// 4×4 — Principiante (4 personajes). Cuatro cuadrantes.
///   a a b b      salón:      alfombra(1), silla(4)
///   a a b b      cocina:     mesa(6)
///   c c d d      dormitorio: planta(8), cama(12,13)
///   c c d d      estudio:    tv(11), alfombra(15)
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
    MapObject(id: 'alfombra-salon', type: ObjectType.alfombra, cells: [1]),
    MapObject(id: 'silla-salon', type: ObjectType.silla, cells: [4]),
    MapObject(id: 'mesa-cocina', type: ObjectType.mesa, cells: [6]),
    MapObject(id: 'planta-dorm', type: ObjectType.planta, cells: [8]),
    MapObject(id: 'cama-dorm', type: ObjectType.cama, cells: [12, 13]),
    MapObject(id: 'tv-estudio', type: ObjectType.tv, cells: [11]),
    MapObject(id: 'alfombra-estudio', type: ObjectType.alfombra, cells: [15]),
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
///   a a b b b      salón:      alfombra(0,1), piano(5)
///   a a b b b      biblioteca: tv(2), sillón(3), planta(4)
///   c c d d e      cocina:     mesa(15), lavadora(20)
///   c c d d e      comedor:    silla(12), mesa(17,18), silla(22)
///   c c d d e      pasillo:    alfombra(19), planta(24)
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
    MapObject(id: 'alfombra-salon', type: ObjectType.alfombra, cells: [0, 1]),
    MapObject(id: 'piano-salon', type: ObjectType.piano, cells: [5]),
    MapObject(id: 'tv-biblio', type: ObjectType.tv, cells: [2]),
    MapObject(id: 'sillon-biblio', type: ObjectType.sillon, cells: [3]),
    MapObject(id: 'planta-biblio', type: ObjectType.planta, cells: [4]),
    MapObject(id: 'mesa-cocina', type: ObjectType.mesa, cells: [15]),
    MapObject(id: 'lavadora-cocina', type: ObjectType.lavadora, cells: [20]),
    MapObject(id: 'silla-comedor-1', type: ObjectType.silla, cells: [12]),
    MapObject(id: 'mesa-comedor', type: ObjectType.mesa, cells: [17, 18]),
    MapObject(id: 'silla-comedor-2', type: ObjectType.silla, cells: [22]),
    MapObject(id: 'alfombra-pasillo', type: ObjectType.alfombra, cells: [19]),
    MapObject(id: 'planta-pasillo', type: ObjectType.planta, cells: [24]),
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

/// 6×6 — Intermedio (6 personajes). Estilo "alquiler vacacional".
///   a a a b b b      recepción:   tv(2), sofá(6,7), planta(8)
///   a a a b b b      restaurante: silla(3), mesa(4), barra(9), silla(10), caja(11)
///   c c d d e e      lavandería:  lavadora(12), caja(18)
///   c c d d e e      habitación:  cama(14,15), alfombra(20), planta(21)
///   f f f f e e      pasillo:     planta(22), alfombra(28), armario(34)
///   f f f f e e      eventos:     tv(24), sillón(25), mesa(30,31), arbusto(33)
final hotel = GameMap(
  id: 'hotel-test',
  nameEs: 'Hotel de prueba',
  size: 6,
  areas: const [
    Area(id: 'recepcion', nameEs: 'la Recepción', cells: [0, 1, 2, 6, 7, 8]),
    Area(
        id: 'restaurante',
        nameEs: 'el Restaurante',
        cells: [3, 4, 5, 9, 10, 11]),
    Area(id: 'lavanderia', nameEs: 'la Lavandería', cells: [12, 13, 18, 19]),
    Area(id: 'habitacion', nameEs: 'la Habitación 101', cells: [14, 15, 20, 21]),
    Area(
        id: 'pasillo',
        nameEs: 'el Pasillo',
        cells: [16, 17, 22, 23, 28, 29, 34, 35]),
    Area(
        id: 'eventos',
        nameEs: 'el Salón de Eventos',
        cells: [24, 25, 26, 27, 30, 31, 32, 33]),
  ],
  objects: const [
    MapObject(id: 'tv-recepcion', type: ObjectType.tv, cells: [2]),
    MapObject(id: 'sofa-recepcion', type: ObjectType.sofa, cells: [6, 7]),
    MapObject(id: 'planta-recepcion', type: ObjectType.planta, cells: [8]),
    MapObject(id: 'silla-rest-1', type: ObjectType.silla, cells: [3]),
    MapObject(id: 'mesa-rest', type: ObjectType.mesa, cells: [4]),
    MapObject(id: 'barra-rest', type: ObjectType.barra, cells: [9]),
    MapObject(id: 'silla-rest-2', type: ObjectType.silla, cells: [10]),
    MapObject(id: 'caja-rest', type: ObjectType.caja, cells: [11]),
    MapObject(id: 'lavadora', type: ObjectType.lavadora, cells: [12]),
    MapObject(id: 'caja-lavanderia', type: ObjectType.caja, cells: [18]),
    MapObject(id: 'cama-habitacion', type: ObjectType.cama, cells: [14, 15]),
    MapObject(
        id: 'alfombra-habitacion', type: ObjectType.alfombra, cells: [20]),
    MapObject(id: 'planta-habitacion', type: ObjectType.planta, cells: [21]),
    MapObject(id: 'planta-pasillo', type: ObjectType.planta, cells: [22]),
    MapObject(id: 'alfombra-pasillo', type: ObjectType.alfombra, cells: [28]),
    MapObject(id: 'armario-pasillo', type: ObjectType.armario, cells: [34]),
    MapObject(id: 'tv-eventos', type: ObjectType.tv, cells: [24]),
    MapObject(id: 'sillon-eventos', type: ObjectType.sillon, cells: [25]),
    MapObject(id: 'mesa-eventos', type: ObjectType.mesa, cells: [30, 31]),
    MapObject(id: 'arbusto-eventos', type: ObjectType.arbusto, cells: [33]),
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
