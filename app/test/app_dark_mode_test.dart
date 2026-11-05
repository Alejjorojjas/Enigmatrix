/// El modo oscuro de la ronda 4.1 es solo de la partida: Inicio, lista de
/// casos y perfil conservan su estilo de papel (se migran en la ronda 4.2) y
/// no quedan ilegibles aunque el teléfono o la Configuración pidan oscuro.
library;

import 'package:enigmatrix/main.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('con el teléfono y la Configuración en oscuro, el resto de la '
      'app sigue claro y legible', (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          casesProvider.overrideWith((_) async => const []),
          initialSettingsProvider.overrideWithValue(
            const AppSettings(themeMode: ThemeMode.dark, skinId: 'papel'),
          ),
        ],
        child: const EnigmatrixApp(),
      ),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    // La pantalla de carga pasa sola al inicio.
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomeShell), findsOneWidget);
    final ctx = tester.element(find.byType(HomeShell));
    expect(Theme.of(ctx).brightness, Brightness.light);
    // El texto de la interfaz es oscuro sobre fondo claro.
    final text = Theme.of(ctx).textTheme.bodyMedium!.color!;
    expect(text.computeLuminance(), lessThan(0.2));
    expect(
      find.descendant(of: find.byType(HomeShell), matching: find.byType(Text)),
      findsWidgets,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
