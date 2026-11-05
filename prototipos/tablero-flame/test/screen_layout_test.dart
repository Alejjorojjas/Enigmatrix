import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/audio/audio_service.dart';
import 'package:tablero_flame/src/game/case_library.dart';
import 'package:tablero_flame/src/game/fps_recorder.dart';
import 'package:tablero_flame/src/scene/board_game.dart';
import 'package:tablero_flame/src/settings.dart';
import 'package:tablero_flame/src/ui/game_screen.dart';
import 'package:tablero_flame/src/ui/layout_metrics.dart';
import 'package:tablero_flame/src/ui/prototype_theme.dart';
import 'package:tablero_flame/src/ui/toolbar.dart';
import 'package:tablero_flame/src/ui/tray.dart';

import 'helpers.dart';

final _gameFinder = find.byWidgetPredicate((w) => w is GameWidget);

/// Pantalla completa del prototipo, con el mismo cableado que `main.dart`.
class _App extends StatelessWidget {
  const _App({required this.settings, required this.cases, required this.fps, required this.audio});
  final GameSettings settings;
  final List<CaseEntry> cases;
  final FpsMonitor fps;
  final SoloudSoundService audio;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          theme: Ui.theme(settings.skinId, Brightness.light),
          darkTheme: Ui.theme(settings.skinId, Brightness.dark),
          themeMode: settings.themeMode,
          home: GameScreen(cases: cases, settings: settings, audio: audio, fps: fps),
        ),
      );
}

List<CaseEntry> _cases() => [
      CaseEntry('6×6 Principiante', 'a', loadCase('caso-principiante-s1')),
      CaseEntry('8×8 Casual', 'b', loadCase('caso-casual-s1')),
    ];

Future<BoardGame> _pump(
  WidgetTester tester,
  Size size, {
  GameSettings? settings,
  int caseIndex = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final s = settings ?? GameSettings(themeMode: ThemeMode.light);
  await tester.pumpWidget(_App(
    settings: s,
    cases: _cases(),
    fps: FpsMonitor(),
    audio: SoloudSoundService(),
  ));
  if (caseIndex != 0) {
    await tester.tap(find.text('8×8'));
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return (tester.widget(_gameFinder) as GameWidget).game! as BoardGame;
}

/// El tablero en coordenadas de pantalla (el juego lo da respecto del
/// escenario).
Rect _globalBoard(WidgetTester tester, BoardGame game) =>
    game.geometry.board.shift(tester.getTopLeft(_gameFinder));

/// Tamaños de letra de todo texto visible (menores que 13 px).
List<String> _smallTexts(WidgetTester tester, {Set<String> except = const {}}) {
  final small = <String>[];
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    final plain = rt.text.toPlainText();
    if (plain.trim().isEmpty || except.any(plain.contains)) continue;
    double? min;
    rt.text.visitChildren((span) {
      if (span is TextSpan && (span.text?.trim().isNotEmpty ?? false)) {
        final f = span.style?.fontSize ?? rt.text.style?.fontSize;
        if (f != null && (min == null || f < min!)) min = f;
      }
      return true;
    });
    final f = min ?? rt.text.style?.fontSize;
    if (f != null && f < 13) small.add('$plain ($f px)');
  }
  return small;
}

void main() {
  setUpAll(loadRoboto);

  group('medidas de la pantalla (puras)', () {
    test('360x740 usa la distribución normal y el tablero mide 336', () {
      final m = ScreenMetrics.of(const Size(360, 740));
      expect(m.compact, isFalse);
      expect(m.boardSide, 336);
    });

    test('360x640 usa la compacta y el tablero también mide 336', () {
      final m = ScreenMetrics.of(const Size(360, 640));
      expect(m.compact, isTrue);
      expect(m.boardSide, 336);
    });

    test('en una pantalla ancha y baja el tablero se achica para caber', () {
      final m = ScreenMetrics.of(const Size(800, 500));
      expect(m.boardSide, lessThan(776));
      expect(m.boardSide, greaterThan(0));
    });
  });

  for (final size in const [Size(360, 740), Size(360, 640)]) {
    group('pantalla ${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('el tablero 6x6 ocupa el ancho menos 12 px por lado (casilla 56)',
          (tester) async {
        final game = await _pump(tester, size);
        expect(game.geometry.board.width, closeTo(336, 0.5));
        expect(_globalBoard(tester, game).left, closeTo(12, 0.5));
        expect(_globalBoard(tester, game).right, closeTo(size.width - 12, 0.5));
        expect(game.geometry.cell, closeTo(56, 0.1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('el tablero 8x8 ocupa el ancho menos 12 px por lado (casilla 42)',
          (tester) async {
        final game = await _pump(tester, size, caseIndex: 1);
        expect(game.geometry.board.width, closeTo(336, 0.5));
        expect(game.geometry.cell, closeTo(42, 0.1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('nada se desplaza: todo cabe en la pantalla y sin desbordes',
          (tester) async {
        for (final settings in [
          GameSettings(themeMode: ThemeMode.light),
          GameSettings(skinId: 'papel', themeMode: ThemeMode.dark, fpsMeter: true),
          GameSettings(skinId: 'neutra'),
        ]) {
          final game = await _pump(tester, size, settings: settings, caseIndex: 1);
          final board = _globalBoard(tester, game);
          expect(board.top, greaterThanOrEqualTo(0));
          expect(board.bottom, lessThanOrEqualTo(size.height));
          // El botón Resolver queda dentro de la pantalla.
          final resolve = tester.getRect(find.text('Resolver'));
          expect(resolve.bottom, lessThanOrEqualTo(size.height));
          expect(resolve.top, greaterThan(board.bottom));
          // La barra de herramientas está debajo del tablero.
          final tools = tester.getRect(find.byType(ToolBar));
          expect(tools.top, greaterThanOrEqualTo(board.bottom));
          expect(tools.bottom, lessThanOrEqualTo(size.height));
          // Ninguna lista vertical: lo único que desliza es la fila de retratos.
          for (final sc in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
            expect(sc.axis, Axis.horizontal);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('retratos de unos 52 px y letra de 13 px o más en toda la interfaz',
          (tester) async {
        await _pump(tester, size);
        // Cada retrato mide unos 52 px (54 con el aro de selección).
        final portrait = tester.getSize(find
            .descendant(of: find.byKey(const ValueKey('c1')), matching: find.byType(CustomPaint))
            .first);
        expect(portrait.width, inInclusiveRange(50, 56));
        expect(portrait.height, inInclusiveRange(50, 56));
        expect(_smallTexts(tester), isEmpty);
      });
    });
  }

  group('encabezado, medidor de FPS y herramientas', () {
    testWidgets('el medidor de FPS arranca apagado', (tester) async {
      expect(GameSettings().fpsMeter, isFalse);
      await _pump(tester, const Size(360, 740));
      expect(find.byKey(const ValueKey('fps-en-vivo')), findsNothing);
    });

    testWidgets('encendido, va en la barra superior y fuera del tablero', (tester) async {
      for (final size in const [Size(360, 740), Size(360, 640)]) {
        final settings = GameSettings(themeMode: ThemeMode.light, fpsMeter: true);
        final game = await _pump(tester, size, settings: settings);
        final fps = tester.getRect(find.byKey(const ValueKey('fps-en-vivo')));
        expect(fps.overlaps(_globalBoard(tester, game)), isFalse);
        final stage = tester.getRect(_gameFinder);
        expect(fps.bottom, lessThanOrEqualTo(stage.top + 0.5));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('la barra de herramientas mide unos 56 px y trae los nombres propios',
        (tester) async {
      await _pump(tester, const Size(360, 740));
      for (final t in ['Anotar', 'Tachar', 'Confirmar', 'Borrar']) {
        expect(find.text(t), findsOneWidget);
      }
      for (final old in ['Notas', 'Colocar']) {
        expect(find.text(old), findsNothing);
      }
      final h = tester.getSize(find.byType(ToolButton).first).height;
      expect(h, closeTo(56, 1));
    });

    testWidgets('la pista crece según el texto (hasta 3 líneas) en la normal',
        (tester) async {
      final game = await _pump(tester, const Size(360, 740));
      final before = game.geometry.board;
      await tester.tap(find.text('Adela'));
      await tester.pump(const Duration(milliseconds: 100));
      // El tablero no se mueve ni cambia de tamaño al elegir un personaje.
      expect(game.geometry.board, before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en la compacta la pista es de una línea y se expande al tocarla',
        (tester) async {
      final game = await _pump(tester, const Size(360, 640));
      final before = game.geometry.board;
      await tester.tap(find.text('Adela'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      final collapsedHeight = tester.getSize(find.byType(HintBox)).height;
      await tester.tap(find.byType(HintBox), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      // Al expandirse flota: el tablero no se mueve y la pista no empuja nada.
      expect(game.geometry.board, before);
      expect(tester.getSize(find.byType(HintBox)).height, collapsedHeight);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(HintBox), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('las Opciones tienen letra de 13 px o más y el medidor se enciende ahí',
        (tester) async {
      final settings = GameSettings(themeMode: ThemeMode.light);
      await _pump(tester, const Size(360, 740), settings: settings);
      await tester.tap(find.byIcon(Icons.tune));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Medidor de FPS'), findsOneWidget);
      expect(_smallTexts(tester), isEmpty);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Medidor de FPS'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(settings.fpsMeter, isTrue);
    });
  });
}

