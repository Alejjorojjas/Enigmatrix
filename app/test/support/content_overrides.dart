/// Contenido de prueba para las pantallas: la app lee el Mundo 1, los retos y
/// el banco de pruebas por tres proveedores distintos; estas ayudas los
/// reemplazan a la vez con listas ya cargadas (sin tocar los assets).
library;

import 'package:enigmatrix/src/data/case_repository.dart';
import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enigmatrix/src/ui/v1_scope.dart' show kChallengeDays;

import 'game_ui.dart' show loadBankCase;

/// Reemplaza los proveedores de contenido: [world] es el Mundo 1 (campaña
/// "mansion"), [challenges] los retos y [bank] el banco de pruebas (por
/// omisión, el mismo [world]).
List<Override> contentOverrides(
  List<PuzzleCase> world, {
  List<DailyChallenge> challenges = const [],
  List<PuzzleCase>? bank,
}) => [
  campaignProvider.overrideWith((ref, _) async => world),
  dailyChallengesProvider.overrideWith((_) async => challenges),
  casesProvider.overrideWith((_) async => bank ?? world),
];

/// Los 30 retos reales (assets/cases/reto-001.json ... reto-030.json).
List<DailyChallenge> loadAllChallenges() => [
  for (var d = 1; d <= kChallengeDays; d++)
    DailyChallenge(
      day: d,
      puzzle: loadBankCase('reto-${d.toString().padLeft(3, '0')}'),
    ),
];
