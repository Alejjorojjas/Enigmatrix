/// Herramientas con archivos (dart:io): recorrido de la puerta de contenido
/// y alta de casos en el catálogo. NO se exporta desde enigmatrix_engine.dart
/// (la app no debe depender de dart:io); se importa como
/// `package:enigmatrix_engine/enigmatrix_tools.dart`.
library;

import 'dart:convert';
import 'dart:io';

import '../catalog.dart';
import '../content_gate.dart';
import '../puzzle_case.dart';
import '../uniqueness.dart';

const kIndexFileName = 'index.json';

String _stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

String _name(FileSystemEntity f) => f.uri.pathSegments.last;

/// Archivos de caso (.json) de una carpeta, sin index.json ni catalogo.json.
List<File> caseFilesIn(Directory dir) => [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.toLowerCase().endsWith('.json') &&
            _name(f) != kIndexFileName &&
            _name(f) != kCatalogFileName)
          f
    ]..sort((a, b) => _name(a).compareTo(_name(b)));

PuzzleCase loadCaseFile(File f) => PuzzleCase.fromJson(
    jsonDecode(_stripBom(f.readAsStringSync())) as Map<String, dynamic>);

class ContentGateReport {
  /// Por nombre de archivo.
  final Map<String, CaseCheck> checks = {};

  /// Problemas globales (catálogo, índice, archivos ilegibles).
  final List<String> problems = [];

  bool get passed =>
      problems.isEmpty && checks.values.every((c) => c.passed);

  List<String> get allProblems => [
        ...problems,
        for (final e in checks.entries)
          for (final p in e.value.problems) '${e.key}: $p',
      ];
}

/// Recorre [casesDir] (y [tutorialDir] si existe) y comprueba cada caso y la
/// coherencia entre archivos, catálogo e índice.
ContentGateReport runContentGate({
  required Directory casesDir,
  Directory? tutorialDir,
  SolverLimits limits = SolverLimits.standard,
}) {
  final report = ContentGateReport();
  final caseIds = <String, String>{}; // archivo -> caseId
  final difficulties = <String, String>{}; // archivo -> dificultad

  void checkDir(Directory dir, {required bool inCatalog}) {
    for (final f in caseFilesIn(dir)) {
      final name = _name(f);
      try {
        final pc = loadCaseFile(f);
        if (inCatalog) {
          caseIds[name] = pc.caseId;
          difficulties[name] = pc.difficulty;
        }
        report.checks[inCatalog ? name : 'tutorial/$name'] =
            checkCaseContent(pc, limits: limits);
      } catch (e) {
        report.problems.add('$name: no se pudo leer como caso: $e');
      }
    }
  }

  checkDir(casesDir, inCatalog: true);
  if (tutorialDir != null && tutorialDir.existsSync()) {
    checkDir(tutorialDir, inCatalog: false);
  }

  final onDisk = caseFilesIn(casesDir).map(_name).toSet();

  // Catálogo.
  final catalogFile = File('${casesDir.path}/$kCatalogFileName');
  if (catalogFile.existsSync()) {
    try {
      final parsed = CaseCatalog.parse(catalogFile.readAsStringSync());
      for (final e in parsed.errors) {
        report.problems.add('catálogo: $e');
      }
      final cat = parsed.catalog;
      report.problems.addAll(
          [for (final p in cat.consistencyProblems()) 'catálogo: $p']);
      final listed = cat.files.toSet();
      for (final f in listed.difference(onDisk)) {
        report.problems.add('catálogo lista "$f" pero el archivo no existe');
      }
      for (final f in onDisk.difference(listed)) {
        report.problems.add('el archivo "$f" existe pero no está en el '
            'catálogo');
      }
      for (final e in cat.entries) {
        final id = caseIds[e.archivo];
        if (id != null && id != e.id) {
          report.problems.add('catálogo: "${e.archivo}" declara id "${e.id}" '
              'pero el caso es "$id"');
        }
        final dif = difficulties[e.archivo];
        if (dif != null && dif != e.dificultad) {
          report.problems.add('catálogo: "${e.id}" declara dificultad '
              '"${e.dificultad}" pero el caso es "$dif"');
        }
      }
    } catch (e) {
      report.problems.add('catálogo ilegible: $e');
    }
  } else {
    report.problems.add('falta $kCatalogFileName en ${casesDir.path}');
  }

  // Índice heredado (compatibilidad): si existe, lista exactamente los casos.
  final indexFile = File('${casesDir.path}/$kIndexFileName');
  if (indexFile.existsSync()) {
    try {
      final idx = (jsonDecode(_stripBom(indexFile.readAsStringSync())) as List)
          .cast<String>();
      final listed = idx.toSet();
      if (listed.length != idx.length) {
        report.problems.add('index.json tiene nombres repetidos');
      }
      for (final f in listed.difference(onDisk)) {
        report.problems.add('index.json lista "$f" pero no existe');
      }
      for (final f in onDisk.difference(listed)) {
        report.problems.add('el archivo "$f" no está en index.json');
      }
    } catch (e) {
      report.problems.add('index.json ilegible: $e');
    }
  }
  return report;
}

/// Resultado de agregar casos al catálogo.
class CatalogAddResult {
  final List<CatalogEntry> added;
  final List<String> errors;
  const CatalogAddResult(this.added, this.errors);
}

/// Agrega al catálogo (y al index.json heredado, si existe) los casos de
/// [sources]. Cada caso debe pasar la puerta de contenido; el id del caso es
/// su id estable y no puede repetirse. Copia el archivo a [casesDir] si no
/// está ya allí. Solo escribe si no hubo errores en NINGÚN caso.
CatalogAddResult addCasesToCatalog({
  required Directory casesDir,
  required List<File> sources,
  required String mundo,
  required CaseKind tipo,
  SolverLimits limits = SolverLimits.standard,
}) {
  final catalogFile = File('${casesDir.path}/$kCatalogFileName');
  var catalog = catalogFile.existsSync()
      ? CaseCatalog.fromJsonString(catalogFile.readAsStringSync())
      : CaseCatalog(const []);
  final errors = <String>[];
  final added = <CatalogEntry>[];
  final toCopy = <File, String>{};

  for (final src in sources) {
    try {
      final pc = loadCaseFile(src);
      final check = checkCaseContent(pc, limits: limits);
      if (!check.passed) {
        errors.add('${_name(src)}: no pasa la puerta de contenido: '
            '${check.problems.join('; ')}');
        continue;
      }
      final entry = CatalogEntry(
        id: pc.caseId,
        mundo: mundo,
        tipo: tipo,
        dificultad: pc.difficulty,
        orden: catalog.nextOrden,
        archivo: _name(src),
      );
      catalog = catalog.withEntry(entry);
      added.add(entry);
      toCopy[src] = _name(src);
    } on ArgumentError catch (e) {
      errors.add('${_name(src)}: ${e.message}');
    } catch (e) {
      errors.add('${_name(src)}: $e');
    }
  }
  if (errors.isNotEmpty) return CatalogAddResult(const [], errors);

  casesDir.createSync(recursive: true);
  toCopy.forEach((src, name) {
    final dest = File('${casesDir.path}/$name');
    if (src.absolute.path != dest.absolute.path) {
      dest.writeAsBytesSync(src.readAsBytesSync());
    }
  });
  catalogFile.writeAsStringSync(catalog.toJsonString());

  final indexFile = File('${casesDir.path}/$kIndexFileName');
  if (indexFile.existsSync()) {
    final idx = (jsonDecode(_stripBom(indexFile.readAsStringSync())) as List)
        .cast<String>()
        .toSet()
      ..addAll(toCopy.values);
    final sorted = idx.toList()..sort();
    indexFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('    ').convert(sorted)}\n');
  }
  return CatalogAddResult(added, const []);
}
