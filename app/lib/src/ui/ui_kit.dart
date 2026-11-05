/// Piezas de interfaz compartidas por todas las pantallas (ronda 4.2, H-59):
/// fondo, tarjetas, botones, fichas, barras de progreso, íconos de color y
/// hojas inferiores. Se dibujan con [ChromeBox] y [ChromeButton], así que cada
/// piel las ve a su manera (contorno oscuro en Ilustrada, recortes de papel en
/// Papel) y todo el color sale de la paleta del modo activo.
library;

import 'package:flutter/material.dart';

import '../board/scene/palette.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';

/// Textos que se repiten en varias pantallas (centralizados para traducir en
/// la ronda 4.3).
abstract final class UiTexts {
  static const demo = 'DEMO';
  static const comingSoon = 'Próximamente';
  static const back = 'Volver';
  static const close = 'Cerrar';
  static const demoNotice =
      'Función simulada: se activa con el modo online (Fase 2)';
}

/// Fondo de pantalla: el color de la piel, una luz suave arriba y, en Papel,
/// la fibra del cartón.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bg,
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.3,
          colors: [
            p.light.withValues(alpha: p.isDark ? 0.07 : 0.28),
            p.light.withValues(alpha: 0),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [const PaperFibers(), child],
      ),
    );
  }
}

/// Tarjeta de la interfaz. Con [accent] lleva una franja de color a la
/// izquierda; con [onTap] se puede tocar entera.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.color,
    this.onTap,
    this.semanticsLabel,
    this.radius = 18,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final double radius;

  static const double stripe = 8;

  @override
  Widget build(BuildContext context) {
    final inner = accent == null
        ? Padding(padding: padding, child: child)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius - 3),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: stripe),
                  child: Padding(padding: padding, child: child),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: stripe,
                  child: ColoredBox(color: accent!),
                ),
              ],
            ),
          );
    Widget box = SizedBox(
      width: double.infinity,
      child: ChromeBox(color: color, radius: radius, child: inner),
    );
    if (onTap != null) {
      box = Semantics(
        button: true,
        label: semanticsLabel,
        // Con etiqueta propia, el texto de adentro no se lee dos veces.
        excludeSemantics: semanticsLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: box,
        ),
      );
    }
    return Padding(padding: margin, child: box);
  }
}

/// Botón con texto (y ícono opcional). [color] por omisión es el acento de la
/// piel; con [quiet] es un botón discreto.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
    this.expand = true,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final bool expand;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fill = quiet ? p.surfaceAlt : (color ?? p.accent);
    final fg = quiet ? p.text : p.onColor(fill);
    final btn = ChromeButton(
      onTap: onTap,
      color: fill,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      minSize: const Size(SkinUi.minTouch, 52),
      semanticsLabel: label,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.body(
                15,
                weight: FontWeight.w800,
                color: fg,
                spacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Ficha informativa pequeña (ícono y texto).
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = color ?? p.text;
    return ChromeBox(
      color: p.surfaceAlt,
      radius: 12,
      depth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, style: context.body(13, color: p.text)),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta "DEMO": lo que todavía es simulado debe verse como tal.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.pill,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          UiTexts.demo,
          style: context.body(
            13,
            weight: FontWeight.w800,
            color: p.onPill,
            spacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta "Próximamente" para lo que todavía no se puede abrir.
class SoonBadge extends StatelessWidget {
  const SoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.textDim, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          UiTexts.comingSoon,
          style: context.body(13, color: p.textDim),
        ),
      ),
    );
  }
}

/// Rótulo en mayúsculas sobre un bloque.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.textDim;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: context.body(
              13,
              weight: FontWeight.w800,
              color: c,
              spacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra de progreso redondeada con la paleta de la piel.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 12,
    this.semanticsLabel,
  });

  final double value;
  final Color? color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: '${(v * 100).round()}%',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: p.line, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: ColoredBox(color: color ?? p.accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrito de color con un ícono (mundos, dificultades, avatar). Se dibuja
/// con el recuadro de la piel.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ChromeBox(
      color: color,
      radius: size * 0.3,
      depth: 3,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: size * 0.54, color: p.onColor(color)),
        ),
      ),
    );
  }
}

/// Dato grande con su rótulo (puntos, racha, casos cerrados).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.demo = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ChromeBox(
      color: p.surfaceAlt,
      radius: 16,
      depth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: color ?? p.accent),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: context.display(24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.body(13, weight: FontWeight.w600, color: p.textDim),
          ),
          if (demo) ...[const SizedBox(height: 4), const DemoBadge()],
        ],
      ),
    );
  }
}

/// Aviso corto en la parte de abajo (SnackBar con el tema de la piel).
void showAppToast(BuildContext context, String text) {
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(content: Text(text)));
}

/// Hoja inferior con el tema de la piel. El contenido se desplaza si no cabe
/// (por ejemplo en pantallas bajas).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 520),
  builder: (ctx) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: builder(ctx),
    ),
  ),
);

/// Estilo del recuadro según la piel (para quien necesite distinguir).
bool isPaperSkin(BuildContext context) =>
    context.skinTheme.chrome == ChromeKind.paper;

/// Título de una pestaña: nombre grande, línea de apoyo y, a la derecha,
/// lo que se quiera (etiqueta DEMO, botón).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.badge});

  final String title;
  final String? subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(title, style: context.display(30))),
              if (badge != null) ...[const SizedBox(width: 10), badge!],
            ],
          ),
          if (subtitle != null)
            Text(subtitle!, style: context.note(16, color: p.softText)),
        ],
      ),
    );
  }
}

/// Fila con un interruptor (Sonido, Vibración). Sin [onChanged] queda
/// apagada y con la etiqueta "Próximamente".
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final enabled = onChanged != null;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: icon == null
          ? null
          : Icon(icon, size: 24, color: enabled ? p.text : p.textDim),
      title: Text(
        label,
        style: context.body(16, color: enabled ? p.text : p.textDim),
      ),
      subtitle: enabled
          ? null
          : const Align(alignment: Alignment.centerLeft, child: SoonBadge()),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Recuadro de aviso dentro de una hoja (donde un SnackBar quedaría tapado).
class NoticeBox extends StatelessWidget {
  const NoticeBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ChromeBox(
      color: p.surfaceAlt,
      radius: 14,
      depth: 2,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: context.body(14, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
