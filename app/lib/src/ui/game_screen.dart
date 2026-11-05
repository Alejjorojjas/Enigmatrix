/// Pantalla de partida (doc 06, pantalla 19): tablero, tarjetas de
/// personajes con su pista (formato Murdoku), papelera, deshacer/rehacer,
/// limpiar, resolver.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../data/case_repository.dart';
import '../game/board_state.dart';
import '../game/game_controller.dart';
import 'board_view.dart';
import 'tutorial_coach.dart';
import 'victory_screen.dart';

class GameScreen extends ConsumerWidget {
  final String caseId;

  /// Modo tutorial (regla 11, ADR-0012): juega el caso propio de
  /// assets/tutorial (no el del banco, [caseId] se ignora), con la guía
  /// paso a paso, sin escribir "done:" y con Saltar siempre visible.
  final bool tutorial;
  const GameScreen({super.key, required this.caseId, this.tutorial = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tutorial) {
      return TutorialLoader(builder: (pc) => _GameView(pc: pc, tutorial: true));
    }
    final pc = ref.watch(caseByIdProvider(caseId));
    if (pc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _GameView(pc: pc, tutorial: tutorial);
  }
}

class _GameView extends ConsumerWidget {
  final PuzzleCase pc;
  final bool tutorial;
  const _GameView({required this.pc, this.tutorial = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    void showMsg(String text, {Duration? duration}) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            duration: duration ?? const Duration(seconds: 4),
          ),
        );
    }

    // Salir con seguridad (regla 10): el avance ya está guardado, pero se
    // pide confirmación para que un toque accidental no saque al jugador.
    Future<void> requestExit() async {
      if (!context.mounted) return;
      if (tutorial) {
        // El tutorial no guarda avance: salir equivale a saltarlo.
        if (ref.read(gameControllerProvider(pc)).solved) {
          await leaveTutorial(context);
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Brand.surface,
            title: const Text('Salir del tutorial'),
            content: const Text(
              'El tutorial no guarda avance. Si sales, '
              'podrás repetirlo desde la lista de casos. ¿Salir?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Seguir practicando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) await leaveTutorial(context);
        return;
      }
      if (ref.read(gameControllerProvider(pc)).solved) {
        context.go('/casos');
        return;
      }
      controller.holdClock();
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Brand.surface,
          title: const Text('Salir del caso'),
          content: const Text('Tu avance queda guardado. ¿Salir del caso?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir jugando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (leave != true) {
        controller.releaseClock();
        return;
      }
      await controller.saveNow();
      // '/casos' y no '/': la raíz pasa por la pantalla de carga.
      if (context.mounted) context.go('/casos');
    }

    Future<void> handleFeedback(
      ActionFeedback fb, {
      int? cell,
      Tool? tool,
    }) async {
      switch (fb) {
        case ActionFeedback.cellHasConfirmed:
          // Mensaje literal del doc 03.
          showMsg(
            'Esta casilla ya tiene una decisión confirmada, '
            'borra primero para colocar candidato',
          );
        case ActionFeedback.askReplaceConfirmed:
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Brand.surface,
              title: const Text('¿Reemplazar confirmado?'),
              content: const Text(
                'Esta casilla ya tiene una decisión confirmada. '
                '¿Quieres reemplazarla?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reemplazar'),
                ),
              ],
            ),
          );
          if (yes == true && cell != null && tool is SuspectTool) {
            controller.placeSuspect(
              cell,
              charId: tool.charId,
              confirm: true,
              replace: true,
            );
          }
        case ActionFeedback.cellHasX:
          showMsg(
            'Esta casilla está descartada con una X — '
            'bórrala primero para anotar candidatos',
          );
        case ActionFeedback.alreadyConfirmedElsewhere:
          showMsg(
            'Ese personaje ya está confirmado en otra casilla — '
            'borra esa confirmación primero',
          );
        case ActionFeedback.noToolSelected:
          showMsg(noToolSelectedMessage, duration: const Duration(seconds: 2));
        case ActionFeedback.incompleteBoard:
          showMsg(
            'Confirma a cada personaje exactamente una vez '
            'antes de resolver',
          );
        case ActionFeedback.wrongSolution:
          // Regla 9: solo se dice cuántas casillas no cuadran, no cuáles.
          // En el tutorial además se marcan en el tablero.
          final n = ref.read(gameControllerProvider(pc)).wrongCount;
          showMsg(
            tutorial
                ? '${wrongCellsMessage(n)}: revisa las marcadas'
                : wrongCellsMessage(n),
          );
        case ActionFeedback.solvedOk:
          if (!context.mounted) break;
          if (tutorial) {
            // El tutorial no usa la pantalla de victoria: esa escribe
            // "done:" y el feedback del caso.
            showTutorialEnd(context, pc, ref.read(gameControllerProvider(pc)));
          } else {
            showVictoryScreen(context, ref, pc);
          }
        case ActionFeedback.ok:
          break;
      }
    }

    // Tap = candidato (letra) · mantener oprimido o arrastrar = confirmado.
    // Con el borrador seleccionado, tocar limpia la casilla.
    void onPlace(int cell, Tool tool, {required bool confirm}) async {
      final fb = switch (tool) {
        SuspectTool(:final charId) => controller.placeSuspect(
          cell,
          charId: charId,
          confirm: confirm,
        ),
        XTool(:final level) => controller.placeXMark(cell, level),
        EraserTool() => controller.eraseCell(cell),
      };
      await handleFeedback(fb, cell: cell, tool: tool);
    }

    final boardColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _keyed(
          tutorial,
          TutorialTargets.header,
          _Header(pc: pc, tutorial: tutorial, onFeedback: handleFeedback),
        ),
        const SizedBox(height: 8),
        _keyed(
          tutorial,
          TutorialTargets.board,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
            child: BoardView(
              pc: pc,
              onPlace: onPlace,
              onNoTool: (cell) =>
                  handleFeedback(controller.placeAt(cell, confirm: false)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Pistas SIEMPRE visibles junto al tablero (pedido del usuario:
        // verlas sin perder el tablero de vista). Tap = destacar/tachar.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _ClueStrip(pc: pc),
        ),
        const SizedBox(height: 6),
        // Papelera pegada al tablero: arrastrar marcas aquí sin alejarse.
        _keyed(
          tutorial,
          TutorialTargets.trash,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _Trash(pc: pc),
          ),
        ),
      ],
    );

    final suspectPanel = _SuspectPanel(
      pc: pc,
      shrink: false,
      tutorial: tutorial,
    );

    // En el tutorial la tarjeta de la guía va ARRIBA, en el flujo de la
    // pantalla (no encima del juego): nunca tapa lo que explica.
    Widget withCoach(Widget game) => !tutorial
        ? game
        : Column(
            children: [
              if (!state.loading && !state.paused) TutorialCoach(pc: pc),
              Expanded(child: game),
            ],
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Salir del caso',
            icon: const Icon(Icons.arrow_back),
            onPressed: requestExit,
          ),
          title: Text(
            tutorial
                ? 'Tutorial · ${pc.map.nameEs}'
                : '${pc.map.nameEs} · ${pc.difficulty}'
                      '${pc.hasWeapon ? ' · caso con arma' : ''}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // Regla 11: Saltar siempre visible (también mientras carga o en
            // pausa). Salta el tutorial y no vuelve a aparecer solo.
            if (tutorial && !state.solved)
              TextButton(
                onPressed: () => leaveTutorial(context),
                child: const Text(
                  'Saltar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            IconButton(
              tooltip: 'Leyenda: habitaciones, muebles y reglas',
              icon: const Icon(Icons.menu_book_rounded),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: Brand.surface,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .8,
                ),
                builder: (_) => _InfoPanel(pc: pc, shrink: false),
              ),
            ),
            if (state.solved)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton(
                  onPressed: () => tutorial
                      ? showTutorialEnd(context, pc, state)
                      : showVictoryScreen(context, ref, pc),
                  child: const Text('Ver resumen'),
                ),
              ),
          ],
        ),
        body: withCoach(
          state.loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          if (box.maxWidth > 1150) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 300, child: suspectPanel),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(child: boardColumn),
                                        _keyed(
                                          tutorial,
                                          TutorialTargets.controls,
                                          _Controls(pc: pc),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                boardColumn,
                                const SizedBox(height: 4),
                                // Personajes justo después del tablero (pedido del usuario).
                                _SuspectPanel(
                                  pc: pc,
                                  shrink: true,
                                  tutorial: tutorial,
                                ),
                                _keyed(
                                  tutorial,
                                  TutorialTargets.controls,
                                  _Controls(pc: pc),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Partida en pausa (app en segundo plano): tapa el tablero y las
                    // pistas hasta que el jugador toque Continuar (regla 10).
                    if (state.paused && !state.solved)
                      Positioned.fill(
                        child: _PausedCover(onContinue: controller.resume),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Asigna a [child] la clave con la que la guía del tutorial lo señala (solo
/// en modo tutorial; fuera de él no cambia nada).
Widget _keyed(bool tutorial, GlobalKey key, Widget child) =>
    tutorial ? KeyedSubtree(key: key, child: child) : child;

/// Aviso al tocar una casilla sin sospechoso ni herramienta (regla 20).
const noToolSelectedMessage =
    'Elige primero a un sospechoso (toca su tarjeta) o una herramienta';

/// Resultado de un Resolver fallido (regla 9): cuántas, nunca cuáles.
String wrongCellsMessage(int count) {
  if (count <= 0) return 'Hay casillas que no cuadran';
  return count == 1 ? '1 casilla no cuadra' : '$count casillas no cuadran';
}

/// Tarjeta que tapa todo mientras la partida está en pausa.
class _PausedCover extends StatelessWidget {
  final VoidCallback onContinue;
  const _PausedCover({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Brand.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Brand.surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Brand.gold.withValues(alpha: .4)),
              boxShadow: const [
                BoxShadow(
                  color: Brand.paperShadow,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_outline,
                  size: 56,
                  color: Brand.goldBright,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Partida en pausa',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El reloj está detenido y el tablero oculto. '
                  'Toca Continuar para seguir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 52),
                  ),
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _fmt(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

class _Header extends ConsumerWidget {
  final PuzzleCase pc;
  final Future<void> Function(ActionFeedback, {int? cell, Tool? tool})
  onFeedback;

  /// En el tutorial se señalan las casillas erróneas (regla 9).
  final bool tutorial;
  const _Header({
    required this.pc,
    required this.onFeedback,
    this.tutorial = false,
  });

  Widget _chip(Widget icon, String text, {Color? border}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Brand.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: (border ?? Brand.gold).withValues(alpha: .45)),
      boxShadow: const [
        BoxShadow(
          color: Brand.paperShadow,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
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
          const Icon(Icons.timer_outlined, size: 17, color: Brand.goldBright),
          _fmt(state.elapsedSeconds),
        ),
        _chip(
          const Icon(Icons.close, size: 17, color: Brand.error),
          '${state.errorCount} errores',
          border: Brand.error,
        ),
        if (state.solved)
          _chip(
            const Icon(Icons.check_circle, size: 17, color: Brand.success),
            'RESUELTO',
            border: Brand.success,
          ),
        if (state.locked && !state.solved)
          _chip(
            const Icon(Icons.lock_clock, size: 17, color: Brand.error),
            'Bloqueado…',
            border: Brand.error,
          ),
        // RESOLVER arriba, junto a los errores (pedido del usuario):
        // siempre visible sin scroll.
        if (!state.solved)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: Brand.goldGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Brand.paperShadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (tutorial) {
                  // Antes del Resolver final la guía enseña uno fallido.
                  final block = tutorialResolveBlock(
                    pc,
                    ref.read(gameControllerProvider(pc)),
                    ref.read(tutorialStepProvider),
                  );
                  if (block != null) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(content: Text(block)));
                    return;
                  }
                }
                final controller = ref.read(
                  gameControllerProvider(pc).notifier,
                );
                onFeedback(controller.solve(revealCells: tutorial));
              },
              icon: const Icon(Icons.gavel, size: 17),
              label: const Text(
                'RESOLVER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  final PuzzleCase pc;
  const _Controls({required this.pc});

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
                        'El tiempo y los errores se mantienen.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Limpiar'),
                        ),
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
      ],
    );
  }
}

/// PISTAS: las tarjetas de los personajes en versión compacta horizontal,
/// fijas bajo el tablero (pedido del usuario: pistas + tablero a la vez,
/// 100% funcionales — tocar selecciona, arrastrar confirma, tocar la
/// pista la destaca/tacha). Sustituye al bloque PERSONAJES.
class _ClueStrip extends ConsumerWidget {
  final PuzzleCase pc;
  const _ClueStrip({required this.pc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 2),
          child: Text(
            'PISTAS',
            style: TextStyle(
              color: Brand.gold,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            'Toca la tarjeta para seleccionar. En el tablero: toca = '
            'anotar la letra · mantén oprimido o arrastra = confirmar. '
            'Toca la pista para destacarla o tacharla; mantenla oprimida '
            'para leerla completa.',
            style: TextStyle(color: Brand.muted, fontSize: 11),
          ),
        ),
        SizedBox(
          height: 136,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final ch in pc.characters)
                SizedBox(
                  width: 205,
                  child: _SuspectCard(
                    pc: pc,
                    charId: ch.id,
                    state: state,
                    compact: true,
                    onTapAvatar: () => controller.tapSuspect(ch.id),
                    onTapClue: (i) => controller.cycleClue(i),
                    onLongPressClue: (i) =>
                        showFullClueSheet(context, pc, ch.id, i),
                  ),
                ),
            ],
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

  /// En el tutorial las herramientas llevan la clave que la guía señala.
  final bool tutorial;
  const _SuspectPanel({
    required this.pc,
    required this.shrink,
    this.tutorial = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider(pc));
    final controller = ref.read(gameControllerProvider(pc).notifier);

    return ListView(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        // Solo HERRAMIENTAS: los personajes viven en el deslizador PISTAS
        // bajo el tablero (el bloque anterior quedó redundante).
        const Text(
          'HERRAMIENTAS',
          style: TextStyle(
            color: Brand.gold,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _keyed(
          tutorial,
          TutorialTargets.xTool,
          _XChip(state: state, onTap: controller.tapX),
        ),
        const SizedBox(height: 8),
        _keyed(
          tutorial,
          TutorialTargets.eraser,
          _EraserChip(state: state, onTap: controller.tapEraser),
        ),
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
            color: selected
                ? Brand.goldBright
                : Brand.muted.withValues(alpha: .4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.backspace_outlined,
              size: 20,
              color: selected ? Brand.goldBright : Brand.cream,
            ),
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

  /// Mantener oprimido el texto de la pista abre la pista completa (H-56).
  final void Function(int clueIndex)? onLongPressClue;
  final bool compact;
  const _SuspectCard({
    required this.pc,
    required this.charId,
    required this.state,
    required this.onTapAvatar,
    required this.onTapClue,
    this.onLongPressClue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tool = state.tool;
    final selected = tool is SuspectTool && tool.charId == charId;
    final isVictim = charId == pc.victimId;
    final color = charColor(pc, charId);

    final clue = pc.clueFor(charId);
    final clueIndex = clue == null ? -1 : pc.clues.indexOf(clue);
    final clueMark = clueIndex >= 0
        ? state.clueMarks[clueIndex]
        : ClueMark.normal;

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
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          isVictim ? '†' : pc.character(charId).nameEs[0],
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: radius * .95,
          ),
        ),
      ),
    );

    // Tarjeta estilo "polaroid" del cuadernillo Murdoku: fondo claro,
    // nombre manuscrito, pista en burbuja. TODA la tarjeta selecciona
    // (pedido del usuario); la burbuja de la pista conserva su propio tap
    // para destacar/tachar.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapAvatar,
      child: Container(
        margin: compact
            ? const EdgeInsets.only(right: 8)
            : const EdgeInsets.only(bottom: 10),
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
              color: Brand.paperShadow,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
            if (selected)
              BoxShadow(
                color: Brand.goldBright.withValues(alpha: .5),
                blurRadius: 16,
              ),
          ],
        ),
        padding: EdgeInsets.all(compact ? 7 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTapAvatar,
              child: Draggable<PanelDrag>(
                data: PanelDrag(SuspectTool(charId)),
                feedback: Material(
                  color: Colors.transparent,
                  child: avatar(24),
                ),
                child: Row(
                  children: [
                    avatar(
                      compact ? (selected ? 16 : 14) : (selected ? 19 : 17),
                    ),
                    SizedBox(width: compact ? 7 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pc.character(charId).nameEs,
                            style: TextStyle(
                              fontSize: compact ? 14.5 : 17,
                              fontFamily: Brand.scriptFont,
                              fontFamilyFallback: const ['cursive', 'Georgia'],
                              fontWeight: FontWeight.w600,
                              color: Brand.inkOnLight,
                              height: 1.1,
                            ),
                          ),
                          if (isVictim)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Brand.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LA VÍCTIMA',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.touch_app, size: 20, color: Brand.gold),
                  ],
                ),
              ),
            ),
            if (clue != null)
              InkWell(
                onTap: clueIndex >= 0 ? () => onTapClue(clueIndex) : null,
                onLongPress: clueIndex >= 0 && onLongPressClue != null
                    ? () => onLongPressClue!(clueIndex)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: EdgeInsets.only(top: compact ? 5 : 8),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: compact ? 4 : 6,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: switch (clueMark) {
                      ClueMark.highlighted => Brand.goldBright.withValues(
                        alpha: .35,
                      ),
                      _ => Brand.cardLightShade,
                    },
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: clueMark == ClueMark.highlighted
                          ? Brand.gold
                          : Colors.black.withValues(alpha: .12),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final text = clue.cardTextEs(pc.map, pc.names);
                      final style = TextStyle(
                        fontSize: compact ? 11.5 : 12.5,
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
                      );
                      // ¿El texto queda cortado con "…"? Entonces se avisa que
                      // hay más para leer (mantener oprimido).
                      var truncated = false;
                      if (compact && box.maxWidth.isFinite) {
                        final painter = TextPainter(
                          text: TextSpan(text: text, style: style),
                          maxLines: 3,
                          textDirection: TextDirection.ltr,
                          textScaler: MediaQuery.textScalerOf(context),
                        )..layout(maxWidth: box.maxWidth);
                        truncated = painter.didExceedMaxLines;
                        painter.dispose();
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            maxLines: compact ? 3 : null,
                            overflow: compact ? TextOverflow.ellipsis : null,
                            style: style,
                          ),
                          if (truncated)
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.unfold_more,
                                    size: 14,
                                    color: Brand.inkOnLight,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'ver más',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: Brand.inkOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Abre la pista completa de un personaje en una hoja inferior (H-56): letra
/// de 16 px o más, nombre del personaje y botones para fijar la marca.
Future<void> showFullClueSheet(
  BuildContext context,
  PuzzleCase pc,
  String charId,
  int clueIndex,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Brand.surface,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _FullClueSheet(pc: pc, charId: charId, clueIndex: clueIndex),
  );
}

class _FullClueSheet extends ConsumerWidget {
  final PuzzleCase pc;
  final String charId;
  final int clueIndex;
  const _FullClueSheet({
    required this.pc,
    required this.charId,
    required this.clueIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mark = ref.watch(
      gameControllerProvider(pc).select((s) => s.clueMarks[clueIndex]),
    );
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final clue = pc.clues[clueIndex];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pc.character(charId).nameEs,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Brand.inkOnLight,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: mark == ClueMark.highlighted
                    ? Brand.goldBright.withValues(alpha: .35)
                    : Brand.cardLightShade,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: mark == ClueMark.highlighted
                      ? Brand.gold
                      : Colors.black.withValues(alpha: .12),
                ),
              ),
              child: Text(
                clue.cardTextEs(pc.map, pc.names),
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: mark == ClueMark.struck
                      ? Brand.inkOnLight.withValues(alpha: .5)
                      : Brand.inkOnLight,
                  fontWeight: mark == ClueMark.highlighted
                      ? FontWeight.w700
                      : FontWeight.w500,
                  decoration: mark == ClueMark.struck
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Marca de la pista',
              style: TextStyle(fontSize: 14, color: Brand.muted),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ClueMark>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, 52)),
                ),
                segments: const [
                  ButtonSegment(
                    value: ClueMark.normal,
                    icon: Icon(Icons.radio_button_unchecked),
                    label: Text('Normal'),
                  ),
                  ButtonSegment(
                    value: ClueMark.highlighted,
                    icon: Icon(Icons.star_rounded),
                    label: Text('Destacar'),
                  ),
                  ButtonSegment(
                    value: ClueMark.struck,
                    icon: Icon(Icons.strikethrough_s),
                    label: Text('Tachar'),
                  ),
                ],
                selected: {mark},
                onSelectionChanged: (sel) =>
                    controller.setClueMark(clueIndex, sel.first),
              ),
            ),
          ],
        ),
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
              color: Brand.paperShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Brand.goldBright,
                letterSpacing: 2.5,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(
      gameControllerProvider(pc).select((s) => s.clueMarks),
    );
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final extras = pc.extraClues;

    return ListView(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        if (extras.isNotEmpty)
          _section(
            title: 'INFORMACIÓN ADICIONAL',
            children: [
              for (final e in extras)
                Builder(
                  builder: (context) {
                    final i = pc.clues.indexOf(e);
                    return InkWell(
                      onTap: () => controller.cycleClue(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '· ${e.textEs(pc.map, pc.names)}',
                          style: switch (marks[i]) {
                            ClueMark.normal => const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                            ),
                            ClueMark.highlighted => const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: Brand.goldBright,
                              fontWeight: FontWeight.bold,
                            ),
                            ClueMark.struck => TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: Brand.muted.withValues(alpha: .6),
                              decoration: TextDecoration.lineThrough,
                            ),
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        _section(
          title: 'HABITACIONES',
          children: [
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
                        color: areaPalette[i % areaPalette.length].withValues(
                          alpha: .75,
                        ),
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
          ],
        ),
        _section(
          title: 'MUEBLES',
          children: [
            const Text(
              'Pisables: puedes colocar gente encima. '
              'Los demás bloquean su casilla.',
              style: TextStyle(color: Brand.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final type in {for (final o in pc.map.objects) o.type})
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Brand.surfaceHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: objectColor(type).withValues(alpha: .5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          objectIcon(type),
                          size: 14,
                          color: objectColor(type),
                        ),
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
            const Text(
              '◦ = pisable',
              style: TextStyle(color: Brand.muted, fontSize: 10),
            ),
          ],
        ),
        _section(
          title: 'REGLAS',
          children: [
            const Text(
              'Una persona por fila y por columna. El asesino quedó a solas '
              'con la víctima en la misma habitación. Ubica a todos, '
              'incluida la víctima.',
              style: TextStyle(color: Brand.muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
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
          child: Text(
            '✕',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Brand.gold.withValues(alpha: .18) : Brand.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Brand.goldBright : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(
                '✕',
                style: TextStyle(
                  fontSize: selected && level == XLevel.large ? 26 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
            width: hovering.isNotEmpty ? 2.5 : 1,
          ),
          boxShadow: hovering.isNotEmpty
              ? [
                  BoxShadow(
                    color: Brand.error.withValues(alpha: .4),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 24,
              color: hovering.isNotEmpty ? Brand.error : Brand.muted,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                hovering.isNotEmpty
                    ? 'Suelta para borrar'
                    : 'Papelera — arrastra marcas aquí',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hovering.isNotEmpty ? Brand.cream : Brand.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
