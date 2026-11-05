/// Banco de pruebas (desarrollo): los 20 casos de prueba que ya no salen en la
/// navegación normal. Se abre desde Configuración > "Banco de pruebas
/// (desarrollo)" y sirve para probar el motor y el tablero con casos sueltos.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/case_repository.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

/// Textos del banco de pruebas (centralizados para traducir en la ronda 4.3).
abstract final class BankTexts {
  static const title = 'Banco de pruebas';
  static const subtitle =
      'Solo para desarrollo: estos casos no forman parte del juego.';
  static const back = 'Volver';
  static const done = 'Resuelto';
  static const open = 'En curso';
  static const error = 'No se pudo cargar el banco de pruebas';
}

class BankScreen extends ConsumerWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final cases = ref.watch(casesProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Tooltip(
                      message: BankTexts.back,
                      child: ChromeButton(
                        onTap: () => context.go('/home'),
                        radius: 14,
                        color: p.surface,
                        semanticsLabel: BankTexts.back,
                        padding: EdgeInsets.zero,
                        minSize: const Size(SkinUi.minTouch, SkinUi.minTouch),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: p.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(BankTexts.title, style: context.display(22)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  BankTexts.subtitle,
                  style: context.note(15, color: p.softText),
                ),
              ),
              Expanded(
                child: cases.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '${BankTexts.error}: $e',
                        textAlign: TextAlign.center,
                        style: context.body(16, color: p.danger),
                      ),
                    ),
                  ),
                  data: (list) => ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    children: [
                      for (final pc in list)
                        _BankRow(
                          pc: pc,
                          state: _stateOf(
                            prefs?.getString('done:${pc.caseId}'),
                            prefs?.getString('game:${pc.caseId}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _stateOf(String? done, String? game) {
    if (done != null) return BankTexts.done;
    return game != null ? BankTexts.open : null;
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.pc, required this.state});

  final PuzzleCase pc;
  final String? state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final title = caseTitle(pc);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      accent: p.difficulty(pc.difficulty),
      semanticsLabel:
          '$title, ${difficultyName(pc.difficulty)}, tablero '
          '${pc.map.size} por ${pc.map.size}${state == null ? '' : ', $state'}',
      onTap: () => context.go('/play/${pc.caseId}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pc.caseId,
                  style: context.body(16, weight: FontWeight.w800),
                ),
                Text(
                  '${difficultyName(pc.difficulty)} · '
                  '${pc.map.size}×${pc.map.size}'
                  '${state == null ? '' : ' · $state'}',
                  style: context.body(
                    14,
                    weight: FontWeight.w600,
                    color: p.softText,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textDim, size: 28),
        ],
      ),
    );
  }
}
