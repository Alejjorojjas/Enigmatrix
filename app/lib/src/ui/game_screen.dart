/// Pantalla de partida (doc 06, pantalla 19): tablero, pistas, panel de
/// sospechosos, papelera, deshacer/rehacer, limpiar, resolver.
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
            controller.place(cell,
                charId: tool.charId, markState: tool.state, replace: true);
          }
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

    void onPlace(int cell, Tool tool) async {
      final fb = switch (tool) {
        SuspectTool(:final charId, :final state) =>
          controller.place(cell, charId: charId, markState: state),
        XTool(:final level) => controller.placeXMark(cell, level),
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
        const SizedBox(height: 12),
        _Controls(pc: pc, onFeedback: handleFeedback),
      ],
    );

    final cluePanel = _CluePanel(pc: pc);
    final suspectPanel = _SuspectPanel(pc: pc);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(
            '${pc.map.nameEs} · ${pc.difficulty}'
            '${pc.hasWeapon ? ' · 🗡 caso con arma' : ''}',
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
                SizedBox(width: 330, child: cluePanel),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: boardColumn,
                )),
                SizedBox(width: 240, child: suspectPanel),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [boardColumn, suspectPanel, cluePanel],
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
    final murderer = state.murdererId == null
        ? null
        : pc.character(state.murdererId!);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 18, color: Brand.muted),
        const SizedBox(width: 4),
        Text(_fmt(state.elapsedSeconds),
            style: const TextStyle(fontSize: 18, fontFeatures: [])),
        const SizedBox(width: 24),
        const Icon(Icons.close, size: 18, color: Brand.error),
        const SizedBox(width: 4),
        Text('${state.errorCount} errores'),
        const SizedBox(width: 24),
        if (state.solved)
          const Text('✓ RESUELTO',
              style: TextStyle(
                  color: Brand.success, fontWeight: FontWeight.bold)),
        if (state.locked && !state.solved)
          const Text('Bloqueado…', style: TextStyle(color: Brand.error)),
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
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Brand.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          onPressed: state.solved
              ? null
              : () => onFeedback(controller.solve()),
          icon: const Icon(Icons.gavel),
          label: const Text('RESOLVER',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _CluePanel extends ConsumerWidget {
  final PuzzleCase pc;
  const _CluePanel({required this.pc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks =
        ref.watch(gameControllerProvider(pc).select((s) => s.clueMarks));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('PISTAS',
            style: TextStyle(
                color: Brand.gold, letterSpacing: 3, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Toca una pista para destacarla o tacharla',
            style: TextStyle(color: Brand.muted, fontSize: 12)),
        const SizedBox(height: 8),
        for (var i = 0; i < pc.clues.length; i++)
          InkWell(
            onTap: () => controller.cycleClue(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${i + 1}. ${_capitalize(pc.clues[i].textEs(pc.map, pc.nameOf))}',
                style: switch (marks[i]) {
                  ClueMark.normal => const TextStyle(fontSize: 14, height: 1.3),
                  ClueMark.highlighted => const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Brand.goldBright,
                      fontWeight: FontWeight.bold),
                  ClueMark.struck => TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Brand.muted.withValues(alpha: .6),
                      decoration: TextDecoration.lineThrough),
                },
              ),
            ),
          ),
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Habitaciones y armas',
              style: TextStyle(fontSize: 14, color: Brand.muted)),
          children: [
            for (var i = 0; i < pc.map.areas.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      color: areaPalette[i % areaPalette.length]
                          .withValues(alpha: .6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode('a'.codeUnitAt(0) + i)} = '
                        '${pc.map.areas[i].nameEs}'
                        '${pc.map.weaponsInArea(pc.map.areas[i].id).isEmpty ? '' : ' · 🗡 ${pc.map.weaponsInArea(pc.map.areas[i].id).map((w) => w.nameEs).join(', ')}'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Reglas: una persona por fila y por columna. El asesino quedó '
          'a solas con la víctima en la misma habitación.',
          style: TextStyle(color: Brand.muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _SuspectPanel extends ConsumerWidget {
  final PuzzleCase pc;
  const _SuspectPanel({required this.pc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('PERSONAJES',
            style: TextStyle(
                color: Brand.gold, letterSpacing: 3, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Toca: candidato → confirmado. Arrastra al tablero.',
            style: TextStyle(color: Brand.muted, fontSize: 12)),
        const SizedBox(height: 10),
        for (final ch in pc.characters)
          _SuspectChip(pc: pc, charId: ch.id, state: state,
              onTap: () => controller.tapSuspect(ch.id)),
        const Divider(height: 28),
        _XChip(state: state, onTap: controller.tapX),
        const SizedBox(height: 20),
        _Trash(pc: pc),
      ],
    );
  }
}

class _SuspectChip extends StatelessWidget {
  final PuzzleCase pc;
  final String charId;
  final GameState state;
  final VoidCallback onTap;
  const _SuspectChip(
      {required this.pc,
      required this.charId,
      required this.state,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tool = state.tool;
    final selected = tool is SuspectTool && tool.charId == charId;
    final markState = selected ? tool.state : SuspectMarkState.candidate;
    final isVictim = charId == pc.victimId;
    final color = charColor(pc, charId);

    final chip = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Brand.gold.withValues(alpha: .18) : Brand.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? (markState == SuspectMarkState.confirmed
                  ? Brand.success
                  : Brand.goldBright)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: selected && markState == SuspectMarkState.confirmed
                ? 18
                : 14,
            backgroundColor: color,
            child: Text(
              isVictim ? '†' : pc.character(charId).nameEs[0],
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pc.character(charId).nameEs,
                    style: const TextStyle(fontSize: 14)),
                if (isVictim)
                  const Text('LA VÍCTIMA',
                      style: TextStyle(
                          fontSize: 10,
                          color: Brand.error,
                          letterSpacing: 1.5)),
              ],
            ),
          ),
          if (selected)
            Text(
              markState == SuspectMarkState.candidate ? '?' : '✓',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: markState == SuspectMarkState.candidate
                      ? Brand.goldBright
                      : Brand.success),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Draggable<PanelDrag>(
        data: PanelDrag(SuspectTool(charId, markState)),
        feedback: Material(
          color: Colors.transparent,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(isVictim ? '†' : pc.character(charId).nameEs[0],
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ),
        child: chip,
      ),
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
      builder: (context, hovering, _) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: hovering.isNotEmpty
              ? Brand.error.withValues(alpha: .3)
              : Brand.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hovering.isNotEmpty ? Brand.error : Brand.muted,
              width: hovering.isNotEmpty ? 2.5 : 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 26),
            Text('Papelera — arrastra aquí para borrar',
                style: TextStyle(fontSize: 11, color: Brand.muted)),
          ],
        ),
      ),
    );
  }
}
