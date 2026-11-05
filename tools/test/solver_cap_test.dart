// H-42: tope de nodos del solver de unicidad y del generador. Si se supera,
// el caso se descarta con el motivo "tope" en vez de colgarse. Se prueba con
// el tope de NODOS (determinista); el de tiempo es solo red de seguridad.
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

void main() {
  group('UniquenessChecker con tope', () {
    test('sin tope decide la unicidad y cuenta nodos', () {
      final r = UniquenessChecker.analyze(cabanaCase(cabanaPin),
          limits: SolverLimits.unlimited);
      expect(r.capped, isFalse);
      expect(r.solutions, 1);
      expect(r.nodes, greaterThan(0));
      expect(r.capKind, isNull);
    });

    test('con un tope de nodos mínimo corta y lo avisa', () {
      final r = UniquenessChecker.analyze(cabanaCase(cabanaPin),
          limits: const SolverLimits(maxNodes: 1));
      expect(r.capped, isTrue);
      expect(r.capKind, 'nodos');
      expect(r.nodes, lessThanOrEqualTo(3));
    });

    test('el tope es determinista: mismo caso, mismos nodos', () {
      const limits = SolverLimits(maxNodes: 25);
      final a = UniquenessChecker.analyze(cabanaCase(cabanaAreaOnly),
          limit: 1000, limits: limits);
      final b = UniquenessChecker.analyze(cabanaCase(cabanaAreaOnly),
          limit: 1000, limits: limits);
      expect(a.nodes, b.nodes);
      expect(a.solutions, b.solutions);
      expect(a.capped, b.capped);
    });

    test('countSolutions lanza SolverLimitExceeded en vez de colgarse', () {
      expect(
        () => UniquenessChecker.countSolutions(cabanaCase(cabanaPin),
            limits: const SolverLimits(maxNodes: 1)),
        throwsA(isA<SolverLimitExceeded>()),
      );
    });

    test('un tope holgado no cambia el resultado', () {
      expect(
        UniquenessChecker.countSolutions(cabanaCase(cabanaPin),
            limits: const SolverLimits(maxNodes: 1000000)),
        1,
      );
    });

    test('el tope por defecto es finito', () {
      expect(SolverLimits.standard.maxNodes, kDefaultSolverMaxNodes);
      expect(SolverLimits.standard.maxTime, isNotNull);
      expect(rejectSolverCap, 'tope');
    });
  });

  group('Generator y CaseFactory con tope', () {
    const tiny = GenerationLimits(solver: SolverLimits(maxNodes: 1));

    test('el generador descarta con el motivo "tope" y no devuelve caso', () {
      final g = Generator(cabana, DifficultyProfile.principiante,
          maxAttempts: 6, limits: tiny);
      final r = g.generate(7);
      expect(r.puzzle, isNull);
      expect(r.rejections[rejectSolverCap], greaterThan(0),
          reason: '${r.rejections}');
    });

    test('la fábrica propaga el tope y registra "tope" en los descartes', () {
      final f = CaseFactory(DifficultyProfile.principiante,
          maxMapAttempts: 2, limits: tiny);
      final r = f.generate(3);
      expect(r.puzzle, isNull);
      expect(r.rejections[rejectSolverCap], greaterThan(0),
          reason: '${r.rejections}');
    });

    test('con el tope estándar el mismo caso sí se genera', () {
      final r = CaseFactory(DifficultyProfile.principiante).generate(3);
      expect(r.puzzle, isNotNull, reason: '${r.rejections}');
      expect(r.rejections.containsKey(rejectSolverCap), isFalse);
    });
  });
}
