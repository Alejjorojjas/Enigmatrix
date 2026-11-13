/// De dónde sale el ranking del día. La interfaz no conoce Firebase: la
/// implementación real lee Firestore (`dailyRankings/{fecha}/entries`) y los
/// tests usan una falsa.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../backend/backend_config.dart';
import '../backend/validation_client.dart';
import 'daily_logic.dart';

/// Puerto del emulador de Firestore (backend/firebase.json).
const int kFirestoreEmulatorPort = 8080;

abstract class DailyRankingSource {
  /// Los mejores [kRankingLimit] del día [localDate] (`YYYY-MM-DD`), por
  /// score ascendente y, en empate, por `solvedAt`. [ownUid] es el usuario
  /// actual (null si no se sabe): si no está en el top se consulta su entrada
  /// aparte. Lanza [ValidationException] (`network` o `serverError`).
  Future<RankingData> load(String localDate, {String? ownUid});

  /// uid del usuario actual, o null si no hay sesión.
  String? get currentUid;
}

class FirestoreRankingSource implements DailyRankingSource {
  FirestoreRankingSource(
    this._db,
    this._uid, {
    this.timeout = const Duration(seconds: 15),
  });

  final FirebaseFirestore _db;
  final String? Function() _uid;
  final Duration timeout;

  static bool _emulatorSet = false;

  /// Firestore del proyecto según el modo (null si Firebase no arrancó).
  static FirestoreRankingSource? forMode(
    BackendMode mode,
    String? Function() uid,
  ) {
    try {
      final db = FirebaseFirestore.instanceFor(app: Firebase.app());
      if (mode == BackendMode.emulator && !_emulatorSet) {
        _emulatorSet = true;
        db.useFirestoreEmulator(
          resolveEmulatorHost(platform: defaultTargetPlatform),
          kFirestoreEmulatorPort,
        );
      }
      return FirestoreRankingSource(db, uid);
    } on Object catch (e) {
      debugPrint('Firestore no está disponible: $e');
      return null;
    }
  }

  @override
  String? get currentUid => _uid();

  static int _ms(Object? v) =>
      v is Timestamp ? v.millisecondsSinceEpoch : (v is num ? v.toInt() : 0);

  RankingEntry? _read(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    if (data == null) return null;
    return RankingEntry.fromMap(d.id, {
      ...data,
      'solvedAt': _ms(data['solvedAt']),
    });
  }

  @override
  Future<RankingData> load(String localDate, {String? ownUid}) async {
    final uid = ownUid ?? _uid();
    try {
      final col = _db
          .collection('dailyRankings')
          .doc(localDate)
          .collection('entries');
      final snap = await col
          .orderBy('score')
          .orderBy('solvedAt')
          .limit(kRankingLimit)
          .get()
          .timeout(timeout);
      final top = <RankingEntry>[for (final d in snap.docs) ?_read(d)];
      RankingEntry? own;
      if (uid != null) {
        final inTop = top.where((e) => e.uid == uid);
        if (inTop.isNotEmpty) {
          own = inTop.first;
        } else {
          final doc = await col.doc(uid).get().timeout(timeout);
          own = doc.exists ? _read(doc) : null;
        }
      }
      return RankingData(top: top, own: own, ownUid: uid);
    } on TimeoutException {
      throw const ValidationException(
        ValidationFailure.network,
        'ranking-timeout',
      );
    } on FirebaseException catch (e) {
      throw ValidationException(
        (e.code == 'unavailable' || e.code == 'deadline-exceeded')
            ? ValidationFailure.network
            : ValidationFailure.serverError,
        e.code,
      );
    }
  }
}
