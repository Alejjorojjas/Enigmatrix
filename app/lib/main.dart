import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/data/case_repository.dart';
import 'src/ui/case_list_screen.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: EnigmatrixApp()));
}

/// Identidad visual PAPER CRAFT (elegida por el usuario 2026-07-12 entre 6
/// mockups — ver docs/mockups/estilos/05-paper-craft.html): todo el juego es
/// una maqueta de papel y cartón. Fondo kraft claro, tinta oscura, sombras
/// duras de capas de papel, acentos de chincheta carmesí.
/// Los nombres de los tokens se conservan por compatibilidad; el significado
/// es semántico (cream = color de TEXTO principal, hoy tinta).
abstract final class Brand {
  static const background = Color(0xFFE9DCBE); // kraft claro
  static const backgroundDeep = Color(0xFFDCCBA2); // kraft sombreado
  static const surface = Color(0xFFF7F0DC); // papel crema
  static const surfaceHigh = Color(0xFFFFFBEA); // papel blanco cálido
  static const gold = Color(0xFFB3821F); // dorado tinta (legible en claro)
  static const goldBright = Color(0xFF8A5C2E); // marrón cálido de titular
  static const cream = Color(0xFF3D2F1C); // TEXTO principal (tinta)
  static const muted = Color(0xFF8A7A5C); // texto secundario
  static const error = Color(0xFFB3452E); // rojo chincheta
  static const success = Color(0xFF4A7A34); // verde papel

  /// Tarjetas claras estilo "polaroid" para los sospechosos.
  static const cardLight = Color(0xFFFFFBEA);
  static const cardLightShade = Color(0xFFE8D9B4);
  static const inkOnLight = Color(0xFF3D2F1C);

  /// Sombra dura de papel recortado.
  static const paperShadow = Color(0x59473418);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9A030), Color(0xFFB3821F)],
  );

  /// Fuentes: Baloo 2 para títulos y Patrick Hand para lo manuscrito se
  /// obtienen vía google_fonts (Enx.display / Enx.hand). Estos fallbacks
  /// quedan para los pocos usos por fontFamily directa.
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
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/casos', builder: (_, __) => const CaseListScreen()),
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
            center: Alignment(0, -0.9),
            radius: 1.7,
            colors: [Color(0xFFF2E7C9), Brand.backgroundDeep],
          ),
        ),
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.light(
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
        textTheme: Typography.blackMountainView.apply(
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
