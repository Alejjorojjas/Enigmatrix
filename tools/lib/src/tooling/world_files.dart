/// Herramientas de contenido por mundo (ronda 3.2, usan dart:io): lectura de
/// los datos de un mundo y construcción de casos desde un PLAN.
///
/// Un plan (tools/data/mundos/mansion-casos.json, reto-casos.json...) lista,
/// por caso, su id estable, dificultad, SEMILLA explícita, si lleva arma y su
/// título y premisa. Con la misma semilla y los mismos datos de mundo el caso
/// sale idéntico: el contenido es reproducible. Formato:
/// ```json
/// {
///   "mundo": "mansion",
///   "casos": [
///     {"id": "mansion-01", "dificultad": "principiante", "semilla": 7,
///      "arma": false,
///      "titulo": {"es": "..."}, "premisa": {"es": "..."}}
///   ]
/// }
/// ```
/// `titulo` y `premisa` son opcionales al explorar semillas (el caso sale sin
/// historia); la puerta de contenido exige historia solo a lo que entra al
/// catálogo mediante el comando de la CLI.
library;

import 'dart:convert';
import 'dart:io';

import '../case_factory.dart';
import '../generator.dart';
import '../puzzle_case.dart';
import '../story.dart';
import '../world.dart';

String _stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

/// Carpeta de datos de mundos (tools/data/mundos), relativa a este paquete.
Directory defaultWorldsDir() =>
    Directory.fromUri(Platform.script.resolve('../data/mundos/'));

/// Lee un mundo de un archivo. Lanza [FormatException] si es inválido o si
/// [WorldData.problems] encuentra algo.
WorldData loadWorldFile(File f) {
  final w = WorldData.fromJson(
      jsonDecode(_stripBom(f.readAsStringSync())) as Map<String, dynamic>);
  final problems = w.problems();
  if (problems.isNotEmpty) {
    throw FormatException('mundo "${w.id}" inválido: ${problems.join('; ')}');
  }
  return w;
}

/// Un caso del plan.
class PlanCase {
  final String id;
  final String difficulty;
  final int seed;
  final bool weapon;
  final Map<String, String>? title;
  final Map<String, String>? premise;

  const PlanCase({
    required this.id,
    required this.difficulty,
    required this.seed,
    required this.weapon,
    this.title,
    this.premise,
  });

  factory PlanCase.fromJson(Map<String, dynamic> j) {
    Map<String, String>? texts(String k) =>
        j[k] == null ? null : (j[k] as Map).cast<String, String>();
    return PlanCase(
      id: j['id'] as String,
      difficulty: j['dificultad'] as String,
      seed: j['semilla'] as int,
      weapon: (j['arma'] as bool?) ?? false,
      title: texts('titulo'),
      premise: texts('premisa'),
    );
  }
}

class Plan {
  final String world;
  final List<PlanCase> cases;
  const Plan(this.world, this.cases);

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        j['mundo'] as String,
        [
          for (final c in (j['casos'] as List))
            PlanCase.fromJson((c as Map).cast<String, dynamic>())
        ],
      );

  factory Plan.fromFile(File f) => Plan.fromJson(
      jsonDecode(_stripBom(f.readAsStringSync())) as Map<String, dynamic>);
}

/// Resultado de construir un caso del plan.
class BuiltCase {
  final PlanCase plan;
  final PuzzleCase? puzzle;
  final Map<String, int> rejections;
  const BuiltCase(this.plan, this.puzzle, this.rejections);
}

/// Genera un caso del plan: perfil por dificultad, semilla explícita, mundo
/// y su historia. Devuelve el caso (o null si la semilla no da caso).
BuiltCase buildPlanCase(PlanCase c, WorldData world,
    {GenerationLimits limits = GenerationLimits.standard}) {
  final factory = CaseFactory(DifficultyProfile.byLabel(c.difficulty),
      withWeapon: c.weapon, world: world, limits: limits);
  final r = factory.generate(c.seed, caseId: c.id);
  var pc = r.puzzle;
  if (pc != null && c.title != null && c.premise != null) {
    pc = pc.withStory(
        CaseStory(world: world.id, title: c.title!, premise: c.premise!));
  }
  return BuiltCase(c, pc, r.rejections);
}

/// Escribe el caso como `<id>.json` en [outDir] y devuelve el archivo.
File writeCaseFile(PuzzleCase pc, Directory outDir) {
  outDir.createSync(recursive: true);
  final f = File('${outDir.path}/${pc.caseId}.json');
  f.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(pc.toJson())}\n');
  return f;
}
