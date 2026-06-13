/// Pantalla de partida (doc 06, pantalla 19): tablero, tarjetas de
/// personajes con su pista (formato Murdoku), papelera, deshacer/rehacer,
/// limpiar, resolver.
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../data/case_repository.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';
import 'board_view.dart';

class GameScreen extends ConsumerWidget {
  final String caseId;
  const GameScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = ref.watch(caseByIdProvider(caseId));
    if (pc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _GameView(pc: pc);
  }
}

class _GameView extends ConsumerWidget {
  final PuzzleCase pc;
  const _GameView({required this.pc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    void showMsg(String text) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));
    }

    Future<void> handleFeedback(ActionFeedback fb,
        {int? cell, Tool? tool}) async {
      switch (fb) {
        case ActionFeedback.cellHasConfirmed:
          // Mensaje literal del doc 03.
          showMsg('Esta casilla ya tiene una decisión confirmada, '
              'borra primero para colocar candidato');
        case ActionFeedback.askReplaceConfirmed:
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Brand.surface,
              title: const Text('¿Reemplazar confirmado?'),
              content: const Text(
                  'Esta casilla ya tiene una decisión confirmada. '
                  '¿Quieres reemplazarla?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Reemplazar')),
              ],
            ),
          );
          if (yes == true && cell != null && tool is SuspectTool) {
            controller.placeSuspect(cell,
                charId: tool.charId, confirm: true, replace: true);
          }
        case ActionFeedback.cellHasX:
          showMsg('Esta casilla está descartada con una X — '
              'bórrala primero para anotar candidatos');
        case ActionFeedback.alreadyConfirmedElsewhere:
          showMsg('Ese personaje ya está confirmado en otra casilla — '
              'borra esa confirmación primero');
        case ActionFeedback.incompleteBoard:
          showMsg('Confirma a cada personaje exactamente una vez '
              'antes de resolver');
        case ActionFeedback.wrongSolution:
          showMsg('Hay errores en el tablero: revisa las casillas marcadas');
        case ActionFeedback.solvedOk:
          if (context.mounted) _showSummary(context, ref);
        case ActionFeedback.ok:
          break;
      }
    }

    // Tap = candidato (letra) · mantener oprimido o arrastrar = confirmado.
    // Con el borrador seleccionado, tocar limpia la casilla.
    void onPlace(int cell, Tool tool, {required bool confirm}) async {
      final fb = switch (tool) {
        SuspectTool(:final charId) =>
          controller.placeSuspect(cell, charId: charId, confirm: confirm),
        XTool(:final level) => controller.placeXMark(cell, level),
        EraserTool() => controller.eraseCell(cell),
      };
      await handleFeedback(fb, cell: cell, tool: tool);
    }

    final boardColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Header(pc: pc),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
          child: BoardView(pc: pc, onPlace: onPlace),
        ),
        const SizedBox(height: 10),
        // Papelera pegada al tablero: arrastrar marcas aquí sin alejarse.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _Trash(pc: pc),
        ),
        const SizedBox(height: 10),
        _Controls(pc: pc, onFeedback: handleFeedback),
      ],
    );

    final infoPanel = _InfoPanel(pc: pc, shrink: false);
    final suspectPanel = _SuspectPanel(pc: pc, shrink: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(
            '${pc.map.nameEs} · ${pc.difficulty}'
            '${pc.hasWeapon ? ' · caso con arma' : ''}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          if (state.solved)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton(
                onPressed: () => _showSummary(context, ref),
                child: const Text('Ver resumen'),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth > 1150) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: suspectPanel),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: boardColumn,
                )),
                SizedBox(width: 280, child: infoPanel),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                boardColumn,
                _SuspectPanel(pc: pc, shrink: true),
                _InfoPanel(pc: pc, shrink: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSummary(BuildContext context, WidgetRef ref) async {
    final state = ref.read(gameControllerProvider(pc));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'done:${pc.caseId}',
        jsonEncode({
          'time': state.elapsedSeconds,
          'errors': state.errorCount,
          'date': DateTime.now().toIso8601String().substring(0, 16),
        }));
    final fbController =
        TextEditingController(text: prefs.getString('fb:${pc.caseId}') ?? '');

    if (!context.mounted) return;
    final murderer =
        state.murdererId == null ? null : pc.character(state.murdererId!);
    final weapon = state.lethalWeaponId == null
        ? null
        : pc.map.weapons.firstWhere((w) => w.id == state.lethalWeaponId);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        title: const Text('🎉 ¡Caso resuelto!'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('El asesino era ${murderer?.nameEs ?? '?'}, que quedó a '
                  'solas con la víctima.'),
              if (weapon != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Arma homicida: ${weapon.nameEs}.'),
                ),
              const SizedBox(height: 12),
              Text('Tiempo: ${_fmt(state.elapsedSeconds)}   ·   '
                  'Errores de resolver: ${state.errorCount}'),
              const SizedBox(height: 16),
              const Text('Feedback de playtest (¿pistas confusas? '
                  '¿dificultad justa?):'),
              const SizedBox(height: 8),
              TextField(
                controller: fbController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tus notas sobre este caso...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setString('fb:${pc.caseId}', fbController.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar y seguir mirando'),
          ),
          FilledButton(
            onPressed: () async {
              await prefs.setString('fb:${pc.caseId}', fbController.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ctx.go('/');
              }
            },
            child: const Text('Guardar y volver a la lista'),
          ),
        ],
      ),
    );
  }
}

String _fmt(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

class _Header extends ConsumerWidget {
  final PuzzleCase pc;
  const _Header({required this.pc});

  Widget _chip(Widget icon, String text, {Color? border}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Brand.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: (border ?? Brand.gold).withValues(alpha: .45)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _chip(
            const Icon(Icons.timer_outlined,
                size: 17, color: Brand.goldBright),
            _fmt(state.elapsedSeconds)),
        _chip(const Icon(Icons.close, size: 17, color: Brand.error),
            '${state.errorCount} errores',
            border: Brand.error),
        if (state.solved)
          _chip(
              const Icon(Icons.check_circle,
                  size: 17, color: Brand.success),
              'RESUELTO',
              border: Brand.success),
        if (state.locked && !state.solved)
          _chip(const Icon(Icons.lock_clock, size: 17, color: Brand.error),
              'Bloqueado…',
              border: Brand.error),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  final PuzzleCase pc;
  final Future<void> Function(ActionFeedback, {int? cell, Tool? tool})
      onFeedback;
  const _Controls({required this.pc, required this.onFeedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: 'Deshacer',
          onPressed: state.canUndo ? controller.undo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: 'Rehacer',
          onPressed: state.canRedo ? controller.redo : null,
          icon: const Icon(Icons.redo),
        ),
        TextButton.icon(
          onPressed: state.board.isEmpty
              ? null
              : () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Brand.surface,
                      title: const Text('¿Limpiar tablero?'),
                      content: const Text(
                          'Se borran las marcas del tablero y de las pistas. '
                          'El tiempo y los errores se mantienen.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar')),
                        FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Limpiar')),
                      ],
                    ),
                  );
                  if (yes == true) controller.clearBoard();
                },
          icon: const Icon(Icons.cleaning_services_outlined, size: 18),
          label: const Text('Limpiar'),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Mapa')),
            ButtonSegment(value: false, label: Text('Notas')),
          ],
          selected: {state.mapMode},
          onSelectionChanged: (_) => controller.toggleMapMode(),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        Tooltip(
          message:
              'Al confirmar a alguien, tacha su fila y columna automáticamente',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: state.autoX,
                onChanged: (_) => controller.toggleAutoX(),
                activeTrackColor: Brand.gold,
              ),
              const Text('Auto-X', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: state.solved ? null : Brand.goldGradient,
            color: state.solved ? Brand.surface : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: state.solved
                ? null
                : [
                    BoxShadow(
                        color: Brand.gold.withValues(alpha: .45),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed:
                state.solved ? null : () => onFeedback(controller.solve()),
            icon: const Icon(Icons.gavel),
            label: const Text('RESOLVER',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Panel de personajes: tarjeta con avatar + SU pista (formato Murdoku).
/// Tocar el avatar selecciona (candidato → confirmado); tocar la pista la
/// destaca/tacha; arrastrar el avatar lo lleva al tablero.
class _SuspectPanel extends ConsumerWidget {
  final PuzzleCase pc;
  final bool shrink;
  const _SuspectPanel({required this.pc, required this.shrink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return ListView(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        const Text('PERSONAJES',
            style: TextStyle(
                color: Brand.gold,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
            'Toca el avatar para seleccionar. En el tablero: toca = anotar '
            'la letra · mantén oprimido o arrastra = confirmar. '
            'Toca la pista para destacarla o tacharla.',
            style: TextStyle(color: Brand.muted, fontSize: 12)),
        const SizedBox(height: 10),
        for (final ch in pc.characters)
          _SuspectCard(
              pc: pc,
              charId: ch.id,
              state: state,
              onTapAvatar: () => controller.tapSuspect(ch.id),
              onTapClue: (i) => controller.cycleClue(i)),
        const Divider(height: 28),
        const Text('HERRAMIENTAS',
            style: TextStyle(
                color: Brand.gold,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 8),
        _XChip(state: state, onTap: controller.tapX),
        const SizedBox(height: 8),
        _EraserChip(state: state, onTap: controller.tapEraser),
      ],
    );
  }
}

/// Borrador: selecciónalo y toca casillas para limpiarlas.
class _EraserChip extends StatelessWidget {
  final GameState state;
  final VoidCallback onTap;
  const _EraserChip({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = state.tool is EraserTool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Brand.gold.withValues(alpha: .18) : Brand.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? Brand.goldBright : Brand.muted.withValues(alpha: .4),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.backspace_outlined,
                size: 20,
                color: selected ? Brand.goldBright : Brand.cream),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected
                    ? 'Borrador activo: toca casillas para limpiarlas'
                    : 'Borrador (toca y limpia casillas)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuspectCard extends StatelessWidget {
  final PuzzleCase pc;
  final String charId;
  final GameState state;
  final VoidCallback onTapAvatar;
  final void Function(int clueIndex) onTapClue;
  const _SuspectCard({
    required this.pc,
    required this.charId,
    required this.state,
    required this.onTapAvatar,
    required this.onTapClue,
  });

  @override
  Widget build(BuildContext context) {
    final tool = state.tool;
    final selected = tool is SuspectTool && tool.charId == charId;
    final isVictim = charId == pc.victimId;
    final color = charColor(pc, charId);

    final clue = pc.clueFor(charId);
    final clueIndex = clue == null ? -1 : pc.clues.indexOf(clue);
    final clueMark =
        clueIndex >= 0 ? state.clueMarks[clueIndex] : ClueMark.normal;

    Widget avatar(double radius) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, .3)!,
                color,
                Color.lerp(color, Colors.black, .2)!,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Text(
              isVictim ? '†' : pc.character(charId).nameEs[0],
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: radius * .95),
            ),
          ),
        );

    // Tarjeta estilo "polaroid" del cuadernillo Murdoku: fondo claro,
    // nombre manuscrito, pista en burbuja.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isVictim ? const Color(0xFFF2E3DD) : Brand.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Brand.goldBright
              : Colors.black.withValues(alpha: .25),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          const BoxShadow(
              color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
          if (selected)
            BoxShadow(
                color: Brand.goldBright.withValues(alpha: .5),
                blurRadius: 16),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapAvatar,
            child: Draggable<PanelDrag>(
              data: PanelDrag(SuspectTool(charId)),
              feedback:
                  Material(color: Colors.transparent, child: avatar(24)),
              child: Row(
                children: [
                  avatar(selected ? 19 : 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pc.character(charId).nameEs,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: Brand.scriptFont,
                            fontFamilyFallback: ['cursive', 'Georgia'],
                            fontWeight: FontWeight.w600,
                            color: Brand.inkOnLight,
                            height: 1.1,
                          ),
                        ),
                        if (isVictim)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Brand.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LA VÍCTIMA',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5)),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.touch_app,
                        size: 20, color: Brand.gold),
                ],
              ),
            ),
          ),
          if (clue != null)
            InkWell(
              onTap: clueIndex >= 0 ? () => onTapClue(clueIndex) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: switch (clueMark) {
                    ClueMark.highlighted =>
                      Brand.goldBright.withValues(alpha: .35),
                    _ => Brand.cardLightShade,
                  },
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: clueMark == ClueMark.highlighted
                          ? Brand.gold
                          : Colors.black.withValues(alpha: .12)),
                ),
                child: Text(
                  clue.cardTextEs(pc.map, pc.names),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: clueMark == ClueMark.struck
                        ? Brand.inkOnLight.withValues(alpha: .4)
                        : Brand.inkOnLight,
                    fontWeight: clueMark == ClueMark.highlighted
                        ? FontWeight.w700
                        : FontWeight.w500,
                    decoration: clueMark == ClueMark.struck
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Panel de información: pistas sueltas, habitaciones/armas y reglas,
/// en tarjetas con profundidad.
class _InfoPanel extends ConsumerWidget {
  final PuzzleCase pc;
  final bool shrink;
  const _InfoPanel({required this.pc, required this.shrink});

  Widget _section({required String title, required List<Widget> children}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Brand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Brand.gold.withValues(alpha: .25)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Brand.goldBright,
                    letterSpacing: 2.5,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks =
        ref.watch(gameControllerProvider(pc).select((s) => s.clueMarks));
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final extras = pc.extraClues;

    return ListView(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        if (extras.isNotEmpty)
          _section(title: 'INFORMACIÓN ADICIONAL', children: [
            for (final e in extras)
              Builder(builder: (context) {
                final i = pc.clues.indexOf(e);
                return InkWell(
                  onTap: () => controller.cycleClue(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '· ${e.textEs(pc.map, pc.names)}',
                      style: switch (marks[i]) {
                        ClueMark.normal =>
                          const TextStyle(fontSize: 13, height: 1.3),
                        ClueMark.highlighted => const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Brand.goldBright,
                            fontWeight: FontWeight.bold),
                        ClueMark.struck => TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Brand.muted.withValues(alpha: .6),
                            decoration: TextDecoration.lineThrough),
                      },
                    ),
                  ),
                );
              }),
          ]),
        _section(title: 'HABITACIONES', children: [
          for (var i = 0; i < pc.map.areas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: areaPalette[i % areaPalette.length]
                          .withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pc.map.areas[i].nameEs}'
                      '${pc.map.weaponsInArea(pc.map.areas[i].id).isEmpty ? '' : '  ·  armas: ${pc.map.weaponsInArea(pc.map.areas[i].id).map((w) => w.nameEs).join(', ')}'}',
                      style: const TextStyle(fontSize: 12.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ]),
        _section(title: 'MUEBLES', children: [
          const Text('Pisables: puedes colocar gente encima. '
              'Los demás bloquean su casilla.',
              style: TextStyle(color: Brand.muted, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in {for (final o in pc.map.objects) o.type})
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: objectColor(type).withValues(alpha: .5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(objectIcon(type),
                          size: 14, color: objectColor(type)),
                      const SizedBox(width: 5),
                      Text(
                        '${type.nameEs}${type.standable ? ' ◦' : ''}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('◦ = pisable',
              style: TextStyle(color: Brand.muted, fontSize: 10)),
        ]),
        _section(title: 'REGLAS', children: [
          const Text(
            'Una persona por fila y por columna. El asesino quedó a solas '
            'con la víctima en la misma habitación. Ubica a todos, '
            'incluida la víctima.',
            style: TextStyle(color: Brand.muted, fontSize: 12, height: 1.5),
          ),
        ]),
      ],
    );
  }
}

class _XChip extends StatelessWidget {
  final GameState state;
  final VoidCallback onTap;
  const _XChip({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tool = state.tool;
    final selected = tool is XTool;
    final level = selected ? tool.level : XLevel.small;

    return GestureDetector(
      onTap: onTap,
      child: Draggable<PanelDrag>(
        data: PanelDrag(XTool(level)),
        feedback: const Material(
          color: Colors.transparent,
          child: Text('✕',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Brand.gold.withValues(alpha: .18) : Brand.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? Brand.goldBright : Colors.transparent,
                width: 2),
          ),
          child: Row(
            children: [
              Text('✕',
                  style: TextStyle(
                      fontSize: selected && level == XLevel.large ? 26 : 16,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected
                      ? (level == XLevel.small ? 'X pequeña' : 'X grande')
                      : 'Descarte (X)',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Trash extends ConsumerWidget {
  final PuzzleCase pc;
  const _Trash({required this.pc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider(pc).notifier);
    return DragTarget<BoardElementDrag>(
      onAcceptWithDetails: (d) =>
          controller.removeElement(d.data.cell, d.data.element),
      builder: (context, hovering, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 52,
        decoration: BoxDecoration(
          color: hovering.isNotEmpty
              ? Brand.error.withValues(alpha: .35)
              : Brand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hovering.isNotEmpty ? Brand.error : Brand.muted,
              width: hovering.isNotEmpty ? 2.5 : 1),
          boxShadow: hovering.isNotEmpty
              ? [BoxShadow(color: Brand.error.withValues(alpha: .4), blurRadius: 14)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                size: 24,
                color: hovering.isNotEmpty ? Brand.error : Brand.muted),
            const SizedBox(width: 10),
            Text(
              hovering.isNotEmpty
                  ? 'Suelta para borrar'
                  : 'Papelera — arrastra marcas aquí',
              style: TextStyle(
                  fontSize: 13,
                  color: hovering.isNotEmpty ? Brand.cream : Brand.muted),
            ),
          ],
        ),
      ),
    );
  }
}
