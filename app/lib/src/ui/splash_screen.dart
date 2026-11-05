/// Pantalla de carga: logo de papel que entra con rebote, nombre del juego y
/// transición al inicio. Mientras se muestra, precarga los casos. Toma su
/// aspecto de la piel y el modo activos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/case_repository.dart';
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
    // Precarga de casos + tiempo mínimo para que el logo respire.
    final load = ref.read(casesProvider.future);
    await Future.wait([
      load,
      Future<void>.delayed(const Duration(milliseconds: 1700)),
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
              Text('Enigmatrix', style: context.display(42, spacing: 1)),
              Text(
                'Un misterio de papel',
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
                    semanticsLabel: 'Cargando',
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
