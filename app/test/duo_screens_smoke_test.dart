/// Smoke tests del pase Duo (2026-07-11): las pantallas nuevas construyen,
/// hacen layout y pintan sin excepciones, con casos reales de assets.
library;

import 'dart:convert';

import 'package:enigmatrix/main.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<PuzzleCase>> _loadRealCases() async {
  final raw = await rootBundle.loadString('assets/cases/index.json');
  final names = (jsonDecode(raw) as List).cast<String>()
    ..remove('index.json');
  final cases = <PuzzleCase>[];
  for (final name in names.take(4)) {
    final j = jsonDecode(await rootBundle.loadString('assets/cases/$name'))
        as Map<String, dynamic>;
    cases.add(PuzzleCase.fromJson(j));
  }
  return cases;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin red en tests: google_fonts usa la fuente de fallback.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('el camino de casos construye y pinta', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cases = await tester.runAsync(_loadRealCases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases!),
        ],
        child: const MaterialApp(home: CaseListScreen()),
      ),
    );
    // La burbuja EMPEZAR anima en bucle: pumps fijos, no pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ENIGMATRIX'), findsOneWidget);
    expect(find.text('EMPEZAR'), findsOneWidget); // nodo actual
    expect(find.textContaining('SECCIÓN'), findsWidgets);
  });

  testWidgets('tocar un nodo abre la ficha del caso con botón Jugar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cases = await tester.runAsync(_loadRealCases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases!),
        ],
        child: const MaterialApp(home: CaseListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // El primer nodo es el actual (icono lupa).
    await tester.tap(find.byIcon(Icons.search_rounded).first,
        warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.textContaining('sospechosos'), findsOneWidget);
  });

  testWidgets('nodo resuelto muestra check y datos de la partida',
      (tester) async {
    final cases = await tester.runAsync(_loadRealCases);
    SharedPreferences.setMockInitialValues({
      'done:${cases!.first.caseId}':
          jsonEncode({'time': 95, 'errors': 1, 'date': '2026-07-11T10:00'}),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases),
        ],
        child: const MaterialApp(home: CaseListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('la app completa arranca con el camino como pantalla inicial',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cases = await tester.runAsync(_loadRealCases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases!),
        ],
        child: const EnigmatrixApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ENIGMATRIX'), findsOneWidget);
  });
}
