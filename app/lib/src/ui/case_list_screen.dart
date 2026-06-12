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
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ENIGMATRIX',
                style: TextStyle(
                    fontFamily: Brand.displayFont,
                    fontSize: 30,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                    color: Brand.cream)),
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 2.5,
              width: 130,
              decoration: BoxDecoration(
                  gradient: Brand.goldGradient,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Banco de pruebas · Fase 1',
                  style: TextStyle(
                      fontSize: 12, color: Brand.muted, letterSpacing: 2)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _copyFeedback(context, ref),
            icon: const Icon(Icons.copy_all, color: Brand.goldBright),
            label: const Text('Copiar feedback',
                style: TextStyle(color: Brand.goldBright)),
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
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: difficultyColor(e.key),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: difficultyColor(e.key)
                                      .withValues(alpha: .7),
                                  blurRadius: 8),
                            ]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.key.toUpperCase()} · ${e.value.first.map.size}×${e.value.first.map.size}',
                        style: TextStyle(
                            color: difficultyColor(e.key),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
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

    final diffColor = difficultyColor(pc.difficulty);
    return InkWell(
      onTap: () => context.go('/play/${pc.caseId}'),
      borderRadius: BorderRadius.circular(14),
      hoverColor: Brand.gold.withValues(alpha: .08),
      child: Container(
        width: 235,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Brand.surfaceHigh, Brand.surface],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done != null
                  ? Brand.success.withValues(alpha: .8)
                  : diffColor.withValues(alpha: .45)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: diffColor.withValues(alpha: .6)),
                  ),
                  child: Text('CASO $number',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                          color: diffColor)),
                ),
                const Spacer(),
                if (done != null)
                  const Icon(Icons.check_circle,
                      color: Brand.success, size: 20),
                if (pc.hasWeapon)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: 'Incluye arma homicida',
                      child: Icon(Icons.colorize,
                          size: 16, color: Brand.goldBright),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(pc.map.nameEs,
                style: const TextStyle(
                    fontFamily: Brand.displayFont,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Brand.cream)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.group_outlined,
                    size: 14, color: Brand.muted),
                const SizedBox(width: 4),
                Text('${pc.characters.length}',
                    style:
                        const TextStyle(color: Brand.muted, fontSize: 12.5)),
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 14, color: Brand.muted),
                const SizedBox(width: 4),
                Text('${pc.clues.length} pistas',
                    style:
                        const TextStyle(color: Brand.muted, fontSize: 12.5)),
              ],
            ),
            if (done != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '✓ Resuelto en ${done['time']}s · ${done['errors']} errores',
                    style:
                        const TextStyle(color: Brand.success, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
