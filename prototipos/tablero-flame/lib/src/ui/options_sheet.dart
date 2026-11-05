/// Hoja de opciones: aspecto (piel y modo, para comparar en vivo), sonido,
/// vibración, reducir movimiento, tope de partículas, medidor de FPS y
/// herramientas de medición.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../game/fps_recorder.dart';
import '../scene/skins.dart';
import '../settings.dart';
import '../strings.dart';
import 'fps_overlay.dart';
import 'prototype_theme.dart';

Future<void> showOptionsSheet(
  BuildContext context, {
  required GameSettings settings,
  required FpsReport? lastReport,
  required String? audioError,
  required VoidCallback onAutofill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListenableBuilder(
        listenable: settings,
        builder: (ctx, _) {
          final p = ctx.pal;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(Strings.options, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              AppearanceSelector(settings: settings),
              const Divider(height: 32),
              _SwitchRow(
                title: Strings.sound,
                value: settings.soundOn,
                onChanged: (v) => settings.soundOn = v,
              ),
              _SwitchRow(
                title: Strings.haptics,
                value: settings.hapticsOn,
                onChanged: (v) => settings.hapticsOn = v,
              ),
              _SwitchRow(
                title: Strings.reduceMotion,
                subtitle: Strings.reduceMotionHint,
                value: settings.reduceMotion,
                onChanged: (v) => settings.reduceMotion = v,
              ),
              const SizedBox(height: 8),
              Text(Strings.particleCap, style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final v in GameSettings.particleCapChoices)
                    ButtonSegment(value: v, label: Text('$v')),
                ],
                selected: {settings.particleCap},
                onSelectionChanged: (s) => settings.particleCap = s.first,
              ),
              const SizedBox(height: 8),
              _SwitchRow(
                title: Strings.fpsMeter,
                subtitle: Strings.fpsMeterHint,
                value: settings.fpsMeter,
                onChanged: (v) => settings.fpsMeter = v,
              ),
              _SwitchRow(
                title: Strings.doubleTap,
                subtitle: Strings.doubleTapHint,
                value: settings.doubleTapConfirm,
                onChanged: (v) => settings.doubleTapConfirm = v,
              ),
              _SwitchRow(
                title: Strings.autoX,
                value: settings.autoX,
                onChanged: (v) => settings.autoX = v,
              ),
              const Divider(height: 32),
              Text(Strings.measureTools, style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(Strings.autofillHint,
                  style: TextStyle(color: p.textDim, fontSize: 13)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onAutofill();
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text(Strings.autofill),
              ),
              const SizedBox(height: 16),
              Text(Strings.lastResult, style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 6),
              if (lastReport == null)
                Text(Strings.noResultYet, style: TextStyle(color: p.textDim))
              else ...[
                Text(lastReport.toText(), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => copyReport(ctx, lastReport),
                  icon: const Icon(Icons.copy),
                  label: const Text(Strings.copyResult),
                ),
              ],
              if (audioError != null) ...[
                const SizedBox(height: 16),
                Text(
                  kIsWeb ? Strings.audioWeb : '${Strings.audioUnavailable}: $audioError',
                  style: TextStyle(color: kIsWeb ? p.textDim : p.danger, fontSize: 13),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

/// Selector de piel (Ilustrada / Papel / Neutra) y de modo (Sistema / Claro /
/// Oscuro). Cambia en vivo: el tablero y la interfaz se redibujan al tocar.
class AppearanceSelector extends StatelessWidget {
  const AppearanceSelector({super.key, required this.settings});

  final GameSettings settings;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Strings.skin, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(Strings.skinHint, style: TextStyle(color: p.textDim, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              key: const ValueKey('selector-piel'),
              showSelectedIcon: false,
              segments: [
                for (final s in SkinRegistry.specs)
                  ButtonSegment(
                    value: s.id,
                    label: Text(s.displayName),
                  ),
              ],
              selected: {settings.skinId},
              onSelectionChanged: (s) => settings.skinId = s.first,
            ),
          ),
          const SizedBox(height: 16),
          Text(Strings.themeMode, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              key: const ValueKey('selector-modo'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text(Strings.modeSystem)),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text(Strings.modeLight)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text(Strings.modeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.themeMode = s.first,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: context.pal.textDim, fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }
}
