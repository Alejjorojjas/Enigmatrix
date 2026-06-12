/// Modelo del tablero de Enigmatrix.
/// Fuente conceptual: docs/16-spec-puzzle.md (secciones 1 y 2).
library;

/// Direcciones cardinales en orientación canónica (fila 0 = norte).
enum Direction { north, south, east, west }

/// Categorías lógicas de arma (doc 03). No se muestran en UI.
enum WeaponCategory { cortante, contundente, veneno, asfixia }

/// Tipos de mueble/objeto del mapa (modelo Murdoku, decidido 2026-06-10):
/// - pisables: la gente puede estar ENCIMA ("sobre una cama",
///   "sentado en una silla")
/// - bloqueantes: nadie puede ocupar esas celdas ("junto a la mesa")
///
/// [group] agrupa tipos equivalentes para las pistas
/// (planta y arbusto se leen ambos como "una planta").
enum ObjectType {
  silla('silla', female: true, standable: true, seated: true),
  sillon('sillón', female: false, standable: true, seated: true),
  sofa('sofá', female: false, standable: true, seated: true),
  cama('cama', female: true, standable: true),
  alfombra('alfombra', female: true, standable: true),
  mesa('mesa', female: true),
  tv('TV', female: true),
  planta('planta', female: true),
  arbusto('arbusto', female: false, groupOverride: 'planta'),
  armario('armario', female: false),
  caja('caja', female: true),
  lavadora('lavadora', female: true),
  piano('piano', female: false),
  barra('barra', female: true);

  final String nameEs;
  final bool female;

  /// true: la gente puede estar encima; false: bloquea la celda.
  final bool standable;

  /// true: "sentado en" en vez de "sobre".
  final bool seated;
  final String? groupOverride;

  const ObjectType(
    this.nameEs, {
    required this.female,
    this.standable = false,
    this.seated = false,
    this.groupOverride,
  });

  /// Grupo de pista: planta y arbusto comparten "planta".
  String get group => groupOverride ?? name;

  String get indefEs => '${female ? 'una' : 'un'} $nameEs';
  String get defEs => '${female ? 'la' : 'el'} $nameEs';
}

class Area {
  final String id;
  final String nameEs;
  final List<int> cells;

  const Area({required this.id, required this.nameEs, required this.cells});
}

/// Mueble u objeto del mapa. Puede ocupar varias celdas (cama, mesa larga).
class MapObject {
  final String id;
  final ObjectType type;
  final List<int> cells;

  const MapObject({required this.id, required this.type, required this.cells});

  bool get blocks => !type.standable;
}

/// Arma potencial visible: vive en un área fija del mapa, no bloquea celda.
class WeaponDef {
  final String id;
  final String nameEs;
  final WeaponCategory category;
  final String areaId;

  const WeaponDef({
    required this.id,
    required this.nameEs,
    required this.category,
    required this.areaId,
  });
}

class Character {
  final String id;
  final String nameEs;
  final bool female;

  const Character(
      {required this.id, required this.nameEs, required this.female});
}

/// Mapa autorado. Grilla cuadrada de size × size.
/// Invariantes (validados en el constructor):
/// - toda celda pertenece a exactamente un área
/// - objetos dentro de grilla y sin solaparse entre sí
/// - armas en áreas existentes
class GameMap {
  final String id;
  final String nameEs;
  final int size;
  final List<Area> areas;
  final List<MapObject> objects;
  final List<WeaponDef> weapons;

  late final List<String> _areaIdByCell;
  late final List<MapObject?> _objectByCell;

  GameMap({
    required this.id,
    required this.nameEs,
    required this.size,
    required this.areas,
    this.objects = const [],
    this.weapons = const [],
  }) {
    final total = size * size;
    final byCell = List<String?>.filled(total, null);
    for (final area in areas) {
      for (final cell in area.cells) {
        if (cell < 0 || cell >= total) {
          throw ArgumentError('Área ${area.id}: celda $cell fuera de grilla');
        }
        if (byCell[cell] != null) {
          throw ArgumentError(
              'Celda $cell en dos áreas: ${byCell[cell]} y ${area.id}');
        }
        byCell[cell] = area.id;
      }
    }
    for (var i = 0; i < total; i++) {
      if (byCell[i] == null) {
        throw ArgumentError('Celda $i sin área asignada');
      }
    }
    _areaIdByCell = byCell.cast<String>();

    _objectByCell = List<MapObject?>.filled(total, null);
    for (final obj in objects) {
      for (final cell in obj.cells) {
        if (cell < 0 || cell >= total) {
          throw ArgumentError('Objeto ${obj.id}: celda fuera de grilla');
        }
        if (_objectByCell[cell] != null) {
          throw ArgumentError('Celda $cell con dos objetos: '
              '${_objectByCell[cell]!.id} y ${obj.id}');
        }
        _objectByCell[cell] = obj;
      }
    }
    for (final w in weapons) {
      area(w.areaId); // lanza si no existe
    }
  }

  int row(int cell) => cell ~/ size;
  int col(int cell) => cell % size;
  int cellAt(int r, int c) => r * size + c;
  bool inGrid(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  String areaIdOf(int cell) => _areaIdByCell[cell];

  Area area(String id) => areas.firstWhere(
        (a) => a.id == id,
        orElse: () => throw ArgumentError('Área inexistente: $id'),
      );

  /// Objeto que cubre la celda (o null).
  MapObject? objectAt(int cell) => _objectByCell[cell];

  bool isOccupiable(int cell) => !(_objectByCell[cell]?.blocks ?? false);

  List<int> get occupiableCells =>
      [for (var i = 0; i < size * size; i++) if (isOccupiable(i)) i];

  bool sameArea(int a, int b) => _areaIdByCell[a] == _areaIdByCell[b];

  /// Vecinos ortogonales (arriba, abajo, izquierda, derecha) dentro de grilla.
  List<int> orthNeighbors(int cell) {
    final r = row(cell), c = col(cell);
    return [
      if (inGrid(r - 1, c)) cellAt(r - 1, c),
      if (inGrid(r + 1, c)) cellAt(r + 1, c),
      if (inGrid(r, c - 1)) cellAt(r, c - 1),
      if (inGrid(r, c + 1)) cellAt(r, c + 1),
    ];
  }

  /// "Junto a" entre personas: adyacencia ortogonal Y misma área (spec 1.4).
  bool besideInArea(int a, int b) =>
      sameArea(a, b) && orthNeighbors(a).contains(b);

  // ---- Consultas de muebles (vocabulario de pistas Murdoku) ----------------

  List<MapObject> objectsOfGroup(String group) =>
      [for (final o in objects) if (o.type.group == group) o];

  /// Cuántos muebles del grupo hay en el mapa (decide "la silla" vs
  /// "una silla" en el texto de la pista).
  int countOfGroup(String group) => objectsOfGroup(group).length;

  /// ¿La persona en [cell] está ENCIMA de un mueble del grupo?
  bool isOnGroup(int cell, String group) {
    final o = _objectByCell[cell];
    return o != null && o.type.standable && o.type.group == group;
  }

  /// Celdas donde alguien puede estar "sobre {grupo}".
  Set<int> cellsOnGroup(String group) => {
        for (final o in objectsOfGroup(group))
          if (o.type.standable) ...o.cells
      };

  /// ¿La persona en [cell] está JUNTO A un mueble del grupo?
  /// Adyacente ortogonal a alguna celda del mueble, misma área, y no
  /// encima de ese mismo mueble.
  bool isBesideGroup(int cell, String group) {
    for (final o in objectsOfGroup(group)) {
      if (o.cells.contains(cell)) continue;
      for (final oc in o.cells) {
        if (sameArea(cell, oc) && orthNeighbors(cell).contains(oc)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Celdas (ocupables) que cumplen "junto a {grupo}".
  Set<int> cellsBesideGroup(String group) => {
        for (final c in occupiableCells)
          if (isBesideGroup(c, group)) c
      };

  /// Grupos de mueble presentes en el mapa.
  Set<String> get objectGroups => {for (final o in objects) o.type.group};

  List<WeaponDef> weaponsInArea(String areaId) =>
      [for (final w in weapons) if (w.areaId == areaId) w];

  /// Serialización: el mapa viaja embebido en cada caso (cada caso tiene
  /// su propio mapa generado — decisión 2026-06-11).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name_es': nameEs,
        'size': size,
        'areas': [
          for (final a in areas)
            {'id': a.id, 'name_es': a.nameEs, 'cells': a.cells}
        ],
        'objects': [
          for (final o in objects)
            {'id': o.id, 'type': o.type.name, 'cells': o.cells}
        ],
        'weapons': [
          for (final w in weapons)
            {
              'id': w.id,
              'name_es': w.nameEs,
              'category': w.category.name,
              'area': w.areaId,
            }
        ],
      };

  factory GameMap.fromJson(Map<String, dynamic> j) => GameMap(
        id: j['id'] as String,
        nameEs: j['name_es'] as String,
        size: j['size'] as int,
        areas: [
          for (final a in (j['areas'] as List))
            Area(
              id: a['id'] as String,
              nameEs: a['name_es'] as String,
              cells: (a['cells'] as List).cast<int>(),
            )
        ],
        objects: [
          for (final o in (j['objects'] as List))
            MapObject(
              id: o['id'] as String,
              type: ObjectType.values.byName(o['type'] as String),
              cells: (o['cells'] as List).cast<int>(),
            )
        ],
        weapons: [
          for (final w in (j['weapons'] as List))
            WeaponDef(
              id: w['id'] as String,
              nameEs: w['name_es'] as String,
              category: WeaponCategory.values.byName(w['category'] as String),
              areaId: w['area'] as String,
            )
        ],
      );
}
