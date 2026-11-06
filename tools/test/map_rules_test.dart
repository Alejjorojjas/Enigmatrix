// 05-11-2026, decisión de Alejandro tras la prueba de juego n.º 1:
// coherencia del mapa (familias de objetos parecidos, objetos únicos por
// habitación, cada objeto en su habitación) y objetos nuevos (perchero,
// bañera, nevera, chimenea). Cubre el modelo, la tabla de habitaciones, el
// generador, las pistas en español y la puerta de contenido.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

/// Mapa 6×6 de tres habitaciones (dormitorio, salón y cocina, dos filas cada
/// una) con los objetos dados. Las celdas se eligen a mano en cada prueba.
GameMap mapWith(List<MapObject> objects) => GameMap(
      id: 'm-reglas',
      nameEs: 'Casa de prueba',
      size: 6,
      areas: [
        Area(id: 'dormitorio', nameEs: 'el Dormitorio', cells: [
          for (var i = 0; i < 12; i++) i,
        ]),
        Area(id: 'salon', nameEs: 'el Salón', cells: [
          for (var i = 12; i < 24; i++) i,
        ]),
        Area(id: 'cocina', nameEs: 'la Cocina', cells: [
          for (var i = 24; i < 36; i++) i,
        ]),
      ],
      objects: objects,
    );

MapObject obj(ObjectType t, List<int> cells, [String? id]) =>
    MapObject(id: id ?? '${t.name}-${cells.first}', type: t, cells: cells);

const _names = ClueNames(
    nameOf: _nameOf, isFemale: _isFemale); // para las pistas de las pruebas
String _nameOf(String id) => id == 'c1' ? 'Adela' : 'Bruno';
bool _isFemale(String id) => id == 'c1';

/// Tabla pactada habitación -> muebles permitidos (se repite aquí a propósito:
/// cambiar la tabla del motor obliga a tocar esta prueba y la spec).
const tablaPactada = <String, Set<String>>{
  'salon': {
    'sofa',
    'sillon',
    'alfombra',
    'tv',
    'piano',
    'mesa',
    'planta',
    'chimenea'
  },
  'cocina': {'mesa', 'silla', 'barra', 'planta', 'nevera'},
  'dormitorio': {
    'cama',
    'armario',
    'alfombra',
    'silla',
    'tv',
    'planta',
    'perchero'
  },
  'biblioteca': {
    'silla',
    'sillon',
    'mesa',
    'alfombra',
    'planta',
    'armario',
    'chimenea'
  },
  'comedor': {'mesa', 'silla', 'alfombra', 'planta'},
  'estudio': {'silla', 'sillon', 'mesa', 'armario', 'planta', 'alfombra'},
  'bano': {'banera', 'planta', 'alfombra', 'lavadora'},
  'pasillo': {'planta', 'alfombra', 'armario', 'silla', 'perchero'},
  'vestibulo': {'planta', 'alfombra', 'armario', 'silla', 'sillon', 'perchero'},
  'jardin': {'planta', 'arbusto', 'silla', 'mesa'},
  'porche': {'silla', 'sillon', 'planta', 'arbusto', 'sofa', 'mesa'},
  'atico': {'caja', 'armario', 'alfombra', 'silla'},
  'bodega': {'caja', 'armario', 'lavadora', 'mesa'},
  'terraza': {'silla', 'sofa', 'planta', 'arbusto', 'mesa'},
  'invernadero': {'planta', 'arbusto', 'silla', 'mesa'},
  'galeria': {'sofa', 'sillon', 'alfombra', 'planta', 'silla'},
  'sala-de-musica': {'piano', 'sillon', 'silla', 'alfombra', 'planta'},
};

void main() {
  group('familias y objetos únicos en el modelo', () {
    Set<ObjectType> familia(String f) => {
          for (final t in ObjectType.values)
            if (t.family == f) t
        };

    test('familias pactadas', () {
      expect(familia(kFamilySeats),
          {ObjectType.silla, ObjectType.sillon, ObjectType.sofa});
      expect(familia(kFamilySurfaces), {ObjectType.mesa, ObjectType.barra});
      expect(familia(kFamilyPlants), {ObjectType.planta, ObjectType.arbusto});
      expect(familia(kFamilyStorage), {ObjectType.armario, ObjectType.caja});
      expect(
          familia(kFamilyAppliances), {ObjectType.nevera, ObjectType.lavadora});
    });

    test('toda familia tiene al menos dos miembros; el resto no tiene familia',
        () {
      final byFamily = <String, int>{};
      for (final t in ObjectType.values) {
        if (t.family != null)
          byFamily.update(t.family!, (v) => v + 1, ifAbsent: () => 1);
      }
      expect(byFamily.values.every((n) => n >= 2), isTrue);
      for (final t in [
        ObjectType.cama,
        ObjectType.alfombra,
        ObjectType.tv,
        ObjectType.piano,
        ObjectType.perchero,
        ObjectType.banera,
        ObjectType.chimenea,
      ]) {
        expect(t.family, isNull, reason: t.name);
      }
    });

    test('objetos únicos por habitación (lista pactada)', () {
      expect({
        for (final t in ObjectType.values)
          if (t.uniquePerRoom) t
      }, {
        ObjectType.cama,
        ObjectType.alfombra,
        ObjectType.tv,
        ObjectType.lavadora,
        ObjectType.piano,
        ObjectType.barra,
        ObjectType.perchero,
        ObjectType.banera,
        ObjectType.nevera,
        ObjectType.chimenea,
      });
    });

    test('los objetos nuevos bloquean, con su género y su nombre', () {
      const esperado = {
        ObjectType.perchero: ('perchero', false),
        ObjectType.banera: ('bañera', true),
        ObjectType.nevera: ('nevera', true),
        ObjectType.chimenea: ('chimenea', true),
      };
      esperado.forEach((t, e) {
        expect(t.nameEs, e.$1);
        expect(t.female, e.$2);
        expect(t.standable, isFalse, reason: t.name);
        expect(t.seated, isFalse, reason: t.name);
        expect(t.group, t.name);
        expect(t.indefEs, '${e.$2 ? 'una' : 'un'} ${e.$1}');
        expect(t.defEs, '${e.$2 ? 'la' : 'el'} ${e.$1}');
      });
      expect(ObjectType.banera.name, 'banera');
    });

    test('un mapa con un objeto nuevo viaja por JSON y las celdas se bloquean',
        () {
      final map = mapWith([
        obj(ObjectType.banera, [5])
      ]);
      expect(map.isOccupiable(5), isFalse);
      final back = GameMap.fromJson(
          jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>);
      expect(back.objects.single.type, ObjectType.banera);
    });
  });

  group('tabla de habitaciones (kRoomFurniture)', () {
    test('coincide con la tabla pactada, habitación por habitación', () {
      expect(kRoomFurniture.keys.toSet(), tablaPactada.keys.toSet());
      kRoomFurniture.forEach((room, list) {
        expect({for (final t in list) t.name}, tablaPactada[room],
            reason: room);
        expect(list.toSet().length, list.length,
            reason: '$room tiene muebles repetidos en la lista');
      });
    });

    test('la cama solo vive en el dormitorio; el resto de únicos, donde toca',
        () {
      Set<String> rooms(ObjectType t) => {
            for (final e in kRoomFurniture.entries)
              if (e.value.contains(t)) e.key
          };
      expect(rooms(ObjectType.cama), {'dormitorio'});
      expect(rooms(ObjectType.banera), {'bano'});
      expect(rooms(ObjectType.nevera), {'cocina'});
      expect(rooms(ObjectType.chimenea), {'salon', 'biblioteca'});
      expect(
          rooms(ObjectType.perchero), {'dormitorio', 'pasillo', 'vestibulo'});
      expect(rooms(ObjectType.piano), {'salon', 'sala-de-musica'});
      expect(rooms(ObjectType.barra), {'cocina'});
      expect(rooms(ObjectType.tv), {'salon', 'dormitorio'});
    });

    test('todas las habitaciones del pool genérico tienen entrada', () {
      for (var seed = 1; seed <= 20; seed++) {
        final map = MapGenerator(size: 9, rng: Random(seed), id: 'm').build()!;
        for (final a in map.areas) {
          expect(kRoomFurniture, contains(a.id));
        }
      }
    });

    test(
        'ninguna habitación tiene dos asientos de familias distintas por '
        'definición de lista que obligue a repetir (cada una tiene opciones)',
        () {
      // Con la regla de una variante por familia, cada habitación debe
      // conservar al menos 3 tipos utilizables de familias distintas.
      kRoomFurniture.forEach((room, list) {
        final keys = {for (final t in list) t.family ?? t.name};
        expect(keys.length, greaterThanOrEqualTo(3), reason: room);
      });
    });
  });

  group('MapRules.problemsOf', () {
    final rules = MapRules.generic;

    test('mapa coherente: sin problemas', () {
      final map = mapWith([
        obj(ObjectType.cama, [0, 1]),
        obj(ObjectType.perchero, [6]),
        obj(ObjectType.sofa, [12, 13]),
        obj(ObjectType.chimenea, [18]),
        obj(ObjectType.mesa, [24, 25]),
        obj(ObjectType.nevera, [30]),
      ]);
      expect(rules.problemsOf(map), isEmpty);
    });

    test('familia repetida (silla + sillón en el mismo mapa): problema', () {
      final map = mapWith([
        obj(ObjectType.silla, [0]),
        obj(ObjectType.sillon, [12]),
      ]);
      final p = rules.problemsOf(map);
      expect(p.join(' '), contains('familia "asientos"'));
      expect(p.join(' '), contains('silla'));
      expect(p.join(' '), contains('sillón'));
    });

    test(
        'silla + sofá, mesa + barra, armario + caja, planta + arbusto, '
        'nevera + lavadora: cada pareja es una familia repetida', () {
      final parejas = [
        (ObjectType.silla, ObjectType.sofa, 'asientos', 'dormitorio', 'salon'),
        (ObjectType.mesa, ObjectType.barra, 'superficies', 'salon', 'cocina'),
        (
          ObjectType.armario,
          ObjectType.caja,
          'almacenaje',
          'dormitorio',
          'dormitorio'
        ),
        (ObjectType.planta, ObjectType.arbusto, 'plantas', 'salon', 'cocina'),
        (
          ObjectType.nevera,
          ObjectType.lavadora,
          'electrodomesticos',
          'cocina',
          'cocina'
        ),
      ];
      // Celdas libres de cada habitación: dormitorio 0.., salón 12.., cocina 24..
      const base = {'dormitorio': 0, 'salon': 12, 'cocina': 24};
      for (final (a, b, familia, ra, rb) in parejas) {
        final cellA = base[ra]!;
        final cellB = base[rb]! + (ra == rb ? 3 : 0);
        final map = mapWith([
          obj(a, [cellA]),
          obj(b, [cellB])
        ]);
        final p = MapRules({
          for (final r in ['dormitorio', 'salon', 'cocina'])
            r: ObjectType.values.toSet()
        }).problemsOf(map);
        expect(p.join(' '), contains('familia "$familia"'), reason: '$a $b');
      }
    });

    test('el mismo tipo repetido NO rompe la familia (dos sillas están bien)',
        () {
      final map = mapWith([
        obj(ObjectType.silla, [0]),
        obj(ObjectType.silla, [14]),
        obj(ObjectType.silla, [26]),
      ]);
      expect(
          rules.problemsOf(map).where((p) => p.contains('familia')), isEmpty);
    });

    test('objeto único repetido en la misma habitación: problema', () {
      final map = mapWith([
        obj(ObjectType.cama, [0, 1]),
        obj(ObjectType.cama, [6, 7]),
      ]);
      final p = rules.problemsOf(map);
      expect(p.join(' '), contains('2 × cama'));
      expect(p.join(' '), contains('dormitorio'));
    });

    test(
        'dos alfombras en la misma habitación: problema; en habitaciones '
        'distintas: bien', () {
      expect(
          rules
              .problemsOf(mapWith([
                obj(ObjectType.alfombra, [12, 13]),
                obj(ObjectType.alfombra, [18, 19]),
              ]))
              .join(' '),
          contains('2 × alfombra'));
      expect(
          rules.problemsOf(mapWith([
            obj(ObjectType.alfombra, [0, 1]),
            obj(ObjectType.alfombra, [12, 13]),
          ])),
          isEmpty);
    });

    test('el mismo objeto único en dos habitaciones distintas está bien', () {
      final map = mapWith([
        obj(ObjectType.tv, [12]),
        obj(ObjectType.tv, [0]),
      ]);
      expect(rules.problemsOf(map), isEmpty);
    });

    test('un objeto no único se puede repetir en la habitación (sillas)', () {
      final map = mapWith([
        obj(ObjectType.silla, [24]),
        obj(ObjectType.silla, [25]),
        obj(ObjectType.mesa, [30, 31]),
      ]);
      expect(rules.problemsOf(map), isEmpty);
    });

    test('cama en la cocina: fuera de su habitación', () {
      final map = mapWith([
        obj(ObjectType.cama, [24, 25])
      ]);
      final p = rules.problemsOf(map);
      expect(
          p.join(' '),
          contains('cama no corresponde a la habitación '
              '"cocina"'));
    });

    test(
        'nevera en el dormitorio y bañera en el salón: fuera de su '
        'habitación', () {
      final map = mapWith([
        obj(ObjectType.nevera, [0]),
        obj(ObjectType.banera, [12]),
      ]);
      final p = rules.problemsOf(map).join(' ');
      expect(p, contains('nevera no corresponde a la habitación "dormitorio"'));
      expect(p, contains('bañera no corresponde a la habitación "salon"'));
    });

    test('habitación desconocida con muebles: problema', () {
      final map = GameMap(
        id: 'x',
        nameEs: 'x',
        size: 2,
        areas: const [
          Area(id: 'sotano', nameEs: 'el Sótano', cells: [0, 1, 2, 3])
        ],
        objects: [
          obj(ObjectType.silla, [0])
        ],
      );
      expect(rules.problemsOf(map).join(' '), contains('desconocida'));
    });

    test('un mueble que cruza dos habitaciones: problema', () {
      final map = mapWith([
        obj(ObjectType.mesa, [10, 16])
      ]);
      // 10 es dormitorio (fila 1) y 16 salón (fila 2, col 4): no son
      // vecinas pero la regla solo mira el área de cada celda.
      expect(rules.problemsOf(map).join(' '), contains('cruza varias'));
    });

    test('reglas de un mundo: la lista del mundo manda sobre la canónica', () {
      final soloSilla = MapRules.fromRooms({
        'dormitorio': [ObjectType.silla],
        'salon': [ObjectType.silla],
        'cocina': [ObjectType.silla],
      });
      expect(
          soloSilla.problemsOf(mapWith([
            obj(ObjectType.cama, [0, 1])
          ])),
          isNotEmpty);
      expect(
          soloSilla.problemsOf(mapWith([
            obj(ObjectType.silla, [0])
          ])),
          isEmpty);
    });
  });

  group('los datos del Mundo 1 cumplen la tabla', () {
    final world = loadWorldFile(File('data/mundos/mansion.json'));

    test('cada habitación del mundo usa solo muebles permitidos', () {
      expect(world.problems(), isEmpty);
      for (final r in world.rooms) {
        final canon = kRoomFurniture[r.id];
        expect(canon, isNotNull, reason: r.id);
        expect(canon!.toSet().containsAll(r.furniture), isTrue,
            reason: '${r.id}: ${r.furniture.map((f) => f.name)}');
      }
    });

    test('tabla pactada del Mundo 1 (habitación -> muebles)', () {
      const pactada = {
        'biblioteca': {
          'silla',
          'sillon',
          'mesa',
          'alfombra',
          'planta',
          'armario',
          'chimenea'
        },
        'salon': {
          'sofa',
          'sillon',
          'alfombra',
          'mesa',
          'planta',
          'piano',
          'chimenea'
        },
        'comedor': {'mesa', 'silla', 'alfombra', 'planta'},
        'cocina': {'mesa', 'silla', 'barra', 'planta', 'nevera'},
        'estudio': {'silla', 'sillon', 'mesa', 'armario', 'planta', 'alfombra'},
        'invernadero': {'planta', 'arbusto', 'silla', 'mesa'},
        'galeria': {'sofa', 'sillon', 'alfombra', 'planta', 'silla'},
        'dormitorio': {
          'cama',
          'armario',
          'alfombra',
          'silla',
          'planta',
          'perchero'
        },
        'bodega': {'caja', 'armario', 'mesa'},
        'vestibulo': {
          'planta',
          'alfombra',
          'armario',
          'silla',
          'sillon',
          'perchero'
        },
        'sala-de-musica': {'piano', 'sillon', 'silla', 'alfombra', 'planta'},
        'bano': {'banera', 'planta', 'alfombra'},
      };
      expect({for (final r in world.rooms) r.id}, pactada.keys.toSet());
      for (final r in world.rooms) {
        expect({for (final f in r.furniture) f.name}, pactada[r.id],
            reason: r.id);
      }
    });

    test('un mundo con una cama en la cocina no es válido', () {
      final cocinaConCama = WorldData(
        id: world.id,
        names: world.names,
        cast: world.cast,
        rooms: [
          for (final r in world.rooms)
            r.id == 'cocina'
                ? WorldRoom(
                    id: r.id,
                    nameEs: r.nameEs,
                    furniture: [...r.furniture, ObjectType.cama])
                : r
        ],
        weapons: world.weapons,
      );
      expect(cocinaConCama.problems().join(' '),
          contains('cama no corresponde a la habitación cocina'));
    });

    test(
        'un mundo con un mueble repetido en la lista de una habitación '
        'no es válido', () {
      final repetido = WorldData(
        id: world.id,
        names: world.names,
        cast: world.cast,
        rooms: [
          for (final r in world.rooms)
            r.id == 'comedor'
                ? WorldRoom(
                    id: r.id,
                    nameEs: r.nameEs,
                    furniture: [...r.furniture, ObjectType.mesa])
                : r
        ],
        weapons: world.weapons,
      );
      expect(repetido.problems().join(' '), contains('repetidos'));
    });
  });

  group('el generador cumple las tres reglas por construcción', () {
    GameMap gen(int size, int seed, {WorldData? world}) => MapGenerator(
          size: size,
          rng: Random(seed),
          id: 'm-$size-$seed',
          world: world,
        ).build()!;

    final world = loadWorldFile(File('data/mundos/mansion.json'));

    for (final size in [6, 8, 9, 12, 16]) {
      test(
          '${size}x$size, sin mundo y con La Mansión: 0 problemas en 40 '
          'semillas', () {
        final mansionRules = MapRules.fromRooms(world.roomFurniture);
        for (var seed = 1; seed <= 40; seed++) {
          expect(MapRules.generic.problemsOf(gen(size, seed)), isEmpty,
              reason: 'genérico, semilla $seed');
          expect(
              mansionRules.problemsOf(gen(size, seed, world: world)), isEmpty,
              reason: 'Mansión, semilla $seed');
        }
      });
    }

    test(
        'nunca hay dos tipos de la misma familia, ni dos camas en una '
        'habitación, ni una cama fuera del dormitorio (200 mapas)', () {
      for (var seed = 1; seed <= 200; seed++) {
        final map = gen([6, 8, 9][seed % 3], seed);
        final famTypes = <String, Set<ObjectType>>{};
        final camasPorArea = <String, int>{};
        for (final o in map.objects) {
          if (o.type.family != null) {
            famTypes.putIfAbsent(o.type.family!, () => {}).add(o.type);
          }
          if (o.type == ObjectType.cama) {
            final area = map.areaIdOf(o.cells.first);
            expect(area, 'dormitorio', reason: 'semilla $seed');
            camasPorArea.update(area, (v) => v + 1, ifAbsent: () => 1);
          }
        }
        for (final e in famTypes.entries) {
          expect(e.value.length, 1,
              reason: 'semilla $seed familia ${e.key}: $e');
        }
        expect(camasPorArea.values.every((n) => n == 1), isTrue);
      }
    });

    test('los objetos nuevos aparecen de verdad (genérico, 400 mapas)', () {
      final vistos = <ObjectType>{};
      for (var seed = 1; seed <= 400; seed++) {
        for (final o in gen([6, 8, 9, 12][seed % 4], seed).objects) {
          vistos.add(o.type);
        }
      }
      for (final t in [
        ObjectType.perchero,
        ObjectType.banera,
        ObjectType.nevera,
        ObjectType.chimenea,
      ]) {
        expect(vistos, contains(t), reason: t.name);
      }
    });

    test(
        'perchero, nevera, chimenea y bañera aparecen en La Mansión (300 mapas)',
        () {
      final vistos = <ObjectType>{};
      for (var seed = 1; seed <= 300; seed++) {
        for (final o in gen([6, 8, 9][seed % 3], seed, world: world).objects) {
          vistos.add(o.type);
        }
      }
      expect(
          vistos,
          containsAll([
            ObjectType.perchero,
            ObjectType.nevera,
            ObjectType.chimenea,
          ]));
      // La Mansión tiene baño (05-11-2026): la bañera aparece.
      expect(vistos, contains(ObjectType.banera));
    });

    test('los objetos nuevos ocupan 1 casilla y bloquean', () {
      for (var seed = 1; seed <= 200; seed++) {
        for (final o in gen(9, seed).objects) {
          if ({
            ObjectType.perchero,
            ObjectType.banera,
            ObjectType.nevera,
            ObjectType.chimenea,
          }.contains(o.type)) {
            expect(o.cells.length, 1);
            expect(o.blocks, isTrue);
          }
        }
      }
    });

    test('misma semilla, mismo mapa (determinismo con las reglas nuevas)', () {
      expect(jsonEncode(gen(9, 7).toJson()), jsonEncode(gen(9, 7).toJson()));
    });
  });

  group('pistas en español con los objetos nuevos', () {
    const f = ClueFormatterEs.instance;

    GameMap uno(ObjectType t, {int extra = 0}) => mapWith([
          obj(t, [24]),
          if (extra > 0) obj(t, [30]),
        ]);

    test('"junto a" con artículo y género correctos (uno solo)', () {
      for (final (t, esperado) in [
        (ObjectType.perchero, 'estaba junto al perchero'),
        (ObjectType.banera, 'estaba junto a la bañera'),
        (ObjectType.nevera, 'estaba junto a la nevera'),
        (ObjectType.chimenea, 'estaba junto a la chimenea'),
      ]) {
        final map = uno(t);
        expect(f.predicate(BesideObjectGroup('c1', t.group), map, _names),
            esperado,
            reason: t.name);
      }
    });

    test('"junto a" con artículo indefinido cuando hay varios', () {
      // Perchero y chimenea no son únicos por mapa, solo por habitación.
      final map = mapWith([
        obj(ObjectType.perchero, [0]),
        obj(ObjectType.perchero, [14]),
        obj(ObjectType.chimenea, [15]),
        obj(ObjectType.chimenea, [27]),
      ]);
      expect(f.predicate(BesideObjectGroup('c1', 'perchero'), map, _names),
          'estaba junto a un perchero');
      expect(f.predicate(BesideObjectGroup('c1', 'chimenea'), map, _names),
          'estaba junto a una chimenea');
    });

    test('compuesta con área: "estaba en la Cocina y junto a la nevera"', () {
      final map = uno(ObjectType.nevera);
      final c = CompoundClue('c1', [
        InArea('c1', 'cocina'),
        BesideObjectGroup('c1', 'nevera'),
      ]);
      expect(f.predicate(c, map, _names),
          'estaba en la Cocina y junto a la nevera');
      expect(f.text(c, map, _names),
          'Adela estaba en la Cocina y junto a la nevera.');
      expect(f.cardText(c, map, _names),
          'Estaba en la Cocina y junto a la nevera.');
    });

    test(
        'la semántica de "junto a" funciona con los objetos nuevos '
        '(misma área, no encima)', () {
      // Nevera en la celda 24 (cocina). La 25 está al lado y en la cocina;
      // la 18 está arriba pero en el salón: no cuenta (otra área).
      final map = uno(ObjectType.nevera);
      expect(map.isBesideGroup(25, 'nevera'), isTrue);
      expect(map.isBesideGroup(30, 'nevera'), isTrue);
      expect(map.isBesideGroup(18, 'nevera'), isFalse);
      expect(map.cellsOnGroup('nevera'), isEmpty);
      expect(map.cellsBesideGroup('nevera'), {25, 30});
    });

    test(
        'el generador solo usa "sobre/sentado" con objetos pisables y '
        '"junto a" cuando puede, en casos reales de las reglas nuevas', () {
      final world = loadWorldFile(File('data/mundos/mansion.json'));
      final profile = DifficultyProfile.byLabel('casual');
      var casos = 0, conNuevos = 0;
      final nuevos = {'perchero', 'banera', 'nevera', 'chimenea'};
      for (var seed = 1; seed <= 12; seed++) {
        final r = CaseFactory(profile, world: world).generate(seed);
        final pc = r.puzzle;
        if (pc == null) continue;
        casos++;
        for (final c in pc.clues) {
          final j = c.toJson();
          final partes = j['type'] == 'compound'
              ? [for (final p in (j['parts'] as List)) p as Map]
              : [j];
          for (final p in partes) {
            final tipo = p['type'];
            final g = p['group'] as String?;
            if (tipo == 'on_object' || tipo == 'only_one_on') {
              expect(nuevos, isNot(contains(g)),
                  reason: 'sobre/sentado con un objeto que bloquea: $g');
            }
            if (g != null && nuevos.contains(g)) {
              conNuevos++;
              expect(tipo, 'beside_object');
              // Y el texto sale bien en español.
              final t = c.textEs(pc.map, pc.names);
              expect(
                  t,
                  anyOf(contains('junto al $g'), contains('junto a la'),
                      contains('junto a una'), contains('junto a un ')));
              expect(t, isNot(contains('null')));
            }
          }
        }
      }
      expect(casos, greaterThan(5));
      expect(conNuevos, greaterThan(0),
          reason: 'ningún caso usó un objeto nuevo en sus pistas');
    });
  });

  group('puerta de contenido: reglas de mapa', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('enx_rules_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void writeCatalog(String id, String mundo, [String dif = 'test']) =>
        File('${tmp.path}/catalogo.json').writeAsStringSync(jsonEncode({
          'version': 1,
          'casos': [
            {
              'id': id,
              'mundo': mundo,
              'tipo': 'campana',
              'dificultad': dif,
              'orden': 1,
              'archivo': '$id.json',
            }
          ]
        }));

    PuzzleCase conHistoria(PuzzleCase pc, String world) =>
        pc.withStory(CaseStory(
            world: world,
            title: const {'es': 'Prueba'},
            premise: const {'es': 'Una premisa corta.'}));

    // La cabaña trae una silla en el salón y una TV en el estudio: ninguna
    // de las dos está permitida en esas habitaciones.
    test(
        'la cabaña (silla en el salón, TV en el estudio) falla fuera del '
        'banco de pruebas', () {
      File('${tmp.path}/a.json').writeAsStringSync(jsonEncode(
          conHistoria(cabanaCase(cabanaPin, caseId: 'a'), 'mansion').toJson()));
      writeCatalog('a', 'mansion');
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      final texto = r.allProblems.join('\n');
      expect(texto, contains('mapa: silla no corresponde'));
      expect(texto, contains('mapa: TV no corresponde'));
    });

    test(
        'el mismo caso en el banco de pruebas pasa (mundo exento por '
        'defecto)', () {
      File('${tmp.path}/a.json').writeAsStringSync(
          jsonEncode(cabanaCase(cabanaPin, caseId: 'a').toJson()));
      writeCatalog('a', kBancoDePruebas);
      final r = runContentGate(casesDir: tmp);
      expect(r.allProblems, isEmpty);
    });

    test(
        'se puede eximir otro mundo con mapRulesExemptMundos y volver a '
        'exigirlo al banco con un conjunto vacío', () {
      File('${tmp.path}/a.json').writeAsStringSync(
          jsonEncode(cabanaCase(cabanaPin, caseId: 'a').toJson()));
      writeCatalog('a', kBancoDePruebas);
      final estricta =
          runContentGate(casesDir: tmp, mapRulesExemptMundos: const {});
      expect(estricta.passed, isFalse);
      expect(estricta.allProblems.join('\n'), contains('mapa:'));
    });

    test(
        'el tutorial está exento por defecto y se exige con '
        'mapRulesOnTutorial', () {
      File('${tmp.path}/catalogo.json')
          .writeAsStringSync(jsonEncode({'version': 1, 'casos': []}));
      final tut = Directory('${tmp.path}/tut')..createSync();
      File('${tut.path}/t.json').writeAsStringSync(
          jsonEncode(cabanaCase(cabanaPin, caseId: 't').toJson()));
      expect(
          runContentGate(casesDir: tmp, tutorialDir: tut).allProblems, isEmpty);
      final estricta = runContentGate(
          casesDir: tmp, tutorialDir: tut, mapRulesOnTutorial: true);
      expect(estricta.allProblems.join('\n'), contains('tutorial/t.json'));
      expect(estricta.allProblems.join('\n'), contains('mapa:'));
    });

    test(
        'un caso real generado con las reglas nuevas pasa la puerta de '
        'contenido completa (mundo con su tabla)', () {
      final world = loadWorldFile(File('data/mundos/mansion.json'));
      PuzzleCase? pc;
      for (var seed = 1; seed <= 30 && pc == null; seed++) {
        pc = buildPlanCase(
                PlanCase(
                    id: 'g',
                    difficulty: 'principiante',
                    seed: seed,
                    weapon: false,
                    title: const {'es': 'Prueba'},
                    premise: const {'es': 'Una premisa corta.'}),
                world)
            .puzzle;
      }
      expect(pc, isNotNull);
      File('${tmp.path}/g.json').writeAsStringSync(jsonEncode(pc!.toJson()));
      writeCatalog('g', 'mansion', 'principiante');
      final r = runContentGate(casesDir: tmp);
      expect(r.allProblems, isEmpty);
    });

    test('un caso real al que se le cuela una segunda cama falla', () {
      final world = loadWorldFile(File('data/mundos/mansion.json'));
      PuzzleCase? pc;
      for (var seed = 1; seed <= 60 && pc == null; seed++) {
        final c = buildPlanCase(
                PlanCase(
                    id: 'g',
                    difficulty: 'principiante',
                    seed: seed,
                    weapon: false,
                    title: const {'es': 'Prueba'},
                    premise: const {'es': 'Una premisa corta.'}),
                world)
            .puzzle;
        if (c != null &&
            c.map.areas.any((a) => a.id == 'dormitorio') &&
            c.map.objects.any((o) => o.type == ObjectType.cama)) {
          pc = c;
        }
      }
      expect(pc, isNotNull,
          reason: 'no se halló un mapa con dormitorio y '
              'cama');
      final j = pc!.toJson();
      final map = j['map'] as Map<String, dynamic>;
      final cama = (map['objects'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((o) => o['type'] == 'cama');
      // Se duplica la cama en la misma habitación (celdas ya ocupadas no
      // importan: el GameMap las rechazaría, así que se usa una celda libre
      // del dormitorio).
      final dorm = (map['areas'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((a) => a['id'] == 'dormitorio');
      final ocupadas = {
        for (final o in (map['objects'] as List))
          ...((o as Map)['cells'] as List).cast<int>()
      };
      final libre = (dorm['cells'] as List)
          .cast<int>()
          .firstWhere((c) => !ocupadas.contains(c), orElse: () => -1);
      if (libre == -1) return; // dormitorio lleno: nada que probar
      (map['objects'] as List).add({
        'id': 'cama-extra',
        'type': 'cama',
        'cells': [libre],
      });
      expect(cama['type'], 'cama');
      File('${tmp.path}/g.json').writeAsStringSync(jsonEncode(j));
      writeCatalog('g', 'mansion');
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('2 × cama'));
    });
  });
}
