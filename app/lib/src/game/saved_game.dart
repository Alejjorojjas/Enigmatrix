/// Partida guardada (H-55, regla 10 del ADR-0012).
///
/// Vive en SharedPreferences bajo la clave `game:<caseId>` con este JSON:
/// {"v":1,"elapsed":int,"errors":int,"savedAt":"(fecha ISO8601)","board":{...},
///  "clueMarks":[int],"autoX":bool,"mapMode":bool}.
/// Se borra al resolver correctamente el caso. Otras pantallas solo leen
/// "elapsed", "errors", "savedAt" y si la clave existe: no cambies esos
/// nombres sin avisar. Es solo cache local, nunca fuente de verdad.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'board_state.dart';

class SavedGame {
  static const int version = 1;

  /// Segundos de juego acumulados (el reloj no cuenta mientras hay pausa).
  final int elapsed;
  final int errors;
  final DateTime savedAt;
  final BoardState board;

  /// Índices de ClueMark (0 normal, 1 destacada, 2 tachada), uno por pista.
  final List<int> clueMarks;
  final bool autoX;
  final bool mapMode;

  const SavedGame({
    required this.elapsed,
    required this.errors,
    required this.savedAt,
    required this.board,
    required this.clueMarks,
    required this.autoX,
    required this.mapMode,
  });

  static String keyFor(String caseId) => 'game:$caseId';

  Map<String, dynamic> toJson() => {
    'v': version,
    'elapsed': elapsed,
    'errors': errors,
    'savedAt': savedAt.toIso8601String(),
    'board': board.toJson(),
    'clueMarks': clueMarks,
    'autoX': autoX,
    'mapMode': mapMode,
  };

  String encode() => jsonEncode(toJson());

  /// Lee un JSON guardado. Devuelve null si está dañado, es de otra versión
  /// o no encaja con el caso ([cellCount] casillas, [clueCount] pistas):
  /// en ese caso se empieza de cero en vez de romper la partida.
  static SavedGame? fromJson(
    Map<String, dynamic> json, {
    int? cellCount,
    int? clueCount,
  }) {
    try {
      if (json['v'] != version) return null;
      final elapsed = json['elapsed'];
      final errors = json['errors'];
      final savedAt = json['savedAt'];
      final board = json['board'];
      final marks = json['clueMarks'];
      final autoX = json['autoX'];
      final mapMode = json['mapMode'];
      if (elapsed is! int || elapsed < 0) return null;
      if (errors is! int || errors < 0) return null;
      if (savedAt is! String) return null;
      if (board is! Map) return null;
      if (marks is! List || marks.any((m) => m is! int || m < 0 || m > 2)) {
        return null;
      }
      if (clueCount != null && marks.length != clueCount) return null;
      if (autoX is! bool || mapMode is! bool) return null;
      return SavedGame(
        elapsed: elapsed,
        errors: errors,
        savedAt: DateTime.parse(savedAt),
        board: BoardState.fromJson(
          board.cast<String, dynamic>(),
          cellCount: cellCount,
        ),
        clueMarks: marks.cast<int>(),
        autoX: autoX,
        mapMode: mapMode,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static SavedGame? decode(String raw, {int? cellCount, int? clueCount}) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      return fromJson(
        j.cast<String, dynamic>(),
        cellCount: cellCount,
        clueCount: clueCount,
      );
    } on FormatException {
      return null;
    }
  }

  // ---- SharedPreferences ----------------------------------------------------

  /// ¿Hay una partida guardada para este caso? (solo mira si existe la clave)
  static bool exists(SharedPreferences prefs, String caseId) =>
      prefs.containsKey(keyFor(caseId));

  static SavedGame? read(
    SharedPreferences prefs,
    String caseId, {
    int? cellCount,
    int? clueCount,
  }) {
    final raw = prefs.getString(keyFor(caseId));
    if (raw == null) return null;
    return decode(raw, cellCount: cellCount, clueCount: clueCount);
  }

  static Future<void> write(
    SharedPreferences prefs,
    String caseId,
    SavedGame game,
  ) => prefs.setString(keyFor(caseId), game.encode());

  static Future<void> clear(SharedPreferences prefs, String caseId) =>
      prefs.remove(keyFor(caseId));
}
