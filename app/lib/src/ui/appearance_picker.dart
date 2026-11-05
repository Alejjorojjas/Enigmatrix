/// Selectores de piel (Ilustrada o Papel) y de modo (Sistema, Claro u Oscuro).
/// Se usan en Configuración y en el menú de la partida. Se dibujan con los
/// botones de la piel activa (ChromeButton) y su paleta.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../game/app_settings.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';

/// Nombre visible de una piel (los textos viven en el .arb).
String skinName(AppLocalizations l10n, String id) => switch (id) {
  'ilustrada' => l10n.skinIllustrated,
  'papel' => l10n.skinPaper,
  'neutra' => l10n.skinNeutral,
  _ => id,
};

class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key, this.labelStyle});

  /// Estilo de los rótulos "Piel" y "Modo" (por omisión, el del tema).
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final label = labelStyle ?? context.body(15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.appearanceSkin, style: label),
        const SizedBox(height: 6),
        _Segments<String>(
          key: const ValueKey('selector-piel'),
          value: settings.skinId == 'neutra' ? kDefaultSkin : settings.skinId,
          options: [
            for (final id in kPlayerSkins) (id, skinName(context.l10n, id)),
          ],
          onChanged: notifier.setSkin,
        ),
        const SizedBox(height: 12),
        Text(context.l10n.appearanceMode, style: label),
        const SizedBox(height: 6),
        _Segments<ThemeMode>(
          key: const ValueKey('selector-modo'),
          value: settings.themeMode,
          options: [
            (ThemeMode.system, context.l10n.appearanceSystem),
            (ThemeMode.light, context.l10n.appearanceLight),
            (ThemeMode.dark, context.l10n.appearanceDark),
          ],
          onChanged: notifier.setThemeMode,
        ),
      ],
    );
  }
}

/// Fila de botones de la piel; el elegido va relleno con el color de acento.
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
    final p = context.pal;
    return Row(
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: ChromeButton(
              onTap: () => onChanged(o.$1),
              color: o.$1 == value ? p.accent : p.surfaceAlt,
              radius: 14,
              selected: o.$1 == value,
              semanticsLabel: o.$2,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minSize: const Size(0, 48),
              child: Text(
                o.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.body(
                  14,
                  weight: FontWeight.w800,
                  color: o.$1 == value ? p.onColor(p.accent) : p.text,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
