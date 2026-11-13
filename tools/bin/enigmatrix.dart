/// CLI del motor de puzzles (Fase 0).
///
/// Uso:
///   dart run bin/enigmatrix.dart generate --difficulty tutorial|principiante|casual|intermedio
///       [--count N] [--seed S] [--weapons] [--out DIR] [--solution]
///       [--tope-nodos N] [--tope-segundos S] [--sin-rango] [--mundo ID]
///   dart run bin/enigmatrix.dart show ARCHIVO.json [--solution]
///   dart run bin/enigmatrix.dart validate ARCHIVO.json
///   dart run bin/enigmatrix.dart measure --difficulty D --seeds 1,2,3 | --count N --seed S
///       [--weapons] [--tope-nodos N] [--tope-segundos S] [--sin-rango]
///       [--mundo ID]
///   dart run bin/enigmatrix.dart build-plan PLAN.json [--out DIR] [--solo id,id]
///       Construye los casos de un plan (mundo, semillas explícitas, historia)
///       y los escribe como <id>.json en DIR (por defecto out/<mundo>).
///   dart run bin/enigmatrix.dart world-check [ID]
///       Valida los datos de un mundo (tools/data/mundos/ID.json).
///   dart run bin/enigmatrix.dart catalog-add ARCHIVO.json... --mundo M
///       [--tipo campana|reto] [--dia-inicio N] [--dir ../app/assets/cases]
///       [--servidor data/casos-servidor]
///       Los casos mansion-* y reto-* se guardan COMPLETOS en --servidor y
///       sin "solution" en --dir (la app no lleva su solución).
///   dart run bin/enigmatrix.dart catalog-check [--dir ../app/assets/cases]
///       [--tutorial ../app/assets/tutorial] [--servidor data/casos-servidor]
///       Valida los casos del servidor sobre su fuente completa y exige que
///       los assets sean idénticos sin "solution".
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
    case 'build-plan':
      _buildPlan(args.skip(1).toList());
    case 'world-check':
      _worldCheck(args.skip(1).toList());
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
      'build-plan | world-check | catalog-add | catalog-check '
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

/// Mundo temático pedido con --mundo ID (tools/data/mundos/ID.json), o null.
WorldData? _world(List<String> args) {
  final id = _opt(args, 'mundo');
  if (id == null) return null;
  return _loadWorld(id);
}

WorldData _loadWorld(String id) {
  final f = File('${defaultWorldsDir().path}/$id.json');
  if (!f.existsSync()) {
    stderr.writeln('No existe el mundo "$id" (${f.path}).');
    exit(1);
  }
  try {
    return loadWorldFile(f);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

void _generate(List<String> args) {
  final difficulty = _opt(args, 'difficulty') ?? 'principiante';
  final count = int.parse(_opt(args, 'count') ?? '1');
  final seed = int.parse(_opt(args, 'seed') ?? '1');
  final weapons = _flag(args, 'weapons');
  final outDir = _opt(args, 'out') ?? 'out';
  final showSolution = _flag(args, 'solution');

  final profile = DifficultyProfile.byLabel(difficulty);
  final generator = CaseFactory(profile,
      withWeapon: weapons,
      range: _range(args),
      limits: _limits(args),
      world: _world(args));

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
    final extras = result.extrasUsed > 0 ? ' +${result.extrasUsed} extras' : '';
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
  if (!pc.hasSolution) {
    stderr.writeln('El caso ${pc.caseId} no trae solución (se valida en el '
        'servidor): valida su fuente en tools/data/casos-servidor.');
    exit(1);
  }

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
  if (list != null)
    return [for (final x in list.split(',')) int.parse(x.trim())];
  final count = int.parse(_opt(args, 'count') ?? '5');
  final seed = int.parse(_opt(args, 'seed') ?? '1');
  return [for (var k = 0; k < count; k++) seed + k];
}

void _measure(List<String> args) {
  final profile =
      DifficultyProfile.byLabel(_opt(args, 'difficulty') ?? 'casual');
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
    world: _world(args),
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

Directory _serverDir(List<String> args) {
  final d = _opt(args, 'servidor');
  return d == null ? findServerCasesDir() : Directory(d);
}

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
  final valueOpts = {'mundo', 'tipo', 'dir', 'dia-inicio', 'servidor'};
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
  final diaInicio = _opt(args, 'dia-inicio');
  final r = addCasesToCatalog(
      casesDir: _casesDir(args),
      sources: files,
      mundo: mundo,
      tipo: tipo,
      serverCasesDir: _serverDir(args),
      diaInicio: diaInicio == null ? null : int.parse(diaInicio));
  if (r.errors.isNotEmpty) {
    stderr.writeln('No se agregó nada:');
    for (final e in r.errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }
  for (final e in r.added) {
    stdout.writeln('Agregado: ${e.id} (${e.mundo}, ${e.tipo.name}, '
        '${e.dificultad}, orden ${e.orden}'
        '${e.dia == null ? '' : ', día ${e.dia}'}) -> ${e.archivo}');
  }
}

void _worldCheck(List<String> args) {
  final ids = args.where((a) => !a.startsWith('--')).toList();
  final id = ids.isEmpty ? 'mansion' : ids.first;
  final w = _loadWorld(id); // sale con error si el mundo no es válido
  stdout.writeln('Mundo "${w.id}" (${w.nameEs}): OK · '
      '${w.cast.length} personajes, ${w.rooms.length} habitaciones, '
      '${w.weapons.length} armas.');
}

void _buildPlan(List<String> args) {
  final valueOpts = {'out', 'solo'};
  final planPath = [
    for (var i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') &&
          !(i > 0 &&
              args[i - 1].startsWith('--') &&
              valueOpts.contains(args[i - 1].substring(2))))
        args[i]
  ];
  if (planPath.isEmpty) {
    stderr.writeln('Indica el archivo del plan (.json).');
    exit(1);
  }
  final plan = Plan.fromFile(File(planPath.first));
  final world = _loadWorld(plan.world);
  final only = _opt(args, 'solo')?.split(',').toSet();
  final outDir = Directory(_opt(args, 'out') ?? 'out/${plan.world}');
  var ok = 0, failed = 0;
  for (final c in plan.cases) {
    if (only != null && !only.contains(c.id)) continue;
    final b = buildPlanCase(c, world, limits: _limits(args));
    final pc = b.puzzle;
    if (pc == null) {
      failed++;
      stdout.writeln('${c.id}: SIN CASO (semilla ${c.seed}) '
          '${b.rejections}');
      continue;
    }
    final check = checkCaseContent(pc,
        mapRules: MapRules.fromRooms(world.roomFurniture));
    final f = writeCaseFile(pc, outDir);
    final m = pc.metrics!;
    stdout.writeln('${check.passed ? 'OK   ' : 'FALLA'} ${pc.caseId} · '
        '${pc.difficulty} ${pc.map.size}x${pc.map.size} · '
        '${m.deductionSteps} pasos · T${m.maxTier} · '
        '${pc.hasWeapon ? 'con arma' : 'sin arma'} -> ${f.path}');
    for (final p in check.problems) {
      stdout.writeln('       PROBLEMA: $p');
    }
    check.passed ? ok++ : failed++;
  }
  stdout.writeln('\nResumen: $ok buenos, $failed con problemas.');
  exit(failed == 0 ? 0 : 1);
}

void _catalogCheck(List<String> args) {
  final tut = Directory(_opt(args, 'tutorial') ?? '../app/assets/tutorial');
  final report = runContentGate(
      casesDir: _casesDir(args),
      tutorialDir: tut,
      serverCasesDir: _serverDir(args));
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
