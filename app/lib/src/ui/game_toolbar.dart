/// Barra de herramientas (Anotar, Tachar, Confirmar, Borrar), cronómetro en una
/// pastilla, botones cuadrados y botón Resolver. Todo con la forma y los
/// colores de la piel activa.
library;

import 'package:flutter/material.dart';

import '../game/game_controller.dart' show ToolMode;
import 'game_chrome.dart';
import 'skin_theme.dart';

/// Textos de la partida que se repiten (centralizados para traducir en 4.3).
abstract final class GameTexts {
  static const toolNotes = 'Anotar';
  static const toolCross = 'Tachar';
  static const toolPlace = 'Confirmar';
  static const toolErase = 'Borrar';
  static const resolve = 'Resolver';
  static const viewSummary = 'Ver resumen';
  static const undo = 'Deshacer';
  static const back = 'Salir del caso';
  static const menu = 'Más acciones';
  static const victim = 'Víctima';
}

class ToolBar extends StatelessWidget {
  const ToolBar({
    super.key,
    required this.mode,
    required this.onSelect,
    this.enabled = true,
    this.height = 56,
    this.wrap,
  });

  final ToolMode mode;
  final ValueChanged<ToolMode> onSelect;
  final bool enabled;

  /// Permite envolver cada botón (el tutorial lo usa para señalarlos).
  final Widget Function(ToolMode mode, Widget button)? wrap;

  /// Alto de los botones (56 normal, 52 en pantallas bajas).
  final double height;

  @override
  Widget build(BuildContext context) {
    final tools = <(ToolMode, IconData, String)>[
      (ToolMode.notes, Icons.edit_outlined, GameTexts.toolNotes),
      (ToolMode.cross, Icons.close, GameTexts.toolCross),
      (ToolMode.place, Icons.check, GameTexts.toolPlace),
      (ToolMode.erase, Icons.cleaning_services_outlined, GameTexts.toolErase),
    ];
    Widget button(ToolMode m, IconData icon, String label) {
      final b = ToolButton(
        key: ValueKey('herramienta-${m.name}'),
        icon: icon,
        label: label,
        height: height,
        active: mode == m,
        onTap: enabled ? () => onSelect(m) : null,
      );
      return wrap == null ? b : wrap!(m, b);
    }

    return Row(
      children: [
        for (var i = 0; i < tools.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: button(tools[i].$1, tools[i].$2, tools[i].$3)),
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
      minSize: Size(SkinUi.minTouch, height),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: fg),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cronómetro en una pastilla oscura con un punto de acento. Es un widget
/// aparte para que el reloj solo redibuje esta pastilla cada segundo, no el
/// tablero (H-58).
class TimerPill extends StatelessWidget {
  const TimerPill({super.key, required this.seconds, this.subline});

  final int seconds;

  /// Segunda línea pequeña (el medidor de FPS, si está activo).
  final Widget? subline;

  static String format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: 'Tiempo ${format(seconds)}',
      excludeSemantics: true,
      child: ChromeBox(
        color: p.pill,
        radius: 30,
        depth: 3,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: subline == null ? 8 : 3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  format(seconds),
                  key: const ValueKey('cronometro'),
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

/// Botón cuadrado con un ícono (salir, deshacer, menú).
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

/// Botón grande Resolver (o Ver resumen si el caso ya se resolvió).
class ResolveBar extends StatelessWidget {
  const ResolveBar({
    super.key,
    required this.solved,
    required this.onResolve,
    required this.onSummary,
    this.height = 46,
    this.fill = true,
  });

  final bool solved;
  final VoidCallback onResolve;
  final VoidCallback onSummary;
  final double height;

  /// true = ocupa todo el ancho; false = solo lo que pide su texto (para ir al
  /// lado de la pista en pantallas bajas).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final label = solved ? GameTexts.viewSummary : GameTexts.resolve;
    return SizedBox(
      width: fill ? double.infinity : null,
      child: ChromeButton(
        key: const ValueKey('boton-resolver'),
        onTap: solved ? onSummary : onResolve,
        color: p.accent,
        radius: 20,
        minSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        semanticsLabel: label,
        child: Row(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              solved ? Icons.article_outlined : Icons.search,
              color: p.onAccent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
