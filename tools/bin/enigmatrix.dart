/// CLI del motor de puzzles (Fase 0).
///
/// Uso:
///   dart run bin/enigmatrix.dart generate --difficulty tutorial|principiante|casual|intermedio
///       [--count N] [--seed S] [--weapons] [--out DIR] [--solution]
///   dart run bin/enigmatrix.dart show ARCHIVO.json [--solution]
///   dart run bin/enigmatrix.dart validate ARCHIVO.json
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

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
    default:
      _usage();
      exit(1);
  }
}

void _usage() {
  stdout.writeln('Comandos: generate | show | validate '
      '(ver encabezado de bin/enigmatrix.dart)');
}

String? _opt(List<String> args, String name) {
  final i = args.indexOf('--$name');
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

bool _flag(List<String> args, String name) => args.contains('--$name');

void _generate(List<String> args) {
  final difficulty = _opt(args, 'difficulty') ?? 'principiante';
  final count = int.parse(_opt(args, 'count') ?? '1');
  final seed = int.parse(_opt(args, 'seed') ?? '1');
  final weapons = _flag(args, 'weapons');
  final outDir = _opt(args, 'out') ?? 'out';
  final showSolution = _flag(args, 'solution');

  final profile = DifficultyProfile.byLabel(difficulty);
  final generator = CaseFactory(profile, withWeapon: weapons);

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
