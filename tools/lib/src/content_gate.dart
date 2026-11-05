/// Puerta de contenido (H-68): comprobación pura de un caso publicable.
/// Un caso pasa si (1) el Validator acepta su solución, (2) esa solución es
/// única por búsqueda exhaustiva, (3) se resuelve por deducción pura y
/// (4) lo que deduce coincide con la solución declarada.
/// El recorrido de carpetas vive en tooling/ (usa dart:io).
library;

import 'deduction.dart';
import 'puzzle_case.dart';
import 'uniqueness.dart';
import 'validator.dart';
import 'world.dart';

class CaseCheck {
  final String caseId;
  final bool validatorOk;
  final bool unique;
  final bool pureDeduction;
  final int? steps;
  final int? tier;

  /// Problemas legibles; vacío = el caso pasa la puerta.
  final List<String> problems;

  const CaseCheck({
    required this.caseId,
    required this.validatorOk,
    required this.unique,
    required this.pureDeduction,
    required this.steps,
    required this.tier,
    required this.problems,
  });

  bool get passed => problems.isEmpty;
}

CaseCheck checkCaseContent(PuzzleCase pc,
    {SolverLimits limits = SolverLimits.standard}) {
  final problems = <String>[];

  final v = Validator.validate(pc, pc.solution.positions);
  if (!v.valid) problems.add('el Validator rechaza la solución: ${v.errors}');
  if (v.valid && v.murdererId != pc.solution.murdererId) {
    problems.add('asesino deducido (${v.murdererId}) distinto del declarado '
        '(${pc.solution.murdererId})');
  }
  if (v.valid && v.lethalWeaponId != pc.solution.lethalWeaponId) {
    problems.add('arma deducida (${v.lethalWeaponId}) distinta de la '
        'declarada (${pc.solution.lethalWeaponId})');
  }

  problems.addAll(contentTextProblems(pc));

  var unique = false;
  final u = UniquenessChecker.analyze(pc, limits: limits);
  if (u.capped) {
    problems.add('unicidad no decidida: tope de ${u.capKind} superado');
  } else if (u.solutions != 1) {
    problems.add('solución no única (${u.solutions} encontradas)');
  } else {
    unique = true;
  }

  final d = DeductionEngine(pc).run();
  var pure = false;
  if (d.status != DeductionStatus.solved) {
    problems.add('no se resuelve por deducción pura (${d.status.name})');
  } else if (!_same(d.assignment!, pc.solution.positions)) {
    problems.add('la deducción llega a posiciones distintas de la solución');
  } else {
    pure = true;
  }

  return CaseCheck(
    caseId: pc.caseId,
    validatorOk: v.valid,
    unique: unique,
    pureDeduction: pure,
    steps: pure ? d.deductionSteps : null,
    tier: pure ? d.maxTier : null,
    problems: problems,
  );
}

/// Palabras que no deben aparecer en el título ni en la premisa (docs/13:
/// cozy mystery, sin gore, sin armas de fuego, sin lenguaje vulgar, nunca
/// "Infantil"). Se comparan sin tildes y como palabra suelta.
const kForbiddenStoryWords = [
  'sangre',
  'sangriento',
  'sangrienta',
  'cadaver',
  'mutilado',
  'mutilada',
  'descuartizado',
  'descuartizada',
  'degollado',
  'degollada',
  'apunalado',
  'apunalada',
  'destripado',
  'destripada',
  'pistola',
  'revolver',
  'escopeta',
  'rifle',
  'disparo',
  'disparos',
  'tiroteo',
  'bomba',
  'granada',
  'infantil',
  'nino',
  'nina',
  'ninos',
  'ninas',
];

/// Largo máximo del título y de la premisa (pillar 3: se lee en una frase).
const kMaxTitleChars = 40;
const kMaxPremiseChars = 220;

/// Problemas de TEXTO de un caso (no de lógica): armas del mapa que no
/// cumplen docs/13 (nunca de fuego) y, si hay historia, título y premisa
/// presentes en español, de largo razonable y sin palabras prohibidas.
List<String> contentTextProblems(PuzzleCase pc) {
  final problems = <String>[];
  for (final w in pc.map.weapons) {
    final bad = forbiddenWeaponWord(w.nameEs) ?? forbiddenWeaponWord(w.id);
    if (bad != null) {
      problems.add('arma no permitida (${w.nameEs}): contiene "$bad"');
    }
  }
  final story = pc.story;
  if (story != null) {
    final title = story.title('es');
    final premise = story.premise('es');
    if (title == null) problems.add('la historia no tiene título en español');
    if (premise == null) {
      problems.add('la historia no tiene premisa en español');
    }
    void lint(String what, String? text, int max) {
      if (text == null) return;
      if (text.trim() != text || text.contains('\n')) {
        problems.add('$what tiene espacios o saltos de línea de más');
      }
      if (text.length > max) {
        problems.add('$what supera $max caracteres (${text.length})');
      }
      final words = foldEs(text).split(RegExp('[^a-z]+'));
      for (final w in kForbiddenStoryWords) {
        if (words.contains(w)) {
          problems.add('$what contiene la palabra no permitida "$w"');
        }
      }
    }

    lint('el título', title, kMaxTitleChars);
    lint('la premisa', premise, kMaxPremiseChars);
  }
  return problems;
}

bool _same(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
