import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  // Asignación de referencia sobre la cabaña 4×4:
  //   c1 Adela (f1,c1) Salón · c2 Bruno (f2,c2) Salón
  //   c3 Clara (f3,c3) Estudio · c4 Dario (f4,c4) Estudio — víctima: c4
  final positions = {'c1': 0, 'c2': 5, 'c3': 10, 'c4': 15};

  ClueContext ctx({Map<String, int>? pos, String? lethal}) => ClueContext(
        map: cabana,
        positions: pos ?? positions,
        victimId: 'c4',
        lethalWeaponId: lethal,
      );

  group('semántica de pistas (spec 16 sección 3.1)', () {
    test('in_area / not_in_area', () {
      expect(const InArea('c1', 'salon').holds(ctx()), isTrue);
      expect(const InArea('c1', 'cocina').holds(ctx()), isFalse);
      expect(const NotInArea('c1', 'cocina').holds(ctx()), isTrue);
      expect(const NotInArea('c1', 'salon').holds(ctx()), isFalse);
    });

    test('same_area / not_same_area', () {
      expect(const SameArea('c1', 'c2').holds(ctx()), isTrue);
      expect(const SameArea('c1', 'c3').holds(ctx()), isFalse);
      expect(const NotSameArea('c1', 'c3').holds(ctx()), isTrue);
      expect(const NotSameArea('c1', 'c2').holds(ctx()), isFalse);
    });

    test('junto a personaje: ortogonal + misma área', () {
      // c1 (f1,c1) y c2 (f2,c2): diagonal -> false.
      expect(const BesideChar('c1', 'c2').holds(ctx()), isFalse);
      // Variante: c2 en (f2,c1)=celda 4 -> adyacente vertical, misma área.
      expect(
          const BesideChar('c1', 'c2')
              .holds(ctx(pos: {'c1': 0, 'c2': 4, 'c3': 10, 'c4': 15})),
          isTrue);
    });

    test('junto a objeto: vecino de la mesa dentro de la Cocina', () {
      // mesa = celda 6 (f2,c3). Vecinos en su área: 2 (f1,c3) y 7 (f2,c4).
      expect(
          const BesideObject('c1', 'mesa')
              .holds(ctx(pos: {'c1': 2, 'c2': 5, 'c3': 10, 'c4': 15})),
          isTrue);
      expect(const BesideObject('c3', 'mesa').holds(ctx()), isFalse);
    });

    test('a solas / a solas con', () {
      expect(const Alone('c1').holds(ctx()), isFalse); // comparte con c2
      expect(
          const Alone('c1')
              .holds(ctx(pos: {'c1': 0, 'c2': 7, 'c3': 10, 'c4': 15})),
          isTrue);
      expect(const AloneWith('c3', 'c4').holds(ctx()), isTrue);
      expect(const AloneWith('c1', 'c3').holds(ctx()), isFalse);
    });

    test('área vacía', () {
      expect(const AreaEmpty('cocina').holds(ctx()), isTrue);
      expect(const AreaEmpty('salon').holds(ctx()), isFalse);
    });

    test('cardinales: comparación estricta de coordenada', () {
      expect(const Cardinal('c1', 'c2', Direction.west).holds(ctx()), isTrue);
      expect(const Cardinal('c1', 'c2', Direction.east).holds(ctx()), isFalse);
      expect(const Cardinal('c1', 'c2', Direction.north).holds(ctx()), isTrue);
      expect(const Cardinal('c4', 'c1', Direction.south).holds(ctx()), isTrue);
    });

    test('fila / columna', () {
      expect(const InRow('c2', 1).holds(ctx()), isTrue);
      expect(const InRow('c2', 0).holds(ctx()), isFalse);
      expect(const InCol('c2', 1).holds(ctx()), isTrue);
    });

    test('esquina', () {
      expect(const CornerClue('c3', 'estudio').holds(ctx()), isTrue);
      expect(const CornerClue('c3', 'salon').holds(ctx()), isFalse);
      expect(const CornerClue('c3', null).holds(ctx()), isTrue);
    });

    test('pistas de arma', () {
      expect(const WeaponInArea('estudio').holds(ctx(lethal: 'tijeras')),
          isTrue);
      expect(const WeaponInArea('cocina').holds(ctx(lethal: 'tijeras')),
          isFalse);
      expect(
          const WeaponCat(WeaponCategory.cortante)
              .holds(ctx(lethal: 'tijeras')),
          isTrue);
      expect(
          const WeaponCat(WeaponCategory.veneno).holds(ctx(lethal: 'tijeras')),
          isFalse);
      expect(const WeaponExact('tijeras').holds(ctx(lethal: 'tijeras')),
          isTrue);
      expect(const WeaponExact('abrecartas').holds(ctx(lethal: 'tijeras')),
          isFalse);
    });

    test('serialización ida y vuelta', () {
      const clues = <Clue>[
        InArea('c1', 'salon'),
        Cardinal('c1', 'c2', Direction.west),
        AloneWith('c3', 'c4'),
        WeaponCat(WeaponCategory.asfixia),
        CornerClue('c3', null),
      ];
      for (final c in clues) {
        expect(Clue.fromJson(c.toJson()).toJson(), c.toJson());
      }
    });
  });
}
