// Rangos de dificultad configurables (PROVISIONALES): el generador rechaza
// los casos fuera de rango y registra el motivo.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

void main() {
  group('DifficultyRange.violation', () {
    const r = DifficultyRange(minSteps: 4, maxSteps: 10, minTier: 3, maxTier: 4);

    test('dentro del rango no hay motivo (límites incluidos)', () {
      expect(r.violation(4, 3), isNull);
      expect(r.violation(10, 4), isNull);
      expect(r.contains(7, 3), isTrue);
    });

    test('cada extremo da su propio motivo', () {
      expect(r.violation(3, 3), rejectStepsBelow);
      expect(r.violation(11, 3), rejectStepsAbove);
      expect(r.violation(5, 2), rejectTierBelow);
      expect(r.violation(5, 5), rejectTierAbove);
      expect(r.contains(3, 3), isFalse);
    });

    test('DifficultyRange.any nunca descarta', () {
      expect(DifficultyRange.any.violation(0, 1), isNull);
      expect(DifficultyRange.any.violation(100000, 4), isNull);
    });
  });

  group('configuración kDifficultyRanges', () {
    test('hay un rango para cada perfil y es coherente', () {
      for (final label in [
        'tutorial',
        'principiante',
        'casual',
        'intermedio',
        'experto',
        'elite',
      ]) {
        final r = kDifficultyRanges[label];
        expect(r, isNotNull, reason: 'falta el rango de $label');
        expect(r!.minSteps, lessThanOrEqualTo(r.maxSteps), reason: label);
        expect(r.minTier, lessThanOrEqualTo(r.maxTier), reason: label);
        expect(rangeForProfile(label), same(r));
      }
    });

    test('una etiqueta sin rango configurado no descarta nada', () {
      expect(rangeForProfile('inventada'), same(DifficultyRange.any));
    });

    test(
        'los 20 casos congelados de la prueba de juego caen dentro de su '
        'rango provisional (no hay que regenerarlos)', () {
      final dir = Directory('../app/assets/cases');
      var n = 0;
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!name.startsWith('caso-')) continue;
        final pc = PuzzleCase.fromJson(
            jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
        final d = DeductionEngine(pc).run();
        final range = rangeForProfile(pc.difficulty);
        expect(range.violation(d.deductionSteps, d.maxTier), isNull,
            reason: '$name: ${d.deductionSteps} pasos, T${d.maxTier} fuera '
                'de $range');
        n++;
      }
      expect(n, 20);
    });
  });

  group('el generador respeta el rango', () {
    test('rango imposible: descarta todo y registra el motivo', () {
      final g = Generator(
        cabana,
        DifficultyProfile.principiante,
        maxAttempts: 8,
        range: const DifficultyRange(
            minSteps: 500, maxSteps: 600, minTier: 1, maxTier: 4),
      );
      final r = g.generate(7);
      expect(r.puzzle, isNull);
      expect(r.rejections[rejectStepsBelow], greaterThan(0),
          reason: '${r.rejections}');
    });

    test('técnica fuera de rango: se descarta con su propio motivo', () {
      final g = Generator(
        cabana,
        DifficultyProfile.principiante,
        maxAttempts: 8,
        // Ningún caso se resuelve con una técnica máxima menor que T1.
        range: const DifficultyRange(
            minSteps: 0, maxSteps: 1000, minTier: 1, maxTier: 0),
      );
      final r = g.generate(7);
      expect(r.puzzle, isNull);
      expect(r.rejections[rejectTierAbove], greaterThan(0),
          reason: '${r.rejections}');
    });

    test('todo caso generado queda dentro del rango de su perfil', () {
      for (final p in [
        DifficultyProfile.principiante,
        DifficultyProfile.casual,
        DifficultyProfile.intermedio,
      ]) {
        final f = CaseFactory(p);
        final range = rangeForProfile(p.label);
        for (var seed = 1; seed <= 6; seed++) {
          final pc = f.generate(seed).puzzle;
          expect(pc, isNotNull, reason: '${p.label} semilla $seed');
          final m = pc!.metrics!;
          expect(range.violation(m.deductionSteps, m.maxTier), isNull,
              reason: '${p.label} semilla $seed: ${m.deductionSteps} pasos '
                  'T${m.maxTier} fuera de $range');
        }
      }
    });

    test('un rango más estrecho que el del perfil cambia lo que se acepta',
        () {
      // Con el rango del perfil la semilla 5 produce un caso; con un rango
      // que solo admite exactamente 1 paso, ninguno.
      final base = CaseFactory(DifficultyProfile.casual).generate(5);
      expect(base.puzzle, isNotNull);
      final estricto = CaseFactory(
        DifficultyProfile.casual,
        maxMapAttempts: 3,
        range: const DifficultyRange(
            minSteps: 1, maxSteps: 1, minTier: 1, maxTier: 4),
      ).generate(5);
      expect(estricto.puzzle, isNull);
      expect(estricto.rejections.keys,
          anyOf(contains(rejectStepsAbove), contains(rejectStepsBelow)));
    });
  });

  test('el JSON de los casos incluye sus métricas dentro del rango', () {
    // Los casos generados llevan metrics; la puerta de contenido las usa.
    final pc = CaseFactory(DifficultyProfile.principiante).generate(2).puzzle!;
    final m = pc.metrics!;
    expect(rangeForProfile('principiante').contains(m.deductionSteps, m.maxTier),
        isTrue);
  });
}
