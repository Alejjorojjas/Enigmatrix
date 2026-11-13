/// Pestañas Reto y Ranking reales (ronda F2b). Servidor y ranking falsos, sin
/// red.
library;

import 'package:enigmatrix/src/auth/auth_providers.dart';
import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/daily/daily_logic.dart';
import 'package:enigmatrix/src/daily/daily_providers.dart';
import 'package:enigmatrix/src/daily/daily_screens.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix/src/game/app_settings.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_ranking_source.dart';
import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;
import 'support/l10n.dart';

final _now = DateTime(2026, 11, 16, 10);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

class _Rig {
  _Rig(this.router, this.registrations);
  final GoRouter router;
  final List<int> registrations;
}

Future<_Rig> _pump(
  WidgetTester tester,
  Widget home, {
  FakeValidationClient? client,
  DailyRankingSourceOverride? ranking,
  Map<String, Object> prefs = const {},
  bool noRankingSource = false,
  FakeAuthService? auth,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final registrations = <int>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: '/play/:id',
        builder: (_, s) =>
            Scaffold(body: Text('JUGANDO ${s.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        backendModeProvider.overrideWithValue(BackendMode.emulator),
        if (client != null) validationClientProvider.overrideWithValue(client),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        dailyClockProvider.overrideWithValue(() => _now),
        dailyChallengesProvider.overrideWith(
          (_) async => [
            DailyChallenge(day: 1, puzzle: loadBankCase('reto-001')),
            DailyChallenge(day: 2, puzzle: loadBankCase('reto-002')),
          ],
        ),
        dailyRankingSourceProvider.overrideWithValue(
          noRankingSource ? null : ranking,
        ),
        onRegistrationRequestedProvider.overrideWithValue(
          (_) => registrations.add(1),
        ),
        initialSettingsProvider.overrideWithValue(
          const AppSettings(skinId: 'ilustrada'),
        ),
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
  await _settle(tester);
  return _Rig(router, registrations);
}

typedef DailyRankingSourceOverride = FakeRankingSource;

RankingEntry _e(String uid, int score, {int errors = 0, int at = 0}) =>
    RankingEntry(
      uid: uid,
      nickname: 'Det$uid',
      serverElapsedMs: score - errors * 30000,
      errors: errors,
      score: score,
      solvedAtMs: at,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pestaña Reto', () {
    testWidgets('invitado: invita a registrarse y no consulta el reto', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = true;
      final rig = await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
      );
      expect(find.byKey(const ValueKey('reto-invitado')), findsOneWidget);
      expect(find.text(l10nEs.dailyGuestTitle), findsOneWidget);
      expect(client.log.any((l) => l.startsWith('daily:')), isFalse);
      await tester.tap(find.text(l10nEs.dailyGuestButton.toUpperCase()));
      await tester.pump();
      expect(rig.registrations, hasLength(1));
    });

    testWidgets('correo sin verificar: muestra el aviso en vez del reto', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      final auth = FakeAuthService(guest: false)..verifiesOnRefresh = true;
      // Sesión de correo sin verificar.
      auth.signedVerified = false;
      await auth.createAccountWithEmail('ana@correo.com', '12345678');
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        auth: auth,
      );
      expect(find.byKey(const ValueKey('verificar-correo')), findsOneWidget);
      expect(find.text(l10nEs.dailyVerifyTitle), findsOneWidget);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsNothing);
      expect(client.log.any((l) => l.startsWith('daily:')), isFalse);

      // "Ya lo verifiqué": aparece el reto.
      await tester.tap(find.text(l10nEs.emailVerifyDone.toUpperCase()));
      await _settle(tester);
      await _settle(tester);
      expect(find.byKey(const ValueKey('verificar-correo')), findsNothing);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsOneWidget);
    });

    testWidgets('correo ya verificado (o Google): juega el reto normal', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      final auth = FakeAuthService(guest: false);
      await auth.signInWithGoogle(); // verificado
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        auth: auth,
      );
      expect(find.byKey(const ValueKey('verificar-correo')), findsNothing);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsOneWidget);
    });

    testWidgets(
      'con cuenta: avisa que el reloj no se detiene y pide confirmar',
      (tester) async {
        final client = FakeValidationClient()..anonymous = false;
        final rig = await _pump(
          tester,
          const ServerChallengeTab(),
          client: client,
        );
        expect(client.log, contains('daily:2026-11-16'));
        expect(find.byKey(const ValueKey('reto-aviso-reloj')), findsOneWidget);
        expect(find.text(l10nEs.dailyClockWarning), findsOneWidget);
        expect(find.text(l10nEs.dailyOfflineNote), findsNothing);

        await tester.tap(find.text(l10nEs.dailyStartButton.toUpperCase()));
        await _settle(tester);
        // Aviso previo con confirmación: todavía no se entra al reto.
        expect(
          find.byKey(const ValueKey('aviso-reloj-dialogo')),
          findsOneWidget,
        );
        expect(find.text('JUGANDO reto-001'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('aviso-reloj-empezar')));
        await _settle(tester);
        expect(find.text('JUGANDO reto-001'), findsOneWidget);
        expect(rig.router.state.uri.path, '/play/reto-001');
      },
    );

    testWidgets('"Todavía no" cierra el aviso sin empezar', (tester) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(tester, const ServerChallengeTab(), client: client);
      await tester.tap(find.text(l10nEs.dailyStartButton.toUpperCase()));
      await _settle(tester);
      await tester.tap(find.text(l10nEs.dailyWarningStay));
      await _settle(tester);
      expect(find.text('JUGANDO reto-001'), findsNothing);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsOneWidget);
    });

    testWidgets('el servidor decide qué reto toca', (tester) async {
      final client = FakeValidationClient()
        ..anonymous = false
        ..dailyByDate['2026-11-16'] = 'reto-002';
      await _pump(tester, const ServerChallengeTab(), client: client);
      await tester.tap(find.text(l10nEs.dailyStartButton.toUpperCase()));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('aviso-reloj-empezar')));
      await _settle(tester);
      expect(find.text('JUGANDO reto-002'), findsOneWidget);
    });

    testWidgets(
      'sin conexión: usa la fórmula local y avisa que no hay ranking',
      (tester) async {
        final client = FakeValidationClient()
          ..anonymous = false
          ..online = false;
        await _pump(tester, const ServerChallengeTab(), client: client);
        expect(find.text(l10nEs.dailyOfflineNote), findsOneWidget);
        expect(
          find.text(l10nEs.dailyStartButton.toUpperCase()),
          findsOneWidget,
        );
        await tester.tap(find.text(l10nEs.dailyStartButton.toUpperCase()));
        await _settle(tester);
        await tester.tap(find.byKey(const ValueKey('aviso-reloj-empezar')));
        await _settle(tester);
        // 16-11-2026 es el inicio del ciclo: reto-001.
        expect(find.text('JUGANDO reto-001'), findsOneWidget);
      },
    );

    testWidgets(
      'error del servidor: mensaje en español, no una pantalla rota',
      (tester) async {
        final client = _ErrorDailyClient()..anonymous = false;
        await _pump(tester, const ServerChallengeTab(), client: client);
        expect(
          find.text('La fecha de tu teléfono no coincide con la del servidor.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('reto en curso: el tiempo sale del startedAt del servidor', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      final at = _now.millisecondsSinceEpoch - 125000;
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        prefs: {'startedAt:reto-001': '{"date":"2026-11-16","at":$at}'},
      );
      expect(find.byKey(const ValueKey('reto-en-curso')), findsOneWidget);
      expect(find.text(l10nEs.dailyElapsedLine('02:05')), findsOneWidget);
      expect(
        find.text(l10nEs.dailyContinueButton.toUpperCase()),
        findsOneWidget,
      );

      // Reabrir no repite el aviso: se entra directo.
      await tester.tap(find.text(l10nEs.dailyContinueButton.toUpperCase()));
      await _settle(tester);
      expect(find.byKey(const ValueKey('aviso-reloj-dialogo')), findsNothing);
      expect(find.text('JUGANDO reto-001'), findsOneWidget);
    });

    testWidgets('resuelto hoy: muestra su resultado y su puesto', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        ranking: FakeRankingSource(),
        prefs: {
          'done:reto-001':
              '{"time":80,"errors":1,"localDate":"2026-11-16",'
              '"serverElapsedMs":95000,"serverErrors":1,"score":125000,'
              '"rank":3}',
        },
      );
      expect(find.byKey(const ValueKey('reto-resuelto')), findsOneWidget);
      expect(find.text('01:35'), findsOneWidget); // tiempo del servidor
      expect(find.text('02:05'), findsOneWidget); // total con penalización
      expect(find.text('#3'), findsOneWidget);
      expect(find.text(l10nEs.dailySeeRanking.toUpperCase()), findsOneWidget);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsNothing);
    });

    testWidgets('resuelto sin puesto: lo dice con amabilidad', (tester) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        prefs: {
          'done:reto-001':
              '{"time":80,"errors":0,"localDate":"2026-11-16",'
              '"serverElapsedMs":95000,"serverErrors":0,"score":95000,'
              '"rank":null}',
        },
      );
      expect(find.text(l10nEs.dailyNoRankShort), findsOneWidget);
      expect(find.text(l10nEs.dailyNoRank), findsOneWidget);
    });

    testWidgets('un resultado de otro día no cuenta como resuelto hoy', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        const ServerChallengeTab(),
        client: client,
        prefs: {
          'done:reto-001':
              '{"time":80,"errors":0,"localDate":"2026-10-17",'
              '"serverElapsedMs":95000,"serverErrors":0,"score":95000,'
              '"rank":1}',
        },
      );
      expect(find.byKey(const ValueKey('reto-resuelto')), findsNothing);
      expect(find.text(l10nEs.dailyStartButton.toUpperCase()), findsOneWidget);
    });
  });

  group('pestaña Ranking', () {
    testWidgets('estado vacío amable', (tester) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        const ServerRankingTab(),
        client: client,
        ranking: FakeRankingSource(uid: 'yo'),
      );
      expect(find.byKey(const ValueKey('ranking-vacio')), findsOneWidget);
      expect(find.text(l10nEs.rankingEmpty), findsOneWidget);
    });

    testWidgets(
      'filas con apodo, tiempo, errores y total; la propia resaltada',
      (tester) async {
        final client = FakeValidationClient()..anonymous = false;
        final source = FakeRankingSource(
          uid: 'yo',
          entries: [
            _e('A', 90000, at: 1),
            _e('yo', 125000, errors: 1, at: 2),
            _e('C', 200000, errors: 2, at: 3),
          ],
        );
        await _pump(
          tester,
          const ServerRankingTab(),
          client: client,
          ranking: source,
        );
        expect(source.loads, ['2026-11-16']);
        expect(find.text('DetA'), findsOneWidget);
        expect(find.text('Detyo'), findsOneWidget);
        expect(find.text('(${l10nEs.rankingYouTag})'), findsOneWidget);
        expect(
          find.text(l10nEs.rankingRowDetail('01:35', 1, '02:05')),
          findsOneWidget,
        );
        expect(
          find.text(l10nEs.rankingRowDetail('02:20', 2, '03:20')),
          findsOneWidget,
        );
        expect(
          find.text(l10nEs.rankingRowDetail('01:30', 0, '01:30')),
          findsOneWidget,
        );
        // Sin fila "Tu puesto" aparte: ya está dentro del top.
        expect(find.text(l10nEs.rankingYourPlace), findsNothing);
      },
    );

    testWidgets('la fila propia sale aparte si queda fuera del top 50', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      final source = FakeRankingSource(
        uid: 'yo',
        entries: [
          for (var i = 0; i < 60; i++) _e('u$i', 60000 + i * 1000, at: i),
          _e('yo', 900000, errors: 3, at: 99),
        ],
      );
      await _pump(
        tester,
        const ServerRankingTab(),
        client: client,
        ranking: source,
        prefs: const {
          'done:reto-001':
              '{"time":80,"errors":0,"localDate":"2026-11-16",'
              '"serverElapsedMs":810000,"serverErrors":3,"score":900000,'
              '"rank":61}',
        },
      );
      final data = await source.load('2026-11-16', ownUid: 'yo');
      expect(data.top, hasLength(50));
      expect(data.ownOutsideTop?.uid, 'yo');

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ranking-fila-yo')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10nEs.rankingYourPlace), findsOneWidget);
      expect(find.text('(${l10nEs.rankingYouTag})'), findsOneWidget);
      expect(find.text('61'), findsOneWidget);
      // La fila 51 no está en el top.
      expect(find.byKey(const ValueKey('ranking-fila-u50')), findsNothing);
    });

    testWidgets('sin red: mensaje en español y Reintentar', (tester) async {
      final client = FakeValidationClient()..anonymous = false;
      final source = FakeRankingSource(uid: 'yo')
        ..failure = ValidationFailure.network;
      await _pump(
        tester,
        const ServerRankingTab(),
        client: client,
        ranking: source,
      );
      expect(find.text(l10nEs.rankingLoadError), findsOneWidget);
      source
        ..failure = null
        ..entries = [_e('A', 90000)];
      await tester.tap(find.text(l10nEs.dailyRetry.toUpperCase()));
      await _settle(tester);
      expect(find.text('DetA'), findsOneWidget);
      expect(find.text(l10nEs.rankingLoadError), findsNothing);
    });

    testWidgets('sin fuente de ranking: dice que no está disponible', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = false;
      await _pump(
        tester,
        const ServerRankingTab(),
        client: client,
        noRankingSource: true,
      );
      expect(find.text(l10nEs.rankingUnavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invitado: puede ver el ranking y se le invita a registrarse', (
      tester,
    ) async {
      final client = FakeValidationClient()..anonymous = true;
      await _pump(
        tester,
        const ServerRankingTab(),
        client: client,
        ranking: FakeRankingSource(entries: [_e('A', 90000)]),
      );
      expect(find.text('DetA'), findsOneWidget);
      expect(find.text(l10nEs.rankingGuestNote), findsOneWidget);
    });
  });
}

/// Servidor que responde con error al pedir el reto del día (p. ej. la fecha
/// del teléfono no coincide).
class _ErrorDailyClient extends FakeValidationClient {
  @override
  Future<DailyChallengeInfo> getDailyChallenge(String localDate) async {
    throw const ValidationException(
      ValidationFailure.blocked,
      'failed-precondition',
      'La fecha de tu teléfono no coincide con la del servidor.',
    );
  }
}
