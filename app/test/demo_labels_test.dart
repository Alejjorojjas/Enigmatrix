/// Etiquetas de lo simulado: lo que aún no es real debe verse como tal
/// (DEMO en vidas, racha, Perfil y Reto; "Próximamente" en Configuración) y
/// la lista de casos marca "En curso" las partidas guardadas (clave game:ID).
library;

import 'dart:convert';

import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/content_overrides.dart';

Future<List<PuzzleCase>> _loadRealCases() async {
  final raw = await rootBundle.loadString('assets/cases/index.json');
  final names = (jsonDecode(raw) as List).cast<String>()..remove('index.json');
  final cases = <PuzzleCase>[];
  for (final name in names.take(4)) {
    final j =
        jsonDecode(await rootBundle.loadString('assets/cases/$name'))
            as Map<String, dynamic>;
    cases.add(PuzzleCase.fromJson(j));
  }
  return cases;
}

Future<void> _pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...contentOverrides(const [])],
      child: const MaterialApp(home: HomeShell()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('etiquetas DEMO', () {
    testWidgets('Inicio: el chip de vidas y la racha llevan DEMO', (
      tester,
    ) async {
      await _pumpShell(tester);
      expect(find.text('4/5'), findsOneWidget); // chip de vidas
      expect(find.textContaining('Racha:'), findsOneWidget);
      // Vidas + racha (y la tarjeta del reto) muestran la etiqueta.
      expect(find.text('DEMO'), findsAtLeastNWidgets(2));
    });

    testWidgets('Reto: la racha lleva DEMO', (tester) async {
      await _pumpShell(tester);
      await _openTab(tester, Icons.today_rounded);
      expect(find.text('Reto diario'), findsWidgets);
      expect(find.textContaining('días de racha'), findsOneWidget);
      expect(find.text('DEMO'), findsAtLeastNWidgets(1));
    });

    testWidgets('Perfil: lleva DEMO', (tester) async {
      await _pumpShell(tester);
      await _openTab(tester, Icons.person_rounded);
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('DEMO'), findsAtLeastNWidgets(1));
    });

    testWidgets('Configuración: Sonido y Vibración funcionan; Música y '
        'Notificaciones siguen "Próximamente"', (tester) async {
      await _pumpShell(tester);
      await _openTab(tester, Icons.person_rounded);
      await tester.tap(find.text('Configuración'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Solo quedan dos: Música y Notificaciones.
      expect(find.text('Próximamente'), findsNWidgets(2));
      expect(find.text('Sonido'), findsOneWidget);
      expect(find.text('Vibración'), findsOneWidget);
    });
  });

  group('partida en curso en la lista de casos', () {
    testWidgets('una clave game:<id> sembrada muestra "En curso"', (
      tester,
    ) async {
      final cases = (await tester.runAsync(_loadRealCases))!;
      final saved = SavedGame(
        elapsed: 125,
        errors: 1,
        savedAt: DateTime.utc(2026, 11, 4, 9),
        board: BoardState.empty(),
        clueMarks: List.filled(cases[1].clues.length, 0),
        autoX: true,
        mapMode: true,
      );
      // Se siembra el 2.º caso: el 1.º es la ficha actual (su etiqueta es
      // SIGUIENTE CASO) y los demás muestran "En curso".
      // Contrato: {"v":1,"elapsed","errors","savedAt","board","clueMarks",
      // "autoX","mapMode"}.
      final raw = saved.encode();
      expect(
        (jsonDecode(raw) as Map).keys,
        containsAll(<String>[
          'v',
          'elapsed',
          'errors',
          'savedAt',
          'board',
          'clueMarks',
          'autoX',
          'mapMode',
        ]),
      );
      SharedPreferences.setMockInitialValues({'game:${cases[1].caseId}': raw});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...contentOverrides(cases)],
          child: const MaterialApp(home: CaseListScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('En curso'), findsOneWidget);
      expect(find.text('En curso · 2:05'), findsOneWidget);
    });
  });
}
