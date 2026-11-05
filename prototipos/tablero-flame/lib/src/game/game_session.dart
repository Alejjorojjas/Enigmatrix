/// Una partida del prototipo: tablero, sospechoso elegido, errores y tiempo.
/// Las reglas de colocación NO se reescriben aquí: salen de `board_state.dart`
/// (copia fija de la app) y la validación del motor de puzzles (`Validator`).
/// Cada cosa que pasa se le cuenta al director de feedback.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/foundation.dart';

import '../../board_state.dart';
import '../feedback/feedback_director.dart';
import '../feedback/feedback_event.dart';
import '../settings.dart';

/// Herramienta activa de la barra.
/// - notas: toque = anotar candidato, mantener = confirmar (lo de siempre).
/// - tachar: toque = X a mano (otro toque la quita).
/// - colocar: toque = confirmar directamente.
/// - borrar: toque = limpiar la casilla.
enum ToolMode { notes, cross, place, erase }

class GameSession extends ChangeNotifier {
  GameSession({
    required this.pc,
    required this.director,
    required this.settings,
  });

  final PuzzleCase pc;
  final FeedbackDirector director;
  final GameSettings settings;

  BoardState board = BoardState.empty();
  final List<BoardState> _undo = [];

  /// Sospechoso elegido en la bandeja (null si ninguno).
  String? selectedChar;
  ToolMode tool = ToolMode.notes;

  /// Borrador activo (compatibilidad con la barra anterior).
  bool get eraser => tool == ToolMode.erase;

  /// Las casillas candidatas se resaltan con Anotar y Confirmar.
  bool get highlightsCandidates =>
      tool == ToolMode.notes || tool == ToolMode.place;

  int errors = 0;
  int elapsedSeconds = 0;
  bool solved = false;
  RevealData? reveal;

  int get size => pc.map.size;

  List<String> get charIds => [for (final c in pc.characters) c.id];

  int indexOfChar(String id) => pc.characters.indexWhere((c) => c.id == id);

  bool get canUndo => _undo.isNotEmpty && !solved;

  // ---- bandeja ---------------------------------------------------------------

  void selectSuspect(String charId) {
    if (solved) return;
    if (tool == ToolMode.erase || tool == ToolMode.cross) tool = ToolMode.notes;
    final nowSelected = selectedChar != charId;
    selectedChar = nowSelected ? charId : null;
    director.handle(SuspectTapped(charId, selected: nowSelected));
    notifyListeners();
  }

  void toggleEraser() =>
      setTool(tool == ToolMode.erase ? ToolMode.notes : ToolMode.erase);

  /// Cambia de herramienta. Tachar y borrar sueltan al sospechoso elegido.
  void setTool(ToolMode mode) {
    if (solved || tool == mode) return;
    tool = mode;
    if (mode == ToolMode.erase || mode == ToolMode.cross) selectedChar = null;
    notifyListeners();
  }

  // ---- toques en el tablero ---------------------------------------------------

  /// Toque corto: candidato (o borrar, o confirmar con doble toque).
  void tapCell(int cell) {
    if (solved) return;
    if (!pc.map.isOccupiable(cell)) {
      director.handle(
          const PlacementRejected(PlacementProblem.blocked));
      return;
    }
    if (tool == ToolMode.erase) {
      _erase(cell);
      return;
    }
    if (tool == ToolMode.cross) {
      _cross(cell);
      return;
    }
    final id = selectedChar;
    if (id == null) {
      director.handle(
          PlacementRejected(PlacementProblem.noSuspect, cell: cell));
      return;
    }
    // Confirmar: el toque confirma directamente.
    if (tool == ToolMode.place) {
      _confirm(cell, id);
      return;
    }
    // Modo alternativo de tocar dos veces (regla 20): segundo toque en la
    // misma casilla con el mismo sospechoso = confirmar.
    if (settings.doubleTapConfirm &&
        board.cell(cell).candidates.contains(id)) {
      _confirm(cell, id);
      return;
    }
    final result = board.placeCandidate(cell, id);
    switch (result.outcome) {
      case PlaceOutcome.placed:
        _apply(result.board);
        director.handle(CandidateNoted(cell, id));
      case PlaceOutcome.noChange:
        break;
      case PlaceOutcome.rejectedByConfirmed:
        director.handle(PlacementRejected(PlacementProblem.cellHasConfirmed,
            cell: cell));
      case PlaceOutcome.rejectedByX:
        director.handle(
            PlacementRejected(PlacementProblem.cellHasX, cell: cell));
      case PlaceOutcome.alreadyConfirmedElsewhere:
      case PlaceOutcome.needsReplaceConfirmation:
        break; // no se dan al anotar candidatos
    }
  }

  /// Mantener oprimido: confirmar.
  void holdCell(int cell) {
    if (solved) return;
    if (!pc.map.isOccupiable(cell)) {
      director.handle(
          const PlacementRejected(PlacementProblem.blocked));
      return;
    }
    if (tool == ToolMode.erase) {
      _erase(cell);
      return;
    }
    if (tool == ToolMode.cross) {
      _cross(cell);
      return;
    }
    final id = selectedChar;
    if (id == null) {
      director.handle(
          PlacementRejected(PlacementProblem.noSuspect, cell: cell));
      return;
    }
    _confirm(cell, id);
  }

  void _confirm(int cell, String id) {
    final before = board;
    final result = board.placeConfirmed(cell, id,
        autoXGridSize: settings.autoX ? size : null);
    switch (result.outcome) {
      case PlaceOutcome.placed:
        _apply(result.board);
        director.handle(Confirmed(cell, id));
        if (settings.autoX) {
          final crossed = _newlyCrossed(before, result.board, id, cell);
          director.handle(LinesCrossed(cell, crossed));
        }
      case PlaceOutcome.noChange:
        break;
      case PlaceOutcome.rejectedByConfirmed:
      case PlaceOutcome.needsReplaceConfirmation:
        director.handle(PlacementRejected(PlacementProblem.cellHasConfirmed,
            cell: cell));
      case PlaceOutcome.rejectedByX:
        director.handle(
            PlacementRejected(PlacementProblem.cellHasX, cell: cell));
      case PlaceOutcome.alreadyConfirmedElsewhere:
        director.handle(
            PlacementRejected(PlacementProblem.alreadyPlaced, cell: cell));
    }
  }

  /// Tachar a mano: pone una X; si ya había una X a mano, la quita.
  void _cross(int cell) {
    final c = board.cell(cell);
    if (c.confirmed != null) {
      director.handle(
          PlacementRejected(PlacementProblem.cellHasConfirmed, cell: cell));
      return;
    }
    if (c.x != null) {
      _erase(cell);
      return;
    }
    final r = board.placeX(cell, XLevel.small);
    if (r.outcome == PlaceOutcome.placed) {
      _apply(r.board);
      director.handle(CrossMarked(cell));
    }
  }

  void _erase(int cell) {
    final next = board.eraseCell(cell);
    if (identical(next, board)) return;
    _apply(next);
    director.handle(Erased(cell));
  }

  /// Casillas que ganaron una X automática de [charId], de la más cercana a
  /// la más lejana del origen (así se ve la ola).
  List<int> _newlyCrossed(
      BoardState before, BoardState after, String charId, int origin) {
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

  void _apply(BoardState next) {
    _undo.add(board);
    if (_undo.length > 50) _undo.removeAt(0);
    board = next;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    board = _undo.removeLast();
    notifyListeners();
  }

  // ---- resolver ---------------------------------------------------------------

  void solve() {
    if (solved) return;
    final positions = board.confirmedPositions(charIds);
    if (positions == null) {
      final placed = {
        for (final c in board.confirmedCells) board.cell(c).confirmed
      };
      final missing = charIds.where((id) => !placed.contains(id)).length;
      director.handle(SolveIncomplete(missing == 0 ? 1 : missing));
      return;
    }
    final v = Validator.validate(pc, positions);
    if (!v.valid) {
      // Regla 9 (ADR-0012): solo se dice CUÁNTAS casillas no cuadran.
      // En Fase 1 la comparación usa la solución local (riesgo aceptado).
      var wrong = 0;
      for (final e in positions.entries) {
        if (pc.solution.positions[e.key] != e.value) wrong++;
      }
      errors++;
      notifyListeners();
      director.handle(SolveFailed(wrong == 0 ? 1 : wrong));
      return;
    }
    solved = true;
    selectedChar = null;
    tool = ToolMode.notes;
    final murdererId = v.murdererId!;
    final murdererCell = positions[murdererId]!;
    final victimCell = positions[pc.victimId]!;
    reveal = RevealData(
      gridSize: size,
      murdererCell: murdererCell,
      victimCell: victimCell,
      murdererId: murdererId,
      murdererName: pc.character(murdererId).nameEs,
      innocentCells: [
        for (final e in positions.entries)
          if (e.key != murdererId && e.key != pc.victimId) e.value
      ],
    );
    notifyListeners();
    director.handle(SolveSucceeded(reveal!));
  }

  /// SOLO PARA MEDIR: pone a todos los personajes en su casilla correcta, sin
  /// efectos, para poder probar la secuencia de resolver sin deducir el caso.
  /// Usa la solución que el JSON local trae en la Fase 1 (excepción vigente).
  void autofillForMeasuring() {
    if (solved) return;
    var b = BoardState.empty();
    for (final e in pc.solution.positions.entries) {
      b = b.placeConfirmed(e.value, e.key).board;
    }
    _undo.add(board);
    board = b;
    selectedChar = null;
    notifyListeners();
  }

  void tickSecond() {
    if (solved) return;
    elapsedSeconds++;
    notifyListeners();
  }
}
