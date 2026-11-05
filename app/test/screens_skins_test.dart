/// Todas las pantallas con las dos pieles y los dos modos (ronda 4.2, H-59):
/// cada pantalla principal se monta a 360x740 y a 360x640 sin desbordes, sin
/// letra menor de 13 px y con texto legible en claro y en oscuro. Además:
/// Experto y Élite "Próximamente" (ADR-0014), título de la historia, aviso
/// de los mundos que no existen y ningún `Color(0x...)` suelto en `ui/`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/game_chrome.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:enigmatrix/src/ui/splash_screen.dart';
import 'package:enigmatrix/src/ui/ui_kit.dart';
import 'package:enigmatrix/src/ui/v1_scope.dart';
import 'package:enigmatrix/src/ui/victory_screen.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/game_ui.dart' show loadBankCase;
import 'support/content_overrides.dart';

const _skins = ['ilustrada', 'papel'];
const _modes = [ThemeMode.light, ThemeMode.dark];
const _sizes = [Size(360, 740), Size(360, 640)];

/// Razón de contraste WCAG entre dos colores.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Tamaños de letra de todo texto visible que bajan de [minSize] px.
List<String> _smallTexts(WidgetTester tester, {double minSize = 13}) {
  final small = <String>[];
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    final plain = rt.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    double? min;
    rt.text.visitChildren((span) {
      if (span is TextSpan && (span.text?.trim().isNotEmpty ?? false)) {
        final f = span.style?.fontSize ?? rt.text.style?.fontSize;
        if (f != null && (min == null || f < min!)) min = f;
      }
      return true;
    });
    final f = min ?? rt.text.style?.fontSize;
    if (f != null && f < minSize) small.add('$plain ($f px)');
  }
  return small;
}

late List<PuzzleCase> _bank;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required String skin,
  required ThemeMode mode,
  required Size size,
  List<PuzzleCase>? cases,
}) async {
  final list = cases ?? _bank;
  SharedPreferences.setMockInitialValues({
    'tutorial:v2:done': true,
    // El primero cerrado y el tercero en curso: se ven los tres estados.
    'done:${list.first.caseId}': jsonEncode({
      'time': 95,
      'errors': 1,
      'date': '2026-11-05T10:00',
    }),
    'game:${list[2].caseId}': SavedGame(
      elapsed: 125,
      errors: 1,
      savedAt: DateTime.utc(2026, 11, 5, 9),
      board: BoardState.empty(),
      clueMarks: List.filled(list[2].clues.length, 0),
      autoX: true,
      mapMode: true,
    ).encode(),
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/home', builder: (_, _) => const Text('INICIO')),
      GoRoute(path: '/casos', builder: (_, _) => const Text('CASOS')),
      GoRoute(path: '/tutorial', builder: (_, _) => const Text('TUTORIAL')),
      GoRoute(path: '/play/:id', builder: (_, _) => const Text('PARTIDA')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...contentOverrides(list),
        initialSettingsProvider.overrideWithValue(
          AppSettings(skinId: skin, themeMode: mode),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        themeMode: mode,
        theme: SkinUi.theme(skin, Brightness.light),
        darkTheme: SkinUi.theme(skin, Brightness.dark),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChromeButton, label));
  await _settle(tester);
}

/// Toca algo del Perfil que puede quedar más abajo en pantallas bajas.
Future<void> _tapScrolled(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
  await _settle(tester);
}

typedef _Run =
    Future<void> Function(
      WidgetTester tester,
      String skin,
      ThemeMode mode,
      Size size,
    );

class _Scenario {
  const _Scenario(this.name, this.run);
  final String name;
  final _Run run;
}

Future<void> _shell(WidgetTester t, String skin, ThemeMode mode, Size size) =>
    _pump(t, const HomeShell(), skin: skin, mode: mode, size: size);

final _scenarios = <_Scenario>[
  _Scenario('pantalla de carga', (t, skin, mode, size) async {
    await _pump(t, const SplashScreen(), skin: skin, mode: mode, size: size);
    expect(find.text('Enigmatrix'), findsOneWidget);
    // El splash pasa solo al inicio tras unos segundos.
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('INICIO'), findsOneWidget);
  }),
  _Scenario('Inicio', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    expect(find.textContaining('RETO DIARIO'), findsOneWidget);
  }),
  _Scenario('Mundos', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Mundos');
    expect(find.text('La Mansión'), findsOneWidget);
  }),
  _Scenario('Reto', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Reto');
    expect(find.text('Reto diario'), findsOneWidget);
  }),
  _Scenario('Ranking', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Ranking');
    expect(find.text('Tú (detective)'), findsOneWidget);
  }),
  _Scenario('Perfil', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Perfil');
    expect(find.text('Configuración'), findsOneWidget);
  }),
  _Scenario('Configuración', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Perfil');
    await _tapScrolled(t, find.text('Configuración'));
    expect(find.text('Aspecto del juego'), findsOneWidget);
    expect(find.text('Sonido'), findsOneWidget);
  }),
  _Scenario('Tienda', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Perfil');
    await _tapScrolled(t, find.text('Tienda'));
    // Un toque en comprar muestra el aviso de función simulada dentro.
    await t.tap(find.widgetWithText(ChromeButton, r'$0.99').first);
    await _settle(t);
    expect(find.text(UiTexts.demoNotice), findsOneWidget);
  }),
  _Scenario('Premium', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Perfil');
    await _tapScrolled(t, find.text('Premium'));
    await t.tap(find.widgetWithText(ChromeButton, r'MENSUAL · $4.99'));
    await _settle(t);
    expect(find.text(UiTexts.demoNotice), findsOneWidget);
  }),
  _Scenario('diálogo del tutorial', (t, skin, mode, size) async {
    await _shell(t, skin, mode, size);
    await _tab(t, 'Perfil');
    await _tapScrolled(t, find.text('Cómo jugar'));
    expect(find.text('CÓMO JUGAR'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
    // La última página (con el texto más largo) también cabe.
    for (var i = 0; i < 4; i++) {
      await t.tap(find.widgetWithText(ChromeButton, 'SIGUIENTE'));
      await _settle(t);
    }
    expect(find.text('Resolver el caso'), findsOneWidget);
  }),
  _Scenario('lista de casos', (t, skin, mode, size) async {
    await _pump(t, const CaseListScreen(), skin: skin, mode: mode, size: size);
    expect(find.textContaining('EXPEDIENTE'), findsWidgets);
    expect(find.textContaining('En curso'), findsWidgets);
  }),
  _Scenario('ficha del caso', (t, skin, mode, size) async {
    await _pump(t, const CaseListScreen(), skin: skin, mode: mode, size: size);
    await t.tap(find.byIcon(Icons.check_rounded).first);
    await _settle(t);
    expect(find.text('REABRIR CASO'), findsOneWidget);
  }),
  _Scenario('victoria y Caso cerrado', (t, skin, mode, size) async {
    final pc = _bank.first;
    await _pump(
      t,
      Consumer(
        builder: (ctx, ref, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showVictoryScreen(ctx, ref, pc),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
      skin: skin,
      mode: mode,
      size: size,
    );
    await t.tap(find.text('ABRIR'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 900));
    expect(find.text('CASO CERRADO'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsOneWidget);
  }),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    _bank = [
      for (final n in [
        'caso-principiante-s1',
        'caso-principiante-s2',
        'caso-principiante-s3',
        'caso-casual-s1',
        'caso-intermedio-s1',
      ])
        loadBankCase(n),
    ];
  });

  for (final s in _scenarios) {
    for (final skin in _skins) {
      for (final mode in _modes) {
        for (final size in _sizes) {
          testWidgets('${s.name} · $skin · ${mode.name} · '
              '${size.width.toInt()}x${size.height.toInt()}: sin desbordes y '
              'con letra de 13 px o más', (tester) async {
            await s.run(tester, skin, mode, size);
            expect(tester.takeException(), isNull);
            expect(_smallTexts(tester), isEmpty);
          });
        }
      }
    }
  }

  group('legibilidad de las paletas en claro y oscuro', () {
    for (final skin in _skins) {
      for (final b in Brightness.values) {
        test('$skin · ${b.name}: contraste de texto y botones', () {
          final p = SkinUi.theme(skin, b).extension<SkinTheme>()!.palette;
          expect(_contrast(p.text, p.bg), greaterThanOrEqualTo(7));
          expect(_contrast(p.text, p.surface), greaterThanOrEqualTo(7));
          expect(_contrast(p.text, p.surfaceAlt), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.softText, p.bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.softText, p.surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.textDim, p.surface), greaterThanOrEqualTo(3.5));
          // Botones con color de acento: AA (4,5:1) con su texto.
          expect(
            _contrast(p.onColor(p.accent), p.accent),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(p.onColor(p.danger), p.danger),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(p.onColor(p.good), p.good),
            greaterThanOrEqualTo(4.5),
          );
          expect(_contrast(p.onPill, p.pill), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.accent, p.surface), greaterThanOrEqualTo(3));
          expect(_contrast(p.danger, p.surface), greaterThanOrEqualTo(3));
          for (final c in [
            p.accent,
            p.danger,
            p.good,
            for (var i = 0; i < 5; i++) p.world(i),
          ]) {
            // El texto o ícono sobre cualquier color de la interfaz se lee.
            expect(_contrast(p.onColor(c), c), greaterThanOrEqualTo(3.5));
          }
        });
      }
    }
  });

  group('Experto, Élite y mundos que no existen (ADR-0014)', () {
    testWidgets('la lista muestra Experto y Élite "Próximamente" sin '
        'abrirse', (tester) async {
      await _pump(
        tester,
        const CaseListScreen(),
        skin: 'ilustrada',
        mode: ThemeMode.light,
        size: const Size(360, 740),
      );
      await tester.dragUntilVisible(
        find.text('Élite'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await _settle(tester);
      expect(find.text('Experto'), findsOneWidget);
      expect(find.text('Élite'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(2));
      // Tocarlas no abre nada.
      await tester.tap(find.text('Élite'), warnIfMissed: false);
      await _settle(tester);
      expect(find.text('INVESTIGAR'), findsNothing);
      expect(find.text('PARTIDA'), findsNothing);
    });

    testWidgets('la lista cuenta solo los casos de la V1', (tester) async {
      await _pump(
        tester,
        const CaseListScreen(),
        skin: 'papel',
        mode: ThemeMode.dark,
        size: const Size(360, 740),
      );
      // 1 de 5 cerrado (el primero).
      expect(find.text('1 / 5'), findsOneWidget);
    });

    test('solo Principiante, Casual e Intermedio se pueden abrir', () {
      expect(kV1Difficulties, ['principiante', 'casual', 'intermedio']);
      expect(isV1Difficulty('experto'), isFalse);
      expect(isV1Difficulty('elite'), isFalse);
      expect(
        playableCases(_bank).every((c) => isV1Difficulty(c.difficulty)),
        isTrue,
      );
    });

    testWidgets('Mundos: solo La Mansión se abre; los demás dicen '
        '"Próximamente"', (tester) async {
      await _shell(tester, 'papel', ThemeMode.light, const Size(360, 740));
      await _tab(tester, 'Mundos');
      expect(find.text('Próximamente'), findsNWidgets(4));
      await tester.tap(find.text('El Hotel'));
      await _settle(tester);
      expect(find.text('CASOS'), findsNothing);
      await tester.tap(find.text('La Mansión'));
      await _settle(tester);
      expect(find.text('CASOS'), findsOneWidget);
    });
  });

  group('título del caso', () {
    test('usa el de la historia si existe y si no el nombre del mapa', () {
      final pc = _bank.first;
      expect(caseTitle(pc), pc.map.nameEs);
      final withStory = pc.withStory(
        CaseStory(
          world: 'mansion',
          title: const {'es': 'La última cena'},
          premise: const {'es': 'Una cena que acaba mal.'},
        ),
      );
      expect(caseTitle(withStory), 'La última cena');
    });

    testWidgets('la ficha del caso muestra el título y la premisa de la '
        'historia', (tester) async {
      final story = CaseStory(
        world: 'mansion',
        title: const {'es': 'La última cena'},
        premise: const {'es': 'Una cena que acaba mal.'},
      );
      final cases = [_bank.first.withStory(story), ..._bank.skip(1)];
      await _pump(
        tester,
        const CaseListScreen(),
        skin: 'ilustrada',
        mode: ThemeMode.light,
        size: const Size(360, 740),
        cases: cases,
      );
      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await _settle(tester);
      expect(find.textContaining('La última cena'), findsOneWidget);
      expect(find.text('Una cena que acaba mal.'), findsOneWidget);
    });
  });

  group('un solo sistema de tema', () {
    test('no quedan Color(0x...) sueltos en lib/src/ui ni sistemas viejos', () {
      final ui = Directory('lib/src/ui');
      final loose = <String>[];
      for (final f in ui.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        if (RegExp(r'Color\(\s*0x').hasMatch(text)) loose.add(f.path);
      }
      expect(loose, isEmpty, reason: 'colores sueltos: $loose');
      expect(File('lib/src/ui/enx_style.dart').existsSync(), isFalse);
      final main = File('lib/main.dart').readAsStringSync();
      expect(main.contains('Brand'), isFalse);
      expect(RegExp(r'Color\(\s*0x').hasMatch(main), isFalse);
    });
  });
}
