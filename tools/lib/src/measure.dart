/// Medición de la generación por lotes (H-39 y calibración de rangos):
/// genera una lista de semillas explícitas con tope y registra tiempo,
/// descartes y métricas de cada una. Pura (sin archivos): el CLI imprime.
library;

import 'case_factory.dart';
import 'difficulty_ranges.dart';
import 'generator.dart';

/// Resultado de generar UNA semilla.
class MeasureRow {
  final int seed;
  final bool ok;
  final Duration elapsed;

  /// Mapas probados (CaseFactory.attempts).
  final int mapsTried;
  final Map<String, int> rejections;

  // Solo si ok.
  final int? steps;
  final int? tier;
  final int? clues;
  final int extras;
  final String? caseId;

  const MeasureRow({
    required this.seed,
    required this.ok,
    required this.elapsed,
    required this.mapsTried,
    required this.rejections,
    this.steps,
    this.tier,
    this.clues,
    this.extras = 0,
    this.caseId,
  });
}

/// Genera cada semilla con [CaseFactory] y mide. [onRow] se llama al
/// terminar cada una (para imprimir el avance de lotes lentos).
List<MeasureRow> measureBatch({
  required DifficultyProfile profile,
  required List<int> seeds,
  bool withWeapon = false,
  DifficultyRange? range,
  GenerationLimits limits = GenerationLimits.standard,
  void Function(MeasureRow row)? onRow,
}) {
  final rows = <MeasureRow>[];
  for (final seed in seeds) {
    final factory = CaseFactory(profile,
        withWeapon: withWeapon, range: range, limits: limits);
    final sw = Stopwatch()..start();
    final r = factory.generate(seed);
    sw.stop();
    final pc = r.puzzle;
    final row = MeasureRow(
      seed: seed,
      ok: pc != null,
      elapsed: sw.elapsed,
      mapsTried: r.attempts,
      rejections: r.rejections,
      steps: pc?.metrics?.deductionSteps,
      tier: pc?.metrics?.maxTier,
      clues: pc?.metrics?.clueCount,
      extras: r.extrasUsed,
      caseId: pc?.caseId,
    );
    rows.add(row);
    onRow?.call(row);
  }
  return rows;
}

/// Suma de descartes de varias filas.
Map<String, int> totalRejections(Iterable<MeasureRow> rows) {
  final t = <String, int>{};
  for (final r in rows) {
    r.rejections.forEach((k, v) => t.update(k, (x) => x + v, ifAbsent: () => v));
  }
  return t;
}

/// Una línea legible por fila.
String formatRow(MeasureRow r) {
  final secs = (r.elapsed.inMilliseconds / 1000).toStringAsFixed(2);
  final head = 'semilla ${r.seed}: ${r.ok ? 'OK' : 'SIN CASO'} en ${secs}s '
      '(${r.mapsTried} mapas)';
  final detail = r.ok
      ? ' · ${r.steps} pasos · T${r.tier} · ${r.clues} pistas'
          '${r.extras > 0 ? ' (+${r.extras} extras)' : ''}'
      : '';
  final rej = r.rejections.isEmpty
      ? ''
      : ' · descartes: ${r.rejections.entries.map((e) => '${e.value}× ${e.key}').join('; ')}';
  return '$head$detail$rej';
}
