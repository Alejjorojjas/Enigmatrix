/// Tutorial jugable (regla 11, ADR-0012): caso propio que no consume el
/// Caso 1, guía paso a paso que avanza con las acciones del jugador (X,
/// Notas, Borrar y un Resolver fallido controlado), Saltar
/// siempre visible y cero huellas en el progreso del banco ("done:" / "game:").
/// Todo determinista: el reloj real está apagado y el caso es fijo.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/ui/case_list_screen.dart';
import 'package:enigmatrix/src/ui/game_screen.dart';
import 'package:enigmatrix/src/ui/home_shell.dart';
import 'package:enigmatrix/src/ui/tutorial_coach.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/game_ui.dart';
import 'support/content_overrides.dart';
import 'support/l10n.dart';

PuzzleCase _loadTutorial() => PuzzleCase.fromJson(
  jsonDecode(
        File(
          'assets/tutorial/caso-tutorial.json',
        ).readAsStringSync().replaceFirst('﻿', ''),
      )
      as Map<String, dynamic>,
);

/// Primeros casos reales del banco (como en los smoke tests).
Future<List<PuzzleCase>> _loadBank() async {
  final raw = await rootBundle.loadString('assets/cases/index.json');
  final names = (jsonDecode(raw) as List).cast<String>()..remove('index.json');
  final cases = <PuzzleCase>[];
  for (final name in names.take(4)) {
    final j =
        jsonDecode(await rootBundle.loadString('assets/cases/$name'))
            as Map<String, dynamic>;
    cases.add(PuzzleCase.fromJson(j));
  }
  return cases;
}

// Personajes del tutorial (guion fijo): Adela (víctima), Bruno, Clara, Dario
// y Elena. Casillas de la solución en el tablero de 5x5.
const _adela = 'c1', _bruno = 'c2', _clara = 'c3', _dario = 'c4', _elena = 'c5';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Letra real (Roboto) para medir bien la interfaz.
  setUpAll(loadRoboto);
  final pc = _loadTutorial();
  final pos = pc.solution.positions;
  final steps = buildTutorialSteps(pc);

  // ------------------------------------------------------------------------
  group('el caso del tutorial', () {
    test('es un caso propio y el guion encaja con él', () {
      expect(pc.caseId, kTutorialCaseId);
      expect(pc.caseId, 'tutorial');
      expect(pc.map.size, 5);
      expect(pc.victimId, _adela);
      expect(
        [for (final c in pc.characters) c.nameEs],
        ['Adela', 'Bruno', 'Clara', 'Dario', 'Elena'],
      );
      // Las casillas que nombra la guía.
      expect(pos, {_adela: 3, _bruno: 7, _clara: 14, _dario: 15, _elena: 21});
      expect(
        pc.clueFor(_elena)!.cardTextEs(pc.map, pc.names),
        contains('sofá'),
      );
      expect(steps.length, 18);
      expect(steps.last.isFinal, isTrue);
      expect(steps.where((s) => s.manual).length, 4);
    });

    test('no figura en index.json: no cuenta como Caso 1', () {
      final names =
          (jsonDecode(
                    File(
                      'assets/cases/index.json',
                    ).readAsStringSync().replaceFirst('﻿', ''),
                  )
                  as List)
              .cast<String>();
      expect(names.any((n) => n.contains('tutorial')), isFalse);
      expect(names.where((n) => n != 'index.json'), isNotEmpty);
    });

    testWidgets('se empaqueta como asset y no entra al banco', (tester) async {
      final tutorial = await tester.runAsync(CaseRepository.loadTutorial);
      expect(tutorial!.caseId, kTutorialCaseId);
      expect(tutorial.characters.length, 5);
      final bank = await tester.runAsync(CaseRepository.loadAll);
      expect(bank!.any((c) => c.caseId == kTutorialCaseId), isFalse);
    });

    test('los textos de todos los pasos se arman con el caso', () {
      final s = GameState(
        pc: pc,
        board: BoardState.empty(),
        clueMarks: const [],
      );
      for (final (i, step) in steps.indexed) {
        final text = step.text(l10nEs, s);
        expect(text, isNotEmpty, reason: 'paso $i');
        expect(text.contains(r'$'), isFalse, reason: 'paso $i');
        expect(text.contains('null'), isFalse, reason: 'paso $i');
      }
      // Enseña Confirmar, la X (Tachar), las notas, Borrar y el Resolver.
      final all = [for (final st in steps) st.text(l10nEs, s)].join(' ');
      for (final word in [
        'CONFIRMAR',
        'TACHAR',
        'NOTAS',
        'BORRAR',
        'RESOLVER',
      ]) {
        expect(all, contains(word));
      }
    });
  });

  // ------------------------------------------------------------------------
  group('la guía avanza con las acciones del jugador', () {
    late ProviderContainer container;
    late GameController c;

    GameState st() => container.read(gameControllerProvider(pc));
    bool done(int step) => steps[step].advanceWhen!(st());

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [gameTickerEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      container.listen(gameControllerProvider(pc), (_, __) {});
      c = container.read(gameControllerProvider(pc).notifier);
      await c.ready;
    });

    void confirm(String id, [int? cell]) => expect(
      c.placeSuspect(cell ?? pos[id]!, charId: id, confirm: true),
      ActionFeedback.ok,
    );

    test('recorre los 18 pasos con las acciones del guion', () async {
      // 0 y 1 son manuales: el botón Entendido los pasa.
      expect(steps[0].manual && steps[1].manual, isTrue);

      // 2: anotar un candidato.
      expect(done(2), isFalse);
      c.placeSuspect(pos[_adela]!, charId: _adela, confirm: false);
      expect(done(2), isTrue);

      // 3: confirmar a Adela en su casilla. Antes, una casilla equivocada
      // avisa; la correcta avanza.
      expect(done(3), isFalse);
      c.placeSuspect(0, charId: _adela, confirm: true);
      expect(done(3), isFalse);
      expect(steps[3].warning!(l10nEs, st()), contains('Adela no va ahí'));
      c.eraseCell(0);
      confirm(_adela);
      expect(done(3), isTrue);
      expect(steps[3].warning!(l10nEs, st()), isNull);

      // 5: Bruno en la única cama libre (4 es manual: Auto-X).
      expect(steps[4].manual, isTrue);
      expect(done(5), isFalse);
      confirm(_bruno);
      expect(done(5), isTrue);

      // 6: una X a mano en el Porche; una X sobre una casilla solución avisa.
      expect(done(6), isFalse);
      c.placeXMark(20, XLevel.small);
      expect(done(6), isTrue);
      expect(steps[6].warning!(l10nEs, st()), isNull);
      c.placeXMark(pos[_elena]!, XLevel.small);
      expect(steps[6].warning!(l10nEs, st()), contains('Esa X tapa'));
      c.eraseCell(pos[_elena]!);

      // 7 y 8: Notas y de vuelta a Mapa.
      expect(done(7), isFalse);
      c.toggleMapMode();
      expect(done(7), isTrue);
      expect(done(8), isFalse);
      c.toggleMapMode();
      expect(done(8), isTrue);

      // 9: Clara en la única casilla libre del Baño.
      expect(done(9), isFalse);
      confirm(_clara);
      expect(done(9), isTrue);

      // 10: Elena y Dario terminan el tablero.
      expect(done(10), isFalse);
      confirm(_elena);
      confirm(_dario);
      expect(done(10), isTrue);
      expect(tutorialBoardIsCorrect(st()), isTrue);

      // Con el tablero correcto, el Resolver que acierta espera al final.
      expect(tutorialResolveBlock(l10nEs, pc, st(), 11), isNotNull);
      expect(tutorialResolveBlock(l10nEs, pc, st(), 16), isNotNull);
      expect(tutorialResolveBlock(l10nEs, pc, st(), 17), isNull);

      // 11: quitar a Elena y a Dario (Borrar o lo que sea).
      expect(done(11), isFalse);
      c.removeElement(pos[_elena]!, ConfirmedElement(_elena));
      expect(done(11), isFalse);
      c.removeElement(pos[_dario]!, ConfirmedElement(_dario));
      expect(done(11), isTrue);

      // 12: intercambiarlos. Ponerlos bien avisa que no es el experimento.
      expect(done(12), isFalse);
      confirm(_elena);
      confirm(_dario);
      expect(steps[12].warning!(l10nEs, st()), contains('correcto'));
      c.eraseCell(pos[_elena]!);
      c.eraseCell(pos[_dario]!);
      confirm(_elena, pos[_dario]);
      confirm(_dario, pos[_elena]);
      expect(done(12), isTrue);
      expect(steps[12].warning!(l10nEs, st()), isNull);

      // Con el tablero mal, Resolver siempre falla (no se bloquea).
      expect(tutorialResolveBlock(l10nEs, pc, st(), 13), isNull);

      // 13: Resolver fallido: SOLO el tutorial señala las casillas exactas.
      expect(done(13), isFalse);
      expect(c.solve(revealCells: true), ActionFeedback.wrongSolution);
      expect(done(13), isTrue);
      expect(st().errorCells, {pos[_dario], pos[_elena]});
      expect(st().wrongCount, 2);
      expect(steps[14].manual, isTrue);

      // 15: borrar a los dos con el borrador; 16: ponerlos bien.
      // (el bloqueo de 3 s tras el error debe haber pasado)
      await Future<void>.delayed(const Duration(milliseconds: 3100));
      expect(done(15), isFalse);
      c.eraseCell(pos[_dario]!);
      c.eraseCell(pos[_elena]!);
      expect(done(15), isTrue);
      expect(done(16), isFalse);
      confirm(_elena);
      confirm(_dario);
      expect(done(16), isTrue);

      // 17: el Resolver final acierta.
      expect(steps[17].advanceWhen, isNull);
      expect(c.solve(revealCells: true), ActionFeedback.solvedOk);
      expect(st().murdererId, _bruno);
    });

    test('un Resolver normal NO señala casillas (regla 9)', () {
      confirm(_adela, pos[_bruno]);
      confirm(_bruno, pos[_adela]);
      confirm(_clara);
      confirm(_dario);
      confirm(_elena);
      expect(c.solve(), ActionFeedback.wrongSolution);
      expect(st().errorCells, isEmpty);
      expect(st().wrongCount, 2);
    });
  });

  // ------------------------------------------------------------------------
  group('pantalla del tutorial', () {
    const phone = Size(360, 740);

    Future<(ProviderContainer, GoRouter)> pumpApp(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
      String initial = '/tutorial',
      List<PuzzleCase>? bank,
      Size size = phone,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          gameTickerEnabledProvider.overrideWithValue(false),
          ...contentOverrides(bank ?? const []),
          tutorialCaseProvider.overrideWith((_) async => pc),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
          GoRoute(path: '/casos', builder: (_, __) => const CaseListScreen()),
          GoRoute(
            path: '/tutorial',
            builder: (_, __) =>
                const GameScreen(caseId: kTutorialCaseId, tutorial: true),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: kL10nDelegates,
            supportedLocales: kL10nLocales,
            locale: kL10nLocale,
            routerConfig: router,
          ),
        ),
      );
      await _settle(tester);
      return (container, router);
    }

    // Poner a alguien con la herramienta Confirmar (un solo toque).
    Future<void> confirmAt(WidgetTester tester, String id, int cell) async {
      await pickSuspect(tester, id);
      await pickTool(tester, ToolMode.place);
      await tapCell(tester, cell);
      await _settle(tester);
    }

    Future<void> tapResolve(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await _settle(tester);
    }

    Future<void> entendido(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('guia-entendido')));
      await _settle(tester);
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    // La secuencia de resolver corre en la escena (cuadros de 50 ms como
    // máximo) y el resumen sale 0,9 s después de terminar.
    Future<void> watchReveal(WidgetTester tester) async {
      for (var i = 0; i < 140; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    void expectStep(int index) {
      expect(
        find.text('TUTORIAL · ${index + 1}/${steps.length}'),
        findsOneWidget,
      );
    }

    Future<Set<String>> prefKeys() async =>
        (await SharedPreferences.getInstance()).getKeys();

    testWidgets('recorre los pasos principales con el caso del tutorial', (
      tester,
    ) async {
      final (container, _) = await pumpApp(tester);
      GameState state() => container.read(gameControllerProvider(pc));

      // Arranca en el paso 1, con el caso del tutorial y Saltar a la vista.
      expectStep(0);
      expect(find.text('Saltar'), findsOneWidget);
      expect(find.text('Tutorial · El Club'), findsOneWidget);
      expect(find.textContaining('caso de práctica'), findsOneWidget);

      // 0 y 1: pasos manuales.
      await entendido(tester);
      expectStep(1);
      await entendido(tester);

      // 2: tocar el retrato de Adela y una casilla = candidato.
      expectStep(2);
      await pickSuspect(tester, _adela);
      await tapCell(tester, pos[_adela]!);
      await _settle(tester);
      expect(state().board.cell(pos[_adela]!).candidates, {_adela});

      // 3: mantener oprimida la casilla = confirmar.
      expectStep(3);
      await holdCell(tester, pos[_adela]!);
      await _settle(tester);
      expect(state().board.confirmedCellOf(_adela), pos[_adela]);

      // 4: manual (Auto-X).
      expectStep(4);
      await entendido(tester);

      // 5: Bruno en la única cama libre.
      expectStep(5);
      await confirmAt(tester, _bruno, pos[_bruno]!);

      // 6: la X a mano, con la herramienta Tachar y una casilla del Porche.
      expectStep(6);
      await pickTool(tester, ToolMode.cross);
      await tapCell(tester, 20);
      await _settle(tester);
      expect(state().board.cell(20).x, XLevel.small);

      // 7 y 8: vista Notas desde el menú, y de vuelta a Mapa.
      expectStep(7);
      await openMenu(tester);
      await tester.tap(find.text('Notas'));
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(state().mapMode, isFalse);
      expectStep(8);
      await openMenu(tester);
      await tester.tap(find.text('Mapa'));
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(state().mapMode, isTrue);

      // 9 y 10: Clara, luego Elena y Dario.
      expectStep(9);
      await confirmAt(tester, _clara, pos[_clara]!);
      expectStep(10);
      await confirmAt(tester, _elena, pos[_elena]!);
      await confirmAt(tester, _dario, pos[_dario]!);
      expect(tutorialBoardIsCorrect(state()), isTrue);

      // 11: con el tablero correcto el Resolver espera (hay experimento).
      expectStep(11);
      await tapResolve(tester);
      expect(find.textContaining('Aún no'), findsOneWidget);
      expect(state().solved, isFalse);
      expect(state().errorCount, 0);
      await tester.pump(const Duration(seconds: 4));

      // 11: quitar a Elena y a Dario con Borrar.
      await pickTool(tester, ToolMode.erase);
      for (final cell in [pos[_elena]!, pos[_dario]!]) {
        await tapCell(tester, cell);
        await _settle(tester);
      }
      expect(state().board.confirmedCellOf(_elena), isNull);
      expect(state().board.confirmedCellOf(_dario), isNull);

      // 12: intercambiarlos.
      expectStep(12);
      await confirmAt(tester, _elena, pos[_dario]!);
      await confirmAt(tester, _dario, pos[_elena]!);

      // 13: Resolver fallido: se marcan las casillas exactas y se explica.
      expectStep(13);
      await tapResolve(tester);
      expect(state().errorCells, {pos[_dario], pos[_elena]});
      expect(
        find.text('2 casillas no cuadran: revisa las marcadas'),
        findsOneWidget,
      );
      expect(state().errorCount, 1);

      // 14: explicación (manual). El bloqueo de 3 s se acaba solo.
      expectStep(14);
      expect(find.textContaining('Las casillas rojas'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await entendido(tester);

      // 15: Borrar otra vez.
      expectStep(15);
      await pickTool(tester, ToolMode.erase);
      for (final cell in [pos[_dario]!, pos[_elena]!]) {
        await tapCell(tester, cell);
        await _settle(tester);
      }
      expect(state().board.confirmedCellOf(_elena), isNull);

      // 16: ponerlos bien.
      expectStep(16);
      await confirmAt(tester, _elena, pos[_elena]!);
      await confirmAt(tester, _dario, pos[_dario]!);

      // 17: Resolver final.
      expectStep(17);
      expect(find.byKey(const ValueKey('guia-entendido')), findsNothing);
      await tapResolve(tester);
      expect(state().solved, isTrue);
      await watchReveal(tester);
      expect(find.text('¡Práctica superada!'), findsOneWidget);
      expect(find.textContaining('El asesino era Bruno'), findsOneWidget);

      // Sin huellas: ni "done:" ni "game:" de ningún caso.
      final keys = await prefKeys();
      expect(keys.where((k) => k.startsWith('done:')), isEmpty);
      expect(keys.where((k) => k.startsWith('game:')), isEmpty);
      expect(keys.where((k) => k.startsWith('fb:')), isEmpty);
      expect(keys, contains(tutorialPlayedKey));
    });

    testWidgets('la guía señala con un marco lo que explica', (tester) async {
      final (container, _) = await pumpApp(tester);
      Finder spot(String target) => find.byKey(ValueKey('guia-$target-activo'));
      // Paso 0: los retratos. Paso 1: el tablero.
      expect(spot('portraits'), findsOneWidget);
      await entendido(tester);
      expect(spot('board'), findsOneWidget);
      expect(spot('portraits'), findsNothing);
      // Paso 3: primero la herramienta Confirmar, luego el tablero.
      container.read(tutorialStepProvider.notifier).state = 3;
      await _settle(tester);
      expect(spot('toolPlace'), findsOneWidget);
      await pickTool(tester, ToolMode.place);
      expect(spot('board'), findsOneWidget);
      // Paso 7: el menú.
      container.read(tutorialStepProvider.notifier).state = 7;
      await _settle(tester);
      expect(spot('menu'), findsOneWidget);
      // Paso 13: Resolver.
      container.read(tutorialStepProvider.notifier).state = 13;
      await _settle(tester);
      expect(spot('resolve'), findsOneWidget);
    });

    testWidgets('terminar el tutorial deja el Caso 1 sin jugar', (
      tester,
    ) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (container, router) = await pumpApp(
        tester,
        bank: bank,
        size: const Size(1100, 1700),
      );
      final c = container.read(gameControllerProvider(pc).notifier);

      // Se resuelve el caso (con el controlador, ya probado paso a paso).
      for (final e in pos.entries) {
        c.placeSuspect(e.value, charId: e.key, confirm: true);
      }
      await tapResolve(tester);
      // Con el tablero ya correcto pero la guía en el paso 1, Resolver espera
      // (falta el experimento del Resolver fallido). Se fuerza el último
      // paso de la guía para cerrar el caso.
      expect(container.read(gameControllerProvider(pc)).solved, isFalse);
      container.read(tutorialStepProvider.notifier).state = steps.length - 1;
      await tester.pump(const Duration(seconds: 4));
      await _settle(tester);
      await tapResolve(tester);
      await watchReveal(tester);
      expect(find.text('¡Práctica superada!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tutorial-ir-casos')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.uri.path, '/casos');

      // La lista no incluye el tutorial y el Caso 1 sigue siendo el actual.
      expect(bank.any((b) => b.caseId == kTutorialCaseId), isFalse);
      expect(find.text('SIGUIENTE CASO'), findsOneWidget);
      expect(find.text('Completado: puedes repetirlo'), findsOneWidget);
      expect(find.text('REPETIR'), findsOneWidget);

      final keys = await prefKeys();
      expect(keys.where((k) => k.startsWith('done:')), isEmpty);
      for (final b in bank) {
        expect(keys, isNot(contains('game:${b.caseId}')));
        expect(keys, isNot(contains('done:${b.caseId}')));
      }
      expect(keys, isNot(contains('game:$kTutorialCaseId')));
    });

    testWidgets('Saltar está siempre a la vista y no vuelve solo', (
      tester,
    ) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (container, router) = await pumpApp(
        tester,
        bank: bank,
        size: const Size(1100, 1700),
      );

      expect(find.text('Saltar'), findsOneWidget);
      // También con la partida en pausa.
      container.read(appLifecycleProvider.notifier).state =
          AppLifecycleState.paused;
      await _settle(tester);
      expect(find.text('Partida en pausa'), findsOneWidget);
      expect(find.text('Saltar'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await _settle(tester);

      await tester.tap(find.text('Saltar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.uri.path, '/casos');
      expect(find.text('SIGUIENTE CASO'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(tutorialPlayedKey), isTrue);
      expect(prefs.getBool('tutorial:v2:done'), isTrue);
      expect([
        for (final k in prefs.getKeys())
          if (k.startsWith('done:')) k,
      ], isEmpty);
    });

    testWidgets('la flecha pide confirmar y salir equivale a saltar', (
      tester,
    ) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (_, router) = await pumpApp(
        tester,
        bank: bank,
        size: const Size(1100, 1700),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await _settle(tester);
      expect(find.text('Salir del tutorial'), findsOneWidget);
      await tester.tap(find.text('Seguir practicando'));
      await _settle(tester);
      expect(router.state.uri.path, '/tutorial');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await _settle(tester);
      await tester.tap(find.text('Salir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.uri.path, '/casos');
      expect(
        (await SharedPreferences.getInstance()).getBool(tutorialPlayedKey),
        isTrue,
      );
    });

    testWidgets('siempre empieza de cero y no deja partida guardada', (
      tester,
    ) async {
      final (container, _) = await pumpApp(
        tester,
        prefs: {'game:$kTutorialCaseId': 'basura de una partida anterior'},
      );
      // El tutorial ni restaura ni toca "game:tutorial": empieza de cero.
      final s = container.read(gameControllerProvider(pc));
      expect(s.board.isEmpty, isTrue);
      expect(s.elapsedSeconds, 0);
      expectStep(0);
    });

    for (final size in const [Size(360, 740), Size(360, 640)]) {
      testWidgets(
        'a ${size.width.toInt()}x${size.height.toInt()} la tarjeta de la guía '
        'va arriba y no tapa el tablero ni los retratos',
        (tester) async {
          await pumpApp(tester, size: size);
          final card = tester.getRect(find.text('TUTORIAL · 1/18'));
          final board = tester.getRect(gameFinder);
          final portraits = tester.getRect(
            find.byKey(const ValueKey('retrato-c1')),
          );
          expect(card.bottom, lessThan(board.top));
          expect(board.bottom, lessThanOrEqualTo(portraits.top + 60));
          // Nada se sale de la pantalla ni se desborda.
          expect(
            tester.getRect(find.byKey(const ValueKey('boton-resolver'))).bottom,
            lessThanOrEqualTo(size.height),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('el texto de cada paso cabe en la tarjeta sin desplazarse', (
      tester,
    ) async {
      await pumpApp(tester);
      final style = const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        height: 1.25,
      );
      final s = GameState(
        pc: pc,
        board: BoardState.empty(),
        clueMarks: const [],
      );
      // Ancho útil del texto: pantalla 360 - 2*12 de margen - 24 de relleno
      // - 8 + 22 (emoji).
      const width = 360 - 24 - 24 - 30.0;
      final offenders = <String>[];
      for (final (i, step) in steps.indexed) {
        final painter = TextPainter(
          text: TextSpan(text: step.text(l10nEs, s), style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        // Alto disponible para el texto: 132 - 6 - 4 - 38 de pie - 6.
        if (painter.height > kTutorialCoachHeight - 54) {
          offenders.add('paso $i (${painter.height} px)');
        }
      }
      expect(offenders, isEmpty, reason: 'no caben: acórtalos');
    });

    testWidgets('primer arranque: bienvenida y directo al caso de práctica', (
      tester,
    ) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (_, router) = await pumpApp(
        tester,
        initial: '/home',
        bank: bank,
        size: const Size(1100, 1700),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('CÓMO JUGAR'), findsOneWidget);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('SIGUIENTE'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.text('EMPEZAR LA PRÁCTICA'), findsOneWidget);
      expect(router.state.uri.path, '/home');

      await tester.tap(find.text('EMPEZAR LA PRÁCTICA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.uri.path, '/tutorial');
      expectStep(0);
      expect(find.text('Saltar'), findsOneWidget);
    });

    testWidgets('si ya se hizo o se saltó, no aparece solo', (tester) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (_, router) = await pumpApp(
        tester,
        initial: '/home',
        bank: bank,
        prefs: {tutorialPlayedKey: true},
        size: const Size(1100, 1700),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('CÓMO JUGAR'), findsNothing);
      expect(router.state.uri.path, '/home');
    });

    testWidgets('las claves viejas no eximen del tutorial nuevo (v2)', (
      tester,
    ) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (_, router) = await pumpApp(
        tester,
        initial: '/home',
        bank: bank,
        prefs: {'tutorial:seen': true, 'tutorial:played': true},
        size: const Size(1100, 1700),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('CÓMO JUGAR'), findsOneWidget);
      expect(router.state.uri.path, '/home');
      final prefs = await SharedPreferences.getInstance();
      // Las claves viejas se conservan.
      expect(prefs.getBool('tutorial:played'), isTrue);
      expect(prefs.getBool('tutorial:v2:done'), isNull);
    });

    testWidgets('desde la lista de casos se puede repetir', (tester) async {
      final bank = (await tester.runAsync(_loadBank))!;
      final (_, router) = await pumpApp(
        tester,
        initial: '/casos',
        bank: bank,
        prefs: {tutorialPlayedKey: true},
        size: const Size(1100, 1700),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('REPETIR'), findsOneWidget);

      await tester.tap(find.text('REPETIR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.uri.path, '/tutorial');
      await tester.pump(const Duration(milliseconds: 300));
      expectStep(0);
    });
  });
}

/// Deja pasar lo que el tutorial hace tras cada acción: guardado, avance
/// automático (tras el frame) y animaciones cortas.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}
