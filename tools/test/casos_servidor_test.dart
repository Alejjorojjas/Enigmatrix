// Ronda 5A.3 (corte): la app publicada no lleva la solución de los casos
// mansion-* y reto-*; la fuente completa vive en tools/data/casos-servidor y
// es la que lee el servidor (backend/scripts/build-solutions.ts).

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

final assetsDir = Directory('../app/assets/cases');
final serverDir = Directory('data/casos-servidor');

final ids = [
  for (var i = 1; i <= 10; i++) 'mansion-${i.toString().padLeft(2, '0')}',
  for (var i = 1; i <= 30; i++) 'reto-${i.toString().padLeft(3, '0')}',
];

Map<String, dynamic> readJson(File f) =>
    jsonDecode(f.readAsStringSync().replaceFirst('\uFEFF', ''))
        as Map<String, dynamic>;

void main() {
  group('assets de la app (mansion-* y reto-*)', () {
    test('ningún asset lleva la clave "solution"', () {
      // Se recorre TODO lo que parezca mansion-*/reto-* en la carpeta, no
      // solo los 40 esperados: un caso nuevo con solución también falla.
      final files = [
        for (final f in assetsDir.listSync().whereType<File>())
          if (RegExp(r'^(mansion|reto)-.*\.json$')
              .hasMatch(f.uri.pathSegments.last))
            f
      ];
      expect(files.length, 40);
      for (final f in files) {
        expect(readJson(f).containsKey('solution'), isFalse,
            reason: '${f.uri.pathSegments.last} lleva "solution": los casos '
                'del servidor no la llevan en la app');
        expect(f.readAsStringSync().contains('"solution"'), isFalse,
            reason: f.uri.pathSegments.last);
      }
    });

    test('se leen como caso sin solución', () {
      for (final id in ids) {
        final pc = loadCaseFile(File('${assetsDir.path}/$id.json'));
        expect(pc.hasSolution, isFalse, reason: id);
        expect(() => pc.solution, throwsStateError, reason: id);
      }
    });

    test('el tutorial y el banco caso-* conservan su solución (validan local)',
        () {
      final locales = [
        for (final f in assetsDir.listSync().whereType<File>())
          if (f.uri.pathSegments.last.startsWith('caso-')) f,
        File('../app/assets/tutorial/caso-tutorial.json'),
      ];
      expect(locales.length, 21);
      for (final f in locales) {
        expect(loadCaseFile(f).hasSolution, isTrue,
            reason: f.uri.pathSegments.last);
      }
    });
  });

  group('fuente completa tools/data/casos-servidor', () {
    test('tiene los 40 casos, todos con solución', () {
      final files = serverCaseFilesIn(serverDir);
      expect([
        for (final f in files) f.uri.pathSegments.last
      ], [
        for (final id in [...ids]..sort()) '$id.json'
      ]);
      for (final f in files) {
        final pc = loadCaseFile(f);
        expect(pc.hasSolution, isTrue, reason: f.uri.pathSegments.last);
        expect(pc.solution.positions.length, pc.characters.length,
            reason: f.uri.pathSegments.last);
      }
    });

    test('coincide con los assets de la app salvo la solución', () {
      for (final id in ids) {
        final full = readJson(File('${serverDir.path}/$id.json'));
        final app = readJson(File('${assetsDir.path}/$id.json'));
        expect(full.containsKey('solution'), isTrue, reason: id);
        full.remove('solution');
        expect(jsonEncode(app), jsonEncode(full), reason: id);
      }
    });

    test('cada caso pasa la puerta de contenido sobre su fuente completa', () {
      final r = runContentGate(
          casesDir: assetsDir,
          tutorialDir: Directory('../app/assets/tutorial'),
          serverCasesDir: serverDir);
      expect(r.allProblems, isEmpty);
    });
  });

  group('la puerta detecta un asset que vuelve a llevar la solución', () {
    late Directory tmpAssets;
    late Directory tmpServer;
    setUp(() {
      tmpAssets = Directory.systemTemp.createTempSync('enx_assets_');
      tmpServer = Directory.systemTemp.createTempSync('enx_servidor_');
      for (final f in assetsDir.listSync().whereType<File>()) {
        final n = f.uri.pathSegments.last;
        if (n == 'catalogo.json' || n == 'index.json') {
          f.copySync('${tmpAssets.path}/$n');
        }
      }
      for (final id in ['mansion-01']) {
        File('${serverDir.path}/$id.json')
            .copySync('${tmpServer.path}/$id.json');
        File('${assetsDir.path}/$id.json')
            .copySync('${tmpAssets.path}/$id.json');
      }
    });
    tearDown(() {
      tmpAssets.deleteSync(recursive: true);
      tmpServer.deleteSync(recursive: true);
    });

    test('asset con "solution" y asset distinto de la fuente', () {
      final asset = File('${tmpAssets.path}/mansion-01.json');
      final j = readJson(asset);
      j['solution'] =
          readJson(File('${tmpServer.path}/mansion-01.json'))['solution'];
      asset.writeAsStringSync(jsonEncode(j));
      var r = runContentGate(casesDir: tmpAssets, serverCasesDir: tmpServer);
      expect(r.problems.any((p) => p.contains('lleva "solution"')), isTrue);

      j.remove('solution');
      j['difficulty'] = 'otra';
      asset.writeAsStringSync(jsonEncode(j));
      r = runContentGate(casesDir: tmpAssets, serverCasesDir: tmpServer);
      expect(r.problems.any((p) => p.contains('no coincide con la fuente')),
          isTrue);
    });

    test('falta la fuente completa', () {
      File('${tmpServer.path}/mansion-01.json').deleteSync();
      final r = runContentGate(casesDir: tmpAssets, serverCasesDir: tmpServer);
      expect(r.problems.any((p) => p.contains('falta la fuente completa')),
          isTrue);
    });
  });

  group('PuzzleCase sin solución', () {
    final base = loadCaseFile(File('${serverDir.path}/mansion-01.json'));

    test('fromJson acepta un caso sin "solution" y toJson no la escribe', () {
      final pc = PuzzleCase.fromJson(base.withoutSolution().toJson());
      expect(pc.hasSolution, isFalse);
      expect(pc.toJson().containsKey('solution'), isFalse);
      expect(pc.caseId, base.caseId);
      expect(pc.clues.length, base.clues.length);
    });

    test('con solución sigue ida y vuelta igual', () {
      expect(jsonEncode(PuzzleCase.fromJson(base.toJson()).toJson()),
          jsonEncode(base.toJson()));
    });
  });

  test('catalog-add guarda completo en la fuente y sin solución en la app', () {
    final tmpA = Directory.systemTemp.createTempSync('enx_add_a_');
    final tmpS = Directory.systemTemp.createTempSync('enx_add_s_');
    addTearDown(() {
      tmpA.deleteSync(recursive: true);
      tmpS.deleteSync(recursive: true);
    });
    final r = addCasesToCatalog(
        casesDir: tmpA,
        sources: [File('${serverDir.path}/mansion-01.json')],
        mundo: kMundoMansion,
        tipo: CaseKind.campana,
        serverCasesDir: tmpS);
    expect(r.errors, isEmpty);
    expect(
        readJson(File('${tmpS.path}/mansion-01.json')).containsKey('solution'),
        isTrue);
    expect(
        readJson(File('${tmpA.path}/mansion-01.json')).containsKey('solution'),
        isFalse);
    final g = runContentGate(casesDir: tmpA, serverCasesDir: tmpS);
    expect(g.allProblems, isEmpty);
  });
}
