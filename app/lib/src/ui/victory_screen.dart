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

import '../../l10n/l10n.dart';
import '../game/dev_tools.dart';
import '../game/game_controller.dart';
import 'dev_texts.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

/// Arma una frase con un dato resaltado: pide la frase con un marcador en
/// lugar del dato y lo reemplaza por un tramo con [style]. Así el orden de las
/// palabras lo decide cada idioma y no el código.
TextSpan _withHighlight(
  String Function(String marker) phrase,
  String value,
  TextStyle style,
) {
  const marker = '\u0001';
  final parts = phrase(marker).split(marker);
  return TextSpan(
    children: [
      TextSpan(text: parts.first),
      TextSpan(text: value, style: style),
      if (parts.length > 1) TextSpan(text: parts.sublist(1).join(marker)),
    ],
  );
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
    // Sin ENX_DEV no hay cuadro de feedback: no se toca lo ya guardado.
    if (ref.read(devToolsProvider)) {
      await widget.prefs.setString('fb:${widget.pc.caseId}', _fb.text);
    }
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
                            context.l10n.victoryStamp,
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
                  context.l10n.victoryGoodJob,
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
                      SectionLabel(context.l10n.victoryReport),
                      const SizedBox(height: 6),
                      Container(height: 2, color: p.line),
                      const SizedBox(height: 12),
                      Text.rich(
                        _withHighlight(
                          context.l10n.victoryMurdererLine,
                          murderer?.nameEs ?? '?',
                          context.body(
                            17,
                            weight: FontWeight.w800,
                            color: p.danger,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        style: context.body(16),
                      ),
                      if (weapon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text.rich(
                            _withHighlight(
                              context.l10n.victoryWeaponLine,
                              weapon.nameEs,
                              context.body(
                                16,
                                weight: FontWeight.w800,
                                color: p.accent,
                              ),
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
                              label: context.l10n.victoryTime,
                              icon: Icons.timer_outlined,
                              color: p.world(0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              value: '${state.errorCount}',
                              label: context.l10n.victoryErrors,
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

                // Feedback de la prueba de juego: solo con ENX_DEV (H-66).
                if (ref.watch(devToolsProvider)) ...[
                  ChromeBox(
                    color: p.surface,
                    radius: 16,
                    depth: 2.5,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(DevTexts.feedbackTitle),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fb,
                          maxLines: 3,
                          style: context.body(15, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: DevTexts.feedbackHint,
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
                ],
                const SizedBox(height: 20),

                AppButton(
                  label: context.l10n.victoryKeepGoing,
                  onTap: () => _saveAnd(() {
                    Navigator.of(context).pop();
                    context.go(exitRouteFor(pc.caseId));
                  }),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _saveAnd(() => Navigator.of(context).pop()),
                  child: Text(
                    context.l10n.victoryLookBoard,
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
