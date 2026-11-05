/// Ronda 4.3a: el Mundo 1 y el reto en las pantallas. Inicio, Mundos y la
/// lista de casos usan los 10 casos de "La Mansión" en su orden; el Reto juega
/// el caso del día (día = ((días desde el 01-11-2026) mod 30) + 1); el banco de
/// pruebas y el feedback de playtest viven en Configuración.
library;

import 'dart:convert';

import 'package:enigmatrix/src/app_version.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/game/dev_tools.dart';
import 'package:enigmatrix/src/ui/bank_screen.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/feedback_report.dart';
import 'package:enigmatrix/src/ui/game_chrome.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:enigmatrix/src/ui/ui_kit.dart';
import 'package:enigmatrix/src/ui/v1_scope.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/content_overrides.dart';
import 'support/game_ui.dart' show loadBankCase;

late List<PuzzleCase> _world;
late List<DailyChallenge> _retos;
late List<PuzzleCase> _bank;

String _two(int n) => n.toString().padLeft(2, '0');

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required Widget home,
  Map<String, Object> prefs = const {},
  String skin = 'ilustrada',
  bool devTools = false,
}) async {
  SharedPreferences.setMockInitialValues({'tutorial:v2:done': true, ...prefs});
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: '/home', builder: (_, _) => const Text('INICIO')),
      GoRoute(path: '/casos', builder: (_, _) => const CaseListScreen()),
      GoRoute(path: '/banco', builder: (_, _) => const BankScreen()),
      GoRoute(path: '/tutorial', builder: (_, _) => const Text('TUTORIAL')),
      GoRoute(
        path: '/play/:id',
        builder: (_, s) => Text('PARTIDA ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // Clave nueva: cada montaje parte de proveedores limpios.
      key: UniqueKey(),
      overrides: [
        ...contentOverrides(_world, challenges: _retos, bank: _bank),
        devToolsProvider.overrideWithValue(devTools),
        initialSettingsProvider.overrideWithValue(AppSettings(skinId: skin)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: SkinUi.theme(skin, Brightness.light),
        darkTheme: SkinUi.theme(skin, Brightness.dark),
      ),
    ),
  );
  await _settle(tester);
  return router;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChromeButton, label));
  await _settle(tester);
}

Future<void> _tapScrolled(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
  await _settle(tester);
}

String _done() => jsonEncode({'time': 95, 'errors': 1, 'date': '2026-11-05'});

String _retoId(int day) => 'reto-${day.toString().padLeft(3, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _world = [for (var i = 1; i <= 10; i++) loadBankCase('mansion-${_two(i)}')];
    _retos = loadAllChallenges();
    _bank = [
      for (final n in [
        'caso-principiante-s1',
        'caso-principiante-s2',
        'caso-casual-s1',
        'caso-intermedio-s1',
      ])
        loadBankCase(n),
    ];
  });

  group('día del reto', () {
    test('el 01-11-2026 es el día 1 y avanza un día por fecha', () {
      expect(challengeDayFor(DateTime(2026, 11, 1)), 1);
      expect(challengeDayFor(DateTime(2026, 11, 2)), 2);
      expect(challengeDayFor(DateTime(2026, 11, 5)), 5);
      expect(challengeDayFor(DateTime(2026, 11, 30)), 30);
    });

    test('después del día 30 vuelve al 1 (mod 30)', () {
      expect(challengeDayFor(DateTime(2026, 12, 1)), 1);
      expect(challengeDayFor(DateTime(2026, 12, 2)), 2);
      expect(challengeDayFor(DateTime(2026, 12, 31)), 1);
    });

    test('cuenta días de calendario: la hora no mueve el día', () {
      expect(challengeDayFor(DateTime(2026, 11, 5, 0, 0, 1)), 5);
      expect(challengeDayFor(DateTime(2026, 11, 5, 23, 59, 59)), 5);
      // A través de un cambio de hora (marzo) sigue contando fechas.
      final days = DateTime.utc(
        2027,
        3,
        29,
      ).difference(DateTime.utc(2026, 11, 1)).inDays;
      expect(challengeDayFor(DateTime(2027, 3, 29)), days % 30 + 1);
    });

    test('antes del 01-11-2026 también da un día entre 1 y 30', () {
      expect(challengeDayFor(DateTime(2026, 10, 31)), 30);
      for (var d = 0; d < 90; d++) {
        final date = DateTime(2026, 8, 1).add(Duration(days: d));
        expect(challengeDayFor(date), inInclusiveRange(1, 30));
      }
    });

    test('todaysChallenge devuelve el reto de ese día', () {
      final c = todaysChallenge(_retos, DateTime(2026, 11, 8));
      expect(c?.day, 8);
      expect(c?.puzzle.caseId, 'reto-008');
      expect(todaysChallenge(const [], DateTime(2026, 11, 8)), isNull);
    });
  });

  group('caseByIdProvider', () {
    test('encuentra casos del Mundo 1, retos y banco', () async {
      final c = ProviderContainer(
        overrides: contentOverrides(_world, challenges: _retos, bank: _bank),
      );
      addTearDown(c.dispose);
      await c.read(campaignProvider(kMundoMansion).future);
      await c.read(dailyChallengesProvider.future);
      await c.read(casesProvider.future);
      expect(c.read(caseByIdProvider('mansion-04'))?.caseId, 'mansion-04');
      expect(c.read(caseByIdProvider('reto-017'))?.caseId, 'reto-017');
      expect(
        c.read(caseByIdProvider('caso-casual-s1'))?.caseId,
        'caso-casual-s1',
      );
      expect(c.read(caseByIdProvider('no-existe')), isNull);
    });

    test('la ruta de salida depende del tipo de caso', () {
      expect(exitRouteFor('mansion-03'), '/casos');
      expect(exitRouteFor('reto-009'), '/home');
      expect(exitRouteFor('caso-casual-s1'), '/banco');
    });
  });

  group('Inicio y Mundos', () {
    testWidgets('Inicio cuenta los 10 casos del Mundo 1 con done:<id>', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        home: const HomeShell(),
        prefs: {
          'done:mansion-01': _done(),
          'done:mansion-02': _done(),
          // Un caso del banco cerrado no suma al Mundo 1.
          'done:caso-principiante-s1': _done(),
        },
      );
      expect(find.text('2 de 10 casos cerrados'), findsOneWidget);
    });

    testWidgets('Mundos muestra el progreso del Mundo 1 sobre 10', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        home: const HomeShell(),
        prefs: {'done:mansion-01': _done()},
      );
      await _tab(tester, 'Mundos');
      expect(find.text('1 de 10 casos cerrados'), findsOneWidget);
    });

    testWidgets('Perfil cuenta casos del Mundo 1 y de los retos', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        home: const HomeShell(),
        prefs: {
          'done:mansion-01': _done(),
          'done:reto-003': _done(),
          'done:caso-principiante-s1': _done(),
        },
      );
      await _tab(tester, 'Perfil');
      expect(
        find.descendant(
          of: find.byType(StatTile).first,
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });
  });

  group('lista de casos del Mundo 1', () {
    testWidgets('muestra los 10 casos en el orden de la campaña', (
      tester,
    ) async {
      await _pumpApp(tester, home: const CaseListScreen());
      expect(find.text('0 / 10'), findsOneWidget);
      // Cada ficha lleva su número y el título de su historia.
      final handle = tester.ensureSemantics();
      try {
        for (var i = 0; i < _world.length; i++) {
          final label = 'Caso ${i + 1}: ${caseTitle(_world[i])}';
          await tester.dragUntilVisible(
            find.bySemanticsLabel(label),
            find.byType(ListView),
            const Offset(0, -200),
          );
          expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('la ficha de un caso muestra su título y su premisa', (
      tester,
    ) async {
      await _pumpApp(tester, home: const CaseListScreen());
      final pc = _world.first;
      await tester.tap(find.byIcon(Icons.search_rounded).last);
      await _settle(tester);
      expect(find.textContaining(caseTitle(pc)), findsOneWidget);
      expect(find.text(pc.story!.premise('es')!), findsOneWidget);
    });

    testWidgets('"En curso" sale de game:<id> y el cierre de done:<id>', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        home: const CaseListScreen(),
        prefs: {
          'done:mansion-01': _done(),
          'game:mansion-02': jsonEncode({'elapsed': 61, 'errors': 0}),
        },
      );
      expect(find.text('1 / 10'), findsWidgets);
      expect(find.textContaining('EN CURSO'), findsOneWidget);
    });

    testWidgets('el banco de pruebas y el feedback ya no salen en la lista', (
      tester,
    ) async {
      await _pumpApp(tester, home: const CaseListScreen());
      expect(find.textContaining('caso-principiante'), findsNothing);
      expect(find.byIcon(Icons.copy_all_rounded), findsNothing);
    });
  });

  group('el Reto juega el caso del día', () {
    testWidgets('Inicio abre el reto de hoy y sigue marcado DEMO', (
      tester,
    ) async {
      final day = challengeDayFor(DateTime.now());
      final router = await _pumpApp(tester, home: const HomeShell());
      expect(find.text('Día $day de 30'), findsOneWidget);
      expect(find.text('DEMO'), findsWidgets);
      await tester.tap(find.text('JUGAR EL RETO'));
      await _settle(tester);
      expect(router.state.uri.path, '/play/${_retoId(day)}');
    });

    testWidgets('la pestaña Reto muestra el estado según lo guardado', (
      tester,
    ) async {
      final day = challengeDayFor(DateTime.now());
      final id = _retoId(day);
      await _pumpApp(tester, home: const HomeShell());
      await _tab(tester, 'Reto');
      expect(find.text('Estado: no iniciado'), findsOneWidget);
      expect(find.textContaining('Día $day de 30'), findsOneWidget);

      await _pumpApp(
        tester,
        home: const HomeShell(),
        prefs: {
          'game:$id': jsonEncode({'elapsed': 40, 'errors': 0}),
        },
      );
      await _tab(tester, 'Reto');
      expect(find.text('Estado: en curso'), findsOneWidget);

      await _pumpApp(
        tester,
        home: const HomeShell(),
        prefs: {'done:$id': _done()},
      );
      await _tab(tester, 'Reto');
      expect(find.text('Estado: resuelto'), findsOneWidget);
    });

    testWidgets('sin reto cargado la pestaña lo dice', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial:v2:done': true});
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: contentOverrides(_world),
          child: MaterialApp(
            theme: SkinUi.theme('ilustrada', Brightness.light),
            home: const HomeShell(),
          ),
        ),
      );
      await _settle(tester);
      await _tab(tester, 'Reto');
      expect(find.text('El caso de hoy no está disponible.'), findsOneWidget);
    });
  });

  group('Configuración: banco de pruebas y feedback', () {
    Future<GoRouter> openSettings(
      WidgetTester tester, {
      bool devTools = true,
    }) async {
      final router = await _pumpApp(
        tester,
        home: const HomeShell(),
        devTools: devTools,
      );
      await _tab(tester, 'Perfil');
      await _tapScrolled(tester, find.text('Configuración'));
      return router;
    }

    testWidgets('aparecen el banco de pruebas, el feedback y la versión', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.ensureVisible(find.text('Banco de pruebas (desarrollo)'));
      expect(find.text('Banco de pruebas (desarrollo)'), findsOneWidget);
      expect(find.text('COPIAR FEEDBACK DE PLAYTEST'), findsOneWidget);
      await tester.ensureVisible(find.text('Enigmatrix v$kAppVersion'));
      expect(find.text('Enigmatrix v$kAppVersion'), findsOneWidget);
    });

    testWidgets('abrir el banco muestra los casos de prueba y se pueden '
        'jugar', (tester) async {
      final router = await openSettings(tester);
      await _tapScrolled(tester, find.text('ABRIR BANCO DE PRUEBAS'));
      expect(router.state.uri.path, '/banco');
      expect(find.text('Banco de pruebas'), findsOneWidget);
      expect(find.text('caso-principiante-s1'), findsOneWidget);
      expect(find.text('caso-intermedio-s1'), findsOneWidget);
      await tester.tap(find.text('caso-casual-s1'));
      await _settle(tester);
      expect(router.state.uri.path, '/play/caso-casual-s1');
    });

    testWidgets(
      'sin ENX_DEV no aparecen banco ni feedback, pero sí la versión',
      (tester) async {
        await openSettings(tester, devTools: false);
        await tester.ensureVisible(find.text('Enigmatrix v$kAppVersion'));
        expect(find.text('Enigmatrix v$kAppVersion'), findsOneWidget);
        expect(find.text('Banco de pruebas (desarrollo)'), findsNothing);
        expect(find.text('ABRIR BANCO DE PRUEBAS'), findsNothing);
        expect(find.text('COPIAR FEEDBACK DE PLAYTEST'), findsNothing);
      },
    );

    testWidgets('copiar feedback avisa dentro de la hoja', (tester) async {
      await openSettings(tester);
      await _tapScrolled(tester, find.text('COPIAR FEEDBACK DE PLAYTEST'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _settle(tester);
      expect(find.textContaining('Feedback copiado'), findsOneWidget);
    });
  });

  group('reporte de feedback de playtest', () {
    test('incluye la versión y los casos abiertos sin terminar de TODOS los '
        'casos (Mundo 1, retos y banco)', () async {
      SharedPreferences.setMockInitialValues({
        'game:mansion-03': jsonEncode({'elapsed': 70, 'errors': 2}),
        'game:reto-009': jsonEncode({'elapsed': 33, 'errors': 0}),
        'game:caso-casual-s1': jsonEncode({'elapsed': 12, 'errors': 1}),
        'done:mansion-01': _done(),
        // Caso abierto que luego se terminó: no cuenta como abandonado.
        'game:mansion-01': jsonEncode({'elapsed': 90, 'errors': 1}),
      });
      final prefs = await SharedPreferences.getInstance();
      final cases = await collectReportCases(
        world: () async => _world,
        challenges: () async => _retos,
        bank: () async => _bank,
      );
      final text = buildReportText(
        prefs: prefs,
        cases: cases,
        now: DateTime(2026, 11, 5),
      );
      expect(text, contains('Versión: $kAppVersion'));
      expect(text, contains('## mansion-03'));
      expect(text, contains('## reto-009'));
      expect(text, contains('## caso-casual-s1'));
      expect(
        RegExp('abierto sin terminar').allMatches(text).length,
        3,
        reason: 'los tres abiertos sin terminar',
      );
      expect(RegExp('## mansion-01').allMatches(text).length, 1);
      expect(text, contains('tiempo: 95s'));
    });

    test('un caso repetido en dos listas entra una sola vez y una lista '
        'que falla no frena a las demás', () async {
      final cases = await collectReportCases(
        world: () async => _world.take(2).toList(),
        challenges: () async => throw StateError('sin retos'),
        bank: () async => [_world.first, ..._bank],
      );
      expect(cases.where((c) => c.caseId == 'mansion-01'), hasLength(1));
      expect(cases.length, 2 + _bank.length);
    });
  });
}
