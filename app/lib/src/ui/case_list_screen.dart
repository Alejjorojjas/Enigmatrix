/// Tablero de expedientes (pase Enx 2026-07-11): los casos se recorren como
/// fichas de expediente sobre un camino en culebrita, unidas por un hilo
/// carmesí punteado que sigue la curva, agrupadas por carpeta de dificultad.
/// Incluye selector de ambiente de color para comparar paletas en vivo.
/// Conserva la instrumentación de playtest.
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
import 'tutorial_dialog.dart';

final prefsProvider =
    FutureProvider<SharedPreferences>((_) => SharedPreferences.getInstance());

/// Altura fija de cada fila del camino (permite que el hilo conozca la
/// posición exacta de cada ficha).
const _rowHeight = 124.0;

/// Alto del contenido de cada fila (etiqueta + ficha, ficha abajo).
const _rowContent = 118.0;

/// Centro vertical de la ficha dentro de su fila.
const _tileCenterY = _rowContent - 39.0;

/// Espacio superior de cada tablero.
const _boardTopPad = 6.0;

/// Desplazamiento horizontal de la culebrita: seno con período de 6 fichas.
double _snake(int i) => math.sin(i * math.pi / 3);

class CaseListScreen extends ConsumerStatefulWidget {
  const CaseListScreen({super.key});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  bool _tutorialChecked = false;

  void _maybeShowTutorial(SharedPreferences prefs) {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    if (prefs.getBool(tutorialSeenKey) ?? false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showTutorialDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(casesProvider);
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final pal = ref.watch(paletteProvider);
    if (prefs != null) _maybeShowTutorial(prefs);

    return Scaffold(
      backgroundColor: pal.background,
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

/// Barra superior fija: marca + progreso + paleta + exportar feedback.
class _TopBar extends ConsumerWidget {
  final int solved;
  final int total;
  final VoidCallback onCopyFeedback;

  const _TopBar(
      {required this.solved,
      required this.total,
      required this.onCopyFeedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ref.watch(paletteProvider);

    Widget squareAction(
            {required IconData icon,
            required Color color,
            required String tooltip,
            required VoidCallback onTap}) =>
        Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pal.border, width: 2),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      decoration: BoxDecoration(
        color: pal.background,
        border: Border(bottom: BorderSide(color: pal.border, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () => context.go('/home'),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_back_rounded,
                    size: 24, color: Enx.goldInk),
              ),
            ),
            const SizedBox(width: 6),
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
              child: const Icon(Icons.search_rounded,
                  size: 18, color: Enx.goldInk),
            ),
            const SizedBox(width: 10),
            Text('Enigmatrix',
                style: Enx.display(22, color: Enx.goldInk, spacing: .5)),
            const Spacer(),
            EnxChip(
                icon: Icons.folder_special_rounded,
                text: '$solved / $total',
                color: solved == total ? Enx.green : Enx.text),
            const SizedBox(width: 8),
            squareAction(
              icon: Icons.help_outline_rounded,
              color: Enx.goldInk,
              tooltip: 'Cómo jugar',
              onTap: () => showTutorialDialog(context),
            ),
            const SizedBox(width: 8),
            squareAction(
              icon: Icons.copy_all,
              color: Enx.blue,
              tooltip: 'Copiar feedback de playtest',
              onTap: onCopyFeedback,
            ),
          ],
        ),
      ),
    );
  }

}

/// Cabecera de sección con forma de carpeta de expediente: pestaña de color
/// arriba y cuerpo oscuro con el detalle.
class _CaseFolderHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ref.watch(paletteProvider);
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
                  color: pal.surface,
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
                          style: Enx.display(18)),
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

/// Tablero de evidencias de una sección: hilo carmesí punteado que serpentea
/// siguiendo la culebrita de fichas.
class _EvidenceBoard extends StatelessWidget {
  final List<PuzzleCase> cases;
  final Map<String, Map<String, dynamic>> done;
  final String? currentId;

  const _EvidenceBoard(
      {required this.cases, required this.done, required this.currentId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Amplitud de la culebrita limitada por el ancho disponible.
        final amplitude =
            math.min(120.0, math.max(0.0, box.maxWidth / 2 - 70));
        final height = _boardTopPad + cases.length * _rowHeight + 10;

        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreadPainter(
                      count: cases.length, amplitude: amplitude),
                ),
              ),
              for (final (i, pc) in cases.indexed)
                Positioned(
                  top: _boardTopPad + i * _rowHeight,
                  child: Transform.translate(
                    offset: Offset(_snake(i) * amplitude, 0),
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
        );
      },
    );
  }
}

/// Hilo punteado que pasa por el centro de cada ficha, con curvas suaves
/// entre una y la siguiente — la cuerda roja del corcho de detective.
class _ThreadPainter extends CustomPainter {
  final int count;
  final double amplitude;

  _ThreadPainter({required this.count, required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final cx = size.width / 2;

    Offset center(int i) => Offset(cx + _snake(i) * amplitude,
        _boardTopPad + i * _rowHeight + _tileCenterY);

    // Curva suave: cúbicas con controles verticales a mitad de camino.
    final path = Path()..moveTo(center(0).dx, center(0).dy);
    for (var i = 1; i < count; i++) {
      final a = center(i - 1);
      final b = center(i);
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }

    final paint = Paint()
      ..color = Enx.crimson.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Punteado a mano sobre la curva.
    const dash = 9.0, gap = 9.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) =>
      old.count != count || old.amplitude != amplitude;
}

/// Ficha de expediente: cuadrado redondeado inclinado con efecto 3D.
/// Resuelta = color de dificultad con check; actual = borde dorado con
/// etiqueta SIGUIENTE CASO; pendiente = carpeta archivada oscura.
/// Todas son jugables (banco de pruebas).
class _CaseFile extends ConsumerStatefulWidget {
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
  ConsumerState<_CaseFile> createState() => _CaseFileState();
}

class _CaseFileState extends ConsumerState<_CaseFile>
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
    final pal = ref.watch(paletteProvider);
    final isDone = widget.doneInfo != null;
    final diffColor = difficultyColor(widget.pc.difficulty);
    final fileColor = isDone
        ? diffColor
        : widget.isCurrent
            ? pal.surfaceHigh
            : pal.lockedNode;
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
                      ? Enx.goldInk
                      : pal.muted,
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
                          : pal.muted,
                      spacing: .5)),
            ),
          ],
        ),
      ),
    );

    final tilted = Transform.rotate(angle: widget.tilt, child: tile);

    if (!widget.isCurrent) {
      // Reserva el mismo alto que la ficha actual para que la fila sea fija.
      return SizedBox(
          height: _rowContent,
          child: Align(alignment: Alignment.bottomCenter, child: tilted));
    }

    // La ficha actual lleva una etiqueta de papel que rebota.
    return SizedBox(
      height: _rowContent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
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
      ),
    );
  }

  void _showCaseSheet(BuildContext context) {
    final pc = widget.pc;
    final diffColor = difficultyColor(pc.difficulty);
    final done = widget.doneInfo;
    final pal = ref.read(paletteProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pal.surface,
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
                    color: pal.border,
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
