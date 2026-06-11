/// Carga de casos desde assets (Fase 1: casos empaquetados localmente;
/// en Fase 2 vendrán del servidor SIN solución).
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CaseRepository {
  static Future<List<PuzzleCase>> loadAll() async {
    final raw = await rootBundle.loadString('assets/cases/index.json');
    final names = (jsonDecode(_stripBom(raw)) as List).cast<String>()
      ..remove('index.json');
    final cases = <PuzzleCase>[];
    for (final name in names) {
      final j = jsonDecode(
              _stripBom(await rootBundle.loadString('assets/cases/$name')))
          as Map<String, dynamic>;
      cases.add(PuzzleCase.fromJson(j, mapById(j['mapId'] as String)));
    }
    // Orden: por dificultad y luego por id.
    const order = ['principiante', 'casual', 'intermedio', 'experto', 'elite'];
    cases.sort((a, b) {
      final d = order.indexOf(a.difficulty).compareTo(
          order.indexOf(b.difficulty));
      return d != 0 ? d : a.caseId.compareTo(b.caseId);
    });
    return cases;
  }

  static String _stripBom(String s) =>
      s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;
}

final casesProvider =
    FutureProvider<List<PuzzleCase>>((ref) => CaseRepository.loadAll());

final caseByIdProvider = Provider.family<PuzzleCase?, String>((ref, id) {
  final cases = ref.watch(casesProvider).valueOrNull;
  if (cases == null) return null;
  for (final c in cases) {
    if (c.caseId == id) return c;
  }
  return null;
});
