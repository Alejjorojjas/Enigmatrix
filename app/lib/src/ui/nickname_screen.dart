/// Apodo del jugador (etapa 5A.3): pantalla que se muestra justo después de
/// registrarse (sin disparador automático todavía: lo conecta la ronda del
/// registro; los invitados no tienen apodo)
/// y diálogo para cambiarlo desde Configuración. Las reglas son las del
/// servidor (3 a 16 caracteres; letras, números, espacio, punto, guion y
/// guion bajo); el servidor tiene la última palabra.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../backend/nickname_service.dart';
import '../backend/validation_providers.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'skin_theme.dart';
import 'ui_kit.dart';

/// Texto del problema de un apodo.
String nicknameProblemText(AppLocalizations l10n, NicknameProblem p) =>
    switch (p) {
      NicknameProblem.tooShort => l10n.nickTooShort,
      NicknameProblem.tooLong => l10n.nickTooLong,
      NicknameProblem.invalidChars => l10n.nickInvalidChars,
    };

/// Campo de apodo con su botón. Al guardar con éxito llama a [onSaved].
class NicknameForm extends ConsumerStatefulWidget {
  const NicknameForm({
    super.key,
    required this.submitLabel,
    required this.onSaved,
    this.initial = '',
  });

  final String submitLabel;
  final String initial;
  final void Function(NicknameSaved saved) onSaved;

  @override
  ConsumerState<NicknameForm> createState() => _NicknameFormState();
}

class _NicknameFormState extends ConsumerState<NicknameForm> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial,
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final service = ref.read(nicknameServiceProvider);
    if (service == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await service.save(_ctl.text);
    if (!mounted) return;
    switch (result) {
      case NicknameSaved():
        ref.invalidate(prefsProvider);
        setState(() => _busy = false);
        widget.onSaved(result);
      case NicknameInvalid(:final problem):
        setState(() {
          _busy = false;
          _error = nicknameProblemText(l10n, problem);
        });
      case NicknameRejected(:final message):
        setState(() {
          _busy = false;
          _error = (message != null && message.trim().isNotEmpty)
              ? message
              : l10n.nickRejected;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctl,
          enabled: !_busy,
          autofocus: true,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(32)],
          style: context.body(18),
          decoration: InputDecoration(
            labelText: context.l10n.nickFieldLabel,
            helperText: context.l10n.nickHelper,
            helperMaxLines: 2,
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: _busy ? context.l10n.nickSaving : widget.submitLabel,
          color: p.accent,
          onTap: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// Se muestra justo después de registrarse (no se abre sola al arrancar).
class NicknameScreen extends ConsumerWidget {
  const NicknameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.nickScreenTitle,
                      style: context.display(30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.nickScreenBody,
                      style: context.note(17, color: p.softText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    NicknameForm(
                      submitLabel: context.l10n.nickContinue,
                      onSaved: (_) => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de Configuración / Perfil para cambiar el apodo.
Future<void> showNicknameDialog(BuildContext context, WidgetRef ref) async {
  final prefs = await ref.read(prefsProvider.future);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final offlineNote = context.l10n.nickOfflineNote;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.settingsChangeNick, style: ctx.display(20)),
      content: SingleChildScrollView(
        child: NicknameForm(
          initial: prefs.getString(kNickKey) ?? '',
          submitLabel: ctx.l10n.nickSaveChange,
          onSaved: (saved) {
            Navigator.pop(ctx);
            if (!saved.synced) {
              messenger?.showSnackBar(SnackBar(content: Text(offlineNote)));
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.sheetCancel),
        ),
      ],
    ),
  );
}

/// Confirma y borra la cuenta y los datos. Tras borrar, vuelve a pedir el
/// apodo (como un primer arranque).
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final service = ref.read(nicknameServiceProvider);
  if (service == null) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.of(context);
  final navigator = Navigator.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.deleteAccountTitle, style: ctx.display(20)),
      content: Text(ctx.l10n.deleteAccountBody, style: ctx.body(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.sheetCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.deleteAccountConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await service.deleteAccount();
  } on Object {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.deleteAccountFailed)));
    return;
  }
  ref.invalidate(prefsProvider);
  messenger?.showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
  // Cierra la hoja de Configuración y vuelve a pedir el apodo.
  if (navigator.mounted) navigator.popUntil((r) => r.isFirst);
  router.go('/apodo');
}
