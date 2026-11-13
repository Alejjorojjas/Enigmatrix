/// Errores nuevos del reto (ronda de QA tras F2): `failed-precondition` con
/// `details.reason` `wrong-limit` y `email-unverified` son estados propios,
/// distintos del límite por minuto y del registro obligatorio. Sin red.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/firebase_validation_client.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/backend/validation_service.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart';
import 'support/l10n.dart';

late PuzzleCase pc;

void _placeSolution(GameRig rig) {
  final c = rig.container.read(gameControllerProvider(pc).notifier);
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

Future<GameRig> _pump(FakeValidationClient client, WidgetTester tester) =>
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('traducción del código del servidor', () {
    test('wrong-limit y email-unverified se distinguen por details.reason', () {
      expect(
        failureForFunctionsCode(
          'failed-precondition',
          'Llegaste al máximo de intentos del reto de hoy.',
          {'reason': 'wrong-limit'},
        ),
        ValidationFailure.wrongLimit,
      );
      expect(
        failureForFunctionsCode(
          'failed-precondition',
          'Verifica tu correo para jugar el reto.',
          {'reason': 'email-unverified'},
        ),
        ValidationFailure.emailUnverified,
      );
    });

    test('lo demás sigue igual', () {
      expect(
        failureForFunctionsCode('resource-exhausted'),
        ValidationFailure.rateLimited,
      );
      expect(
        failureForFunctionsCode(
          'failed-precondition',
          'Regístrate para seguir',
        ),
        ValidationFailure.registrationRequired,
      );
      expect(
        failureForFunctionsCode('failed-precondition'),
        ValidationFailure.blocked,
      );
      expect(
        failureForFunctionsCode('failed-precondition', 'x', {'reason': 'otra'}),
        ValidationFailure.blocked,
      );
      expect(
        failureForFunctionsCode('failed-precondition', 'x', 'texto'),
        ValidationFailure.blocked,
      );
    });
  });

  group('servicio y controlador', () {
    for (final (failure, feedback) in [
      (ValidationFailure.wrongLimit, ActionFeedback.wrongLimit),
      (ValidationFailure.emailUnverified, ActionFeedback.emailUnverified),
    ]) {
      test('$failure: estado propio, no queda en la cola', () async {
        final client = FakeValidationClient()
          ..add(pc)
          ..submitFailure = failure;
        final service = ValidationService(client: client);
        addTearDown(service.dispose);
        final out = await service.submit(
          PendingSubmission(
            caseId: pc.caseId,
            submissionId: 'sub-limite-0001',
            positions: pc.solution.positions,
            clientElapsedMs: 1000,
            startedOnline: true,
            elapsedSeconds: 1,
            errorCount: 0,
            createdAt: DateTime(2026, 11, 16),
          ),
        );
        expect(
          out,
          failure == ValidationFailure.wrongLimit
              ? isA<OutcomeWrongLimit>()
              : isA<OutcomeEmailUnverified>(),
        );
        expect(out, isNot(isA<OutcomeRateLimited>()));
        expect(out, isNot(isA<OutcomeRegistrationRequired>()));
        expect(service.pendingCaseIds, isEmpty);
        expect(feedback, isNot(ActionFeedback.rateLimited));
      });
    }
  });

  group('en la partida', () {
    testWidgets(
      'máximo de intentos: muestra su texto, no "espera un momento"',
      (tester) async {
        final client = FakeValidationClient()
          ..add(pc)
          ..submitFailure = ValidationFailure.wrongLimit;
        final rig = await _pump(client, tester);
        _placeSolution(rig);
        await settle(tester, 2);
        await tester.tap(find.byKey(const ValueKey('boton-resolver')));
        await settle(tester, 4);

        expect(find.text(l10nEs.validationWrongLimit), findsOneWidget);
        expect(
          l10nEs.validationWrongLimit,
          'Llegaste al máximo de intentos del reto de hoy.',
        );
        expect(find.text(l10nEs.validationRateLimited), findsNothing);
        expect(
          rig.container.read(gameControllerProvider(pc)).pendingValidation,
          isFalse,
        );
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets('correo sin verificar: muestra su texto', (tester) async {
      final client = FakeValidationClient()
        ..add(pc)
        ..submitFailure = ValidationFailure.emailUnverified;
      final rig = await _pump(client, tester);
      _placeSolution(rig);
      await settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('boton-resolver')));
      await settle(tester, 4);

      expect(find.text(l10nEs.validationEmailUnverified), findsOneWidget);
      expect(
        l10nEs.validationEmailUnverified,
        'Verifica tu correo para jugar el reto.',
      );
      expect(find.text(l10nEs.validationRateLimited), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
