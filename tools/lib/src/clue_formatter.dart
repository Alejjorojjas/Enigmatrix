/// Redacción de las pistas por idioma (H-63).
///
/// La SEMÁNTICA de cada pista (cuándo se cumple) vive en clue.dart. Aquí
/// vive solo la REDACCIÓN: cómo se dice en un idioma. Hoy existe el español
/// ([ClueFormatterEs]); para agregar inglés se crea un `ClueFormatterEn`
/// que extienda [ClueFormatter] y se registra en [ClueFormatter.forLanguage].
/// Como [Clue] es una clase sellada, el `switch` de cada formateador es
/// exhaustivo: al agregar un tipo de pista el compilador exige redactarlo en
/// todos los idiomas.
library;

import 'clue.dart';
import 'model.dart';

abstract class ClueFormatter {
  const ClueFormatter();

  /// Código de idioma ("es", "en"...).
  String get languageCode;

  /// Predicado sin el sujeto: "estaba en el Salón". Para pistas sin sujeto
  /// (área vacía, arma) devuelve la frase completa.
  String predicate(Clue clue, GameMap map, ClueNames names);

  /// Frase completa: "Adela estaba en el Salón."
  String text(Clue clue, GameMap map, ClueNames names) {
    final p = predicate(clue, map, names);
    final subject = clue.subjectId;
    if (subject == null) return p;
    return '${names.nameOf(subject)} $p.';
  }

  /// Texto de la tarjeta del personaje (sin nombre): "Estaba en el Salón."
  String cardText(Clue clue, GameMap map, ClueNames names) {
    final p = predicate(clue, map, names);
    return '${p[0].toUpperCase()}${p.substring(1)}'
        '${clue.subjectId == null ? '' : '.'}';
  }

  /// Idiomas con formateador disponible. Para sumar inglés: agregar aquí
  /// `'en': ClueFormatterEn.instance` (no existe todavía).
  static const Map<String, ClueFormatter> _registry = {
    'es': ClueFormatterEs.instance,
  };

  static Iterable<String> get supportedLanguages => _registry.keys;

  /// Formateador del idioma dado. Lanza [ArgumentError] si no existe.
  static ClueFormatter forLanguage(String code) {
    final f = _registry[code];
    if (f == null) {
      throw ArgumentError('Idioma sin formateador de pistas: $code '
          '(disponibles: ${_registry.keys.join(', ')})');
    }
    return f;
  }
}

/// Redacción en español de las pistas.
class ClueFormatterEs extends ClueFormatter {
  const ClueFormatterEs._();

  static const instance = ClueFormatterEs._();

  @override
  String get languageCode => 'es';

  @override
  String predicate(Clue clue, GameMap map, ClueNames names) => switch (clue) {
        InArea(:final areaId) => 'estaba en ${map.area(areaId).nameEs}',
        NotInArea(:final areaId) => 'no estaba en ${map.area(areaId).nameEs}',
        OnObjectGroup(:final subject, :final group) =>
          _onObject(map, names, subject, group),
        BesideObjectGroup(:final group) =>
          'estaba ${_besideText(map, group)}',
        OnlyOneOnGroup(:final group) => _onlyOneOn(map, group),
        CompoundClue(:final parts) => _compound(map, names, parts),
        LastFreeCell() => 'estaba en la última casilla libre',
        SameArea(:final b) => 'estaba con ${names.nameOf(b)}',
        NotSameArea(:final b) => 'no estaba con ${names.nameOf(b)}',
        BesideChar(:final b) => 'estaba junto a ${names.nameOf(b)}',
        Alone(:final subject) =>
          names.isFemale(subject) ? 'estaba sola' : 'estaba solo',
        AloneWith(:final b) => 'estaba a solas con ${names.nameOf(b)}',
        AreaEmpty(:final areaId) =>
          'Nadie estaba en ${map.area(areaId).nameEs}.',
        WeaponInArea(:final areaId) =>
          'El arma homicida está en ${map.area(areaId).nameEs}.',
        WeaponCat(:final category) =>
          'El arma homicida es ${_weaponCategoryEs[category]}.',
        WeaponExact(:final weaponId) =>
          'El arma homicida es ${map.weapons.firstWhere((w) => w.id == weaponId).nameEs}.',
      };

  /// "estaba sobre una cama" / "estaba sentada en la silla".
  String _onObject(GameMap map, ClueNames names, String subject, String group) {
    final type = ObjectType.values.byName(group);
    final obj = _groupText(map, group);
    if (type.seated) {
      final seated = names.isFemale(subject) ? 'sentada' : 'sentado';
      return 'estaba $seated en $obj';
    }
    return 'estaba sobre $obj';
  }

  /// "era la única persona sobre una alfombra" / "... sentada en una silla".
  String _onlyOneOn(GameMap map, String group) {
    final type = ObjectType.values.byName(group);
    final obj = _groupText(map, group);
    return type.seated
        ? 'era la única persona sentada en $obj'
        : 'era la única persona sobre $obj';
  }

  /// "estaba en la Cocina y estaba junto a una mesa" ->
  /// "estaba en la Cocina y junto a una mesa".
  String _compound(GameMap map, ClueNames names, List<Clue> parts) {
    final preds = [for (final p in parts) predicate(p, map, names)];
    for (var i = 1; i < preds.length; i++) {
      if (preds[i].startsWith('estaba ')) {
        preds[i] = preds[i].substring('estaba '.length);
      }
    }
    return preds.join(' y ');
  }

  /// "una silla" / "la silla" (definido si solo hay un mueble de ese grupo
  /// en el mapa).
  String _groupText(GameMap map, String group) {
    final type = ObjectType.values.byName(group);
    return map.countOfGroup(group) == 1 ? type.defEs : type.indefEs;
  }

  /// "junto a" + objeto, con la contracción del español "a el" -> "al".
  String _besideText(GameMap map, String group) {
    final obj = _groupText(map, group);
    return obj.startsWith('el ')
        ? 'junto al ${obj.substring(3)}'
        : 'junto a $obj';
  }

  static const _weaponCategoryEs = {
    WeaponCategory.cortante: 'un arma cortante',
    WeaponCategory.contundente: 'un arma contundente',
    WeaponCategory.veneno: 'un veneno',
    WeaponCategory.asfixia: 'un arma de asfixia o atadura',
  };
}
