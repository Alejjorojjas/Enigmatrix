/// Datos de un mundo temático (ronda 3.2): elenco, habitaciones y armas.
///
/// El generador de mapas y casos puede recibir un [WorldData] para usar sus
/// nombres en vez de los genéricos. NO cambia la lógica: solo el vocabulario
/// (nombres de personas, de habitaciones, muebles permitidos por habitación y
/// armas del mundo). Sin mundo, el motor se comporta exactamente como antes.
///
/// Formato (tools/data/mundos/<id>.json): ver mansion.json. Pura (sin
/// dart:io): el archivo se lee en tooling/world_files.dart.
library;

import 'dart:math';

import 'map_rules.dart';
import 'model.dart';

/// Un personaje posible del elenco.
class CastMember {
  final String name;
  final bool female;

  /// Arquetipo de época con artículo ("la institutriz"). Es sabor: no entra
  /// en la lógica del caso ni lo guarda el JSON del caso.
  final String archetype;

  const CastMember(
      {required this.name, required this.female, required this.archetype});

  /// Inicial en mayúscula (la ficha del tablero muestra esa letra).
  String get initial => name.substring(0, 1).toUpperCase();
}

/// Una habitación del mundo y los muebles que tienen sentido en ella.
class WorldRoom {
  final String id;
  final String nameEs;
  final List<ObjectType> furniture;

  const WorldRoom(
      {required this.id, required this.nameEs, required this.furniture});
}

/// Un arma permitida en el mundo (nunca de fuego, docs/13).
class WorldWeapon {
  final String id;
  final String nameEs;
  final WeaponCategory category;

  const WorldWeapon(
      {required this.id, required this.nameEs, required this.category});
}

/// Palabras que NO pueden aparecer en el nombre de un arma (docs/13: nunca
/// armas de fuego, militares ni explosivos). Se comparan en minúsculas y sin
/// tildes. Las usa la validación del mundo y la puerta de contenido.
const kForbiddenWeaponWords = [
  'pistola',
  'revolver',
  'escopeta',
  'rifle',
  'fusil',
  'carabina',
  'arma de fuego',
  'disparo',
  'bala',
  'municion',
  'bomba',
  'granada',
  'explosivo',
  'dinamita',
  'metralleta',
  'ametralladora',
  'canon',
  'misil',
];

/// Minúsculas y sin tildes (para comparar palabras).
String foldEs(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunaeiouun';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch.toLowerCase());
  }
  return b.toString();
}

/// Primera palabra prohibida que contiene [text] como palabra suelta (no
/// dentro de otra palabra más larga), o null.
String? forbiddenWeaponWord(String text) {
  final t = foldEs(text);
  for (final w in kForbiddenWeaponWords) {
    final pattern =
        RegExp(r"(^|[^a-z])" + RegExp.escape(w) + r"(s|es)?($|[^a-z])");
    if (pattern.hasMatch(t)) return w;
  }
  return null;
}

class WorldData {
  /// Id estable del mundo ("mansion"). Coincide con `story.world` y con el
  /// `mundo` del catálogo.
  final String id;

  /// Nombre del lugar por idioma ("La Mansión").
  final Map<String, String> names;

  final List<CastMember> cast;
  final List<WorldRoom> rooms;
  final List<WorldWeapon> weapons;

  const WorldData({
    required this.id,
    required this.names,
    required this.cast,
    required this.rooms,
    required this.weapons,
  });

  String get nameEs => names['es'] ?? id;

  /// Muebles permitidos por id de habitación (para las reglas de mapa).
  Map<String, List<ObjectType>> get roomFurniture =>
      {for (final r in rooms) r.id: r.furniture};

  /// Elenco de [count] personajes con iniciales distintas, elegido de forma
  /// determinista por [seed] (con su propio generador: no altera el sorteo
  /// del caso). Se devuelve ordenado alfabéticamente, como el elenco genérico.
  List<CastMember> pickCast(int count, int seed) {
    final rng = Random(seed * 7919 + 104729);
    final byInitial = <String, List<CastMember>>{};
    for (final m in cast) {
      byInitial.putIfAbsent(m.initial, () => []).add(m);
    }
    final initials = byInitial.keys.toList()..sort();
    if (initials.length < count) {
      throw StateError('El mundo $id solo tiene ${initials.length} iniciales '
          'distintas; se piden $count personajes');
    }
    initials.shuffle(rng);
    final picked = [
      for (final i in initials.take(count))
        byInitial[i]![rng.nextInt(byInitial[i]!.length)]
    ]..sort((a, b) => foldEs(a.name).compareTo(foldEs(b.name)));
    return picked;
  }

  /// Problemas de la definición (vacío = sana). Garantiza lo que el
  /// generador necesita: iniciales, habitaciones y armas suficientes, ids
  /// únicos y ningún arma prohibida.
  List<String> problems({int maxCharacters = 9}) {
    final p = <String>[];
    if (names['es'] == null || names['es']!.trim().isEmpty) {
      p.add('el mundo no tiene nombre "es"');
    }
    final initials = {for (final m in cast) m.initial};
    if (initials.length < maxCharacters) {
      p.add('el elenco tiene ${initials.length} iniciales distintas; '
          'hacen falta al menos $maxCharacters');
    }
    final castNames = <String>{};
    for (final m in cast) {
      if (!castNames.add(foldEs(m.name))) p.add('nombre repetido: ${m.name}');
      if (m.name.trim().isEmpty || m.archetype.trim().isEmpty) {
        p.add('personaje sin nombre o sin arquetipo');
      }
      if (m.name.length > 9) p.add('nombre demasiado largo: ${m.name}');
    }
    if (rooms.length < 8) {
      p.add('el mundo tiene ${rooms.length} habitaciones; hacen falta '
          'al menos 8 (los mapas más grandes usan hasta 7)');
    }
    final roomIds = <String>{};
    for (final r in rooms) {
      if (!roomIds.add(r.id)) p.add('habitación repetida: ${r.id}');
      if (r.furniture.isEmpty) p.add('habitación sin muebles: ${r.id}');
      if (r.furniture.toSet().length != r.furniture.length) {
        p.add('habitación con muebles repetidos en su lista: ${r.id}');
      }
      // Coherencia (05-11-2026): si la habitación figura en la tabla
      // canónica, el mundo solo puede usar un subconjunto de ella (jamás una
      // cama en la cocina). Una habitación nueva se valida solo contra sí
      // misma.
      final canon = kRoomFurniture[r.id];
      if (canon != null) {
        for (final f in r.furniture) {
          if (!canon.contains(f)) {
            p.add('${f.nameEs} no corresponde a la habitación ${r.id}');
          }
        }
      }
    }
    if (weapons.length < 3) {
      p.add('el mundo tiene ${weapons.length} armas; hacen falta al menos 3');
    }
    final weaponIds = <String>{};
    for (final w in weapons) {
      if (!weaponIds.add(w.id)) p.add('arma repetida: ${w.id}');
      final bad = forbiddenWeaponWord(w.nameEs) ?? forbiddenWeaponWord(w.id);
      if (bad != null) p.add('arma prohibida (${w.nameEs}): contiene "$bad"');
    }
    return p;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': names,
        'cast': [
          for (final m in cast)
            {'name': m.name, 'female': m.female, 'archetype': m.archetype}
        ],
        'rooms': [
          for (final r in rooms)
            {
              'id': r.id,
              'name_es': r.nameEs,
              'furniture': [for (final f in r.furniture) f.name]
            }
        ],
        'weapons': [
          for (final w in weapons)
            {'id': w.id, 'name_es': w.nameEs, 'category': w.category.name}
        ],
      };

  /// Estricto: lanza [FormatException] si algo falta o no se entiende.
  factory WorldData.fromJson(Map<String, dynamic> j) {
    try {
      return WorldData(
        id: j['id'] as String,
        names: (j['name'] as Map).cast<String, String>(),
        cast: [
          for (final m in (j['cast'] as List))
            CastMember(
              name: m['name'] as String,
              female: m['female'] as bool,
              archetype: m['archetype'] as String,
            )
        ],
        rooms: [
          for (final r in (j['rooms'] as List))
            WorldRoom(
              id: r['id'] as String,
              nameEs: r['name_es'] as String,
              furniture: [
                for (final f in (r['furniture'] as List))
                  ObjectType.values.byName(f as String)
              ],
            )
        ],
        weapons: [
          for (final w in (j['weapons'] as List))
            WorldWeapon(
              id: w['id'] as String,
              nameEs: w['name_es'] as String,
              category: WeaponCategory.values.byName(w['category'] as String),
            )
        ],
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('datos de mundo inválidos: $e');
    }
  }
}
