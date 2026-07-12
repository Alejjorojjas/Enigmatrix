/// Pantalla de victoria (pase Enx 2026-07-11 v2): al resolver un caso se
/// estampa el sello CASO CERRADO sobre un informe en papel crema con la
/// revelación del asesino, los datos de la partida y el feedback de
/// playtest.
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
import 'enx_style.dart';

String _fmt(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

/// Guarda el resultado y muestra la celebración.
Future<void> showVictoryScreen(
    BuildContext context, WidgetRef ref, PuzzleCase pc) async {
  final state = ref.read(gameControllerProvider(pc));
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'done:${pc.caseId}',
      jsonEncode({
        'time': state.elapsedSeconds,
        'errors': state.errorCount,
        'date': DateTime.now().toIso8601String().substring(0, 16),
      }));

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Consumer(
      builder: (_, dialogRef, __) => Dialog.fullscreen(
        backgroundColor: dialogRef.watch(paletteProvider).background,
        child: _VictoryView(pc: pc, prefs: prefs),
      ),
    ),
  );
}

class _VictoryView extends ConsumerStatefulWidget {
  final PuzzleCase pc;
  final SharedPreferences prefs;
  const _VictoryView({required this.pc, required this.prefs});

  @override
  ConsumerState<_VictoryView> createState() => _VictoryViewState();
}

class _VictoryViewState extends ConsumerState<_VictoryView> {
  late final TextEditingController _fb = TextEditingController(
      text: widget.prefs.getString('fb:${widget.pc.caseId}') ?? '');

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
    final pal = ref.watch(paletteProvider);
    final pc = widget.pc;
    final state = ref.read(gameControllerProvider(pc));
    final murderer =
        state.murdererId == null ? null : pc.character(state.murdererId!);
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
                          border:
                              Border.all(color: Enx.crimson, width: 4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Enx.crimson, width: 2),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text('CASO CERRADO',
                              style: Enx.display(30,
                                  color: Enx.crimson, spacing: 3)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Buen trabajo, detective.',
                    textAlign: TextAlign.center,
                    style: Enx.display(19, color: Enx.gold)),
                Text(pc.map.nameEs,
                    textAlign: TextAlign.center,
                    style: Enx.font(15, color: pal.muted)),
                const SizedBox(height: 22),

                // Informe del caso en papel.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Enx.paper,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: enxDarken(Enx.paper, .4),
                          offset: const Offset(0, 6),
                          blurRadius: 0),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('INFORME DEL CASO',
                          style: Enx.font(11,
                              weight: FontWeight.w800,
                              color: Enx.inkMuted,
                              spacing: 2.5)),
                      const SizedBox(height: 4),
                      Container(height: 2, color: Enx.paperShade),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'El asesino era '),
                          TextSpan(
                              text: murderer?.nameEs ?? '?',
                              style: Enx.font(16,
                                  weight: FontWeight.w800,
                                  color: Enx.crimson)),
                          const TextSpan(
                              text: ', que quedó a solas con la víctima.'),
                        ]),
                        textAlign: TextAlign.center,
                        style: Enx.font(16, color: Enx.ink),
                      ),
                      if (weapon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Arma homicida: '),
                              TextSpan(
                                  text: weapon.nameEs,
                                  style: Enx.font(15,
                                      weight: FontWeight.w800,
                                      color: Enx.goldInk)),
                            ]),
                            style: Enx.font(15, color: Enx.ink),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EnxReportStat(
                              label: 'Tiempo',
                              value: _fmt(state.elapsedSeconds),
                              icon: Icons.timer_outlined,
                              color: Enx.blue),
                          const SizedBox(width: 12),
                          EnxReportStat(
                              label: 'Errores',
                              value: '${state.errorCount}',
                              icon: state.errorCount == 0
                                  ? Icons.verified_outlined
                                  : Icons.close_rounded,
                              color: state.errorCount == 0
                                  ? Enx.green
                                  : Enx.crimson),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Feedback de playtest (se conserva de la Fase 1).
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pal.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FEEDBACK DE PLAYTEST',
                          style: Enx.font(11,
                              weight: FontWeight.w800,
                              color: pal.muted,
                              spacing: 2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fb,
                        maxLines: 3,
                        style: Enx.font(14, weight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: pal.background,
                          hintText:
                              '¿Pistas confusas? ¿Dificultad justa?…',
                          hintStyle: Enx.font(14,
                              weight: FontWeight.w600, color: pal.muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: pal.border, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: pal.border, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Enx.gold, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                EnxButton(
                  label: 'Continuar',
                  color: Enx.gold,
                  textColor: Enx.goldInk,
                  onPressed: () => _saveAnd(() {
                    Navigator.of(context).pop();
                    context.go('/');
                  }),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      _saveAnd(() => Navigator.of(context).pop()),
                  child: Text('Seguir mirando el tablero',
                      style: Enx.font(14, color: pal.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
