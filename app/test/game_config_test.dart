/// Ronda 4.3b: valores de juego en configuración externa (H-65) y
/// herramientas de desarrollo detrás de ENX_DEV (H-66).
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/main.dart' show buildAppRouter;
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/dev_tools.dart';
import 'package:enigmatrix/src/game/game_config.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:enigmatrix/src/ui/victory_screen.dart';
import 'package:enigmatrix/src/ui/v1_scope.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/game_ui.dart' show loadBankCase;
import 'support/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameConfig: valores por defecto', () {
    test('son los que tenía el código antes de moverlos', () {
      const c = GameConfig();
      expect(c.undoLimit, 50);
      expect(c.periodicSaveSeconds, 15);
      expect(c.wrongSolveLockSeconds, 3);
      expect(c.splashMinMillis, 1700);
      expect(c.challengeStartDate, '2026-11-01');
      expect(c.challengeStart, DateTime(2026, 11, 1));
      expect(c.challengeDays, 30);
      expect(c.maxLives, 5);
      expect(c.v1Difficulties, ['principiante', 'casual', 'intermedio']);
      expect(
        [for (final w in c.worlds) (w.id, w.available)],
        [
          ('mansion', true),
          ('hotel', false),
          ('museo', false),
          ('tren', false),
          ('hospital', false),
        ],
      );
    });

    test('el provider entrega los valores por defecto sin sobreescribir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(gameConfigProvider), const GameConfig());
    });
  });

  group('GameConfig: lectura tolerante', () {
    test('JSON parcial: lo que falta toma su valor por defecto', () {
      final c = GameConfig.fromJsonString(
        '{"undoLimit": 7, "maxLives": 9, "wrongSolveLockSeconds": 0}',
      );
      expect(c.undoLimit, 7);
      expect(c.maxLives, 9);
      expect(c.wrongSolveLockSeconds, 0);
      expect(c.periodicSaveSeconds, 15);
      expect(c.splashMinMillis, 1700);
      expect(c.challengeDays, 30);
      expect(c.v1Difficulties, const GameConfig().v1Difficulties);
      expect(c.worlds, const GameConfig().worlds);
    });

    test('tipo o rango erróneo en una clave: vuelve a su valor por '
        'defecto', () {
      final c = GameConfig.fromJson({
        'undoLimit': 'cincuenta',
        'periodicSaveSeconds': 0,
        'wrongSolveLockSeconds': -1,
        'splashMinMillis': 2.5,
        'challengeStartDate': '2026-02-31',
        'challengeDays': null,
        'maxLives': true,
        'v1Difficulties': ['casual', 3],
        'worlds': 'mansion',
      });
      expect(c, const GameConfig());
    });

    test('un entero escrito como 20.0 se acepta', () {
      expect(
        GameConfig.fromJsonString(
          '{"periodicSaveSeconds": 20.0}',
        ).periodicSaveSeconds,
        20,
      );
    });

    test('lista de dificultades y mundos propios', () {
      final c = GameConfig.fromJson({
        'v1Difficulties': ['principiante'],
        'worlds': [
          {'id': 'mansion', 'available': true},
          {'id': 'hotel', 'available': true},
          {'id': 'sin-bandera'},
          'basura',
        ],
      });
      expect(c.v1Difficulties, ['principiante']);
      expect(c.isV1Difficulty('casual'), isFalse);
      expect(
        [for (final w in c.worlds) (w.id, w.available)],
        [('mansion', true), ('hotel', true)],
      );
      // Una lista vacía o sin entradas válidas no deja la app sin mundos.
      expect(
        GameConfig.fromJson({'v1Difficulties': [], 'worlds': []}),
        const GameConfig(),
      );
    });

    test('JSON roto o que no es un mapa: todos los valores por defecto', () {
      expect(GameConfig.fromJsonString('{"undoLimit": 7'), const GameConfig());
      expect(GameConfig.fromJsonString(''), const GameConfig());
      expect(GameConfig.fromJsonString('[1, 2]'), const GameConfig());
      expect(GameConfig.fromJsonString('null'), const GameConfig());
    });

    test('el asset empaquetado coincide con los valores por defecto', () {
      final raw = File('assets/config/game_config.json').readAsStringSync();
      expect(jsonDecode(raw), isA<Map>());
      expect(GameConfig.fromJsonString(raw), const GameConfig());
    });

    test('GameConfig.load lee el asset del paquete', () async {
      expect(await GameConfig.load(), const GameConfig());
    });
  });

  group('día del reto con la configuración', () {
    test('con la configuración por defecto sigue igual', () {
      expect(challengeDayFor(DateTime(2026, 11, 1)), 1);
      expect(challengeDayFor(DateTime(2026, 11, 30)), 30);
      expect(challengeDayFor(DateTime(2026, 12, 1)), 1);
      expect(challengeDayFor(DateTime(2026, 10, 31)), 30);
    });

    test('otra fecha de inicio y otro número de días', () {
      const cfg = GameConfig(
        challengeStartDate: '2027-01-10',
        challengeDays: 7,
      );
      expect(challengeDayFor(DateTime(2027, 1, 10), config: cfg), 1);
      expect(challengeDayFor(DateTime(2027, 1, 16), config: cfg), 7);
      expect(challengeDayFor(DateTime(2027, 1, 17), config: cfg), 1);
      expect(challengeDayFor(DateTime(2027, 1, 9), config: cfg), 7);
    });

    test('todaysChallenge usa la configuración', () {
      final retos = [
        for (var d = 1; d <= 7; d++)
          DailyChallenge(day: d, puzzle: loadBankCase('reto-00$d')),
      ];
      const cfg = GameConfig(
        challengeStartDate: '2027-01-10',
        challengeDays: 7,
      );
      expect(
        todaysChallenge(retos, DateTime(2027, 1, 12), config: cfg)?.day,
        3,
      );
    });
  });

  group('alcance de la V1 con la configuración', () {
    test('worldsFor respeta orden y disponibilidad de la configuración', () {
      final defaults = worldsFor(const GameConfig(), l10nEs);
      expect(defaults.map((w) => w.name), [
        'La Mansión',
        'El Hotel',
        'El Museo',
        'El Tren',
        'El Hospital',
      ]);
      expect(defaults.where((w) => w.available).length, 1);

      final custom = worldsFor(
        const GameConfig(
          worlds: [
            WorldConfig('hotel', available: true),
            WorldConfig('inventado', available: false),
          ],
        ),
        l10nEs,
      );
      expect(custom.map((w) => w.id), ['hotel', 'inventado']);
      expect(custom.first.name, 'El Hotel');
      expect(custom.first.available, isTrue);
      expect(custom.last.name, 'inventado');
    });

    test('playableCases usa las dificultades de la configuración', () {
      final all = [
        loadBankCase('caso-principiante-s1'),
        loadBankCase('caso-casual-s1'),
        loadBankCase('caso-intermedio-s1'),
      ];
      expect(playableCases(all).length, 3);
      const solo = GameConfig(v1Difficulties: ['casual']);
      expect(playableCases(all, config: solo).map((c) => c.difficulty), [
        'casual',
      ]);
    });
  });

  group('GameController usa los valores de la configuración', () {
    late PuzzleCase pc;
    setUpAll(() => pc = loadBankCase('caso-principiante-s1'));

    Future<GameController> open(GameConfig cfg) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          gameTickerEnabledProvider.overrideWithValue(false),
          gameConfigProvider.overrideWithValue(cfg),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider(pc), (_, __) {});
      final c = container.read(gameControllerProvider(pc).notifier);
      await c.ready;
      return c;
    }

    List<int> freeCells() => [
      for (var i = 0; i < pc.map.size * pc.map.size; i++)
        if (pc.map.isOccupiable(i)) i,
    ];

    /// Cuántas veces se puede deshacer tras [placed] acciones.
    int undoCount(GameController c, int placed) {
      final cells = freeCells();
      expect(cells.length, greaterThanOrEqualTo(placed));
      final id = pc.characters.first.id;
      for (var i = 0; i < placed; i++) {
        c.placeSuspect(cells[i], charId: id, confirm: false);
      }
      var n = 0;
      while (c.state.canUndo && n < 1000) {
        c.undo();
        n++;
      }
      return n;
    }

    test('un límite de deshacer de 3 solo deja deshacer 3 acciones', () async {
      expect(undoCount(await open(const GameConfig(undoLimit: 3)), 5), 3);
    });

    test('un límite de deshacer de 5 deja deshacer 5 acciones', () async {
      expect(undoCount(await open(const GameConfig(undoLimit: 5)), 6), 5);
    });

    test('el límite de deshacer por defecto es 50 (doc 08)', () {
      expect(const GameConfig().undoLimit, 50);
    });

    test('el bloqueo tras Resolver fallido dura lo que dice la '
        'configuración', () async {
      final entries = pc.solution.positions.entries.toList();
      Future<GameController> wrongSolve(GameConfig cfg) async {
        final c = await open(cfg);
        c.toggleAutoX();
        c.placeSuspect(entries[1].value, charId: entries[0].key, confirm: true);
        c.placeSuspect(entries[0].value, charId: entries[1].key, confirm: true);
        for (final e in entries.skip(2)) {
          c.placeSuspect(e.value, charId: e.key, confirm: true);
        }
        expect(c.solve(), ActionFeedback.wrongSolution);
        expect(c.state.locked, isTrue);
        return c;
      }

      // Bloqueo de 0 s: se libera en cuanto corre el temporizador.
      final libre = await wrongSolve(
        const GameConfig(wrongSolveLockSeconds: 0),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(libre.state.locked, isFalse);

      // Bloqueo por defecto (3 s): sigue bloqueado pasado un instante.
      final bloqueada = await wrongSolve(const GameConfig());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloqueada.state.locked, isTrue);
    });

    test('el guardado periódico del reloj usa la configuración', () async {
      final id = pc.characters.first.id;
      final cell = freeCells().first;

      Future<void> flush() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      Future<int> savedElapsedAfterTwoTicks(GameConfig cfg) async {
        final c = await open(cfg);
        c.placeSuspect(cell, charId: id, confirm: false);
        await flush();
        c.tick();
        c.tick();
        await flush();
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(SavedGame.keyFor(pc.caseId))!;
        return SavedGame.decode(raw)!.elapsed;
      }

      expect(
        await savedElapsedAfterTwoTicks(
          const GameConfig(periodicSaveSeconds: 2),
        ),
        2,
      );
      expect(await savedElapsedAfterTwoTicks(const GameConfig()), 0);
    });
  });

  group('herramientas de desarrollo (ENX_DEV)', () {
    test('sin la bandera de compilación quedan apagadas', () {
      expect(kEnxDev, isFalse);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(devToolsProvider), isFalse);
    });

    Future<GoRouter> pumpRouter(WidgetTester tester, bool dev) async {
      SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = buildAppRouter(devTools: () => dev);
      addTearDown(router.dispose);
      final world = [
        for (var i = 1; i <= 10; i++)
          loadBankCase('mansion-${i.toString().padLeft(2, '0')}'),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...contentOverrides(world),
            devToolsProvider.overrideWithValue(dev),
          ],
          child: MaterialApp.router(
            localizationsDelegates: kL10nDelegates,
            supportedLocales: kL10nLocales,
            locale: kL10nLocale,
            routerConfig: router,
            theme: SkinUi.theme('ilustrada', Brightness.light),
          ),
        ),
      );
      // La carga del inicio espera su tiempo mínimo y pasa a /home.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 300));
      router.go('/banco');
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return router;
    }

    testWidgets('sin la bandera /banco redirige a /home', (tester) async {
      final router = await pumpRouter(tester, false);
      expect(router.state.uri.path, '/home');
      expect(find.text('Banco de pruebas'), findsNothing);
    });

    testWidgets('con la bandera /banco abre el banco de pruebas', (
      tester,
    ) async {
      final router = await pumpRouter(tester, true);
      expect(router.state.uri.path, '/banco');
      expect(find.text('Banco de pruebas'), findsOneWidget);
    });

    for (final dev in [false, true]) {
      testWidgets(
        'la pantalla de victoria ${dev ? 'muestra' : 'oculta'} el cuadro de '
        'feedback de playtest',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final pc = loadBankCase('caso-principiante-s1');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                gameTickerEnabledProvider.overrideWithValue(false),
                devToolsProvider.overrideWithValue(dev),
              ],
              child: MaterialApp(
                localizationsDelegates: kL10nDelegates,
                supportedLocales: kL10nLocales,
                locale: kL10nLocale,
                theme: SkinUi.theme('ilustrada', Brightness.light),
                home: Consumer(
                  builder: (ctx, ref, _) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => showVictoryScreen(ctx, ref, pc),
                        child: const Text('ABRIR'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('ABRIR'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 900));
          expect(find.text('CASO CERRADO'), findsOneWidget);
          expect(
            find.text('FEEDBACK DE PLAYTEST'),
            dev ? findsOneWidget : findsNothing,
          );
        },
      );
    }
  });
}
