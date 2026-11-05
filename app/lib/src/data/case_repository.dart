/// Carga de casos desde assets (Fase 1: casos empaquetados localmente;
/// en Fase 2 vendrán del servidor SIN solución).
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id del caso del tutorial (regla 11 del ADR-0012). No está en el catálogo
/// ni en assets/cases/index.json: no cuenta como Caso 1 ni aparece en la
/// lista.
const kTutorialCaseId = 'tutorial';

/// Archivo del caso del tutorial.
const kTutorialAsset = 'assets/tutorial/caso-tutorial.json';

/// Catálogo de casos (manifiesto): id estable, mundo, tipo, dificultad, orden
/// y archivo. Manda el orden de la lista (H-43, H-50).
const kCatalogAsset = 'assets/cases/$kCatalogFileName';

/// Índice heredado: solo nombres de archivo. Se usa si el catálogo falta o
/// está dañado.
const kIndexAsset = 'assets/cases/index.json';

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
///
/// Si se da [orderOf] (id -> posición en el catálogo), los casos que tienen
/// posición van primero, por ella; los que no la tienen van después con el
/// orden de siempre (dificultad y número final).
List<T> sortCases<T>(
  Iterable<T> items, {
  required String Function(T) idOf,
  required String Function(T) difficultyOf,
  Map<String, int>? orderOf,
}) => items.toList()
  ..sort((a, b) {
    if (orderOf != null) {
      final oa = orderOf[idOf(a)];
      final ob = orderOf[idOf(b)];
      if (oa != null && ob != null) {
        final c = oa.compareTo(ob);
        return c != 0 ? c : idOf(a).compareTo(idOf(b));
      }
      if (oa != null) return -1;
      if (ob != null) return 1;
    }
    return compareCaseKeys(idOf(a), difficultyOf(a), idOf(b), difficultyOf(b));
  });

/// Qué archivos cargar y en qué orden: el resultado de leer el catálogo (o
/// el índice heredado si el catálogo no sirve).
class CaseSource {
  /// Nombres de archivo a cargar.
  final List<String> files;

  /// id del caso -> posición en el catálogo. Vacío si se usó el índice
  /// heredado (entonces se ordena por dificultad y número final).
  final Map<String, int> orderById;

  /// true si los nombres salieron del catálogo.
  final bool fromCatalog;

  /// Entradas del catálogo omitidas o avisos de lectura.
  final List<String> warnings;

  const CaseSource({
    required this.files,
    required this.orderById,
    required this.fromCatalog,
    this.warnings = const [],
  });
}

/// Decide la fuente de casos a partir de los textos crudos del catálogo y
/// del índice heredado (cualquiera puede faltar o venir roto). Función pura:
/// se prueba sin rootBundle.
///
/// Prioridad: el catálogo si trae al menos una entrada válida; si no, el
/// índice heredado. Si no sirve ninguno lanza [StateError].
///
/// [mundo] y [tipo] (opcionales) limitan las entradas del catálogo que se
/// devuelven. El índice heredado solo lista los casos del banco de pruebas,
/// así que como respaldo se usa tal cual.
CaseSource resolveCaseSource({
  String? catalogRaw,
  String? indexRaw,
  String? mundo,
  CaseKind? tipo,
}) {
  final warnings = <String>[];
  if (catalogRaw != null) {
    try {
      final parsed = CaseCatalog.parse(catalogRaw);
      warnings.addAll([for (final e in parsed.errors) 'Catálogo: $e']);
      final entries = parsed.catalog.where(mundo: mundo, tipo: tipo);
      if (entries.isNotEmpty) {
        return CaseSource(
          files: [for (final e in entries) e.archivo],
          orderById: {for (final e in entries) e.id: e.orden},
          fromCatalog: true,
          warnings: warnings,
        );
      }
      warnings.add('Catálogo sin casos válidos: se usa index.json.');
    } catch (e) {
      warnings.add('Catálogo ilegible, se usa index.json: $e');
    }
  }
  if (indexRaw != null) {
    try {
      final names = (jsonDecode(stripBom(indexRaw)) as List).cast<String>()
        ..remove('index.json')
        ..remove(kCatalogFileName);
      if (names.isNotEmpty) {
        return CaseSource(
          files: names,
          orderById: const {},
          fromCatalog: false,
          warnings: warnings,
        );
      }
    } catch (e) {
      warnings.add('index.json ilegible: $e');
    }
  }
  throw StateError(
    'No se pudo leer la lista de casos (catálogo ni índice). '
    'Reinstala la app o avisa al equipo. ${warnings.join(' ')}',
  );
}

/// Parsea cada JSON crudo (nombre de archivo -> texto) saltando los que
/// fallan (se registran con [onError]). Lanza [StateError] si no queda
/// ninguno. Función pura: se prueba sin rootBundle.
List<T> parseCasesTolerant<T>(
  Map<String, String> rawByName, {
  required T Function(Map<String, dynamic> json) parse,
  required String Function(T) idOf,
  required String Function(T) difficultyOf,
  Map<String, int>? orderOf,
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
  return sortCases(
    ok,
    idOf: idOf,
    difficultyOf: difficultyOf,
    orderOf: orderOf,
  );
}

String stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

/// Entradas del catálogo de un mundo y tipo (ambos opcionales), en el orden
/// del catálogo. Función pura. Entradas inválidas del catálogo se saltan.
/// Lanza [StateError] si el catálogo falta o no se puede leer.
List<CatalogEntry> selectCatalogEntries(
  String? catalogRaw, {
  String? mundo,
  CaseKind? tipo,
}) {
  if (catalogRaw == null) {
    throw StateError(
      'No se pudo leer el catálogo de casos. '
      'Reinstala la app o avisa al equipo.',
    );
  }
  try {
    return CaseCatalog.parse(
      catalogRaw,
    ).catalog.where(mundo: mundo, tipo: tipo);
  } catch (e) {
    throw StateError('Catálogo de casos ilegible: $e');
  }
}

/// Une cada entrada con su caso ya leído (archivo -> texto JSON), conservando
/// el orden de [entries]. Salta, avisando con [onError], las entradas cuyo
/// archivo falta o cuyo JSON no se entiende, o cuyo id no coincide con el del
/// catálogo (el id del catálogo manda: es la clave del progreso del jugador).
/// Función pura: se prueba sin rootBundle.
List<({CatalogEntry entry, PuzzleCase puzzle})> pairEntriesWithCases(
  List<CatalogEntry> entries,
  Map<String, String> rawByFile, {
  void Function(String message)? onError,
}) {
  final out = <({CatalogEntry entry, PuzzleCase puzzle})>[];
  for (final e in entries) {
    final raw = rawByFile[e.archivo];
    if (raw == null) {
      onError?.call('Caso omitido (${e.archivo}): no se pudo leer.');
      continue;
    }
    try {
      final pc = PuzzleCase.fromJson(
        jsonDecode(stripBom(raw)) as Map<String, dynamic>,
      );
      if (pc.caseId != e.id) {
        onError?.call(
          'Caso omitido (${e.archivo}): el catálogo dice "${e.id}" '
          'pero el caso es "${pc.caseId}".',
        );
        continue;
      }
      out.add((entry: e, puzzle: pc));
    } catch (err) {
      onError?.call('Caso omitido (${e.archivo}): $err');
    }
  }
  return out;
}

/// Un día del reto diario: su número (1 a 30) y el caso de ese día.
class DailyChallenge {
  final int day;
  final PuzzleCase puzzle;
  const DailyChallenge({required this.day, required this.puzzle});
}

/// Retos ordenados por número de día (copia).
List<DailyChallenge> sortChallenges(Iterable<DailyChallenge> items) =>
    items.toList()..sort((a, b) => a.day.compareTo(b.day));

class CaseRepository {
  /// Lee el texto de un asset; null si no existe o falla.
  static Future<String?> _tryLoad(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }

  /// Carga los casos del banco de pruebas en el orden del catálogo
  /// (assets/cases/catalogo.json). Es la lista que la app muestra hoy: el
  /// Mundo 1 y el reto diario NO entran aquí, se piden con [loadCampaign] y
  /// [loadDailyChallenges].
  /// Si el catálogo falta o está dañado, usa index.json (orden por
  /// dificultad y número final, como antes). Un caso que no se lee o no se
  /// entiende se omite y se registra; el resto carga.
  static Future<List<PuzzleCase>> loadAll() async {
    final source = resolveCaseSource(
      catalogRaw: await _tryLoad(kCatalogAsset),
      indexRaw: await _tryLoad(kIndexAsset),
      mundo: kBancoDePruebas,
    );
    source.warnings.forEach(debugPrint);
    final raws = <String, String>{};
    for (final name in source.files) {
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
      orderOf: source.orderById,
      onError: debugPrint,
    );
  }

  /// Casos de campaña de un mundo ([world], por ejemplo [kMundoMansion]), en
  /// el orden del catálogo (el orden en que se juegan). Un caso que no se lee
  /// o no se entiende se omite y se registra. Lista vacía si el mundo no
  /// existe; lanza [StateError] si el catálogo no se puede leer.
  static Future<List<PuzzleCase>> loadCampaign(String world) async {
    final entries = selectCatalogEntries(
      await _tryLoad(kCatalogAsset),
      mundo: world,
      tipo: CaseKind.campana,
    );
    final pairs = await _loadEntries(entries);
    return [for (final p in pairs) p.puzzle];
  }

  /// Los retos diarios (tipo "reto"), ordenados por día (1 a 30). La hora de
  /// cambio de día está pendiente (pregunta 7 de la auditoría): aquí solo se
  /// conoce el número de día. Lanza [StateError] si el catálogo no se puede
  /// leer.
  static Future<List<DailyChallenge>> loadDailyChallenges() async {
    final entries = selectCatalogEntries(
      await _tryLoad(kCatalogAsset),
      tipo: CaseKind.reto,
    );
    final pairs = await _loadEntries(entries);
    return sortChallenges([
      for (final p in pairs)
        if (p.entry.dia != null)
          DailyChallenge(day: p.entry.dia!, puzzle: p.puzzle),
    ]);
  }

  /// El reto de un día concreto, o null si no existe.
  static Future<PuzzleCase?> loadDailyChallenge(int day) async {
    for (final c in await loadDailyChallenges()) {
      if (c.day == day) return c.puzzle;
    }
    return null;
  }

  static Future<List<({CatalogEntry entry, PuzzleCase puzzle})>> _loadEntries(
    List<CatalogEntry> entries,
  ) async {
    final raws = <String, String>{};
    for (final e in entries) {
      try {
        raws[e.archivo] = await rootBundle.loadString(
          'assets/cases/${e.archivo}',
        );
      } catch (err) {
        debugPrint('Caso omitido (${e.archivo}): no se pudo leer: $err');
      }
    }
    return pairEntriesWithCases(entries, raws, onError: debugPrint);
  }

  /// Caso del tutorial (assets/tutorial/caso-tutorial.json), separado del
  /// banco: no pasa por el catálogo, no se ordena ni cuenta como Caso 1.
  static Future<PuzzleCase> loadTutorial() async {
    final raw = await rootBundle.loadString(kTutorialAsset);
    return PuzzleCase.fromJson(
      jsonDecode(stripBom(raw)) as Map<String, dynamic>,
    );
  }
}

/// Los 20 casos del banco de pruebas (desarrollo). No es la lista normal de
/// la app: se carga solo cuando se abre el banco desde Configuración o cuando
/// una partida pide uno de esos casos.
final casesProvider = FutureProvider<List<PuzzleCase>>(
  (ref) => CaseRepository.loadAll(),
);

/// Casos de campaña de un mundo ("mansion"), en el orden en que se juegan.
final campaignProvider = FutureProvider.family<List<PuzzleCase>, String>(
  (ref, world) => CaseRepository.loadCampaign(world),
);

/// Los 30 retos diarios por número de día.
final dailyChallengesProvider = FutureProvider<List<DailyChallenge>>(
  (ref) => CaseRepository.loadDailyChallenges(),
);

/// Caso propio del tutorial, aparte del banco de casos.
final tutorialCaseProvider = FutureProvider<PuzzleCase>(
  (ref) => CaseRepository.loadTutorial(),
);

/// Busca un caso por su id: primero en el Mundo 1, luego en los retos y, al
/// final, en el banco de pruebas (que solo se carga si hace falta). Null
/// mientras no se haya cargado la lista donde está.
final caseByIdProvider = Provider.family<PuzzleCase?, String>((ref, id) {
  PuzzleCase? find(Iterable<PuzzleCase>? list) {
    if (list == null) return null;
    for (final c in list) {
      if (c.caseId == id) return c;
    }
    return null;
  }

  final world = find(ref.watch(campaignProvider(kMundoMansion)).valueOrNull);
  if (world != null) return world;
  final challenges = ref.watch(dailyChallengesProvider).valueOrNull;
  final daily = find(
    challenges == null ? null : [for (final c in challenges) c.puzzle],
  );
  if (daily != null) return daily;
  return find(ref.watch(casesProvider).valueOrNull);
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
