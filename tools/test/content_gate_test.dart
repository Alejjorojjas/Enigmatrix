// H-68: puerta de contenido. Recorre app/assets/cases y app/assets/tutorial y
// comprueba en cada JSON: pasa el Validator, solución única, deducción pura
// resuelta, y que el catálogo y el índice listan exactamente los archivos
// que existen. Si alguien agrega un caso roto, esta prueba falla.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

final casesDir = Directory('../app/assets/cases');
final tutorialDir = Directory('../app/assets/tutorial');

void main() {
  group('puerta de contenido sobre los assets reales', () {
    final files = caseFilesIn(casesDir);

    test(
        'hay casos que revisar (20 del banco, 10 del Mundo 1, 30 de reto y '
        '1 de tutorial)', () {
      expect(files.length, 60);
      expect(caseFilesIn(tutorialDir).length, 1);
    });

    for (final f in [...files, ...caseFilesIn(tutorialDir)]) {
      final name = f.uri.pathSegments.last;
      test('$name: Validator, solución única y deducción pura', () {
        final pc = loadCaseFile(f);
        // 1. El Validator acepta la solución declarada.
        final v = Validator.validate(pc, pc.solution.positions);
        expect(v.valid, isTrue, reason: '${v.errors}');
        // 2. Solución única por búsqueda exhaustiva.
        expect(UniquenessChecker.countSolutions(pc), 1);
        // 3. Deducción pura: llega sola a la solución, sin adivinar.
        final d = DeductionEngine(pc).run();
        expect(d.status, DeductionStatus.solved);
        expect(d.assignment, pc.solution.positions);
        // Y el resumen de la puerta coincide.
        final check = checkCaseContent(pc);
        expect(check.problems, isEmpty);
        expect(check.passed, isTrue);
      });
    }

    test('la puerta completa (casos, catálogo e índice) pasa sin problemas',
        () {
      final report =
          runContentGate(casesDir: casesDir, tutorialDir: tutorialDir);
      expect(report.allProblems, isEmpty);
      expect(report.passed, isTrue);
      expect(report.checks.length, 61);
    });

    test('el catálogo lista exactamente los archivos que existen', () {
      final cat = CaseCatalog.fromJsonString(
          File('${casesDir.path}/catalogo.json').readAsStringSync());
      final onDisk = [for (final f in files) f.uri.pathSegments.last]..sort();
      expect([...cat.files]..sort(), onDisk);
    });

    test(
        'el índice heredado lista exactamente los 20 casos del banco de '
        'pruebas (los mundos reales solo van en el catálogo)', () {
      final idx =
          (jsonDecode(File('${casesDir.path}/index.json').readAsStringSync())
                  as List)
              .cast<String>();
      final cat = CaseCatalog.fromJsonString(
          File('${casesDir.path}/catalogo.json').readAsStringSync());
      final banco = [
        for (final e in cat.entries)
          if (e.mundo == kBancoDePruebas) e.archivo
      ]..sort();
      expect(banco.length, 20);
      expect([...idx]..sort(), banco);
    });
  });

  group('checkCaseContent rechaza lo que no debe publicarse', () {
    test('caso válido: pasa', () {
      final c = checkCaseContent(cabanaCase(cabanaPin));
      expect(c.passed, isTrue, reason: '${c.problems}');
      expect(c.unique && c.pureDeduction && c.validatorOk, isTrue);
      expect(c.steps, greaterThan(0));
    });

    test('caso ambiguo (varias soluciones, se atasca): falla', () {
      final c = checkCaseContent(cabanaCase(cabanaAreaOnly));
      expect(c.passed, isFalse);
      expect(c.unique, isFalse);
      expect(c.pureDeduction, isFalse);
      expect(c.problems.join(' '), contains('no única'));
      expect(c.problems.join(' '), contains('deducción pura'));
    });

    test('solución declarada que el Validator rechaza: falla', () {
      final bad = PuzzleCase(
        caseId: 'malo',
        map: cabana,
        characters: cabanaCase(cabanaPin).characters,
        victimId: 'c4',
        clues: cabanaPin,
        hasWeapon: false,
        difficulty: 'test',
        // Dos personas en la misma fila: inválida.
        solution: Solution(
          positions: {'c1': 1, 'c2': 2, 'c3': 10, 'c4': 15},
          murdererId: 'c3',
        ),
      );
      final c = checkCaseContent(bad);
      expect(c.validatorOk, isFalse);
      expect(c.passed, isFalse);
    });

    test('tope del solver superado: se reporta, no se da por válido', () {
      final c = checkCaseContent(cabanaCase(cabanaPin),
          limits: const SolverLimits(maxNodes: 1));
      expect(c.passed, isFalse);
      expect(c.problems.join(' '), contains('tope'));
    });
  });

  group('runContentGate en una carpeta temporal', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('enx_gate_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    String caseJson(String id) {
      final j = cabanaCase(cabanaPin, caseId: id).toJson();
      return jsonEncode(j);
    }

    void writeCase(String name, String id) =>
        File('${tmp.path}/$name').writeAsStringSync(caseJson(id));

    void writeCatalog(List<Map<String, Object>> casos) =>
        File('${tmp.path}/catalogo.json')
            .writeAsStringSync(jsonEncode({'version': 1, 'casos': casos}));

    Map<String, Object> entry(String id, String file, int orden) => {
          'id': id,
          'mundo': kBancoDePruebas,
          'tipo': 'campana',
          'dificultad': 'test',
          'orden': orden,
          'archivo': file,
        };

    test('carpeta coherente: pasa', () {
      writeCase('a.json', 'a');
      writeCase('b.json', 'b');
      writeCatalog([entry('a', 'a.json', 1), entry('b', 'b.json', 2)]);
      File('${tmp.path}/index.json')
          .writeAsStringSync(jsonEncode(['a.json', 'b.json']));
      final r = runContentGate(casesDir: tmp);
      expect(r.allProblems, isEmpty);
      expect(r.passed, isTrue);
    });

    test('el catálogo lista un archivo que no existe: falla', () {
      writeCase('a.json', 'a');
      writeCatalog([entry('a', 'a.json', 1), entry('b', 'b.json', 2)]);
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('"b.json" pero el archivo'));
    });

    test('hay un archivo que el catálogo no lista: falla', () {
      writeCase('a.json', 'a');
      writeCase('extra.json', 'extra');
      writeCatalog([entry('a', 'a.json', 1)]);
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('extra.json'));
    });

    test('el índice no coincide con los archivos: falla', () {
      writeCase('a.json', 'a');
      writeCatalog([entry('a', 'a.json', 1)]);
      File('${tmp.path}/index.json')
          .writeAsStringSync(jsonEncode(['a.json', 'fantasma.json']));
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('fantasma.json'));
    });

    test('el id del catálogo no coincide con el del caso: falla', () {
      writeCase('a.json', 'real');
      writeCatalog([entry('otro', 'a.json', 1)]);
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('otro'));
    });

    test('un caso ambiguo en la carpeta hace fallar la puerta', () {
      File('${tmp.path}/a.json').writeAsStringSync(
          jsonEncode(cabanaCase(cabanaAreaOnly, caseId: 'a').toJson()));
      writeCatalog([entry('a', 'a.json', 1)]);
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.checks['a.json']!.passed, isFalse);
    });

    test('JSON roto: se reporta como problema, no revienta', () {
      File('${tmp.path}/roto.json').writeAsStringSync('{no es json');
      writeCatalog([]);
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('roto.json'));
    });

    test('sin catalogo.json: falla', () {
      writeCase('a.json', 'a');
      final r = runContentGate(casesDir: tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join('\n'), contains('catalogo.json'));
    });
  });
}
