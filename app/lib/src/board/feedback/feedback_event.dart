/// Eventos que el juego le cuenta al director de feedback. El director decide
/// qué animación, sonido y vibración dispara cada uno.
library;

/// Por qué se rechazó una colocación.
enum PlacementProblem { noSuspect, cellHasConfirmed, cellHasX, alreadyPlaced, blocked }

/// Datos que necesita la secuencia de revelar.
class RevealData {
  /// Lado de la cuadrícula.
  final int gridSize;

  /// Celda donde está el asesino y celda de la víctima.
  final int murdererCell;
  final int victimCell;
  final String murdererId;
  final String murdererName;

  /// Celdas de los inocentes (sin víctima ni asesino), en cualquier orden.
  final List<int> innocentCells;

  const RevealData({
    required this.gridSize,
    required this.murdererCell,
    required this.victimCell,
    required this.murdererId,
    required this.murdererName,
    required this.innocentCells,
  });
}

/// Momentos de la secuencia de resolver (los emite el reloj de la secuencia).
enum RevealBeatKind { waveRow, cascade, zoomHit, star, fanfare, end }

sealed class FeedbackEvent {
  const FeedbackEvent();
}

/// Se tocó a un sospechoso de la bandeja. [selected] es false si se soltó.
class SuspectTapped extends FeedbackEvent {
  final String charId;
  final bool selected;
  const SuspectTapped(this.charId, {required this.selected});
}

class CandidateNoted extends FeedbackEvent {
  final int cell;
  final String charId;
  const CandidateNoted(this.cell, this.charId);
}

class Confirmed extends FeedbackEvent {
  final int cell;
  final String charId;
  const Confirmed(this.cell, this.charId);
}

/// Casillas que se tacharon solas al confirmar (fila y columna), ordenadas de
/// la más cercana a la más lejana de [origin]: así se ve la ola.
class LinesCrossed extends FeedbackEvent {
  final int origin;
  final List<int> cells;
  const LinesCrossed(this.origin, this.cells);
}

/// El jugador tachó una casilla a mano (herramienta Tachar).
class CrossMarked extends FeedbackEvent {
  final int cell;
  const CrossMarked(this.cell);
}

class Erased extends FeedbackEvent {
  final int cell;
  const Erased(this.cell);
}

class PlacementRejected extends FeedbackEvent {
  final int? cell;
  final PlacementProblem problem;
  const PlacementRejected(this.problem, {this.cell});
}

class SolveFailed extends FeedbackEvent {
  final int wrongCells;
  const SolveFailed(this.wrongCells);
}

class SolveIncomplete extends FeedbackEvent {
  final int missing;
  const SolveIncomplete(this.missing);
}

class SolveSucceeded extends FeedbackEvent {
  final RevealData reveal;
  const SolveSucceeded(this.reveal);
}

/// Un momento de la secuencia de revelar (lo emite la propia secuencia).
class RevealBeat extends FeedbackEvent {
  final RevealBeatKind kind;

  /// Fila, índice de inocente o número de estrella, según [kind].
  final int index;

  /// Celda a la que apunta el momento (inocente que salta, asesino...).
  final int? cell;
  final RevealData reveal;
  const RevealBeat(this.kind, this.reveal, {this.index = 0, this.cell});
}

/// El jugador saltó la secuencia (solo permitido tras 1 s).
class RevealSkipped extends FeedbackEvent {
  final RevealData reveal;
  const RevealSkipped(this.reveal);
}
