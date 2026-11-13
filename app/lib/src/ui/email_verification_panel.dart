/// Aviso de verificación de correo (ronda de QA tras F2): "Te enviamos un
/// correo de verificación" con "Ya lo verifiqué" y "Reenviar correo". Lo usan
/// la pantalla de registro (justo tras crear la cuenta) y la pestaña Reto
/// (en lugar del reto mientras el correo siga sin verificar).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_providers.dart';
import 'registration_screen.dart' show authProblemText;
import 'skin_theme.dart';
import 'ui_kit.dart';

class EmailVerificationPanel extends ConsumerStatefulWidget {
  const EmailVerificationPanel({
    super.key,
    this.title,
    this.onVerified,
    this.onLater,
  });

  /// Título; por defecto "Te enviamos un correo de verificación".
  final String? title;

  /// Se llama cuando "Ya lo verifiqué" encuentra el correo verificado.
  final VoidCallback? onVerified;

  /// Si no es null se ofrece "Más tarde" (seguir sin verificar).
  final VoidCallback? onLater;

  @override
  ConsumerState<EmailVerificationPanel> createState() =>
      _EmailVerificationPanelState();
}

class _EmailVerificationPanelState
    extends ConsumerState<EmailVerificationPanel> {
  bool _busy = false;
  String? _message;
  bool _ok = false;

  Future<void> _check() async {
    final service = ref.read(authServiceProvider);
    if (service == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    final info = await service.refreshVerification();
    if (!mounted) return;
    final verified = info.emailVerified;
    setState(() {
      _busy = false;
      _ok = verified;
      _message = verified ? l10n.emailVerifyVerified : l10n.emailVerifyNotYet;
    });
    if (verified) {
      ref.invalidate(authInfoProvider);
      widget.onVerified?.call();
    }
  }

  Future<void> _resend() async {
    final service = ref.read(authServiceProvider);
    if (service == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    final problem = await service.resendVerification();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = problem == null;
      _message = problem == null
          ? l10n.emailVerifyResent
          : authProblemText(l10n, problem);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final l10n = context.l10n;
    final email = ref.watch(accountEmailProvider) ?? '';
    return AppCard(
      key: const ValueKey('verificar-correo'),
      accent: p.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? l10n.emailVerifyTitle,
            style: context.display(20),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.emailVerifyBody(email),
            style: context.body(15, color: p.softText),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(
              _message!,
              key: const Key('verificarMensaje'),
              style: context.body(15, color: _ok ? p.good : p.danger),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: l10n.emailVerifyDone,
            color: p.accent,
            onTap: _busy ? null : _check,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.emailVerifyResend,
            quiet: true,
            onTap: _busy ? null : _resend,
          ),
          if (widget.onLater != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : widget.onLater,
              child: Text(l10n.emailVerifyLater),
            ),
          ],
        ],
      ),
    );
  }
}
