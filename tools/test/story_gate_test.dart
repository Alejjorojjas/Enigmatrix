// Ronda 3.2: la puerta de contenido y el catálogo frente a historias, armas
// de fuego, días de reto e índice heredado.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

CaseStory historia(
        {String world = 'mansion',
        String title = 'La última cena',
        String premise =
            'Una cena de aniversario termina de forma inesperada.'}) =>
    CaseStory(world: world, title: {'es': title}, premise: {'es': premise});

PuzzleCase conHistoria(CaseStory s, {String id = 'test'}) =>
    cabanaCase(cabanaPin, caseId: id).withStory(s);

void main() {
  group('contentTextProblems', () {
    test('un caso sin historia no tiene problemas de texto', () {
      expect(contentTextProblems(cabanaCase(cabanaPin)), isEmpty);
    });

    test('una historia correcta pasa', () {
      expect(contentTextProblems(conHistoria(historia())), isEmpty);
      expect(checkCaseContent(conHistoria(historia())).passed, isTrue);
    });

    test('rechaza palabras de gore, de armas de fuego o de infancia', () {
      for (final w in [
        'sangre',
        'cadáver',
        'pistola',
        'disparo',
        'Infantil',
        'niños',
        'bomba'
      ]) {
        final p = contentTextProblems(
            conHistoria(historia(premise: 'Una noche con $w en la casa.')));
        expect(p.join(' '), contains('no permitida'), reason: w);
      }
    });

    test('no confunde una palabra que solo contiene un fragmento', () {
      // "rifles" no está, pero "trifle" o "disparate" no deben saltar.
      final p = contentTextProblems(conHistoria(
          historia(premise: 'Un disparate de familia y un postre de trifle.')));
      expect(p, isEmpty);
    });

    test('rechaza título o premisa demasiado largos o con saltos de línea', () {
      expect(
          contentTextProblems(
                  conHistoria(historia(title: 'A' * (kMaxTitleChars + 1))))
              .join(' '),
          contains('supera'));
      expect(
          contentTextProblems(
                  conHistoria(historia(premise: 'B' * (kMaxPremiseChars + 1))))
              .join(' '),
          contains('supera'));
      expect(
          contentTextProblems(conHistoria(historia(premise: 'Uno.\nDos.')))
              .join(' '),
          contains('saltos de línea'));
      expect(
          contentTextProblems(conHistoria(historia(title: ' Con espacio ')))
              .join(' '),
          contains('espacios'));
    });

    test('exige título y premisa en español', () {
      final soloIngles = CaseStory(
          world: 'mansion',
          title: {'en': 'Dinner'},
          premise: {'en': 'A dinner'});
      final p = contentTextProblems(conHistoria(soloIngles)).join(' ');
      expect(p, contains('título en español'));
      expect(p, contains('premisa en español'));
    });

    test('rechaza un arma de fuego en el mapa', () {
      final mapa = GameMap(
        id: 'm',
        nameEs: 'M',
        size: cabana.size,
        areas: cabana.areas,
        objects: cabana.objects,
        weapons: const [
          WeaponDef(
              id: 'pistola',
              nameEs: 'la pistola',
              category: WeaponCategory.contundente,
              areaId: 'salon'),
        ],
      );
      final base = cabanaCase(cabanaPin);
      final pc = PuzzleCase(
        caseId: 'x',
        map: mapa,
        characters: base.characters,
        victimId: base.victimId,
        clues: base.clues,
        hasWeapon: false,
        difficulty: base.difficulty,
        solution: base.solution,
      );
      expect(contentTextProblems(pc).join(' '), contains('arma no permitida'));
      expect(checkCaseContent(pc).passed, isFalse);
    });
  });

  group('catálogo: día de reto', () {
    CatalogEntry reto(String id, int orden, int? dia) => CatalogEntry(
        id: id,
        mundo: kMundoMansion,
        tipo: CaseKind.reto,
        dificultad: 'casual',
        orden: orden,
        archivo: '$id.json',
        dia: dia);

    test('ida y vuelta por JSON conserva el día y no lo escribe sin él', () {
      final e = reto('r', 1, 7);
      expect(e.toJson()['dia'], 7);
      expect(CatalogEntry.fromJson(e.toJson()).dia, 7);
      final camp = CatalogEntry(
          id: 'c',
          mundo: kMundoMansion,
          tipo: CaseKind.campana,
          dificultad: 'casual',
          orden: 2,
          archivo: 'c.json');
      expect(camp.toJson().containsKey('dia'), isFalse);
      expect(CatalogEntry.fromJson(camp.toJson()).dia, isNull);
    });

    test('un día fuera de 1 a 30 es inválido', () {
      for (final d in [0, 31, -1, 'tres']) {
        final j = reto('r', 1, 1).toJson()..['dia'] = d;
        expect(() => CatalogEntry.fromJson(j), throwsFormatException,
            reason: '$d');
      }
    });

    test('consistencia: reto sin día, campaña con día y días repetidos', () {
      final p = CaseCatalog([
        reto('a', 1, null),
        reto('b', 2, 3),
        reto('c', 3, 3),
        CatalogEntry(
            id: 'd',
            mundo: kMundoMansion,
            tipo: CaseKind.campana,
            dificultad: 'casual',
            orden: 4,
            archivo: 'd.json',
            dia: 5),
      ]).consistencyProblems().join(' | ');
      expect(p, contains('no tiene "dia"'));
      expect(p, contains('no debe tener "dia"'));
      expect(p, contains('día de reto repetido'));
    });

    test('where filtra por mundo y tipo sin perder el orden', () {
      final c = CaseCatalog([
        reto('a', 1, 1),
        reto('b', 2, 2),
        CatalogEntry(
            id: 'x',
            mundo: kBancoDePruebas,
            tipo: CaseKind.campana,
            dificultad: 'casual',
            orden: 3,
            archivo: 'x.json'),
      ]);
      expect([for (final e in c.where(tipo: CaseKind.reto)) e.id], ['a', 'b']);
      expect([for (final e in c.where(mundo: kBancoDePruebas)) e.id], ['x']);
      expect(c.where().length, 3);
    });
  });

  group('addCasesToCatalog con mundos reales', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('enx_story_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Directory casesDir() => Directory('${tmp.path}/cases');

    File src(String name, PuzzleCase pc) {
      final f = File('${tmp.path}/$name')
        ..writeAsStringSync(jsonEncode(pc.toJson()));
      return f;
    }

    CatalogAddResult add(List<File> files,
            {String mundo = kMundoMansion,
            CaseKind tipo = CaseKind.campana,
            int? diaInicio}) =>
        addCasesToCatalog(
            casesDir: casesDir(),
            sources: files,
            mundo: mundo,
            tipo: tipo,
            diaInicio: diaInicio);

    test('un mundo real exige historia', () {
      final r = add([src('a.json', cabanaCase(cabanaPin, caseId: 'a'))]);
      expect(r.errors.join(' '), contains('no tiene historia'));
      expect(r.added, isEmpty);
    });

    test('la historia debe ser del mundo al que se agrega', () {
      final r =
          add([src('a.json', conHistoria(historia(world: 'hotel'), id: 'a'))]);
      expect(r.errors.join(' '), contains('"hotel"'));
      expect(r.added, isEmpty);
    });

    test('el banco de pruebas no exige historia', () {
      final r = add([src('a.json', cabanaCase(cabanaPin, caseId: 'a'))],
          mundo: kBancoDePruebas);
      expect(r.errors, isEmpty);
      expect(r.added.single.dia, isNull);
    });

    test('los retos toman días consecutivos desde --dia-inicio', () {
      final r = add([
        src('r1.json', conHistoria(historia(), id: 'r1')),
        src('r2.json', conHistoria(historia(), id: 'r2')),
      ], tipo: CaseKind.reto, diaInicio: 5);
      expect([for (final e in r.added) e.dia], [5, 6]);
      // Sin día de inicio continúa tras el último usado.
      final r2 = add([src('r3.json', conHistoria(historia(), id: 'r3'))],
          tipo: CaseKind.reto);
      expect(r2.added.single.dia, 7);
    });

    test('no deja pasar del día 30 y no escribe nada', () {
      final r = add([
        src('r1.json', conHistoria(historia(), id: 'r1')),
        src('r2.json', conHistoria(historia(), id: 'r2')),
      ], tipo: CaseKind.reto, diaInicio: kDiasReto);
      expect(r.errors.join(' '), contains('día $kDiasReto'));
      expect(r.added, isEmpty);
      expect(File('${casesDir().path}/catalogo.json').existsSync(), isFalse);
    });

    test('un día de campaña se ignora', () {
      final r = add([src('c1.json', conHistoria(historia(), id: 'c1'))],
          diaInicio: 3);
      expect(r.added.single.dia, isNull);
    });

    test('el index.json heredado solo recibe casos del banco de pruebas', () {
      casesDir().createSync(recursive: true);
      File('${casesDir().path}/index.json').writeAsStringSync('["z.json"]');
      add([src('m1.json', conHistoria(historia(), id: 'm1'))]);
      expect(
          jsonDecode(File('${casesDir().path}/index.json').readAsStringSync()),
          ['z.json']);
      add([src('b1.json', cabanaCase(cabanaPin, caseId: 'b1'))],
          mundo: kBancoDePruebas);
      expect(
          jsonDecode(File('${casesDir().path}/index.json').readAsStringSync()),
          ['b1.json', 'z.json']);
    });
  });

  group('runContentGate con historias', () {
    late Directory tmp;

    // Estas pruebas hablan de historias, no de muebles: los fixtures de la
    // cabaña no cumplen las reglas de mapa de La Mansión, así que se eximen.
    ContentGateReport gate(Directory d) => runContentGate(
        casesDir: d, mapRulesExemptMundos: {kBancoDePruebas, kMundoMansion});

    setUp(() => tmp = Directory.systemTemp.createTempSync('enx_gate2_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String id, PuzzleCase pc,
        {String mundo = kMundoMansion,
        String tipo = 'campana',
        int orden = 1,
        int? dia}) {
      File('${tmp.path}/$id.json').writeAsStringSync(jsonEncode(pc.toJson()));
      final cat = File('${tmp.path}/catalogo.json');
      final casos = cat.existsSync()
          ? (jsonDecode(cat.readAsStringSync())['casos'] as List)
          : [];
      casos.add({
        'id': id,
        'mundo': mundo,
        'tipo': tipo,
        'dificultad': 'test',
        'orden': orden,
        'archivo': '$id.json',
        if (dia != null) 'dia': dia,
      });
      cat.writeAsStringSync(jsonEncode({'version': 1, 'casos': casos}));
    }

    test('un mundo real con historia propia pasa', () {
      write('a', conHistoria(historia(), id: 'a'));
      final r = gate(tmp);
      expect(r.allProblems, isEmpty);
    });

    test('un mundo real sin historia falla', () {
      write('a', cabanaCase(cabanaPin, caseId: 'a'));
      final r = gate(tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join(' '), contains('no tiene historia'));
    });

    test('la historia de otro mundo falla', () {
      write('a', conHistoria(historia(world: 'hotel'), id: 'a'));
      final r = gate(tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join(' '), contains('su historia dice "hotel"'));
    });

    test('un texto con palabras no permitidas hace fallar la puerta', () {
      write(
          'a',
          conHistoria(historia(premise: 'Hay sangre en la alfombra.'),
              id: 'a'));
      final r = gate(tmp);
      expect(r.passed, isFalse);
      expect(r.allProblems.join(' '), contains('"sangre"'));
    });

    test('el índice no debe listar casos que no son del banco de pruebas', () {
      write('a', conHistoria(historia(), id: 'a'));
      write('b', cabanaCase(cabanaPin, caseId: 'b'),
          mundo: kBancoDePruebas, orden: 2);
      File('${tmp.path}/index.json')
          .writeAsStringSync(jsonEncode(['a.json', 'b.json']));
      final r = gate(tmp);
      expect(r.allProblems.join(' '), contains('no es del banco de pruebas'));
      File('${tmp.path}/index.json').writeAsStringSync(jsonEncode(['b.json']));
      expect(gate(tmp).allProblems, isEmpty);
    });
  });
}
