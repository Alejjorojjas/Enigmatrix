/// Pantalla de victoria: al resolver un caso se estampa el sello CASO CERRADO
/// sobre un informe con la revelación del asesino, los datos de la partida y
/// el feedback de la prueba de juego. Toma su aspecto de la piel y el modo
/// activos.
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

/// Textos de la victoria (centralizados para traducir en la ronda 4.3).
abstract final class VictoryTexts {
  static const stamp = 'CASO CERRADO';
  static const goodJob = 'Buen trabajo, detective.';
  static const report = 'INFORME DEL CASO';
  static const murdererWas = 'El asesino era ';
  static const murdererTail = ', que quedó a solas con la víctima.';
  static const weapon = 'Arma homicida: ';
  static const time = 'Tiempo';
  static const errors = 'Errores';
  static const feedback = 'FEEDBACK DE PLAYTEST';
  static const feedbackHint = '¿Pistas confusas? ¿Dificultad justa?…';
  static const keepGoing = 'Continuar';
  static const lookBoard = 'Seguir mirando el tablero';
}

String _fmt(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

/// Guarda el resultado y muestra la celebración.
Future<void> showVictoryScreen(
  BuildContext context,
  WidgetRef ref,
  PuzzleCase pc,
) async {
  final state = ref.read(gameControllerProvider(pc));
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'done:${pc.caseId}',
    jsonEncode({
      'time': state.elapsedSeconds,
      'errors': state.errorCount,
      'date': DateTime.now().toIso8601String().substring(0, 16),
    }),
  );

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: ctx.pal.bg,
      child: ScreenBackground(
        child: _VictoryView(pc: pc, prefs: prefs),
      ),
    ),
  );
}

class _VictoryView extends ConsumerStatefulWidget {
  const _VictoryView({required this.pc, required this.prefs});

  final PuzzleCase pc;
  final SharedPreferences prefs;

  @override
  ConsumerState<_VictoryView> createState() => _VictoryViewState();
}

class _VictoryViewState extends ConsumerState<_VictoryView> {
  late final TextEditingController _fb = TextEditingController(
    text: widget.prefs.getString('fb:${widget.pc.caseId}') ?? '',
  );

  @override
  void dispose() {
    _fb.dispose();
    super.dispose();
  }

  Future<void> _saveAnd(void Function() then) async {
    await widget.prefs.setString('fb:${widget.pc.caseId}', _fb.text);
    then();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pc = widget.pc;
    final state = ref.read(gameControllerProvider(pc));
    final murderer = state.murdererId == null
        ? null
        : pc.character(state.murdererId!);
    final weapon = state.lethalWeaponId == null
        ? null
        : pc.map.weapons.firstWhere((w) => w.id == state.lethalWeaponId);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sello que se estampa con rebote.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 2.2, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.09,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.danger, width: 4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: p.danger, width: 2),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            VictoryTexts.stamp,
                            style: context.display(
                              30,
                              color: p.danger,
                              spacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  VictoryTexts.goodJob,
                  textAlign: TextAlign.center,
                  style: context.display(20, color: p.accent),
                ),
                Text(
                  caseTitle(pc),
                  textAlign: TextAlign.center,
                  style: context.body(
                    16,
                    weight: FontWeight.w600,
                    color: p.softText,
                  ),
                ),
                const SizedBox(height: 20),

                // Informe del caso.
                ChromeBox(
                  color: p.surface,
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const SectionLabel(VictoryTexts.report),
                      const SizedBox(height: 6),
                      Container(height: 2, color: p.line),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: VictoryTexts.murdererWas),
                            TextSpan(
                              text: murderer?.nameEs ?? '?',
                              style: context.body(
                                17,
                                weight: FontWeight.w800,
                                color: p.danger,
                              ),
                            ),
                            const TextSpan(text: VictoryTexts.murdererTail),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: context.body(16),
                      ),
                      if (weapon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: VictoryTexts.weapon),
                                TextSpan(
                                  text: weapon.nameEs,
                                  style: context.body(
                                    16,
                                    weight: FontWeight.w800,
                                    color: p.accent,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: context.body(16),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: _fmt(state.elapsedSeconds),
                              label: VictoryTexts.time,
                              icon: Icons.timer_outlined,
                              color: p.world(0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              value: '${state.errorCount}',
                              label: VictoryTexts.errors,
                              icon: state.errorCount == 0
                                  ? Icons.verified_outlined
                                  : Icons.close_rounded,
                              color: state.errorCount == 0 ? p.good : p.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Feedback de la prueba de juego (se conserva de la Fase 1).
                ChromeBox(
                  color: p.surface,
                  radius: 16,
                  depth: 2.5,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(VictoryTexts.feedback),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fb,
                        maxLines: 3,
                        style: context.body(15, weight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: VictoryTexts.feedbackHint,
                          hintStyle: context.body(
                            15,
                            weight: FontWeight.w600,
                            color: p.textDim,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  label: VictoryTexts.keepGoing,
                  onTap: () => _saveAnd(() {
                    Navigator.of(context).pop();
                    context.go('/casos');
                  }),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _saveAnd(() => Navigator.of(context).pop()),
                  child: Text(
                    VictoryTexts.lookBoard,
                    style: context.body(15, color: p.softText),
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
