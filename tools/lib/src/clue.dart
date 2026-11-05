/// Tipos de pista y su semántica formal — vocabulario Murdoku
/// (decisiones 2026-06-11: pistas de áreas, muebles y personas;
/// sin pistas mecánicas de fila/columna/esquina/cardinales en V1).
/// Tabla de referencia: docs/16-spec-puzzle.md sección 3.1.
/// La semántica de cada tipo vive AQUÍ y solo aquí. La REDACCIÓN por idioma
/// vive en clue_formatter.dart (H-63).
library;

import 'clue_formatter.dart';
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

/// Resolución de nombres y género para los textos de pista.
class ClueNames {
  final String Function(String charId) nameOf;
  final bool Function(String charId) isFemale;

  const ClueNames({required this.nameOf, required this.isFemale});
}

sealed class Clue {
  const Clue();

  /// Personaje del que habla la pista (dueño de la tarjeta).
  /// null para pistas sueltas (área vacía, arma).
  String? get subjectId => null;

  /// ¿La pista se cumple en la asignación completa [ctx]?
  bool holds(ClueContext ctx);

  /// Predicado en español sin el sujeto: "estaba en el Salón".
  /// Para pistas sin sujeto devuelve la frase completa.
  /// La redacción vive en [ClueFormatterEs] (clue_formatter.dart); estos
  /// métodos delegan para que la app y las herramientas sigan igual.
  String predicateEs(GameMap map, ClueNames names) =>
      ClueFormatterEs.instance.predicate(this, map, names);

  /// Frase completa: "Adela estaba en el Salón."
  String textEs(GameMap map, ClueNames names) =>
      ClueFormatterEs.instance.text(this, map, names);

  /// Texto para la tarjeta del personaje (sin nombre): "Estaba en el Salón."
  String cardTextEs(GameMap map, ClueNames names) =>
      ClueFormatterEs.instance.cardText(this, map, names);

  Map<String, dynamic> toJson();

  static Clue fromJson(Map<String, dynamic> j) {
    final t = j['type'] as String;
    return switch (t) {
      'in_area' => InArea(j['subject'] as String, j['area'] as String),
      'not_in_area' => NotInArea(j['subject'] as String, j['area'] as String),
      'same_area' => SameArea(j['a'] as String, j['b'] as String),
      'not_same_area' => NotSameArea(j['a'] as String, j['b'] as String),
      'beside' => BesideChar(j['a'] as String, j['b'] as String),
      'on_object' => OnObjectGroup(j['subject'] as String, j['group'] as String),
      'beside_object' =>
        BesideObjectGroup(j['subject'] as String, j['group'] as String),
      'only_one_on' =>
        OnlyOneOnGroup(j['subject'] as String, j['group'] as String),
      'compound' => CompoundClue(
          j['subject'] as String,
          [
            for (final p in (j['parts'] as List))
              Clue.fromJson((p as Map).cast<String, dynamic>())
          ],
        ),
      'victim_filler' => LastFreeCell(j['subject'] as String),
      'alone' => Alone(j['subject'] as String),
      'alone_with' => AloneWith(j['a'] as String, j['b'] as String),
      'area_empty' => AreaEmpty(j['area'] as String),
      'weapon_area' => WeaponInArea(j['area'] as String),
      'weapon_category' =>
        WeaponCat(WeaponCategory.values.byName(j['category'] as String)),
      'weapon_exact' => WeaponExact(j['weapon'] as String),
      _ => throw ArgumentError('Tipo de pista desconocido: $t'),
    };
  }
}

/// "Estaba en {área}".
class InArea extends Clue {
  final String subject;
  final String areaId;
  const InArea(this.subject, this.areaId);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) => ctx.map.areaIdOf(ctx.pos(subject)) == areaId;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'in_area', 'subject': subject, 'area': areaId};
}

/// "No estaba en {área}".
class NotInArea extends Clue {
  final String subject;
  final String areaId;
  const NotInArea(this.subject, this.areaId);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) => ctx.map.areaIdOf(ctx.pos(subject)) != areaId;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'not_in_area', 'subject': subject, 'area': areaId};
}

/// "Estaba sobre una cama" / "Estaba sentada en la silla".
/// La persona está ENCIMA de un mueble pisable del grupo.
class OnObjectGroup extends Clue {
  final String subject;
  final String group;
  const OnObjectGroup(this.subject, this.group);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) => ctx.map.isOnGroup(ctx.pos(subject), group);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'on_object', 'subject': subject, 'group': group};
}

/// "Estaba junto a una planta": adyacente ortogonal a alguna celda de un
/// mueble del grupo, en la misma área, sin estar encima de ese mueble.
class BesideObjectGroup extends Clue {
  final String subject;
  final String group;
  const BesideObjectGroup(this.subject, this.group);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) =>
      ctx.map.isBesideGroup(ctx.pos(subject), group);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'beside_object', 'subject': subject, 'group': group};
}

/// "Era la única persona sobre una alfombra": está encima de un mueble del
/// grupo Y nadie más está encima de ningún mueble de ese grupo.
class OnlyOneOnGroup extends Clue {
  final String subject;
  final String group;
  const OnlyOneOnGroup(this.subject, this.group);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) {
    if (!ctx.map.isOnGroup(ctx.pos(subject), group)) return false;
    for (final e in ctx.positions.entries) {
      if (e.key != subject && ctx.map.isOnGroup(e.value, group)) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'only_one_on', 'subject': subject, 'group': group};
}

/// Pista compuesta: "estaba junto a una planta y sobre una cama".
/// Todas las partes hablan del mismo personaje y deben cumplirse.
class CompoundClue extends Clue {
  final String subject;
  final List<Clue> parts;
  const CompoundClue(this.subject, this.parts);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) => parts.every((p) => p.holds(ctx));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'compound',
        'subject': subject,
        'parts': [for (final p in parts) p.toJson()],
      };
}

/// Relleno de la víctima: "Estaba en la última casilla libre."
/// No aporta información: el caso se resuelve con las demás pistas.
class LastFreeCell extends Clue {
  final String subject;
  const LastFreeCell(this.subject);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) => true;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'victim_filler', 'subject': subject};
}

/// "Estaba con {persona}" (misma área).
class SameArea extends Clue {
  final String a;
  final String b;
  const SameArea(this.a, this.b);

  @override
  String get subjectId => a;

  @override
  bool holds(ClueContext ctx) => ctx.map.sameArea(ctx.pos(a), ctx.pos(b));

  @override
  Map<String, dynamic> toJson() => {'type': 'same_area', 'a': a, 'b': b};
}

/// "No estaba con {persona}" (áreas distintas).
class NotSameArea extends Clue {
  final String a;
  final String b;
  const NotSameArea(this.a, this.b);

  @override
  String get subjectId => a;

  @override
  bool holds(ClueContext ctx) => !ctx.map.sameArea(ctx.pos(a), ctx.pos(b));

  @override
  Map<String, dynamic> toJson() => {'type': 'not_same_area', 'a': a, 'b': b};
}

/// "Estaba junto a {persona}": adyacencia ortogonal Y misma área (spec 1.4).
class BesideChar extends Clue {
  final String a;
  final String b;
  const BesideChar(this.a, this.b);

  @override
  String get subjectId => a;

  @override
  bool holds(ClueContext ctx) => ctx.map.besideInArea(ctx.pos(a), ctx.pos(b));

  @override
  Map<String, dynamic> toJson() => {'type': 'beside', 'a': a, 'b': b};
}

/// "Estaba a solas": nadie más en su área (ni la víctima).
class Alone extends Clue {
  final String subject;
  const Alone(this.subject);

  @override
  String get subjectId => subject;

  @override
  bool holds(ClueContext ctx) =>
      ctx.occupantsOf(ctx.map.areaIdOf(ctx.pos(subject))).length == 1;

  @override
  Map<String, dynamic> toJson() => {'type': 'alone', 'subject': subject};
}

/// "Estaba a solas con {persona}": exactamente {a, b} en ese área.
class AloneWith extends Clue {
  final String a;
  final String b;
  const AloneWith(this.a, this.b);

  @override
  String get subjectId => a;

  @override
  bool holds(ClueContext ctx) {
    final areaId = ctx.map.areaIdOf(ctx.pos(a));
    final occ = ctx.occupantsOf(areaId);
    return occ.length == 2 && occ.contains(a) && occ.contains(b);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'alone_with', 'a': a, 'b': b};
}

/// "Nadie estaba en {área}." Pista suelta (sin tarjeta).
class AreaEmpty extends Clue {
  final String areaId;
  const AreaEmpty(this.areaId);

  @override
  bool holds(ClueContext ctx) => ctx.occupantsOf(areaId).isEmpty;

  @override
  Map<String, dynamic> toJson() => {'type': 'area_empty', 'area': areaId};
}

/// "El arma homicida está en {área}." Pista suelta.
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
  Map<String, dynamic> toJson() => {'type': 'weapon_area', 'area': areaId};
}

/// "El arma homicida es {categoría}." Pista suelta.
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

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'weapon_category', 'category': category.name};
}

/// "El arma homicida es {nombre}." Pista suelta.
class WeaponExact extends Clue {
  final String weaponId;
  const WeaponExact(this.weaponId);

  @override
  bool holds(ClueContext ctx) => ctx.lethalWeaponId == weaponId;

  @override
  Map<String, dynamic> toJson() => {'type': 'weapon_exact', 'weapon': weaponId};
}
