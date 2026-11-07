/// QA independiente de la ronda 5A.2 (la app se conecta al servidor).
/// Casos de borde: doble toque, salir mientras se valida, dos casos pendientes,
/// reloj, respuesta tardia de un caso ya resuelto.
library;

import 'dart:async';
import 'dart:convert';

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

const _pendingKey = 'pending:submissions';

/// Servidor falso que retiene la respuesta hasta que la prueba la suelta.
class GatedClient extends FakeValidationClient {
  Completer<void>? gate;
  @override
  Future<SubmitResponse> submitSolution(SubmitRequest request) async {
    final g = gate;
    if (g != null) await g.future;
    return super.submitSolution(request);
  }
}

ProviderContainer _container(FakeValidationClient client) {
  final c = ProviderContainer(
    overrides: [
      gameTickerEnabledProvider.overrideWithValue(false),
      backendModeProvider.overrideWithValue(BackendMode.emulator),
      validationClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

final Map<PuzzleCase, ProviderSubscription<GameState>> _open_ = {};
Future<void> _settle() => Future<void>.delayed(Duration.zero);
Future<void> _leave(PuzzleCase pc) async {
  _open_.remove(pc)?.close();
  await _settle();
}

Future<GameController> _open(ProviderContainer c, PuzzleCase pc) async {
  _open_[pc] = c.listen(gameControllerProvider(pc), (_, _) {});
  final controller = c.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  return controller;
}

void _place(GameController c, PuzzleCase pc) {
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PuzzleCase m1;
  late PuzzleCase m2;
  setUpAll(() {
    m1 = loadBankCase('mansion-01');
    m2 = loadBankCase('mansion-02');
  });
  late GatedClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = GatedClient()
      ..add(m1)
      ..add(m2);
  });

  test('doble toque en Resolver con envio en vuelo: un solo submit', () async {
    final c = _container(client);
    final ctl = await _open(c, m1);
    _place(ctl, m1);
    client.gate = Completer();
    final a = ctl.solveOnline();
    final b = ctl.solveOnline(); // segundo toque
    await _settle();
    expect(await b, ActionFeedback.ok);
    client.gate!.complete();
    expect(await a, ActionFeedback.solvedOk);
    expect(client.submits.length, 1);
  });

  test('doble toque sin red: un solo envio en la cola', () async {
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c, m1);
    _place(ctl, m1);
    expect(await ctl.solveOnline(), ActionFeedback.pendingValidation);
    expect(await ctl.solveOnline(), ActionFeedback.ok);
    final prefs = await SharedPreferences.getInstance();
    final q = jsonDecode(prefs.getString(_pendingKey)!) as Map;
    expect((q['items'] as List).length, 1);
  });

  test('dos casos pendientes se reenvian cada uno con su id', () async {
    client.online = false;
    final c = _container(client);
    final c1 = await _open(c, m1);
    _place(c1, m1);
    await c1.solveOnline();
    final c2 = await _open(c, m2);
    _place(c2, m2);
    await c2.solveOnline();
    final ids = {for (final s in client.submits) s.caseId: s.submissionId};
    client.online = true;
    client.submits.clear();
    await c.read(validationServiceProvider)!.flush();
    await _settle();
    expect(client.submits.map((s) => s.caseId).toSet(), {
      m1.caseId,
      m2.caseId,
    });
    for (final s in client.submits) {
      expect(s.submissionId, ids[s.caseId]);
    }
    expect(c.read(gameControllerProvider(m1)).solved, isTrue);
    expect(c.read(gameControllerProvider(m2)).solved, isTrue);
    expect(c.read(pendingCaseIdsProvider), isEmpty);
  });

  test('reloj: no corre en por validar', () async {
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c, m1);
    _place(ctl, m1);
    ctl.tick();
    await ctl.solveOnline();
    final t = c.read(gameControllerProvider(m1)).elapsedSeconds;
    ctl.tick();
    ctl.tick();
    expect(c.read(gameControllerProvider(m1)).elapsedSeconds, t);
  });

  test('solved tardio para un caso ya resuelto: no pisa done', () async {
    SharedPreferences.setMockInitialValues({
      'done:${m1.caseId}': jsonEncode({'time': 99, 'errors': 2, 'date': 'x'}),
    });
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c, m1);
    _place(ctl, m1);
    await ctl.solveOnline();
    await _leave(m1);
    client.online = true;
    await c.read(validationServiceProvider)!.flush();
    final prefs = await SharedPreferences.getInstance();
    final done = jsonDecode(prefs.getString('done:${m1.caseId}')!) as Map;
    expect(done['time'], 99);
    expect(c.read(pendingCaseIdsProvider), isEmpty);
  });

  test(
    'salir mientras se valida y el servidor responde solved: '
    'el progreso debe quedar resuelto',
    () async {
      final c = _container(client);
      final ctl = await _open(c, m1);
      _place(ctl, m1);
      client.gate = Completer();
      final f = ctl.solveOnline();
      await _settle();
      await _leave(m1); // sale con el envio en vuelo
      client.gate!.complete();
      await f;
      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey('done:${m1.caseId}'),
        isTrue,
        reason: 'el servidor lo dio por resuelto pero la app no lo recuerda',
      );
    },
  );

  test(
    'salir con el envio en vuelo y volver a entrar: no queda atascado',
    () async {
      final c = _container(client);
      final ctl = await _open(c, m1);
      _place(ctl, m1);
      await ctl.saveNow();
      client.gate = Completer();
      final f = ctl.solveOnline();
      await _settle();
      await _leave(m1);
      await _open(c, m1); // reabre mientras sigue en vuelo
      client.gate!.complete();
      await f;
      await _settle();
      await c.read(validationServiceProvider)!.flush();
      await _settle();
      final s = c.read(gameControllerProvider(m1));
      expect(
        s.pendingValidation && !s.solved,
        isFalse,
        reason: 'pendingValidation=true sin nada en la cola',
      );
    },
  );

  test('wrong tardio con partida guardada suma un solo error', () async {
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c, m1);
    ctl.toggleAutoX();
    final e = m1.solution.positions.entries.toList();
    ctl.placeSuspect(e[1].value, charId: e[0].key, confirm: true);
    ctl.placeSuspect(e[0].value, charId: e[1].key, confirm: true);
    for (final x in e.skip(2)) {
      ctl.placeSuspect(x.value, charId: x.key, confirm: true);
    }
    await ctl.solveOnline();
    await ctl.saveNow();
    await _leave(m1);
    client.online = true;
    await c.read(validationServiceProvider)!.flush();
    final prefs = await SharedPreferences.getInstance();
    final saved = SavedGame.decode(
      prefs.getString(SavedGame.keyFor(m1.caseId))!,
    );
    expect(saved!.errors, 1);
  });
}
