/// Resolver nunca llama a startCase (abuso A1 de la auditoría): un inicio justo
/// antes del envío fijaría la hora de inicio a milisegundos de la solución y el
/// servidor daría un tiempo oficial casi cero. Si la partida no tiene
/// `started:<id>` = '1', el envío lleva `startedOnline: false`.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

late PuzzleCase pc;

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

ProviderSubscription<GameState>? _sub;

Future<GameController> _open(ProviderContainer c) async {
  _sub = c.listen(gameControllerProvider(pc), (_, _) {});
  final controller = c.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  // Deja terminar el aviso de inicio (startCase) que se lanza al abrir.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return controller;
}

void _place(GameController c) {
  for (final e in pc.solution.positions.entries) {
    c.placeSuspect(e.value, charId: e.key, confirm: true);
  }
}

int _startCalls(FakeValidationClient client) =>
    client.log.where((e) => e.startsWith('start:')).length;

Map<String, Object> _savedWithTime() => {
  SavedGame.keyFor(pc.caseId): SavedGame(
    elapsed: 120,
    errors: 0,
    savedAt: DateTime.utc(2026, 11, 6, 9),
    board: BoardState.empty(),
    clueMarks: List.filled(pc.clues.length, 0),
    autoX: true,
    mapMode: true,
  ).encode(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => pc = loadBankCase('mansion-01'));

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeValidationClient()..add(pc);
  });

  test('el aviso de inicio falló en el servidor: Resolver no lo reintenta y '
      'envía startedOnline false', () async {
    client.startFailure = ValidationFailure.serverError;
    final c = _container(client);
    final ctl = await _open(c);
    expect(_startCalls(client), 1); // el de la apertura
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('started:${pc.caseId}'), isFalse);

    // El servidor se recupera, pero la partida ya empezó: no se llama a
    // startCase justo antes del envío.
    client.startFailure = null;
    _place(ctl);
    expect(await ctl.solveOnline(), ActionFeedback.solvedOk);

    expect(_startCalls(client), 1);
    expect(client.starts, isEmpty);
    expect(client.submits.single.startedOnline, isFalse);
    expect(
      client.log.where((e) => e.startsWith('start:')).length,
      1,
      reason: 'ningún startCase antes de submitSolution',
    );
  });

  test('partida guardada con tiempo y sin registro: ni se abre con startCase '
      'ni Resolver lo llama', () async {
    SharedPreferences.setMockInitialValues(_savedWithTime());
    final c = _container(client);
    final ctl = await _open(c);
    _place(ctl);
    await ctl.solveOnline();

    expect(_startCalls(client), 0);
    expect(client.submits.single.startedOnline, isFalse);
    final prefs = await SharedPreferences.getInstance();
    // Resuelto: el registro de inicio se limpia.
    expect(prefs.getString('started:${pc.caseId}'), anyOf(isNull, '0'));
  });

  test('sin red al abrir: queda "0" y Resolver envía startedOnline false '
      'sin llamar a startCase', () async {
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c);
    final before = _startCalls(client);
    _place(ctl);
    await ctl.solveOnline();
    expect(_startCalls(client), before);
    expect(client.submits.single.startedOnline, isFalse);
  });

  test('empezó con conexión: Resolver envía startedOnline true y no vuelve a '
      'llamar a startCase', () async {
    final c = _container(client);
    final ctl = await _open(c);
    expect(_startCalls(client), 1);
    _place(ctl);
    await ctl.solveOnline();
    expect(_startCalls(client), 1);
    expect(client.submits.single.startedOnline, isTrue);
    expect(
      client.log.indexOf('submit:${pc.caseId}'),
      greaterThan(client.log.indexOf('start:${pc.caseId}')),
    );
  });

  test('reabrir un caso sin tiempo jugado vuelve a probar startCase', () async {
    client.startFailure = ValidationFailure.serverError;
    final c = _container(client);
    await _open(c);
    expect(_startCalls(client), 1);

    // El jugador sale sin jugar y vuelve a entrar con el servidor sano.
    _sub!.close();
    await Future<void>.delayed(Duration.zero);
    client.startFailure = null;
    await _open(c);
    expect(_startCalls(client), 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('started:${pc.caseId}'), '1');
  });
}
