/// Hojas inferiores y diálogos del Perfil: Tienda y Premium (DEMO),
/// Configuración (piel, modo, sonido y vibración) y el nombre de detective.
/// Todas toman su aspecto de la piel y el modo activos.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../app_version.dart';
import '../game/app_settings.dart';
import '../game/dev_tools.dart';
import 'appearance_picker.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'dev_texts.dart';
import 'feedback_report.dart';
import 'skin_theme.dart';
import 'tutorial_dialog.dart';
import 'ui_kit.dart';

void openHowToPlay(BuildContext context) => showTutorialDialog(context);

// ---------- TIENDA ----------

Future<void> openShopSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _ShopSheet());

class _ShopSheet extends StatefulWidget {
  const _ShopSheet();

  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> {
  bool _notice = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    // Precios simulados (DEMO): se reemplazan por los de la tienda real.
    final items = [
      (Icons.favorite_rounded, context.l10n.shopLives(10), r'$0.99'),
      (Icons.shield_rounded, context.l10n.shopProtectors(3), r'$0.99'),
      (Icons.shield_rounded, context.l10n.shopProtectors(10), r'$2.99'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.sheetShop, style: context.display(24)),
            const SizedBox(width: 10),
            const DemoBadge(),
          ],
        ),
        const SizedBox(height: 14),
        for (final (i, it) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                IconTile(
                  icon: it.$1,
                  color: i == 0 ? p.danger : p.world(1),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(it.$2, style: context.body(16))),
                const SizedBox(width: 8),
                AppButton(
                  label: it.$3,
                  expand: false,
                  onTap: () => setState(() => _notice = true),
                ),
              ],
            ),
          ),
        if (_notice) NoticeBox(context.l10n.uiDemoNotice),
      ],
    );
  }
}

// ---------- PREMIUM ----------

Future<void> openPremiumSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _PremiumSheet());

class _PremiumSheet extends StatefulWidget {
  const _PremiumSheet();

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  bool _notice = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.sheetPremium, style: context.display(24)),
            const SizedBox(width: 10),
            const DemoBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.sheetPremiumBody,
          style: context.note(16, color: p.softText),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: context.l10n.premiumMonthly(r'$4.99'),
          onTap: () => setState(() => _notice = true),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: context.l10n.premiumYearly(r'$29.99'),
          color: p.danger,
          onTap: () => setState(() => _notice = true),
        ),
        if (_notice) ...[
          const SizedBox(height: 12),
          NoticeBox(context.l10n.uiDemoNotice),
        ],
      ],
    );
  }
}

// ---------- CONFIGURACIÓN ----------

Future<void> openSettingsSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _SettingsSheet());

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final showSim = ref.watch(showSimulatedProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.sheetSettings, style: context.display(24)),
        const SizedBox(height: 6),
        // Sonido y Vibración ya funcionan; Música y Notificaciones siguen
        // "Próximamente" hasta sus etapas.
        SwitchRow(
          icon: Icons.volume_up_rounded,
          label: context.l10n.sheetSound,
          value: settings.soundOn,
          onChanged: notifier.setSound,
        ),
        // Música y Notificaciones no hacen nada aún: solo con simulados.
        if (showSim)
          SwitchRow(
            icon: Icons.music_note_rounded,
            label: context.l10n.sheetMusic,
            value: false,
            onChanged: null,
          ),
        SwitchRow(
          icon: Icons.vibration_rounded,
          label: context.l10n.sheetHaptics,
          value: settings.hapticsOn,
          onChanged: notifier.setHaptics,
        ),
        if (showSim)
          SwitchRow(
            icon: Icons.notifications_rounded,
            label: context.l10n.sheetNotifications,
            value: false,
            onChanged: null,
          ),
        SwitchRow(
          icon: Icons.slow_motion_video_rounded,
          label: context.l10n.sheetReduceMotion,
          value: settings.reduceMotion,
          onChanged: notifier.setReduceMotion,
        ),
        Text(
          context.l10n.sheetReduceMotionHint,
          style: context.note(14, color: p.softText),
        ),
        const Divider(height: 24),
        Text(context.l10n.appearanceTitle, style: context.display(19)),
        const SizedBox(height: 10),
        AppearancePicker(labelStyle: context.body(14, color: p.softText)),
        const Divider(height: 24),
        Row(
          children: [
            Icon(Icons.language_rounded, size: 24, color: p.text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(context.l10n.sheetLanguage, style: context.body(16)),
            ),
            Text(
              context.l10n.sheetSpanish,
              style: context.body(15, color: p.softText),
            ),
          ],
        ),
        // La cuenta es simulada hasta la etapa 5.
        if (showSim) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: Text(context.l10n.sheetAccount, style: context.body(16)),
              ),
              const SizedBox(width: 8),
              const DemoBadge(),
            ],
          ),
          Text(
            context.l10n.sheetAccountBody,
            style: context.note(15, color: p.softText),
          ),
        ],
        // Banco de pruebas y feedback de playtest: solo con ENX_DEV (H-66).
        if (ref.watch(devToolsProvider)) ...[
          const Divider(height: 24),
          const _DevSection(),
        ],
        const SizedBox(height: 10),
        Text(
          context.l10n.settingsVersion(kAppVersion),
          style: context.body(13, weight: FontWeight.w600, color: p.textDim),
        ),
      ],
    );
  }
}

/// Banco de pruebas (desarrollo) y copia del feedback de la prueba de juego.
class _DevSection extends ConsumerStatefulWidget {
  const _DevSection();

  @override
  ConsumerState<_DevSection> createState() => _DevSectionState();
}

class _DevSectionState extends ConsumerState<_DevSection> {
  bool _copied = false;

  Future<void> _copy() async {
    final report = await buildReportFor(ref);
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DevTexts.bankEntryTitle, style: context.display(19)),
        const SizedBox(height: 4),
        Text(
          DevTexts.bankEntryBody,
          style: context.note(15, color: p.softText),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: DevTexts.bankEntryOpen,
          quiet: true,
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            router.go('/banco');
          },
        ),
        const SizedBox(height: 10),
        AppButton(
          label: DevTexts.feedbackCopy,
          quiet: true,
          icon: Icons.copy_all_rounded,
          onTap: _copy,
        ),
        if (_copied) ...[
          const SizedBox(height: 10),
          const NoticeBox(DevTexts.feedbackCopied),
        ],
      ],
    );
  }
}

// ---------- NOMBRE DE DETECTIVE ----------

void editNickname(
  BuildContext context,
  WidgetRef ref,
  SharedPreferences? prefs,
) {
  final ctl = TextEditingController(
    text: prefs?.getString('profile:nick') ?? '',
  );
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.sheetNickTitle, style: ctx.display(20)),
      content: TextField(controller: ctl, maxLength: 16, style: ctx.body(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.sheetCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (ctl.text.trim().isNotEmpty) {
              await prefs?.setString('profile:nick', ctl.text.trim());
              ref.invalidate(prefsProvider);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(ctx.l10n.sheetSave),
        ),
      ],
    ),
  );
}
