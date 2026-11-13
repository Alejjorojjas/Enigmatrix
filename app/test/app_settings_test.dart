/// Opciones del jugador (ronda 4.1): piel, modo, sonido y vibración se
/// guardan en shared_preferences (cfg:piel, cfg:modo, cfg:sonido,
/// cfg:vibracion), se leen al arrancar y se cambian desde Configuración.
library;

import 'package:enigmatrix/src/game/dev_tools.dart' show showSimulatedProvider;
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/feedback_providers.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart' show resolveBrightness;
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/content_overrides.dart';
import 'support/l10n.dart';

Future<ProviderContainer> _container([AppSettings? initial]) async {
  final c = ProviderContainer(
    overrides: [
      if (initial != null) initialSettingsProvider.overrideWithValue(initial),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('valores de arranque', () {
    test('piel Ilustrada, modo Sistema, sonido y vibración encendidos', () {
      const s = AppSettings.defaults;
      expect(s.skinId, 'ilustrada');
      expect(s.themeMode, ThemeMode.system);
      expect(s.soundOn, isTrue);
      expect(s.hapticsOn, isTrue);
      expect(s.fpsMeter, isFalse);
      expect(s.reduceMotion, isFalse);
    });

    test('sin nada guardado se usan los valores de arranque', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AppSettings.load(), AppSettings.defaults);
    });

    test('el jugador solo ve Ilustrada y Papel', () {
      expect(kPlayerSkins, ['ilustrada', 'papel']);
    });
  });

  group('lo guardado', () {
    test('se lee cada clave', () async {
      SharedPreferences.setMockInitialValues({
        'cfg:piel': 'papel',
        'cfg:modo': 'oscuro',
        'cfg:sonido': false,
        'cfg:vibracion': false,
        'cfg:fps': true,
      });
      final s = await AppSettings.load();
      expect(s.skinId, 'papel');
      expect(s.themeMode, ThemeMode.dark);
      expect(s.soundOn, isFalse);
      expect(s.hapticsOn, isFalse);
      expect(s.fpsMeter, isTrue);
    });

    test('modo claro y modo sistema', () async {
      SharedPreferences.setMockInitialValues({'cfg:modo': 'claro'});
      expect((await AppSettings.load()).themeMode, ThemeMode.light);
      SharedPreferences.setMockInitialValues({'cfg:modo': 'sistema'});
      expect((await AppSettings.load()).themeMode, ThemeMode.system);
    });

    test('un dato dañado o desconocido vuelve al valor de arranque', () async {
      SharedPreferences.setMockInitialValues({
        'cfg:piel': 'no-existe',
        'cfg:modo': 'raro',
        'cfg:sonido': 'sí',
        'cfg:vibracion': 7,
        'cfg:fps': 'x',
      });
      expect(await AppSettings.load(), AppSettings.defaults);
    });

    test('la piel de desarrollo "neutra" no se ofrece pero no rompe', () {
      expect(AppSettings.skinFromText('neutra'), 'neutra');
      expect(AppSettings.skinFromText(null), 'ilustrada');
      expect(AppSettings.skinFromText('Papel'), 'ilustrada'); // exacto
    });

    test('las opciones guardadas llegan al proveedor al arrancar', () async {
      SharedPreferences.setMockInitialValues({
        'cfg:piel': 'papel',
        'cfg:modo': 'claro',
      });
      final loaded = await AppSettings.load();
      final c = await _container(loaded);
      expect(c.read(settingsProvider).skinId, 'papel');
      expect(c.read(settingsProvider).themeMode, ThemeMode.light);
    });
  });

  group('cambiar y guardar', () {
    test('cada cambio queda en shared_preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _container(const AppSettings(fpsMeter: false));
      final n = c.read(settingsProvider.notifier);
      n.setSkin('papel');
      n.setThemeMode(ThemeMode.dark);
      n.setSound(false);
      n.setHaptics(false);
      n.setFpsMeter(true);
      await Future<void>.delayed(Duration.zero);
      final s = c.read(settingsProvider);
      expect(s.skinId, 'papel');
      expect(s.themeMode, ThemeMode.dark);
      expect(s.soundOn, isFalse);
      expect(s.hapticsOn, isFalse);
      expect(s.fpsMeter, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cfg:piel'), 'papel');
      expect(prefs.getString('cfg:modo'), 'oscuro');
      expect(prefs.getBool('cfg:sonido'), isFalse);
      expect(prefs.getBool('cfg:vibracion'), isFalse);
      expect(prefs.getBool('cfg:fps'), isTrue);
    });

    test('lo guardado vuelve igual al reiniciar la app', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _container(const AppSettings(fpsMeter: false));
      final n = c.read(settingsProvider.notifier);
      n.setSkin('papel');
      n.setThemeMode(ThemeMode.light);
      n.setSound(false);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await AppSettings.load();
      expect(reloaded.skinId, 'papel');
      expect(reloaded.themeMode, ThemeMode.light);
      expect(reloaded.soundOn, isFalse);
      expect(reloaded.hapticsOn, isTrue);
    });

    test('una piel que no existe no se guarda', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _container(const AppSettings(fpsMeter: false));
      c.read(settingsProvider.notifier).setSkin('inventada');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(settingsProvider).skinId, 'ilustrada');
      expect(
        (await SharedPreferences.getInstance()).containsKey('cfg:piel'),
        isFalse,
      );
    });

    test('repetir el mismo valor no vuelve a guardar', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _container(const AppSettings(fpsMeter: false));
      c.read(settingsProvider.notifier).setSound(true);
      await Future<void>.delayed(Duration.zero);
      expect(
        (await SharedPreferences.getInstance()).containsKey('cfg:sonido'),
        isFalse,
      );
    });
  });

  group('modo silencio del teléfono y reducir movimiento', () {
    const on = AppSettings();

    test('normal: lo que eligió el jugador', () {
      final e = on.effective(systemReduceMotion: false);
      expect(e.soundOn, isTrue);
      expect(e.hapticsOn, isTrue);
    });

    test('vibrar: sin sonido pero con vibración', () {
      final e = on.effective(
        systemReduceMotion: false,
        ringer: RingerMode.vibrate,
      );
      expect(e.soundOn, isFalse);
      expect(e.hapticsOn, isTrue);
    });

    test('silencio: ni sonido ni vibración', () {
      final e = on.effective(
        systemReduceMotion: false,
        ringer: RingerMode.silent,
      );
      expect(e.soundOn, isFalse);
      expect(e.hapticsOn, isFalse);
    });

    test('un interruptor apagado nunca se enciende por el teléfono', () {
      final e = const AppSettings(
        soundOn: false,
        hapticsOn: false,
      ).effective(systemReduceMotion: false, ringer: RingerMode.normal);
      expect(e.soundOn, isFalse);
      expect(e.hapticsOn, isFalse);
    });

    test('reducir movimiento lo pide el sistema o el jugador', () {
      expect(on.effective(systemReduceMotion: true).reduceMotion, isTrue);
      expect(
        const AppSettings(
          reduceMotion: true,
        ).effective(systemReduceMotion: false).reduceMotion,
        isTrue,
      );
      expect(on.effective(systemReduceMotion: false).reduceMotion, isFalse);
    });

    test('el modo de timbre se lee como silencio, vibrar o normal', () async {
      expect(RingerMode.values, hasLength(3));
      // Fuera de Android (pruebas, web) no hay canal: se asume normal.
      expect(await AndroidRingerProbe().read(), RingerMode.normal);
    });
  });

  group('brillo según el modo elegido', () {
    test('Sistema sigue al teléfono; Claro y Oscuro mandan', () {
      expect(
        resolveBrightness(ThemeMode.system, Brightness.dark),
        Brightness.dark,
      );
      expect(
        resolveBrightness(ThemeMode.system, Brightness.light),
        Brightness.light,
      );
      expect(
        resolveBrightness(ThemeMode.light, Brightness.dark),
        Brightness.light,
      );
      expect(
        resolveBrightness(ThemeMode.dark, Brightness.light),
        Brightness.dark,
      );
    });
  });

  group('Configuración en la app', () {
    Future<ProviderContainer> openConfig(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = ProviderContainer(
        overrides: [
          ...contentOverrides(const []),
          showSimulatedProvider.overrideWithValue(true),
          initialSettingsProvider.overrideWithValue(
            const AppSettings(fpsMeter: false),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            localizationsDelegates: kL10nDelegates,
            supportedLocales: kL10nLocales,
            locale: kL10nLocale,
            home: HomeShell(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Configuración'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return c;
    }

    testWidgets('Sonido y Vibración se encienden y apagan y se guardan', (
      tester,
    ) async {
      final c = await openConfig(tester);
      final sound = find.widgetWithText(SwitchListTile, 'Sonido');
      final haptics = find.widgetWithText(SwitchListTile, 'Vibración');
      expect(tester.widget<SwitchListTile>(sound).value, isTrue);
      expect(tester.widget<SwitchListTile>(haptics).value, isTrue);
      expect(tester.widget<SwitchListTile>(sound).onChanged, isNotNull);

      await tester.tap(sound);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(haptics);
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.read(settingsProvider).soundOn, isFalse);
      expect(c.read(settingsProvider).hapticsOn, isFalse);
      expect(tester.widget<SwitchListTile>(sound).value, isFalse);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('cfg:sonido'), isFalse);
      expect(prefs.getBool('cfg:vibracion'), isFalse);
    });

    testWidgets('Música y Notificaciones siguen como "Próximamente"', (
      tester,
    ) async {
      await openConfig(tester);
      expect(find.text('Próximamente'), findsNWidgets(2));
      for (final label in ['Música', 'Notificaciones']) {
        final tile = find.widgetWithText(SwitchListTile, label);
        expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);
      }
    });

    testWidgets('el selector de piel y de modo cambia y guarda', (
      tester,
    ) async {
      final c = await openConfig(tester);
      expect(find.text('Aspecto del juego'), findsOneWidget);
      Finder pick(String key, String text) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.text(text),
      );
      // Solo las dos pieles del jugador.
      expect(pick('selector-piel', 'Ilustrada'), findsOneWidget);
      expect(pick('selector-piel', 'Papel'), findsOneWidget);
      expect(pick('selector-piel', 'Neutra'), findsNothing);

      await tester.ensureVisible(pick('selector-piel', 'Papel'));
      await tester.tap(pick('selector-piel', 'Papel'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(pick('selector-modo', 'Oscuro'));
      await tester.tap(pick('selector-modo', 'Oscuro'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(settingsProvider).skinId, 'papel');
      expect(c.read(settingsProvider).themeMode, ThemeMode.dark);

      await tester.tap(pick('selector-modo', 'Claro'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(settingsProvider).themeMode, ThemeMode.light);
      await tester.tap(pick('selector-modo', 'Sistema'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(settingsProvider).themeMode, ThemeMode.system);

      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cfg:piel'), 'papel');
      expect(prefs.getString('cfg:modo'), 'sistema');
    });
  });
}
