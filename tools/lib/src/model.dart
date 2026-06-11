/// Modelo del tablero de Enigmatrix.
/// Fuente conceptual: docs/16-spec-puzzle.md (secciones 1 y 2).

/// Direcciones cardinales en orientación canónica (fila 0 = norte).
enum Direction { north, south, east, west }

/// Categorías lógicas de arma (doc 03). No se muestran en UI.
enum WeaponCategory { cortante, contundente, veneno, asfixia }

class Area {
  final String id;
  final String nameEs;
  final List<int> cells;

  const Area({required this.id, required this.nameEs, required this.cells});
}

class MapObject {
  final String id;
  final String nameEs;
  final int cell;

  /// true: la celda no es ocupable por personajes (mesa, planta...).
  final bool blocks;

  const MapObject({
    required this.id,
    required this.nameEs,
    required this.cell,
    this.blocks = true,
  });
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

  const Character({required this.id, required this.nameEs});
}

/// Mapa autorado. Grilla cuadrada de size × size.
/// Invariantes (validados en el constructor):
/// - toda celda pertenece a exactamente un área
/// - las áreas referencian celdas dentro de la grilla
/// - los objetos y armas referencian celdas/áreas existentes
class GameMap {
  final String id;
  final String nameEs;
  final int size;
  final List<Area> areas;
  final List<MapObject> objects;
  final List<WeaponDef> weapons;

  late final List<String> _areaIdByCell;
  late final List<bool> _occupiable;

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

    _occupiable = List<bool>.filled(total, true);
    for (final obj in objects) {
      if (obj.cell < 0 || obj.cell >= total) {
        throw ArgumentError('Objeto ${obj.id}: celda fuera de grilla');
      }
      if (obj.blocks) _occupiable[obj.cell] = false;
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

  bool isOccupiable(int cell) => _occupiable[cell];

  List<int> get occupiableCells =>
      [for (var i = 0; i < size * size; i++) if (_occupiable[i]) i];

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

  /// "Junto a": adyacencia ortogonal Y misma área (spec 1.4).
  bool besideInArea(int a, int b) =>
      sameArea(a, b) && orthNeighbors(a).contains(b);

  /// Esquina de un área: al menos una pared vertical (N o S) Y una
  /// horizontal (E u O) — donde "pared" = borde de grilla o cambio de área.
  bool isCorner(int cell) {
    final r = row(cell), c = col(cell);
    bool wall(int rr, int cc) =>
        !inGrid(rr, cc) || _areaIdByCell[cellAt(rr, cc)] != _areaIdByCell[cell];
    final vertical = wall(r - 1, c) || wall(r + 1, c);
    final horizontal = wall(r, c - 1) || wall(r, c + 1);
    return vertical && horizontal;
  }

  List<WeaponDef> weaponsInArea(String areaId) =>
      [for (final w in weapons) if (w.areaId == areaId) w];

  MapObject objectById(String id) => objects.firstWhere(
        (o) => o.id == id,
        orElse: () => throw ArgumentError('Objeto inexistente: $id'),
      );
}
