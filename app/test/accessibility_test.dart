/// Accesibilidad básica (H-56, ronda 4.3a): semántica por casilla del tablero,
/// etiquetas en botones y retratos, texto del sistema a 1,3 sin desbordes en
/// las pantallas principales (360×740) y "Reducir movimiento" en Configuración.
/// También vigila que no queden colores sueltos (blanco) en la interfaz.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/dev_tools.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/ui/bank_screen.dart';
import 'package:enigmatrix/src/ui/board_semantics.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/game_chrome.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix/src/ui/layout_metrics.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:enigmatrix/src/ui/splash_screen.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/game_ui.dart';

late PuzzleCase _pc;
late List<PuzzleCase> _world;

String _two(int n) => n.toString().padLeft(2, '0');

/// Nodos de semántica que se pueden tocar pero no dicen qué son.
List<String> _unlabeledTappables(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final tappable = data.hasAction(SemanticsAction.tap);
    final hidden = data.flagsCollection.isHidden;
    // El interruptor de una fila con título ("Sonido") lo lee la fila.
    final toggleOfLabeledRow =
        data.flagsCollection.isToggled != ui.Tristate.none &&
        (node.parent?.label.trim().isNotEmpty ?? false);
    if (tappable &&
        !hidden &&
        !toggleOfLabeledRow &&
        data.label.trim().isEmpty &&
        data.tooltip.trim().isEmpty &&
        data.value.trim().isEmpty) {
      final up = <String>[];
      for (var n = node.parent; n != null && up.length < 3; n = n.parent) {
        up.add('[${n.label}]');
      }
      out.add('${node.rect} dentro de ${up.join(' > ')}');
    }
    node.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Navigator).first));
  return out;
}

Future<GoRouter> _pumpShell(
  WidgetTester tester,
  Widget home, {
  String skin = 'ilustrada',
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(360, 740),
  double textScale = 1.0,
  bool devTools = true,
}) async {
  SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/casos', builder: (_, _) => const CaseListScreen()),
      GoRoute(path: '/banco', builder: (_, _) => const BankScreen()),
      GoRoute(path: '/tutorial', builder: (_, _) => const Text('TUTORIAL')),
      GoRoute(path: '/play/:id', builder: (_, _) => const Text('PARTIDA')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...contentOverrides(_world, challenges: loadAllChallenges()),
        devToolsProvider.overrideWithValue(devTools),
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
  await _settle(tester);
  return router;
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

Future<void> _tapScrolled(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
  await _settle(tester);
}

Finder _cellLabel(int row, int col) =>
    find.bySemanticsLabel(RegExp('^Fila $row, columna $col,'));

FinderBase<SemanticsNode> _cellNode(int row, int col) =>
    find.semantics.byLabel(RegExp('^Fila $row, columna $col,'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _pc = loadBankCase('caso-principiante-s1');
    _world = [for (var i = 1; i <= 10; i++) loadBankCase('mansion-${_two(i)}')];
  });

  group('descripción hablada de cada casilla', () {
    test('dice fila, columna, habitación, mueble cercano, candidatos y '
        'confirmado', () {
      final map = _pc.map;
      // Una casilla libre con un mueble pegado.
      final cell = [
        for (var i = 0; i < map.size * map.size; i++)
          if (map.isOccupiable(i) &&
              map.objectAt(i) == null &&
              map.orthNeighbors(i).any((n) => map.objectAt(n) != null))
            i,
      ].first;
      final label = cellSemanticsLabel(_pc, BoardState.empty(), cell);
      expect(
        label,
        startsWith(
          'Fila ${map.row(cell) + 1}, columna ${map.col(cell) + 1}, '
          '${map.area(map.areaIdOf(cell)).nameEs}, junto a ',
        ),
      );
      expect(label, endsWith('candidatos: ninguno, confirmado: ninguno'));
    });

    test('lista los candidatos y el confirmado por su nombre', () {
      final map = _pc.map;
      final free = [
        for (var i = 0; i < map.size * map.size; i++)
          if (map.isOccupiable(i)) i,
      ];
      final a = _pc.characters[0], b = _pc.characters[1];
      var board = BoardState.empty()
          .placeCandidate(free[0], b.id)
          .board
          .placeCandidate(free[0], a.id)
          .board;
      // Siempre en el orden de los personajes del caso.
      expect(
        cellSemanticsLabel(_pc, board, free[0]),
        contains('candidatos: ${a.nameEs}, ${b.nameEs}, confirmado: ninguno'),
      );
      board = board.placeConfirmed(free[0], a.id).board;
      expect(
        cellSemanticsLabel(_pc, board, free[0]),
        contains('confirmado: ${a.nameEs}'),
      );
      board = BoardState.empty().placeX(free[1], XLevel.small).board;
      expect(cellSemanticsLabel(_pc, board, free[1]), contains('tachada'));
    });

    test(
      'una casilla con mueble que bloquea lo dice y no admite candidatos',
      () {
        final map = _pc.map;
        final blocked = [
          for (var i = 0; i < map.size * map.size; i++)
            if (!map.isOccupiable(i)) i,
        ];
        if (blocked.isEmpty) return;
        final label = cellSemanticsLabel(
          _pc,
          BoardState.empty(),
          blocked.first,
        );
        expect(label, contains('no se puede usar'));
        expect(label, isNot(contains('candidatos')));
      },
    );

    test('no revela la solución: es igual con el tablero vacío', () {
      final map = _pc.map;
      for (var i = 0; i < map.size * map.size; i++) {
        final label = cellSemanticsLabel(_pc, BoardState.empty(), i);
        for (final c in _pc.characters) {
          expect(label, isNot(contains(c.nameEs)), reason: 'casilla $i');
        }
      }
    });
  });

  group('capa de semántica del tablero en la partida', () {
    testWidgets('hay un nodo por casilla y tocarlo coloca igual que el dedo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        final rig = await pumpGameScreen(tester, _pc);
        final n = _pc.map.size;
        expect(
          find.bySemanticsLabel(RegExp(r'^Fila \d+, columna \d+,')),
          findsNWidgets(n * n),
        );
        expect(
          find.bySemanticsLabel(BoardSemanticsTexts.board(n)),
          findsOneWidget,
        );

        // Elige un sospechoso y "toca" una casilla libre con el lector.
        final free = firstFreeCell(_pc);
        final row = _pc.map.row(free) + 1, col = _pc.map.col(free) + 1;
        final who = _pc.characters.first;
        await pickSuspect(tester, who.id);
        expect(_cellLabel(row, col), findsOneWidget);
        tester.semantics.tap(_cellNode(row, col));
        await settle(tester, 6);
        final board = rig.container.read(gameControllerProvider(_pc)).board;
        expect(board.cell(free).candidates, contains(who.id));
        // La descripción se actualiza sola.
        expect(
          find.bySemanticsLabel(
            RegExp('^Fila $row, columna $col,.*candidatos: ${who.nameEs}'),
          ),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('mantener oprimido desde el lector confirma', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final rig = await pumpGameScreen(tester, _pc);
        final free = firstFreeCell(_pc);
        final row = _pc.map.row(free) + 1, col = _pc.map.col(free) + 1;
        final who = _pc.characters.first;
        await pickSuspect(tester, who.id);
        tester.semantics.longPress(_cellNode(row, col));
        await settle(tester, 6);
        final board = rig.container.read(gameControllerProvider(_pc)).board;
        expect(board.cell(free).confirmed, who.id);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('la capa no tapa los toques del tablero', (tester) async {
      final rig = await pumpGameScreen(tester, _pc);
      final free = firstFreeCell(_pc);
      final who = _pc.characters.first;
      await pickSuspect(tester, who.id);
      await tapCell(tester, free);
      final board = rig.container.read(gameControllerProvider(_pc)).board;
      expect(board.cell(free).candidates, contains(who.id));
    });

    testWidgets('retratos y botones de la partida tienen etiqueta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpGameScreen(tester, _pc);
        for (final c in _pc.characters) {
          expect(
            find.bySemanticsLabel(RegExp('^${c.nameEs}')),
            findsWidgets,
            reason: 'retrato de ${c.nameEs}',
          );
        }
        expect(_unlabeledTappables(tester), isEmpty);
      } finally {
        handle.dispose();
      }
    });
  });

  group('todo lo que se toca dice qué es', () {
    for (final skin in ['ilustrada', 'papel']) {
      testWidgets('Inicio y pestañas · $skin', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await _pumpShell(tester, const HomeShell(), skin: skin);
          for (final tab in ['Inicio', 'Mundos', 'Reto', 'Ranking', 'Perfil']) {
            await _tab(tester, tab);
            expect(_unlabeledTappables(tester), isEmpty, reason: tab);
          }
        } finally {
          handle.dispose();
        }
      });

      testWidgets('lista de casos y Configuración · $skin', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await _pumpShell(tester, const CaseListScreen(), skin: skin);
          expect(_unlabeledTappables(tester), isEmpty);
          await _pumpShell(tester, const HomeShell(), skin: skin);
          await _tab(tester, 'Perfil');
          await _tapScrolled(tester, find.text('Configuración'));
          expect(_unlabeledTappables(tester), isEmpty);
        } finally {
          handle.dispose();
        }
      });
    }
  });

  group('texto del sistema a 1,3 sin desbordes (360×740)', () {
    const skins = ['ilustrada', 'papel'];
    const modes = [ThemeMode.light, ThemeMode.dark];

    for (final skin in skins) {
      for (final mode in modes) {
        final tag = '$skin · ${mode.name}';

        testWidgets('pantalla de carga · $tag', (tester) async {
          await _pumpShell(
            tester,
            const SplashScreen(),
            skin: skin,
            mode: mode,
            textScale: 1.3,
          );
          expect(find.text('Enigmatrix'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 3));
          await tester.pump(const Duration(milliseconds: 500));
        });

        testWidgets('Inicio, Mundos, Reto, Ranking y Perfil · $tag', (
          tester,
        ) async {
          await _pumpShell(
            tester,
            const HomeShell(),
            skin: skin,
            mode: mode,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull, reason: 'Inicio');
          for (final tab in ['Mundos', 'Reto', 'Ranking', 'Perfil']) {
            await _tab(tester, tab);
            expect(tester.takeException(), isNull, reason: tab);
          }
        });

        testWidgets('lista de casos, ficha y Configuración · $tag', (
          tester,
        ) async {
          await _pumpShell(
            tester,
            const CaseListScreen(),
            skin: skin,
            mode: mode,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull, reason: 'lista');
          await tester.tap(find.byIcon(Icons.search_rounded).last);
          await _settle(tester);
          expect(find.text('INVESTIGAR'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'ficha');

          await _pumpShell(
            tester,
            const HomeShell(),
            skin: skin,
            mode: mode,
            textScale: 1.3,
          );
          await _tab(tester, 'Perfil');
          await _tapScrolled(tester, find.text('Configuración'));
          expect(find.text('Reducir movimiento'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'Configuración');
          await _tapScrolled(tester, find.text('ABRIR BANCO DE PRUEBAS'));
          expect(tester.takeException(), isNull, reason: 'banco de pruebas');
        });

        for (final size in const [Size(360, 740), Size(360, 640)]) {
          testWidgets('partida a ${size.height.toInt()} · $tag', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = 1.3;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpGameScreen(
              tester,
              _pc,
              size: size,
              settings: AppSettings(skinId: skin, themeMode: mode),
              platformBrightness: mode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light,
            );
            expect(tester.takeException(), isNull, reason: 'partida');
            // La pista más larga también cabe.
            final longest = _pc.characters.reduce((a, b) {
              int len(Character c) =>
                  _pc.clueFor(c.id)?.cardTextEs(_pc.map, _pc.names).length ?? 0;
              return len(a) >= len(b) ? a : b;
            });
            await pickSuspect(tester, longest.id);
            expect(tester.takeException(), isNull, reason: 'partida con pista');
          });
        }

        testWidgets('tutorial · $tag', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpGameScreen(
            tester,
            _pc,
            tutorial: true,
            settings: AppSettings(skinId: skin, themeMode: mode),
            platformBrightness: mode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
          );
          expect(tester.takeException(), isNull, reason: 'tutorial');
        });
      }
    }
  });

  group('Reducir movimiento', () {
    test('se guarda en el teléfono y se lee al arrancar', () async {
      SharedPreferences.setMockInitialValues({});
      expect(AppSettings.defaults.reduceMotion, isFalse);
      final c = ProviderContainer(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            const AppSettings(skinId: 'papel'),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.read(settingsProvider.notifier).setReduceMotion(true);
      expect(c.read(settingsProvider).reduceMotion, isTrue);
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppSettings.reduceMotionKey), isTrue);
      expect(AppSettings.fromPrefs(prefs).reduceMotion, isTrue);
    });

    test('el sistema o el jugador lo piden: la escena lo recibe', () {
      const on = AppSettings(reduceMotion: true);
      expect(
        on.effective(systemReduceMotion: false).reduceMotion,
        isTrue,
        reason: 'lo pidió el jugador',
      );
      expect(
        AppSettings.defaults.effective(systemReduceMotion: true).reduceMotion,
        isTrue,
        reason: 'lo pidió el teléfono',
      );
      expect(
        AppSettings.defaults.effective(systemReduceMotion: false).reduceMotion,
        isFalse,
      );
    });

    testWidgets('aparece en Configuración y se puede activar', (tester) async {
      await _pumpShell(tester, const HomeShell());
      await _tab(tester, 'Perfil');
      await _tapScrolled(tester, find.text('Configuración'));
      expect(find.text('Reducir movimiento'), findsOneWidget);
      final sw = find.widgetWithText(SwitchListTile, 'Reducir movimiento');
      expect(tester.widget<SwitchListTile>(sw).value, isFalse);
      await tester.tap(sw);
      await _settle(tester);
      expect(tester.widget<SwitchListTile>(sw).value, isTrue);
    });

    testWidgets('se aplica al tablero y al director de feedback', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, _pc);
      expect(gameOf(tester).settings.reduceMotion, isFalse);
      rig.container.read(settingsProvider.notifier).setReduceMotion(true);
      await settle(tester, 4);
      expect(gameOf(tester).settings.reduceMotion, isTrue);
      rig.container.read(settingsProvider.notifier).setReduceMotion(false);
      await settle(tester, 4);
      expect(gameOf(tester).settings.reduceMotion, isFalse);
    });

    testWidgets('si ya estaba activado al abrir la partida, arranca reducido', (
      tester,
    ) async {
      await pumpGameScreen(
        tester,
        _pc,
        settings: const AppSettings(reduceMotion: true),
      );
      expect(gameOf(tester).settings.reduceMotion, isTrue);
    });
  });

  group('medidas de la partida con texto agrandado', () {
    test('a escala 1 son las de siempre', () {
      final m = ScreenMetrics.of(const Size(360, 740));
      expect(m.titleRowHeight, ScreenMetrics.headerRow2Normal);
      expect(m.portraitRowHeight, ScreenMetrics.portraitRow);
      expect(m.boardSide, 336);
    });

    test('a 1,3 el título, los retratos y la pista crecen y el tablero cede '
        'ese alto', () {
      const big = TextScaler.linear(1.3);
      final m1 = ScreenMetrics.of(const Size(360, 640));
      final m13 = ScreenMetrics.of(const Size(360, 640), textScaler: big);
      expect(m13.titleRowHeight, greaterThan(m1.titleRowHeight));
      expect(m13.portraitRowHeight, greaterThan(m1.portraitRowHeight));
      expect(m13.hintMaxHeight, greaterThan(m1.hintMaxHeight));
      expect(m13.boardSide, lessThan(m1.boardSide));
      expect(m13.boardSide, greaterThan(250));
    });

    test('la pantalla de partida no pasa de 1,3', () {
      expect(kGameMaxTextScale, 1.3);
    });
  });

  group('colores sueltos', () {
    test('la interfaz no usa Colors.white ni Colors.black', () {
      final bad = <String>[];
      for (final f in Directory('lib/src/ui').listSync().whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        if (RegExp(r'Colors\.(white|black)\b').hasMatch(text)) {
          bad.add(f.path);
        }
      }
      expect(bad, isEmpty, reason: 'colores sueltos: $bad');
    });
  });
}
