// H-43 y H-50: catálogo de casos (manifiesto) y comando para agregar casos.
import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix_engine/enigmatrix_tools.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

CatalogEntry entry(String id, int orden,
        {String archivo = '', String dif = 'casual'}) =>
    CatalogEntry(
      id: id,
      mundo: 'prueba',
      tipo: CaseKind.campana,
      dificultad: dif,
      orden: orden,
      archivo: archivo.isEmpty ? '$id.json' : archivo,
    );

void main() {
  group('CaseCatalog (pura)', () {
    test('ordena por orden y luego por id', () {
      final c = CaseCatalog([entry('b', 2), entry('z', 1), entry('a', 2)]);
      expect([for (final e in c.entries) e.id], ['z', 'a', 'b']);
      expect(c.nextOrden, 3);
      expect(CaseCatalog(const []).nextOrden, 1);
    });

    test('withEntry rechaza ids y archivos repetidos', () {
      final c = CaseCatalog([entry('a', 1)]);
      expect(() => c.withEntry(entry('a', 2, archivo: 'otro.json')),
          throwsArgumentError);
      expect(() => c.withEntry(entry('b', 2, archivo: 'a.json')),
          throwsArgumentError);
      expect(c.withEntry(entry('b', 2)).entries.length, 2);
    });

    test('ida y vuelta por JSON conserva todo', () {
      final c = CaseCatalog([
        entry('a', 1),
        CatalogEntry(
            id: 'r1',
            mundo: kBancoDePruebas,
            tipo: CaseKind.reto,
            dificultad: 'intermedio',
            orden: 2,
            archivo: 'r1.json'),
      ]);
      final back = CaseCatalog.fromJsonString(c.toJsonString());
      expect(jsonEncode(back.toJson()), jsonEncode(c.toJson()));
      expect(back.byId('r1')!.tipo, CaseKind.reto);
    });

    test('parse tolerante: salta lo inválido y repetido, y lo reporta', () {
      final text = jsonEncode({
        'version': 1,
        'casos': [
          entry('a', 1).toJson(),
          {'id': 'sin-campos'},
          entry('a', 5, archivo: 'dup.json').toJson(),
          {...entry('x', 3).toJson(), 'tipo': 'raro'},
          {...entry('y', 0).toJson()},
          {...entry('w', 4).toJson(), 'archivo': 'carpeta/w.json'},
          'no soy un objeto',
          entry('ok', 6).toJson(),
        ],
      });
      final r = CaseCatalog.parse(text);
      expect([for (final e in r.catalog.entries) e.id], ['a', 'ok']);
      expect(r.errors.length, 6);
      expect(() => CaseCatalog.fromJsonString(text), throwsFormatException);
    });

    test('documentos que no son catálogo lanzan FormatException', () {
      expect(() => CaseCatalog.parse('basura'), throwsFormatException);
      expect(() => CaseCatalog.parse('[]'), throwsFormatException);
      expect(() => CaseCatalog.parse('{"version":1}'), throwsFormatException);
      expect(() => CaseCatalog.parse('{"version":99,"casos":[]}'),
          throwsFormatException);
    });

    test('tolera el BOM al inicio', () {
      final c =
          CaseCatalog.parse('﻿${jsonEncode({'version': 1, 'casos': []})}');
      expect(c.catalog.entries, isEmpty);
    });

    test('consistencyProblems detecta repetidos', () {
      final c = CaseCatalog([
        entry('a', 1),
        entry('b', 1, archivo: 'a.json'),
      ]);
      final p = c.consistencyProblems().join(' ');
      expect(p, contains('archivo repetido'));
      expect(p, contains('orden repetido'));
    });
  });

  group('catálogo real (app/assets/cases/catalogo.json)', () {
    final cat = CaseCatalog.fromJsonString(
        File('../app/assets/cases/catalogo.json').readAsStringSync());

    final banco = cat.where(mundo: kBancoDePruebas);

    test('los 20 casos del banco de pruebas van como campaña, orden 1 a 20',
        () {
      expect(cat.consistencyProblems(), isEmpty);
      expect(banco.length, 20);
      expect(banco.every((e) => e.tipo == CaseKind.campana), isTrue);
      expect(
          [for (final e in banco) e.orden], [for (var i = 1; i <= 20; i++) i]);
    });

    test(
        'conserva los ids actuales (las claves de progreso no cambian) y '
        'el orden numérico actual de la lista', () {
      expect([
        for (final e in banco) e.id
      ], [
        for (var i = 1; i <= 8; i++) 'caso-principiante-s$i',
        for (final i in [1, 2, 3, 4, 5, 20, 21]) 'caso-casual-s$i',
        for (var i = 1; i <= 5; i++) 'caso-intermedio-s$i',
      ]);
      for (final e in cat.entries) {
        expect(e.archivo, '${e.id}.json');
      }
    });
  });

  group('addCasesToCatalog', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('enx_cat_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    File src(String name, PuzzleCase pc) {
      final d = Directory('${tmp.path}/src')..createSync(recursive: true);
      return File('${d.path}/$name')
        ..writeAsStringSync(jsonEncode(pc.toJson()));
    }

    Directory casesDir() => Directory('${tmp.path}/cases');

    test('agrega casos válidos con orden consecutivo y copia el archivo', () {
      final a = src('a.json', cabanaCase(cabanaPin, caseId: 'a'));
      final b = src('b.json', cabanaCase(cabanaPin, caseId: 'b'));
      final r = addCasesToCatalog(
          casesDir: casesDir(),
          sources: [a, b],
          mundo: kBancoDePruebas,
          tipo: CaseKind.campana);
      expect(r.errors, isEmpty);
      expect([for (final e in r.added) '${e.id}:${e.orden}'], ['a:1', 'b:2']);
      expect(File('${casesDir().path}/a.json').existsSync(), isTrue);
      final cat = CaseCatalog.fromJsonString(
          File('${casesDir().path}/catalogo.json').readAsStringSync());
      expect(cat.byId('b')!.mundo, kBancoDePruebas);
      // Segunda tanda: sigue el orden.
      final c = src('c.json', cabanaCase(cabanaPin, caseId: 'c'));
      final r2 = addCasesToCatalog(
          casesDir: casesDir(),
          sources: [c],
          mundo: kBancoDePruebas,
          tipo: CaseKind.reto);
      expect(r2.added.single.orden, 3);
      expect(r2.added.single.tipo, CaseKind.reto);
    });

    test('mantiene al día el index.json heredado si existe', () {
      casesDir().createSync(recursive: true);
      File('${casesDir().path}/index.json').writeAsStringSync('["z.json"]');
      addCasesToCatalog(
          casesDir: casesDir(),
          sources: [src('a.json', cabanaCase(cabanaPin, caseId: 'a'))],
          mundo: kBancoDePruebas,
          tipo: CaseKind.campana);
      final idx =
          jsonDecode(File('${casesDir().path}/index.json').readAsStringSync())
              as List;
      expect(idx, ['a.json', 'z.json']);
    });

    test('un id repetido se rechaza y no se escribe nada', () {
      final a = src('a.json', cabanaCase(cabanaPin, caseId: 'a'));
      addCasesToCatalog(
          casesDir: casesDir(),
          sources: [a],
          mundo: kBancoDePruebas,
          tipo: CaseKind.campana);
      final antes = File('${casesDir().path}/catalogo.json').readAsStringSync();
      final dup = src('otro.json', cabanaCase(cabanaPin, caseId: 'a'));
      final nuevo = src('n.json', cabanaCase(cabanaPin, caseId: 'n'));
      final r = addCasesToCatalog(
          casesDir: casesDir(),
          sources: [nuevo, dup],
          mundo: kBancoDePruebas,
          tipo: CaseKind.campana);
      expect(r.errors, isNotEmpty);
      expect(r.added, isEmpty);
      expect(
          File('${casesDir().path}/catalogo.json').readAsStringSync(), antes);
      expect(File('${casesDir().path}/n.json').existsSync(), isFalse);
    });

    test('un caso que no pasa la puerta de contenido no entra', () {
      final malo = src('malo.json', cabanaCase(cabanaAreaOnly, caseId: 'malo'));
      final r = addCasesToCatalog(
          casesDir: casesDir(),
          sources: [malo],
          mundo: kBancoDePruebas,
          tipo: CaseKind.campana);
      expect(r.errors.join(' '), contains('puerta de contenido'));
      expect(File('${casesDir().path}/catalogo.json').existsSync(), isFalse);
    });
  });
}
