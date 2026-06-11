import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  // Asignación de referencia sobre la cabaña 4×4:
  //   c1 Adela (f1,c2) Salón, sobre la alfombra
  //   c2 Bruno (f2,c1) Salón, sentado en la silla
  //   c3 Clara (f3,c3) Estudio
  //   c4 Dario (f4,c4) Estudio, sobre la otra alfombra — víctima: c4
  final positions = {'c1': 1, 'c2': 4, 'c3': 10, 'c4': 15};

  const chars = [
    Character(id: 'c1', nameEs: 'Adela', female: true),
    Character(id: 'c2', nameEs: 'Bruno', female: false),
    Character(id: 'c3', nameEs: 'Clara', female: true),
    Character(id: 'c4', nameEs: 'Dario', female: false),
  ];
  final names = ClueNames(
    nameOf: (id) =>
        id == 'c4' ? 'La víctima' : chars.firstWhere((c) => c.id == id).nameEs,
    isFemale: (id) => chars.firstWhere((c) => c.id == id).female,
  );

  ClueContext ctx({Map<String, int>? pos, String? lethal}) => ClueContext(
        map: cabana,
        positions: pos ?? positions,
        victimId: 'c4',
        lethalWeaponId: lethal,
      );

  group('semántica de pistas (vocabulario Murdoku, spec 16 §3.1)', () {
    test('in_area / not_in_area', () {
      expect(const InArea('c1', 'salon').holds(ctx()), isTrue);
      expect(const InArea('c1', 'cocina').holds(ctx()), isFalse);
      expect(const NotInArea('c1', 'cocina').holds(ctx()), isTrue);
      expect(const NotInArea('c1', 'salon').holds(ctx()), isFalse);
    });

    test('sobre un mueble (on_object)', () {
      expect(const OnObjectGroup('c1', 'alfombra').holds(ctx()), isTrue);
      expect(const OnObjectGroup('c2', 'silla').holds(ctx()), isTrue);
      expect(const OnObjectGroup('c3', 'alfombra').holds(ctx()), isFalse);
      expect(const OnObjectGroup('c1', 'silla').holds(ctx()), isFalse);
    });

    test('junto a un mueble (beside_object)', () {
      // c3 en 10, vecina de la TV (11).
      expect(const BesideObjectGroup('c3', 'tv').holds(ctx()), isTrue);
      // c4 está SOBRE la alfombra del estudio: no cuenta como "junto a".
      expect(const BesideObjectGroup('c4', 'alfombra').holds(ctx()), isFalse);
      // c2 en 4: la mesa está en la cocina, no junto a él.
      expect(const BesideObjectGroup('c2', 'mesa').holds(ctx()), isFalse);
      // Alguien en 2 (cocina) sí está junto a la mesa (6).
      expect(
          const BesideObjectGroup('c1', 'mesa')
              .holds(ctx(pos: {'c1': 2, 'c2': 4, 'c3': 10, 'c4': 15})),
          isTrue);
    });

    test('única persona sobre un grupo (only_one_on)', () {
      // c1 y c4 están ambas sobre alfombras -> ninguna es "la única".
      expect(const OnlyOneOnGroup('c1', 'alfombra').holds(ctx()), isFalse);
      // c2 es el único sentado en silla.
      expect(const OnlyOneOnGroup('c2', 'silla').holds(ctx()), isTrue);
    });

    test('compuesta: todas las partes deben cumplirse', () {
      const compound = CompoundClue('c4', [
        InArea('c4', 'estudio'),
        OnObjectGroup('c4', 'alfombra'),
      ]);
      expect(compound.holds(ctx()), isTrue);
      const broken = CompoundClue('c4', [
        InArea('c4', 'cocina'),
        OnObjectGroup('c4', 'alfombra'),
      ]);
      expect(broken.holds(ctx()), isFalse);
    });

    test('relleno de la víctima: siempre verdadero', () {
      expect(const LastFreeCell('c4').holds(ctx()), isTrue);
    });

    test('relaciones entre personas', () {
      expect(const SameArea('c1', 'c2').holds(ctx()), isTrue);
      expect(const SameArea('c1', 'c3').holds(ctx()), isFalse);
      expect(const NotSameArea('c1', 'c3').holds(ctx()), isTrue);
      // 1 y 4 son diagonales: no "junto a".
      expect(const BesideChar('c1', 'c2').holds(ctx()), isFalse);
      expect(
          const BesideChar('c1', 'c2')
              .holds(ctx(pos: {'c1': 0, 'c2': 4, 'c3': 10, 'c4': 15})),
          isTrue);
      expect(const AloneWith('c3', 'c4').holds(ctx()), isTrue);
      expect(const Alone('c1').holds(ctx()), isFalse);
      expect(
          const Alone('c1')
              .holds(ctx(pos: {'c1': 2, 'c2': 4, 'c3': 10, 'c4': 15})),
          isTrue);
    });

    test('área vacía', () {
      expect(const AreaEmpty('cocina').holds(ctx()), isTrue);
      expect(const AreaEmpty('salon').holds(ctx()), isFalse);
    });

    test('pistas de arma', () {
      expect(
          const WeaponInArea('estudio').holds(ctx(lethal: 'tijeras')), isTrue);
      expect(
          const WeaponInArea('cocina').holds(ctx(lethal: 'tijeras')), isFalse);
      expect(
          const WeaponCat(WeaponCategory.cortante)
              .holds(ctx(lethal: 'tijeras')),
          isTrue);
      expect(
          const WeaponCat(WeaponCategory.veneno).holds(ctx(lethal: 'tijeras')),
          isFalse);
      expect(
          const WeaponExact('tijeras').holds(ctx(lethal: 'tijeras')), isTrue);
    });

    test('textos: género, artículos y tarjeta', () {
      // silla única en la cabaña -> "la silla"; Bruno -> "sentado".
      expect(const OnObjectGroup('c2', 'silla').cardTextEs(cabana, names),
          'Estaba sentado en la silla.');
      // dos alfombras -> "una alfombra"; texto de tarjeta sin nombre.
      expect(const OnObjectGroup('c1', 'alfombra').cardTextEs(cabana, names),
          'Estaba sobre una alfombra.');
      expect(const OnObjectGroup('c1', 'alfombra').textEs(cabana, names),
          'Adela estaba sobre una alfombra.');
      // La víctima como sujeto usa "La víctima".
      expect(const InArea('c4', 'estudio').textEs(cabana, names),
          'La víctima estaba en el Estudio.');
      // Género en "sola/solo".
      expect(const Alone('c1').cardTextEs(cabana, names), 'Estaba sola.');
      expect(const Alone('c2').cardTextEs(cabana, names), 'Estaba solo.');
      // Compuesta: el segundo "estaba" se omite.
      expect(
          const CompoundClue('c3', [
            BesideObjectGroup('c3', 'tv'),
            InArea('c3', 'estudio'),
          ]).cardTextEs(cabana, names),
          'Estaba junto a la TV y en el Estudio.');
    });

    test('serialización ida y vuelta', () {
      const clues = <Clue>[
        InArea('c1', 'salon'),
        OnObjectGroup('c2', 'silla'),
        BesideObjectGroup('c3', 'tv'),
        OnlyOneOnGroup('c1', 'alfombra'),
        CompoundClue('c4', [InArea('c4', 'estudio'), OnObjectGroup('c4', 'alfombra')]),
        LastFreeCell('c4'),
        AloneWith('c3', 'c4'),
        WeaponCat(WeaponCategory.asfixia),
      ];
      for (final c in clues) {
        expect(Clue.fromJson(c.toJson()).toJson(), c.toJson());
      }
    });
  });
}
