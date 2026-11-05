/// Tutorial jugable (regla 11 del ADR-0012): un caso propio y pequeño
/// (assets/tutorial/caso-tutorial.json, 5x5) con una guía paso a paso que
/// avanza sola al detectar la acción del jugador. Enseña candidatos,
/// confirmar, la X (automática y a mano), el modo Mapa/Notas, la papelera,
/// el borrador y un Resolver fallido controlado en el que SOLO el tutorial
/// marca las casillas exactas.
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

import '../data/case_repository.dart';
import '../game/game_controller.dart';
import 'enx_style.dart';

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

/// Claves de los elementos de la pantalla de partida que la guía señala
/// (solo se asignan en modo tutorial). Sirven para llevar el scroll hasta
/// lo que se está explicando.
abstract final class TutorialTargets {
  static final board = GlobalKey(debugLabel: 'tutorial-board');
  static final header = GlobalKey(debugLabel: 'tutorial-header');
  static final xTool = GlobalKey(debugLabel: 'tutorial-x');
  static final eraser = GlobalKey(debugLabel: 'tutorial-eraser');
  static final trash = GlobalKey(debugLabel: 'tutorial-trash');
  static final controls = GlobalKey(debugLabel: 'tutorial-controls');
}

/// Un paso de la guía. [advanceWhen] null = paso manual (botón Entendido),
/// salvo en el [isFinal], que termina al resolver el caso.
class TutorialStep {
  final String emoji;
  final String Function(GameState s) text;
  final bool Function(GameState s)? advanceWhen;

  /// Elemento hacia el que se desplaza la pantalla al entrar al paso.
  final GlobalKey? Function(GameState s)? target;

  /// Dónde queda el elemento señalado en la pantalla: 0 = arriba, 1 = abajo.
  final double Function(GameState s)? alignment;

  /// Aviso (en rojo) cuando el jugador va por mal camino.
  final String? Function(GameState s)? warning;
  final bool isFinal;

  const TutorialStep({
    required this.emoji,
    required this.text,
    this.advanceWhen,
    this.target,
    this.alignment,
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
String? tutorialResolveBlock(PuzzleCase pc, GameState s, int step) {
  if (!tutorialBoardIsCorrect(s)) return null; // fallar siempre es posible
  if (step >= buildTutorialSteps(pc).length - 1) return null;
  return 'Aún no: antes del Resolver final hay un experimento. '
      'Sigue la tarjeta de arriba (o pulsa Saltar).';
}

/// Los pasos, escritos para el caso del tutorial (c1 Adela la víctima,
/// c2 Bruno, c3 Clara, c4 Dario, c5 Elena). Las casillas y los nombres salen
/// del propio caso; un test fija que el caso siga encajando con el guion.
List<TutorialStep> buildTutorialSteps(PuzzleCase pc) {
  const victim = 'c1', bruno = 'c2', clara = 'c3', dario = 'c4', elena = 'c5';
  final pos = pc.solution.positions;
  final size = pc.map.size;

  String n(String id) => pc.character(id).nameEs;
  String rc(int cell) => 'fila ${cell ~/ size + 1}, columna ${cell % size + 1}';
  String area(int cell) =>
      pc.map.areas.firstWhere((a) => a.id == pc.map.areaIdOf(cell)).nameEs;
  String clue(String id) {
    final c = pc.clueFor(id);
    if (c == null) return '';
    final text = c
        .cardTextEs(pc.map, pc.names)
        .replaceFirst(RegExp(r'\.$'), '');
    return '«$text»';
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

  String? misplaced(GameState s, String id, String why) {
    final cell = s.board.confirmedCellOf(id);
    if (cell == null || cell == pos[id]) return null;
    return '${n(id)} no va ahí: $why Bórrala con el borrador o la '
        'papelera y prueba otra.';
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

  return [
    // 0
    TutorialStep(
      emoji: '🕵️',
      text: (_) =>
          'Este es un caso de práctica: solo 5 personajes, y no '
          'cuenta como ningún caso de la lista. Debajo del mapa están los '
          'sospechosos, cada uno con su pista (deslízalos para verlos a '
          'todos).',
    ),
    // 1
    TutorialStep(
      emoji: '📏',
      text: (_) =>
          'Regla de oro: UNA persona por fila y UNA por columna, '
          'como en un sudoku. Hay que ubicar a todos, incluida la víctima: '
          '${n(victim)} (su tarjeta lleva †).',
    ),
    // 2
    TutorialStep(
      emoji: '✏️',
      text: (_) =>
          'Pista de ${n(victim)}: ${clue(victim)}. Toca su tarjeta '
          'y luego TOCA una casilla donde pueda estar: queda anotada como '
          'candidato (su letra).',
      advanceWhen: anyMark,
      target: (_) => TutorialTargets.board,
    ),
    // 3
    TutorialStep(
      emoji: '📌',
      text: (_) =>
          'En ${area(pos[victim]!)} solo hay una casilla junto a '
          'una cama sin ser cama: ${rc(pos[victim]!)}. Con ${n(victim)} '
          'elegida, MANTÉN PRESIONADA esa casilla (o arrastra su tarjeta '
          'hasta ella) para CONFIRMARLA.',
      advanceWhen: (s) => at(s, victim),
      target: (_) => TutorialTargets.board,
      warning: (s) => misplaced(
        s,
        victim,
        'solo cuadra junto a una cama, sin estar encima de ella.',
      ),
    ),
    // 4
    TutorialStep(
      emoji: '❌',
      text: (_) =>
          '¿Viste? Al confirmar a ${n(victim)}, el juego tachó con '
          'X claras su fila y su columna (interruptor Auto-X): ahí ya no '
          'puede haber nadie más. Las X te ahorran trabajo.',
      target: (_) => TutorialTargets.board,
    ),
    // 5
    TutorialStep(
      emoji: '🛏️',
      text: (_) =>
          'Pista de ${n(bruno)}: ${clue(bruno)}. Casi todas las '
          'casillas de cama quedaron tachadas: solo una sigue libre, '
          '${rc(pos[bruno]!)}. Confirma a ${n(bruno)} ahí.',
      advanceWhen: (s) => at(s, bruno),
      target: (_) => TutorialTargets.board,
      warning: (s) => misplaced(
        s,
        bruno,
        'solo puede ir en la casilla de cama que no está tachada.',
      ),
    ),
    // 6
    TutorialStep(
      emoji: '✖️',
      text: (s) {
        final cell = suggestX(s);
        final where = cell == null
            ? 'una casilla en ${area(pos[elena]!)} que no sea el sofá'
            : rc(cell);
        return s.tool is XTool
            ? 'Con la X elegida, toca $where. Esa X la pones tú: sirve para '
                  'descartar lo que sabes que no puede ser.'
            : '${n(elena)} está sobre un sofá, en ${area(pos[elena]!)}: ahí '
                  'nadie más puede estar. Descártalo con la herramienta X '
                  '(baja hasta HERRAMIENTAS y tócala).';
      },
      advanceWhen: anyManualX,
      target: (s) =>
          s.tool is XTool ? TutorialTargets.board : TutorialTargets.xTool,
      alignment: (s) => s.tool is XTool ? 0 : .5,
      warning: (s) => manualXOnSolution(s)
          ? 'Esa X tapa la casilla de alguien. Bórrala con el borrador '
                'o con la papelera.'
          : null,
    ),
    // 7
    TutorialStep(
      emoji: '🗒️',
      text: (_) =>
          'Para pensar sin el dibujo, cambia a NOTAS con el '
          'interruptor Mapa/Notas (debajo de los sospechosos).',
      advanceWhen: (s) => !s.mapMode,
      target: (_) => TutorialTargets.controls,
      alignment: (_) => .5,
    ),
    // 8
    TutorialStep(
      emoji: '🧮',
      text: (_) =>
          'En NOTAS se esconden los muebles y los nombres de las '
          'habitaciones: queda la cuadrícula con tus marcas, ideal para '
          'repasar filas y columnas. Vuelve a MAPA.',
      advanceWhen: (s) => s.mapMode,
      target: (_) => TutorialTargets.controls,
      alignment: (_) => .5,
    ),
    // 9
    TutorialStep(
      emoji: '🛁',
      text: (_) =>
          'Pista de ${n(clara)}: ${clue(clara)}. Con las X que hay, '
          'en ${area(pos[clara]!)} solo queda una casilla libre: '
          '${rc(pos[clara]!)}. Confirma a ${n(clara)} ahí.',
      advanceWhen: (s) => at(s, clara),
      target: (_) => TutorialTargets.board,
      warning: (s) => misplaced(
        s,
        clara,
        'solo cuadra en la única casilla libre de su habitación.',
      ),
    ),
    // 10
    TutorialStep(
      emoji: '🧩',
      text: (_) =>
          'Faltan ${n(elena)} (${clue(elena)}) y ${n(dario)} '
          '(${clue(dario)}). Termina tú con las X y la regla de fila y '
          'columna.',
      advanceWhen: tutorialBoardIsCorrect,
      target: (_) => TutorialTargets.board,
      warning: (s) => fiveWrong(s)
          ? 'Los cinco están puestos, pero alguno no cuadra. Relee las '
                'pistas de los que dudes.'
          : null,
    ),
    // 11
    TutorialStep(
      emoji: '🗑️',
      text: (_) =>
          '¡Todos bien ubicados! Antes de resolver, un experimento: '
          'equivoquémonos a propósito. Primero quita a ${n(elena)} y a '
          '${n(dario)}: arrastra cada ficha del mapa hasta la PAPELERA '
          '(la barra bajo las pistas).',
      advanceWhen: (s) => gone(s, elena) && gone(s, dario),
      target: (_) => TutorialTargets.trash,
      alignment: (_) => 1,
    ),
    // 12
    TutorialStep(
      emoji: '🔀',
      text: (_) =>
          'Ahora cámbialos de sitio: ${n(elena)} en ${rc(pos[dario]!)} '
          'y ${n(dario)} en ${rc(pos[elena]!)}. Elige su tarjeta y mantén '
          'presionada la casilla.',
      advanceWhen: (s) =>
          s.board.confirmedCellOf(elena) == pos[dario] &&
          s.board.confirmedCellOf(dario) == pos[elena],
      target: (_) => TutorialTargets.board,
      warning: (s) => tutorialBoardIsCorrect(s)
          ? 'Ese tablero es el correcto; para el experimento hay que '
                'intercambiarlos.'
          : null,
    ),
    // 13
    TutorialStep(
      emoji: '⚖️',
      text: (_) =>
          'Con el tablero lleno pero mal, pulsa RESOLVER (arriba). '
          'En el tutorial el juego marca en rojo las casillas que no '
          'cuadran.',
      advanceWhen: (s) => s.errorCells.isNotEmpty,
      target: (_) => TutorialTargets.header,
    ),
    // 14
    TutorialStep(
      emoji: '🔴',
      text: (_) =>
          'Las casillas rojas (se apagan a los 3 segundos) no '
          'cuadran: ${n(elena)} no está sobre un sofá, y su pista lo '
          'exige; y al estar ella mal, falla también ${n(dario)}. Para '
          'hallar un error, mira la casilla roja y relee la pista de quien '
          'está ahí. Ojo: en una partida real solo te diremos CUÁNTAS no '
          'cuadran, no cuáles.',
      target: (_) => TutorialTargets.board,
    ),
    // 15
    TutorialStep(
      emoji: '🧽',
      text: (_) =>
          'Para corregir, usa el BORRADOR (en HERRAMIENTAS): '
          'elígelo y toca a ${n(elena)} y a ${n(dario)} en el mapa para '
          'limpiarlos.',
      advanceWhen: (s) => gone(s, elena) && gone(s, dario),
      target: (s) =>
          s.tool is EraserTool ? TutorialTargets.board : TutorialTargets.eraser,
      alignment: (s) => s.tool is EraserTool ? 0 : .5,
    ),
    // 16
    TutorialStep(
      emoji: '🔧',
      text: (_) =>
          'Ahora ponlos bien: ${n(elena)} en ${rc(pos[elena]!)} '
          '(sobre el sofá) y ${n(dario)} en ${rc(pos[dario]!)} (a solas).',
      advanceWhen: tutorialBoardIsCorrect,
      target: (_) => TutorialTargets.board,
    ),
    // 17
    TutorialStep(
      emoji: '🏁',
      text: (_) =>
          '¡Tablero completo y correcto! Pulsa RESOLVER: si todo '
          'cuadra, sabrás quién quedó a solas con la víctima. Ese es el '
          'asesino.',
      target: (_) => TutorialTargets.header,
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
                  'No se pudo abrir el tutorial.',
                  textAlign: TextAlign.center,
                  style: Enx.hand(18, color: Enx.ink),
                ),
                const SizedBox(height: 16),
                EnxButton(
                  label: 'Volver a los casos',
                  color: Enx.gold,
                  textColor: Enx.goldInk,
                  expand: false,
                  onPressed: () => context.go('/casos'),
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
/// barra superior de la partida y siempre está a la vista.
class TutorialCoach extends ConsumerStatefulWidget {
  final PuzzleCase pc;
  const TutorialCoach({super.key, required this.pc});

  @override
  ConsumerState<TutorialCoach> createState() => _TutorialCoachState();
}

class _TutorialCoachState extends ConsumerState<TutorialCoach> {
  late final List<TutorialStep> _steps = buildTutorialSteps(widget.pc);
  int _lastStep = -1;
  GlobalKey? _lastTarget;

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    ref.read(tutorialStepProvider.notifier).state = index;
  }

  void _scrollTo(GlobalKey? key, double alignment) {
    final ctx = key?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: alignment,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider(widget.pc));
    final index = ref.watch(tutorialStepProvider).clamp(0, _steps.length - 1);
    if (state.solved) return const SizedBox.shrink();

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

    // Lleva el scroll a lo que se explica (al entrar al paso o al cambiar
    // el elemento señalado).
    final target = step.target?.call(state);
    final alignment = step.alignment?.call(state) ?? 0.0;
    if (index != _lastStep || target != _lastTarget) {
      _lastStep = index;
      _lastTarget = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(target, alignment);
      });
    }

    final warning = step.warning?.call(state);
    final maxHeight = MediaQuery.sizeOf(context).height * .34;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620, maxHeight: maxHeight),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: Enx.paper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Enx.gold, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x73473418),
                    offset: Offset(0, 4),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.text(state),
                                  style: Enx.hand(16.5, color: Enx.ink),
                                ),
                                if (warning != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '⚠ $warning',
                                      style: Enx.font(
                                        13,
                                        weight: FontWeight.w700,
                                        color: Enx.crimson,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'TUTORIAL · ${index + 1}/${_steps.length}',
                        style: Enx.font(
                          10.5,
                          weight: FontWeight.w800,
                          color: Enx.inkMuted,
                          spacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (step.manual)
                        EnxButton(
                          label: 'Entendido',
                          color: Enx.gold,
                          textColor: const Color(0xFF4A3200),
                          expand: false,
                          onPressed: () => _goTo(index + 1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
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
    barrierColor: const Color(0xCC3D2F1C),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          decoration: BoxDecoration(
            color: Enx.paper,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99271D0E),
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎓', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text(
                  '¡Práctica superada!',
                  textAlign: TextAlign.center,
                  style: Enx.display(23, color: Enx.goldInk),
                ),
                const SizedBox(height: 12),
                Text(
                  'El asesino era ${murderer?.nameEs ?? '?'}: fue la única '
                  'persona que quedó a solas con la víctima.',
                  textAlign: TextAlign.center,
                  style: Enx.hand(18, color: Enx.ink),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ya sabes ubicar, descartar con X, usar Notas, borrar y '
                  'resolver. Esto era solo práctica: tu Caso 1 te espera '
                  'sin empezar.',
                  textAlign: TextAlign.center,
                  style: Enx.hand(17, color: Enx.ink),
                ),
                const SizedBox(height: 18),
                EnxButton(
                  label: 'Ir a los casos',
                  color: Enx.crimson,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/casos');
                  },
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Seguir mirando el tablero',
                    style: Enx.font(14, color: Enx.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
