/// Une lo que hace el jugador en el tablero con el [GameController] (las
/// reglas) y con el director de feedback (animación, sonido y vibración).
///
/// El controlador decide y devuelve un [ActionFeedback]; aquí se compara el
/// tablero de antes con el de después para contarle al director QUÉ pasó
/// (anotó, confirmó, tachó, borró, rechazó...). Así las reglas siguen en un
/// solo sitio y los efectos no dependen de Flame: se prueba sin pantalla.
library;

import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

import '../board/feedback/feedback_director.dart';
import '../board/feedback/feedback_event.dart';
import 'board_state.dart';
import 'game_controller.dart';

class BoardInteraction {
  BoardInteraction({
    required this.controller,
    required this.read,
    required this.director,
    required this.confirmReplace,
    this.doubleTapConfirm = true,
  });

  final GameController controller;

  /// Estado actual de la partida (`ref.read(gameControllerProvider(pc))`).
  final GameState Function() read;
  final FeedbackDirector director;

  /// Pregunta si se reemplaza la ficha de una casilla (la UI abre el diálogo).
  final Future<bool> Function() confirmReplace;

  /// Modo alternativo de la regla 20 del ADR-0012: con Anotar, tocar otra vez
  /// la misma casilla con el mismo sospechoso la confirma.
  final bool doubleTapConfirm;

  PuzzleCase get _pc => read().pc;

  // ---- retratos -----------------------------------------------------------------

  void selectSuspect(String charId) {
    if (read().solved) return;
    controller.tapSuspect(charId);
    director.handle(
      SuspectTapped(charId, selected: read().selectedChar == charId),
    );
  }

  // ---- tablero ------------------------------------------------------------------

  /// Toque corto sobre una casilla.
  void tapCell(int cell) => _press(cell, hold: false);

  /// Mantener oprimida una casilla.
  void holdCell(int cell) => _press(cell, hold: true);

  void _press(int cell, {required bool hold}) {
    final before = read();
    final id = before.selectedChar;
    var confirm = hold;
    if (!hold &&
        doubleTapConfirm &&
        before.toolMode == ToolMode.notes &&
        id != null &&
        before.board.cell(cell).candidates.contains(id)) {
      confirm = true;
    }
    final fb = controller.placeAt(cell, confirm: confirm);
    switch (fb) {
      case ActionFeedback.ok:
        _emitChange(before, read(), cell);
      case ActionFeedback.blockedCell:
        director.handle(const PlacementRejected(PlacementProblem.blocked));
      case ActionFeedback.noToolSelected:
        director.handle(
          PlacementRejected(PlacementProblem.noSuspect, cell: cell),
        );
      case ActionFeedback.cellHasConfirmed:
        director.handle(
          PlacementRejected(PlacementProblem.cellHasConfirmed, cell: cell),
        );
      case ActionFeedback.cellHasX:
        director.handle(
          PlacementRejected(PlacementProblem.cellHasX, cell: cell),
        );
      case ActionFeedback.alreadyConfirmedElsewhere:
        director.handle(
          PlacementRejected(PlacementProblem.alreadyPlaced, cell: cell),
        );
      case ActionFeedback.askReplaceConfirmed:
        if (id != null) _askReplace(cell, id);
      case ActionFeedback.incompleteBoard:
      case ActionFeedback.wrongSolution:
      case ActionFeedback.solvedOk:
        break; // no salen de colocar
    }
  }

  Future<void> _askReplace(int cell, String charId) async {
    final yes = await confirmReplace();
    if (!yes) return;
    final before = read();
    controller.placeSuspect(cell, charId: charId, confirm: true, replace: true);
    _emitChange(before, read(), cell);
  }

  /// Compara el tablero de antes y de después y se lo cuenta al director.
  void _emitChange(GameState before, GameState after, int cell) {
    if (identical(before.board, after.board)) return;
    final b = before.board.cell(cell);
    final a = after.board.cell(cell);

    final placedId = a.confirmed;
    if (placedId != null && placedId != b.confirmed) {
      director.handle(Confirmed(cell, placedId));
      final crossed = newlyCrossed(
        before.board,
        after.board,
        placedId,
        cell,
        after.pc.map.size,
      );
      if (crossed.isNotEmpty) director.handle(LinesCrossed(cell, crossed));
      return;
    }
    final added = a.candidates.difference(b.candidates);
    if (a.confirmed == null && added.isNotEmpty) {
      director.handle(CandidateNoted(cell, added.first));
      return;
    }
    if (a.x != null && b.x == null && a.confirmed == null) {
      director.handle(CrossMarked(cell));
      return;
    }
    director.handle(Erased(cell));
  }

  /// Casillas que ganaron una X automática de [charId], de la más cercana a
  /// la más lejana del origen (así se ve la ola).
  static List<int> newlyCrossed(
    BoardState before,
    BoardState after,
    String charId,
    int origin,
    int size,
  ) {
    final out = <int>[];
    for (var i = 0; i < size * size; i++) {
      if (i == origin) continue;
      final had = before.cell(i).autoXFrom.contains(charId);
      final has = after.cell(i).autoXFrom.contains(charId);
      if (has && !had) out.add(i);
    }
    int dist(int c) =>
        (c ~/ size - origin ~/ size).abs() + (c % size - origin % size).abs();
    out.sort((a, b) {
      final d = dist(a).compareTo(dist(b));
      return d != 0 ? d : a.compareTo(b);
    });
    return out;
  }

  // ---- resolver -----------------------------------------------------------------

  /// Resolver. [revealCells] es solo del tutorial (regla 9): señala las
  /// casillas que no cuadran.
  ActionFeedback solve({bool revealCells = false}) {
    final fb = controller.solve(revealCells: revealCells);
    final s = read();
    switch (fb) {
      case ActionFeedback.incompleteBoard:
        final placed = {
          for (final c in s.board.confirmedCells) s.board.cell(c).confirmed,
        };
        final missing = _pc.characters
            .where((c) => !placed.contains(c.id))
            .length;
        director.handle(SolveIncomplete(math.max(1, missing)));
      case ActionFeedback.wrongSolution:
        director.handle(SolveFailed(math.max(1, s.wrongCount)));
      case ActionFeedback.solvedOk:
        director.handle(SolveSucceeded(revealDataOf(s)));
      default:
        break;
    }
    return fb;
  }

  /// Datos de la secuencia de revelar, a partir de una partida resuelta.
  static RevealData revealDataOf(GameState s) {
    final pc = s.pc;
    final positions = s.board.confirmedPositions(
      pc.characters.map((c) => c.id),
    )!;
    final murdererId = s.murdererId!;
    return RevealData(
      gridSize: pc.map.size,
      murdererCell: positions[murdererId]!,
      victimCell: positions[pc.victimId]!,
      murdererId: murdererId,
      murdererName: pc.character(murdererId).nameEs,
      innocentCells: [
        for (final e in positions.entries)
          if (e.key != murdererId && e.key != pc.victimId) e.value,
      ],
    );
  }
}
