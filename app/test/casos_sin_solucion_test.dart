// Ronda 5A.3 (corte): los casos publicados (mansion-*, reto-*) no llevan la
// solución en los assets de la app; solo el servidor la tiene.

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/src/backend/backend_config.dart';
import 'package:enigmatrix/src/game/game_controller.dart';
import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/game_ui.dart' show loadBankCase;

Map<String, dynamic> _json(File f) =>
    jsonDecode(f.readAsStringSync().replaceFirst('\uFEFF', ''))
        as Map<String, dynamic>;

void main() {
  test(
    'ningún asset mansion-*/reto-* de app/assets/cases lleva "solution"',
    () {
      final files = [
        for (final f in Directory('assets/cases').listSync().whereType<File>())
          if (RegExp(
            r'^(mansion|reto)-.*\.json$',
          ).hasMatch(f.uri.pathSegments.last))
            f,
      ];
      expect(files.length, 40);
      for (final f in files) {
        expect(
          _json(f).containsKey('solution'),
          isFalse,
          reason: '${f.uri.pathSegments.last} lleva "solution"',
        );
      }
    },
  );

  test('el tutorial y el banco caso-* conservan su solución', () {
    final locales = [
      for (final f in Directory('assets/cases').listSync().whereType<File>())
        if (f.uri.pathSegments.last.startsWith('caso-')) f,
      File('assets/tutorial/caso-tutorial.json'),
    ];
    expect(locales.length, 21);
    for (final f in locales) {
      expect(
        _json(f).containsKey('solution'),
        isTrue,
        reason: f.uri.pathSegments.last,
      );
    }
  });

  test('el repositorio carga los casos publicados sin solución', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final campaign = await CaseRepository.loadCampaign(kMundoMansion);
    final retos = await CaseRepository.loadDailyChallenges();
    expect(campaign.length, 10);
    expect(retos.length, 30);
    expect(campaign.every((c) => !c.hasSolution), isTrue);
    expect(retos.every((r) => !r.puzzle.hasSolution), isTrue);
    final banco = await CaseRepository.loadAll();
    expect(banco.every((c) => c.hasSolution), isTrue);
  });

  test(
    'con ENX_BACKEND=none un caso sin solución no se valida local',
    () async {
      SharedPreferences.setMockInitialValues({});
      final pc = loadBankCase('mansion-01').withoutSolution();
      final c = ProviderContainer(
        overrides: [
          backendModeProvider.overrideWithValue(BackendMode.none),
          gameTickerEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(c.dispose);
      c.listen(gameControllerProvider(pc), (_, _) {});
      final ctrl = c.read(gameControllerProvider(pc).notifier);
      await ctrl.ready;
      expect(ctrl.usesServer, isFalse);
      expect(ctrl.solve(), ActionFeedback.serverOnly);
      expect(c.read(gameControllerProvider(pc)).solved, isFalse);
    },
  );
}
