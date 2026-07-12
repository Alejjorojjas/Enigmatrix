/// Lenguaje visual propio de Enigmatrix (pase 2026-07-11 v2): mantiene lo
/// gordito, redondeado y presionable, pero con identidad detective —
/// violeta medianoche, latón dorado, hilo carmesí de tablero de evidencias
/// y papel crema de expediente. Tipografía Baloo 2 + Quicksand.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ambiente de color del tablero (el usuario elige desde la app para
/// comparar en vivo). Lo que NO cambia entre ambientes: latón dorado de
/// marca, hilo carmesí, papel crema y colores de dificultad.
class EnxPalette {
  final String name;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color muted;
  final Color lockedNode;

  const EnxPalette({
    required this.name,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.muted,
    required this.lockedNode,
  });

  /// Estilo elegido por el usuario (2026-07-12): PAPER CRAFT. Se conserva
  /// la infraestructura de paletas por si en el futuro entra un modo oscuro.
  static const presets = [
    EnxPalette(
      name: 'Papel',
      background: Color(0xFFE9DCBE),
      surface: Color(0xFFF7F0DC),
      surfaceHigh: Color(0xFFFFFBEA),
      border: Color(0xFFC9B48A),
      muted: Color(0xFF8A7A5C),
      lockedNode: Color(0xFFD9CBA8),
    ),
  ];
}

class PaletteNotifier extends Notifier<EnxPalette> {
  static const _prefsKey = 'enx:palette';

  @override
  EnxPalette build() {
    _load();
    return EnxPalette.presets[0];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final i = prefs.getInt(_prefsKey);
    if (i != null && i >= 0 && i < EnxPalette.presets.length) {
      state = EnxPalette.presets[i];
    }
  }

  Future<void> select(int i) async {
    state = EnxPalette.presets[i];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, i);
  }
}

final paletteProvider =
    NotifierProvider<PaletteNotifier, EnxPalette>(PaletteNotifier.new);

abstract final class Enx {
  /// Texto principal: tinta sobre papel.
  static const text = Color(0xFF3D2F1C);

  // Marca: latón, con variante tinta para texto sobre claro.
  static const gold = Color(0xFFF0B429);
  static const goldInk = Color(0xFF8A5C2E);

  // Chinchetas, hilo del corcho y sellos.
  static const crimson = Color(0xFFB3452E);

  // Papel de expediente (tarjetas claras).
  static const paper = Color(0xFFFFFBEA);
  static const paperShade = Color(0xFFE8D9B4);
  static const ink = Color(0xFF3D2F1C);
  static const inkMuted = Color(0xFF8A7A5C);

  static const green = Color(0xFF4A7A34);
  static const blue = Color(0xFF2E5D8A);
  static const red = Color(0xFFB3452E);

  /// Cuerpo de texto y UI: Quicksand redondeada geométrica.
  static TextStyle font(double size,
          {FontWeight weight = FontWeight.w700,
          Color color = text,
          double spacing = 0}) =>
      GoogleFonts.quicksand(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  /// Titulares: Baloo 2, gordita con carácter.
  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w700,
          Color color = text,
          double spacing = 0}) =>
      GoogleFonts.baloo2(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  /// Manuscrita: Patrick Hand, para nombres, etiquetas y notas de papel.
  static TextStyle hand(double size,
          {Color color = text, double spacing = 0}) =>
      GoogleFonts.patrickHand(
          fontSize: size, color: color, letterSpacing: spacing);
}

/// Oscurece un color para el borde inferior 3D.
Color enxDarken(Color c, [double amount = .28]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Botón gordito presionable: color sólido con borde inferior oscuro que se
/// hunde al tocar. La forma es propia (radio 18, texto Quicksand w800).
class EnxButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final Color? textColor;

  const EnxButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.textColor,
  });

  @override
  State<EnxButton> createState() => _EnxButtonState();
}

class _EnxButtonState extends State<EnxButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const edge = 5.0;
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : const Color(0xFFD9CBA8);
    final fg = widget.textColor ?? Colors.white;

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
          borderRadius: BorderRadius.circular(18),
          boxShadow: _pressed
              ? const []
              : [
                  BoxShadow(
                      color: enxDarken(color),
                      offset: const Offset(0, edge),
                      blurRadius: 0),
                ],
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fg, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: Enx.font(16,
                    weight: FontWeight.w800, color: fg, spacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip informativo pequeño (contadores, metadatos). Toma superficie y
/// borde del ambiente activo.
class EnxChip extends ConsumerWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const EnxChip(
      {super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ref.watch(paletteProvider);
    final fg = color ?? pal.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pal.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 5),
          Text(text, style: Enx.font(13.5, color: fg)),
        ],
      ),
    );
  }
}

/// Dato dentro del informe en papel: icono de color + etiqueta + valor.
class EnxReportStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const EnxReportStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Enx.paperShade,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(value,
                  style: Enx.display(20, color: Enx.ink)),
            ],
          ),
          Text(label.toUpperCase(),
              style: Enx.font(10,
                  weight: FontWeight.w800,
                  color: Enx.inkMuted,
                  spacing: 1.5)),
        ],
      ),
    );
  }
}
