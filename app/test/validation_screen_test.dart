/// Pantalla de partida en modo servidor (etapa 5A.2): los avisos de "por
/// validar", de demasiados intentos y la respuesta que llega con la partida
/// abierta. Con un servidor falso, sin red.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart';
import 'support/l10n.dart';

late PuzzleCase pc;

void _placeSolution(WidgetTester tester, GameRig rig) {
  final c = rig.container.read(gameControllerProvider(pc).notifier);
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

Future<GameRig> _pump(WidgetTester tester, FakeValidationClient client) =>
    pumpGameScreen(
      tester,
      pc,
      extraOverrides: [
        backendModeProvider.overrideWithValue(BackendMode.emulator),
        validationClientProvider.overrideWithValue(client),
        campaignProvider.overrideWith((ref, _) async => [pc]),
        dailyChallengesProvider.overrideWith((_) async => const []),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => pc = loadBankCase('mansion-01'));

  testWidgets('sin conexión: Resolver deja el caso "por validar" con aviso', (
    tester,
  ) async {
    final client = FakeValidationClient()
      ..add(pc)
      ..online = false;
    final rig = await _pump(tester, client);
    _placeSolution(tester, rig);
    await settle(tester, 2);

    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 4);

    expect(find.text(l10nEs.validationPending), findsOneWidget);
    expect(
      rig.container.read(gameControllerProvider(pc)).pendingValidation,
      isTrue,
    );
    expect(rig.container.read(pendingCaseIdsProvider), {pc.caseId});

    // El aviso no se apaga solo: dura hasta que llegue la respuesta.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(l10nEs.validationPending), findsOneWidget);
    // Tocar Resolver otra vez no envía nada nuevo.
    final sent = client.submits.length;
    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 3);
    expect(client.submits.length, sent);

    // El reintento periódico es un temporizador vivo: se apaga al cerrar.
    rig.container.read(validationServiceProvider)!.dispose();
  });

  testWidgets('demasiados intentos: avisa y deja jugar', (tester) async {
    final client = FakeValidationClient()
      ..add(pc)
      ..rateLimited = true;
    final rig = await _pump(tester, client);
    _placeSolution(tester, rig);
    await settle(tester, 2);

    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 4);

    expect(find.text(l10nEs.validationRateLimited), findsOneWidget);
    expect(
      rig.container.read(gameControllerProvider(pc)).pendingValidation,
      isFalse,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('la respuesta llega con la partida abierta: se quita el aviso', (
    tester,
  ) async {
    final client = FakeValidationClient()
      ..add(pc)
      ..online = false;
    final rig = await _pump(tester, client);
    _placeSolution(tester, rig);
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('boton-resolver')));
    await settle(tester, 4);
    expect(find.text(l10nEs.validationPending), findsOneWidget);

    client.online = true;
    await rig.container.read(validationServiceProvider)!.flush();
    await settle(tester, 4);

    final s = rig.container.read(gameControllerProvider(pc));
    expect(s.pendingValidation, isFalse);
    expect(s.solved, isTrue);
    expect(find.text(l10nEs.validationPending), findsNothing);
    // La secuencia de resolver y el resumen siguen su curso.
    await tester.pump(const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 2));
  });
}
