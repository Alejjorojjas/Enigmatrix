/// Registro e inicio de sesión (/registro) y la invitación reutilizable a
/// registrarse (ronda F2a). Google, Apple (solo iPhone) y correo con
/// contraseña. Tras registrarse por primera vez se pide el apodo si falta.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';
import '../backend/nickname_service.dart';
import '../backend/validation_providers.dart' show nicknameServiceProvider;
import 'case_list_screen.dart' show prefsProvider;
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';

/// Ruta de la pantalla de registro.
const String kRegistrationRoute = '/registro';

/// Texto en español de un problema de registro.
String authProblemText(AppLocalizations l10n, AuthProblem p) => switch (p) {
  AuthProblem.invalidEmail => l10n.authErrInvalidEmail,
  AuthProblem.wrongCredentials => l10n.authErrWrongCredentials,
  AuthProblem.emailInUse => l10n.authErrEmailInUse,
  AuthProblem.weakPassword => l10n.authErrWeakPassword,
  AuthProblem.userDisabled => l10n.authErrUserDisabled,
  AuthProblem.network => l10n.authErrNetwork,
  AuthProblem.tooManyRequests => l10n.authErrTooManyRequests,
  AuthProblem.notAllowed => l10n.authErrNotAllowed,
  AuthProblem.unavailable => l10n.authErrUnavailable,
  AuthProblem.unknown => l10n.authErrUnknown,
};

/// Abre la pantalla de registro encima de la actual.
void openRegistration(BuildContext context) => context.push(kRegistrationRoute);

/// Invitación a registrarse: la que ve un invitado al pedir un caso que exige
/// cuenta (también sirve para la pestaña del Reto). Devuelve true si el
/// jugador eligió registrarse (y ya se abrió /registro).
Future<bool> showRegistrationInvite(BuildContext context) async {
  final router = GoRouter.of(context);
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.registerInviteTitle, style: ctx.display(20)),
      content: Text(ctx.l10n.registerInviteBody, style: ctx.body(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.registerInviteLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.registerInviteAction),
        ),
      ],
    ),
  );
  if (go != true) return false;
  router.push(kRegistrationRoute);
  return true;
}

/// Cierra la sesión (tras confirmar) y vuelve a invitado. El apodo guardado
/// es de la cuenta que se va: se olvida en este teléfono.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final service = ref.read(authServiceProvider);
  if (service == null) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.settingsSignOutTitle, style: ctx.display(20)),
      content: Text(ctx.l10n.settingsSignOutBody, style: ctx.body(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.sheetCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.settingsSignOut),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await service.signOut();
    final prefs = await ref.read(prefsProvider.future);
    await prefs.remove(kNickKey);
    await prefs.remove(kNickPendingKey);
    ref.invalidate(prefsProvider);
  } on Object {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.settingsSignOutFailed)),
    );
  }
}

enum _Mode { create, signIn }

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Mode _mode = _Mode.create;
  String? _error;
  String? _info;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AuthOutcome> Function(AuthService s) action) async {
    final service = ref.read(authServiceProvider);
    if (service == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final outcome = await action(service);
    if (!mounted) return;
    switch (outcome) {
      case AuthCancelled():
        setState(() => _busy = false);
      case AuthFailed(:final problem):
        setState(() {
          _busy = false;
          _error = authProblemText(context.l10n, problem);
        });
      case AuthSignedIn():
        await _finish(outcome);
    }
  }

  Future<void> _finish(AuthSignedIn outcome) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.of(context);
    final text = [
      if (outcome.replacedGuest)
        l10n.registerReplacedGuest
      else
        l10n.registerDone,
      if (outcome.verificationSent) l10n.registerVerificationSent,
    ].join(' ');
    messenger?.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
    // Cuenta que ya tenía apodo en el servidor: se trae, no se vuelve a pedir.
    await ref.read(nicknameServiceProvider)?.restoreFromServer();
    ref.invalidate(prefsProvider);
    final prefs = await ref.read(prefsProvider.future);
    if (!mounted) return;
    setState(() => _busy = false);
    // Sin apodo (cuenta nueva o teléfono nuevo): se pide justo ahora.
    if (NicknameService.needsNickname(prefs)) {
      router.go('/apodo');
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go('/home');
    }
  }

  String? _checkEmailPassword() {
    final l10n = context.l10n;
    if (!isValidEmail(_email.text)) return l10n.registerErrEmailInvalid;
    if (_mode == _Mode.create && _password.text.length < kPasswordMinLength) {
      return l10n.registerErrPasswordShort;
    }
    if (_password.text.isEmpty) return l10n.authErrWrongCredentials;
    return null;
  }

  Future<void> _submitEmail() async {
    final problem = _checkEmailPassword();
    if (problem != null) {
      setState(() {
        _error = problem;
        _info = null;
      });
      return;
    }
    final email = _email.text;
    final pass = _password.text;
    await _run(
      (s) => _mode == _Mode.create
          ? s.createAccountWithEmail(email, pass)
          : s.signInWithEmail(email, pass),
    );
  }

  Future<void> _forgot() async {
    final service = ref.read(authServiceProvider);
    if (service == null || _busy) return;
    final l10n = context.l10n;
    if (!isValidEmail(_email.text)) {
      setState(() {
        _error = _email.text.trim().isEmpty
            ? l10n.registerResetNeedsEmail
            : l10n.registerErrEmailInvalid;
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final problem = await service.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (problem == null) {
        _info = l10n.registerResetSent;
      } else {
        _error = authProblemText(l10n, problem);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final l10n = context.l10n;
    final service = ref.watch(authServiceProvider);
    final create = _mode == _Mode.create;
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: l10n.uiBack,
                        child: ChromeButton(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                          radius: 14,
                          color: p.surface,
                          semanticsLabel: l10n.uiBack,
                          padding: EdgeInsets.zero,
                          minSize: const Size(SkinUi.minTouch, SkinUi.minTouch),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.registerTitle,
                      style: context.display(30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.registerBody,
                      style: context.note(17, color: p.softText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: l10n.registerGoogle,
                      icon: Icons.account_circle_rounded,
                      onTap: _busy
                          ? null
                          : () => _run((s) => s.signInWithGoogle()),
                    ),
                    if (service?.appleAvailable ?? false) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        label: l10n.registerApple,
                        icon: Icons.apple_rounded,
                        quiet: true,
                        onTap: _busy
                            ? null
                            : () => _run((s) => s.signInWithApple()),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      l10n.registerOr,
                      style: context.note(15, color: p.softText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<_Mode>(
                      segments: [
                        ButtonSegment(
                          value: _Mode.create,
                          label: Text(l10n.registerModeCreate),
                        ),
                        ButtonSegment(
                          value: _Mode.signIn,
                          label: Text(l10n.registerModeSignIn),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _busy
                          ? null
                          : (s) => setState(() {
                              _mode = s.first;
                              _error = null;
                              _info = null;
                            }),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: context.body(18),
                      decoration: InputDecoration(
                        labelText: l10n.registerEmailLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _hidePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        create
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      inputFormatters: [LengthLimitingTextInputFormatter(128)],
                      style: context.body(18),
                      onSubmitted: (_) => _submitEmail(),
                      decoration: InputDecoration(
                        labelText: l10n.registerPasswordLabel,
                        helperText: create ? l10n.registerPasswordHelper : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        key: const Key('registerError'),
                        style: context.body(15, color: p.danger),
                      ),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _info!,
                        key: const Key('registerInfo'),
                        style: context.body(15, color: p.good),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      label: _busy
                          ? l10n.registerBusy
                          : create
                          ? l10n.registerSubmitCreate
                          : l10n.registerSubmitSignIn,
                      color: p.accent,
                      onTap: _busy ? null : _submitEmail,
                    ),
                    if (!create) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _busy ? null : _forgot,
                        child: Text(l10n.registerForgot),
                      ),
                    ],
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
