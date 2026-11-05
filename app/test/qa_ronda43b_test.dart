/// QA independiente de la ronda 4.3b: huecos que los tests de la ronda no
/// cubren (carga con asset ausente o ilegible, y variantes de la ruta /banco).
library;

import 'dart:convert';

import 'package:enigmatrix/main.dart' show buildAppRouter;
import 'package:enigmatrix/src/game/game_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/game_ui.dart' show loadBankCase;
import 'support/l10n.dart';

/// Bundle de prueba: entrega un texto fijo o falla como si el asset faltara.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.text);
  final String? text;

  @override
  Future<ByteData> load(String key) async {
    if (text == null) throw FlutterError('Unable to load asset: $key');
    final bytes = Uint8List.fromList(utf8.encode(text!));
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameConfig.load: nunca cuelga el arranque', () {
    Future<GameConfig> loadFrom(String? text) =>
        GameConfig.load(bundle: _FakeBundle(text));

    test('asset ausente: valores por defecto', () async {
      expect(await loadFrom(null), const GameConfig());
    });

    test('asset con basura: valores por defecto', () async {
      expect(await loadFrom('{{{ no es json'), const GameConfig());
    });

    test('asset vacío: valores por defecto', () async {
      expect(await loadFrom(''), const GameConfig());
    });

    test('asset válido con un valor propio se respeta', () async {
      final c = await loadFrom('{"undoLimit": 9, "maxLives": "cinco"}');
      expect(c.undoLimit, 9);
      expect(c.maxLives, 5);
    });
  });

  group('/banco sin ENX_DEV', () {
    for (final path in ['/banco', '/banco/', '/banco?x=1']) {
      testWidgets('$path no deja abrir el banco', (tester) async {
        final router = buildAppRouter(devTools: () => false);
        addTearDown(router.dispose);
        SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final world = [
          for (var i = 1; i <= 10; i++)
            loadBankCase('mansion-${i.toString().padLeft(2, '0')}'),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: contentOverrides(world),
            child: MaterialApp.router(
              localizationsDelegates: kL10nDelegates,
              supportedLocales: kL10nLocales,
              locale: kL10nLocale,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pump(const Duration(milliseconds: 300));
        router.go(path);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(router.state.uri.path, isNot(startsWith('/banco')));
      });
    }
  });
}
