/// Valores de juego en configuración externa (principio 3 de CLAUDE.md,
/// hallazgo H-65). Hoy salen del asset `assets/config/game_config.json`; en la
/// etapa 5 vendrán de Remote Config con la misma forma.
///
/// La lectura es tolerante: una clave ausente o de tipo (o rango) erróneo
/// toma su valor por defecto, y un JSON roto deja todos los valores por
/// defecto. La app nunca se cuelga por una configuración dañada.
///
/// Los valores por defecto son los que tenía el código antes de moverlos
/// (los de `docs/08-balance.md` y los de la Fase 1).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asset con la configuración empaquetada.
const kGameConfigAsset = 'assets/config/game_config.json';

/// Un mundo según la configuración: solo el id y si está disponible. El
/// nombre visible es un texto y vive en el código (v1_scope.dart).
@immutable
class WorldConfig {
  const WorldConfig(this.id, {required this.available});

  final String id;
  final bool available;

  @override
  bool operator ==(Object other) =>
      other is WorldConfig && other.id == id && other.available == available;

  @override
  int get hashCode => Object.hash(id, available);
}

@immutable
class GameConfig {
  const GameConfig({
    this.undoLimit = 50,
    this.periodicSaveSeconds = 15,
    this.wrongSolveLockSeconds = 3,
    this.splashMinMillis = 1700,
    this.challengeStartDate = '2026-11-01',
    this.challengeDays = 30,
    this.maxLives = 5,
    this.serverTimeoutSeconds = 15,
    this.pendingRetrySeconds = 60,
    this.serverErrorRetryLimit = 3,
    this.v1Difficulties = const ['principiante', 'casual', 'intermedio'],
    this.worlds = const [
      WorldConfig('mansion', available: true),
      WorldConfig('hotel', available: false),
      WorldConfig('museo', available: false),
      WorldConfig('tren', available: false),
      WorldConfig('hospital', available: false),
    ],
  });

  /// Acciones que se pueden deshacer (doc 08: 50).
  final int undoLimit;

  /// Cada cuántos segundos de juego se guarda el reloj sin cambios en el
  /// tablero.
  final int periodicSaveSeconds;

  /// Segundos de bloqueo tras un Resolver fallido (doc 03: "unos segundos").
  final int wrongSolveLockSeconds;

  /// Espera mínima de la pantalla de carga, en milisegundos.
  final int splashMinMillis;

  /// Primer día del reto diario (día 1), en formato aaaa-mm-dd.
  final String challengeStartDate;

  /// Cuántos días tiene el ciclo de retos (después vuelve al día 1).
  final int challengeDays;

  /// Vidas máximas (hoy solo se muestran como DEMO).
  final int maxLives;

  /// Tiempo máximo de cada llamada al servidor, en segundos (etapa 5A.2).
  final int serverTimeoutSeconds;

  /// Cada cuántos segundos se reintenta la cola de envíos "por validar".
  final int pendingRetrySeconds;

  /// Cuántos errores seguidos del servidor se reintentan antes de detener el
  /// envío y preguntar al jugador (no cuenta la falta de señal).
  final int serverErrorRetryLimit;

  /// Dificultades jugables en la V1 (ADR-0014).
  final List<String> v1Difficulties;

  /// Mundos en el orden en que se muestran, con su disponibilidad.
  final List<WorldConfig> worlds;

  /// Fecha de inicio del reto como [DateTime] local (medianoche).
  DateTime get challengeStart =>
      _parseDate(challengeStartDate) ?? DateTime(2026, 11, 1);

  bool isV1Difficulty(String difficulty) => v1Difficulties.contains(difficulty);

  /// Lee la configuración de un valor ya decodificado. Tolerante: cualquier
  /// cosa que no sea un mapa devuelve todos los valores por defecto.
  factory GameConfig.fromJson(Object? json) {
    const d = GameConfig();
    if (json is! Map) return d;
    return GameConfig(
      undoLimit: _positiveInt(json['undoLimit'], d.undoLimit),
      periodicSaveSeconds: _positiveInt(
        json['periodicSaveSeconds'],
        d.periodicSaveSeconds,
      ),
      wrongSolveLockSeconds: _nonNegativeInt(
        json['wrongSolveLockSeconds'],
        d.wrongSolveLockSeconds,
      ),
      splashMinMillis: _nonNegativeInt(
        json['splashMinMillis'],
        d.splashMinMillis,
      ),
      challengeStartDate: _dateText(
        json['challengeStartDate'],
        d.challengeStartDate,
      ),
      challengeDays: _positiveInt(json['challengeDays'], d.challengeDays),
      maxLives: _positiveInt(json['maxLives'], d.maxLives),
      serverTimeoutSeconds: _positiveInt(
        json['serverTimeoutSeconds'],
        d.serverTimeoutSeconds,
      ),
      pendingRetrySeconds: _positiveInt(
        json['pendingRetrySeconds'],
        d.pendingRetrySeconds,
      ),
      serverErrorRetryLimit: _positiveInt(
        json['serverErrorRetryLimit'],
        d.serverErrorRetryLimit,
      ),
      v1Difficulties: _stringList(json['v1Difficulties'], d.v1Difficulties),
      worlds: _worlds(json['worlds'], d.worlds),
    );
  }

  /// Lee la configuración de un texto JSON. Un JSON roto devuelve todos los
  /// valores por defecto.
  factory GameConfig.fromJsonString(String raw) {
    try {
      return GameConfig.fromJson(jsonDecode(raw));
    } catch (_) {
      return const GameConfig();
    }
  }

  /// Carga la configuración empaquetada. Si el asset falta o está dañado
  /// devuelve los valores por defecto: nunca lanza.
  static Future<GameConfig> load({AssetBundle? bundle}) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(kGameConfigAsset);
      return GameConfig.fromJsonString(raw);
    } catch (_) {
      return const GameConfig();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.undoLimit == undoLimit &&
      other.periodicSaveSeconds == periodicSaveSeconds &&
      other.wrongSolveLockSeconds == wrongSolveLockSeconds &&
      other.splashMinMillis == splashMinMillis &&
      other.challengeStartDate == challengeStartDate &&
      other.challengeDays == challengeDays &&
      other.maxLives == maxLives &&
      other.serverTimeoutSeconds == serverTimeoutSeconds &&
      other.pendingRetrySeconds == pendingRetrySeconds &&
      other.serverErrorRetryLimit == serverErrorRetryLimit &&
      listEquals(other.v1Difficulties, v1Difficulties) &&
      listEquals(other.worlds, worlds);

  @override
  int get hashCode => Object.hash(
    undoLimit,
    periodicSaveSeconds,
    wrongSolveLockSeconds,
    splashMinMillis,
    challengeStartDate,
    challengeDays,
    maxLives,
    serverTimeoutSeconds,
    pendingRetrySeconds,
    serverErrorRetryLimit,
    Object.hashAll(v1Difficulties),
    Object.hashAll(worlds),
  );
}

// ---- lectura tolerante ------------------------------------------------------

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double && v.isFinite && v == v.truncateToDouble()) return v.toInt();
  return null;
}

int _positiveInt(Object? v, int fallback) {
  final n = _asInt(v);
  return (n != null && n >= 1) ? n : fallback;
}

int _nonNegativeInt(Object? v, int fallback) {
  final n = _asInt(v);
  return (n != null && n >= 0) ? n : fallback;
}

/// Fecha aaaa-mm-dd válida (solo fecha, sin hora) o null.
DateTime? _parseDate(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final da = int.parse(m.group(3)!);
  final date = DateTime(y, mo, da);
  // DateTime normaliza fechas imposibles (31 de febrero): se rechazan.
  if (date.year != y || date.month != mo || date.day != da) return null;
  return date;
}

String _dateText(Object? v, String fallback) =>
    (v is String && _parseDate(v) != null) ? v : fallback;

List<String> _stringList(Object? v, List<String> fallback) {
  if (v is! List || v.isEmpty || v.any((e) => e is! String)) return fallback;
  return List.unmodifiable(v.cast<String>());
}

List<WorldConfig> _worlds(Object? v, List<WorldConfig> fallback) {
  if (v is! List) return fallback;
  final out = <WorldConfig>[];
  for (final e in v) {
    if (e is Map && e['id'] is String && e['available'] is bool) {
      out.add(
        WorldConfig(e['id'] as String, available: e['available'] as bool),
      );
    }
  }
  return out.isEmpty ? fallback : List.unmodifiable(out);
}

/// Configuración de juego vigente. Sin sobreescribir son los valores por
/// defecto; `main.dart` la sobreescribe con la leída del asset y los tests
/// con la que necesiten.
final gameConfigProvider = Provider<GameConfig>((ref) => const GameConfig());
