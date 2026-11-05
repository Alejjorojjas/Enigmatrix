/// Pantalla de carga: logo de papel que entra con rebote, nombre del juego y
/// transición al inicio. Mientras se muestra, precarga los casos. Toma su
/// aspecto de la piel y el modo activos.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../data/case_repository.dart';
import '../game/game_config.dart';
import 'logo.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    // Precarga del Mundo 1 y del reto diario + tiempo mínimo para que el logo
    // respire. Si algo falla al leer, la pantalla de destino lo muestra.
    await Future.wait([
      ref
          .read(campaignProvider(kMundoMansion).future)
          .catchError((_) => <PuzzleCase>[]),
      ref
          .read(dailyChallengesProvider.future)
          .catchError((_) => <DailyChallenge>[]),
      Future<void>.delayed(
        Duration(milliseconds: ref.read(gameConfigProvider).splashMinMillis),
      ),
    ]);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: ScreenBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .5, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: const PaperLogo(size: 168),
              ),
              const SizedBox(height: 26),
              Text(
                context.l10n.appTitle,
                style: context.display(42, spacing: 1),
              ),
              Text(
                context.l10n.splashTagline,
                style: context.note(20, color: p.softText),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (_, v, __) => AppProgressBar(
                    value: v,
                    height: 12,
                    semanticsLabel: context.l10n.splashLoading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
