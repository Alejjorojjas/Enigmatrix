/// Hojas inferiores y diálogos del Perfil: Tienda y Premium (DEMO),
/// Configuración (piel, modo, sonido y vibración) y el nombre de detective.
/// Todas toman su aspecto de la piel y el modo activos.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import '../game/app_settings.dart';
import 'appearance_picker.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'feedback_report.dart';
import 'skin_theme.dart';
import 'tutorial_dialog.dart';
import 'ui_kit.dart';

/// Textos de las hojas (centralizados para traducir en la ronda 4.3).
abstract final class SheetTexts {
  static const shop = 'Tienda';
  static const premium = 'Premium';
  static const premiumBody =
      'Sin anuncios · vidas ilimitadas · sin ventajas de ranking';
  static const settings = 'Configuración';
  static const sound = 'Sonido';
  static const music = 'Música';
  static const haptics = 'Vibración';
  static const reduceMotion = 'Reducir movimiento';
  static const reduceMotionHint =
      'Menos rebotes, sacudidas y partículas en el tablero.';
  static const devTitle = 'Banco de pruebas (desarrollo)';
  static const devBody =
      'Los 20 casos de prueba, para revisar el motor. No son parte del juego.';
  static const devOpen = 'Abrir banco de pruebas';
  static const notifications = 'Notificaciones';
  static const language = 'Idioma';
  static const spanish = 'Español';
  static const account = 'Cuenta y compras';
  static const accountBody =
      'Restaurar compras, cerrar sesión y eliminar cuenta se activan con el '
      'modo online.';
  static const nickTitle = 'Tu nombre de detective';
  static const cancel = 'Cancelar';
  static const save = 'Guardar';
}

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
    const items = [
      (Icons.favorite_rounded, '10 vidas', r'$0.99'),
      (Icons.shield_rounded, '3 protectores de racha', r'$0.99'),
      (Icons.shield_rounded, '10 protectores de racha', r'$2.99'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(SheetTexts.shop, style: context.display(24)),
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
        if (_notice) const NoticeBox(UiTexts.demoNotice),
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
            Text(SheetTexts.premium, style: context.display(24)),
            const SizedBox(width: 10),
            const DemoBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          SheetTexts.premiumBody,
          style: context.note(16, color: p.softText),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: r'Mensual · $4.99',
          onTap: () => setState(() => _notice = true),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: r'Anual · $29.99 (ahorra 50%)',
          color: p.danger,
          onTap: () => setState(() => _notice = true),
        ),
        if (_notice) ...[
          const SizedBox(height: 12),
          const NoticeBox(UiTexts.demoNotice),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SheetTexts.settings, style: context.display(24)),
        const SizedBox(height: 6),
        // Sonido y Vibración ya funcionan; Música y Notificaciones siguen
        // "Próximamente" hasta sus etapas.
        SwitchRow(
          icon: Icons.volume_up_rounded,
          label: SheetTexts.sound,
          value: settings.soundOn,
          onChanged: notifier.setSound,
        ),
        const SwitchRow(
          icon: Icons.music_note_rounded,
          label: SheetTexts.music,
          value: false,
          onChanged: null,
        ),
        SwitchRow(
          icon: Icons.vibration_rounded,
          label: SheetTexts.haptics,
          value: settings.hapticsOn,
          onChanged: notifier.setHaptics,
        ),
        const SwitchRow(
          icon: Icons.notifications_rounded,
          label: SheetTexts.notifications,
          value: false,
          onChanged: null,
        ),
        SwitchRow(
          icon: Icons.slow_motion_video_rounded,
          label: SheetTexts.reduceMotion,
          value: settings.reduceMotion,
          onChanged: notifier.setReduceMotion,
        ),
        Text(
          SheetTexts.reduceMotionHint,
          style: context.note(14, color: p.softText),
        ),
        const Divider(height: 24),
        Text(AppearanceTexts.title, style: context.display(19)),
        const SizedBox(height: 10),
        AppearancePicker(labelStyle: context.body(14, color: p.softText)),
        const Divider(height: 24),
        Row(
          children: [
            Icon(Icons.language_rounded, size: 24, color: p.text),
            const SizedBox(width: 12),
            Expanded(child: Text(SheetTexts.language, style: context.body(16))),
            Text(
              SheetTexts.spanish,
              style: context.body(15, color: p.softText),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Flexible(child: Text(SheetTexts.account, style: context.body(16))),
            const SizedBox(width: 8),
            const DemoBadge(),
          ],
        ),
        Text(
          SheetTexts.accountBody,
          style: context.note(15, color: p.softText),
        ),
        const Divider(height: 24),
        const _DevSection(),
        const SizedBox(height: 10),
        Text(
          'Enigmatrix v$kAppVersion',
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
        Text(SheetTexts.devTitle, style: context.display(19)),
        const SizedBox(height: 4),
        Text(SheetTexts.devBody, style: context.note(15, color: p.softText)),
        const SizedBox(height: 12),
        AppButton(
          label: SheetTexts.devOpen,
          quiet: true,
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            router.go('/banco');
          },
        ),
        const SizedBox(height: 10),
        AppButton(
          label: FeedbackTexts.copy,
          quiet: true,
          icon: Icons.copy_all_rounded,
          onTap: _copy,
        ),
        if (_copied) ...[
          const SizedBox(height: 10),
          const NoticeBox(FeedbackTexts.copied),
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
      title: Text(SheetTexts.nickTitle, style: ctx.display(20)),
      content: TextField(controller: ctl, maxLength: 16, style: ctx.body(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(SheetTexts.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (ctl.text.trim().isNotEmpty) {
              await prefs?.setString('profile:nick', ctl.text.trim());
              ref.invalidate(prefsProvider);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text(SheetTexts.save),
        ),
      ],
    ),
  );
}
