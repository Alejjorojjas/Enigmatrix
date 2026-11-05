/// Camino de casos: los casos se recorren como fichas de expediente sobre un
/// camino en culebrita, unidas por un hilo punteado que sigue la curva,
/// agrupadas por carpeta de dificultad. Todo el color sale de la piel y el
/// modo activos. Experto y Élite se muestran "Próximamente" y no se abren
/// (ADR-0014). Muestra los 10 casos de la campaña "mansion" en su orden, con
/// título y premisa, y conserva "En curso" para las partidas guardadas. Los 20
/// casos del banco de pruebas y el reporte de feedback viven en Configuración.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_repository.dart';
import '../game/game_config.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'tutorial_coach.dart';
import 'tutorial_dialog.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

final prefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

/// Textos de la lista de casos (centralizados para traducir en la ronda 4.3).
abstract final class CaseListTexts {
  static const title = 'Casos';
  static const folder = 'EXPEDIENTE';
  static const nextCase = 'SIGUIENTE CASO';
  static const inProgress = 'En curso';
  static const tutorial = 'TUTORIAL';
  static const tutorialBody =
      'Caso de práctica paso a paso (no cuenta como Caso 1)';
  static const tutorialDone = 'Completado: puedes repetirlo';
  static const start = 'Empezar';
  static const repeat = 'Repetir';
  static const soonBody = 'Llega en una próxima actualización.';
  static const howToPlay = 'Cómo jugar';
  static const reopen = 'Reabrir caso';
  static const keepPlaying = 'Continuar';
  static const investigate = 'Investigar';
}

/// Altura fija de cada fila del camino (permite que el hilo conozca la
/// posición exacta de cada ficha).
const _rowHeight = 128.0;

/// Alto del contenido de cada fila (etiqueta + ficha, ficha abajo).
const _rowContent = 122.0;

/// Lado del cuadro de cada ficha.
const _tileSize = 78.0;

/// Centro vertical de la ficha dentro de su fila.
const _tileCenterY = _rowContent - _tileSize / 2;

/// Espacio superior de cada tablero.
const _boardTopPad = 6.0;

/// Desplazamiento horizontal de la culebrita: seno con período de 6 fichas.
double _snake(int i) => math.sin(i * math.pi / 3);

IconData _difficultyIcon(String d) => switch (d) {
  'principiante' => Icons.eco_rounded,
  'casual' => Icons.search_rounded,
  'intermedio' => Icons.psychology_rounded,
  'experto' => Icons.whatshot_rounded,
  'elite' => Icons.diamond_rounded,
  _ => Icons.folder_rounded,
};

class CaseListScreen extends ConsumerStatefulWidget {
  const CaseListScreen({super.key});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(campaignProvider(kMundoMansion));
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final p = context.pal;

    return Scaffold(
      body: ScreenBackground(
        child: cases.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando casos: $e',
                textAlign: TextAlign.center,
                style: context.body(16, color: p.danger),
              ),
            ),
          ),
          data: (all) {
            // Solo los casos de la V1: Experto y Élite no se abren.
            final config = ref.watch(gameConfigProvider);
            final list = playableCases(all, config: config);
            // Número de cada caso en la campaña (Nº 1 a Nº 10).
            final numberOf = {
              for (final (i, pc) in list.indexed) pc.caseId: i + 1,
            };
            final done = <String, Map<String, dynamic>>{};
            for (final pc in list) {
              final raw = prefs?.getString('done:${pc.caseId}');
              if (raw != null) done[pc.caseId] = jsonDecode(raw);
            }
            // Partidas abiertas y sin terminar (clave game:<id>, solo lectura).
            final inProgress = <String, SavedGameInfo>{};
            for (final pc in list) {
              if (done.containsKey(pc.caseId)) continue;
              final g = prefs?.getString('game:${pc.caseId}');
              if (g != null) inProgress[pc.caseId] = SavedGameInfo.fromRaw(g);
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

            var folderNo = 0;
            return Column(
              children: [
                _TopBar(solved: done.length, total: list.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 60),
                    children: [
                      _TutorialNode(
                        played: prefs?.getBool(tutorialPlayedKey) ?? false,
                      ),
                      for (final d in kAllDifficulties)
                        if (config.isV1Difficulty(d))
                          if (sections[d] case final cs?) ...[
                            _CaseFolderHeader(
                              index: ++folderNo,
                              difficulty: d,
                              size: cs.first.map.size,
                              count: cs.length,
                              solved: cs
                                  .where((pc) => done.containsKey(pc.caseId))
                                  .length,
                            ),
                            _EvidenceBoard(
                              cases: cs,
                              done: done,
                              inProgress: inProgress,
                              currentId: currentId,
                              numberOf: numberOf,
                            ),
                          ] else
                            const SizedBox.shrink()
                        else
                          _SoonFolderHeader(index: ++folderNo, difficulty: d),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Barra superior fija: volver, título, progreso y ayuda.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.solved, required this.total});

  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    Widget square(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
      message: tooltip,
      child: ChromeButton(
        onTap: onTap,
        radius: 14,
        color: p.surface,
        semanticsLabel: tooltip,
        padding: EdgeInsets.zero,
        minSize: const Size(SkinUi.minTouch, SkinUi.minTouch),
        child: Icon(icon, size: 24, color: p.text),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(bottom: BorderSide(color: p.line, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              square(
                Icons.arrow_back_rounded,
                'Volver',
                () => context.go('/home'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CaseListTexts.title,
                    style: context.display(22, spacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InfoChip(
                icon: Icons.folder_special_rounded,
                text: '$solved / $total',
                color: solved == total ? p.good : p.text,
              ),
              const SizedBox(width: 6),
              square(
                Icons.help_outline_rounded,
                CaseListTexts.howToPlay,
                () => showTutorialDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabecera de una carpeta de dificultad: pestaña con el número de
/// expediente y tarjeta con ícono de color, nombre y barra de progreso.
class _CaseFolderHeader extends StatelessWidget {
  const _CaseFolderHeader({
    required this.index,
    required this.difficulty,
    required this.size,
    required this.count,
    required this.solved,
  });

  final int index;
  final String difficulty;
  final int size;
  final int count;
  final int solved;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = p.difficulty(difficulty);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FolderTab(
                text: '${CaseListTexts.folder} Nº$index',
                color: color,
              ),
              ChromeBox(
                color: p.surface,
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconTile(
                          icon: _difficultyIcon(difficulty),
                          color: color,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                difficultyName(difficulty),
                                style: context.display(21),
                              ),
                              Text(
                                'Tablero $size×$size',
                                style: context.body(
                                  14,
                                  weight: FontWeight.w600,
                                  color: p.softText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$solved / $count',
                          style: context.display(18, color: p.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppProgressBar(
                      value: count == 0 ? 0 : solved / count,
                      color: color,
                      semanticsLabel:
                          'Progreso de ${difficultyName(difficulty)}',
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

/// Carpeta de una dificultad que aún no llega (Experto y Élite): se ve, pero
/// no se abre.
class _SoonFolderHeader extends StatelessWidget {
  const _SoonFolderHeader({required this.index, required this.difficulty});

  final int index;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
          child: Opacity(
            opacity: 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FolderTab(
                  text: '${CaseListTexts.folder} Nº$index',
                  color: p.surfaceAlt,
                  textColor: p.textDim,
                ),
                ChromeBox(
                  color: p.surface,
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconTile(
                        icon: Icons.lock_rounded,
                        color: p.surfaceAlt,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficultyName(difficulty),
                              style: context.display(21),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: SoonBadge(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CaseListTexts.soonBody,
                              style: context.body(
                                13,
                                weight: FontWeight.w600,
                                color: p.softText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderTab extends StatelessWidget {
  const _FolderTab({required this.text, required this.color, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(left: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border.all(color: p.line, width: 1.5),
      ),
      child: Text(
        text,
        style: context.body(
          13,
          weight: FontWeight.w800,
          color: textColor ?? p.onColor(color),
          spacing: 1.6,
        ),
      ),
    );
  }
}

/// Tablero de evidencias de una sección: hilo punteado que serpentea
/// siguiendo la culebrita de fichas.
class _EvidenceBoard extends StatelessWidget {
  const _EvidenceBoard({
    required this.cases,
    required this.done,
    required this.inProgress,
    required this.currentId,
    required this.numberOf,
  });

  final Map<String, int> numberOf;
  final List<PuzzleCase> cases;
  final Map<String, Map<String, dynamic>> done;
  final Map<String, SavedGameInfo> inProgress;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final threadColor = context.pal.danger.withValues(alpha: 0.45);
    return LayoutBuilder(
      builder: (context, box) {
        // Amplitud de la culebrita limitada por el ancho disponible.
        final amplitude = math.min(110.0, math.max(0.0, box.maxWidth / 2 - 72));
        final height = _boardTopPad + cases.length * _rowHeight + 10;

        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreadPainter(
                    count: cases.length,
                    amplitude: amplitude,
                    color: threadColor,
                  ),
                ),
              ),
              for (final (i, pc) in cases.indexed)
                Positioned(
                  top: _boardTopPad + i * _rowHeight,
                  child: Transform.translate(
                    offset: Offset(_snake(i) * amplitude, 0),
                    child: _CaseFile(
                      pc: pc,
                      number: numberOf[pc.caseId] ?? i + 1,
                      tilt: (i.isEven ? -1 : 1) * 0.045,
                      doneInfo: done[pc.caseId],
                      savedGame: inProgress[pc.caseId],
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
/// entre una y la siguiente.
class _ThreadPainter extends CustomPainter {
  _ThreadPainter({
    required this.count,
    required this.amplitude,
    required this.color,
  });

  final int count;
  final double amplitude;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final cx = size.width / 2;

    Offset center(int i) => Offset(
      cx + _snake(i) * amplitude,
      _boardTopPad + i * _rowHeight + _tileCenterY,
    );

    // Curva suave: cúbicas con controles verticales a mitad de camino.
    final path = Path()..moveTo(center(0).dx, center(0).dy);
    for (var i = 1; i < count; i++) {
      final a = center(i - 1);
      final b = center(i);
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Punteado a mano sobre la curva.
    const dash = 9.0, gap = 9.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) =>
      old.count != count || old.amplitude != amplitude || old.color != color;
}

/// Ficha de expediente. Resuelta = color de dificultad con check; actual =
/// color de acento con etiqueta SIGUIENTE CASO; pendiente = carpeta archivada.
class _CaseFile extends ConsumerStatefulWidget {
  const _CaseFile({
    required this.pc,
    required this.number,
    required this.tilt,
    required this.doneInfo,
    this.savedGame,
    required this.isCurrent,
  });

  final PuzzleCase pc;
  final int number;
  final double tilt;
  final Map<String, dynamic>? doneInfo;
  final SavedGameInfo? savedGame;
  final bool isCurrent;

  @override
  ConsumerState<_CaseFile> createState() => _CaseFileState();
}

class _CaseFileState extends ConsumerState<_CaseFile>
    with SingleTickerProviderStateMixin {
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
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
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
    final p = context.pal;
    final isDone = widget.doneInfo != null;
    final diffColor = p.difficulty(widget.pc.difficulty);
    final fill = isDone
        ? diffColor
        : widget.isCurrent
        ? p.accent
        : p.surfaceAlt;
    final fg = isDone || widget.isCurrent ? p.onColor(fill) : p.textDim;
    final title = caseTitle(widget.pc);

    final tile = SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Center(
        child: ChromeButton(
          onTap: () => _showCaseSheet(context),
          color: fill,
          radius: 22,
          padding: EdgeInsets.zero,
          minSize: const Size(_tileSize - 6, _tileSize - 6),
          semanticsLabel:
              'Caso ${widget.number}: $title'
              '${isDone ? ', cerrado' : ''}',
          child: SizedBox(
            width: _tileSize - 8,
            height: _tileSize - 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: Icon(
                    isDone
                        ? Icons.check_rounded
                        : widget.isCurrent
                        ? Icons.search_rounded
                        : Icons.folder_rounded,
                    color: fg,
                    size: 30,
                  ),
                ),
                if (widget.pc.hasWeapon)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(Icons.colorize, size: 14, color: fg),
                  ),
                Positioned(
                  bottom: 6,
                  child: Text(
                    'Nº ${widget.number}',
                    style: context.body(
                      13,
                      weight: FontWeight.w800,
                      color: fg,
                      spacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final tilted = Transform.rotate(angle: widget.tilt, child: tile);

    if (!widget.isCurrent) {
      // Reserva el mismo alto que la ficha actual para que la fila sea fija.
      return SizedBox(
        height: _rowContent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.savedGame != null) ...[
                _Tag(
                  text:
                      '${CaseListTexts.inProgress} · '
                      '${formatElapsed(widget.savedGame!.elapsed)}',
                ),
                const SizedBox(height: 6),
              ],
              tilted,
            ],
          ),
        ),
      );
    }

    // La ficha actual lleva una etiqueta que rebota.
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
            child: _Tag(
              text: widget.savedGame != null
                  ? 'EN CURSO · ${formatElapsed(widget.savedGame!.elapsed)}'
                  : CaseListTexts.nextCase,
              strong: true,
            ),
          ),
          const SizedBox(height: 6),
          tilted,
        ],
      ),
    );
  }

  void _showCaseSheet(BuildContext context) {
    final pc = widget.pc;
    final p = context.pal;
    final diffColor = p.difficulty(pc.difficulty);
    final done = widget.doneInfo;
    final premise = pc.story?.premise('es');

    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caso Nº${widget.number} — ${caseTitle(pc)}',
            style: ctx.display(22),
          ),
          if (premise != null && premise.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(premise, style: ctx.note(16, color: p.softText)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                icon: Icons.speed_rounded,
                text: difficultyName(pc.difficulty),
                color: diffColor,
              ),
              InfoChip(
                icon: Icons.grid_on_rounded,
                text: '${pc.map.size}×${pc.map.size}',
              ),
              InfoChip(
                icon: Icons.group_outlined,
                text: '${pc.characters.length} sospechosos',
              ),
              InfoChip(
                icon: Icons.search_rounded,
                text: '${pc.clues.length} pistas',
              ),
              if (pc.hasWeapon)
                InfoChip(
                  icon: Icons.colorize,
                  text: 'arma homicida',
                  color: p.medal(0),
                ),
            ],
          ),
          if (done != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Caso cerrado en ${done['time']} s · ${done['errors']} '
                'errores',
                style: ctx.body(15, color: p.good),
              ),
            ),
          if (done == null && widget.savedGame != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'En curso: ${formatElapsed(widget.savedGame!.elapsed)} '
                'jugados · ${widget.savedGame!.errors ?? 0} errores',
                style: ctx.body(15, color: p.accent),
              ),
            ),
          const SizedBox(height: 18),
          AppButton(
            label: done != null
                ? CaseListTexts.reopen
                : widget.savedGame != null
                ? CaseListTexts.keepPlaying
                : CaseListTexts.investigate,
            color: done != null ? diffColor : null,
            onTap: () {
              Navigator.pop(ctx);
              context.go('/play/${pc.caseId}');
            },
          ),
        ],
      ),
    );
  }
}

/// Etiqueta corta sobre una ficha ("En curso", "Siguiente caso").
class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ChromeBox(
      color: strong ? p.pill : p.surface,
      radius: 10,
      depth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(
        text,
        style: context.body(
          13,
          weight: FontWeight.w800,
          color: strong ? p.onPill : p.text,
          spacing: strong ? 1 : 0,
        ),
      ),
    );
  }
}

/// Nodo TUTORIAL: aparece ANTES del Caso Nº1. Abre el caso de práctica
/// propio (assets/tutorial) en modo guiado paso a paso (TutorialCoach): no
/// consume ni cuenta como el Caso 1. Se puede repetir las veces que se quiera.
class _TutorialNode extends StatelessWidget {
  const _TutorialNode({required this.played});

  final bool played;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AppCard(
            accent: p.accent,
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(
                      icon: Icons.school_rounded,
                      color: p.world(3),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel(CaseListTexts.tutorial),
                          Text(
                            CaseListTexts.tutorialBody,
                            style: context.note(16, color: p.text),
                          ),
                          if (played)
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: p.good,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    CaseListTexts.tutorialDone,
                                    style: context.body(
                                      13,
                                      weight: FontWeight.w700,
                                      color: p.good,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: played ? CaseListTexts.repeat : CaseListTexts.start,
                  quiet: played,
                  onTap: () => context.go('/tutorial'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
