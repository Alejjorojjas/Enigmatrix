/// Semántica del tablero para lectores de pantalla (H-56). El tablero se dibuja
/// en una escena de Flame, que para TalkBack es una imagen sin partes. Esta
/// capa pone, encima de la escena y sin tapar ni mover nada, un nodo por
/// casilla con su descripción ("Fila 2, columna 3, el Comedor, junto a un
/// sofá, candidatos: Adela; confirmado: ninguno") y las acciones de tocar y de
/// mantener oprimida, que llaman a lo mismo que el dedo.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../board/scene/board_geometry.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';

/// Descripción hablada de una casilla. Función pura (se prueba sin pantalla).
///
/// Incluye la posición, la habitación, el mueble que la cubre o que tiene al
/// lado, los candidatos, el confirmado y si está tachada. No dice nada que el
/// jugador no vea ya en el tablero (no revela la solución ni las casillas que
/// no cuadran).
String cellSemanticsLabel(
  AppLocalizations l10n,
  PuzzleCase pc,
  BoardState board,
  int cell,
) {
  final map = pc.map;
  String nameOf(String id) => pc.character(id).nameEs;
  final parts = <String>[
    l10n.boardSemanticsPosition(map.row(cell) + 1, map.col(cell) + 1),
    map.area(map.areaIdOf(cell)).nameEs,
  ];

  final here = map.objectAt(cell);
  if (here != null) {
    parts.add(
      here.blocks
          ? l10n.boardSemanticsBlockedBy(here.type.indefEs)
          : l10n.boardSemanticsOnObject(here.type.indefEs),
    );
  }
  // Muebles de las casillas de al lado (sin repetir el de esta casilla).
  final beside = <String>[];
  for (final n in map.orthNeighbors(cell)) {
    final o = map.objectAt(n);
    if (o == null || identical(o, here)) continue;
    final name = o.type.indefEs;
    if (!beside.contains(name)) beside.add(name);
  }
  if (beside.isNotEmpty) {
    parts.add(l10n.boardSemanticsBesideObjects(beside.join(', ')));
  }

  if (map.isOccupiable(cell)) {
    final content = board.cell(cell);
    // En el orden de los personajes del caso, para que siempre suene igual.
    final cands = [
      for (final c in pc.characters)
        if (content.candidates.contains(c.id)) c.nameEs,
    ];
    parts.add(
      cands.isEmpty
          ? l10n.boardSemanticsNoCandidates
          : l10n.boardSemanticsCandidates(cands.join(', ')),
    );
    final conf = content.confirmed;
    parts.add(
      conf == null
          ? l10n.boardSemanticsNoConfirmed
          : l10n.boardSemanticsConfirmed(nameOf(conf)),
    );
    if (content.x != null) {
      parts.add(l10n.boardSemanticsCrossed);
    } else if (content.autoXFrom.isNotEmpty) {
      parts.add(
        l10n.boardSemanticsAutoCrossed(
          [
            for (final c in pc.characters)
              if (content.autoXFrom.contains(c.id)) c.nameEs,
          ].join(', '),
        ),
      );
    }
  }
  return parts.join(', ');
}

/// Capa de semántica que se pone encima de la escena del tablero. No dibuja
/// nada ni recibe toques: solo describe cada casilla al lector de pantalla.
class BoardSemanticsLayer extends ConsumerWidget {
  const BoardSemanticsLayer({
    super.key,
    required this.pc,
    required this.onTapCell,
    required this.onHoldCell,
  });

  final PuzzleCase pc;
  final void Function(int cell) onTapCell;
  final void Function(int cell) onHoldCell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(gameControllerProvider(pc).select((s) => s.board));
    final n = pc.map.size;
    return LayoutBuilder(
      builder: (context, box) {
        final geo = BoardGeometry.fit(
          n,
          box.biggest,
          margin: kSceneMargin,
          marginY: kSceneMarginY,
        );
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: context.l10n.boardSemanticsBoard(n),
          child: Stack(
            children: [
              for (var i = 0; i < n * n; i++)
                Positioned.fromRect(
                  rect: geo.cellRect(i),
                  child: Semantics(
                    button: pc.map.isOccupiable(i),
                    label: cellSemanticsLabel(context.l10n, pc, board, i),
                    onTap: pc.map.isOccupiable(i) ? () => onTapCell(i) : null,
                    onLongPress: pc.map.isOccupiable(i)
                        ? () => onHoldCell(i)
                        : null,
                    onLongPressHint: context.l10n.boardSemanticsHoldHint,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
