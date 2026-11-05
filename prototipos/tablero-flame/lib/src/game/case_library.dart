/// Los dos casos de prueba (copiados de app/assets/cases) y su lectura con
/// el motor de puzzles (`PuzzleCase`).
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/services.dart';

class CaseEntry {
  final String label;
  final String asset;
  final PuzzleCase puzzle;
  const CaseEntry(this.label, this.asset, this.puzzle);
}

class CaseLibrary {
  /// Un 6x6 Principiante y un 8x8 Casual.
  static const assets = [
    ('6×6 Principiante', 'assets/cases/caso-principiante-s1.json'),
    ('8×8 Casual', 'assets/cases/caso-casual-s1.json'),
  ];

  static PuzzleCase parse(String jsonText) =>
      PuzzleCase.fromJson((jsonDecode(jsonText) as Map).cast<String, dynamic>());

  static Future<List<CaseEntry>> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final out = <CaseEntry>[];
    for (final (label, path) in assets) {
      out.add(CaseEntry(label, path, parse(await b.loadString(path))));
    }
    return out;
  }
}
