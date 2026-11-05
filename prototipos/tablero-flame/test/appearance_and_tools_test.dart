import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/feedback/feedback_event.dart';
import 'package:tablero_flame/src/game/game_session.dart';
import 'package:tablero_flame/src/scene/skins.dart';
import 'package:tablero_flame/src/settings.dart';
import 'package:tablero_flame/src/strings.dart';
import 'package:tablero_flame/src/ui/options_sheet.dart';
import 'package:tablero_flame/src/ui/prototype_theme.dart';
import 'package:tablero_flame/src/ui/toolbar.dart';
import 'package:tablero_flame/src/ui/tray.dart';

import 'helpers.dart';

/// Mini aplicación con el mismo cableado de tema que `main.dart`.
class _Harness extends StatelessWidget {
  const _Harness({required this.settings, required this.child});
  final GameSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        theme: Ui.theme(settings.skinId, Brightness.light),
        darkTheme: Ui.theme(settings.skinId, Brightness.dark),
        themeMode: settings.themeMode,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }
}

void main() {
  group('selector de piel y modo (pantalla de opciones)', () {
    testWidgets('tocar una piel cambia la piel y el tema', (tester) async {
      final settings = GameSettings();
      await tester.pumpWidget(_Harness(
          settings: settings, child: AppearanceSelector(settings: settings)));
      expect(settings.skinId, 'ilustrada');
      final ctx = tester.element(find.byType(AppearanceSelector));
      expect(ctx.enx.skinId, 'ilustrada');

      await tester.tap(find.text('Papel'));
      await tester.pumpAndSettle();
      expect(settings.skinId, 'papel');
      expect(tester.element(find.byType(AppearanceSelector)).enx.skinId, 'papel');

      await tester.tap(find.text('Neutra'));
      await tester.pumpAndSettle();
      expect(settings.skinId, 'neutra');
      expect(tester.element(find.byType(AppearanceSelector)).enx.skinId, 'neutra');

      await tester.tap(find.text('Ilustrada'));
      await tester.pumpAndSettle();
      expect(settings.skinId, 'ilustrada');
    });

    testWidgets('tocar un modo cambia el tema claro u oscuro', (tester) async {
      final settings = GameSettings();
      await tester.pumpWidget(_Harness(
          settings: settings, child: AppearanceSelector(settings: settings)));

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      expect(settings.themeMode, ThemeMode.dark);
      var ctx = tester.element(find.byType(AppearanceSelector));
      expect(Theme.of(ctx).brightness, Brightness.dark);
      expect(ctx.pal.mode, Brightness.dark);
      final darkBg = ctx.pal.bg;

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(settings.themeMode, ThemeMode.light);
      ctx = tester.element(find.byType(AppearanceSelector));
      expect(Theme.of(ctx).brightness, Brightness.light);
      expect(ctx.pal.bg.computeLuminance(), greaterThan(darkBg.computeLuminance()));
    });

    testWidgets('con Sistema, el teléfono decide', (tester) async {
      final settings = GameSettings(); // ThemeMode.system
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(_Harness(
          settings: settings, child: AppearanceSelector(settings: settings)));
      var ctx = tester.element(find.byType(AppearanceSelector));
      expect(ctx.pal.mode, Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      ctx = tester.element(find.byType(AppearanceSelector));
      expect(ctx.pal.mode, Brightness.light);
    });

    testWidgets('cada piel arma su tema con su estilo de recuadros', (tester) async {
      for (final spec in SkinRegistry.specs) {
        for (final m in Brightness.values) {
          final t = Ui.theme(spec.id, m);
          final enx = t.extension<EnxTheme>()!;
          expect(enx.skinId, spec.id);
          expect(enx.chrome, spec.chrome);
          expect(enx.palette.mode, m);
          expect(t.brightness, m);
        }
      }
    });
  });

  group('barra de herramientas y bandeja', () {
    late LoggingRig rig;
    late GameSession s;

    setUp(() {
      rig = LoggingRig();
      s = rig.session(loadCase('caso-principiante-s1'));
    });

    int freeCell() => s.pc.map.occupiableCells
        .firstWhere((c) => !s.pc.solution.positions.values.contains(c));

    testWidgets('los cuatro botones están y Anotar arranca activa', (tester) async {
      final settings = GameSettings();
      await tester.pumpWidget(_Harness(
        settings: settings,
        child: ListenableBuilder(
            listenable: s, builder: (_, _) => ToolBar(session: s)),
      ));
      for (final t in ['Anotar', 'Tachar', 'Confirmar', 'Borrar']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(s.tool, ToolMode.notes);
      await tester.tap(find.text('Tachar'));
      await tester.pump();
      expect(s.tool, ToolMode.cross);
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(s.tool, ToolMode.place);
      await tester.tap(find.text('Borrar'));
      await tester.pump();
      expect(s.tool, ToolMode.erase);
      expect(s.eraser, isTrue);
    });

    test('Confirmar: un toque confirma al sospechoso elegido', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.setTool(ToolMode.place);
      s.tapCell(cell);
      expect(s.board.cell(cell).confirmed, 'c1');
      expect(rig.eventsOf<Confirmed>().single.cell, cell);
    });

    test('Confirmar sin sospechoso elegido avisa', () {
      s.setTool(ToolMode.place);
      s.tapCell(freeCell());
      expect(rig.eventsOf<PlacementRejected>().single.problem,
          PlacementProblem.noSuspect);
    });

    test('Anotar: un toque anota y mantener oprimido confirma (como antes)', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.tapCell(cell);
      expect(s.board.cell(cell).candidates, {'c1'});
      s.holdCell(cell);
      expect(s.board.cell(cell).confirmed, 'c1');
    });

    test('Tachar: un toque pone una X a mano y otro la quita', () {
      final cell = freeCell();
      s.setTool(ToolMode.cross);
      s.tapCell(cell);
      expect(s.board.cell(cell).x, isNotNull);
      expect(rig.eventsOf<CrossMarked>().single.cell, cell);
      s.tapCell(cell);
      expect(s.board.cell(cell).hasX, isFalse);
      expect(rig.eventsOf<Erased>().single.cell, cell);
    });

    test('Tachar no pisa una ficha confirmada', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.holdCell(cell);
      s.setTool(ToolMode.cross);
      s.tapCell(cell);
      expect(s.board.cell(cell).confirmed, 'c1');
      expect(rig.eventsOf<PlacementRejected>().last.problem,
          PlacementProblem.cellHasConfirmed);
    });

    test('Tachar y Borrar sueltan al sospechoso; elegir uno vuelve a Anotar', () {
      s.selectSuspect('c1');
      s.setTool(ToolMode.cross);
      expect(s.selectedChar, isNull);
      s.selectSuspect('c2');
      expect(s.tool, ToolMode.notes);
      expect(s.selectedChar, 'c2');
      s.setTool(ToolMode.place);
      s.selectSuspect('c3'); // Confirmar se mantiene
      expect(s.tool, ToolMode.place);
    });

    testWidgets('la fila de retratos muestra a todos y elegir uno muestra su pista',
        (tester) async {
      final settings = GameSettings();
      final skin = SkinRegistry.create('ilustrada', Brightness.light);
      final pulse = ValueNotifier<TrayPulse?>(null);
      await tester.pumpWidget(_Harness(
        settings: settings,
        child: ListenableBuilder(
          listenable: s,
          builder: (_, _) =>
              SuspectPanel(session: s, skin: skin, pulse: pulse),
        ),
      ));
      expect(find.text(Strings.hintEmpty), findsOneWidget);
      // Los retratos visibles de la fila (la fila se desliza).
      expect(find.text('Adela'), findsOneWidget);
      await tester.tap(find.text('Adela'));
      await tester.pump();
      expect(s.selectedChar, 'c1');
      final clue = s.pc.clueFor('c1')!.cardTextEs(s.pc.map, s.pc.names);
      expect(find.textContaining(clue, findRichText: true), findsOneWidget);
      expect(find.textContaining('ADELA', findRichText: true), findsOneWidget);
      // Con 6 personajes todos caben en el ancho: no hay que deslizar.
      expect(find.text('Víctima'), findsOneWidget);
    });
  });
}
