/// CLI del motor de puzzles (Fase 0).
///
/// Uso:
///   dart run bin/enigmatrix.dart generate --difficulty tutorial|principiante|casual|intermedio
///       [--count N] [--seed S] [--weapons] [--out DIR] [--solution]
///       [--tope-nodos N] [--tope-segundos S] [--sin-rango]
///   dart run bin/enigmatrix.dart show ARCHIVO.json [--solution]
///   dart run bin/enigmatrix.dart validate ARCHIVO.json
///   dart run bin/enigmatrix.dart measure --difficulty D --seeds 1,2,3 | --count N --seed S
///       [--weapons] [--tope-nodos N] [--tope-segundos S] [--sin-rango]
///   dart run bin/enigmatrix.dart catalog-add ARCHIVO.json... --mundo M
///       [--tipo campana|reto] [--dir ../app/assets/cases]
///   dart run bin/enigmatrix.dart catalog-check [--dir ../app/assets/cases]
///       [--tutorial ../app/assets/tutorial]
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    _usage();
    exit(1);
  }
  switch (args.first) {
    case 'generate':
      _generate(args.skip(1).toList());
    case 'show':
      _show(args.skip(1).toList());
    case 'validate':
      _validate(args.skip(1).toList());
    case 'measure':
      _measure(args.skip(1).toList());
    case 'catalog-add':
      _catalogAdd(args.skip(1).toList());
    case 'catalog-check':
      _catalogCheck(args.skip(1).toList());
    default:
      _usage();
      exit(1);
  }
}

void _usage() {
  stdout.writeln('Comandos: generate | show | validate | measure | '
      'catalog-add | catalog-check '
      '(ver encabezado de bin/enigmatrix.dart)');
}

String? _opt(List<String> args, String name) {
  final i = args.indexOf('--$name');
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

bool _flag(List<String> args, String name) => args.contains('--$name');

/// Topes de la línea de comandos (H-42): nodos del solver y segundos por caso.
GenerationLimits _limits(List<String> args) {
  final nodes = _opt(args, 'tope-nodos');
  final secs = _opt(args, 'tope-segundos');
  return GenerationLimits(
    solver: SolverLimits(
      maxNodes: nodes == null ? kDefaultSolverMaxNodes : int.parse(nodes),
      maxTime: const Duration(seconds: 30),
    ),
    maxCaseTime: secs == null ? null : Duration(seconds: int.parse(secs)),
  );
}

DifficultyRange? _range(List<String> args) =>
    _flag(args, 'sin-rango') ? DifficultyRange.any : null;

void _generate(List<String> args) {
  final difficulty = _opt(args, 'difficulty') ?? 'principiante';
  final count = int.parse(_opt(args, 'count') ?? '1');
  final seed = int.parse(_opt(args, 'seed') ?? '1');
  final weapons = _flag(args, 'weapons');
  final outDir = _opt(args, 'out') ?? 'out';
  final showSolution = _flag(args, 'solution');

  final profile = DifficultyProfile.byLabel(difficulty);
  final generator = CaseFactory(profile,
      withWeapon: weapons, range: _range(args), limits: _limits(args));

  Directory(outDir).createSync(recursive: true);
  final rejectionTotals = <String, int>{};
  var ok = 0, failed = 0;
  String? firstPath;

  for (var k = 0; k < count; k++) {
    final result = generator.generate(seed + k);
    result.rejections.forEach(
        (r, n) => rejectionTotals.update(r, (v) => v + n, ifAbsent: () => n));
    final pc = result.puzzle;
    if (pc == null) {
      failed++;
      stdout.writeln('semilla ${seed + k}: SIN CASO (agotó intentos)');
      continue;
    }
    final file = File('$outDir/${pc.caseId}.json');
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(pc.toJson()));
    firstPath ??= file.path;
    final m = pc.metrics!;
    final extras =
        result.extrasUsed > 0 ? ' +${result.extrasUsed} extras' : '';
    stdout.writeln('${pc.caseId}: ${m.clueCount} pistas$extras, '
        '${m.deductionSteps} pasos, T${m.maxTier}, única OK '
        '(${result.attempts} intentos) -> ${file.path}');
    ok++;
  }

  stdout.writeln('\nResumen: $ok generados, $failed fallidos, '
      'de $count solicitados.');
  if (rejectionTotals.isNotEmpty) {
    stdout.writeln('Descartes internos del generador:');
    rejectionTotals.forEach((r, n) => stdout.writeln('  $n × $r'));
  }

  if (firstPath != null) {
    stdout.writeln('\nEJEMPLO (primer caso generado):\n');
    stdout.writeln(
        renderCaseSheet(_load(firstPath), revealSolution: showSolution));
  }
}

PuzzleCase _load(String path) {
  final j = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return PuzzleCase.fromJson(j); // el mapa viene embebido en el caso
}

void _show(List<String> args) {
  final path = args.firstWhere((a) => !a.startsWith('--'));
  stdout.writeln(
      renderCaseSheet(_load(path), revealSolution: _flag(args, 'solution')));
}

void _validate(List<String> args) {
  final path = args.firstWhere((a) => !a.startsWith('--'));
  final pc = _load(path);

  final v = Validator.validate(pc, pc.solution.positions);
  stdout.writeln('Validador: ${v.valid ? 'OK' : 'FALLA ${v.errors}'}');

  final d = DeductionEngine(pc).run();
  stdout.writeln('Deducción pura: ${d.status.name}'
      '${d.status == DeductionStatus.solved ? ' (${d.deductionSteps} pasos, T${d.maxTier})' : ''}');

  final solutions = UniquenessChecker.countSolutions(pc, limit: 3);
  stdout.writeln('Soluciones encontradas: $solutions '
      '${solutions == 1 ? '(única ✓)' : '(¡PROBLEMA!)'}');

  final clientJson = pc.toClientJson();
  final leaks = ['solution', 'lethalWeapon', 'metrics']
      .where(clientJson.containsKey)
      .toList();
  stdout.writeln('Payload cliente sin solución: '
      '${leaks.isEmpty ? 'OK' : 'FILTRA $leaks'}');

  exit(v.valid && d.status == DeductionStatus.solved && solutions == 1 ? 0 : 1);
}

List<int> _seeds(List<String> args) {
  final list = _opt(args, 'seeds');
  if (list != null) return [for (final x in list.split(',')) int.parse(x.trim())];
  final count = int.parse(_opt(args, 'count') ?? '5');
  final seed = int.parse(_opt(args, 'seed') ?? '1');
  return [for (var k = 0; k < count; k++) seed + k];
}

void _measure(List<String> args) {
  final profile = DifficultyProfile.byLabel(_opt(args, 'difficulty') ?? 'casual');
  final seeds = _seeds(args);
  final weapons = _flag(args, 'weapons');
  final limits = _limits(args);
  stdout.writeln('Medición: ${profile.label} ${profile.size}x${profile.size}'
      '${weapons ? ' con arma' : ''}, semillas $seeds, '
      'tope ${limits.solver.maxNodes} nodos'
      '${limits.maxCaseTime == null ? '' : ' / ${limits.maxCaseTime!.inSeconds}s por caso'}'
      '${_flag(args, 'sin-rango') ? ', sin rango' : ''}');
  final rows = measureBatch(
    profile: profile,
    seeds: seeds,
    withWeapon: weapons,
    range: _range(args),
    limits: limits,
    onRow: (r) => stdout.writeln(formatRow(r)),
  );
  final ok = rows.where((r) => r.ok).toList();
  final total = rows.fold<int>(0, (a, r) => a + r.elapsed.inMilliseconds);
  stdout.writeln('\nResumen: ${ok.length}/${rows.length} con caso, '
      'tiempo total ${(total / 1000).toStringAsFixed(1)}s');
  final rej = totalRejections(rows);
  if (rej.isNotEmpty) {
    stdout.writeln('Descartes totales:');
    rej.forEach((r, n) => stdout.writeln('  $n × $r'));
  }
}

Directory _casesDir(List<String> args) =>
    Directory(_opt(args, 'dir') ?? '../app/assets/cases');

void _catalogAdd(List<String> args) {
  final mundo = _opt(args, 'mundo');
  if (mundo == null) {
    stderr.writeln('Falta --mundo (por ejemplo --mundo la-mansion).');
    exit(1);
  }
  final tipo = CaseKind.tryParse(_opt(args, 'tipo') ?? 'campana');
  if (tipo == null) {
    stderr.writeln('--tipo debe ser campana o reto.');
    exit(1);
  }
  // Los argumentos sin "--" que no sean valor de una opción son archivos.
  final valueOpts = {'mundo', 'tipo', 'dir'};
  final files = <File>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      if (valueOpts.contains(a.substring(2))) i++;
      continue;
    }
    files.add(File(a));
  }
  if (files.isEmpty) {
    stderr.writeln('Indica al menos un archivo de caso (.json).');
    exit(1);
  }
  final r = addCasesToCatalog(
      casesDir: _casesDir(args), sources: files, mundo: mundo, tipo: tipo);
  if (r.errors.isNotEmpty) {
    stderr.writeln('No se agregó nada:');
    for (final e in r.errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }
  for (final e in r.added) {
    stdout.writeln('Agregado: ${e.id} (${e.mundo}, ${e.tipo.name}, '
        '${e.dificultad}, orden ${e.orden}) -> ${e.archivo}');
  }
}

void _catalogCheck(List<String> args) {
  final tut = Directory(_opt(args, 'tutorial') ?? '../app/assets/tutorial');
  final report = runContentGate(casesDir: _casesDir(args), tutorialDir: tut);
  report.checks.forEach((name, c) {
    stdout.writeln('${c.passed ? 'OK   ' : 'FALLA'} $name '
        '${c.steps == null ? '' : '(${c.steps} pasos, T${c.tier})'}');
  });
  for (final p in report.problems) {
    stdout.writeln('PROBLEMA: $p');
  }
  stdout.writeln(report.passed
      ? '\nPuerta de contenido: TODO OK (${report.checks.length} casos).'
      : '\nPuerta de contenido: FALLA.');
  exit(report.passed ? 0 : 1);
}
