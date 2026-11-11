/// Shell de navegación: barra inferior con cinco pestañas (Inicio, Mundos,
/// Reto, Ranking y Perfil) dibujada con el recuadro de la piel activa. Las
/// pantallas usan DATOS SIMULADOS (DEMO) mientras llega el servidor; la
/// estructura queda final. El primer arranque abre el tutorial obligatorio.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../game/dev_tools.dart' show showSimulatedProvider;
import 'case_list_screen.dart' show prefsProvider;
import 'game_chrome.dart';
import 'home_tabs.dart';
import 'skin_theme.dart';
import 'tutorial_coach.dart' show tutorialPlayedKey;
import 'tutorial_dialog.dart';
import 'ui_kit.dart';

export 'mock_data.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  bool _tutorialChecked = false;

  /// El tutorial SIEMPRE aparece en el primer arranque tras instalar (o
  /// reinstalar: allowBackup=false borra las prefs al desinstalar): primero
  /// el diálogo de bienvenida y después, directo, el caso de práctica
  /// (regla 11, ADR-0012). Allí hay un botón Saltar siempre visible; si se
  /// salta o se termina no vuelve a aparecer solo.
  void _maybeShowTutorial(SharedPreferences prefs) {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    // Solo cuenta la clave v2: las viejas (tutorial:seen / tutorial:played)
    // no eximen del tutorial nuevo.
    if (prefs.getBool(tutorialPlayedKey) ?? false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showTutorialDialog(context, thenPractice: true);
      if (mounted) context.go('/tutorial');
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider).valueOrNull;
    if (prefs != null) _maybeShowTutorial(prefs);
    // Ranking es simulado: solo existe con kShowSimulated (pregunta 18).
    final showRanking = ref.watch(showSimulatedProvider);
    final tabs = [
      const HomeTab(),
      const WorldsTab(),
      const ChallengeTab(),
      if (showRanking) const RankingTab(),
      const ProfileTab(),
    ];
    if (_tab >= tabs.length) _tab = tabs.length - 1;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _tab, children: tabs),
        ),
      ),
      bottomNavigationBar: _NavBar(
        showRanking: showRanking,
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Barra inferior: ícono y rótulo; la pestaña activa va enmarcada.
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.current,
    required this.onTap,
    required this.showRanking,
  });

  final bool showRanking;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = [
      (Icons.home_rounded, context.l10n.navHome, p.danger),
      (Icons.map_rounded, context.l10n.navWorlds, p.good),
      (Icons.today_rounded, context.l10n.navChallenge, p.accent),
      if (showRanking)
        (Icons.emoji_events_rounded, context.l10n.navRanking, p.medal(0)),
      (Icons.person_rounded, context.l10n.navProfile, p.world(0)),
    ];
    return ColoredBox(
      color: p.surface,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.line, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            // El alto crece con el texto del sistema (ícono + rótulo + aire).
            child: SizedBox(
              height: math.max(
                62.0,
                26 + MediaQuery.textScalerOf(context).scale(17) + 18,
              ),
              child: Row(
                children: [
                  for (final (i, item) in items.indexed)
                    Expanded(
                      child: _NavItem(
                        icon: item.$1,
                        label: item.$2,
                        color: item.$3,
                        selected: i == current,
                        onTap: () => onTap(i),
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = selected ? p.onColor(color) : p.textDim;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ChromeButton(
        onTap: onTap,
        color: selected ? color : p.surface,
        radius: 16,
        selected: selected,
        semanticsLabel: label,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        minSize: const Size(SkinUi.minTouch, 54),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: fg),
            Text(
              label,
              maxLines: 1,
              style: context.body(13, weight: FontWeight.w800, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
