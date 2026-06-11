/// Tablero jugable: celdas con áreas/paredes, marcas, drag & drop.
/// Interacción según docs/03 y spec 16 §4.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';

/// Payload de arrastre desde el panel (sospechoso en su estado actual o X).
class PanelDrag {
  final Tool tool;
  const PanelDrag(this.tool);
}

/// Payload de arrastre de un elemento ya colocado (para papelera).
class BoardElementDrag {
  final int cell;
  final CellElement element;
  const BoardElementDrag(this.cell, this.element);
}

/// Paleta para áreas (modo mapa). En modo lógica se atenúan.
const areaPalette = [
  Color(0xFF8D6E63),
  Color(0xFF5C6BC0),
  Color(0xFF66BB6A),
  Color(0xFF26A69A),
  Color(0xFFEC407A),
  Color(0xFFFFA726),
];

const charPalette = [
  Color(0xFFD9A427),
  Color(0xFF64B5F6),
  Color(0xFFEF8A65),
  Color(0xFFBA68C8),
  Color(0xFF81C784),
  Color(0xFF4DD0E1),
  Color(0xFFF06292),
  Color(0xFFFFD54F),
];

Color charColor(PuzzleCase pc, String charId) =>
    charPalette[pc.characters.indexWhere((c) => c.id == charId) %
        charPalette.length];

class BoardView extends ConsumerWidget {
  final PuzzleCase pc;
  final void Function(int cell, Tool tool) onPlace;
  const BoardView({super.key, required this.pc, required this.onPlace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final map = pc.map;
    final n = map.size;

    return AspectRatio(
      aspectRatio: 1,
      child: IgnorePointer(
        ignoring: state.locked || state.solved,
        child: Column(
          children: [
            for (var r = 0; r < n; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < n; c++)
                      Expanded(
                          child:
                              _Cell(pc: pc, cell: map.cellAt(r, c), onPlace: onPlace)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends ConsumerWidget {
  final PuzzleCase pc;
  final int cell;
  final void Function(int cell, Tool tool) onPlace;
  const _Cell({required this.pc, required this.cell, required this.onPlace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final state = ref.watch(gameControllerProvider(pc));
    final map = pc.map;
    final r = map.row(cell), c = map.col(cell);
    final areaIdx =
        map.areas.indexWhere((a) => a.id == map.areaIdOf(cell));
    final blocked = !map.isOccupiable(cell);
    final isError = state.errorCells.contains(cell);
    final content = state.board.cell(cell);

    bool wall(int rr, int cc) =>
        !map.inGrid(rr, cc) ||
        map.areaIdOf(map.cellAt(rr, cc)) != map.areaIdOf(cell);

    final wallColor = Brand.gold.withValues(alpha: .8);
    final gridColor = Brand.cream.withValues(alpha: .12);
    BorderSide side(bool isWall) => BorderSide(
        color: isWall ? wallColor : gridColor, width: isWall ? 2.5 : 0.6);

    final baseColor = areaPalette[areaIdx % areaPalette.length]
        .withValues(alpha: state.mapMode ? .30 : .08);

    // Indicador de armas: en la primera celda del área.
    final weapons = map.weaponsInArea(map.areaIdOf(cell));
    final isAreaAnchor =
        weapons.isNotEmpty && map.areas[areaIdx].cells.first == cell;

    return DragTarget<PanelDrag>(
      onWillAcceptWithDetails: (_) => !blocked,
      onAcceptWithDetails: (d) => onPlace(cell, d.data.tool),
      builder: (context, hovering, _) => GestureDetector(
        onTap: () {
          if (blocked) return;
          if (state.tool != null) {
            onPlace(cell, state.tool!);
          } else if (content.elementCount > 0) {
            _showMiniPanel(context, controller, state.board.elementsOf(cell));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isError
                ? Brand.error.withValues(alpha: .45)
                : hovering.isNotEmpty
                    ? Brand.gold.withValues(alpha: .35)
                    : baseColor,
            border: Border(
              top: side(wall(r - 1, c)),
              bottom: side(wall(r + 1, c)),
              left: side(wall(r, c - 1)),
              right: side(wall(r, c + 1)),
            ),
          ),
          child: Stack(
            children: [
              // Letra del área como marca de agua.
              Positioned(
                left: 3,
                bottom: 1,
                child: Text(
                  String.fromCharCode('a'.codeUnitAt(0) + areaIdx),
                  style: TextStyle(
                      fontSize: state.mapMode ? 11 : 16,
                      color: Brand.cream.withValues(alpha: .35)),
                ),
              ),
              if (isAreaAnchor)
                Positioned(
                  right: 2,
                  top: 1,
                  child: Tooltip(
                    message:
                        'Armas: ${weapons.map((w) => w.nameEs).join(', ')}',
                    child: const Text('🗡', style: TextStyle(fontSize: 13)),
                  ),
                ),
              if (blocked)
                Center(
                  child: Tooltip(
                    message: map.objects
                        .firstWhere((o) => o.cell == cell)
                        .nameEs,
                    child: Icon(Icons.chair_outlined,
                        color: Brand.cream.withValues(alpha: .5), size: 22),
                  ),
                ),
              if (!blocked) Center(child: _CellMarks(pc: pc, cell: cell)),
            ],
          ),
        ),
      ),
    );
  }

  /// Mini panel de borrado (doc 06, pantalla 22): solo sirve para borrar;
  /// se cierra al borrar un elemento.
  void _showMiniPanel(BuildContext context, GameController controller,
      List<CellElement> elements) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Brand.surface,
        title: const Text('Borrar de esta casilla', style: TextStyle(fontSize: 16)),
        children: [
          for (final el in elements)
            SimpleDialogOption(
              onPressed: () {
                controller.removeElement(cell, el);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  const Icon(Icons.delete_outline,
                      color: Brand.error, size: 18),
                  const SizedBox(width: 8),
                  Text(_elementLabel(el)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _elementLabel(CellElement el) => switch (el) {
        ConfirmedElement(:final charId) =>
          '${pc.character(charId).nameEs} (confirmado)',
        CandidateElement(:final charId) =>
          '${pc.character(charId).nameEs} (candidato)',
        XElement(:final level) =>
          level == XLevel.small ? 'X pequeña' : 'X grande',
      };
}

class _CellMarks extends ConsumerWidget {
  final PuzzleCase pc;
  final int cell;
  const _CellMarks({required this.pc, required this.cell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref
        .watch(gameControllerProvider(pc).select((s) => s.board.cell(cell)));

    if (content.confirmed != null) {
      return _draggableMark(
        ConfirmedElement(content.confirmed!),
        _ConfirmedAvatar(pc: pc, charId: content.confirmed!),
      );
    }

    final marks = <Widget>[
      for (final id in content.candidates)
        _draggableMark(
            CandidateElement(id), _CandidateAvatar(pc: pc, charId: id)),
      if (content.x != null)
        _draggableMark(XElement(content.x!), _XMark(level: content.x!)),
    ];
    if (marks.isEmpty) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Wrap(spacing: 2, runSpacing: 2, children: marks),
    );
  }

  Widget _draggableMark(CellElement element, Widget child) =>
      Draggable<BoardElementDrag>(
        data: BoardElementDrag(cell, element),
        feedback: Material(color: Colors.transparent, child: child),
        childWhenDragging: Opacity(opacity: .35, child: child),
        child: child,
      );
}

class _ConfirmedAvatar extends StatelessWidget {
  final PuzzleCase pc;
  final String charId;
  const _ConfirmedAvatar({required this.pc, required this.charId});

  @override
  Widget build(BuildContext context) {
    final color = charColor(pc, charId);
    final isVictim = charId == pc.victimId;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: color,
          child: Text(
            isVictim ? '†' : pc.character(charId).nameEs[0],
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        const Positioned(
          right: -4,
          bottom: -4,
          child: Icon(Icons.check_circle, color: Brand.success, size: 16),
        ),
      ],
    );
  }
}

class _CandidateAvatar extends StatelessWidget {
  final PuzzleCase pc;
  final String charId;
  const _CandidateAvatar({required this.pc, required this.charId});

  @override
  Widget build(BuildContext context) {
    final color = charColor(pc, charId);
    final isVictim = charId == pc.victimId;
    return CircleAvatar(
      radius: 11,
      backgroundColor: color.withValues(alpha: .55),
      child: Text(
        '${isVictim ? '†' : pc.character(charId).nameEs[0]}?',
        style: const TextStyle(
            color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _XMark extends StatelessWidget {
  final XLevel level;
  const _XMark({required this.level});

  @override
  Widget build(BuildContext context) => Text(
        '✕',
        style: TextStyle(
          fontSize: level == XLevel.small ? 14 : 26,
          fontWeight: FontWeight.w900,
          color: Colors.black.withValues(alpha: .85),
          shadows: const [Shadow(color: Colors.white24, blurRadius: 2)],
        ),
      );
}
