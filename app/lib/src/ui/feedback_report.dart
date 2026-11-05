/// Reporte de feedback de la prueba de juego: se arma con TODOS los casos
/// (Mundo 1, retos y banco de pruebas), con la versión de la app y los casos
/// abiertos sin terminar, y se copia al portapapeles. Vive en Configuración >
/// "Banco de pruebas (desarrollo)".
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import '../data/case_repository.dart';
import 'ui_kit.dart';

/// Los casos que entran al reporte: Mundo 1, retos y banco, sin repetir. Si
/// una lista no se puede cargar, las demás igual entran.
Future<List<PuzzleCase>> collectReportCases({
  required Future<List<PuzzleCase>> Function() world,
  required Future<List<DailyChallenge>> Function() challenges,
  required Future<List<PuzzleCase>> Function() bank,
}) async {
  final out = <PuzzleCase>[];
  final seen = <String>{};
  void add(Iterable<PuzzleCase> list) {
    for (final c in list) {
      if (seen.add(c.caseId)) out.add(c);
    }
  }

  try {
    add(await world());
  } catch (_) {}
  try {
    add([for (final d in await challenges()) d.puzzle]);
  } catch (_) {}
  try {
    add(await bank());
  } catch (_) {}
  return out;
}

/// Arma el reporte con lo guardado en [prefs] y los casos de [cases].
String buildReportText({
  required SharedPreferences prefs,
  required List<PuzzleCase> cases,
  required DateTime now,
}) => buildFeedbackReport(
  version: kAppVersion,
  now: now,
  cases: [
    for (final pc in cases)
      FeedbackCaseData(
        caseId: pc.caseId,
        difficulty: pc.difficulty,
        doneRaw: prefs.getString('done:${pc.caseId}'),
        gameRaw: prefs.getString('game:${pc.caseId}'),
        notes: prefs.getString('fb:${pc.caseId}'),
      ),
  ],
);

/// Arma el reporte de la app con TODOS los casos y lo guardado en el teléfono.
Future<String> buildReportFor(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cases = await collectReportCases(
    world: () => ref.read(campaignProvider(kMundoMansion).future),
    challenges: () => ref.read(dailyChallengesProvider.future),
    bank: () => ref.read(casesProvider.future),
  );
  return buildReportText(prefs: prefs, cases: cases, now: DateTime.now());
}

/// Copia el reporte y avisa con un mensaje breve.
Future<void> copyFeedbackReport(BuildContext context, WidgetRef ref) async {
  final report = await buildReportFor(ref);
  await Clipboard.setData(ClipboardData(text: report));
  if (context.mounted) {
    showAppToast(context, FeedbackTexts.copied);
  }
}

/// Textos del reporte (centralizados para traducir en la ronda 4.3).
abstract final class FeedbackTexts {
  static const copy = 'Copiar feedback de playtest';
  static const copied =
      'Feedback copiado al portapapeles: pégalo en el chat de Claude para '
      'calibrar el generador';
}
