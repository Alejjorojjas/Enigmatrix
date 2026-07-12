/// Tablero de expedientes (pase Enx 2026-07-11): los casos se recorren como
/// fichas de expediente clavadas sobre un tablero de evidencias, unidas por
/// un hilo carmesí punteado y agrupadas por carpeta de dificultad. Conserva
/// la instrumentación de playtest (progreso guardado y exportar feedback).
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
import 'enx_style.dart';

final prefsProvider =
    FutureProvider<SharedPreferences>((_) => SharedPreferences.getInstance());

class CaseListScreen extends ConsumerWidget {
  const CaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(casesProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Enx.background,
      body: cases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando casos: $e')),
        data: (list) {
          final done = <String, Map<String, dynamic>>{};
          for (final pc in list) {
            final raw = prefs?.getString('done:${pc.caseId}');
            if (raw != null) done[pc.caseId] = jsonDecode(raw);
          }
          // Ficha actual = primer caso sin resolver en el orden del tablero.
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
                      _CaseFolderHeader(
                        index: i + 1,
                        difficulty: e.key,
                        size: e.value.first.map.size,
                        count: e.value.length,
                        solved: e.value
                            .where((pc) => done.containsKey(pc.caseId))
                            .length,
                      ),
                      _EvidenceBoard(
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
        color: Enx.background,
        border: Border(bottom: BorderSide(color: Enx.border, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Enx.gold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: enxDarken(Enx.gold),
                      offset: const Offset(0, 3),
                      blurRadius: 0),
                ],
              ),
              child:
                  const Icon(Icons.search_rounded, size: 18, color: Enx.goldInk),
            ),
            const SizedBox(width: 10),
            Text('Enigmatrix',
                style: Enx.display(22, color: Enx.gold, spacing: .5)),
            const Spacer(),
            EnxChip(
                icon: Icons.folder_special_rounded,
                text: '$solved / $total',
                color: solved == total ? Enx.green : Enx.text),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Copiar feedback de playtest',
              child: InkWell(
                onTap: onCopyFeedback,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Enx.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Enx.border, width: 2),
                  ),
                  child: const Icon(Icons.copy_all,
                      size: 18, color: Enx.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera de sección con forma de carpeta de expediente: pestaña de color
/// arriba y cuerpo oscuro con el detalle.
class _CaseFolderHeader extends StatelessWidget {
  final int index;
  final String difficulty;
  final int size;
  final int count;
  final int solved;

  const _CaseFolderHeader(
      {required this.index,
      required this.difficulty,
      required this.size,
      required this.count,
      required this.solved});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pestaña de la carpeta.
              Container(
                margin: const EdgeInsets.only(left: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Text('EXPEDIENTE Nº$index',
                    style: Enx.font(11,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        spacing: 2)),
              ),
              // Cuerpo de la carpeta.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Enx.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: enxDarken(color, .35),
                        offset: const Offset(0, 5),
                        blurRadius: 0),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${difficulty[0].toUpperCase()}${difficulty.substring(1)}'
                          ' · tablero $size×$size',
                          style: Enx.display(18, color: Enx.text)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withValues(alpha: .6), width: 1.5),
                      ),
                      child: Text('$solved / $count',
                          style: Enx.font(13, color: color)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablero de evidencias de una sección: hilo punteado carmesí detrás y
/// fichas inclinadas encima.
class _EvidenceBoard extends StatelessWidget {
  final List<PuzzleCase> cases;
  final Map<String, Map<String, dynamic>> done;
  final String? currentId;

  const _EvidenceBoard(
      {required this.cases, required this.done, required this.currentId});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Hilo del tablero de evidencias.
        Positioned.fill(
          child: CustomPaint(painter: _ThreadPainter()),
        ),
        Column(
          children: [
            for (final (i, pc) in cases.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 20 : 14),
                child: Transform.translate(
                  offset: Offset(_waveOffset(i) * 58, 0),
                  child: _CaseFile(
                    pc: pc,
                    number: i + 1,
                    tilt: (i.isEven ? -1 : 1) * 0.045,
                    doneInfo: done[pc.caseId],
                    isCurrent: pc.caseId == currentId,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  double _waveOffset(int i) {
    const pattern = [0.0, 1.0, 1.0, 0.0, -1.0, -1.0];
    return pattern[i % pattern.length];
  }
}

/// Hilo punteado vertical, como la cuerda roja de un corcho de detective.
class _ThreadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Enx.crimson.withValues(alpha: .38)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 9.0, gap = 9.0;
    final x = size.width / 2;
    double y = 6;
    while (y < size.height - 6) {
      canvas.drawLine(
          Offset(x, y), Offset(x, math.min(y + dash, size.height - 6)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ficha de expediente: cuadrado redondeado inclinado con efecto 3D.
/// Resuelta = color de dificultad con check; actual = borde dorado con
/// etiqueta SIGUIENTE CASO; pendiente = carpeta archivada oscura.
/// Todas son jugables (banco de pruebas).
class _CaseFile extends StatefulWidget {
  final PuzzleCase pc;
  final int number;
  final double tilt;
  final Map<String, dynamic>? doneInfo;
  final bool isCurrent;

  const _CaseFile(
      {required this.pc,
      required this.number,
      required this.tilt,
      required this.doneInfo,
      required this.isCurrent});

  @override
  State<_CaseFile> createState() => _CaseFileState();
}

class _CaseFileState extends State<_CaseFile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  /// Solo la ficha actual anima su etiqueta; las demás no crean ticker.
  AnimationController? _bounce;

  @override
  void initState() {
    super.initState();
    _syncBounce();
  }

  @override
  void didUpdateWidget(covariant _CaseFile oldWidget) {
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
    final fileColor = isDone
        ? diffColor
        : widget.isCurrent
            ? Enx.surfaceHigh
            : Enx.lockedNode;
    const fileSize = 78.0;
    const edge = 6.0;

    final tile = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showCaseSheet(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: EdgeInsets.only(top: _pressed ? edge : 0),
        width: fileSize,
        height: fileSize,
        decoration: BoxDecoration(
          color: fileColor,
          borderRadius: BorderRadius.circular(22),
          border: widget.isCurrent
              ? Border.all(color: Enx.gold, width: 3)
              : null,
          boxShadow: _pressed
              ? const []
              : [
                  BoxShadow(
                      color: enxDarken(fileColor),
                      offset: const Offset(0, edge),
                      blurRadius: 0),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isDone
                  ? Icons.check_rounded
                  : widget.isCurrent
                      ? Icons.search_rounded
                      : Icons.folder_rounded,
              color: isDone
                  ? Colors.white
                  : widget.isCurrent
                      ? Enx.gold
                      : Enx.muted,
              size: 32,
            ),
            if (widget.pc.hasWeapon)
              Positioned(
                right: 9,
                top: 9,
                child: Icon(Icons.colorize,
                    size: 13, color: Colors.white.withValues(alpha: .8)),
              ),
            Positioned(
              bottom: 7,
              child: Text('Nº ${widget.number}',
                  style: Enx.font(10,
                      weight: FontWeight.w800,
                      color: isDone
                          ? Colors.white.withValues(alpha: .85)
                          : Enx.muted,
                      spacing: .5)),
            ),
          ],
        ),
      ),
    );

    final tilted = Transform.rotate(angle: widget.tilt, child: tile);

    if (!widget.isCurrent) return tilted;

    // La ficha actual lleva una etiqueta de papel que rebota.
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Enx.paper,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                    color: enxDarken(Enx.paper, .35),
                    offset: const Offset(0, 3),
                    blurRadius: 0),
              ],
            ),
            child: Text('SIGUIENTE CASO',
                style: Enx.font(12,
                    weight: FontWeight.w800,
                    color: Enx.ink,
                    spacing: 1.2)),
          ),
        ),
        const SizedBox(height: 7),
        tilted,
      ],
    );
  }

  void _showCaseSheet(BuildContext context) {
    final pc = widget.pc;
    final diffColor = difficultyColor(pc.difficulty);
    final done = widget.doneInfo;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Enx.surface,
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
                    color: Enx.border,
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Caso Nº${widget.number} — ${pc.map.nameEs}',
                style: Enx.display(20)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EnxChip(
                    icon: Icons.speed,
                    text: pc.difficulty,
                    color: diffColor),
                EnxChip(
                    icon: Icons.grid_on,
                    text: '${pc.map.size}×${pc.map.size}'),
                EnxChip(
                    icon: Icons.group_outlined,
                    text: '${pc.characters.length} sospechosos'),
                EnxChip(icon: Icons.search, text: '${pc.clues.length} pistas'),
                if (pc.hasWeapon)
                  const EnxChip(
                      icon: Icons.colorize,
                      text: 'arma homicida',
                      color: Enx.gold),
              ],
            ),
            if (done != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                    '✓ Caso cerrado en ${done['time']}s · ${done['errors']} '
                    'errores',
                    style: Enx.font(14, color: Enx.green)),
              ),
            const SizedBox(height: 20),
            EnxButton(
              label: done != null ? 'Reabrir caso' : 'Investigar',
              color: done != null ? diffColor : Enx.gold,
              textColor: done != null ? Colors.white : Enx.goldInk,
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
