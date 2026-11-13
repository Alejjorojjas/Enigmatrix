/// Ranking falso para probar las pantallas sin Firestore ni red.
library;

import 'package:enigmatrix/src/backend/validation_client.dart';
import 'package:enigmatrix/src/daily/daily_logic.dart';
import 'package:enigmatrix/src/daily/ranking_source.dart';

class FakeRankingSource implements DailyRankingSource {
  FakeRankingSource({this.entries = const [], this.uid});

  /// Todas las entradas del día (se ordenan como el servidor: score y luego
  /// solvedAt) y el uid del jugador actual.
  List<RankingEntry> entries;
  final String? uid;

  /// Si no es null, la carga falla con este tipo de error.
  ValidationFailure? failure;
  final List<String> loads = [];

  @override
  String? get currentUid => uid;

  @override
  Future<RankingData> load(String localDate, {String? ownUid}) async {
    loads.add(localDate);
    final f = failure;
    if (f != null) throw ValidationException(f, 'falla');
    // Como Firestore: cada fila es un documento con id == uid y SIN campo
    // `uid`; la app identifica la fila por el id.
    final docs = <RankingEntry>[
      for (final e in entries)
        ?RankingEntry.fromMap(e.uid, {
          'nickname': e.nickname,
          'serverElapsedMs': e.serverElapsedMs,
          'errors': e.errors,
          'score': e.score,
          'solvedAt': e.solvedAtMs,
        }),
    ];
    final sorted = [...docs]..sort(compareRanking);
    final top = sorted.take(kRankingLimit).toList();
    final me = ownUid ?? uid;
    final own = me == null
        ? null
        : sorted.where((e) => e.uid == me).firstOrNull;
    return RankingData(top: top, own: own, ownUid: me);
  }
}
