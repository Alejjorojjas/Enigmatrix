// H-40: al reforzar la pista de un personaje, el generador debe pasar a la
// candidata INMEDIATAMENTE más fuerte, no a la más fuerte de todas.
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

// Fuerza = tamaño del dominio permitido: menor número = pista más fuerte.
ClueCandidate cand(String area, int strength, [double flavor = 0]) =>
    ClueCandidate(InArea('c1', area), null, strength, flavor);

void main() {
  group('Generator.nextStronger (H-40)', () {
    final c10 = cand('a10', 10);
    final c8 = cand('a8', 8);
    final c6 = cand('a6', 6);
    final c3 = cand('a3', 3);
    final c2 = cand('a2', 2);

    test('devuelve la candidata inmediatamente más fuerte, no la más fuerte '
        'de todas', () {
      // Ordenadas de la más fuerte (2) a la más débil (10), como las deja
      // el generador: la versión errónea devolvía c2 (la primera).
      final sorted = [c2, c3, c6, c8, c10];
      expect(Generator.nextStronger(sorted, c10), same(c8));
      expect(Generator.nextStronger(sorted, c8), same(c6));
      expect(Generator.nextStronger(sorted, c6), same(c3));
      expect(Generator.nextStronger(sorted, c3), same(c2));
    });

    test('no depende del orden de la lista', () {
      final shuffled = [c6, c10, c2, c8, c3];
      expect(Generator.nextStronger(shuffled, c10), same(c8));
      expect(Generator.nextStronger(shuffled, c6), same(c3));
    });

    test('salta las que no son más fuertes y no se queda en las iguales', () {
      final equal = cand('otra10', 10);
      final weaker = cand('a12', 12);
      expect(Generator.nextStronger([weaker, equal, c10, c8], c10), same(c8));
    });

    test('devuelve null si ninguna es más fuerte', () {
      expect(Generator.nextStronger([c10, c8, c6], c6), isNull);
      expect(Generator.nextStronger(const [], c6), isNull);
    });

    test('entre candidatas de igual fuerza prefiere la de más sabor; a igual '
        'sabor, la primera', () {
      final soso = cand('soso', 8, 1);
      final sabrosa = cand('sabrosa', 8, 3);
      final otraSabrosa = cand('otra', 8, 3);
      expect(Generator.nextStronger([soso, sabrosa, c2], c10), same(sabrosa));
      expect(Generator.nextStronger([otraSabrosa, sabrosa], c10),
          same(otraSabrosa));
    });

    test('repetir el refuerzo recorre la escalera paso a paso hasta agotarla',
        () {
      final sorted = [c2, c3, c6, c8, c10];
      final visited = <ClueCandidate>[];
      ClueCandidate? cur = c10;
      while ((cur = Generator.nextStronger(sorted, cur!)) != null) {
        visited.add(cur!);
      }
      expect(visited, [c8, c6, c3, c2]);
    });
  });
}
