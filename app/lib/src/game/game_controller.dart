/// Controlador de partida: tablero + cronómetro + errores + resolver.
/// Flujos: docs/02-flujo.md ("Flujo dentro de partida") y docs/03.
/// Interacción 2026-06-11: tap = candidato (letra), mantener oprimido o
/// arrastrar = confirmado (círculo con avatar) + auto-X opcional.
library;

import 'dart:async';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'board_state.dart';

/// Herramienta seleccionada en el panel.
sealed class Tool {
  const Tool();
}

class SuspectTool extends Tool {
  final String charId;
  const SuspectTool(this.charId);
}

class XTool extends Tool {
  final XLevel level;
  const XTool(this.level);
}

/// Borrador: tocar una casilla la limpia por completo.
class EraserTool extends Tool {
  const EraserTool();
}

/// Estado de una pista: ciclo normal -> destacada -> tachada -> normal.
enum ClueMark { normal, highlighted, struck }

class GameState {
  final PuzzleCase pc;
  final BoardState board;
  final List<ClueMark> clueMarks;
  final Tool? tool;
  final int elapsedSeconds;
  final int errorCount;
  final bool locked; // bloqueo temporal tras error (doc 03)
  final Set<int> errorCells;
  final bool solved;
  final String? murdererId; // revelado al resolver correcto
  final String? lethalWeaponId;
  final bool mapMode; // true = mapa · false = vista lógica (notas)
  final bool autoX; // tachar fila/columna al confirmar (opción)
  final bool canUndo;
  final bool canRedo;

  const GameState({
    required this.pc,
    required this.board,
    required this.clueMarks,
    this.tool,
    this.elapsedSeconds = 0,
    this.errorCount = 0,
    this.locked = false,
    this.errorCells = const {},
    this.solved = false,
    this.murdererId,
    this.lethalWeaponId,
    this.mapMode = true,
    this.autoX = true,
    this.canUndo = false,
    this.canRedo = false,
  });

  GameState copyWith({
    BoardState? board,
    List<ClueMark>? clueMarks,
    Tool? Function()? tool,
    int? elapsedSeconds,
    int? errorCount,
    bool? locked,
    Set<int>? errorCells,
    bool? solved,
    String? murdererId,
    String? lethalWeaponId,
    bool? mapMode,
    bool? autoX,
    bool? canUndo,
    bool? canRedo,
  }) =>
      GameState(
        pc: pc,
        board: board ?? this.board,
        clueMarks: clueMarks ?? this.clueMarks,
        tool: tool != null ? tool() : this.tool,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        errorCount: errorCount ?? this.errorCount,
        locked: locked ?? this.locked,
        errorCells: errorCells ?? this.errorCells,
        solved: solved ?? this.solved,
        murdererId: murdererId ?? this.murdererId,
        lethalWeaponId: lethalWeaponId ?? this.lethalWeaponId,
        mapMode: mapMode ?? this.mapMode,
        autoX: autoX ?? this.autoX,
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
      );
}

/// Resultado de una acción para que la UI reaccione (mensajes/diálogos).
enum ActionFeedback {
  ok,
  cellHasConfirmed, // mensaje del doc 03
  cellHasX, // casilla descartada: no acepta candidatos
  alreadyConfirmedElsewhere, // ese personaje ya está fijado en otra casilla
  askReplaceConfirmed, // diálogo de confirmación
  incompleteBoard, // falta confirmar personajes
  wrongSolution,
  solvedOk,
}

class GameController extends AutoDisposeFamilyNotifier<GameState, PuzzleCase> {
  static const _undoLimit = 50; // doc 08: historial de 50 acciones
  final List<BoardState> _undo = [];
  final List<BoardState> _redo = [];
  Timer? _ticker;
  Timer? _unlockTimer;

  @override
  GameState build(PuzzleCase arg) {
    ref.onDispose(() {
      _ticker?.cancel();
      _unlockTimer?.cancel();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.solved) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
    return GameState(
      pc: arg,
      board: BoardState.empty(),
      clueMarks: List.filled(arg.clues.length, ClueMark.normal),
    );
  }

  // ---- selección de herramienta --------------------------------------------

  void tapSuspect(String charId) {
    final t = state.tool;
    state = state.copyWith(
      tool: () =>
          (t is SuspectTool && t.charId == charId) ? null : SuspectTool(charId),
    );
  }

  void tapX() {
    final t = state.tool;
    if (t is XTool) {
      state = state.copyWith(
        tool: () => t.level == XLevel.small ? const XTool(XLevel.large) : null,
      );
    } else {
      state = state.copyWith(tool: () => const XTool(XLevel.small));
    }
  }

  void tapEraser() {
    state = state.copyWith(
      tool: () => state.tool is EraserTool ? null : const EraserTool(),
    );
  }

  void toggleAutoX() => state = state.copyWith(autoX: !state.autoX);

  // ---- colocación ----------------------------------------------------------

  bool get _editable => !state.locked && !state.solved;

  /// Coloca con la herramienta seleccionada. [confirm] viene del gesto:
  /// tap = candidato, mantener oprimido / arrastrar = confirmado.
  ActionFeedback placeAt(int cell, {required bool confirm}) {
    final t = state.tool;
    if (t == null || !_editable) return ActionFeedback.ok;
    return switch (t) {
      SuspectTool(:final charId) =>
        placeSuspect(cell, charId: charId, confirm: confirm),
      XTool(:final level) => placeXMark(cell, level),
      EraserTool() => eraseCell(cell),
    };
  }

  /// Borrador: limpia la casilla completa (incluye X automáticas del
  /// confirmado borrado).
  ActionFeedback eraseCell(int cell) {
    if (!_editable) return ActionFeedback.ok;
    final next = state.board.eraseCell(cell);
    if (identical(next, state.board)) return ActionFeedback.ok;
    _pushUndo();
    state = state.copyWith(board: next, canUndo: true, canRedo: false);
    return ActionFeedback.ok;
  }

  ActionFeedback placeSuspect(int cell,
      {required String charId, required bool confirm, bool replace = false}) {
    if (!_editable) return ActionFeedback.ok;
    final result = confirm
        ? state.board.placeConfirmed(cell, charId,
            replace: replace,
            autoXGridSize: state.autoX ? state.pc.map.size : null)
        : state.board.placeCandidate(cell, charId);
    return _applyPlace(result);
  }

  ActionFeedback placeXMark(int cell, XLevel level) {
    if (!_editable) return ActionFeedback.ok;
    return _applyPlace(state.board.placeX(cell, level));
  }

  ActionFeedback _applyPlace(PlaceResult result) {
    switch (result.outcome) {
      case PlaceOutcome.placed:
        _pushUndo();
        state =
            state.copyWith(board: result.board, canUndo: true, canRedo: false);
        return ActionFeedback.ok;
      case PlaceOutcome.noChange:
        return ActionFeedback.ok;
      case PlaceOutcome.rejectedByConfirmed:
        return ActionFeedback.cellHasConfirmed;
      case PlaceOutcome.rejectedByX:
        return ActionFeedback.cellHasX;
      case PlaceOutcome.alreadyConfirmedElsewhere:
        return ActionFeedback.alreadyConfirmedElsewhere;
      case PlaceOutcome.needsReplaceConfirmation:
        return ActionFeedback.askReplaceConfirmed;
    }
  }

  void removeElement(int cell, CellElement element) {
    if (!_editable) return;
    final next = state.board.removeElement(cell, element);
    if (identical(next, state.board)) return;
    _pushUndo();
    state = state.copyWith(board: next, canUndo: true, canRedo: false);
  }

  void _pushUndo() {
    _undo.add(state.board);
    if (_undo.length > _undoLimit) _undo.removeAt(0); // doc 08
    _redo.clear();
  }

  // ---- deshacer / rehacer / limpiar (doc 03) -------------------------------

  void undo() {
    if (_undo.isEmpty || !_editable) return;
    _redo.add(state.board);
    state = state.copyWith(
      board: _undo.removeLast(),
      canUndo: _undo.isNotEmpty,
      canRedo: true,
    );
  }

  void redo() {
    if (_redo.isEmpty || !_editable) return;
    _undo.add(state.board);
    state = state.copyWith(
      board: _redo.removeLast(),
      canUndo: true,
      canRedo: _redo.isNotEmpty,
    );
  }

  /// Limpiar tablero (doc 03): borra tablero y marcas de pistas; mantiene
  /// tiempo y errores. La UI pide confirmación antes.
  void clearBoard() {
    if (!_editable) return;
    _undo.clear();
    _redo.clear();
    state = state.copyWith(
      board: BoardState.empty(),
      clueMarks: List.filled(state.pc.clues.length, ClueMark.normal),
      canUndo: false,
      canRedo: false,
    );
  }

  // ---- pistas (doc 03: ciclo normal -> destacada -> tachada) ---------------

  void cycleClue(int index) {
    final next = [...state.clueMarks];
    next[index] =
        ClueMark.values[(next[index].index + 1) % ClueMark.values.length];
    state = state.copyWith(clueMarks: next);
  }

  void toggleMapMode() => state = state.copyWith(mapMode: !state.mapMode);

  // ---- resolver (doc 03) ----------------------------------------------------

  ActionFeedback solve() {
    if (!_editable) return ActionFeedback.ok;
    final positions =
        state.board.confirmedPositions(state.pc.characters.map((c) => c.id));
    if (positions == null) return ActionFeedback.incompleteBoard;

    final v = Validator.validate(state.pc, positions);
    if (v.valid) {
      _ticker?.cancel();
      state = state.copyWith(
        solved: true,
        murdererId: v.murdererId,
        lethalWeaponId: v.lethalWeaponId,
        errorCells: const {},
        tool: () => null,
      );
      return ActionFeedback.solvedOk;
    }

    // Resaltado de casillas incorrectas: en Fase 1 se compara contra la
    // solución local (en Fase 2 esto lo responde el servidor).
    final wrong = <int>{
      for (final e in positions.entries)
        if (state.pc.solution.positions[e.key] != e.value) e.value
    };
    state = state.copyWith(
      errorCount: state.errorCount + 1,
      errorCells: wrong,
      locked: true,
    );
    _unlockTimer?.cancel();
    _unlockTimer = Timer(const Duration(seconds: 3), () {
      state = state.copyWith(locked: false, errorCells: const {});
    });
    return ActionFeedback.wrongSolution;
  }
}

final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameState, PuzzleCase>(GameController.new);
