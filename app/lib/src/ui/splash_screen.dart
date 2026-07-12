/// Pantalla de carga (2026-07-12): logo de papel que entra con rebote,
/// nombre del juego y transición al inicio. Mientras se muestra, precarga
/// los casos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/case_repository.dart';
import 'enx_style.dart';
import 'logo.dart';

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
    if (mounted) context.go('/casos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9DCBE),
      body: Center(
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
            Text('Enigmatrix',
                style: Enx.display(40, color: Enx.goldInk, spacing: 1)),
            Text('Un misterio de papel',
                style: Enx.hand(20, color: Enx.inkMuted)),
            const SizedBox(height: 34),
            SizedBox(
              width: 120,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFD9CBA8),
                    color: Enx.crimson,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
