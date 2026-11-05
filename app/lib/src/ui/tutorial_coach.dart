/// Tutorial jugable (regla 11 del ADR-0012): un caso propio y pequeño
/// (assets/tutorial/caso-tutorial.json, 5x5) con una guía paso a paso que
/// avanza sola al detectar la acción del jugador. Enseña candidatos,
/// confirmar, la X (automática y a mano), la vista Mapa/Notas, Borrar y un
/// Resolver fallido controlado en el que SOLO el tutorial marca las casillas
/// exactas.
///
/// Es obligatorio la primera vez (lo dispara home_shell tras el diálogo de
/// bienvenida), se puede saltar en cualquier momento y se repite desde la
/// lista de casos. No cuenta como Caso 1: no escribe "done:" de ningún caso
/// y no guarda partida ("game:tutorial").
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../data/case_repository.dart';
import '../game/game_controller.dart';
import 'clue_text.dart';
import 'ui_kit.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';

/// Clave de "el tutorial ya se terminó o se saltó".
/// Clave vigente (v2): el tutorial nuevo es obligatorio una vez para todos,
/// aunque existan las claves viejas tutorial:seen / tutorial:played.
const tutorialPlayedKey = 'tutorial:v2:done';

/// Anota que el tutorial ya se hizo (terminado, saltado o abandonado), para
/// que no vuelva a aparecer solo. Sigue disponible desde la lista de casos.
Future<void> markTutorialPlayed() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialPlayedKey, true);
  } catch (_) {
    // Sin almacenamiento el tutorial se puede repetir; no es grave.
  }
}

/// Sale del tutorial (Saltar o flecha): queda anotado y se vuelve a la lista.
Future<void> leaveTutorial(BuildContext context) async {
  await markTutorialPlayed();
  if (context.mounted) context.go('/casos');
}

/// Paso actual de la guía. Es autoDispose: cada vez que se abre el tutorial
/// empieza en el paso 0.
final tutorialStepProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Alto fijo de la tarjeta de la guía. La partida no se desplaza, así que la
/// tarjeta reserva su sitio y el tablero se acomoda al resto.
const double kTutorialCoachHeight = 132;

/// Elementos de la pantalla de partida que la guía puede señalar con un
/// marco (solo en modo tutorial).
enum TutorialTarget {
  portraits,
  board,
  toolNotes,
  toolCross,
  toolPlace,
  toolErase,
  menu,
  resolve,
}

/// Un paso de la guía. [advanceWhen] null = paso manual (botón Entendido),
/// salvo en el [isFinal], que termina al resolver el caso.
class TutorialStep {
  final String emoji;
  final String Function(AppLocalizations l10n, GameState s) text;
  final bool Function(GameState s)? advanceWhen;

  /// Elemento que se señala con un marco mientras dura el paso.
  final TutorialTarget? Function(GameState s)? target;

  /// Aviso (en rojo) cuando el jugador va por mal camino.
  final String? Function(AppLocalizations l10n, GameState s)? warning;
  final bool isFinal;

  const TutorialStep({
    required this.emoji,
    required this.text,
    this.advanceWhen,
    this.target,
    this.warning,
    this.isFinal = false,
  });

  bool get manual => advanceWhen == null && !isFinal;
}

/// ¿Está el tablero completo y todos en su casilla correcta?
bool tutorialBoardIsCorrect(GameState s) => s.pc.solution.positions.entries
    .every((e) => s.board.confirmedCellOf(e.key) == e.value);

/// Mientras la guía no llegue al último paso, el Resolver que acierta queda
/// en espera: antes hay que ver el Resolver fallido. Devuelve el aviso a
/// mostrar, o null si se puede resolver.
String? tutorialResolveBlock(
  AppLocalizations l10n,
  PuzzleCase pc,
  GameState s,
  int step,
) {
  if (!tutorialBoardIsCorrect(s)) return null; // fallar siempre es posible
  if (step >= buildTutorialSteps(pc).length - 1) return null;
  return l10n.tutorialCoachBlockResolve;
}

/// Los pasos de un caso (se arman una sola vez por caso).
final tutorialStepsProvider = Provider.family<List<TutorialStep>, PuzzleCase>(
  (ref, pc) => buildTutorialSteps(pc),
);

/// A qué elemento señala la guía en este momento (null = a ninguno).
final tutorialTargetProvider = Provider.autoDispose
    .family<TutorialTarget?, PuzzleCase>((ref, pc) {
      final steps = ref.watch(tutorialStepsProvider(pc));
      final i = ref.watch(tutorialStepProvider).clamp(0, steps.length - 1);
      final s = ref.watch(gameControllerProvider(pc));
      if (s.solved) return null;
      return steps[i].target?.call(s);
    });

/// Marco que resalta el elemento señalado por la guía. El árbol de widgets
/// NO cambia al encender o apagar el marco (el tablero de Flame no se
/// reconstruye): solo cambia la decoración.
class TutorialSpot extends ConsumerWidget {
  const TutorialSpot({
    super.key,
    required this.pc,
    required this.target,
    required this.child,
    this.radius = 18,
  });

  final PuzzleCase pc;
  final TutorialTarget target;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      tutorialTargetProvider(pc).select((t) => t == target),
    );
    return DecoratedBox(
      key: ValueKey('guia-${target.name}${active ? '-activo' : ''}'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: active ? Border.all(color: context.pal.accent, width: 3) : null,
      ),
      child: child,
    );
  }
}

/// Los pasos, escritos para el caso del tutorial (c1 Adela la víctima,
/// c2 Bruno, c3 Clara, c4 Dario, c5 Elena). Las casillas y los nombres salen
/// del propio caso; un test fija que el caso siga encajando con el guion. Los
/// textos viven en el .arb y se piden con el idioma activo en cada llamada.
List<TutorialStep> buildTutorialSteps(PuzzleCase pc) {
  const victim = 'c1', bruno = 'c2', clara = 'c3', dario = 'c4', elena = 'c5';
  final pos = pc.solution.positions;
  final size = pc.map.size;

  String n(String id) => pc.character(id).nameEs;
  String rc(AppLocalizations l, int cell) =>
      l.tutorialCoachRowCol(cell ~/ size + 1, cell % size + 1);
  String area(int cell) =>
      pc.map.areas.firstWhere((a) => a.id == pc.map.areaIdOf(cell)).nameEs;
  String clue(AppLocalizations l, String id) {
    final c = pc.clueFor(id);
    if (c == null) return '';
    final text = clueText(pc, c).replaceFirst(RegExp(r'\.$'), '');
    return l.tutorialCoachClueQuote(text);
  }

  bool at(GameState s, String id) => s.board.confirmedCellOf(id) == pos[id];
  bool anyMark(GameState s) => [
    for (var i = 0; i < size * size; i++) s.board.cell(i),
  ].any((c) => c.candidates.isNotEmpty || c.confirmed != null);
  bool anyManualX(GameState s) => [
    for (var i = 0; i < size * size; i++) s.board.cell(i),
  ].any((c) => c.x != null);
  bool manualXOnSolution(GameState s) =>
      pos.values.any((cell) => s.board.cell(cell).x != null);
  bool gone(GameState s, String id) => s.board.confirmedCellOf(id) == null;
  bool fiveWrong(GameState s) =>
      s.board.confirmedCells.length >= pc.characters.length &&
      !tutorialBoardIsCorrect(s);

  // Aviso de un personaje puesto donde no va; [why] es la razón, ya traducida.
  String? misplaced(AppLocalizations l, GameState s, String id, String why) {
    final cell = s.board.confirmedCellOf(id);
    if (cell == null || cell == pos[id]) return null;
    return l.tutorialCoachMisplaced(n(id), why);
  }

  // Una casilla del Porche (la habitación del sofá) para ensayar la X: nadie
  // más puede estar ahí porque Elena ocupa esa habitación.
  int? suggestX(GameState s) {
    final sofaArea = pc.map.areaIdOf(pos[elena]!);
    for (final a in pc.map.areas.where((a) => a.id == sofaArea)) {
      for (final cell in a.cells) {
        final o = pc.map.objectAt(cell);
        if (o != null && o.type == ObjectType.sofa) continue;
        if (pos.values.contains(cell)) continue;
        if (!s.board.cell(cell).isEmpty) continue;
        return cell;
      }
    }
    return null;
  }

  // Señala el tablero si ya está elegida la herramienta; si no, la herramienta.
  TutorialTarget? Function(GameState) boardOr(
    TutorialTarget tool,
    ToolMode mode,
  ) =>
      (s) => s.toolMode == mode ? TutorialTarget.board : tool;

  return [
    // 0
    TutorialStep(
      emoji: '🕵️',
      text: (l, _) => l.tutorialCoachStep0,
      target: (_) => TutorialTarget.portraits,
    ),
    // 1
    TutorialStep(
      emoji: '📏',
      text: (l, _) => l.tutorialCoachStep1(n(victim)),
      target: (_) => TutorialTarget.board,
    ),
    // 2
    TutorialStep(
      emoji: '✏️',
      text: (l, _) => l.tutorialCoachStep2(n(victim), clue(l, victim)),
      advanceWhen: anyMark,
      target: (_) => TutorialTarget.board,
    ),
    // 3
    TutorialStep(
      emoji: '📌',
      text: (l, s) => s.toolMode == ToolMode.place
          ? l.tutorialCoachStep3Place(
              area(pos[victim]!),
              rc(l, pos[victim]!),
              n(victim),
            )
          : l.tutorialCoachStep3Tool(
              area(pos[victim]!),
              rc(l, pos[victim]!),
              n(victim),
            ),
      advanceWhen: (s) => at(s, victim),
      target: boardOr(TutorialTarget.toolPlace, ToolMode.place),
      warning: (l, s) => misplaced(l, s, victim, l.tutorialCoachWhyVictim),
    ),
    // 4
    TutorialStep(
      emoji: '❌',
      text: (l, _) => l.tutorialCoachStep4(n(victim)),
      target: (_) => TutorialTarget.board,
    ),
    // 5
    TutorialStep(
      emoji: '🛏️',
      text: (l, _) =>
          l.tutorialCoachStep5(n(bruno), clue(l, bruno), rc(l, pos[bruno]!)),
      advanceWhen: (s) => at(s, bruno),
      target: (_) => TutorialTarget.board,
      warning: (l, s) => misplaced(l, s, bruno, l.tutorialCoachWhyBruno),
    ),
    // 6
    TutorialStep(
      emoji: '✖️',
      text: (l, s) {
        if (s.toolMode == ToolMode.cross) {
          final cell = suggestX(s);
          final where = cell == null
              ? l.tutorialCoachStep6AnyCell(area(pos[elena]!))
              : rc(l, cell);
          return l.tutorialCoachStep6Cross(where);
        }
        return l.tutorialCoachStep6Tool(n(elena), area(pos[elena]!));
      },
      advanceWhen: anyManualX,
      target: boardOr(TutorialTarget.toolCross, ToolMode.cross),
      warning: (l, s) =>
          manualXOnSolution(s) ? l.tutorialCoachWarnXOnSolution : null,
    ),
    // 7
    TutorialStep(
      emoji: '🗒️',
      text: (l, _) => l.tutorialCoachStep7,
      advanceWhen: (s) => !s.mapMode,
      target: (_) => TutorialTarget.menu,
    ),
    // 8
    TutorialStep(
      emoji: '🧮',
      text: (l, _) => l.tutorialCoachStep8,
      advanceWhen: (s) => s.mapMode,
      target: (_) => TutorialTarget.menu,
    ),
    // 9
    TutorialStep(
      emoji: '🛁',
      text: (l, _) => l.tutorialCoachStep9(
        n(clara),
        clue(l, clara),
        area(pos[clara]!),
        rc(l, pos[clara]!),
      ),
      advanceWhen: (s) => at(s, clara),
      target: (_) => TutorialTarget.board,
      warning: (l, s) => misplaced(l, s, clara, l.tutorialCoachWhyClara),
    ),
    // 10
    TutorialStep(
      emoji: '🧩',
      text: (l, _) => l.tutorialCoachStep10(
        n(elena),
        clue(l, elena),
        n(dario),
        clue(l, dario),
      ),
      advanceWhen: tutorialBoardIsCorrect,
      target: (_) => TutorialTarget.board,
      warning: (l, s) => fiveWrong(s) ? l.tutorialCoachWarnFiveWrong : null,
    ),
    // 11
    TutorialStep(
      emoji: '🧽',
      text: (l, _) => l.tutorialCoachStep11(n(elena), n(dario)),
      advanceWhen: (s) => gone(s, elena) && gone(s, dario),
      target: boardOr(TutorialTarget.toolErase, ToolMode.erase),
    ),
    // 12
    TutorialStep(
      emoji: '🔀',
      text: (l, _) => l.tutorialCoachStep12(
        n(elena),
        rc(l, pos[dario]!),
        n(dario),
        rc(l, pos[elena]!),
      ),
      advanceWhen: (s) =>
          s.board.confirmedCellOf(elena) == pos[dario] &&
          s.board.confirmedCellOf(dario) == pos[elena],
      target: (_) => TutorialTarget.board,
      warning: (l, s) =>
          tutorialBoardIsCorrect(s) ? l.tutorialCoachWarnBoardCorrect : null,
    ),
    // 13
    TutorialStep(
      emoji: '⚖️',
      text: (l, _) => l.tutorialCoachStep13,
      advanceWhen: (s) => s.errorCells.isNotEmpty,
      target: (_) => TutorialTarget.resolve,
    ),
    // 14
    TutorialStep(
      emoji: '🔴',
      text: (l, _) => l.tutorialCoachStep14(n(elena), n(dario)),
      target: (_) => TutorialTarget.board,
    ),
    // 15
    TutorialStep(
      emoji: '🧹',
      text: (l, _) => l.tutorialCoachStep15(n(elena), n(dario)),
      advanceWhen: (s) => gone(s, elena) && gone(s, dario),
      target: boardOr(TutorialTarget.toolErase, ToolMode.erase),
    ),
    // 16
    TutorialStep(
      emoji: '🔧',
      text: (l, _) => l.tutorialCoachStep16(
        n(elena),
        rc(l, pos[elena]!),
        n(dario),
        rc(l, pos[dario]!),
      ),
      advanceWhen: tutorialBoardIsCorrect,
      target: (_) => TutorialTarget.board,
    ),
    // 17
    TutorialStep(
      emoji: '🏁',
      text: (l, _) => l.tutorialCoachStep17,
      target: (_) => TutorialTarget.resolve,
      isFinal: true,
    ),
  ];
}

/// Prepara el tutorial antes de mostrar la partida: carga el caso propio. El
/// controlador no guarda ni restaura "game:tutorial", así que SIEMPRE
/// empieza de cero.
class TutorialLoader extends ConsumerStatefulWidget {
  final Widget Function(PuzzleCase pc) builder;
  const TutorialLoader({super.key, required this.builder});

  @override
  ConsumerState<TutorialLoader> createState() => _TutorialLoaderState();
}

class _TutorialLoaderState extends ConsumerState<TutorialLoader> {
  @override
  Widget build(BuildContext context) {
    final loaded = ref.watch(tutorialCaseProvider);
    if (loaded.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.tutorialCoachLoadError,
                  textAlign: TextAlign.center,
                  style: context.note(18, color: context.pal.text),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: context.l10n.tutorialCoachBackToCases,
                  expand: false,
                  onTap: () => context.go('/casos'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final pc = loaded.valueOrNull;
    if (pc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.builder(pc);
  }
}

/// Tarjeta de la guía. Va FUERA del área de juego (arriba, en el flujo de
/// la pantalla), así nunca tapa lo que explica; el botón Saltar vive en la
/// fila del título de la partida y siempre está a la vista.
class TutorialCoach extends ConsumerStatefulWidget {
  final PuzzleCase pc;
  const TutorialCoach({super.key, required this.pc});

  @override
  ConsumerState<TutorialCoach> createState() => _TutorialCoachState();
}

class _TutorialCoachState extends ConsumerState<TutorialCoach> {
  late final List<TutorialStep> _steps = buildTutorialSteps(widget.pc);

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    ref.read(tutorialStepProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider(widget.pc));
    final index = ref.watch(tutorialStepProvider).clamp(0, _steps.length - 1);
    if (state.solved) return const SizedBox(height: kTutorialCoachHeight);
    final p = context.pal;

    final step = _steps[index];

    // Avance automático cuando el jugador cumplió la acción del paso.
    final auto = step.advanceWhen;
    if (auto != null && auto(state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(tutorialStepProvider) == index) {
          _goTo(index + 1);
        }
      });
    }

    final warning = step.warning?.call(context.l10n, state);

    return SizedBox(
      height: kTutorialCoachHeight,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: ChromeBox(
          color: p.surface,
          radius: 16,
          depth: 3,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.text(context.l10n, state),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                color: p.text,
                              ),
                            ),
                            if (warning != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  context.l10n.tutorialCoachWarning(warning),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: p.danger,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    Text(
                      context.l10n.tutorialCoachProgress(
                        index + 1,
                        _steps.length,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: p.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (step.manual)
                      ChromeButton(
                        key: const ValueKey('guia-entendido'),
                        onTap: () => _goTo(index + 1),
                        color: p.accent,
                        radius: 14,
                        minSize: const Size(SkinUi.minTouch, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        semanticsLabel: context.l10n.tutorialCoachGotIt,
                        child: Text(
                          context.l10n.tutorialCoachGotIt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.onAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cierre del tutorial al resolver bien el caso: revela al asesino, avisa
/// que el Caso 1 sigue sin empezar y lleva a la lista. NO usa la pantalla de
/// victoria normal, porque esa escribe "done:" y el feedback del caso.
Future<void> showTutorialEnd(
  BuildContext context,
  PuzzleCase pc,
  GameState state,
) async {
  await markTutorialPlayed();
  if (!context.mounted) return;
  final murderer = state.murdererId == null
      ? null
      : pc.character(state.murdererId!);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final p = ctx.pal;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ChromeBox(
            color: p.surface,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 6),
                  Text(
                    ctx.l10n.tutorialEndTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ctx.l10n.tutorialEndMurderer(murderer?.nameEs ?? '?'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, height: 1.35, color: p.text),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ctx.l10n.tutorialEndSummary,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.35, color: p.text),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ChromeButton(
                      key: const ValueKey('tutorial-ir-casos'),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.go('/casos');
                      },
                      color: p.accent,
                      radius: 18,
                      minSize: const Size(0, 50),
                      semanticsLabel: ctx.l10n.tutorialEndGoToCases,
                      child: Text(
                        ctx.l10n.tutorialEndGoToCases,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.onAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      ctx.l10n.tutorialEndLookBoard,
                      style: TextStyle(fontSize: 15, color: p.textDim),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
