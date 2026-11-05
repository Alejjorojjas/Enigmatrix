/// Selectores de piel (Ilustrada o Papel) y de modo (Sistema, Claro u Oscuro).
/// Se usan en Configuración y en el menú de la partida. Toman los colores del
/// tema donde se pongan, así sirven con el estilo de papel de la app y con
/// las pieles del juego.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/scene/skins.dart';
import '../game/app_settings.dart';

/// Textos del selector (centralizados para traducir en la ronda 4.3).
abstract final class AppearanceTexts {
  static const title = 'Aspecto del juego';
  static const skin = 'Piel';
  static const mode = 'Modo';
  static const system = 'Sistema';
  static const light = 'Claro';
  static const dark = 'Oscuro';
}

class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key, this.labelStyle});

  /// Estilo de los rótulos "Piel" y "Modo" (por omisión, el del tema).
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final label =
        labelStyle ??
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppearanceTexts.skin, style: label),
        const SizedBox(height: 6),
        _Segments<String>(
          key: const ValueKey('selector-piel'),
          value: settings.skinId == 'neutra' ? kDefaultSkin : settings.skinId,
          options: [
            for (final id in kPlayerSkins)
              (id, SkinRegistry.spec(id).displayName),
          ],
          onChanged: notifier.setSkin,
        ),
        const SizedBox(height: 12),
        Text(AppearanceTexts.mode, style: label),
        const SizedBox(height: 6),
        _Segments<ThemeMode>(
          key: const ValueKey('selector-modo'),
          value: settings.themeMode,
          options: const [
            (ThemeMode.system, AppearanceTexts.system),
            (ThemeMode.light, AppearanceTexts.light),
            (ThemeMode.dark, AppearanceTexts.dark),
          ],
          onChanged: notifier.setThemeMode,
        ),
      ],
    );
  }
}

class _Segments<T> extends StatelessWidget {
  const _Segments({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? cs.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: cs.onSurface.withValues(alpha: 0.35)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        segments: [
          for (final o in options)
            ButtonSegment<T>(value: o.$1, label: Text(o.$2)),
        ],
        selected: {value},
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );
  }
}
