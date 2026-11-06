/// Reglas de coherencia del mapa (05-11-2026, decisión de Alejandro tras la
/// prueba de juego n.º 1). Fuente única de las tres reglas:
///
/// 1. Familias: un mapa usa como mucho UN tipo por familia de objetos
///    parecidos ([ObjectType.family]): "silla" nunca convive con "sillón" ni
///    "sofá" en el mismo mapa.
/// 2. Tope por habitación: una habitación no repite un objeto único por
///    naturaleza ([ObjectType.uniquePerRoom]: una cama, una TV...) y tiene
///    como mucho [kMaxSameTypePerRoom] (2) del mismo tipo de los demás.
/// 3. Habitación permitida: cada objeto vive solo en las habitaciones donde
///    tiene sentido ([kRoomFurniture]; un mundo puede restringirla más).
///
/// El generador de mapas las cumple por construcción y la puerta de contenido
/// las verifica sobre los casos ya hechos. Pura (sin dart:io).
library;

import 'model.dart';

/// Muebles permitidos por tipo de habitación: la tabla canónica. Las claves
/// son ids de habitación. Los 14 primeros son el pool genérico del generador
/// (sin mundo); los tres últimos solo existen en el Mundo 1.
const kRoomFurniture = <String, List<ObjectType>>{
  'salon': [
    ObjectType.sofa,
    ObjectType.sillon,
    ObjectType.alfombra,
    ObjectType.tv,
    ObjectType.piano,
    ObjectType.mesa,
    ObjectType.planta,
    ObjectType.chimenea,
  ],
  'cocina': [
    ObjectType.mesa,
    ObjectType.silla,
    ObjectType.barra,
    ObjectType.planta,
    ObjectType.nevera,
  ],
  'dormitorio': [
    ObjectType.cama,
    ObjectType.armario,
    ObjectType.alfombra,
    ObjectType.silla,
    ObjectType.tv,
    ObjectType.planta,
    ObjectType.perchero,
  ],
  'biblioteca': [
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.mesa,
    ObjectType.alfombra,
    ObjectType.planta,
    ObjectType.armario,
    ObjectType.chimenea,
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
    ObjectType.banera,
    ObjectType.planta,
    ObjectType.alfombra,
    ObjectType.lavadora,
  ],
  'pasillo': [
    ObjectType.planta,
    ObjectType.alfombra,
    ObjectType.armario,
    ObjectType.silla,
    ObjectType.perchero,
  ],
  'vestibulo': [
    ObjectType.planta,
    ObjectType.alfombra,
    ObjectType.armario,
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.perchero,
  ],
  'jardin': [
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.silla,
    ObjectType.mesa,
  ],
  'porche': [
    ObjectType.silla,
    ObjectType.sillon,
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.sofa,
    ObjectType.mesa,
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
    ObjectType.mesa,
  ],
  'terraza': [
    ObjectType.silla,
    ObjectType.sofa,
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.mesa,
  ],
  // Habitaciones propias del Mundo 1 (La Mansión).
  'invernadero': [
    ObjectType.planta,
    ObjectType.arbusto,
    ObjectType.silla,
    ObjectType.mesa,
  ],
  'galeria': [
    ObjectType.sofa,
    ObjectType.sillon,
    ObjectType.alfombra,
    ObjectType.planta,
    ObjectType.silla,
  ],
  'sala-de-musica': [
    ObjectType.piano,
    ObjectType.sillon,
    ObjectType.silla,
    ObjectType.alfombra,
    ObjectType.planta,
  ],
};

/// Familia de un tipo, o null si no tiene parecidos.
String? familyOf(ObjectType t) => t.family;

/// Tope de objetos del MISMO tipo en una habitación para los tipos que sí
/// pueden repetirse (silla, sillón, sofá, mesa, planta, arbusto, armario,
/// caja). Decisión de Alejandro del 06-11-2026 (mansion-04 tenía 7 mesas,
/// varias juntas en una misma habitación). Los tipos únicos por habitación
/// ([ObjectType.uniquePerRoom]) siguen en 1.
const int kMaxSameTypePerRoom = 2;

/// Máximo de objetos de [t] que admite una habitación.
int maxPerRoomOf(ObjectType t) => t.uniquePerRoom ? 1 : kMaxSameTypePerRoom;

/// Reglas de coherencia aplicables a un mapa.
class MapRules {
  /// Muebles permitidos por id de habitación. Una habitación que no figura
  /// aquí se considera desconocida: incumple la regla 3 si tiene muebles.
  final Map<String, Set<ObjectType>> roomFurniture;

  const MapRules(this.roomFurniture);

  /// Reglas con la tabla canónica ([kRoomFurniture]).
  static final MapRules generic = MapRules({
    for (final e in kRoomFurniture.entries) e.key: e.value.toSet(),
  });

  /// Reglas con una tabla propia (por ejemplo, las habitaciones de un mundo).
  factory MapRules.fromRooms(Map<String, Iterable<ObjectType>> rooms) =>
      MapRules({for (final r in rooms.entries) r.key: r.value.toSet()});

  /// Problemas legibles del mapa (vacío = coherente).
  List<String> problemsOf(GameMap map) {
    final problems = <String>[];

    // 1. Una sola variante por familia en todo el mapa.
    final typesByFamily = <String, Set<ObjectType>>{};
    for (final o in map.objects) {
      final f = o.type.family;
      if (f != null) typesByFamily.putIfAbsent(f, () => {}).add(o.type);
    }
    for (final e in typesByFamily.entries) {
      if (e.value.length > 1) {
        final names = [for (final t in e.value) t.nameEs]..sort();
        problems.add('familia "${e.key}" repetida en el mapa: '
            '${names.join(', ')} (solo se permite un tipo por familia)');
      }
    }

    // 2. Tope por habitación: los únicos por naturaleza, 1; el resto de
    //    tipos, como mucho [kMaxSameTypePerRoom] del mismo tipo.
    final seen = <String, int>{}; // "área|tipo" -> cuántos
    for (final o in map.objects) {
      final key = '${map.areaIdOf(o.cells.first)}|${o.type.name}';
      seen.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final e in seen.entries) {
      final parts = e.key.split('|');
      final type = ObjectType.values.byName(parts[1]);
      if (e.value > maxPerRoomOf(type)) {
        problems.add('${e.value} × ${type.nameEs} en "${parts[0]}" '
            '(${type.uniquePerRoom ? 'objeto único por habitación' : 'máximo $kMaxSameTypePerRoom del mismo tipo por habitación'})');
      }
    }

    // 3. Cada objeto en una habitación donde tiene sentido; un objeto
    //    multicelda no puede cruzar habitaciones.
    for (final o in map.objects) {
      final areas = {for (final c in o.cells) map.areaIdOf(c)};
      if (areas.length > 1) {
        problems.add('${o.type.nameEs} (${o.id}) cruza varias habitaciones: '
            '${areas.join(', ')}');
      }
      final areaId = map.areaIdOf(o.cells.first);
      final allowed = roomFurniture[areaId];
      if (allowed == null) {
        problems.add('${o.type.nameEs} en la habitación desconocida '
            '"$areaId"');
      } else if (!allowed.contains(o.type)) {
        problems.add('${o.type.nameEs} no corresponde a la habitación '
            '"$areaId"');
      }
    }
    return problems;
  }
}
