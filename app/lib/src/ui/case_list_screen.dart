/// Lista de casos del banco de pruebas (Fase 1). Muestra progreso y permite
/// exportar el feedback de playtest acumulado.
library;

import 'dart:convert';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../data/case_repository.dart';

final prefsProvider =
    FutureProvider<SharedPreferences>((_) => SharedPreferences.getInstance());

class CaseListScreen extends ConsumerWidget {
  const CaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(casesProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ENIGMATRIX · banco de pruebas Fase 1',
            style: TextStyle(letterSpacing: 2)),
        actions: [
          TextButton.icon(
            onPressed: () => _copyFeedback(context, ref),
            icon: const Icon(Icons.copy_all, color: Brand.gold),
            label: const Text('Copiar feedback',
                style: TextStyle(color: Brand.gold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: cases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando casos: $e')),
        data: (list) {
          final byDifficulty = <String, List<PuzzleCase>>{};
          for (final c in list) {
            byDifficulty.putIfAbsent(c.difficulty, () => []).add(c);
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final e in byDifficulty.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    e.key.toUpperCase(),
                    style: const TextStyle(
                        color: Brand.gold,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final pc in e.value) _CaseCard(pc: pc, prefs: prefs),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyFeedback(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final cases = ref.read(casesProvider).valueOrNull ?? [];
    final report = StringBuffer('FEEDBACK PLAYTEST ENIGMATRIX\n\n');
    for (final pc in cases) {
      final done = prefs.getString('done:${pc.caseId}');
      final fb = prefs.getString('fb:${pc.caseId}');
      if (done == null && (fb == null || fb.isEmpty)) continue;
      report.writeln('## ${pc.caseId} (${pc.difficulty})');
      if (done != null) {
        final d = jsonDecode(done);
        report.writeln(
            '   tiempo: ${d['time']}s · errores: ${d['errors']} · ${d['date']}');
      }
      if (fb != null && fb.isNotEmpty) report.writeln('   notas: $fb');
      report.writeln();
    }
    await Clipboard.setData(ClipboardData(text: report.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Feedback copiado al portapapeles — pégalo en el chat '
              'de Claude para calibrar el generador')));
    }
  }
}

class _CaseCard extends StatelessWidget {
  final PuzzleCase pc;
  final SharedPreferences? prefs;
  const _CaseCard({required this.pc, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final doneRaw = prefs?.getString('done:${pc.caseId}');
    final done = doneRaw == null ? null : jsonDecode(doneRaw);
    final number = pc.caseId.split('-s').last;

    return InkWell(
      onTap: () => context.go('/play/${pc.caseId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Brand.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: done != null ? Brand.success : Brand.gold.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Caso $number',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (done != null)
                  const Icon(Icons.check_circle,
                      color: Brand.success, size: 20),
                if (pc.hasWeapon)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: 'Incluye arma homicida',
                      child: Text('🗡', style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(pc.map.nameEs,
                style: const TextStyle(color: Brand.muted, fontSize: 13)),
            Text(
                '${pc.map.size}×${pc.map.size} · ${pc.characters.length} personajes · ${pc.clues.length} pistas',
                style: const TextStyle(color: Brand.muted, fontSize: 13)),
            if (done != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    'Resuelto en ${done['time']}s · ${done['errors']} errores',
                    style:
                        const TextStyle(color: Brand.success, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
