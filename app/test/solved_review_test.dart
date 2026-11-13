/// Tablero resuelto que se puede mirar (jugadores de prueba) y la letra V de
/// la víctima: al tocar "Seguir mirando el tablero" la cámara vuelve a la
/// vista normal, se ve la solución completa, se leen las pistas y Mapa/Notas
/// cambian, pero el tablero no se edita.
library;

import 'package:enigmatrix/src/board/scene/skin.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/ui/clue_text.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_ui.dart';

/// Resuelve el caso, salta la secuencia y toca "Seguir mirando el tablero".
Future<GameRig> _solveAndLook(WidgetTester tester, PuzzleCase pc) async {
  final rig = await pumpGameScreen(tester, pc);
  final c = rig.container.read(gameControllerProvider(pc).notifier);
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
  await settle(tester, 2);
  await tester.tap(find.byKey(const ValueKey('boton-resolver')));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.byKey(const ValueKey('saltar-secuencia')));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('CASO CERRADO'), findsOneWidget);
  return rig;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRoboto);
  final small = loadBankCase('caso-principiante-s1');

  group('letra de la víctima', () {
    test('la víctima lleva siempre V y los demás su inicial', () {
      expect(tokenInitial('Julián', victim: true), 'V');
      expect(tokenInitial('Julián', victim: false), 'J');
      expect(tokenInitial('álvaro', victim: false), 'Á');
      expect(tokenInitial('', victim: false), '?');
      // Otro personaje que empieza por V no se confunde con la víctima.
      expect(tokenInitial('Valeria', victim: false), 'Va');
      expect(tokenInitial('Valeria', victim: true), 'V');
      expect(initialScale('Va'), lessThan(1));
      expect(initialScale('V'), 1);
    });

    testWidgets('el retrato de la víctima muestra V aunque su nombre no', (
      tester,
    ) async {
      await pumpGameScreen(tester, small);
      final victim = small.character(small.victimId);
      expect(victim.nameEs.toUpperCase().startsWith('V'), isFalse);
      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(ValueKey('retrato-${victim.id}')),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => p.painter)
          .whereType<Object>()
          .map((p) => (p as dynamic).style as TokenStyle)
          .toList();
      expect(painters, isNotEmpty);
      expect(painters.every((s) => s.initial == 'V' && s.victim), isTrue);
    });
  });

  group('seguir mirando el tablero resuelto', () {
    testWidgets('la cámara vuelve a la vista normal y no queda foco', (
      tester,
    ) async {
      final rig = await _solveAndLook(tester, small);
      final game = gameOf(tester);
      expect(game.rig.zoomT, greaterThan(0), reason: 'quedó el zoom al asesino');
      expect(game.overlay.spot, greaterThan(0));

      await tester.tap(find.text('Seguir mirando el tablero'));
      await settle(tester, 10);

      expect(find.text('CASO CERRADO'), findsNothing);
      expect(game.rig.zoomT, 0);
      expect(game.rig.scale, 1);
      expect(game.overlay.spot, 0);
      expect(game.overlay.dark, 0);
      expect(rig.container.read(gameControllerProvider(small)).reviewing, isTrue);
    });

    testWidgets('muestra la solución completa con X de fila y columna', (
      tester,
    ) async {
      final rig = await _solveAndLook(tester, small);
      await tester.tap(find.text('Seguir mirando el tablero'));
      await settle(tester, 10);
      final s = rig.container.read(gameControllerProvider(small));
      final n = small.map.size;
      for (final e in small.solution.positions.entries) {
        expect(s.board.cell(e.value).confirmed, e.key);
      }
      final solved = small.solution.positions.values.toSet();
      for (var i = 0; i < n * n; i++) {
        if (solved.contains(i)) continue;
        final c = s.board.cell(i);
        expect(c.confirmed, isNull);
        expect(c.candidates, isEmpty);
        expect(c.hasX, isTrue, reason: 'casilla $i debe verse descartada');
      }
    });

    testWidgets('se leen las pistas y se cambia entre Mapa y Notas', (
      tester,
    ) async {
      final rig = await _solveAndLook(tester, small);
      await tester.tap(find.text('Seguir mirando el tablero'));
      await settle(tester, 10);

      final id = small.characters.last.id;
      final clue = small.clueFor(id)!;
      await pickSuspect(tester, id);
      final s = rig.container.read(gameControllerProvider(small));
      expect(s.selectedChar, id);
      expect(
        find.textContaining(
          clueText(small, clue, locale: const Locale('es')),
          findRichText: true,
        ),
        findsWidgets,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Notas'));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester, 2);
      expect(gameOf(tester).session.mapMode, isFalse);
    });

    testWidgets('no se puede editar el tablero resuelto', (tester) async {
      final rig = await _solveAndLook(tester, small);
      await tester.tap(find.text('Seguir mirando el tablero'));
      await settle(tester, 10);
      final before = rig.container.read(gameControllerProvider(small)).board;

      final id = small.characters.first.id;
      await pickSuspect(tester, id);
      final free = firstFreeCell(small);
      await tapCell(tester, free);
      await holdCell(tester, free);
      final c = rig.container.read(gameControllerProvider(small).notifier);
      c.placeSuspect(free, charId: id, confirm: false);
      c.placeXMark(free, XLevel.large);
      c.eraseCell(small.solution.positions.values.first);
      c.undo();
      c.clearBoard();
      await settle(tester, 4);

      final after = rig.container.read(gameControllerProvider(small));
      expect(after.board, same(before));
      expect(gameOf(tester).session.interactive, isFalse);
      expect(after.solved, isTrue);
    });

    testWidgets('hay salida clara: Ver resumen y volver a la lista', (
      tester,
    ) async {
      await _solveAndLook(tester, small);
      await tester.tap(find.text('Seguir mirando el tablero'));
      await settle(tester, 10);
      expect(find.text('Ver resumen'), findsOneWidget);
      await tester.tap(find.text('Ver resumen'));
      await settle(tester, 10);
      expect(find.text('CASO CERRADO'), findsOneWidget);
    });
  });
}
