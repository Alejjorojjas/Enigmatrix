/// Controlador de partida: tablero + cronómetro + errores + resolver.
/// Flujos: docs/02-flujo.md ("Flujo dentro de partida") y docs/03.
/// Herramientas del ADR-0013: Anotar (toque = candidato, mantener oprimido =
/// confirmar), Tachar (X a mano), Confirmar (un toque) y Borrar.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend_config.dart' show isServerCaseId;
import '../backend/validation_client.dart';
import '../backend/validation_providers.dart';
import '../backend/validation_service.dart';
import '../data/case_repository.dart' show kTutorialCaseId;
import 'board_state.dart';
import 'game_config.dart';
import 'saved_game.dart';

/// Estado del ciclo de vida de la app (lo publica main.dart). Al pasar a
/// segundo plano, la partida en pantalla se pausa y se guarda (regla 10).
final appLifecycleProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
);

/// Herramienta activa de la barra (ADR-0013):
///  - notes (Anotar): toque = candidato; mantener oprimido = confirmar.
///  - cross (Tachar): toque = X a mano; otro toque la quita.
///  - place (Confirmar): un toque confirma al sospechoso elegido.
///  - erase (Borrar): toque = limpiar la casilla.
enum ToolMode { notes, cross, place, erase }

/// Estado de una pista: ciclo normal -> destacada -> tachada -> normal.
enum ClueMark { normal, highlighted, struck }

class GameState {
  final PuzzleCase pc;
  final BoardState board;
  final List<ClueMark> clueMarks;

  /// Herramienta activa de la barra y sospechoso elegido en los retratos.
  final ToolMode toolMode;
  final String? selectedChar;
  final int elapsedSeconds;
  final int errorCount;
  final bool locked; // bloqueo temporal tras error (doc 03)
  final Set<int> errorCells;
  final bool solved;

  /// El caso está resuelto y el jugador sigue mirando el tablero (solo
  /// lectura): se ven las pistas y se cambia entre Mapa y Notas.
  final bool reviewing;
  final String? murdererId; // revelado al resolver correcto
  final String? lethalWeaponId;
  final bool mapMode; // true = mapa · false = vista lógica (notas)
  final bool autoX; // tachar fila/columna al confirmar (opción)
  final bool canUndo;
  final bool canRedo;

  /// Casillas que no cuadran tras un Resolver fallido (regla 9). Solo se
  /// conserva mientras dura el bloqueo; no dice cuáles son.
  final int wrongCount;

  /// true mientras se lee la partida guardada (el reloj aún no corre).
  final bool loading;

  /// Partida en pausa (app en segundo plano): el tablero queda tapado y el
  /// reloj detenido hasta que el jugador toque Continuar.
  final bool paused;

  /// Esperando la respuesta del servidor a Resolver (modo servidor).
  final bool submitting;

  /// Resolver se envió sin conexión: el tablero queda "por validar" y se
  /// valida en cuanto haya señal (ADR-0016).
  final bool pendingValidation;

  /// El envío "por validar" se detuvo tras errores seguidos del servidor: el
  /// jugador elige Reintentar o Cancelar envío.
  final bool validationStalled;

  const GameState({
    required this.pc,
    required this.board,
    required this.clueMarks,
    this.toolMode = ToolMode.notes,
    this.selectedChar,
    this.elapsedSeconds = 0,
    this.errorCount = 0,
    this.locked = false,
    this.errorCells = const {},
    this.solved = false,
    this.reviewing = false,
    this.murdererId,
    this.lethalWeaponId,
    this.mapMode = true,
    this.autoX = true,
    this.canUndo = false,
    this.canRedo = false,
    this.wrongCount = 0,
    this.loading = false,
    this.paused = false,
    this.submitting = false,
    this.pendingValidation = false,
    this.validationStalled = false,
  });

  GameState copyWith({
    BoardState? board,
    List<ClueMark>? clueMarks,
    ToolMode? toolMode,
    String? Function()? selectedChar,
    int? elapsedSeconds,
    int? errorCount,
    bool? locked,
    Set<int>? errorCells,
    bool? solved,
    bool? reviewing,
    String? murdererId,
    String? lethalWeaponId,
    bool? mapMode,
    bool? autoX,
    bool? canUndo,
    bool? canRedo,
    int? wrongCount,
    bool? loading,
    bool? paused,
    bool? submitting,
    bool? pendingValidation,
    bool? validationStalled,
  }) => GameState(
    pc: pc,
    board: board ?? this.board,
    clueMarks: clueMarks ?? this.clueMarks,
    toolMode: toolMode ?? this.toolMode,
    selectedChar: selectedChar != null ? selectedChar() : this.selectedChar,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    errorCount: errorCount ?? this.errorCount,
    locked: locked ?? this.locked,
    errorCells: errorCells ?? this.errorCells,
    solved: solved ?? this.solved,
    reviewing: reviewing ?? this.reviewing,
    murdererId: murdererId ?? this.murdererId,
    lethalWeaponId: lethalWeaponId ?? this.lethalWeaponId,
    mapMode: mapMode ?? this.mapMode,
    autoX: autoX ?? this.autoX,
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    wrongCount: wrongCount ?? this.wrongCount,
    loading: loading ?? this.loading,
    paused: paused ?? this.paused,
    submitting: submitting ?? this.submitting,
    pendingValidation: pendingValidation ?? this.pendingValidation,
    validationStalled: validationStalled ?? this.validationStalled,
  );
}

/// Resultado de una acción para que la UI reaccione (mensajes/diálogos).
enum ActionFeedback {
  ok,
  cellHasConfirmed, // mensaje del doc 03
  cellHasX, // casilla descartada: no acepta candidatos
  alreadyConfirmedElsewhere, // ese personaje ya está fijado en otra casilla
  askReplaceConfirmed, // diálogo de confirmación
  noToolSelected, // casilla tocada sin sospechoso elegido (regla 20)
  blockedCell, // hay un mueble que bloquea la casilla
  incompleteBoard, // falta confirmar personajes
  wrongSolution,
  solvedOk,

  // Solo en modo servidor:
  pendingValidation, // sin conexión: queda "por validar"
  rateLimited, // el servidor pidió esperar un momento
  validationFailed, // el servidor no aceptó el envío
  registrationRequired, // invitado en un caso que pide registro
}

/// Tope del tiempo que se informa al servidor (24 h, backend/validation.ts).
const _kMaxClientElapsedMs = 24 * 60 * 60 * 1000;

/// En producción el reloj corre solo (1 tick por segundo). Los tests lo
/// apagan para llamar a [GameController.tick] a mano y ser deterministas.
final gameTickerEnabledProvider = Provider<bool>((ref) => true);

class GameController extends AutoDisposeFamilyNotifier<GameState, PuzzleCase> {
  /// Valores de juego (H-65): límite de deshacer (doc 08: 50), guardado
  /// periódico del reloj y bloqueo tras Resolver fallido. Se leen una vez al
  /// crear el controlador.
  late GameConfig _config;

  final List<BoardState> _undo = [];
  final List<BoardState> _redo = [];
  Timer? _ticker;
  Timer? _unlockTimer;

  SharedPreferences? _prefs;
  bool _alive = true;

  /// Servicio de validación del servidor. Null en el modo `none`: entonces
  /// todo se valida en el teléfono, como siempre.
  ValidationService? _validation;
  bool _serverCase = false;

  /// true cuando hay algo que vale la pena guardar: el jugador cambió algo
  /// o se restauró una partida. Abrir un caso y salir sin tocar nada no
  /// deja partida guardada.
  bool _touched = false;
  bool _savePending = false;
  Future<void> _io = Future<void>.value();
  Future<void> _ready = Future<void>.value();

  /// Se completa cuando terminó de leerse la partida guardada.
  Future<void> get ready => _ready;

  @override
  GameState build(PuzzleCase arg) {
    _alive = true;
    _config = ref.read(gameConfigProvider);
    // El tutorial y el banco `caso-*` validan siempre en el teléfono.
    _validation = ref.read(validationServiceProvider);
    _serverCase = _validation != null && isServerCaseId(arg.caseId);
    final server = _serverCase ? _validation : null;
    if (server != null) {
      server.activeCases.add(arg.caseId);
      final sub = server.events.listen(_onValidationEvent);
      ref.onDispose(() {
        sub.cancel();
        server.activeCases.remove(arg.caseId);
      });
    }
    ref.onDispose(() {
      _alive = false;
      _ticker?.cancel();
      _unlockTimer?.cancel();
      _saveOnDispose();
    });

    // App a segundo plano: pausa y guarda (regla 10). Al volver NO se
    // reanuda sola: el jugador toca Continuar.
    ref.listen<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.paused ||
          next == AppLifecycleState.inactive ||
          next == AppLifecycleState.hidden) {
        pause();
      }
    });

    // Guardar en cada cambio de lo que se persiste (agrupado por microtarea).
    listenSelf((prev, next) {
      if (prev == null || prev.loading || next.loading || next.solved) return;
      if (!identical(prev.board, next.board) ||
          !identical(prev.clueMarks, next.clueMarks) ||
          prev.errorCount != next.errorCount ||
          prev.autoX != next.autoX ||
          prev.mapMode != next.mapMode) {
        _touched = true;
        _scheduleSave();
      }
    });

    _ready = Future<void>.microtask(_load);
    return GameState(
      pc: arg,
      board: BoardState.empty(),
      clueMarks: List.filled(arg.clues.length, ClueMark.normal),
      loading: true,
    );
  }

  // ---- partida guardada (H-55) ---------------------------------------------

  Future<void> _load() async {
    SharedPreferences? prefs;
    try {
      // El tutorial no guarda, no restaura ni borra "game:" (prefs nulo
      // desactiva toda la persistencia).
      prefs = arg.caseId == kTutorialCaseId
          ? null
          : await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null; // sin almacenamiento: se juega igual, sin guardar
    }
    if (!_alive) return;
    _prefs = prefs;

    // Modo servidor: ¿hay un envío esperando respuesta? Si no, se avisa del
    // inicio (sin bloquear la partida: si falla, la partida sigue).
    var pending = false;
    var stalled = false;
    final server = _serverCase ? _validation : null;
    if (server != null) {
      await server.ready;
      if (!_alive) return;
      pending = server.isPending(arg.caseId);
      stalled = pending && server.isStalled(arg.caseId);
    }

    SavedGame? saved;
    if (prefs != null) {
      try {
        saved = SavedGame.read(
          prefs,
          arg.caseId,
          cellCount: arg.map.size * arg.map.size,
          clueCount: arg.clues.length,
        );
      } catch (_) {
        saved = null; // dato dañado: se empieza de cero
      }
    }
    if (saved != null) {
      _touched = true;
      state = state.copyWith(
        board: saved.board,
        clueMarks: [for (final i in saved.clueMarks) ClueMark.values[i]],
        elapsedSeconds: saved.elapsed,
        errorCount: saved.errors,
        autoX: saved.autoX,
        mapMode: saved.mapMode,
        loading: false,
        pendingValidation: pending,
        validationStalled: stalled,
      );
    } else {
      state = state.copyWith(
        loading: false,
        pendingValidation: pending,
        validationStalled: stalled,
      );
    }
    // Aviso de inicio al servidor, sin frenar la partida. Una partida guardada
    // que ya tiene tiempo y no tiene registro de cómo empezó se da por
    // empezada sin conexión: no entra al ranking.
    if (server != null && !pending) {
      unawaited(
        server.ensureStarted(
          arg.caseId,
          alreadyPlayed: (saved?.elapsed ?? 0) > 0,
        ),
      );
    }
    // Si la app ya está en segundo plano al terminar la carga, queda en
    // pausa y el reloj no arranca.
    final life = ref.read(appLifecycleProvider);
    if (life == AppLifecycleState.paused ||
        life == AppLifecycleState.inactive ||
        life == AppLifecycleState.hidden) {
      state = state.copyWith(paused: true);
    }
    _startTicker();
  }

  SavedGame _snapshot() => SavedGame(
    elapsed: state.elapsedSeconds,
    errors: state.errorCount,
    savedAt: DateTime.now(),
    board: state.board,
    clueMarks: [for (final m in state.clueMarks) m.index],
    autoX: state.autoX,
    mapMode: state.mapMode,
  );

  void _enqueue(Future<Object?> Function() op) {
    _io = _io.then((_) async {
      try {
        await op();
      } catch (_) {
        // Guardar es un cache local: un fallo no debe tumbar la partida.
      }
    });
  }

  void _scheduleSave() {
    if (_savePending) return;
    _savePending = true;
    scheduleMicrotask(() {
      _savePending = false;
      if (_alive) _enqueueSave();
    });
  }

  void _enqueueSave() {
    final prefs = _prefs;
    if (prefs == null || !_touched || state.loading || state.solved) return;
    final raw = _snapshot().encode();
    _enqueue(() => prefs.setString(SavedGame.keyFor(arg.caseId), raw));
  }

  void _saveOnDispose() {
    final prefs = _prefs;
    if (prefs == null || !_touched) return;
    try {
      if (state.loading || state.solved) return;
      final raw = _snapshot().encode();
      _enqueue(() => prefs.setString(SavedGame.keyFor(arg.caseId), raw));
    } catch (_) {
      // Sin estado legible al cerrar: ya se guardó en el último cambio.
    }
  }

  /// Guarda ya (al salir del caso o pasar a segundo plano). Devuelve cuando
  /// la escritura terminó.
  Future<void> saveNow() {
    _enqueueSave();
    return _io;
  }

  // ---- reloj y pausa (regla 10) ---------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (!ref.read(gameTickerEnabledProvider)) return;
    if (state.loading || state.paused || state.solved || _held || _waiting) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// true mientras un diálogo detiene el reloj sin mostrar la pausa.
  bool _held = false;

  /// El reloj se detiene mientras se espera al servidor o el tablero está
  /// "por validar".
  bool get _waiting => state.submitting || state.pendingValidation;

  /// Detiene el reloj SIN tapar el tablero (p. ej. diálogo de salida).
  void holdClock() {
    _held = true;
    _stopTicker();
  }

  /// Reanuda el reloj detenido con [holdClock].
  void releaseClock() {
    if (!_held) return;
    _held = false;
    _startTicker();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Un segundo de juego. No avanza si la partida está en pausa, cargando
  /// o resuelta.
  void tick() {
    if (state.loading || state.paused || state.solved || _held || _waiting) {
      return;
    }
    final elapsed = state.elapsedSeconds + 1;
    state = state.copyWith(elapsedSeconds: elapsed);
    if (elapsed % _config.periodicSaveSeconds == 0) _enqueueSave();
  }

  /// Detiene el reloj, tapa el tablero y guarda.
  void pause() {
    if (state.loading || state.solved || state.paused) return;
    _stopTicker();
    state = state.copyWith(paused: true);
    _enqueueSave();
  }

  /// Quita la pausa y el reloj sigue (botón Continuar).
  void resume() {
    if (!state.paused) return;
    state = state.copyWith(paused: false);
    _startTicker();
  }

  // ---- selección de herramienta --------------------------------------------

  /// Elige (o suelta, si ya estaba elegido) a un sospechoso. Desde Tachar o
  /// Borrar, elegir un retrato vuelve a Anotar.
  void tapSuspect(String charId) {
    if (state.solved && !state.reviewing) return;
    final selecting = state.selectedChar != charId;
    final backToNotes =
        state.toolMode == ToolMode.erase || state.toolMode == ToolMode.cross;
    state = state.copyWith(
      selectedChar: () => selecting ? charId : null,
      toolMode: backToNotes ? ToolMode.notes : null,
    );
  }

  /// Resuelto: pasa a mirar el tablero. Muestra la solución completa (cada
  /// personaje en su casilla, lo demás tachado) y deja elegir retratos para
  /// leer las pistas. El tablero sigue sin poder editarse.
  void startReview() {
    if (!state.solved || state.reviewing) return;
    state = state.copyWith(
      board: state.board.solvedView(state.pc.map.size),
      reviewing: true,
      selectedChar: () => null,
      toolMode: ToolMode.notes,
    );
  }

  /// Cambia de herramienta. Tachar y Borrar sueltan al sospechoso elegido.
  void setToolMode(ToolMode mode) {
    if (state.solved || state.toolMode == mode) return;
    final releases = mode == ToolMode.erase || mode == ToolMode.cross;
    state = state.copyWith(
      toolMode: mode,
      selectedChar: releases ? () => null : null,
    );
  }

  void toggleAutoX() => state = state.copyWith(autoX: !state.autoX);

  // ---- colocación ----------------------------------------------------------

  bool get _editable =>
      !state.locked &&
      !state.solved &&
      !state.paused &&
      !state.loading &&
      !_waiting;

  /// Actúa sobre una casilla con la herramienta activa (ADR-0013).
  /// [confirm] viene del gesto: toque corto = candidato, mantener oprimido =
  /// confirmado. Con Confirmar, cualquier toque confirma. Con Tachar pone o
  /// quita la X a mano y con Borrar limpia la casilla.
  ///
  /// Sin sospechoso elegido (Anotar o Confirmar) devuelve
  /// [ActionFeedback.noToolSelected] para que la UI avise (regla 20). Sobre
  /// un mueble que bloquea devuelve [ActionFeedback.blockedCell].
  ActionFeedback placeAt(int cell, {required bool confirm}) {
    if (!_editable) return ActionFeedback.ok;
    if (!state.pc.map.isOccupiable(cell)) return ActionFeedback.blockedCell;
    switch (state.toolMode) {
      case ToolMode.erase:
        return eraseCell(cell);
      case ToolMode.cross:
        return crossAt(cell);
      case ToolMode.notes:
      case ToolMode.place:
        final id = state.selectedChar;
        if (id == null) return ActionFeedback.noToolSelected;
        return placeSuspect(
          cell,
          charId: id,
          confirm: confirm || state.toolMode == ToolMode.place,
        );
    }
  }

  /// Tachar a mano: pone una X; si ya había una X a mano, la quita. Una
  /// casilla con ficha no se tacha.
  ActionFeedback crossAt(int cell) {
    if (!_editable) return ActionFeedback.ok;
    final c = state.board.cell(cell);
    if (c.confirmed != null) return ActionFeedback.cellHasConfirmed;
    if (c.x != null) return eraseCell(cell);
    return placeXMark(cell, XLevel.small);
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

  ActionFeedback placeSuspect(
    int cell, {
    required String charId,
    required bool confirm,
    bool replace = false,
  }) {
    if (!_editable) return ActionFeedback.ok;
    final result = confirm
        ? state.board.placeConfirmed(
            cell,
            charId,
            replace: replace,
            autoXGridSize: state.autoX ? state.pc.map.size : null,
          )
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
        state = state.copyWith(
          board: result.board,
          canUndo: true,
          canRedo: false,
        );
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
    if (_undo.length > _config.undoLimit) _undo.removeAt(0); // doc 08
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
    if (state.paused || state.loading) return;
    final next = [...state.clueMarks];
    next[index] =
        ClueMark.values[(next[index].index + 1) % ClueMark.values.length];
    state = state.copyWith(clueMarks: next);
  }

  /// Fija la marca de una pista (hoja de pista completa: Normal, Destacar,
  /// Tachar), sin pasar por el ciclo del toque simple.
  void setClueMark(int index, ClueMark mark) {
    if (state.paused || state.loading) return;
    if (index < 0 || index >= state.clueMarks.length) return;
    if (state.clueMarks[index] == mark) return;
    final next = [...state.clueMarks];
    next[index] = mark;
    state = state.copyWith(clueMarks: next);
  }

  void toggleMapMode() => state = state.copyWith(mapMode: !state.mapMode);

  // ---- resolver (doc 03 + regla 9 del ADR-0012) -------------------------------

  /// true si Resolver se valida en el servidor (campaña y reto en modo
  /// servidor). El tutorial y el banco `caso-*` validan siempre aquí.
  bool get usesServer => _serverCase;

  /// Comprueba el tablero en el teléfono. Si es incorrecto cuenta las casillas
  /// que no cuadran ([GameState.wrongCount]) y solo señala cuáles
  /// ([GameState.errorCells]) cuando [revealCells] es true (tutorial).
  ///
  /// Con el modo `none` es el camino de siempre. En modo servidor los casos
  /// de campaña y de reto usan [solveOnline].
  ActionFeedback solve({bool revealCells = false}) {
    // Un caso de servidor nunca se valida en el teléfono: usa solveOnline.
    if (_serverCase) {
      assert(false, 'solve() es solo para casos locales; usa solveOnline()');
      return ActionFeedback.ok;
    }
    if (!_editable) return ActionFeedback.ok;
    final positions = state.board.confirmedPositions(
      state.pc.characters.map((c) => c.id),
    );
    if (positions == null) return ActionFeedback.incompleteBoard;

    final v = Validator.validate(state.pc, positions);
    if (v.valid) {
      _applySolved(v.murdererId, v.lethalWeaponId);
      return ActionFeedback.solvedOk;
    }

    // Casillas incorrectas: en Fase 1 se compara contra la solución local
    // (en el modo servidor lo responde el servidor).
    final wrong = <int>{
      for (final e in positions.entries)
        if (state.pc.solution.positions[e.key] != e.value) e.value,
    };
    _registerWrong(wrong.length, revealCells ? wrong : const {});
    return ActionFeedback.wrongSolution;
  }

  /// Marca el caso como resuelto con el asesino y el arma dados.
  void _applySolved(String? murdererId, String? lethalWeaponId) {
    _stopTicker();
    state = state.copyWith(
      solved: true,
      murdererId: murdererId,
      lethalWeaponId: lethalWeaponId,
      errorCells: const {},
      wrongCount: 0,
      selectedChar: () => null,
      toolMode: ToolMode.notes,
      submitting: false,
      pendingValidation: false,
      validationStalled: false,
    );
    // Resuelto: la partida guardada ya no hace falta.
    _touched = false;
    final prefs = _prefs;
    if (prefs != null) {
      _enqueue(() => SavedGame.clear(prefs, arg.caseId));
    }
  }

  /// Un Resolver fallido: suma el error, bloquea unos segundos y deja el
  /// conteo de casillas que no cuadran.
  void _registerWrong(int wrongCount, Set<int> errorCells) {
    state = state.copyWith(
      errorCount: state.errorCount + 1,
      errorCells: errorCells,
      wrongCount: wrongCount,
      locked: true,
      submitting: false,
      pendingValidation: false,
      validationStalled: false,
    );
    _unlockTimer?.cancel();
    _unlockTimer = Timer(Duration(seconds: _config.wrongSolveLockSeconds), () {
      state = state.copyWith(
        locked: false,
        errorCells: const {},
        wrongCount: 0,
      );
    });
    // Por si el reloj estaba detenido esperando al servidor.
    if (_ticker == null) _startTicker();
  }

  // ---- resolver con el servidor (ADR-0016) -------------------------------------

  /// Envía el tablero al servidor. Sin conexión no se pierde nada: el envío
  /// queda en la cola y el caso "por validar" ([ActionFeedback.pendingValidation]).
  /// Si el caso no se valida en el servidor, es igual que [solve].
  Future<ActionFeedback> solveOnline() async {
    final server = _serverCase ? _validation : null;
    if (server == null) return solve();
    if (!_editable) return ActionFeedback.ok;
    final positions = state.board.confirmedPositions(
      state.pc.characters.map((c) => c.id),
    );
    if (positions == null) return ActionFeedback.incompleteBoard;

    _stopTicker();
    state = state.copyWith(submitting: true);
    // Solo se lee cómo empezó la partida: nunca se llama a startCase aquí.
    final startedOnline = await server.startedOnlineForSubmit(arg.caseId);
    if (!_alive) return ActionFeedback.ok;
    final outcome = await server.submit(
      PendingSubmission(
        caseId: arg.caseId,
        submissionId: server.newSubmissionId(),
        positions: positions,
        clientElapsedMs: math.min(
          state.elapsedSeconds * 1000,
          _kMaxClientElapsedMs,
        ),
        startedOnline: startedOnline,
        elapsedSeconds: state.elapsedSeconds,
        errorCount: state.errorCount,
        createdAt: server.now(),
      ),
    );
    if (!_alive) return ActionFeedback.ok;

    switch (outcome) {
      case OutcomeSolved(:final response):
        _applySolved(response.murdererId, response.lethalWeaponId);
        return ActionFeedback.solvedOk;
      case OutcomeWrong(:final response):
        _registerWrong(response.wrongCount, const {});
        return ActionFeedback.wrongSolution;
      case OutcomeQueued():
        // El reloj sigue detenido hasta que llegue la respuesta.
        state = state.copyWith(submitting: false, pendingValidation: true);
        _enqueueSave();
        return ActionFeedback.pendingValidation;
      case OutcomeRateLimited():
        state = state.copyWith(submitting: false);
        _startTicker();
        return ActionFeedback.rateLimited;
      case OutcomeRejected():
        state = state.copyWith(submitting: false);
        _startTicker();
        return ActionFeedback.validationFailed;
      case OutcomeRegistrationRequired():
        state = state.copyWith(submitting: false);
        _startTicker();
        return ActionFeedback.registrationRequired;
      case OutcomeStalled():
        // Errores seguidos del servidor: el tablero queda esperando la
        // decisión del jugador (Reintentar o Cancelar envío).
        state = state.copyWith(
          submitting: false,
          pendingValidation: true,
          validationStalled: true,
        );
        _enqueueSave();
        return ActionFeedback.pendingValidation;
    }
  }

  /// Reintentar un envío detenido. La respuesta llega por el servicio.
  void retryValidation() {
    final server = _validation;
    if (server == null ||
        !state.pendingValidation ||
        !state.validationStalled) {
      return;
    }
    state = state.copyWith(validationStalled: false);
    unawaited(server.retryStalled(arg.caseId));
  }

  /// Cancelar el envío detenido: sale de la cola y el tablero se desbloquea.
  Future<void> cancelValidation() async {
    final server = _validation;
    if (server == null || !state.pendingValidation) return;
    await server.cancel(arg.caseId);
    if (!_alive) return;
    state = state.copyWith(pendingValidation: false, validationStalled: false);
    _startTicker();
  }

  /// Respuesta del servidor a un envío que estaba en la cola.
  void _onValidationEvent(ValidationEvent e) {
    if (!_alive || e.caseId != arg.caseId || !state.pendingValidation) return;
    switch (e.kind) {
      case ValidationEventKind.solved:
        final r = e.response;
        if (r is SubmitSolved) _applySolved(r.murdererId, r.lethalWeaponId);
      case ValidationEventKind.wrong:
        final r = e.response;
        if (r is SubmitWrong) _registerWrong(r.wrongCount, const {});
      case ValidationEventKind.rejected:
      case ValidationEventKind.registrationRequired:
        state = state.copyWith(
          pendingValidation: false,
          validationStalled: false,
        );
        _startTicker();
      case ValidationEventKind.stalled:
        state = state.copyWith(validationStalled: true);
    }
  }
}

final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameState, PuzzleCase>(GameController.new);
