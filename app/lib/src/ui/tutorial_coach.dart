/// Tutorial jugable paso a paso (2026-07-12): guía superpuesta a la partida
/// que avanza sola detectando las acciones del jugador (anotar candidato,
/// confirmar, completar el tablero). Se abre desde el nodo TUTORIAL del
/// camino de mundos, antes del Caso Nº1.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
import 'enx_style.dart';

const tutorialPlayedKey = 'tutorial:played';

/// Un paso del guía: texto + condición de avance (null = botón manual).
class _Step {
  final String emoji;
  final String text;
  final bool Function(GameState state, int total)? advanceWhen;
  const _Step(this.emoji, this.text, {this.advanceWhen});
}

final _steps = <_Step>[
  const _Step('🕵️',
      'Bienvenido a tu primer caso. Este mapa es la escena: habitaciones, '
      'muebles… y abajo, los sospechosos con su pista.'),
  const _Step('📏',
      'Regla de oro: hay UNA persona por fila y UNA por columna, como en '
      'un sudoku. Todos deben quedar ubicados, incluida la víctima.'),
  _Step('✏️',
      'Toca la tarjeta de un sospechoso y luego TOCA una casilla que '
      'cumpla su pista: quedará anotado como candidato (su letra).',
      advanceWhen: (s, _) => !s.board.isEmpty),
  _Step('📌',
      '¡Bien! Cuando estés seguro, MANTÉN PRESIONADA la casilla (o '
      'arrastra la tarjeta) para CONFIRMARLO.',
      advanceWhen: (s, _) => s.board.confirmedCells.isNotEmpty),
  const _Step('❌',
      '¿Viste? Al confirmar se tachan su fila y su columna con X '
      'automáticas: ahí ya no puede ir nadie más.'),
  _Step('🧩',
      'Ahora sigue tú: usa cada pista y los descartes para ubicar a '
      'TODOS. Puedes borrar con la papelera y deshacer si te equivocas.',
      advanceWhen: (s, total) => s.board.confirmedCells.length >= total),
  const _Step('⚖️',
      '¡Todos ubicados! Pulsa RESOLVER. Si el tablero está bien, sabrás '
      'quién quedó a solas con la víctima: el asesino.'),
];

class TutorialCoach extends ConsumerStatefulWidget {
  final PuzzleCase pc;
  const TutorialCoach({super.key, required this.pc});

  @override
  ConsumerState<TutorialCoach> createState() => _TutorialCoachState();
}

class _TutorialCoachState extends ConsumerState<TutorialCoach> {
  int _step = 0;
  bool _dismissed = false;

  void _advance() {
    if (_step >= _steps.length - 1) return;
    setState(() => _step++);
    if (_step == _steps.length - 1) _markPlayed();
  }

  Future<void> _markPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialPlayedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final state = ref.watch(gameControllerProvider(widget.pc));
    if (state.solved) return const SizedBox.shrink();

    // Avance automático si el paso tiene condición y ya se cumplió.
    final step = _steps[_step];
    final auto = step.advanceWhen;
    if (auto != null && auto(state, widget.pc.characters.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _advance();
      });
    }

    final isManual = step.advanceWhen == null;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: Enx.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Enx.gold, width: 2.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x73473418),
                offset: Offset(0, 6),
                blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(step.text, style: Enx.hand(17.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('TUTORIAL · ${_step + 1}/${_steps.length}',
                    style: Enx.font(10.5,
                        weight: FontWeight.w800,
                        color: Enx.inkMuted,
                        spacing: 1.5)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _markPlayed();
                    setState(() => _dismissed = true);
                  },
                  child: Text('Saltar',
                      style: Enx.font(13, color: Enx.inkMuted)),
                ),
                if (isManual)
                  EnxButton(
                    label: 'Entendido',
                    color: Enx.gold,
                    textColor: const Color(0xFF4A3200),
                    expand: false,
                    onPressed: _advance,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
