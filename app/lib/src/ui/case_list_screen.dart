/// Camino de casos (pase Duo 2026-07-11): los casos del banco de pruebas se
/// recorren como un camino de nodos en zigzag, agrupados por sección de
/// dificultad. Conserva la instrumentación de playtest (progreso guardado y
/// exportar feedback).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../data/case_repository.dart';
import 'duo_widgets.dart';

final prefsProvider =
    FutureProvider<SharedPreferences>((_) => SharedPreferences.getInstance());

class CaseListScreen extends ConsumerWidget {
  const CaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(casesProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Duo.background,
      body: cases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando casos: $e')),
        data: (list) {
          final done = <String, Map<String, dynamic>>{};
          for (final pc in list) {
            final raw = prefs?.getString('done:${pc.caseId}');
            if (raw != null) done[pc.caseId] = jsonDecode(raw);
          }
          // Nodo actual = primer caso sin resolver en el orden del camino.
          final currentId = list
              .where((pc) => !done.containsKey(pc.caseId))
              .map((pc) => pc.caseId)
              .firstOrNull;

          final sections = <String, List<PuzzleCase>>{};
          for (final pc in list) {
            sections.putIfAbsent(pc.difficulty, () => []).add(pc);
          }

          return Column(
            children: [
              _TopBar(
                solved: done.length,
                total: list.length,
                onCopyFeedback: () => _copyFeedback(context, ref),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 60),
                  children: [
                    for (final (i, e) in sections.entries.indexed) ...[
                      _SectionBanner(
                        index: i + 1,
                        difficulty: e.key,
                        size: e.value.first.map.size,
                        count: e.value.length,
                      ),
                      _PathSection(
                        cases: e.value,
                        done: done,
                        currentId: currentId,
                      ),
                    ],
                  ],
                ),
              ),
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

/// Barra superior fija: marca + progreso + exportar feedback.
class _TopBar extends StatelessWidget {
  final int solved;
  final int total;
  final VoidCallback onCopyFeedback;

  const _TopBar(
      {required this.solved,
      required this.total,
      required this.onCopyFeedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      decoration: const BoxDecoration(
        color: Duo.background,
        border: Border(bottom: BorderSide(color: Duo.border, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text('ENIGMATRIX',
                style: Duo.font(20,
                    weight: FontWeight.w900,
                    color: Duo.gold,
                    spacing: 3)),
            const Spacer(),
            DuoChip(
                icon: Icons.check_circle,
                text: '$solved / $total',
                color: solved == total ? Duo.green : Duo.text),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Copiar feedback de playtest',
              child: InkWell(
                onTap: onCopyFeedback,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Duo.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Duo.border, width: 2),
                  ),
                  child:
                      const Icon(Icons.copy_all, size: 18, color: Duo.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de sección estilo unidad: color de la dificultad, título y datos.
class _SectionBanner extends StatelessWidget {
  final int index;
  final String difficulty;
  final int size;
  final int count;

  const _SectionBanner(
      {required this.index,
      required this.difficulty,
      required this.size,
      required this.count});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.fromLTRB(20, 26, 20, 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: duoDarken(color),
                offset: const Offset(0, 5),
                blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SECCIÓN $index',
                      style: Duo.font(12,
                          color: Colors.white.withValues(alpha: .85),
                          spacing: 2)),
                  const SizedBox(height: 2),
                  Text(
                      '${difficulty[0].toUpperCase()}${difficulty.substring(1)}'
                      ' · tablero $size×$size',
                      style: Duo.font(19,
                          weight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count casos',
                  style: Duo.font(13, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Camino en zigzag de una sección.
class _PathSection extends StatelessWidget {
  final List<PuzzleCase> cases;
  final Map<String, Map<String, dynamic>> done;
  final String? currentId;

  const _PathSection(
      {required this.cases, required this.done, required this.currentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, pc) in cases.indexed)
          Padding(
            // El desplazamiento en X sigue una onda: 0, 1, 2, 1, 0, -1, -2…
            padding: EdgeInsets.only(top: i == 0 ? 18 : 12),
            child: Transform.translate(
              offset: Offset(_waveOffset(i) * 66, 0),
              child: _CaseNode(
                pc: pc,
                number: i + 1,
                doneInfo: done[pc.caseId],
                isCurrent: pc.caseId == currentId,
              ),
            ),
          ),
      ],
    );
  }

  double _waveOffset(int i) {
    const pattern = [0.0, 1.0, 2.0, 1.0, 0.0, -1.0, -2.0, -1.0];
    return pattern[i % pattern.length];
  }
}

/// Nodo del camino: círculo gordito 3D. Verde-dificultad si está resuelto,
/// coloreado con anillo y burbuja EMPEZAR si es el actual, gris si está
/// pendiente. Todos son jugables (banco de pruebas).
class _CaseNode extends StatefulWidget {
  final PuzzleCase pc;
  final int number;
  final Map<String, dynamic>? doneInfo;
  final bool isCurrent;

  const _CaseNode(
      {required this.pc,
      required this.number,
      required this.doneInfo,
      required this.isCurrent});

  @override
  State<_CaseNode> createState() => _CaseNodeState();
}

class _CaseNodeState extends State<_CaseNode>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  /// Solo el nodo actual anima su burbuja EMPEZAR; los demás no crean ticker.
  AnimationController? _bounce;

  @override
  void initState() {
    super.initState();
    _syncBounce();
  }

  @override
  void didUpdateWidget(covariant _CaseNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBounce();
  }

  void _syncBounce() {
    if (widget.isCurrent && _bounce == null) {
      _bounce = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);
    } else if (!widget.isCurrent && _bounce != null) {
      _bounce!.dispose();
      _bounce = null;
    }
  }

  @override
  void dispose() {
    _bounce?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.doneInfo != null;
    final diffColor = difficultyColor(widget.pc.difficulty);
    final nodeColor = isDone || widget.isCurrent ? diffColor : Duo.lockedNode;
    const nodeSize = 72.0;
    const edge = 7.0;

    final circle = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showCaseSheet(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: EdgeInsets.only(top: _pressed ? edge : 0),
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          color: nodeColor,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? const []
              : [
                  BoxShadow(
                      color: duoDarken(nodeColor),
                      offset: const Offset(0, edge),
                      blurRadius: 0),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isDone ? Icons.check_rounded : Icons.search_rounded,
              color: isDone || widget.isCurrent
                  ? Colors.white
                  : Duo.muted,
              size: 34,
            ),
            if (widget.pc.hasWeapon)
              Positioned(
                right: 10,
                top: 10,
                child: Icon(Icons.colorize,
                    size: 14,
                    color: Colors.white.withValues(alpha: .85)),
              ),
            Positioned(
              bottom: 10,
              child: Text('${widget.number}',
                  style: Duo.font(11,
                      color: (isDone || widget.isCurrent)
                          ? Colors.white.withValues(alpha: .8)
                          : Duo.muted)),
            ),
          ],
        ),
      ),
    );

    // El nodo actual lleva anillo y burbuja EMPEZAR flotante.
    final node = widget.isCurrent
        ? Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Duo.border, width: 4),
            ),
            child: circle,
          )
        : circle;

    if (!widget.isCurrent) return node;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _bounce!,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -3 * math.sin(_bounce!.value * math.pi)),
            child: child,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Duo.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Duo.border, width: 2),
            ),
            child: Text('EMPEZAR',
                style: Duo.font(13, color: diffColor, spacing: 1.5)),
          ),
        ),
        const SizedBox(height: 6),
        node,
      ],
    );
  }

  void _showCaseSheet(BuildContext context) {
    final pc = widget.pc;
    final diffColor = difficultyColor(pc.difficulty);
    final done = widget.doneInfo;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Duo.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: Duo.border,
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Caso ${widget.number} — ${pc.map.nameEs}',
                style: Duo.font(21, weight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DuoChip(
                    icon: Icons.speed,
                    text: pc.difficulty,
                    color: diffColor),
                DuoChip(
                    icon: Icons.grid_on,
                    text: '${pc.map.size}×${pc.map.size}'),
                DuoChip(
                    icon: Icons.group_outlined,
                    text: '${pc.characters.length} sospechosos'),
                DuoChip(icon: Icons.search, text: '${pc.clues.length} pistas'),
                if (pc.hasWeapon)
                  const DuoChip(
                      icon: Icons.colorize,
                      text: 'arma homicida',
                      color: Duo.gold),
              ],
            ),
            if (done != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                    '✓ Resuelto en ${done['time']}s · ${done['errors']} '
                    'errores',
                    style: Duo.font(14, color: Duo.green)),
              ),
            const SizedBox(height: 20),
            DuoButton(
              label: done != null ? 'Jugar de nuevo' : 'Jugar',
              color: diffColor,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/play/${pc.caseId}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
