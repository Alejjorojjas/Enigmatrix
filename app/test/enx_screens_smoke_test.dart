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
    SharedPreferences.setMockInitialValues({'tutorial:seen': true});
    final cases = await tester.runAsync(_loadRealCases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases!),
        ],
        child: const MaterialApp(home: CaseListScreen()),
      ),
    );
    // La etiqueta SIGUIENTE CASO anima en bucle: pumps fijos, no
    // pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Enigmatrix'), findsOneWidget);
    expect(find.text('SIGUIENTE CASO'), findsOneWidget); // ficha actual
    expect(find.textContaining('EXPEDIENTE'), findsWidgets);
  });

  testWidgets('tocar un nodo abre la ficha del caso con botón Jugar',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial:seen': true});
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

    // La primera ficha es la actual (icono lupa; la barra superior usa
    // otro tamaño del mismo icono, por eso .last = la ficha).
    await tester.tap(find.byIcon(Icons.search_rounded).last,
        warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('INVESTIGAR'), findsOneWidget);
    expect(find.textContaining('sospechosos'), findsOneWidget);
  });

  testWidgets('nodo resuelto muestra check y datos de la partida',
      (tester) async {
    final cases = await tester.runAsync(_loadRealCases);
    SharedPreferences.setMockInitialValues({
      'tutorial:seen': true,
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
    // Aparece en la barra superior y en la carpeta de la sección.
    expect(find.text('1 / 4'), findsWidgets);
  });

  testWidgets('primer arranque: el tutorial aparece automáticamente',
      (tester) async {
    // Sin 'tutorial:seen' (instalación nueva o reinstalación).
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
    await tester.pump(const Duration(milliseconds: 2000));
    // El diálogo llega tras varios awaits (prefs + postFrame + showDialog).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('CÓMO JUGAR'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
  });

  testWidgets('la app completa arranca en el Inicio del shell',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial:seen': true});
    final cases = await tester.runAsync(_loadRealCases);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => cases!),
        ],
        child: const EnigmatrixApp(),
      ),
    );
    // El router es global: si otro test ya navegó, este arranque puede no
    // pasar por el splash — solo se asierta el destino final.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 400));
    // Aterriza en el Inicio del shell (saludo + tarjeta del reto diario).
    expect(find.text('detective'), findsOneWidget);
    expect(find.textContaining('RETO DIARIO'), findsOneWidget);
  });
}
