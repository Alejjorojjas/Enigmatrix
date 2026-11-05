/// Carga de casos desde assets (Fase 1: casos empaquetados localmente;
/// en Fase 2 vendrán del servidor SIN solución).
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id del caso del tutorial (regla 11 del ADR-0012). No está en
/// assets/cases/index.json: no cuenta como Caso 1 ni aparece en la lista.
const kTutorialCaseId = 'tutorial';

/// Archivo del caso del tutorial.
const kTutorialAsset = 'assets/tutorial/caso-tutorial.json';

/// Orden de las carpetas de dificultad.
const kDifficultyOrder = [
  'principiante',
  'casual',
  'intermedio',
  'experto',
  'elite',
];

/// Número final de un id ("caso-casual-s20" -> 20). Null si no termina en
/// dígitos.
int? caseNumberOf(String caseId) {
  final m = RegExp(r'(\d+)$').firstMatch(caseId);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Comparación pura: dificultad (dificultad desconocida al final), luego
/// número final del id (numérico); sin número va al final de su dificultad y
/// se ordena alfabéticamente.
int compareCaseKeys(
  String idA,
  String difficultyA,
  String idB,
  String difficultyB,
) {
  int rank(String d) {
    final i = kDifficultyOrder.indexOf(d);
    return i < 0 ? kDifficultyOrder.length : i;
  }

  final d = rank(difficultyA).compareTo(rank(difficultyB));
  if (d != 0) return d;
  final na = caseNumberOf(idA);
  final nb = caseNumberOf(idB);
  if (na != null && nb != null) {
    final n = na.compareTo(nb);
    return n != 0 ? n : idA.compareTo(idB);
  }
  if (na != null) return -1;
  if (nb != null) return 1;
  return idA.compareTo(idB);
}

/// Ordena una lista (en una copia) por dificultad y número final del id.
List<T> sortCases<T>(
  Iterable<T> items, {
  required String Function(T) idOf,
  required String Function(T) difficultyOf,
}) => items.toList()
  ..sort(
    (a, b) =>
        compareCaseKeys(idOf(a), difficultyOf(a), idOf(b), difficultyOf(b)),
  );

/// Parsea cada JSON crudo (nombre de archivo -> texto) saltando los que
/// fallan (se registran con [onError]). Lanza [StateError] si no queda
/// ninguno. Función pura: se prueba sin rootBundle.
List<T> parseCasesTolerant<T>(
  Map<String, String> rawByName, {
  required T Function(Map<String, dynamic> json) parse,
  required String Function(T) idOf,
  required String Function(T) difficultyOf,
  void Function(String message)? onError,
}) {
  final ok = <T>[];
  rawByName.forEach((name, raw) {
    try {
      final j = jsonDecode(stripBom(raw)) as Map<String, dynamic>;
      ok.add(parse(j));
    } catch (e) {
      onError?.call('Caso omitido ($name): $e');
    }
  });
  if (ok.isEmpty) {
    throw StateError(
      'No se pudo cargar ningún caso (${rawByName.length} archivos '
      'revisados). Reinstala la app o avisa al equipo.',
    );
  }
  return sortCases(ok, idOf: idOf, difficultyOf: difficultyOf);
}

String stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

class CaseRepository {
  static Future<List<PuzzleCase>> loadAll() async {
    final raw = await rootBundle.loadString('assets/cases/index.json');
    final names = (jsonDecode(stripBom(raw)) as List).cast<String>()
      ..remove('index.json');
    final raws = <String, String>{};
    for (final name in names) {
      try {
        raws[name] = await rootBundle.loadString('assets/cases/$name');
      } catch (e) {
        debugPrint('Caso omitido ($name): no se pudo leer: $e');
      }
    }
    // Cada caso trae su propio mapa embebido (decisión 2026-06-11).
    return parseCasesTolerant<PuzzleCase>(
      raws,
      parse: PuzzleCase.fromJson,
      idOf: (c) => c.caseId,
      difficultyOf: (c) => c.difficulty,
      onError: debugPrint,
    );
  }

  /// Caso del tutorial (assets/tutorial/caso-tutorial.json), separado del
  /// banco: no pasa por index.json, no se ordena ni cuenta como Caso 1.
  static Future<PuzzleCase> loadTutorial() async {
    final raw = await rootBundle.loadString(kTutorialAsset);
    return PuzzleCase.fromJson(
      jsonDecode(stripBom(raw)) as Map<String, dynamic>,
    );
  }
}

final casesProvider = FutureProvider<List<PuzzleCase>>(
  (ref) => CaseRepository.loadAll(),
);

/// Caso propio del tutorial, aparte del banco de casos.
final tutorialCaseProvider = FutureProvider<PuzzleCase>(
  (ref) => CaseRepository.loadTutorial(),
);

final caseByIdProvider = Provider.family<PuzzleCase?, String>((ref, id) {
  final cases = ref.watch(casesProvider).valueOrNull;
  if (cases == null) return null;
  for (final c in cases) {
    if (c.caseId == id) return c;
  }
  return null;
});

// ---------- Partidas en curso y reporte de feedback (solo lectura) ----------

/// Resumen de la partida guardada en "game:caseId" (contrato compartido:
/// aquí solo se LEE). [elapsed] y [errors] pueden ser null si el JSON está
/// dañado; la partida cuenta como existente igual.
class SavedGameInfo {
  final int? elapsed;
  final int? errors;
  final String? savedAt;
  const SavedGameInfo({this.elapsed, this.errors, this.savedAt});

  static SavedGameInfo fromRaw(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is Map) {
        return SavedGameInfo(
          elapsed: (j['elapsed'] as num?)?.toInt(),
          errors: (j['errors'] as num?)?.toInt(),
          savedAt: j['savedAt'] as String?,
        );
      }
    } catch (_) {}
    return const SavedGameInfo();
  }
}

/// Segundos -> "m:ss" (o "h:mm:ss").
String formatElapsed(int? seconds) {
  if (seconds == null || seconds < 0) return '--:--';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// dd-mm-yyyy
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.year}';

/// Datos crudos de un caso para el reporte.
class FeedbackCaseData {
  final String caseId;
  final String difficulty;
  final String? doneRaw;
  final String? gameRaw;
  final String? notes;
  const FeedbackCaseData({
    required this.caseId,
    required this.difficulty,
    this.doneRaw,
    this.gameRaw,
    this.notes,
  });
}

/// Reporte de playtest (función pura). Incluye casos terminados, notas y
/// casos abiertos sin terminar (partida guardada sin "done:"), para medir
/// abandonos.
String buildFeedbackReport({
  required String version,
  required DateTime now,
  required Iterable<FeedbackCaseData> cases,
}) {
  final r = StringBuffer('FEEDBACK PLAYTEST ENIGMATRIX\n')
    ..writeln('Versión: $version')
    ..writeln('Fecha: ${formatDate(now)}')
    ..writeln();
  for (final c in cases) {
    final notes = c.notes;
    final hasNotes = notes != null && notes.isNotEmpty;
    final abandoned = c.doneRaw == null && c.gameRaw != null;
    if (c.doneRaw == null && !hasNotes && !abandoned) continue;
    r.writeln('## ${c.caseId} (${c.difficulty})');
    if (c.doneRaw != null) {
      final d = jsonDecode(c.doneRaw!);
      r.writeln(
        '   tiempo: ${d['time']}s · errores: ${d['errors']} · ${d['date']}',
      );
    } else if (abandoned) {
      final g = SavedGameInfo.fromRaw(c.gameRaw!);
      r.writeln(
        '   abierto sin terminar · tiempo: ${g.elapsed ?? '?'}s · '
        'errores: ${g.errors ?? '?'}',
      );
    }
    if (hasNotes) r.writeln('   notas: $notes');
    r.writeln();
  }
  return r.toString();
}
