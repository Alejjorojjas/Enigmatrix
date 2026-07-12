import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/data/case_repository.dart';
import 'src/ui/case_list_screen.dart';
import 'src/ui/game_screen.dart';

void main() {
  runApp(const ProviderScope(child: EnigmatrixApp()));
}

/// Identidad visual base del Design System
/// (docs/Enigmatrix Design System - Standalone.html) + pase de diseño
/// 2026-06-11: profundidad, gradientes y tarjetas estilo Murdoku.
abstract final class Brand {
  static const background = Color(0xFF1A1816);
  static const backgroundDeep = Color(0xFF121009);
  static const surface = Color(0xFF26221E);
  static const surfaceHigh = Color(0xFF322C26);
  static const gold = Color(0xFFB8860B);
  static const goldBright = Color(0xFFE3B341);
  static const cream = Color(0xFFF0EBE0);
  static const muted = Color(0xFFA09890);
  static const error = Color(0xFFCF5C5C);
  static const success = Color(0xFF5CA86B);

  /// Tarjetas claras estilo "polaroid" para los sospechosos.
  static const cardLight = Color(0xFFF3EDDF);
  static const cardLightShade = Color(0xFFE5DCC8);
  static const inkOnLight = Color(0xFF2B241C);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3B341), Color(0xFFB8860B)],
  );

  /// Fuentes (web): serif elegante para títulos, script para nombres.
  static const displayFont = 'Georgia';
  static const scriptFont = 'Segoe Script';
}

/// Color identificador por dificultad (paleta vintage detective,
/// pase Enx 2026-07-11).
Color difficultyColor(String label) => switch (label) {
      'principiante' => const Color(0xFF7BC950), // verde salvia
      'casual' => const Color(0xFF4FA3D1), // azul empolvado
      'intermedio' => const Color(0xFFE8871E), // calabaza
      'experto' => const Color(0xFFD64550), // ladrillo
      'elite' => const Color(0xFF9B5DE5), // violeta
      _ => Brand.muted,
    };

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const CaseListScreen()),
    GoRoute(
      path: '/play/:id',
      builder: (_, state) => GameScreen(caseId: state.pathParameters['id']!),
    ),
  ],
);

class EnigmatrixApp extends ConsumerWidget {
  const EnigmatrixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Precarga de casos al arrancar.
    ref.watch(casesProvider);
    return MaterialApp.router(
      title: 'Enigmatrix — banco de pruebas',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.8),
            radius: 1.6,
            colors: [Color(0xFF2C2620), Brand.backgroundDeep],
          ),
        ),
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Brand.gold,
          secondary: Brand.goldBright,
          surface: Brand.surface,
          error: Brand.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Brand.cream,
          centerTitle: false,
          elevation: 0,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Brand.cream,
          displayColor: Brand.cream,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Brand.surfaceHigh,
          contentTextStyle: const TextStyle(color: Brand.cream),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Brand.gold.withValues(alpha: .4)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Brand.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Brand.gold.withValues(alpha: .35)),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Brand.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Brand.gold.withValues(alpha: .4)),
          ),
          textStyle: const TextStyle(color: Brand.cream, fontSize: 12),
        ),
      ),
    );
  }
}
