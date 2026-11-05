/// Controlador de partida: guardar y restaurar (H-55), reloj y pausa
/// (regla 10), Resolver sin señalar casillas (regla 9) y aviso sin
/// herramienta (regla 20). Todo determinista: el reloj real se apaga y los
/// segundos se avanzan a mano con tick().
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/game_tray.dart' show HintBox;
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/game_ui.dart';
import 'support/l10n.dart';

PuzzleCase _loadCase() {
  final j =
      jsonDecode(
            File(
              'assets/cases/caso-principiante-s1.json',
            ).readAsStringSync().replaceFirst('﻿', ''),
          )
          as Map<String, dynamic>;
  return PuzzleCase.fromJson(j);
}

/// Contenedor con el reloj real apagado, partida cargada y mantenida viva
/// (el controlador es autoDispose).
Future<(ProviderContainer, GameController)> _open(
  PuzzleCase pc, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(
    overrides: [gameTickerEnabledProvider.overrideWithValue(false)],
  );
  addTearDown(container.dispose);
  container.listen(gameControllerProvider(pc), (_, __) {});
  final controller = container.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  return (container, controller);
}

/// Deja que terminen las escrituras agrupadas en microtareas.
Future<void> _settle(GameController c) async {
  await Future<void>.delayed(Duration.zero);
  await c.saveNow();
}

/// Confirma a todos los personajes en su casilla de la solución.
void _placeSolution(GameController c, PuzzleCase pc) {
  for (final e in pc.solution.positions.entries) {
    final fb = c.placeSuspect(e.value, charId: e.key, confirm: true);
    expect(fb, ActionFeedback.ok);
  }
}

/// Confirma a todos, pero intercambia a los dos primeros (2 casillas mal).
Set<int> _placeSwapped(GameController c, PuzzleCase pc) {
  final entries = pc.solution.positions.entries.toList();
  final a = entries[0], b = entries[1];
  c.toggleAutoX(); // sin X automáticas: más simple de razonar
  c.placeSuspect(b.value, charId: a.key, confirm: true);
  c.placeSuspect(a.value, charId: b.key, confirm: true);
  for (final e in entries.skip(2)) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
  return {a.value, b.value};
}

Map<String, Object> _savedPrefs(PuzzleCase pc, {List<int>? marks}) => {
  SavedGame.keyFor(pc.caseId): SavedGame(
    elapsed: 321,
    errors: 2,
    savedAt: DateTime.utc(2026, 11, 4, 9),
    board: BoardState.empty()
        .placeConfirmed(0, pc.characters.first.id)
        .board
        .placeCandidate(5, pc.characters.last.id)
        .board,
    clueMarks:
        marks ?? [for (var i = 0; i < pc.clues.length; i++) i == 0 ? 1 : 0],
    autoX: false,
    mapMode: false,
  ).encode(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Letra real (Roboto) para medir bien la interfaz.
  setUpAll(loadRoboto);
  final pc = _loadCase();
  final firstChar = pc.characters.first.id;

  group('guardar y restaurar', () {
    test('sin partida guardada empieza de cero y lista', () async {
      final (container, c) = await _open(pc);
      final s = container.read(gameControllerProvider(pc));
      expect(s.loading, isFalse);
      expect(s.paused, isFalse);
      expect(s.elapsedSeconds, 0);
      expect(s.errorCount, 0);
      expect(s.board.isEmpty, isTrue);
      expect(s.autoX, isTrue);
      expect(s.mapMode, isTrue);
      expect(c.ready, completes);
    });

    test('abrir y salir sin tocar nada no deja partida guardada', () async {
      final (_, c) = await _open(pc);
      c.tick();
      c.pause();
      await _settle(c);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('game:${pc.caseId}'), isFalse);
    });

    test('guarda en cada cambio y restaura todo al volver a abrir', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      c.placeAt(0, confirm: true); // confirmado
      c.placeAt(7, confirm: false); // candidato de otro tipo de acción
      c.cycleClue(0); // destacada
      c.toggleMapMode();
      c.toggleAutoX();
      for (var i = 0; i < 5; i++) {
        c.tick();
      }
      await _settle(c);

      final prefs = await SharedPreferences.getInstance();
      final raw =
          jsonDecode(prefs.getString('game:${pc.caseId}')!)
              as Map<String, dynamic>;
      // Contrato compartido con las demás pantallas.
      expect(raw['v'], 1);
      expect(raw['elapsed'], 5);
      expect(raw['errors'], 0);
      expect(DateTime.tryParse(raw['savedAt'] as String), isNotNull);
      expect(raw['board'], isA<Map>());
      expect((raw['clueMarks'] as List).length, pc.clues.length);
      expect((raw['clueMarks'] as List).first, ClueMark.highlighted.index);
      expect(raw['autoX'], false);
      expect(raw['mapMode'], false);

      final before = container.read(gameControllerProvider(pc));
      container.dispose();

      // Se vuelve a abrir el caso con lo guardado.
      final (container2, c2) = await _open(
        pc,
        prefs: {'game:${pc.caseId}': prefs.getString('game:${pc.caseId}')!},
      );
      final after = container2.read(gameControllerProvider(pc));
      expect(after.board.toJson(), before.board.toJson());
      expect(after.board.confirmedCellOf(firstChar), 0);
      expect(after.clueMarks, before.clueMarks);
      expect(after.elapsedSeconds, 5);
      expect(after.errorCount, 0);
      expect(after.autoX, isFalse);
      expect(after.mapMode, isFalse);
      // El historial de deshacer empieza vacío.
      expect(after.canUndo, isFalse);
      expect(after.canRedo, isFalse);
      c2.undo();
      expect(
        container2.read(gameControllerProvider(pc)).board.toJson(),
        before.board.toJson(),
      );
    });

    test('restaura una partida guardada de antemano', () async {
      final (container, _) = await _open(pc, prefs: _savedPrefs(pc));
      final s = container.read(gameControllerProvider(pc));
      expect(s.elapsedSeconds, 321);
      expect(s.errorCount, 2);
      expect(s.board.confirmedCellOf(pc.characters.first.id), 0);
      expect(s.board.cell(5).candidates, {pc.characters.last.id});
      expect(s.clueMarks.first, ClueMark.highlighted);
      expect(s.autoX, isFalse);
      expect(s.mapMode, isFalse);
      expect(s.canUndo, isFalse);
    });

    test('una partida que no encaja con el caso se ignora', () async {
      final (container, _) = await _open(
        pc,
        prefs: _savedPrefs(pc, marks: [0, 1]),
      );
      final s = container.read(gameControllerProvider(pc));
      expect(s.elapsedSeconds, 0);
      expect(s.board.isEmpty, isTrue);
    });

    test('al cerrar el controlador se guarda el tiempo jugado', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      c.placeAt(0, confirm: false);
      await _settle(c);
      for (var i = 0; i < 7; i++) {
        c.tick();
      }
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw =
          jsonDecode(prefs.getString('game:${pc.caseId}')!)
              as Map<String, dynamic>;
      expect(raw['elapsed'], 7);
    });

    test('resolver bien borra la partida guardada', () async {
      final (container, c) = await _open(pc, prefs: _savedPrefs(pc));
      // Se parte de un tablero limpio para poder poner la solución.
      c.clearBoard();
      _placeSolution(c, pc);
      await _settle(c);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('game:${pc.caseId}'), isTrue);

      expect(c.solve(), ActionFeedback.solvedOk);
      expect(container.read(gameControllerProvider(pc)).solved, isTrue);
      await _settle(c);
      expect(prefs.containsKey('game:${pc.caseId}'), isFalse);

      // Resuelto: ni el reloj ni los guardados vuelven a escribir.
      c.tick();
      c.pause();
      await _settle(c);
      expect(prefs.containsKey('game:${pc.caseId}'), isFalse);
      expect(container.read(gameControllerProvider(pc)).elapsedSeconds, 321);
    });
  });

  group('resolver (regla 9)', () {
    test('tablero incompleto no cuenta error', () async {
      final (container, c) = await _open(pc);
      expect(c.solve(), ActionFeedback.incompleteBoard);
      expect(container.read(gameControllerProvider(pc)).errorCount, 0);
    });

    test('incorrecto: cuenta las casillas pero no las señala', () async {
      final (container, c) = await _open(pc);
      _placeSwapped(c, pc);

      expect(c.solve(), ActionFeedback.wrongSolution);
      final s = container.read(gameControllerProvider(pc));
      expect(s.solved, isFalse);
      expect(s.errorCount, 1);
      expect(s.wrongCount, 2);
      expect(s.errorCells, isEmpty);
      expect(s.locked, isTrue);
      // El bloqueo se mantiene: no se puede editar ni resolver otra vez.
      expect(c.solve(), ActionFeedback.ok);
      expect(container.read(gameControllerProvider(pc)).errorCount, 1);
    });

    test(
      'con revealCells (tutorial) también se señalan las casillas',
      () async {
        final (container, c) = await _open(pc);
        final wrongCells = _placeSwapped(c, pc);

        expect(c.solve(revealCells: true), ActionFeedback.wrongSolution);
        final s = container.read(gameControllerProvider(pc));
        expect(s.errorCount, 1);
        expect(s.wrongCount, 2);
        expect(s.errorCells, wrongCells);
        expect(s.locked, isTrue);
      },
    );

    test('el error cuenta aunque se salga y se vuelva a entrar', () async {
      final (container, c) = await _open(pc);
      _placeSwapped(c, pc);
      c.solve();
      await _settle(c);
      final saved = (await SharedPreferences.getInstance()).getString(
        'game:${pc.caseId}',
      )!;
      container.dispose();

      final (container2, _) = await _open(
        pc,
        prefs: {'game:${pc.caseId}': saved},
      );
      expect(container2.read(gameControllerProvider(pc)).errorCount, 1);
    });
  });

  group('aviso sin herramienta (regla 20)', () {
    test('tocar una casilla sin sospechoso ni herramienta avisa', () async {
      final (container, c) = await _open(pc);
      expect(c.placeAt(0, confirm: false), ActionFeedback.noToolSelected);
      expect(c.placeAt(0, confirm: true), ActionFeedback.noToolSelected);
      expect(container.read(gameControllerProvider(pc)).board.isEmpty, isTrue);
    });

    test('con un sospechoso elegido coloca sin avisar', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      expect(
        container.read(gameControllerProvider(pc)).board.cell(0).candidates,
        {firstChar},
      );
    });

    test('con Tachar o Borrar tampoco hace falta un sospechoso', () async {
      final (container, c) = await _open(pc);
      GameState read() => container.read(gameControllerProvider(pc));
      c.setToolMode(ToolMode.cross);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      expect(read().board.cell(0).x, XLevel.small);
      c.setToolMode(ToolMode.erase);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      expect(read().board.cell(0).isEmpty, isTrue);
    });

    test('Anotar y Confirmar sin sospechoso avisan (regla 20)', () async {
      final (_, c) = await _open(pc);
      expect(c.placeAt(0, confirm: false), ActionFeedback.noToolSelected);
      c.setToolMode(ToolMode.place);
      expect(c.placeAt(0, confirm: false), ActionFeedback.noToolSelected);
    });

    test('en pausa no se coloca ni se avisa', () async {
      final (_, c) = await _open(pc);
      c.pause();
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
    });
  });

  group('herramientas del ADR-0013', () {
    test('Anotar: toque corto anota y mantener oprimido confirma', () async {
      final (container, c) = await _open(pc);
      GameState read() => container.read(gameControllerProvider(pc));
      expect(read().toolMode, ToolMode.notes);
      c.tapSuspect(firstChar);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      expect(read().board.cell(0).candidates, {firstChar});
      expect(c.placeAt(0, confirm: true), ActionFeedback.ok);
      expect(read().board.confirmedCellOf(firstChar), 0);
    });

    test('Confirmar: un toque basta para fijar al sospechoso', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      c.setToolMode(ToolMode.place);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      final s = container.read(gameControllerProvider(pc));
      expect(s.board.confirmedCellOf(firstChar), 0);
    });

    test('Tachar pone la X a mano y otro toque la quita', () async {
      final (container, c) = await _open(pc);
      GameState read() => container.read(gameControllerProvider(pc));
      c.setToolMode(ToolMode.cross);
      c.placeAt(0, confirm: false);
      expect(read().board.cell(0).x, XLevel.small);
      c.placeAt(0, confirm: false);
      expect(read().board.cell(0).x, isNull);
    });

    test('Tachar no pisa una ficha confirmada', () async {
      final (container, c) = await _open(pc);
      c.placeSuspect(0, charId: firstChar, confirm: true);
      c.setToolMode(ToolMode.cross);
      expect(c.placeAt(0, confirm: false), ActionFeedback.cellHasConfirmed);
      final s = container.read(gameControllerProvider(pc));
      expect(s.board.confirmedCellOf(firstChar), 0);
    });

    test('Borrar limpia la casilla completa', () async {
      final (container, c) = await _open(pc);
      c.placeSuspect(0, charId: firstChar, confirm: true);
      c.setToolMode(ToolMode.erase);
      expect(c.placeAt(0, confirm: false), ActionFeedback.ok);
      final s = container.read(gameControllerProvider(pc));
      expect(s.board.cell(0).isEmpty, isTrue);
    });

    test('Tachar y Borrar sueltan al sospechoso y elegir un retrato vuelve a '
        'Anotar', () async {
      final (container, c) = await _open(pc);
      GameState read() => container.read(gameControllerProvider(pc));
      c.tapSuspect(firstChar);
      c.setToolMode(ToolMode.cross);
      expect(read().selectedChar, isNull);
      c.tapSuspect(firstChar);
      expect(read().toolMode, ToolMode.notes);
      expect(read().selectedChar, firstChar);
      c.setToolMode(ToolMode.erase);
      expect(read().selectedChar, isNull);
      c.tapSuspect(firstChar);
      expect(read().toolMode, ToolMode.notes);
      // Tocar de nuevo al mismo sospechoso lo suelta.
      c.tapSuspect(firstChar);
      expect(read().selectedChar, isNull);
    });

    test('una casilla con mueble que bloquea avisa y no cambia nada', () async {
      final (container, c) = await _open(pc);
      final blocked = [
        for (var i = 0; i < pc.map.size * pc.map.size; i++)
          if (!pc.map.isOccupiable(i)) i,
      ];
      expect(blocked, isNotEmpty);
      c.tapSuspect(firstChar);
      expect(
        c.placeAt(blocked.first, confirm: true),
        ActionFeedback.blockedCell,
      );
      expect(container.read(gameControllerProvider(pc)).board.isEmpty, isTrue);
    });

    test('al resolver bien la herramienta vuelve a Anotar y no queda nadie '
        'elegido', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      c.setToolMode(ToolMode.place);
      _placeSolution(c, pc);
      expect(c.solve(), ActionFeedback.solvedOk);
      final s = container.read(gameControllerProvider(pc));
      expect(s.toolMode, ToolMode.notes);
      expect(s.selectedChar, isNull);
    });
  });

  group('reloj y pausa (regla 10)', () {
    test('tick avanza el reloj y pause lo detiene', () async {
      final (container, c) = await _open(pc);
      GameState read() => container.read(gameControllerProvider(pc));

      c.tick();
      c.tick();
      expect(read().elapsedSeconds, 2);

      c.pause();
      expect(read().paused, isTrue);
      c.tick();
      c.tick();
      c.tick();
      expect(read().elapsedSeconds, 2, reason: 'el reloj no avanza en pausa');

      c.resume();
      expect(read().paused, isFalse);
      c.tick();
      expect(read().elapsedSeconds, 3);
    });

    test('la pausa bloquea la edición y las marcas de pistas', () async {
      final (container, c) = await _open(pc);
      c.tapSuspect(firstChar);
      c.pause();
      c.placeSuspect(0, charId: firstChar, confirm: true);
      c.cycleClue(0);
      c.setClueMark(0, ClueMark.struck);
      final s = container.read(gameControllerProvider(pc));
      expect(s.board.isEmpty, isTrue);
      expect(s.clueMarks.first, ClueMark.normal);
      expect(c.solve(), ActionFeedback.ok);
    });

    test(
      'pasar a segundo plano pausa y guarda; al volver sigue en pausa',
      () async {
        final (container, c) = await _open(pc);
        GameState read() => container.read(gameControllerProvider(pc));
        c.tapSuspect(firstChar);
        c.placeAt(0, confirm: false);
        c.tick();
        c.tick();

        container.read(appLifecycleProvider.notifier).state =
            AppLifecycleState.paused;
        expect(read().paused, isTrue);
        await _settle(c);
        final prefs = await SharedPreferences.getInstance();
        final raw =
            jsonDecode(prefs.getString('game:${pc.caseId}')!)
                as Map<String, dynamic>;
        expect(raw['elapsed'], 2);

        // Al volver, la partida NO se reanuda sola: hay que tocar Continuar.
        container.read(appLifecycleProvider.notifier).state =
            AppLifecycleState.resumed;
        expect(read().paused, isTrue);
        c.tick();
        expect(read().elapsedSeconds, 2);
        c.resume();
        c.tick();
        expect(read().elapsedSeconds, 3);
      },
    );

    test('inactive y hidden también pausan', () async {
      for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
        final (container, _) = await _open(pc);
        container.read(appLifecycleProvider.notifier).state = st;
        expect(
          container.read(gameControllerProvider(pc)).paused,
          isTrue,
          reason: '$st',
        );
        container.dispose();
      }
    });

    test('resuelto: pausa y tick no hacen nada', () async {
      final (container, c) = await _open(pc);
      _placeSolution(c, pc);
      c.tick();
      expect(c.solve(), ActionFeedback.solvedOk);
      c.pause();
      c.tick();
      final s = container.read(gameControllerProvider(pc));
      expect(s.paused, isFalse);
      expect(s.elapsedSeconds, 1);
    });
  });

  group('pantalla de partida', () {
    Future<ProviderContainer> pumpGame(WidgetTester tester) async =>
        (await pumpGameScreen(tester, pc)).container;

    const exitText = 'Tu avance queda guardado. ¿Salir del caso?';

    testWidgets('en segundo plano tapa el tablero con "Partida en pausa"', (
      tester,
    ) async {
      final container = await pumpGame(tester);
      expect(find.text('Partida en pausa'), findsNothing);

      container.read(appLifecycleProvider.notifier).state =
          AppLifecycleState.paused;
      await tester.pump();
      container.read(appLifecycleProvider.notifier).state =
          AppLifecycleState.resumed;
      await tester.pump();
      // Al volver sigue tapado hasta tocar Continuar.
      expect(find.text('Partida en pausa'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(container.read(gameControllerProvider(pc)).paused, isTrue);

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Partida en pausa'), findsNothing);
      expect(container.read(gameControllerProvider(pc)).paused, isFalse);
    });

    testWidgets('en pausa el tablero no recibe toques', (tester) async {
      final container = await pumpGame(tester);
      final c = container.read(gameControllerProvider(pc).notifier);
      c.tapSuspect(firstChar);
      c.pause();
      await settle(tester, 2);
      c.placeAt(0, confirm: true);
      expect(container.read(gameControllerProvider(pc)).board.isEmpty, isTrue);
      expect(gameOf(tester).session.interactive, isFalse);
    });

    testWidgets('la flecha pide confirmación y Salir va a /casos', (
      tester,
    ) async {
      await pumpGame(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(exitText), findsOneWidget);

      await tester.tap(find.text('Seguir jugando'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(exitText), findsNothing);
      expect(find.text('LISTA DE CASOS'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Salir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('LISTA DE CASOS'), findsOneWidget);
    });

    testWidgets('el diálogo de salida detiene el reloj sin mostrar la pausa', (
      tester,
    ) async {
      final container = await pumpGame(tester);
      int secs() => container.read(gameControllerProvider(pc)).elapsedSeconds;
      final c = container.read(gameControllerProvider(pc).notifier);
      c.tick();
      expect(secs(), 1);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(exitText), findsOneWidget);
      c.tick();
      expect(secs(), 1, reason: 'reloj detenido con el diálogo abierto');
      expect(find.text('Partida en pausa'), findsNothing);
      expect(container.read(gameControllerProvider(pc)).paused, isFalse);

      await tester.tap(find.text('Seguir jugando'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      c.tick();
      expect(secs(), 2, reason: 'reloj reanudado');
      expect(find.text('Partida en pausa'), findsNothing);
    });

    testWidgets('el botón Atrás del sistema muestra el mismo diálogo', (
      tester,
    ) async {
      await pumpGame(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(exitText), findsOneWidget);
      expect(find.text('LISTA DE CASOS'), findsNothing);
    });

    testWidgets('tocar una casilla sin sospechoso elegido muestra el aviso', (
      tester,
    ) async {
      await pumpGame(tester);
      await tapCell(tester, firstFreeCell(pc));
      expect(find.text(l10nEs.boardPickSuspectFirst), findsOneWidget);
      expect(l10nEs.boardPickSuspectFirst, 'Elige primero a un sospechoso');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('mantener oprimida la pista abre la pista completa', (
      tester,
    ) async {
      final container = await pumpGame(tester);
      final withClue = pc.characters.firstWhere(
        (c) => pc.clueFor(c.id) != null,
      );
      final clue = pc.clueFor(withClue.id)!;
      final text = clue.cardTextEs(pc.map, pc.names);

      await pickSuspect(tester, withClue.id);
      await tester.longPress(find.byType(HintBox));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // La hoja muestra el texto completo en letra de 16 px o más y las
      // tres marcas.
      final big = find.byWidgetPredicate(
        (w) => w is Text && w.data == text && (w.style?.fontSize ?? 0) >= 16,
      );
      expect(big, findsOneWidget);
      // "Tachar" también es una herramienta de la barra: se busca en la hoja.
      final inSheet = find.byType(BottomSheet);
      Finder mark(String t) =>
          find.descendant(of: inSheet, matching: find.text(t));
      expect(mark('Normal'), findsOneWidget);
      expect(mark('Destacar'), findsOneWidget);
      expect(mark('Tachar'), findsOneWidget);

      final i = pc.clues.indexOf(clue);
      ClueMark current() =>
          container.read(gameControllerProvider(pc)).clueMarks[i];
      await tester.tap(mark('Tachar'));
      await tester.pump();
      expect(current(), ClueMark.struck);
      await tester.tap(mark('Destacar'));
      await tester.pump();
      expect(current(), ClueMark.highlighted);
      await tester.tap(mark('Normal'));
      await tester.pump();
      expect(current(), ClueMark.normal);
    });

    testWidgets('tocar la pista la destaca y luego la tacha', (tester) async {
      final container = await pumpGame(tester);
      final withClue = pc.characters.firstWhere(
        (c) => pc.clueFor(c.id) != null,
      );
      final i = pc.clues.indexOf(pc.clueFor(withClue.id)!);
      ClueMark mark() =>
          container.read(gameControllerProvider(pc)).clueMarks[i];
      await pickSuspect(tester, withClue.id);
      await tester.tap(find.byType(HintBox));
      await tester.pump();
      expect(mark(), ClueMark.highlighted);
      await tester.tap(find.byType(HintBox));
      await tester.pump();
      expect(mark(), ClueMark.struck);
    });

    testWidgets('si la pista queda cortada con "…" aparece "ver más"', (
      tester,
    ) async {
      // En pantallas bajas la pista ocupa una sola línea.
      await pumpGameScreen(tester, pc, size: const Size(360, 640));
      // Con la tipografía de prueba (cada letra ocupa un cuadrado) las
      // pistas largas se cortan: la señal debe verse en esa pista.
      int len(Character c) =>
          pc.clueFor(c.id)?.cardTextEs(pc.map, pc.names).length ?? 0;
      final longest = pc.characters.reduce((a, b) => len(a) >= len(b) ? a : b);
      await pickSuspect(tester, longest.id);
      expect(find.text('ver más'), findsOneWidget);
    });

    test('mensaje de casillas que no cuadran, con plural correcto', () {
      expect(l10nEs.boardWrongCells(1), '1 casilla no cuadra');
      expect(l10nEs.boardWrongCells(2), '2 casillas no cuadran');
      expect(l10nEs.boardWrongCells(5), '5 casillas no cuadran');
    });

    testWidgets('Resolver con casillas mal cuenta cuántas, no cuáles', (
      tester,
    ) async {
      final container = await pumpGame(tester);
      final c = container.read(gameControllerProvider(pc).notifier);
      _placeSwapped(c, pc);
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await settle(tester, 3);
      final s = container.read(gameControllerProvider(pc));
      expect(s.wrongCount, 2);
      expect(s.errorCells, isEmpty); // regla 9: solo el tutorial señala
      expect(s.errorCount, 1);
      await tester.pump(const Duration(seconds: 4));
    });
  });
  group('holdClock y releaseClock', () {
    test('detienen el reloj sin pausar y lo reanudan', () async {
      final (container, c) = await _open(pc);
      c.tick();
      c.holdClock();
      c.tick();
      expect(container.read(gameControllerProvider(pc)).elapsedSeconds, 1);
      expect(container.read(gameControllerProvider(pc)).paused, isFalse);
      c.releaseClock();
      c.tick();
      expect(container.read(gameControllerProvider(pc)).elapsedSeconds, 2);
    });
  });

  group('el tutorial no guarda partida', () {
    final tpc = PuzzleCase.fromJson(
      jsonDecode(
            File(
              'assets/tutorial/caso-tutorial.json',
            ).readAsStringSync().replaceFirst('\uFEFF', ''),
          )
          as Map<String, dynamic>,
    );
    const key = 'game:$kTutorialCaseId';

    test('no guarda, no restaura y no borra "game:tutorial"', () async {
      final (container, c) = await _open(
        tpc,
        prefs: {key: 'dato previo que no se toca'},
      );
      final s = container.read(gameControllerProvider(tpc));
      expect(s.board.isEmpty, isTrue);
      expect(s.elapsedSeconds, 0);
      c.placeSuspect(0, charId: tpc.characters.first.id, confirm: true);
      c.tick();
      c.pause();
      await _settle(c);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), 'dato previo que no se toca');
    });

    test('tampoco crea la clave si no existía', () async {
      final (_, c) = await _open(tpc);
      c.placeSuspect(0, charId: tpc.characters.first.id, confirm: true);
      c.pause();
      await _settle(c);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(key), isFalse);
    });
  });

  group('pausa al cargar en segundo plano', () {
    test('si la app ya está en segundo plano, queda en pausa', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [gameTickerEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      container.read(appLifecycleProvider.notifier).state =
          AppLifecycleState.paused;
      container.listen(gameControllerProvider(pc), (_, __) {});
      await container.read(gameControllerProvider(pc).notifier).ready;
      final s = container.read(gameControllerProvider(pc));
      expect(s.loading, isFalse);
      expect(s.paused, isTrue);
      container.read(gameControllerProvider(pc).notifier).tick();
      expect(container.read(gameControllerProvider(pc)).elapsedSeconds, 0);
    });

    test('en primer plano no queda en pausa', () async {
      final (container, _) = await _open(pc);
      expect(container.read(gameControllerProvider(pc)).paused, isFalse);
    });
  });
}
