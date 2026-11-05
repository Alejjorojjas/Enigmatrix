import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/feedback/feedback_event.dart';
import 'package:tablero_flame/src/game/game_session.dart';
import 'package:tablero_flame/src/settings.dart';

import 'helpers.dart';

void main() {
  late PuzzleCase pc;
  late LoggingRig rig;
  late GameSession s;

  /// Primera casilla libre (ocupable) que no esté en la solución.
  int freeCell() => pc.map.occupiableCells
      .firstWhere((c) => !pc.solution.positions.values.contains(c));

  setUp(() {
    pc = loadCase('caso-principiante-s1');
    rig = LoggingRig();
    s = rig.session(pc);
  });

  group('colocar con las reglas de board_state', () {
    test('tocar sin sospechoso elegido avisa y no cambia el tablero', () {
      s.tapCell(freeCell());
      final e = rig.eventsOf<PlacementRejected>().single;
      expect(e.problem, PlacementProblem.noSuspect);
      expect(s.board.isEmpty, isTrue);
    });

    test('elegir sospechoso y tocar = candidato', () {
      s.selectSuspect('c1');
      final cell = freeCell();
      s.tapCell(cell);
      expect(rig.eventsOf<SuspectTapped>().single.selected, isTrue);
      expect(rig.eventsOf<CandidateNoted>().single.cell, cell);
      expect(s.board.cell(cell).candidates, {'c1'});
    });

    test('volver a tocar el mismo sospechoso lo suelta', () {
      s.selectSuspect('c1');
      s.selectSuspect('c1');
      expect(s.selectedChar, isNull);
      expect(rig.eventsOf<SuspectTapped>().last.selected, isFalse);
    });

    test('mantener oprimido = confirmar, con la fila y la columna tachadas en ola',
        () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.holdCell(cell);
      expect(rig.eventsOf<Confirmed>().single.cell, cell);
      expect(s.board.cell(cell).confirmed, 'c1');
      final crossed = rig.eventsOf<LinesCrossed>().single;
      expect(crossed.cells.length, 2 * (s.size - 1));
      // De la más cercana a la más lejana.
      int dist(int c) =>
          (c ~/ s.size - cell ~/ s.size).abs() + (c % s.size - cell % s.size).abs();
      for (var i = 1; i < crossed.cells.length; i++) {
        expect(dist(crossed.cells[i]) >= dist(crossed.cells[i - 1]), isTrue);
      }
    });

    test('sin tachado automático no hay ola', () {
      rig.settings.autoX = false;
      s.selectSuspect('c1');
      s.holdCell(freeCell());
      expect(rig.eventsOf<LinesCrossed>(), isEmpty);
    });

    test('doble toque (regla 20): el segundo toque confirma', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.tapCell(cell);
      s.tapCell(cell);
      expect(rig.eventsOf<CandidateNoted>(), hasLength(1));
      expect(rig.eventsOf<Confirmed>(), hasLength(1));
      expect(s.board.cell(cell).confirmed, 'c1');
      expect(s.board.cell(cell).candidates, isEmpty);
    });

    test('con el doble toque apagado, el segundo toque no hace nada', () {
      rig.settings.doubleTapConfirm = false;
      final cell = freeCell();
      s.selectSuspect('c1');
      s.tapCell(cell);
      s.tapCell(cell);
      expect(rig.eventsOf<Confirmed>(), isEmpty);
      expect(rig.eventsOf<CandidateNoted>(), hasLength(1));
    });

    test('una casilla con ficha rechaza otra ficha', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.holdCell(cell);
      s.selectSuspect('c2');
      s.holdCell(cell);
      expect(rig.eventsOf<PlacementRejected>().last.problem,
          PlacementProblem.cellHasConfirmed);
      expect(s.board.cell(cell).confirmed, 'c1');
    });

    test('un sospechoso ya colocado no se coloca en otra casilla', () {
      final cells = pc.map.occupiableCells
          .where((c) => !pc.solution.positions.values.contains(c))
          .take(2)
          .toList();
      rig.settings.autoX = false;
      s.selectSuspect('c1');
      s.holdCell(cells[0]);
      s.holdCell(cells[1]);
      expect(rig.eventsOf<PlacementRejected>().last.problem,
          PlacementProblem.alreadyPlaced);
    });

    test('los muebles que bloquean no admiten fichas', () {
      final blocked = pc.map.objects.firstWhere((o) => o.blocks).cells.first;
      s.selectSuspect('c1');
      s.holdCell(blocked);
      expect(rig.eventsOf<PlacementRejected>().single.problem,
          PlacementProblem.blocked);
      expect(s.board.isEmpty, isTrue);
    });

    test('el borrador limpia la casilla y deshacer la recupera', () {
      final cell = freeCell();
      s.selectSuspect('c1');
      s.holdCell(cell);
      s.toggleEraser();
      s.tapCell(cell);
      expect(rig.eventsOf<Erased>().single.cell, cell);
      expect(s.board.cell(cell).isEmpty, isTrue);
      s.undo();
      expect(s.board.cell(cell).confirmed, 'c1');
    });
  });

  group('resolver', () {
    void placeSolution({Map<String, int>? override}) {
      final pos = override ?? pc.solution.positions;
      for (final e in pos.entries) {
        s.selectSuspect(e.key);
        s.holdCell(e.value);
      }
    }

    test('con el tablero incompleto avisa cuántos faltan', () {
      s.solve();
      expect(rig.eventsOf<SolveIncomplete>().single.missing, pc.characters.length);
      expect(s.errors, 0);
    });

    test('regla 9: un error dice solo CUÁNTAS casillas no cuadran', () {
      final pos = Map<String, int>.from(pc.solution.positions);
      final ids = pos.keys.toList();
      final a = ids[0], b = ids[1];
      final tmp = pos[a]!;
      pos[a] = pos[b]!;
      pos[b] = tmp; // dos personajes intercambiados
      placeSolution(override: pos);
      s.solve();
      final f = rig.eventsOf<SolveFailed>().single;
      expect(f.wrongCells, 2);
      expect(s.errors, 1);
      expect(s.solved, isFalse);
      // Se puede seguir jugando: no hay bloqueo tras el error.
      s.selectSuspect(a);
      expect(s.selectedChar, a);
    });

    test('resolver bien revela al asesino y cierra el tablero', () {
      placeSolution();
      s.solve();
      expect(s.solved, isTrue);
      final ok = rig.eventsOf<SolveSucceeded>().single.reveal;
      expect(ok.murdererId, pc.solution.murdererId);
      expect(ok.murdererCell, pc.solution.positions[pc.solution.murdererId]);
      expect(ok.victimCell, pc.solution.positions[pc.victimId]);
      expect(ok.innocentCells, hasLength(pc.characters.length - 2));
      expect(ok.gridSize, pc.map.size);
      // Ya resuelto, los toques no cambian nada.
      final before = s.board;
      s.tapCell(freeCell());
      expect(identical(s.board, before), isTrue);
    });

    test('llenar para medir deja el tablero listo para Resolver', () {
      s.autofillForMeasuring();
      s.solve();
      expect(s.solved, isTrue);
    });
  });

  test('el caso de 8x8 también se resuelve con las mismas reglas', () {
    final pc8 = loadCase('caso-casual-s1');
    final s8 = rig.session(pc8);
    s8.autofillForMeasuring();
    s8.solve();
    expect(s8.solved, isTrue);
    expect(rig.eventsOf<SolveSucceeded>().single.reveal.gridSize, 8);
  });

  test('settings: tope de partículas se mantiene entre 0 y 150', () {
    final st = GameSettings();
    st.particleCap = 999;
    expect(st.particleCap, 150);
    st.particleCap = -3;
    expect(st.particleCap, 0);
  });
}
