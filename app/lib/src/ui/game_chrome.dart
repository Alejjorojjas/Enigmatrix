/// Recuadros y botones de la interfaz, dibujados según la piel activa:
///  - Ilustrada: contorno oscuro grueso y sombra suave.
///  - Papel: recorte con capa inferior más oscura, borde blanco y fibra.
///  - Neutra: plano con una línea fina.
/// Los colores salen de la paleta (`context.pal`), nunca de valores sueltos.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../board/scene/art_parts.dart';
import '../board/scene/palette.dart';
import 'skin_theme.dart';

class ChromeBox extends StatelessWidget {
  const ChromeBox({
    super.key,
    required this.child,
    this.color,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.depth = 3.5,
    this.pressed = false,
  });

  final Widget child;

  /// Relleno; por defecto el de las tarjetas.
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Grosor del recorte de papel y de la sombra dura (en píxeles).
  final double depth;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final enx = context.skinTheme;
    final p = enx.palette;
    final fill = color ?? p.surface;
    final r = BorderRadius.circular(radius);
    switch (enx.chrome) {
      case ChromeKind.flat:
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: Border.all(color: p.line),
          ),
          child: child,
        );
      case ChromeKind.ink:
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: Border.all(color: p.line, width: 2),
            boxShadow: pressed
                ? const []
                : [
                    BoxShadow(
                      color: p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.30),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: child,
        );
      case ChromeKind.paper:
        final d = pressed ? depth * 0.35 : depth;
        return Container(
          padding: EdgeInsets.only(bottom: d),
          decoration: BoxDecoration(
            color: shadeColor(fill, 0.36),
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.26),
                offset: const Offset(0, 3),
                blurRadius: 7,
              ),
            ],
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: r,
              border: Border.all(color: p.paperEdge, width: 2.2),
            ),
            // Fibra de papel dentro de cada recorte.
            child: CustomPaint(
              painter: _GrainPainter(
                p.paperEdge.withValues(alpha: p.isDark ? 0.14 : 0.30),
              ),
              child: child,
            ),
          ),
        );
    }
  }
}

/// Recuadro que se hunde un poco al tocarlo. Cumple el tamaño mínimo de toque.
class ChromeButton extends StatefulWidget {
  const ChromeButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.semanticsLabel,
    this.selected = false,
    this.minSize = const Size(SkinUi.minTouch, SkinUi.minTouch),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;
  final bool selected;
  final Size minSize;

  @override
  State<ChromeButton> createState() => _ChromeButtonState();
}

class _ChromeButtonState extends State<ChromeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticsLabel,
      // Con etiqueta propia, el texto de adentro no se lee dos veces.
      excludeSemantics: widget.semanticsLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.45,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 70),
            offset: _down ? const Offset(0, 0.04) : Offset.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.minSize.width,
                minHeight: widget.minSize.height,
              ),
              child: ChromeBox(
                color: widget.color,
                radius: widget.radius,
                padding: widget.padding,
                pressed: _down,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fibra de papel para fondos de la interfaz (solo se usa en la piel Papel).
class PaperFibers extends StatelessWidget {
  const PaperFibers({super.key, this.seed = 3});
  final int seed;

  @override
  Widget build(BuildContext context) {
    if (context.skinTheme.chrome != ChromeKind.paper) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _FibersPainter(
          seed,
          context.pal.paperEdge.withValues(
            alpha: context.pal.isDark ? 0.12 : 0.34,
          ),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FibersPainter extends CustomPainter {
  _FibersPainter(this.seed, this.color);
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintFibers(
      canvas,
      Offset.zero & size,
      seed,
      color,
      count: math.max(20, (size.width * size.height / 2200).round()),
      len: 14,
      width: 0.9,
    );
  }

  @override
  bool shouldRepaint(_FibersPainter old) =>
      old.color != color || old.seed != seed;
}

/// Fibras cortas dentro de un recorte de la interfaz (piel Papel).
class _GrainPainter extends CustomPainter {
  _GrainPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    paintFibers(
      canvas,
      Offset.zero & size,
      5,
      color,
      count: math.max(4, (size.width * size.height / 1100).round()),
      len: 11,
      width: 0.9,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.color != color;
}
