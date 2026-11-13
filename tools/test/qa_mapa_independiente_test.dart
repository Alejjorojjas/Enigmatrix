// QA independiente (05-11-2026), tras la prueba de juego n.º 1.
// NO usa map_rules.dart: lee el JSON crudo de los 40 casos del Mundo 1 con
// tablas propias y comprueba las 3 reglas, la solución única con el solver,
// el rango de dificultad, las premisas y la gramática de las pistas.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/regeneracion_pendiente.dart';

final dir = Directory('../app/assets/cases');
// Fuente completa (con solución) de mansion-* y reto-*: los assets de la app
// ya no la llevan.
final serverDir = Directory('data/casos-servidor');

const familias = {
  'asientos': {'silla', 'sillon', 'sofa'},
  'superficies': {'mesa', 'barra'},
  'plantas': {'planta', 'arbusto'},
  'almacenaje': {'armario', 'caja'},
  'electro': {'nevera', 'lavadora'},
};
const unicos = {
  'cama', 'tv', 'piano', 'perchero', 'banera', 'nevera', 'chimenea', 'barra',
  'lavadora', 'alfombra',
};
const soloEn = {
  'cama': {'dormitorio'},
  'banera': {'bano'},
  'nevera': {'cocina'},
  'chimenea': {'salon', 'biblioteca'},
  'perchero': {'dormitorio', 'vestibulo', 'pasillo'},
  'piano': {'salon', 'sala-de-musica'},
  'lavadora': {'bano', 'bodega'},
  'barra': {'cocina'},
};

List<File> archivos() => [
      for (var i = 1; i <= 10; i++)
        File('${serverDir.path}/mansion-${i.toString().padLeft(2, '0')}.json'),
      for (var i = 1; i <= 30; i++)
        File('${serverDir.path}/reto-${i.toString().padLeft(3, '0')}.json'),
    ];

/// Problemas de las 3 reglas leyendo el JSON crudo.
List<String> problemas(Map<String, dynamic> j) {
  final m = (j['map'] as Map).cast<String, dynamic>();
  final cellArea = <int, String>{
    for (final a in m['areas'] as List)
      for (final c in (a['cells'] as List)) c as int: a['id'] as String
  };
  final objs = [for (final o in m['objects'] as List) (o as Map)];
  final out = <String>[];
  final tipos = {for (final o in objs) o['type'] as String};
  for (final e in familias.entries) {
    final inter = tipos.intersection(e.value);
    if (inter.length > 1) out.add('familia ${e.key}: $inter');
  }
  final vistos = <String, int>{};
  for (final o in objs) {
    final t = o['type'] as String;
    final salas = {for (final c in o['cells'] as List) cellArea[c as int]!};
    if (salas.length != 1) out.add('$t cruza $salas');
    final a = salas.first;
    if (unicos.contains(t)) {
      vistos.update('$a|$t', (v) => v + 1, ifAbsent: () => 1);
    }
    if (soloEn.containsKey(t) && !soloEn[t]!.contains(a)) out.add('$t en $a');
  }
  vistos.forEach((k, v) {
    if (v > 1) out.add('$v x $k');
  });
  return out;
}

Map<String, dynamic> copia(Map<String, dynamic> j) =>
    jsonDecode(jsonEncode(j)) as Map<String, dynamic>;

void main() {
  final casos = {for (final f in archivos()) f.uri.pathSegments.last: f};

  test('hay 40 archivos', () {
    expect(casos.length, 40);
    expect(casos.values.every((f) => f.existsSync()), isTrue);
  });

  test('las 3 reglas (lectura cruda del JSON) en los 40 casos', () {
    for (final e in casos.entries) {
      final j = jsonDecode(e.value.readAsStringSync()) as Map<String, dynamic>;
      expect(problemas(j), isEmpty, reason: e.key);
    }
  });

  test('mi detector SI detecta violaciones (control negativo)', () {
    final j = jsonDecode(casos['mansion-01.json']!.readAsStringSync())
        as Map<String, dynamic>;
    final c1 = copia(j);
    final objs = (c1['map']['objects'] as List);
    objs.firstWhere((o) => o['type'] == 'planta')['type'] = 'silla';
    expect(problemas(c1), isNotEmpty);
    final c2 = copia(j);
    (c2['map']['objects'] as List).first['type'] = 'cama';
    expect(problemas(c2).join(), contains('cama en'));
  });

  test('solución única (solver) + deducción pura + rango, 40 casos', () {
    final resumen = <String>[];
    for (final e in casos.entries) {
      final pc = loadCaseFile(e.value);
      final u = UniquenessChecker.analyze(pc);
      expect(u.capped, isFalse, reason: e.key);
      expect(u.solutions, 1, reason: e.key);
      final r = DeductionEngine(pc).run();
      expect(r.status, DeductionStatus.solved, reason: e.key);
      expect(r.assignment, pc.solution.positions, reason: e.key);
      final rango = kDifficultyRanges[pc.difficulty]!;
      expect(rango.contains(r.deductionSteps, r.maxTier), isTrue,
          reason: '${e.key}: ${r.deductionSteps} pasos T${r.maxTier} $rango');
      expect(pc.metrics!.deductionSteps, r.deductionSteps, reason: e.key);
      expect(pc.metrics!.maxTier, r.maxTier, reason: e.key);
      resumen.add('${e.key} ${pc.difficulty} ${pc.map.size}x${pc.map.size} '
          'pasos=${r.deductionSteps} T${r.maxTier}');
    }
    // ignore: avoid_print
    print(resumen.join('\n'));
  });

  test('la puerta de contenido FALLA con un caso alterado (copia temporal)',
      () {
    final tmp = Directory.systemTemp.createTempSync('enx_qa_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    for (final f in [
      ...serverDir.listSync().whereType<File>(),
      File('${dir.path}/catalogo.json'),
    ]) {
      final n = f.uri.pathSegments.last;
      if (n.startsWith('mansion-') || n == 'catalogo.json') {
        f.copySync('${tmp.path}/$n');
      }
    }
    List<String> deMapa(ContentGateReport r) => [
          for (final p in r.allProblems)
            if (p.contains('mapa:')) p
        ];
    // Línea base: sin incumplimientos, salvo mientras el Mundo 1 espera su
    // regeneración (tope de 2 por tipo y habitación, 06-11-2026). Entonces
    // solo cuentan los problemas NUEVOS que provoca cada alteración.
    final base = deMapa(runContentGate(casesDir: tmp));
    if (!kMundo1PendienteDeRegenerar) expect(base, isEmpty);

    void alterar(String archivo, void Function(Map<String, dynamic>) f) {
      final file = File('${tmp.path}/$archivo');
      final orig = file.readAsStringSync();
      final j = jsonDecode(orig) as Map<String, dynamic>;
      f(j);
      file.writeAsStringSync(jsonEncode(j));
      final r = runContentGate(casesDir: tmp);
      expect(deMapa(r).where((p) => !base.contains(p)), isNotEmpty,
          reason: 'no detectó la alteración en $archivo');
      expect(r.passed, isFalse);
      file.writeAsStringSync(orig);
    }

    // (a) familia asientos: planta -> silla, sillón -> sofá
    alterar('mansion-01.json', (j) {
      final objs = j['map']['objects'] as List;
      objs.firstWhere((o) => o['type'] == 'planta')['type'] = 'silla';
      objs.firstWhere((o) => o['type'] == 'sillon')['type'] = 'sofa';
    });
    // (b) cama fuera del dormitorio
    alterar('mansion-02.json', (j) {
      (j['map']['objects'] as List).first['type'] = 'cama';
    });
    // (c) dos pianos en la misma habitación
    alterar('mansion-04.json', (j) {
      final objs = j['map']['objects'] as List;
      final p = objs.firstWhere((o) => o['type'] == 'piano');
      final area = (j['map']['areas'] as List).firstWhere(
          (a) => (a['cells'] as List).contains((p['cells'] as List).first));
      // Otro mueble de la misma habitación pasa a ser un segundo piano.
      final otro = objs.firstWhere((o) =>
          o['type'] != 'piano' &&
          (area['cells'] as List).contains((o['cells'] as List).first));
      otro['type'] = 'piano';
    });
    // (d) bañera en una habitación sin baño
    alterar('mansion-03.json', (j) {
      (j['map']['objects'] as List).last['type'] = 'banera';
    });
  });

  test('premisas encajan con su mapa', () {
    Map<String, dynamic> mapa(String id) =>
        (jsonDecode(casos['$id.json']!.readAsStringSync()) as Map)['map']
            as Map<String, dynamic>;
    String sala(Map<String, dynamic> m, Map o) {
      final c = (o['cells'] as List).first;
      return [
        for (final a in m['areas'] as List)
          if ((a['cells'] as List).contains(c)) a['id'] as String
      ].single;
    }

    Set<String> habs(String id) =>
        {for (final a in mapa(id)['areas'] as List) a['id'] as String};
    Set<String> tiposEn(String id, String room) => {
          for (final o in mapa(id)['objects'] as List)
            if (sala(mapa(id), o as Map) == room) o['type'] as String
        };
    String premisa(String id) {
      final pc = loadCaseFile(casos['$id.json']!);
      return '${pc.story!.title('es')} | ${pc.story!.premise('es')}';
    }

    for (final id in [
      'mansion-01',
      'mansion-03',
      'mansion-04',
      'reto-011',
      'reto-014',
      'reto-020'
    ]) {
      // ignore: avoid_print
      print('$id: ${premisa(id)}\n   habs=${habs(id)} tipos=${{
        for (final o in mapa(id)['objects'] as List) o['type']
      }}');
    }
    expect(habs('mansion-01'), contains('comedor'));
    expect(habs('mansion-03'), contains('dormitorio'));
    expect(tiposEn('mansion-03', 'dormitorio'), contains('cama'));
    expect({for (final o in mapa('mansion-04')['objects'] as List) o['type']},
        contains('piano'));
    expect({for (final o in mapa('reto-011')['objects'] as List) o['type']},
        contains('chimenea'));
    for (final id in ['reto-014', 'reto-020']) {
      expect({for (final o in mapa(id)['objects'] as List) o['type']},
          contains('perchero'),
          reason: id);
    }
  });

  test('gramática de las pistas reales (40 casos)', () {
    final raros = <String>[];
    final vistos = <String>{};
    const fem = 'nevera|bañera|chimenea|silla|mesa|planta|barra|alfombra|cama|'
        'caja|lavadora|TV';
    const mas = 'perchero|piano|armario|sillón|sofá|arbusto';
    final malos = [
      RegExp(r'\ba el\b'),
      RegExp('\\bun ($fem)\\b'),
      RegExp('\\buna ($mas)\\b'),
      RegExp('\\bel ($fem)\\b'),
      RegExp('\\bla ($mas)\\b'),
      RegExp(r'  '),
      RegExp(r'\bnull\b'),
    ];
    for (final e in casos.entries) {
      final pc = loadCaseFile(e.value);
      final textos = [
        for (final c in pc.clues) c.textEs(pc.map, pc.names),
        for (final c in pc.clues) c.cardTextEs(pc.map, pc.names),
      ];
      for (final t in textos) {
        vistos.add(t);
        for (final r in malos) {
          if (r.hasMatch(t)) raros.add('${e.key}: "$t" ($r)');
        }
      }
    }
    final nuevos = vistos
        .where((t) => RegExp('perchero|nevera|chimenea|bañera').hasMatch(t))
        .toList()
      ..sort();
    // ignore: avoid_print
    print('frases con objetos nuevos (${nuevos.length}):\n${nuevos.join('\n')}');
    expect(raros, isEmpty);
  });

  test('la curva del Mundo 1 crece (recalculada)', () {
    final pasos = [
      for (var i = 1; i <= 10; i++)
        DeductionEngine(loadCaseFile(
                casos['mansion-${i.toString().padLeft(2, '0')}.json']!))
            .run()
            .deductionSteps
    ];
    // ignore: avoid_print
    print('pasos campaña: $pasos');
    double media(Iterable<int> x) => x.reduce((a, b) => a + b) / x.length;
    expect(media(pasos.take(3)), lessThan(media(pasos.skip(3).take(3))));
    expect(media(pasos.skip(3).take(3)), lessThan(media(pasos.skip(6))));
    expect(pasos.last, greaterThan(pasos.first));
  });
}
