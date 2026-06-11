import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

PuzzleCase makeCase({
  required List<Clue> clues,
  bool hasWeapon = false,
  Map<String, int>? positions,
}) {
  final pos = positions ?? {'c1': 0, 'c2': 5, 'c3': 10, 'c4': 15};
  return PuzzleCase(
    caseId: 'test',
    map: cabana,
    characters: const [
      Character(id: 'c1', nameEs: 'Adela'),
      Character(id: 'c2', nameEs: 'Bruno'),
      Character(id: 'c3', nameEs: 'Clara'),
      Character(id: 'c4', nameEs: 'Dario'),
    ],
    victimId: 'c4',
    clues: clues,
    hasWeapon: hasWeapon,
    difficulty: 'test',
    solution: Solution(positions: pos, murdererId: 'c3'),
  );
}

void main() {
  group('Validator (la lógica que irá al servidor)', () {
    test('solución correcta: válida, asesino deducido', () {
      final pc = makeCase(clues: const []);
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isTrue, reason: v.errors.join('; '));
      expect(v.murdererId, 'c3');
    });

    test('arma deducible única: válida y la identifica', () {
      // Estudio tiene tijeras Y abrecartas (ambas cortantes):
      // hace falta la pista exacta para distinguir.
      final pc = makeCase(
          clues: const [WeaponExact('tijeras')], hasWeapon: true);
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isTrue, reason: v.errors.join('; '));
      expect(v.lethalWeaponId, 'tijeras');
    });

    test('arma ambigua: inválida (dos candidatas en el área de la víctima)',
        () {
      final pc = makeCase(clues: const [], hasWeapon: true);
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isFalse);
      expect(v.errors.single, contains('Arma homicida no deducible'));
    });

    test('víctima sin acompañante: inválida', () {
      // c4 queda sola en el Estudio.
      final pc = makeCase(
        clues: const [],
        positions: {'c1': 1, 'c2': 7, 'c3': 8, 'c4': 14},
      );
      final v = Validator.validate(pc, pc.solution.positions);
      expect(v.valid, isFalse);
      expect(v.errors.single, contains('exactamente 1'));
    });

    test('dos personas en la misma columna: inválida', () {
      final pc = makeCase(
        clues: const [],
        positions: {'c1': 0, 'c2': 4, 'c3': 10, 'c4': 15},
      );
      expect(Validator.validate(pc, pc.solution.positions).valid, isFalse);
    });

    test('celda bloqueada: inválida', () {
      final pc = makeCase(
        clues: const [],
        positions: {'c1': 0, 'c2': 6, 'c3': 10, 'c4': 15}, // 6 = mesa
      );
      expect(Validator.validate(pc, pc.solution.positions).valid, isFalse);
    });

    test('pista incumplida: inválida', () {
      final pc = makeCase(clues: const [InArea('c1', 'cocina')]);
      expect(Validator.validate(pc, pc.solution.positions).valid, isFalse);
    });
  });
}
