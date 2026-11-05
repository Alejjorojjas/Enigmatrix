/// Barra de herramientas (Anotar, Tachar, Confirmar, Borrar), cronómetro en una
/// pastilla y botón Resolver. Todo con la forma y los colores de la piel
/// activa.
library;

import 'package:flutter/material.dart';

import '../game/game_session.dart';
import '../strings.dart';
import 'chrome.dart';
import 'prototype_theme.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({super.key, required this.session, this.height = 56});

  final GameSession session;

  /// Alto de los botones (56 normal, 52 en pantallas bajas).
  final double height;

  @override
  Widget build(BuildContext context) {
    final tools = <(ToolMode, IconData, String)>[
      (ToolMode.notes, Icons.edit_outlined, Strings.toolNotes),
      (ToolMode.cross, Icons.close, Strings.toolCross),
      (ToolMode.place, Icons.check, Strings.toolPlace),
      (ToolMode.erase, Icons.cleaning_services_outlined, Strings.toolErase),
    ];
    return Row(
      children: [
        for (var i = 0; i < tools.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: ToolButton(
              icon: tools[i].$2,
              label: tools[i].$3,
              height: height,
              active: session.tool == tools[i].$1,
              onTap: session.solved ? null : () => session.setTool(tools[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.height = 56,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = active ? p.onToolActive : p.text;
    return ChromeButton(
      onTap: onTap,
      color: active ? p.toolActive : p.surface,
      selected: active,
      semanticsLabel: label,
      radius: 18,
      minSize: Size(Ui.minTouch, height),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: fg),
          Text(label,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 13, height: 1.15, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Cronómetro en una pastilla oscura con un punto de acento.
class TimerPill extends StatelessWidget {
  const TimerPill({super.key, required this.seconds, this.subline});

  final int seconds;

  /// Segunda línea pequeña (el medidor de FPS, si está activo en Opciones).
  final Widget? subline;

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: 'Tiempo ${_fmt(seconds)}',
      child: ChromeBox(
        color: p.pill,
        radius: 30,
        depth: 3,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: subline == null ? 8 : 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 9),
                Text(
                  _fmt(seconds),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.2,
                    color: p.onPill,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            ?subline,
          ],
        ),
      ),
    );
  }
}

/// Botón cuadrado con un ícono (opciones, deshacer, piel, modo).
class IconSquare extends StatelessWidget {
  const IconSquare({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: ChromeButton(
        onTap: onTap,
        semanticsLabel: label,
        radius: 16,
        padding: EdgeInsets.zero,
        child: Icon(icon, size: 24, color: context.pal.text),
      ),
    );
  }
}

/// Botón grande Resolver (o Jugar de nuevo si ya se resolvió).
class ResolveBar extends StatelessWidget {
  const ResolveBar({
    super.key,
    required this.session,
    required this.onPlayAgain,
    this.height = 46,
    this.fill = true,
  });

  final GameSession session;
  final VoidCallback onPlayAgain;
  final double height;

  /// true = ocupa todo el ancho; false = solo lo que pide su texto (para ir al
  /// lado de la pista en pantallas bajas).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final solved = session.solved;
    return SizedBox(
      width: fill ? double.infinity : null,
      child: ChromeButton(
        onTap: solved ? onPlayAgain : session.solve,
        color: p.accent,
        radius: 20,
        minSize: Size(0, height),
        semanticsLabel: solved ? Strings.playAgain : Strings.resolve,
        child: Row(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(solved ? Icons.replay : Icons.search, color: p.onAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              solved ? Strings.playAgain : Strings.resolve,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: p.onAccent),
            ),
          ],
        ),
      ),
    );
  }
}
