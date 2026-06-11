/// Tipos de pista y su semántica formal.
/// Tabla de referencia: docs/16-spec-puzzle.md sección 3.1.
/// La semántica de cada tipo vive AQUÍ y solo aquí.
library;

import 'model.dart';

/// Contexto de evaluación: asignación completa de posiciones.
class ClueContext {
  final GameMap map;

  /// charId -> celda.
  final Map<String, int> positions;
  final String victimId;

  /// Arma homicida (solo casos con arma); null si el caso no tiene.
  final String? lethalWeaponId;

  const ClueContext({
    required this.map,
    required this.positions,
    required this.victimId,
    this.lethalWeaponId,
  });

  int pos(String charId) => positions[charId]!;

  /// Personas (ids) en el área dada.
  List<String> occupantsOf(String areaId) => [
        for (final e in positions.entries)
          if (map.areaIdOf(e.value) == areaId) e.key
      ];
}

sealed class Clue {
  const Clue();

  /// ¿La pista se cumple en la asignación completa [ctx]?
  bool holds(ClueContext ctx);

  /// Texto en español, orientación canónica (la rotación es de Fase 1+).
  String textEs(GameMap map, String Function(String charId) nameOf);

  Map<String, dynamic> toJson();

  static Clue fromJson(Map<String, dynamic> j) {
    final t = j['type'] as String;
    return switch (t) {
      'in_area' => InArea(j['subject'] as String, j['area'] as String),
      'not_in_area' => NotInArea(j['subject'] as String, j['area'] as String),
      'same_area' => SameArea(j['a'] as String, j['b'] as String),
      'not_same_area' => NotSameArea(j['a'] as String, j['b'] as String),
      'beside' => BesideChar(j['a'] as String, j['b'] as String),
      'beside_object' =>
        BesideObject(j['subject'] as String, j['object'] as String),
      'alone' => Alone(j['subject'] as String),
      'alone_with' => AloneWith(j['a'] as String, j['b'] as String),
      'area_empty' => AreaEmpty(j['area'] as String),
      'cardinal' => Cardinal(j['subject'] as String, j['other'] as String,
          Direction.values.byName(j['dir'] as String)),
      'in_row' => InRow(j['subject'] as String, j['index'] as int),
      'in_col' => InCol(j['subject'] as String, j['index'] as int),
      'corner' => CornerClue(j['subject'] as String, j['area'] as String?),
      'weapon_area' => WeaponInArea(j['area'] as String),
      'weapon_category' =>
        WeaponCat(WeaponCategory.values.byName(j['category'] as String)),
      'weapon_exact' => WeaponExact(j['weapon'] as String),
      _ => throw ArgumentError('Tipo de pista desconocido: $t'),
    };
  }
}

/// "X estaba en {área}".
class InArea extends Clue {
  final String subject;
  final String areaId;
  const InArea(this.subject, this.areaId);

  @override
  bool holds(ClueContext ctx) => ctx.map.areaIdOf(ctx.pos(subject)) == areaId;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba en ${map.area(areaId).nameEs}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'in_area', 'subject': subject, 'area': areaId};
}

/// "X no estaba en {área}".
class NotInArea extends Clue {
  final String subject;
  final String areaId;
  const NotInArea(this.subject, this.areaId);

  @override
  bool holds(ClueContext ctx) => ctx.map.areaIdOf(ctx.pos(subject)) != areaId;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} no estaba en ${map.area(areaId).nameEs}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'not_in_area', 'subject': subject, 'area': areaId};
}

/// "X estaba con Y" (misma área).
class SameArea extends Clue {
  final String a;
  final String b;
  const SameArea(this.a, this.b);

  @override
  bool holds(ClueContext ctx) => ctx.map.sameArea(ctx.pos(a), ctx.pos(b));

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(a)} estaba con ${nameOf(b)}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'same_area', 'a': a, 'b': b};
}

/// "X no estaba con Y" (áreas distintas).
class NotSameArea extends Clue {
  final String a;
  final String b;
  const NotSameArea(this.a, this.b);

  @override
  bool holds(ClueContext ctx) => !ctx.map.sameArea(ctx.pos(a), ctx.pos(b));

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(a)} no estaba con ${nameOf(b)}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'not_same_area', 'a': a, 'b': b};
}

/// "X estaba junto a Y": adyacencia ortogonal Y misma área (spec 1.4).
class BesideChar extends Clue {
  final String a;
  final String b;
  const BesideChar(this.a, this.b);

  @override
  bool holds(ClueContext ctx) => ctx.map.besideInArea(ctx.pos(a), ctx.pos(b));

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(a)} estaba junto a ${nameOf(b)}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'beside', 'a': a, 'b': b};
}

/// "X estaba junto a {objeto}": adyacente ortogonal a la celda del objeto,
/// en el área del objeto.
class BesideObject extends Clue {
  final String subject;
  final String objectId;
  const BesideObject(this.subject, this.objectId);

  @override
  bool holds(ClueContext ctx) {
    final objCell = ctx.map.objectById(objectId).cell;
    final p = ctx.pos(subject);
    return ctx.map.sameArea(p, objCell) &&
        ctx.map.orthNeighbors(objCell).contains(p);
  }

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba junto a ${map.objectById(objectId).nameEs}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'beside_object', 'subject': subject, 'object': objectId};
}

/// "X estaba a solas": nadie más en su área (ni la víctima).
class Alone extends Clue {
  final String subject;
  const Alone(this.subject);

  @override
  bool holds(ClueContext ctx) =>
      ctx.occupantsOf(ctx.map.areaIdOf(ctx.pos(subject))).length == 1;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba a solas.';

  @override
  Map<String, dynamic> toJson() => {'type': 'alone', 'subject': subject};
}

/// "X estaba a solas con Y": exactamente {X, Y} en ese área.
class AloneWith extends Clue {
  final String a;
  final String b;
  const AloneWith(this.a, this.b);

  @override
  bool holds(ClueContext ctx) {
    final areaId = ctx.map.areaIdOf(ctx.pos(a));
    final occ = ctx.occupantsOf(areaId);
    return occ.length == 2 && occ.contains(a) && occ.contains(b);
  }

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(a)} estaba a solas con ${nameOf(b)}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'alone_with', 'a': a, 'b': b};
}

/// "Nadie estaba en {área}".
class AreaEmpty extends Clue {
  final String areaId;
  const AreaEmpty(this.areaId);

  @override
  bool holds(ClueContext ctx) => ctx.occupantsOf(areaId).isEmpty;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      'Nadie estaba en ${map.area(areaId).nameEs}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'area_empty', 'area': areaId};
}

/// "X estaba al {oeste} de Y": comparación estricta de coordenada,
/// en cualquier fila/columna y cualquier área (spec 1.4).
class Cardinal extends Clue {
  final String subject;
  final String other;
  final Direction dir;
  const Cardinal(this.subject, this.other, this.dir);

  @override
  bool holds(ClueContext ctx) {
    final m = ctx.map;
    final p = ctx.pos(subject), q = ctx.pos(other);
    return switch (dir) {
      Direction.west => m.col(p) < m.col(q),
      Direction.east => m.col(p) > m.col(q),
      Direction.north => m.row(p) < m.row(q),
      Direction.south => m.row(p) > m.row(q),
    };
  }

  static const _dirEs = {
    Direction.north: 'norte',
    Direction.south: 'sur',
    Direction.east: 'este',
    Direction.west: 'oeste',
  };

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba al ${_dirEs[dir]} de ${nameOf(other)}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'cardinal', 'subject': subject, 'other': other, 'dir': dir.name};
}

/// "X estaba en la fila {n}" (1-based en texto, 0-based interno).
class InRow extends Clue {
  final String subject;
  final int index;
  const InRow(this.subject, this.index);

  @override
  bool holds(ClueContext ctx) => ctx.map.row(ctx.pos(subject)) == index;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba en la fila ${index + 1}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'in_row', 'subject': subject, 'index': index};
}

/// "X estaba en la columna {n}".
class InCol extends Clue {
  final String subject;
  final int index;
  const InCol(this.subject, this.index);

  @override
  bool holds(ClueContext ctx) => ctx.map.col(ctx.pos(subject)) == index;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      '${nameOf(subject)} estaba en la columna ${index + 1}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'in_col', 'subject': subject, 'index': index};
}

/// "X estaba en una esquina (de {área})". Si area es null: esquina de
/// cualquier área.
class CornerClue extends Clue {
  final String subject;
  final String? areaId;
  const CornerClue(this.subject, this.areaId);

  @override
  bool holds(ClueContext ctx) {
    final p = ctx.pos(subject);
    if (!ctx.map.isCorner(p)) return false;
    return areaId == null || ctx.map.areaIdOf(p) == areaId;
  }

  @override
  String textEs(GameMap map, String Function(String) nameOf) => areaId == null
      ? '${nameOf(subject)} estaba en una esquina.'
      : '${nameOf(subject)} estaba en una esquina de ${map.area(areaId!).nameEs}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'corner', 'subject': subject, 'area': areaId};
}

/// "El arma está en {área}". Habla del ARMA HOMICIDA.
class WeaponInArea extends Clue {
  final String areaId;
  const WeaponInArea(this.areaId);

  @override
  bool holds(ClueContext ctx) {
    final lethal = ctx.lethalWeaponId;
    if (lethal == null) return false;
    return ctx.map.weapons.firstWhere((w) => w.id == lethal).areaId == areaId;
  }

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      'El arma homicida está en ${map.area(areaId).nameEs}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'weapon_area', 'area': areaId};
}

/// "El arma es de tipo {categoría}".
class WeaponCat extends Clue {
  final WeaponCategory category;
  const WeaponCat(this.category);

  @override
  bool holds(ClueContext ctx) {
    final lethal = ctx.lethalWeaponId;
    if (lethal == null) return false;
    return ctx.map.weapons.firstWhere((w) => w.id == lethal).category ==
        category;
  }

  static const _catEs = {
    WeaponCategory.cortante: 'un arma cortante',
    WeaponCategory.contundente: 'un arma contundente',
    WeaponCategory.veneno: 'un veneno',
    WeaponCategory.asfixia: 'un arma de asfixia o atadura',
  };

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      'El arma homicida es ${_catEs[category]}.';

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'weapon_category', 'category': category.name};
}

/// "El arma es {nombre}".
class WeaponExact extends Clue {
  final String weaponId;
  const WeaponExact(this.weaponId);

  @override
  bool holds(ClueContext ctx) => ctx.lethalWeaponId == weaponId;

  @override
  String textEs(GameMap map, String Function(String) nameOf) =>
      'El arma homicida es ${map.weapons.firstWhere((w) => w.id == weaponId).nameEs}.';

  @override
  Map<String, dynamic> toJson() => {'type': 'weapon_exact', 'weapon': weaponId};
}
