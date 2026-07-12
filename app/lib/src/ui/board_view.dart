/// Tablero jugable: marco con profundidad, habitaciones con gradiente y
/// etiqueta de nombre (estilo Murdoku), muebles a color dibujados como UNA
/// pieza continua sobre sus celdas (camas/sofás/mesas/alfombras de 2
/// casillas se ven alargados), marcas y drag & drop.
/// Interacción: tap = candidato (letra) · mantener oprimido o arrastrar =
/// confirmado (círculo con avatar) · X grandes.
library;

import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';
import 'furniture_painters.dart';

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

/// Paleta para habitaciones (modo mapa): papeles de colores del estilo
/// paper craft (mockup 05). En modo lógica se atenúan.
const areaPalette = [
  Color(0xFFCE9455), // kraft tostado
  Color(0xFF6FA3B8), // papel azul
  Color(0xFFC77E66), // papel terracota
  Color(0xFF84AE5C), // papel verde
  Color(0xFFB088C9), // papel lila
  Color(0xFFD9A93C), // papel mostaza
  Color(0xFF5CA88C), // papel menta
  Color(0xFFC9708A), // papel rosa
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

/// Color propio de cada mueble (madera, tela, vegetación...).
Color objectColor(ObjectType type) => switch (type) {
      ObjectType.silla || ObjectType.sillon => const Color(0xFFD7B98E),
      ObjectType.sofa => const Color(0xFFCF8B6E),
      ObjectType.cama => const Color(0xFFA8CBEA),
      ObjectType.alfombra => const Color(0xFFC59BD6),
      ObjectType.mesa || ObjectType.barra => const Color(0xFFC49A6C),
      ObjectType.tv => const Color(0xFF86B9D6),
      ObjectType.planta || ObjectType.arbusto => const Color(0xFF8BC97B),
      ObjectType.armario => const Color(0xFFB08A5E),
      ObjectType.caja => const Color(0xFFD0A95E),
      ObjectType.lavadora => const Color(0xFFA9BCCD),
      ObjectType.piano => const Color(0xFF9C9CA8),
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
      child: Container(
        // Marco de corcho/cartón del tablero de evidencias.
        decoration: BoxDecoration(
          color: const Color(0xFF8A6C46),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6E5432), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x664A3A26),
                blurRadius: 18,
                offset: Offset(0, 10)),
            BoxShadow(color: Color(0x338A6C46), blurRadius: 0, spreadRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: IgnorePointer(
            ignoring: state.locked || state.solved,
            child: LayoutBuilder(
              builder: (context, box) {
                final cs = box.maxWidth / n;
                return Stack(
                  children: [
                    // Capa 0 — hoja de papel base del plano.
                    Positioned.fill(
                        child: Container(color: const Color(0xFFF2E7CD))),
                    // Capa 1 — muebles, dibujados como una pieza continua
                    // sobre sus celdas (van DEBAJO de las marcas).
                    if (state.mapMode)
                      for (final furniture in _furniture(map, cs)) furniture,
                    // Capa 2 — celdas: fondo de habitación tenue, paredes,
                    // marcas e interacción (drag & drop, taps).
                    Column(
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
                    // Capa 3 — nombres de habitación sobre el mapa.
                    if (state.mapMode)
                      for (final label in _areaLabels(map, cs, box.maxWidth))
                        label,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Una pieza por mueble, abarcando todas sus celdas (1 o 2), dibujada
  /// como ilustración top-down (cama con almohada, sofá con cojines...).
  /// Los muebles pisables van levemente atenuados para que las marcas del
  /// jugador se lean bien encima.
  List<Widget> _furniture(GameMap map, double cs) {
    final widgets = <Widget>[];
    for (final obj in map.objects) {
      final rows = obj.cells.map((c) => map.row(c));
      final cols = obj.cells.map((c) => map.col(c));
      final minR = rows.reduce(math.min), maxR = rows.reduce(math.max);
      final minC = cols.reduce(math.min), maxC = cols.reduce(math.max);
      final w = (maxC - minC + 1) * cs;
      final h = (maxR - minR + 1) * cs;

      widgets.add(Positioned(
        left: minC * cs,
        top: minR * cs,
        width: w,
        height: h,
        child: Padding(
          padding: EdgeInsets.all(cs * .09),
          child: Opacity(
            opacity: obj.blocks ? 1 : .88,
            child: CustomPaint(
              painter: FurniturePainter(obj.type),
              size: Size(w - cs * .18, h - cs * .18),
            ),
          ),
        ),
      ));
    }
    return widgets;
  }

  List<Widget> _areaLabels(GameMap map, double cs, double boardW) {
    final labels = <Widget>[];
    final fontSize = (cs * .30).clamp(9.0, 15.0);
    for (final area in map.areas) {
      // Celda inferior-izquierda de la habitación para anclar la etiqueta.
      var best = area.cells.first;
      for (final c in area.cells) {
        if (map.row(c) > map.row(best) ||
            (map.row(c) == map.row(best) && map.col(c) < map.col(best))) {
          best = c;
        }
      }
      final name = area.nameEs
          .replaceFirst(RegExp(r'^(el|la|los|las)\s', caseSensitive: false), '')
          .toUpperCase();
      final estWidth = name.length * fontSize * .68 + 6;
      final left = math.min(
          map.col(best) * cs + 3, math.max(0.0, boardW - estWidth));
      final top = map.row(best) * cs + cs - fontSize - 7;
      labels.add(Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Text(
            name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 3),
                Shadow(color: Colors.black, offset: Offset(1.2, 1.2)),
                Shadow(color: Colors.black, offset: Offset(-1.2, 1.2)),
                Shadow(color: Colors.black, offset: Offset(1.2, -1.2)),
                Shadow(color: Colors.black, offset: Offset(-1.2, -1.2)),
              ],
            ),
          ),
        ),
      ));
    }
    return labels;
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

    // Pared (gruesa) entre habitaciones distintas. Entre dos celdas del
    // MISMO mueble no hay línea, para que se vea como una pieza continua.
    bool wall(int rr, int cc) =>
        !map.inGrid(rr, cc) ||
        map.areaIdOf(map.cellAt(rr, cc)) != map.areaIdOf(cell);
    bool sameObject(int rr, int cc) {
      if (!map.inGrid(rr, cc)) return false;
      final o = map.objectAt(cell);
      return o != null && o.id == map.objectAt(map.cellAt(rr, cc))?.id;
    }

    // Paredes de tinta gruesas entre habitaciones (plano dibujado a
    // marcador sobre papel); grilla interior como costura tenue.
    final wallColor = const Color(0xFF3D2C14);
    final gridColor = const Color(0xFF3D2C14).withValues(alpha: .25);
    BorderSide side(int rr, int cc) {
      if (sameObject(rr, cc)) return BorderSide.none;
      final isWall = wall(rr, cc);
      return BorderSide(
          color: isWall ? wallColor : gridColor, width: isWall ? 3.5 : 0.6);
    }

    // Colores de habitación más vivos: se mezclan hacia el blanco y con
    // más opacidad para que se distingan bien (feedback 2026-06-12).
    final basePalette =
        Color.lerp(areaPalette[areaIdx % areaPalette.length], Colors.white, .12)!;
    // Si hay mueble (dibujado debajo), el fondo de la celda es más tenue
    // para dejarlo ver.
    final hasObj = obj != null;
    final hi = state.mapMode ? (hasObj ? .32 : .64) : (hasObj ? .07 : .15);
    final lo = state.mapMode ? (hasObj ? .20 : .46) : (hasObj ? .04 : .09);

    // Indicador de armas: en la primera celda del área.
    final weapons = map.weaponsInArea(map.areaIdOf(cell));
    final isAreaAnchor =
        weapons.isNotEmpty && map.areas[areaIdx].cells.first == cell;

    return DragTarget<PanelDrag>(
      onWillAcceptWithDetails: (_) => !blocked,
      onAcceptWithDetails: (d) => onPlace(cell, d.data.tool, confirm: true),
      builder: (context, hovering, _) {
        final body = GestureDetector(
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isError
                  ? [
                      Brand.error.withValues(alpha: .55),
                      Brand.error.withValues(alpha: .35)
                    ]
                  : hovering.isNotEmpty
                      ? [
                          Brand.goldBright.withValues(alpha: .45),
                          Brand.gold.withValues(alpha: .30)
                        ]
                      : [
                          basePalette.withValues(alpha: hi),
                          basePalette.withValues(alpha: lo)
                        ],
            ),
            border: Border(
              top: side(r - 1, c),
              bottom: side(r + 1, c),
              left: side(r, c - 1),
              right: side(r, c + 1),
            ),
          ),
          child: Stack(
            children: [
              if (isAreaAnchor)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Tooltip(
                    message:
                        'Armas: ${weapons.map((w) => w.nameEs).join(', ')}',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.colorize,
                          size: 11, color: Brand.goldBright),
                    ),
                  ),
                ),
              if (!blocked)
                Positioned.fill(child: _CellMarks(pc: pc, cell: cell)),
            ],
          ),
        ),
        );
        if (obj == null) return body;
        // Tooltip con el nombre del mueble al pasar el mouse (el tooltip de
        // la pieza dibujada quedaba debajo de la celda y no recibía hover).
        return Tooltip(
          message: obj.blocks
              ? obj.type.nameEs[0].toUpperCase() + obj.type.nameEs.substring(1)
              : '${obj.type.nameEs[0].toUpperCase()}${obj.type.nameEs.substring(1)} · '
                  'puedes colocar a alguien encima',
          waitDuration: const Duration(milliseconds: 250),
          child: body,
        );
      },
    );
  }

  /// Mini panel de borrado (doc 06, pantalla 22): solo sirve para borrar;
  /// se cierra al borrar un elemento.
  void _showMiniPanel(BuildContext context, GameController controller,
      List<CellElement> elements) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
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
        _draggableMark(
            CandidateElement(id), _CandidateLetter(pc: pc, charId: id)),
    ];

    return Stack(
      children: [
        if (xWidget != null) Positioned.fill(child: Center(child: xWidget)),
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
        final d = (box.maxWidth.isFinite ? box.maxWidth : 48) * .80;
        return Container(
          width: d.clamp(26, 58),
          height: d.clamp(26, 58),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, .25)!,
                color,
                Color.lerp(color, Colors.black, .25)!,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              const BoxShadow(
                  color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
              BoxShadow(
                  color: color.withValues(alpha: .55),
                  blurRadius: 14,
                  spreadRadius: 1),
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
    // Letra "a lápiz" sobre el papel: color del personaje oscurecido.
    return Text(
      isVictim ? '†' : pc.character(charId).nameEs[0],
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Color.lerp(charColor(pc, charId), const Color(0xFF3D2C14), .45),
        shadows: const [
          Shadow(color: Color(0x66FFFBEA), offset: Offset(1, 1)),
        ],
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
          final size = base * (level == XLevel.small ? .5 : .82);
          // Trazo de marcador rojo sobre el papel (auto-X más tenue).
          return Text(
            '✕',
            style: TextStyle(
              fontSize: size.clamp(14, 54),
              height: 1,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF8A2F1B)
                  .withValues(alpha: isAuto ? .45 : .88),
            ),
          );
        },
      );
}
