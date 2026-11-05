/// Pantalla de partida con el tablero de Flame (ronda 4.1, ADR-0013):
/// distribución a 360x740 y 360x640, herramientas, piel y modo, sonido y
/// vibración, menú de acciones secundarias, rendimiento del reloj (H-58) y
/// el cierre con la secuencia de revelar. Con la letra real (Roboto).
library;

import 'package:enigmatrix/src/board/board_strings.dart';
import 'package:enigmatrix/src/board/feedback/feedback_plan.dart';
import 'package:enigmatrix/src/board/scene/board_game.dart';
import 'package:enigmatrix/src/board/scene/skins.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/feedback_providers.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/game_toolbar.dart';
import 'package:enigmatrix/src/ui/game_tray.dart';
import 'package:enigmatrix/src/ui/layout_metrics.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/game_ui.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRoboto);
  final small = loadBankCase('caso-principiante-s1'); // 6x6
  final big = loadBankCase('caso-casual-s1'); // 8x8
  final firstChar = small.characters.first.id;

  Rect boardOnScreen(WidgetTester tester) =>
      gameOf(tester).geometry.board.shift(tester.getTopLeft(gameFinder));

  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  for (final size in const [Size(360, 740), Size(360, 640)]) {
    group('pantalla ${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('el tablero 6x6 ocupa el ancho menos 12 px por lado '
          '(casilla de 56)', (tester) async {
        await pumpGameScreen(tester, small, size: size);
        final game = gameOf(tester);
        expect(game.geometry.board.width, closeTo(336, 0.5));
        expect(boardOnScreen(tester).left, closeTo(12, 0.5));
        expect(boardOnScreen(tester).right, closeTo(size.width - 12, 0.5));
        expect(game.geometry.cell, closeTo(56, 0.1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('el tablero 8x8 ocupa el ancho menos 12 px por lado '
          '(casilla de 42)', (tester) async {
        await pumpGameScreen(tester, big, size: size);
        final game = gameOf(tester);
        expect(game.geometry.board.width, closeTo(336, 0.5));
        expect(game.geometry.cell, closeTo(42, 0.1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('nada se desplaza ni se desborda, con las dos pieles en '
          'claro y oscuro', (tester) async {
        for (final skin in kPlayerSkins) {
          for (final mode in [ThemeMode.light, ThemeMode.dark]) {
            await pumpGameScreen(
              tester,
              big,
              size: size,
              settings: AppSettings(skinId: skin, themeMode: mode),
            );
            final board = boardOnScreen(tester);
            expect(board.top, greaterThanOrEqualTo(0));
            expect(board.bottom, lessThanOrEqualTo(size.height));
            // El botón Resolver queda dentro de la pantalla y bajo el tablero.
            final resolve = tester.getRect(
              find.byKey(const ValueKey('boton-resolver')),
            );
            expect(resolve.bottom, lessThanOrEqualTo(size.height));
            expect(resolve.top, greaterThan(board.bottom));
            // La barra de herramientas está debajo del tablero.
            final tools = tester.getRect(find.byType(ToolBar));
            expect(tools.top, greaterThanOrEqualTo(board.bottom));
            expect(tools.bottom, lessThanOrEqualTo(size.height));
            // Ninguna lista vertical: lo único que desliza es la fila de
            // retratos.
            for (final sc in tester.widgetList<Scrollable>(
              find.byType(Scrollable),
            )) {
              expect(sc.axis, Axis.horizontal);
            }
            expect(tester.takeException(), isNull, reason: '$skin $mode');
            await tester.pumpWidget(const SizedBox());
          }
        }
      });

      testWidgets('retratos de unos 50 px y letra de 13 px o más en toda la '
          'interfaz', (tester) async {
        await pumpGameScreen(tester, small, size: size);
        final chip = tester.getSize(find.byKey(const ValueKey('retrato-c1')));
        expect(chip.width, inInclusiveRange(50, 56));
        expect(_smallTexts(tester), isEmpty);
      });
    });
  }

  // ---------------------------------------------------------------------------
  group('distribución del prototipo', () {
    testWidgets('trae las cuatro herramientas con sus nombres', (tester) async {
      await pumpGameScreen(tester, small);
      for (final t in ['Anotar', 'Tachar', 'Confirmar', 'Borrar']) {
        expect(find.text(t), findsOneWidget);
      }
      final h = tester.getSize(find.byType(ToolButton).first).height;
      expect(h, closeTo(56, 1));
    });

    testWidgets('la pista crece con el texto en la distribución normal y '
        'no mueve el tablero', (tester) async {
      await pumpGameScreen(tester, small);
      final before = gameOf(tester).geometry.board;
      await pickSuspect(tester, firstChar);
      expect(gameOf(tester).geometry.board, before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en la compacta la pista es de una línea y se expande al '
        'tocarla sin empujar nada', (tester) async {
      await pumpGameScreen(tester, small, size: const Size(360, 640));
      final before = gameOf(tester).geometry.board;
      await pickSuspect(tester, firstChar);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      final collapsed = tester.getSize(find.byType(HintBox)).height;
      await tester.tap(find.byType(HintBox), warnIfMissed: false);
      await settle(tester, 2);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(gameOf(tester).geometry.board, before);
      expect(tester.getSize(find.byType(HintBox)).height, collapsed);
      await tester.tap(find.byType(HintBox), warnIfMissed: false);
      await settle(tester, 2);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('la víctima se rotula "Víctima" y el que ya se colocó lleva '
        'una marca', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      expect(find.text('Víctima'), findsOneWidget);
      final mark = find.descendant(
        of: find.byKey(ValueKey('retrato-$firstChar')),
        matching: find.byIcon(Icons.check),
      );
      expect(mark, findsNothing);
      rig.container
          .read(gameControllerProvider(small).notifier)
          .placeSuspect(0, charId: firstChar, confirm: true);
      await settle(tester, 2);
      expect(mark, findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  group('herramientas en la pantalla', () {
    testWidgets('Anotar: toque anota; mantener oprimido confirma', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      GameState s() => rig.container.read(gameControllerProvider(small));
      final cell = firstFreeCell(small);
      await pickSuspect(tester, firstChar);
      await tapCell(tester, cell);
      expect(s().board.cell(cell).candidates, {firstChar});

      await holdCell(tester, cell);
      expect(s().board.confirmedCellOf(firstChar), cell);
    });

    testWidgets('Confirmar: un toque fija al sospechoso', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      final cell = firstFreeCell(small);
      await pickSuspect(tester, firstChar);
      await pickTool(tester, ToolMode.place);
      await tapCell(tester, cell);
      expect(
        rig.container
            .read(gameControllerProvider(small))
            .board
            .confirmedCellOf(firstChar),
        cell,
      );
    });

    testWidgets('Tachar pone la X y otro toque la quita; Borrar limpia', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      GameState s() => rig.container.read(gameControllerProvider(small));
      final cell = firstFreeCell(small);
      await pickTool(tester, ToolMode.cross);
      await tapCell(tester, cell);
      expect(s().board.cell(cell).x, isNotNull);
      await tapCell(tester, cell);
      expect(s().board.cell(cell).x, isNull);

      await pickSuspect(tester, firstChar);
      await pickTool(tester, ToolMode.place);
      await tapCell(tester, cell);
      expect(s().board.confirmedCellOf(firstChar), cell);
      await pickTool(tester, ToolMode.erase);
      await tapCell(tester, cell);
      expect(s().board.cell(cell).isEmpty, isTrue);
    });

    testWidgets('elegir un retrato desde Borrar vuelve a Anotar', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      await pickTool(tester, ToolMode.erase);
      expect(
        rig.container.read(gameControllerProvider(small)).toolMode,
        ToolMode.erase,
      );
      await pickSuspect(tester, firstChar);
      final s = rig.container.read(gameControllerProvider(small));
      expect(s.toolMode, ToolMode.notes);
      expect(s.selectedChar, firstChar);
    });

    testWidgets('la herramienta activa se ve sin depender del color', (
      tester,
    ) async {
      await pumpGameScreen(tester, small);
      final handle = tester.ensureSemantics();
      // El botón activo se anuncia como seleccionado (además del relleno).
      expect(
        tester.getSemantics(find.byKey(const ValueKey('herramienta-notes'))),
        isSemantics(isSelected: true, label: 'Anotar'),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('herramienta-cross'))),
        isNot(isSemantics(isSelected: true)),
      );
      handle.dispose();
    });

    testWidgets('tocar un mueble que bloquea avisa y no cambia nada', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      final blocked = [
        for (var i = 0; i < small.map.size * small.map.size; i++)
          if (!small.map.isOccupiable(i)) i,
      ].first;
      await pickSuspect(tester, firstChar);
      await tapCell(tester, blocked);
      expect(find.text(BoardStrings.blockedCell), findsOneWidget);
      expect(
        rig.container.read(gameControllerProvider(small)).board.isEmpty,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  // ---------------------------------------------------------------------------
  group('menú de acciones secundarias', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('no ocupa el espacio del tablero: solo abre al tocarlo', (
      tester,
    ) async {
      await pumpGameScreen(tester, small);
      final before = gameOf(tester).geometry.board;
      expect(find.text('Más acciones'), findsNothing);
      await openMenu(tester);
      expect(find.text('Más acciones'), findsOneWidget);
      for (final t in [
        'Rehacer',
        'Limpiar tablero',
        'Mapa',
        'Notas',
        'Auto-X',
        'Leyenda y reglas',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(gameOf(tester).geometry.board, before);
      expect(_smallTexts(tester), isEmpty);
    });

    testWidgets('Deshacer y Rehacer', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      GameState s() => rig.container.read(gameControllerProvider(small));
      final cell = firstFreeCell(small);
      await pickSuspect(tester, firstChar);
      await tapCell(tester, cell);
      expect(s().board.cell(cell).candidates, isNotEmpty);

      await tester.tap(find.byIcon(Icons.undo));
      await settle(tester, 2);
      expect(s().board.isEmpty, isTrue);

      await openMenu(tester);
      await tester.tap(find.text('Rehacer'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(s().board.cell(cell).candidates, isNotEmpty);
    });

    testWidgets('Limpiar tablero pide confirmación', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      GameState s() => rig.container.read(gameControllerProvider(small));
      final cell = firstFreeCell(small);
      await pickSuspect(tester, firstChar);
      await tapCell(tester, cell);

      await openMenu(tester);
      await tester.tap(find.text('Limpiar tablero'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Limpiar tablero?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(s().board.isEmpty, isFalse);

      await tester.tap(find.text('Limpiar tablero'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Limpiar'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(s().board.isEmpty, isTrue);
    });

    testWidgets('Mapa y Notas cambian la vista del tablero', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      await openMenu(tester);
      await tester.tap(find.text('Notas'));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester, 2);
      expect(
        rig.container.read(gameControllerProvider(small)).mapMode,
        isFalse,
      );
      expect(gameOf(tester).session.mapMode, isFalse);
      await openMenu(tester);
      await tester.tap(find.text('Mapa'));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester, 2);
      expect(rig.container.read(gameControllerProvider(small)).mapMode, isTrue);
      expect(gameOf(tester).session.mapMode, isTrue);
    });

    testWidgets('Auto-X se apaga y se enciende', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      await openMenu(tester);
      final before = rig.container.read(gameControllerProvider(small)).autoX;
      await tester.tap(find.byKey(const ValueKey('menu-autox')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(rig.container.read(gameControllerProvider(small)).autoX, !before);
    });

    testWidgets('la leyenda trae habitaciones, muebles y reglas', (
      tester,
    ) async {
      await pumpGameScreen(tester, small);
      await openMenu(tester);
      await tester.tap(find.text('Leyenda y reglas'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      for (final t in ['HABITACIONES', 'MUEBLES', 'REGLAS']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.textContaining(small.map.areas.first.nameEs), findsWidgets);
    });

    testWidgets('el medidor de FPS está apagado y se enciende desde el menú', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      expect(find.byKey(const ValueKey('fps-en-vivo')), findsNothing);
      await openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('menu-fps')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(rig.container.read(settingsProvider).fpsMeter, isTrue);
      await tester.tapAt(const Offset(180, 20)); // cierra la hoja
      await tester.pump(const Duration(milliseconds: 500));
      await settle(tester, 2);
      expect(find.byKey(const ValueKey('fps-en-vivo')), findsOneWidget);
      // Va en la barra superior, fuera del tablero.
      expect(
        tester.getRect(find.byKey(const ValueKey('fps-en-vivo'))).bottom,
        lessThanOrEqualTo(tester.getRect(gameFinder).top + 0.5),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('piel y modo', () {
    Color bgOf(String skin, Brightness b) =>
        SkinRegistry.spec(skin).palette(b).bg;

    testWidgets('la partida usa la piel y el modo elegidos', (tester) async {
      for (final skin in kPlayerSkins) {
        for (final (mode, b) in [
          (ThemeMode.light, Brightness.light),
          (ThemeMode.dark, Brightness.dark),
        ]) {
          await pumpGameScreen(
            tester,
            small,
            settings: AppSettings(skinId: skin, themeMode: mode),
          );
          final game = gameOf(tester);
          expect(game.skin.id, skin);
          expect(game.skin.mode, b);
          final ctx = tester.element(find.byType(Scaffold).first);
          expect(Theme.of(ctx).brightness, b);
          expect(ctx.skinTheme.skinId, skin);
          expect(
            tester
                .widget<Scaffold>(find.byType(Scaffold).first)
                .backgroundColor,
            bgOf(skin, b),
          );
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('el modo "Sistema" sigue al teléfono', (tester) async {
      await pumpGameScreen(tester, small, platformBrightness: Brightness.dark);
      expect(gameOf(tester).skin.mode, Brightness.dark);
      await tester.pumpWidget(const SizedBox());
      await pumpGameScreen(tester, small, platformBrightness: Brightness.light);
      expect(gameOf(tester).skin.mode, Brightness.light);
    });

    testWidgets('arranca con la piel Ilustrada', (tester) async {
      await pumpGameScreen(tester, small);
      expect(gameOf(tester).skin.id, 'ilustrada');
    });

    testWidgets('cambiar piel y modo en vivo no pierde la partida', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      final cell = firstFreeCell(small);
      await pickSuspect(tester, firstChar);
      await pickTool(tester, ToolMode.place);
      await tapCell(tester, cell);
      final game = gameOf(tester);

      rig.container.read(settingsProvider.notifier).setSkin('papel');
      await settle(tester, 3);
      expect(gameOf(tester), same(game), reason: 'es el mismo tablero');
      expect(game.skin.id, 'papel');
      rig.container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await settle(tester, 3);
      expect(game.skin.mode, Brightness.dark);
      expect(
        rig.container
            .read(gameControllerProvider(small))
            .board
            .confirmedCellOf(firstChar),
        cell,
      );
    });

    testWidgets('el menú de la partida cambia la piel y el modo y lo guarda', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      Finder pick(String key, String text) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.text(text),
      );
      await tester.ensureVisible(pick('selector-piel', 'Papel'));
      await tester.tap(pick('selector-piel', 'Papel'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(pick('selector-modo', 'Oscuro'));
      await tester.tap(pick('selector-modo', 'Oscuro'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(rig.container.read(settingsProvider).skinId, 'papel');
      expect(rig.container.read(settingsProvider).themeMode, ThemeMode.dark);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cfg:piel'), 'papel');
      expect(prefs.getString('cfg:modo'), 'oscuro');
    });

    testWidgets('con piel Papel y modo oscuro nada se ve ilegible', (
      tester,
    ) async {
      await pumpGameScreen(
        tester,
        small,
        settings: const AppSettings(skinId: 'papel', themeMode: ThemeMode.dark),
      );
      final p = SkinRegistry.spec('papel').palette(Brightness.dark);
      // El texto se lee sobre el fondo (contraste de al menos 4,5 a 1).
      double lum(Color c) => c.computeLuminance();
      double contrast(Color a, Color b) {
        final l1 = lum(a), l2 = lum(b);
        return (l1 > l2 ? l1 + .05 : l2 + .05) /
            (l1 > l2 ? l2 + .05 : l1 + .05);
      }

      expect(contrast(p.text, p.bg), greaterThan(4.5));
      expect(contrast(p.onToolActive, p.toolActive), greaterThan(4.5));
      expect(contrast(p.onAccent, p.accent), greaterThan(4.5));
      expect(contrast(p.onPill, p.pill), greaterThan(4.5));
    });
  });

  // ---------------------------------------------------------------------------
  group('sonido, vibración y modo silencio', () {
    testWidgets('con todo encendido, elegir un retrato suena y vibra', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, contains(SoundId.tick));
      expect(rig.haptics.pulses, isNotEmpty);
    });

    testWidgets('con el sonido apagado no suena pero sí vibra', (tester) async {
      final rig = await pumpGameScreen(
        tester,
        small,
        settings: const AppSettings(soundOn: false),
      );
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, isEmpty);
      expect(rig.haptics.pulses, isNotEmpty);
    });

    testWidgets('con la vibración apagada suena pero no vibra', (tester) async {
      final rig = await pumpGameScreen(
        tester,
        small,
        settings: const AppSettings(hapticsOn: false),
      );
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, contains(SoundId.tick));
      expect(rig.haptics.pulses, isEmpty);
    });

    testWidgets('los interruptores se aplican en vivo', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      rig.container.read(settingsProvider.notifier).setSound(false);
      rig.container.read(settingsProvider.notifier).setHaptics(false);
      await settle(tester, 2);
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, isEmpty);
      expect(rig.haptics.pulses, isEmpty);
    });

    testWidgets('modo silencio del teléfono: ni sonido ni vibración', (
      tester,
    ) async {
      final rig = await pumpGameScreen(
        tester,
        small,
        ringer: RingerMode.silent,
      );
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, isEmpty);
      expect(rig.haptics.pulses, isEmpty);
    });

    testWidgets('modo vibrar del teléfono: vibra pero no suena', (
      tester,
    ) async {
      final rig = await pumpGameScreen(
        tester,
        small,
        ringer: RingerMode.vibrate,
      );
      await pickSuspect(tester, firstChar);
      expect(rig.sound.played, isEmpty);
      expect(rig.haptics.pulses, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('rendimiento del reloj (H-58)', () {
    testWidgets('el reloj solo redibuja la pastilla, no el tablero ni la '
        'bandeja', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      final controller = rig.container.read(
        gameControllerProvider(small).notifier,
      );
      final rebuilt = <String, int>{};
      final old = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        final n = element.widget.runtimeType.toString();
        rebuilt[n] = (rebuilt[n] ?? 0) + 1;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = old);

      for (var i = 0; i < 5; i++) {
        controller.tick();
        await tester.pump(const Duration(milliseconds: 100));
      }
      debugOnRebuildDirtyWidget = old;

      expect(find.byKey(const ValueKey('cronometro')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cronometro'))).data,
        '00:05',
      );
      expect(rebuilt['TimerPill'], greaterThanOrEqualTo(5));
      for (final heavy in [
        'ToolBar',
        'SuspectPanel',
        'PortraitRow',
        'ResolveBar',
        'HintBox',
      ]) {
        expect(
          rebuilt[heavy],
          isNull,
          reason: '$heavy se redibujó con el reloj',
        );
      }
      // Tampoco la escena de Flame (GameWidget<BoardGame>) ni el escenario
      // (su clase es privada: se busca por nombre).
      expect(
        rebuilt.keys.where((k) => k.startsWith('GameWidget')),
        isEmpty,
        reason: 'la escena de Flame no debe redibujarse con los segundos',
      );
      expect(
        rebuilt.keys.where((k) => k.contains('BoardStage')),
        isEmpty,
        reason: 'el escenario no debe redibujarse con los segundos',
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('partida guardada y cierre', () {
    testWidgets('restaura lo guardado: tablero, vista y errores', (
      tester,
    ) async {
      final saved = SavedGame(
        elapsed: 321,
        errors: 2,
        savedAt: DateTime.utc(2026, 11, 5, 9),
        board: BoardState.empty()
            .placeConfirmed(0, small.characters.first.id)
            .board
            .placeCandidate(5, small.characters.last.id)
            .board,
        clueMarks: [for (var i = 0; i < small.clues.length; i++) 0],
        autoX: false,
        mapMode: false,
      ).encode();
      final rig = await pumpGameScreen(
        tester,
        small,
        prefs: {'game:${small.caseId}': saved},
      );
      final s = rig.container.read(gameControllerProvider(small));
      expect(s.elapsedSeconds, 321);
      expect(s.errorCount, 2);
      expect(s.mapMode, isFalse);
      expect(gameOf(tester).session.mapMode, isFalse);
      expect(gameOf(tester).session.board, same(s.board));
      expect(find.text('05:21'), findsOneWidget);
    });

    testWidgets('Resolver con el tablero incompleto dice cuántos faltan', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      rig.container
          .read(gameControllerProvider(small).notifier)
          .placeSuspect(0, charId: firstChar, confirm: true);
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await settle(tester, 2);
      expect(
        find.text(BoardStrings.missingSuspects(small.characters.length - 1)),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Resolver con casillas mal: "N casillas no cuadran" para '
        'lectores de pantalla y sin señalar cuáles', (tester) async {
      final handle = tester.ensureSemantics();
      final rig = await pumpGameScreen(tester, small);
      final c = rig.container.read(gameControllerProvider(small).notifier);
      final entries = small.solution.positions.entries.toList();
      c.toggleAutoX();
      c.placeSuspect(entries[1].value, charId: entries[0].key, confirm: true);
      c.placeSuspect(entries[0].value, charId: entries[1].key, confirm: true);
      for (final e in entries.skip(2)) {
        c.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await settle(tester, 3);
      expect(find.bySemanticsLabel(BoardStrings.wrongCells(2)), findsWidgets);
      expect(
        rig.container.read(gameControllerProvider(small)).errorCells,
        isEmpty,
      );
      await tester.pump(const Duration(seconds: 4));
      handle.dispose();
    });

    testWidgets('resolver bien corre la secuencia y abre el resumen', (
      tester,
    ) async {
      final rig = await pumpGameScreen(tester, small);
      final c = rig.container.read(gameControllerProvider(small).notifier);
      for (final e in small.solution.positions.entries) {
        c.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await settle(tester, 2);
      expect(rig.container.read(gameControllerProvider(small)).solved, isTrue);
      expect(gameOf(tester).revealPhase.value, isNot(RevealPhase.idle));
      expect(
        find.text('CASO CERRADO'),
        findsNothing,
        reason: 'primero la secuencia',
      );
      // Tras 1 s de secuencia aparece "Saltar" y el botón pasa a "Ver resumen".
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const ValueKey('saltar-secuencia')), findsOneWidget);
      expect(find.text('Ver resumen'), findsOneWidget);
      for (var i = 0; i < 140; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('CASO CERRADO'), findsOneWidget);
      expect(gameOf(tester).revealPhase.value, RevealPhase.done);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('done:${small.caseId}'), isNotNull);
    });

    testWidgets('Saltar corta la secuencia', (tester) async {
      final rig = await pumpGameScreen(tester, small);
      final c = rig.container.read(gameControllerProvider(small).notifier);
      for (final e in small.solution.positions.entries) {
        c.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byKey(const ValueKey('saltar-secuencia')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(gameOf(tester).revealPhase.value, RevealPhase.done);
      expect(rig.sound.stops, greaterThan(0));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('CASO CERRADO'), findsOneWidget);
    });
  });
}
