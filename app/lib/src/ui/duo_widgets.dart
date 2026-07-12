/// Lenguaje visual "Duo" (pase 2026-07-11): botones gorditos presionables
/// con borde inferior 3D, tipografía redondeada extra-bold y fondo oscuro
/// azulado. Inspirado en el design system Feather de Duolingo, adaptado a
/// la identidad detective de Enigmatrix.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta del pase Duo. Convive con Brand (main.dart) mientras el estilo
/// se valida pantalla por pantalla.
abstract final class Duo {
  static const background = Color(0xFF131F24);
  static const surface = Color(0xFF1E2C33);
  static const surfaceHigh = Color(0xFF25343D);
  static const border = Color(0xFF37464F);
  static const text = Color(0xFFF1F7FB);
  static const muted = Color(0xFF8FA5B0);

  static const green = Color(0xFF58CC02);
  static const blue = Color(0xFF1CB0F6);
  static const orange = Color(0xFFFF9600);
  static const red = Color(0xFFFF4B4B);
  static const yellow = Color(0xFFFFC800);
  static const purple = Color(0xFFCE82FF);
  static const gold = Color(0xFFE3B341);

  /// Gris de nodo pendiente (no actual).
  static const lockedNode = Color(0xFF37464F);

  static TextStyle font(double size,
          {FontWeight weight = FontWeight.w800,
          Color color = text,
          double spacing = 0}) =>
      GoogleFonts.nunito(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);
}

/// Oscurece un color para el borde inferior 3D.
Color duoDarken(Color c, [double amount = .28]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Botón gordito estilo Duolingo: color sólido, borde inferior oscuro que
/// se "hunde" al presionar.
class DuoButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final Color? textColor;

  const DuoButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.textColor,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const edge = 5.0;
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Duo.lockedNode;
    final label = Text(
      widget.label.toUpperCase(),
      textAlign: TextAlign.center,
      style: Duo.font(16,
          color: widget.textColor ?? Colors.white, spacing: 1.2),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: EdgeInsets.only(top: _pressed ? edge : 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? const []
              : [
                  BoxShadow(
                      color: duoDarken(color),
                      offset: const Offset(0, edge),
                      blurRadius: 0),
                ],
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  color: widget.textColor ?? Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: label),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de estadística estilo fin de lección: marco de color con
/// cabecera y valor grande.
class DuoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DuoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label.toUpperCase(),
                style: Duo.font(11, color: Colors.white, spacing: 1.5)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Duo.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 6),
                Text(value, style: Duo.font(20, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip informativo pequeño (contadores, metadatos).
class DuoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const DuoChip(
      {super.key,
      required this.icon,
      required this.text,
      this.color = Duo.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Duo.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Duo.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(text, style: Duo.font(13.5, color: color)),
        ],
      ),
    );
  }
}
