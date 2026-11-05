/// Un solo tema para toda la app (ronda 4.2, H-59): la piel y el modo que el
/// jugador elige en Configuración mandan en Inicio, lista de casos, perfil y
/// demás pantallas, igual que en la partida. "Sistema" sigue al teléfono.
library;

import 'package:enigmatrix/main.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/content_overrides.dart';

Future<BuildContext> _pumpApp(
  WidgetTester tester, {
  required AppSettings settings,
  Brightness phone = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = phone;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...contentOverrides(const []),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const EnigmatrixApp(),
    ),
  );
  // La pantalla de carga pasa sola al inicio.
  await tester.pump(const Duration(milliseconds: 2200));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(HomeShell), findsOneWidget);
  return tester.element(find.byType(HomeShell));
}

void main() {
  testWidgets('con Configuración en oscuro y piel Papel, el Inicio usa esa '
      'piel en oscuro aunque el teléfono esté en claro', (tester) async {
    final ctx = await _pumpApp(
      tester,
      settings: const AppSettings(themeMode: ThemeMode.dark, skinId: 'papel'),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(ctx.skinTheme.skinId, 'papel');
    expect(ctx.pal.isDark, isTrue);
    // El texto es claro sobre el fondo oscuro.
    expect(ctx.pal.text.computeLuminance(), greaterThan(0.5));
    expect(ctx.pal.bg.computeLuminance(), lessThan(0.1));
    expect(
      Theme.of(ctx).textTheme.bodyMedium!.color!.computeLuminance(),
      greaterThan(0.5),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('en modo Sistema la app sigue el brillo del teléfono', (
    tester,
  ) async {
    final dark = await _pumpApp(
      tester,
      settings: const AppSettings(skinId: 'ilustrada'),
      phone: Brightness.dark,
    );
    expect(Theme.of(dark).brightness, Brightness.dark);
    expect(dark.skinTheme.skinId, 'ilustrada');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('en modo Claro la app es clara aunque el teléfono esté oscuro', (
    tester,
  ) async {
    final ctx = await _pumpApp(
      tester,
      settings: const AppSettings(themeMode: ThemeMode.light, skinId: 'papel'),
      phone: Brightness.dark,
    );
    expect(Theme.of(ctx).brightness, Brightness.light);
    expect(ctx.pal.text.computeLuminance(), lessThan(0.2));
    await tester.pumpWidget(const SizedBox());
  });
}
