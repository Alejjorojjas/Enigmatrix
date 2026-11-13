/// Reloj de la partida del reto en modo servidor (ajuste post F2): el tiempo
/// sale del `startedAt` del servidor y no se pausa. La campaña y el reto sin
/// red siguen con el reloj local con pausa.
library;

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/backend/validation_providers.dart';
import 'package:enigmatrix/src/daily/daily_providers.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';
import 'support/game_ui.dart' show loadBankCase;

late PuzzleCase reto;
late PuzzleCase campaign;

/// Reloj de la prueba: el "ahora" lo mueve la prueba.
DateTime _now = DateTime(2026, 11, 16, 10);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

Future<GameController> _open(ProviderContainer c, PuzzleCase pc) async {
  c.listen(gameControllerProvider(pc), (_, _) {});
  final controller = c.read(gameControllerProvider(pc).notifier);
  await controller.ready;
  await _settle();
  return controller;
}

ProviderContainer _container(
  FakeValidationClient? client, {
  BackendMode mode = BackendMode.emulator,
}) {
  final c = ProviderContainer(
    overrides: [
      gameTickerEnabledProvider.overrideWithValue(false),
      backendModeProvider.overrideWithValue(mode),
      validationClientProvider.overrideWithValue(client),
      dailyClockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    reto = loadBankCase('reto-001');
    campaign = loadBankCase('mansion-01');
  });

  late FakeValidationClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _now = DateTime(2026, 11, 16, 10);
    client = FakeValidationClient()
      ..add(reto)
      ..add(campaign)
      ..startedAtMs = _now.millisecondsSinceEpoch - 120000;
  });

  test('el reto muestra el tiempo desde el startedAt del servidor', () async {
    final c = _container(client);
    await _open(c, reto);
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 120);
    _now = _now.add(const Duration(seconds: 5));
    c.read(gameControllerProvider(reto).notifier).tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 125);
  });

  test('el reto no se pausa: la pausa solo tapa el tablero', () async {
    final c = _container(client);
    final ctl = await _open(c, reto);
    ctl.pause();
    expect(c.read(gameControllerProvider(reto)).paused, isTrue);
    _now = _now.add(const Duration(seconds: 30)); // la app estuvo fuera
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 150);
    ctl.holdClock(); // un diálogo tampoco lo detiene
    _now = _now.add(const Duration(seconds: 10));
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 160);
    _now = _now.add(const Duration(seconds: 10));
    ctl.resume(); // al continuar se recalcula de inmediato
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 170);
  });

  test('reto sin red (sin startedAt): reloj local con pausa', () async {
    client.online = false;
    final c = _container(client);
    final ctl = await _open(c, reto);
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 0);
    ctl.tick();
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 2);
    ctl.pause();
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 2);
  });

  test('la campaña sigue con reloj local y pausa', () async {
    final c = _container(client);
    final ctl = await _open(c, campaign);
    expect(c.read(gameControllerProvider(campaign)).elapsedSeconds, 0);
    ctl.tick();
    expect(c.read(gameControllerProvider(campaign)).elapsedSeconds, 1);
    ctl.pause();
    ctl.tick();
    expect(c.read(gameControllerProvider(campaign)).elapsedSeconds, 1);
  });

  test('modo none: el reto usa el reloj local con pausa', () async {
    final c = _container(null, mode: BackendMode.none);
    final ctl = await _open(c, reto);
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 1);
    ctl.pause();
    ctl.tick();
    expect(c.read(gameControllerProvider(reto)).elapsedSeconds, 1);
  });
}
