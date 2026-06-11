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
/// (docs/Enigmatrix Design System - Standalone.html).
abstract final class Brand {
  static const background = Color(0xFF1A1816);
  static const surface = Color(0xFF26221E);
  static const gold = Color(0xFFB8860B);
  static const goldBright = Color(0xFFD9A427);
  static const cream = Color(0xFFF0EBE0);
  static const muted = Color(0xFFA09890);
  static const error = Color(0xFFCF5C5C);
  static const success = Color(0xFF5CA86B);
}

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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Brand.background,
        colorScheme: const ColorScheme.dark(
          primary: Brand.gold,
          secondary: Brand.goldBright,
          surface: Brand.surface,
          error: Brand.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Brand.background,
          foregroundColor: Brand.cream,
          centerTitle: false,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Brand.cream,
          displayColor: Brand.cream,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Brand.surface,
          contentTextStyle: TextStyle(color: Brand.cream),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }
}
