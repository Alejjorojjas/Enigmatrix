/// Lo que la escena de Flame lee de la partida. NO tiene reglas: la partida
/// vive en `GameController` (Riverpod) y la pantalla copia aquí lo que la
/// escena necesita dibujar (tablero, sospechoso elegido, casillas erróneas) y
/// le entrega los toques ya interpretados (toque corto y mantener oprimido).
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';

import '../game/board_state.dart';
import 'feedback/feedback_director.dart';

class SceneSession {
  SceneSession({required this.pc, required this.director});

  final PuzzleCase pc;
  final FeedbackDirector director;

  /// Tablero que se dibuja.
  BoardState board = BoardState.empty();

  /// Sospechoso elegido en la bandeja (null si ninguno).
  String? selectedChar;

  /// Si se resaltan las casillas posibles del sospechoso elegido (Anotar y
  /// Confirmar sí; Tachar y Borrar no).
  bool highlightsCandidates = true;

  /// true = vista de mapa (muebles y nombres); false = vista de notas (solo
  /// la cuadrícula con las marcas).
  bool mapMode = true;

  /// El caso ya se resolvió.
  bool solved = false;

  /// El tablero acepta toques (no está en pausa, cargando, resuelto ni
  /// bloqueado tras un error).
  bool interactive = true;

  /// Casillas que se señalan en rojo (solo el tutorial, regla 9).
  Set<int> errorCells = const {};

  /// Toque corto y mantener oprimido sobre una casilla.
  void Function(int cell)? onTapCell;
  void Function(int cell)? onHoldCell;

  int get size => pc.map.size;

  int indexOfChar(String id) => pc.characters.indexWhere((c) => c.id == id);
}
