/// Conexión del tablero con el controlador: cada toque pasa por las reglas de
/// `GameController` y el director de feedback recibe QUÉ pasó (anotó,
/// confirmó, tachó, borró, rechazó...). Todo sin pantalla y con relojes
/// falsos.
library;

import 'package:enigmatrix/src/board/board_strings.dart';
import 'package:enigmatrix/src/board/feedback/feedback_plan.dart';
import 'package:enigmatrix/src/game/board_interaction.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/board_rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pc = loadCase('caso-principiante-s1');
  final solution = pc.solution.positions;
  final first = pc.characters.first.id;
  final second = pc.characters[1].id;

  late ProviderContainer container;
  late GameController controller;
  late Rig rig;
  late BoardInteraction io;
  var replaceAnswer = true;
  var replaceAsked = 0;

  GameState read() => container.read(gameControllerProvider(pc));
  Iterable<VisualKind> kinds() => rig.visual.played.map((e) => e.kind);
  List<String?> messages() => [
    for (final e in rig.visual.played)
      if (e.kind == VisualKind.message) e.text,
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [gameTickerEnabledProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    container.listen(gameControllerProvider(pc), (_, _) {});
    controller = container.read(gameControllerProvider(pc).notifier);
    await controller.ready;
    rig = Rig();
    replaceAnswer = true;
    replaceAsked = 0;
    io = BoardInteraction(
      controller: controller,
      read: read,
      director: rig.director,
      confirmReplace: () async {
        replaceAsked++;
        return replaceAnswer;
      },
    );
  });

  group('retratos', () {
    test(
      'elegir un sospechoso suena y lo marca; tocarlo otra vez lo suelta',
      () {
        io.selectSuspect(first);
        expect(read().selectedChar, first);
        expect(kinds(), contains(VisualKind.selectPulse));
        expect(rig.sound.played.map((c) => c.id), contains(SoundId.tick));

        rig.visual.played.clear();
        io.selectSuspect(first);
        expect(read().selectedChar, isNull);
        expect(rig.visual.played, isEmpty, reason: 'soltar no anima');
      },
    );

    test('con la partida resuelta ya no se elige a nadie', () {
      for (final e in solution.entries) {
        controller.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      controller.solve();
      io.selectSuspect(first);
      expect(read().selectedChar, isNull);
    });
  });

  group('Anotar', () {
    test('sin sospechoso elegido avisa y no cambia el tablero', () {
      io.tapCell(0);
      expect(messages(), [BoardStrings.pickSuspectFirst]);
      expect(read().board.isEmpty, isTrue);
    });

    test('toque corto anota un candidato con su efecto', () {
      io.selectSuspect(first);
      io.tapCell(0);
      expect(read().board.cell(0).candidates, {first});
      expect(kinds(), contains(VisualKind.pencilMark));
    });

    test('mantener oprimido confirma, con tachado automático en ola', () {
      io.selectSuspect(first);
      io.holdCell(0);
      expect(read().board.confirmedCellOf(first), 0);
      expect(
        kinds(),
        containsAll([VisualKind.confirmDrop, VisualKind.crossWave]),
      );
      final wave = rig.visual.played.firstWhere(
        (e) => e.kind == VisualKind.crossWave,
      );
      expect(wave.cells, isNotEmpty);
      expect(wave.cells, isNot(contains(0)));
    });

    test('sin Auto-X no hay ola de tachado', () {
      controller.toggleAutoX();
      io.selectSuspect(first);
      io.holdCell(0);
      expect(read().board.confirmedCellOf(first), 0);
      expect(kinds(), isNot(contains(VisualKind.crossWave)));
    });

    test('modo de tocar dos veces: el segundo toque confirma (regla 20)', () {
      io.selectSuspect(first);
      io.tapCell(0);
      expect(read().board.confirmedCellOf(first), isNull);
      io.tapCell(0);
      expect(read().board.confirmedCellOf(first), 0);
    });

    test('con el modo de dos toques apagado, el segundo toque no confirma', () {
      final off = BoardInteraction(
        controller: controller,
        read: read,
        director: rig.director,
        confirmReplace: () async => true,
        doubleTapConfirm: false,
      );
      off.selectSuspect(first);
      off.tapCell(0);
      off.tapCell(0);
      expect(read().board.confirmedCellOf(first), isNull);
    });

    test('sobre una casilla con ficha, avisa que hay que borrar primero', () {
      io.selectSuspect(first);
      io.holdCell(0);
      io.selectSuspect(second);
      io.tapCell(0);
      expect(messages(), contains(BoardStrings.cellHasConfirmed));
    });

    test('sobre una casilla tachada, avisa', () {
      controller.setToolMode(ToolMode.cross);
      io.tapCell(0);
      io.selectSuspect(first);
      io.tapCell(0);
      expect(messages(), contains(BoardStrings.cellHasX));
    });

    test('un sospechoso ya colocado no se coloca dos veces', () {
      io.selectSuspect(first);
      io.holdCell(0);
      rig.visual.played.clear();
      // Otra casilla libre en otra fila y columna.
      final other = [
        for (var i = 0; i < pc.map.size * pc.map.size; i++)
          if (pc.map.isOccupiable(i) &&
              i ~/ pc.map.size != 0 &&
              i % pc.map.size != 0)
            i,
      ].first;
      controller.toggleAutoX();
      io.holdCell(other);
      expect(messages(), contains(BoardStrings.alreadyPlaced));
    });

    test('un mueble que bloquea avisa', () {
      final blocked = [
        for (var i = 0; i < pc.map.size * pc.map.size; i++)
          if (!pc.map.isOccupiable(i)) i,
      ].first;
      io.selectSuspect(first);
      io.tapCell(blocked);
      expect(messages(), [BoardStrings.blockedCell]);
    });
  });

  group('Confirmar, Tachar y Borrar', () {
    test('Confirmar: un toque fija al sospechoso', () {
      io.selectSuspect(first);
      controller.setToolMode(ToolMode.place);
      io.tapCell(0);
      expect(read().board.confirmedCellOf(first), 0);
    });

    test('Confirmar sin sospechoso avisa', () {
      controller.setToolMode(ToolMode.place);
      io.tapCell(0);
      expect(messages(), [BoardStrings.pickSuspectFirst]);
    });

    test('Confirmar sobre otra ficha pregunta si se reemplaza', () async {
      io.selectSuspect(first);
      controller.setToolMode(ToolMode.place);
      io.tapCell(0);
      io.selectSuspect(second);
      controller.setToolMode(ToolMode.place);
      replaceAnswer = false;
      io.tapCell(0);
      await Future<void>.delayed(Duration.zero);
      expect(replaceAsked, 1);
      expect(read().board.confirmedCellOf(first), 0, reason: 'dijo que no');
      expect(read().board.confirmedCellOf(second), isNull);

      replaceAnswer = true;
      io.tapCell(0);
      await Future<void>.delayed(Duration.zero);
      expect(replaceAsked, 2);
      expect(read().board.confirmedCellOf(second), 0, reason: 'dijo que sí');
      expect(read().board.confirmedCellOf(first), isNull);
    });

    test('Tachar: pone la X y otro toque la quita', () {
      controller.setToolMode(ToolMode.cross);
      io.tapCell(0);
      expect(read().board.cell(0).x, isNotNull);
      expect(kinds(), contains(VisualKind.crossWave));
      io.tapCell(0);
      expect(read().board.cell(0).x, isNull);
      expect(kinds(), contains(VisualKind.erasePuff));
    });

    test('Borrar: limpia la casilla con su efecto', () {
      io.selectSuspect(first);
      io.holdCell(0);
      rig.visual.played.clear();
      controller.setToolMode(ToolMode.erase);
      io.tapCell(0);
      expect(read().board.cell(0).isEmpty, isTrue);
      expect(kinds(), contains(VisualKind.erasePuff));
    });
  });

  group('Resolver', () {
    test('con el tablero incompleto cuenta cuántos faltan', () {
      io.selectSuspect(first);
      io.holdCell(solution[first]!);
      final fb = io.solve();
      expect(fb, ActionFeedback.incompleteBoard);
      expect(messages(), [
        BoardStrings.missingSuspects(pc.characters.length - 1),
      ]);
    });

    test('con casillas mal dice cuántas no cuadran y suena el zumbido', () {
      final entries = solution.entries.toList();
      controller.toggleAutoX();
      controller.placeSuspect(
        entries[1].value,
        charId: entries[0].key,
        confirm: true,
      );
      controller.placeSuspect(
        entries[0].value,
        charId: entries[1].key,
        confirm: true,
      );
      for (final e in entries.skip(2)) {
        controller.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      final fb = io.solve();
      expect(fb, ActionFeedback.wrongSolution);
      final err = rig.visual.played.firstWhere(
        (e) => e.kind == VisualKind.errorText,
      );
      expect(err.text, BoardStrings.wrongCells(2));
      expect(rig.sound.played.map((c) => c.id), contains(SoundId.zumbido));
      // Regla 9: no se dicen cuáles.
      expect(read().errorCells, isEmpty);
    });

    test('en el tutorial sí se señalan las casillas que no cuadran', () {
      final entries = solution.entries.toList();
      controller.toggleAutoX();
      controller.placeSuspect(
        entries[1].value,
        charId: entries[0].key,
        confirm: true,
      );
      controller.placeSuspect(
        entries[0].value,
        charId: entries[1].key,
        confirm: true,
      );
      for (final e in entries.skip(2)) {
        controller.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      io.solve(revealCells: true);
      expect(read().errorCells, {entries[0].value, entries[1].value});
    });

    test('acierto: arranca la secuencia de revelar con el asesino', () {
      for (final e in solution.entries) {
        controller.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      final fb = io.solve();
      expect(fb, ActionFeedback.solvedOk);
      final start = rig.visual.played.firstWhere(
        (e) => e.kind == VisualKind.revealStart,
      );
      final reveal = start.reveal!;
      expect(reveal.murdererId, pc.solution.murdererId);
      expect(reveal.murdererName, pc.character(pc.solution.murdererId).nameEs);
      expect(reveal.murdererCell, solution[pc.solution.murdererId]);
      expect(reveal.victimCell, solution[pc.victimId]);
      expect(reveal.innocentCells, hasLength(pc.characters.length - 2));
      expect(reveal.gridSize, pc.map.size);
    });
  });

  group('casillas que ganaron una X automática', () {
    test('salen de la más cercana a la más lejana', () {
      const size = 6;
      final before = BoardState.empty();
      final after = before.placeConfirmed(14, first, autoXGridSize: size).board;
      final crossed = BoardInteraction.newlyCrossed(
        before,
        after,
        first,
        14,
        size,
      );
      // Fila y columna menos la casilla de origen.
      expect(crossed, hasLength(2 * (size - 1)));
      expect(crossed, isNot(contains(14)));
      int dist(int c) =>
          (c ~/ size - 14 ~/ size).abs() + (c % size - 14 % size).abs();
      for (var i = 1; i < crossed.length; i++) {
        expect(dist(crossed[i]), greaterThanOrEqualTo(dist(crossed[i - 1])));
      }
    });
  });
}
