/// Estado del tablero en partida y reglas de colocación/borrado.
/// Reglas exactas: docs/03-reglas-del-juego.md ("Reglas de colocacion",
/// "Reglas de borrado") y spec 16 sección 4. Lógica pura: sin Flutter.
library;

/// Nivel de descarte.
enum XLevel { small, large }

/// Estado de un sospechoso en el panel / al colocar.
enum SuspectMarkState { candidate, confirmed }

/// Contenido de una celda. Inmutable.
class CellContent {
  /// Personaje confirmado (excluyente: borra y bloquea todo lo demás).
  final String? confirmed;

  /// Candidatos (avatar pequeño + ?). Pueden coexistir varios.
  final Set<String> candidates;

  /// Descarte del jugador.
  final XLevel? x;

  const CellContent({this.confirmed, this.candidates = const {}, this.x});

  bool get isEmpty => confirmed == null && candidates.isEmpty && x == null;

  int get elementCount =>
      (confirmed != null ? 1 : 0) + candidates.length + (x != null ? 1 : 0);

  CellContent copyWith({
    String? Function()? confirmed,
    Set<String>? candidates,
    XLevel? Function()? x,
  }) =>
      CellContent(
        confirmed: confirmed != null ? confirmed() : this.confirmed,
        candidates: candidates ?? this.candidates,
        x: x != null ? x() : this.x,
      );
}

/// Resultado de un intento de colocación (doc 03).
enum PlaceOutcome {
  /// Cambió el tablero.
  placed,

  /// "Si el mismo elemento ya existe, no hace nada."
  noChange,

  /// "Esta casilla ya tiene una decisión confirmada, borra primero
  /// para colocar candidato." (aplica también a X)
  rejectedByConfirmed,

  /// Confirmado sobre confirmado: pide confirmación antes de reemplazar.
  needsReplaceConfirmation,
}

class PlaceResult {
  final PlaceOutcome outcome;
  final BoardState board;
  const PlaceResult(this.outcome, this.board);
}

/// Elemento individual de una celda (para mini panel y papelera).
sealed class CellElement {
  const CellElement();
}

class ConfirmedElement extends CellElement {
  final String charId;
  const ConfirmedElement(this.charId);
}

class CandidateElement extends CellElement {
  final String charId;
  const CandidateElement(this.charId);
}

class XElement extends CellElement {
  final XLevel level;
  const XElement(this.level);
}

/// Tablero completo. Inmutable: cada operación devuelve un tablero nuevo
/// (facilita deshacer/rehacer por snapshots, límite en doc 08).
class BoardState {
  final Map<int, CellContent> _cells;

  const BoardState._(this._cells);

  factory BoardState.empty() => const BoardState._({});

  CellContent cell(int index) => _cells[index] ?? const CellContent();

  bool get isEmpty => _cells.values.every((c) => c.isEmpty);

  BoardState _with(int index, CellContent content) {
    final next = Map<int, CellContent>.from(_cells);
    if (content.isEmpty) {
      next.remove(index);
    } else {
      next[index] = content;
    }
    return BoardState._(next);
  }

  /// Coloca un candidato (doc 03):
  /// - celda con confirmado: rechazado con mensaje
  /// - mismo candidato ya presente: no hace nada
  /// - entidad distinta: coexiste
  PlaceResult placeCandidate(int index, String charId) {
    final c = cell(index);
    if (c.confirmed != null) {
      return PlaceResult(PlaceOutcome.rejectedByConfirmed, this);
    }
    if (c.candidates.contains(charId)) {
      return PlaceResult(PlaceOutcome.noChange, this);
    }
    return PlaceResult(
      PlaceOutcome.placed,
      _with(index, c.copyWith(candidates: {...c.candidates, charId})),
    );
  }

  /// Coloca un confirmado (doc 03):
  /// - borra automáticamente todo lo demás de la celda
  /// - sobre otro confirmado: exige confirmación explícita (replace=true)
  /// - mismo confirmado: no hace nada
  PlaceResult placeConfirmed(int index, String charId,
      {bool replace = false}) {
    final c = cell(index);
    if (c.confirmed == charId) {
      return PlaceResult(PlaceOutcome.noChange, this);
    }
    if (c.confirmed != null && !replace) {
      return PlaceResult(PlaceOutcome.needsReplaceConfirmation, this);
    }
    return PlaceResult(
      PlaceOutcome.placed,
      _with(index, CellContent(confirmed: charId)),
    );
  }

  /// Coloca una X (doc 03):
  /// - celda con confirmado: rechazada
  /// - misma X: no hace nada · X de otro nivel: reemplaza (misma entidad)
  PlaceResult placeX(int index, XLevel level) {
    final c = cell(index);
    if (c.confirmed != null) {
      return PlaceResult(PlaceOutcome.rejectedByConfirmed, this);
    }
    if (c.x == level) {
      return PlaceResult(PlaceOutcome.noChange, this);
    }
    return PlaceResult(
      PlaceOutcome.placed,
      _with(index, c.copyWith(x: () => level)),
    );
  }

  /// Lista los elementos de una celda (para mini panel de borrado).
  List<CellElement> elementsOf(int index) {
    final c = cell(index);
    return [
      if (c.confirmed != null) ConfirmedElement(c.confirmed!),
      for (final id in c.candidates) CandidateElement(id),
      if (c.x != null) XElement(c.x!),
    ];
  }

  /// Borra un elemento concreto (mini panel o papelera).
  BoardState removeElement(int index, CellElement element) {
    final c = cell(index);
    return switch (element) {
      ConfirmedElement(:final charId) => c.confirmed == charId
          ? _with(index, c.copyWith(confirmed: () => null))
          : this,
      CandidateElement(:final charId) => _with(
          index,
          c.copyWith(candidates: {...c.candidates}..remove(charId)),
        ),
      XElement() => _with(index, c.copyWith(x: () => null)),
    };
  }

  /// Posiciones confirmadas charId -> celda.
  /// Devuelve null si algún personaje no está confirmado exactamente una vez.
  Map<String, int>? confirmedPositions(Iterable<String> charIds) {
    final positions = <String, int>{};
    for (final e in _cells.entries) {
      final id = e.value.confirmed;
      if (id != null) {
        if (positions.containsKey(id)) return null; // duplicado
        positions[id] = e.key;
      }
    }
    for (final id in charIds) {
      if (!positions.containsKey(id)) return null; // falta
    }
    return positions;
  }

  /// Celdas donde hay algún personaje confirmado.
  Iterable<int> get confirmedCells =>
      [for (final e in _cells.entries) if (e.value.confirmed != null) e.key];
}
