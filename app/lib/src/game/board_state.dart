/// Estado del tablero en partida y reglas de colocación/borrado.
/// Reglas exactas: docs/03-reglas-del-juego.md ("Reglas de colocacion",
/// "Reglas de borrado") y spec 16 sección 4. Lógica pura: sin Flutter.
library;

/// Nivel de descarte.
enum XLevel { small, large }

/// Estado de un sospechoso al colocar.
enum SuspectMarkState { candidate, confirmed }

/// Contenido de una celda. Inmutable.
class CellContent {
  /// Personaje confirmado (excluyente: borra y bloquea todo lo demás).
  final String? confirmed;

  /// Candidatos (letra del personaje). Pueden coexistir varios.
  final Set<String> candidates;

  /// Descarte manual del jugador.
  final XLevel? x;

  /// Confirmados cuya fila/columna tachan esta celda automáticamente
  /// (opción auto-X, 2026-06-11). Se retiran si se borra el confirmado.
  final Set<String> autoXFrom;

  const CellContent({
    this.confirmed,
    this.candidates = const {},
    this.x,
    this.autoXFrom = const {},
  });

  bool get hasX => x != null || autoXFrom.isNotEmpty;

  bool get isEmpty =>
      confirmed == null && candidates.isEmpty && x == null && autoXFrom.isEmpty;

  int get elementCount =>
      (confirmed != null ? 1 : 0) + candidates.length + (hasX ? 1 : 0);

  CellContent copyWith({
    String? Function()? confirmed,
    Set<String>? candidates,
    XLevel? Function()? x,
    Set<String>? autoXFrom,
  }) =>
      CellContent(
        confirmed: confirmed != null ? confirmed() : this.confirmed,
        candidates: candidates ?? this.candidates,
        x: x != null ? x() : this.x,
        autoXFrom: autoXFrom ?? this.autoXFrom,
      );
}

/// Resultado de un intento de colocación (doc 03 + reglas 2026-06-12).
enum PlaceOutcome {
  /// Cambió el tablero.
  placed,

  /// "Si el mismo elemento ya existe, no hace nada."
  noChange,

  /// "Esta casilla ya tiene una decisión confirmada, borra primero
  /// para colocar candidato." (aplica también a X)
  rejectedByConfirmed,

  /// La casilla está descartada con X: no se pueden anotar candidatos.
  rejectedByX,

  /// Ese personaje ya está confirmado en otra casilla.
  alreadyConfirmedElsewhere,

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

  /// ¿Dónde está confirmado este personaje? (null si no lo está)
  int? confirmedCellOf(String charId) {
    for (final e in _cells.entries) {
      if (e.value.confirmed == charId) return e.key;
    }
    return null;
  }

  /// Coloca un candidato (doc 03 + reglas 2026-06-12):
  /// - celda con confirmado: rechazado con mensaje
  /// - celda con X (manual o automática): rechazado — está descartada
  /// - mismo candidato ya presente: no hace nada
  /// - otros candidatos: coexisten
  PlaceResult placeCandidate(int index, String charId) {
    final c = cell(index);
    if (c.confirmed != null) {
      return PlaceResult(PlaceOutcome.rejectedByConfirmed, this);
    }
    if (c.hasX) {
      return PlaceResult(PlaceOutcome.rejectedByX, this);
    }
    if (c.candidates.contains(charId)) {
      return PlaceResult(PlaceOutcome.noChange, this);
    }
    return PlaceResult(
      PlaceOutcome.placed,
      _with(index, c.copyWith(candidates: {...c.candidates, charId})),
    );
  }

  /// Coloca un confirmado (doc 03 + reglas 2026-06-12):
  /// - cada personaje solo puede estar confirmado en UNA casilla
  /// - al confirmarse, sus candidatos desaparecen de todo el tablero
  /// - borra automáticamente todo lo demás de la celda
  /// - sobre otro confirmado: exige confirmación explícita (replace=true)
  ///
  /// Si [autoXGridSize] no es null, tacha automáticamente la fila y la
  /// columna del confirmado — solo en casillas VACÍAS (no pisa candidatos),
  /// atribuyéndole las X para poder retirarlas si se borra.
  PlaceResult placeConfirmed(int index, String charId,
      {bool replace = false, int? autoXGridSize}) {
    final c = cell(index);
    if (c.confirmed == charId) {
      return PlaceResult(PlaceOutcome.noChange, this);
    }
    final existing = confirmedCellOf(charId);
    if (existing != null && existing != index) {
      return PlaceResult(PlaceOutcome.alreadyConfirmedElsewhere, this);
    }
    if (c.confirmed != null && !replace) {
      return PlaceResult(PlaceOutcome.needsReplaceConfirmation, this);
    }
    var board = this;
    if (c.confirmed != null) {
      board = board._clearAutoX(c.confirmed!);
    }
    board = board._with(index, CellContent(confirmed: charId));
    // Confirmado => sus candidatos sobran en el resto del tablero.
    board = board._removeCandidateEverywhere(charId);
    if (autoXGridSize != null) {
      board = board._applyAutoX(index, charId, autoXGridSize);
    }
    return PlaceResult(PlaceOutcome.placed, board);
  }

  BoardState _removeCandidateEverywhere(String charId) {
    var board = this;
    for (final e in [..._cells.entries]) {
      if (e.value.candidates.contains(charId)) {
        board = board._with(e.key,
            e.value.copyWith(candidates: {...e.value.candidates}..remove(charId)));
      }
    }
    return board;
  }

  BoardState _applyAutoX(int index, String charId, int size) {
    var board = this;
    final r = index ~/ size, col = index % size;
    for (var i = 0; i < size; i++) {
      for (final target in [r * size + i, i * size + col]) {
        if (target == index) continue;
        final tc = board.cell(target);
        if (tc.confirmed != null) continue;
        // No pisa candidatos: el jugador conserva sus anotaciones.
        if (tc.candidates.isNotEmpty) continue;
        if (tc.autoXFrom.contains(charId)) continue;
        board = board._with(
            target, tc.copyWith(autoXFrom: {...tc.autoXFrom, charId}));
      }
    }
    return board;
  }

  BoardState _clearAutoX(String charId) {
    var board = this;
    for (final e in [..._cells.entries]) {
      if (e.value.autoXFrom.contains(charId)) {
        board = board._with(
            e.key,
            e.value
                .copyWith(autoXFrom: {...e.value.autoXFrom}..remove(charId)));
      }
    }
    return board;
  }

  /// Coloca una X manual (doc 03 + reglas 2026-06-12):
  /// - celda con confirmado: rechazada
  /// - misma X: no hace nada · X de otro nivel: reemplaza (misma entidad)
  /// - X y candidatos no conviven: la X manual (acto deliberado) limpia
  ///   los candidatos de la casilla
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
      _with(index, c.copyWith(x: () => level, candidates: const {})),
    );
  }

  /// Borrador: limpia por completo una casilla (candidatos, X y confirmado
  /// con sus X automáticas). Devuelve this si no había nada.
  BoardState eraseCell(int index) {
    final c = cell(index);
    if (c.isEmpty) return this;
    var board = this;
    if (c.confirmed != null) {
      board = board._clearAutoX(c.confirmed!);
    }
    return board._with(index, const CellContent());
  }

  /// Lista los elementos de una celda (para mini panel de borrado).
  List<CellElement> elementsOf(int index) {
    final c = cell(index);
    return [
      if (c.confirmed != null) ConfirmedElement(c.confirmed!),
      for (final id in c.candidates) CandidateElement(id),
      if (c.hasX) XElement(c.x ?? XLevel.large),
    ];
  }

  /// Borra un elemento concreto (mini panel o papelera).
  /// Borrar un confirmado retira también sus X automáticas.
  /// Borrar una X la quita por completo (manual y automática).
  BoardState removeElement(int index, CellElement element) {
    final c = cell(index);
    return switch (element) {
      ConfirmedElement(:final charId) => c.confirmed == charId
          ? _with(index, c.copyWith(confirmed: () => null))
              ._clearAutoX(charId)
          : this,
      CandidateElement(:final charId) => _with(
          index,
          c.copyWith(candidates: {...c.candidates}..remove(charId)),
        ),
      XElement() =>
        _with(index, c.copyWith(x: () => null, autoXFrom: const {})),
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
