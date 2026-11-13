/// Reto diario en la partida (ronda F2b): el inicio oficial se guarda y la
/// victoria muestra tiempo del servidor, errores, score y puesto. Servidor y
/// ranking falsos, sin red.
library;

import 'dart:convert';

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/daily/daily_providers.dart';
import 'package:enigmatrix/src/daily/daily_logic.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_ranking_source.dart';
import 'support/fake_validation_client.dart';
import 'support/game_ui.dart';
import 'support/l10n.dart';

late PuzzleCase pc;

Future<GameRig> _pump(
  WidgetTester tester,
  FakeValidationClient client,
  FakeRankingSource ranking,
) => pumpGameScreen(
  tester,
  pc,
  extraOverrides: [
    backendModeProvider.overrideWithValue(BackendMode.emulator),
    validationClientProvider.overrideWithValue(client),
    dailyRankingSourceProvider.overrideWithValue(ranking),
    campaignProvider.overrideWith((ref, _) async => const []),
    dailyChallengesProvider.overrideWith((_) async => const []),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => pc = loadBankCase('reto-001'));

  testWidgets('la victoria del reto muestra tiempo, errores, score y puesto', (
    tester,
  ) async {
    final client = FakeValidationClient()
      ..add(pc)
      ..anonymous = false
      ..retoElapsedMs = 95000
      ..retoErrors = 1
      ..retoRank = 3;
    final ranking = FakeRankingSource(
      uid: 'yo',
      entries: [
        RankingEntry(
          uid: 'a',
          nickname: 'Ana',
          serverElapsedMs: 80000,
          errors: 0,
          score: 80000,
          solvedAtMs: 1,
        ),
      ],
    );
    final rig = await _pump(tester, client, ranking);
    await settle(tester, 4);

    // El inicio oficial (startedAt del servidor) queda guardado con la fecha.
    final today = formatLocalDate(DateTime.now());
    expect(client.startDates, [today]);
    final prefs = await SharedPreferences.getInstance();
    final started =
        jsonDecode(prefs.getString('startedAt:reto-001')!)
            as Map<String, dynamic>;
    expect(started['date'], today);
    expect(started['at'], 1700000000000);

    final c = rig.container.read(gameControllerProvider(pc).notifier);
    for (final e in pc.solution.positions.entries) {
      c.placeSuspect(e.value, charId: e.key, confirm: true);
    }
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 4);
    for (var i = 0; i < 170; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(client.submits.single.localDate, today);
    expect(find.text('CASO CERRADO'), findsOneWidget);
    // Tiempo del servidor, no el del reloj local de la partida.
    expect(find.text('01:35'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // errores del servidor
    expect(find.byKey(const ValueKey('victoria-score')), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget); // 95 s + 30 s por error
    expect(find.text('#3'), findsOneWidget);

    // Queda guardado para la pestaña Reto (resultado de hoy).
    final done =
        jsonDecode(prefs.getString('done:reto-001')!) as Map<String, dynamic>;
    expect(done['localDate'], today);
    expect(done['serverElapsedMs'], 95000);
    expect(done['score'], 125000);
    expect(done['rank'], 3);
    expect(readDailyProgress(prefs, 'reto-001', today).result!.rank, 3);

    // "Ver ranking" abre el ranking del día.
    await tester.tap(find.text(l10nEs.dailySeeRanking.toUpperCase()));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ranking.loads, [today]);
    expect(find.text('Ana'), findsOneWidget);

    rig.container.read(validationServiceProvider)!.dispose();
  });

  testWidgets('sin puesto: la victoria lo dice y no se rompe', (tester) async {
    final client = FakeValidationClient()
      ..add(pc)
      ..anonymous = false
      ..retoErrors = 0
      ..retoRank = null;
    final rig = await _pump(tester, client, FakeRankingSource(uid: 'yo'));
    await settle(tester, 4);
    final c = rig.container.read(gameControllerProvider(pc).notifier);
    for (final e in pc.solution.positions.entries) {
      c.placeSuspect(e.value, charId: e.key, confirm: true);
    }
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 4);
    for (var i = 0; i < 170; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(l10nEs.dailyNoRankShort), findsOneWidget);
    expect(find.text(l10nEs.dailyNoRank), findsOneWidget);
    expect(tester.takeException(), isNull);
    rig.container.read(validationServiceProvider)!.dispose();
  });
}
