/// Pantalla de victoria (pase Duo 2026-07-11): celebración a pantalla
/// completa al resolver un caso — insignia animada, revelación del asesino,
/// tarjetas de estadísticas y feedback de playtest.
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
import 'duo_widgets.dart';

String _fmt(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
    '${(seconds % 60).toString().padLeft(2, '0')}';

/// Guarda el resultado y muestra la celebración. Reemplaza al viejo
/// AlertDialog de resumen.
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
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Duo.background,
      child: _VictoryView(pc: pc, prefs: prefs),
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
                // Insignia que entra con rebote.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .4, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD75E), Duo.gold],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: duoDarken(Duo.gold),
                              offset: const Offset(0, 7),
                              blurRadius: 0),
                          BoxShadow(
                              color: Duo.gold.withValues(alpha: .35),
                              blurRadius: 40,
                              spreadRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 64, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('¡CASO RESUELTO!',
                    textAlign: TextAlign.center,
                    style: Duo.font(28,
                        weight: FontWeight.w900,
                        color: Duo.gold,
                        spacing: 1.5)),
                const SizedBox(height: 6),
                Text(pc.map.nameEs,
                    textAlign: TextAlign.center,
                    style: Duo.font(16, color: Duo.muted)),
                const SizedBox(height: 24),

                // Revelación del asesino.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Duo.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Duo.border, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('LA REVELACIÓN',
                          style: Duo.font(11,
                              color: Duo.muted, spacing: 2.5)),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'El asesino era '),
                          TextSpan(
                              text: murderer?.nameEs ?? '?',
                              style: Duo.font(16,
                                  weight: FontWeight.w900,
                                  color: Duo.red)),
                          const TextSpan(
                              text: ', que quedó a solas con la víctima.'),
                        ]),
                        textAlign: TextAlign.center,
                        style: Duo.font(16, weight: FontWeight.w600),
                      ),
                      if (weapon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Arma homicida: '),
                              TextSpan(
                                  text: weapon.nameEs,
                                  style: Duo.font(15,
                                      weight: FontWeight.w900,
                                      color: Duo.gold)),
                            ]),
                            style:
                                Duo.font(15, weight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Estadísticas.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DuoStatCard(
                        label: 'Tiempo',
                        value: _fmt(state.elapsedSeconds),
                        icon: Icons.timer_outlined,
                        color: Duo.blue),
                    const SizedBox(width: 12),
                    DuoStatCard(
                        label: 'Errores',
                        value: '${state.errorCount}',
                        icon: state.errorCount == 0
                            ? Icons.verified_outlined
                            : Icons.close_rounded,
                        color:
                            state.errorCount == 0 ? Duo.green : Duo.red),
                  ],
                ),
                const SizedBox(height: 18),

                // Feedback de playtest (se conserva de la Fase 1).
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Duo.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Duo.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FEEDBACK DE PLAYTEST',
                          style: Duo.font(11,
                              color: Duo.muted, spacing: 2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fb,
                        maxLines: 3,
                        style: Duo.font(14, weight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Duo.background,
                          hintText:
                              '¿Pistas confusas? ¿Dificultad justa?…',
                          hintStyle: Duo.font(14,
                              weight: FontWeight.w600, color: Duo.muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Duo.border, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Duo.border, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Duo.blue, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                DuoButton(
                  label: 'Continuar',
                  color: Duo.green,
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
                      style: Duo.font(14, color: Duo.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
