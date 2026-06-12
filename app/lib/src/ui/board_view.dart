/// Tablero jugable: celdas con áreas/paredes, muebles (pisables y
/// bloqueantes), marcas y drag & drop.
/// Interacción 2026-06-11: tap = candidato (letra) · mantener oprimido o
/// arrastrar = confirmado (círculo con avatar) · X grandes.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';

/// Payload de arrastre desde el panel. Soltar un sospechoso = CONFIRMARLO.
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
  Color(0xFF7E57C2),
  Color(0xFF26C6DA),
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
  Color(0xFFA1887F),
  Color(0xFF90CAF9),
  Color(0xFFFFAB91),
  Color(0xFFCE93D8),
  Color(0xFFAED581),
  Color(0xFF80DEEA),
  Color(0xFFF48FB1),
  Color(0xFFFFE082),
];

Color charColor(PuzzleCase pc, String charId) =>
    charPalette[pc.characters.indexWhere((c) => c.id == charId) %
        charPalette.length];

/// Icono por tipo de mueble.
IconData objectIcon(ObjectType type) => switch (type) {
      ObjectType.silla => Icons.chair_alt,
      ObjectType.sillon => Icons.chair,
      ObjectType.sofa => Icons.weekend,
      ObjectType.cama => Icons.bed,
      ObjectType.alfombra => Icons.texture,
      ObjectType.mesa => Icons.table_restaurant,
      ObjectType.tv => Icons.tv,
      ObjectType.planta => Icons.local_florist,
      ObjectType.arbusto => Icons.grass,
      ObjectType.armario => Icons.door_sliding,
      ObjectType.caja => Icons.inventory_2,
      ObjectType.lavadora => Icons.local_laundry_service,
      ObjectType.piano => Icons.piano,
      ObjectType.barra => Icons.countertops,
    };

class BoardView extends ConsumerWidget {
  final PuzzleCase pc;

  /// La pantalla decide cómo reaccionar (mensajes, diálogo de reemplazo).
  final void Function(int cell, Tool tool, {required bool confirm}) onPlace;
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
                          child: _Cell(
                              pc: pc,
                              cell: map.cellAt(r, c),
                              onPlace: onPlace)),
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
  final void Function(int cell, Tool tool, {required bool confirm}) onPlace;
  const _Cell({required this.pc, required this.cell, required this.onPlace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final state = ref.watch(gameControllerProvider(pc));
    final map = pc.map;
    final r = map.row(cell), c = map.col(cell);
    final areaIdx = map.areas.indexWhere((a) => a.id == map.areaIdOf(cell));
    final obj = map.objectAt(cell);
    final blocked = obj != null && obj.blocks;
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
      onAcceptWithDetails: (d) => onPlace(cell, d.data.tool, confirm: true),
      builder: (context, hovering, _) => GestureDetector(
        onTap: () {
          if (blocked) return;
          if (state.tool != null) {
            onPlace(cell, state.tool!, confirm: false);
          } else if (content.elementCount > 0) {
            _showMiniPanel(context, controller, state.board.elementsOf(cell));
          }
        },
        onLongPress: () {
          if (blocked || state.tool == null) return;
          onPlace(cell, state.tool!, confirm: true);
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
                      fontSize: state.mapMode ? 10 : 13,
                      color: Brand.cream.withValues(alpha: .35)),
                ),
              ),
              if (isAreaAnchor)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Tooltip(
                    message:
                        'Armas: ${weapons.map((w) => w.nameEs).join(', ')}',
                    child: const Icon(Icons.colorize,
                        size: 12, color: Brand.goldBright),
                  ),
                ),
              // Mueble bloqueante: ocupa la celda.
              if (blocked)
                Center(
                  child: Tooltip(
                    message: '${obj.type.defEs} (bloquea)',
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(objectIcon(obj.type),
                            color: Brand.cream.withValues(alpha: .55),
                            size: 22),
                      ),
                    ),
                  ),
                ),
              // Mueble pisable: se dibuja tenue debajo de las marcas.
              if (obj != null && !blocked)
                Center(
                  child: Tooltip(
                    message: '${obj.type.defEs} (puedes colocar encima)',
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(objectIcon(obj.type),
                            color: Brand.cream
                                .withValues(alpha: state.mapMode ? .35 : .18),
                            size: 24),
                      ),
                    ),
                  ),
                ),
              if (!blocked)
                Positioned.fill(child: _CellMarks(pc: pc, cell: cell)),
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
        title: const Text('Borrar de esta casilla',
            style: TextStyle(fontSize: 16)),
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
          '${pc.character(charId).nameEs} (confirmado — quita sus X automáticas)',
        CandidateElement(:final charId) =>
          '${pc.character(charId).nameEs} (candidato)',
        XElement() => 'X',
      };
}

class _CellMarks extends ConsumerWidget {
  final PuzzleCase pc;
  final int cell;
  const _CellMarks({required this.pc, required this.cell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content =
        ref.watch(gameControllerProvider(pc).select((s) => s.board.cell(cell)));

    // Confirmado: círculo con avatar que llena la celda.
    if (content.confirmed != null) {
      return Center(
        child: _draggableMark(
          ConfirmedElement(content.confirmed!),
          _ConfirmedAvatar(pc: pc, charId: content.confirmed!),
        ),
      );
    }

    final hasMarks = content.candidates.isNotEmpty || content.hasX;
    if (!hasMarks) return const SizedBox.shrink();

    // X (manual o automática): grande, llenando la celda.
    final xWidget = content.hasX
        ? _draggableMark(
            XElement(content.x ?? XLevel.large),
            _XMark(
              level: content.x ?? XLevel.large,
              isAuto: content.x == null,
            ),
          )
        : null;

    // Candidatos: solo letras.
    final letters = [
      for (final id in content.candidates)
        _draggableMark(CandidateElement(id), _CandidateLetter(pc: pc, charId: id)),
    ];

    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          if (xWidget != null)
            Positioned.fill(child: Center(child: xWidget)),
          if (letters.isNotEmpty)
            Positioned.fill(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Wrap(spacing: 1, children: letters),
                ),
              ),
            ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, box) {
        final d = (box.maxWidth.isFinite ? box.maxWidth : 48) * .78;
        return Container(
          width: d.clamp(26, 56),
          height: d.clamp(26, 56),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Brand.cream, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4),
            ],
          ),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  isVictim ? '†' : pc.character(charId).nameEs[0],
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 22),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CandidateLetter extends StatelessWidget {
  final PuzzleCase pc;
  final String charId;
  const _CandidateLetter({required this.pc, required this.charId});

  @override
  Widget build(BuildContext context) {
    final isVictim = charId == pc.victimId;
    return Text(
      isVictim ? '†' : pc.character(charId).nameEs[0],
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: charColor(pc, charId),
        shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
      ),
    );
  }
}

class _XMark extends StatelessWidget {
  final XLevel level;
  final bool isAuto;
  const _XMark({required this.level, this.isAuto = false});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final base = box.maxWidth.isFinite ? box.maxWidth : 48;
          final size = base * (level == XLevel.small ? .5 : .8);
          return Text(
            '✕',
            style: TextStyle(
              fontSize: size.clamp(14, 52),
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: isAuto ? .55 : .85),
              shadows: const [Shadow(color: Colors.white24, blurRadius: 2)],
            ),
          );
        },
      );
}
