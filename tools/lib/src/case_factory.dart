/// Fábrica de casos completos: genera un MAPA ÚNICO por caso (decisión
/// 2026-06-11) y sobre él el caso (personajes, pistas, arma).
/// Una semilla = un caso reproducible con su propio mapa.
library;

import 'dart:math';

import 'generator.dart';
import 'map_generator.dart';

class CaseFactory {
  final DifficultyProfile profile;
  final bool withWeapon;
  final int maxMapAttempts;

  CaseFactory(this.profile, {this.withWeapon = false, this.maxMapAttempts = 40});

  GenerationResult generate(int seed) {
    final rng = Random(seed);
    final rejections = <String, int>{};

    for (var m = 1; m <= maxMapAttempts; m++) {
      final map = MapGenerator(
        size: profile.size,
        rng: rng,
        id: 'mapa-${profile.label}-s$seed${m > 1 ? '-v$m' : ''}',
      ).build();
      if (map == null) {
        rejections.update('mapa inviable', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      if (withWeapon && map.weapons.isEmpty) continue;

      // Pocos intentos de caso por mapa: si este mapa no da un buen caso,
      // se genera otro mapa (cada caso publicado tiene mapa propio igual).
      final result = Generator(
        map,
        profile,
        withWeapon: withWeapon,
        maxAttempts: 8,
        caseIdOverride: 'caso-${profile.label}-s$seed',
      ).generateWith(rng, seed);

      result.rejections.forEach(
          (r, n) => rejections.update(r, (v) => v + n, ifAbsent: () => n));
      if (result.puzzle != null) {
        return GenerationResult(
          puzzle: result.puzzle,
          attempts: m,
          rejections: rejections,
          extrasUsed: result.extrasUsed,
        );
      }
    }
    return GenerationResult(
        puzzle: null,
        attempts: maxMapAttempts,
        rejections: rejections,
        extrasUsed: 0);
  }
}
