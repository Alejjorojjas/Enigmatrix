// Ronda 3.2: historia opcional del caso (mundo, título y premisa por idioma).
import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:test/test.dart';

import 'support/cabana_cases.dart';

CaseStory historia({String world = 'mansion'}) => CaseStory(
      world: world,
      title: {'es': 'La última cena'},
      premise: {'es': 'Una cena de aniversario termina de forma inesperada.'},
    );

void main() {
  group('CaseStory', () {
    test('lee y escribe el formato del contrato', () {
      final s = CaseStory.fromJson(jsonDecode('''
        {"world":"mansion",
         "title":{"es":"La última cena"},
         "premise":{"es":"Una cena de aniversario."}}''')
          as Map<String, dynamic>);
      expect(s.world, 'mansion');
      expect(s.title('es'), 'La última cena');
      expect(s.premise('es'), 'Una cena de aniversario.');
      expect(s.toJson(), {
        'world': 'mansion',
        'title': {'es': 'La última cena'},
        'premise': {'es': 'Una cena de aniversario.'},
      });
    });

    test('un idioma que no existe devuelve null (la app usa el título actual)',
        () {
      final s = historia();
      expect(s.title('en'), isNull);
      expect(s.premise('en'), isNull);
    });

    test('admite más idiomas sin cambiar el formato', () {
      final s = CaseStory.fromJson({
        'world': 'mansion',
        'title': {'es': 'Cena', 'en': 'Dinner'},
        'premise': {'es': 'Una cena.', 'en': 'A dinner.'},
      });
      expect(s.title('en'), 'Dinner');
      expect(s.premise('en'), 'A dinner.');
    });

    test('es estricta: campos ausentes o vacíos lanzan FormatException', () {
      expect(() => CaseStory.fromJson({}), throwsFormatException);
      expect(
          () => CaseStory.fromJson({
                'world': '',
                'title': {'es': 'a'},
                'premise': {'es': 'b'}
              }),
          throwsFormatException);
      expect(
          () => CaseStory.fromJson({
                'world': 'mansion',
                'title': {'es': 'a'},
              }),
          throwsFormatException);
      expect(
          () => CaseStory.fromJson({
                'world': 'mansion',
                'title': {'es': '  '},
                'premise': {'es': 'b'}
              }),
          throwsFormatException);
      expect(
          () => CaseStory.fromJson({
                'world': 'mansion',
                'title': <String, String>{},
                'premise': {'es': 'b'}
              }),
          throwsFormatException);
    });
  });

  group('PuzzleCase.story', () {
    test('un caso sin historia sigue funcionando y no escribe "story"', () {
      final pc = cabanaCase(cabanaPin);
      expect(pc.story, isNull);
      expect(pc.story?.title('es'), isNull);
      expect(pc.toJson().containsKey('story'), isFalse);
      final back = PuzzleCase.fromJson(
          jsonDecode(jsonEncode(pc.toJson())) as Map<String, dynamic>,
          mapOverride: cabana);
      expect(back.story, isNull);
    });

    test('ida y vuelta por JSON conserva la historia', () {
      final pc = cabanaCase(cabanaPin).withStory(historia());
      final raw = jsonEncode(pc.toJson());
      final back = PuzzleCase.fromJson(jsonDecode(raw) as Map<String, dynamic>,
          mapOverride: cabana);
      expect(back.story!.world, 'mansion');
      expect(back.story!.title('es'), 'La última cena');
      expect(back.story!.premise('es'),
          'Una cena de aniversario termina de forma inesperada.');
      expect(jsonEncode(back.toJson()), raw);
    });

    test('withStory no cambia nada más del caso', () {
      final pc = cabanaCase(cabanaPin);
      final con = pc.withStory(historia());
      expect(con.caseId, pc.caseId);
      expect(con.difficulty, pc.difficulty);
      expect(con.clues, pc.clues);
      expect(con.solution.positions, pc.solution.positions);
      final sin = con.withStory(null);
      expect(sin.story, isNull);
    });

    test('el payload del cliente lleva la historia y sigue sin la solución',
        () {
      final pc = cabanaCase(cabanaPin).withStory(historia());
      final client = pc.toClientJson();
      expect(client['story'], isNotNull);
      expect(client.containsKey('solution'), isFalse);
      expect(client.containsKey('metrics'), isFalse);
    });

    test('un "story" dañado en el JSON del caso lanza FormatException', () {
      final j = cabanaCase(cabanaPin).toJson();
      j['story'] = {'world': 'mansion'};
      expect(() => PuzzleCase.fromJson(j, mapOverride: cabana),
          throwsFormatException);
    });
  });
}
