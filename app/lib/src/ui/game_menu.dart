/// Menú de la partida y hojas inferiores: acciones secundarias (rehacer,
/// limpiar, Mapa/Notas, Auto-X, aspecto), pista completa y leyenda. Todo sale
/// de la paleta de la piel activa.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/app_settings.dart';
import '../game/game_controller.dart';
import 'appearance_picker.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';

/// Textos del menú y de las hojas (centralizados para traducir en 4.3).
abstract final class MenuTexts {
  static const title = 'Más acciones';
  static const redo = 'Rehacer';
  static const clear = 'Limpiar tablero';
  static const clearTitle = '¿Limpiar tablero?';
  static const clearBody =
      'Se borran las marcas del tablero y de las pistas. '
      'El tiempo y los errores se mantienen.';
  static const cancel = 'Cancelar';
  static const clearConfirm = 'Limpiar';
  static const view = 'Vista del tablero';
  static const viewMap = 'Mapa';
  static const viewNotes = 'Notas';
  static const autoX = 'Auto-X';
  static const autoXHelp =
      'Al confirmar a alguien, tacha su fila y columna automáticamente';
  static const legend = 'Leyenda y reglas';
  static const fps = 'Medidor de FPS (pruebas)';
  static const clueMark = 'Marca de la pista';
  static const markNormal = 'Normal';
  static const markHighlight = 'Destacar';
  static const markStrike = 'Tachar';
}

/// Abre una hoja inferior que se pinta con la piel y el modo de AHORA: si el
/// jugador los cambia con la hoja abierta (menú), la hoja cambia con ellos.
Future<void> _showThemedSheet(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (ctx) => _LiveThemedSheet(child: builder(ctx)),
  );
}

class _LiveThemedSheet extends ConsumerWidget {
  const _LiveThemedSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinId = ref.watch(settingsProvider.select((s) => s.skinId));
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final brightness = resolveBrightness(
      mode,
      MediaQuery.platformBrightnessOf(context),
    );
    return Theme(
      data: SkinUi.theme(skinId, brightness),
      child: Builder(
        builder: (context) {
          final p = context.pal;
          return Material(
            color: p.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              side: BorderSide(color: p.line, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textDim.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Abre el menú de acciones secundarias de la partida.
Future<void> showGameMenu(BuildContext context, PuzzleCase pc) =>
    _showThemedSheet(context, (_) => GameMenuSheet(pc: pc));

class GameMenuSheet extends ConsumerWidget {
  const GameMenuSheet({super.key, required this.pc});

  final PuzzleCase pc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(
      gameControllerProvider(pc).select(
        (s) => (s.canRedo, s.board.isEmpty, s.mapMode, s.autoX, s.solved),
      ),
    );
    final (canRedo, boardEmpty, mapMode, autoX, solved) = s;
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final settings = ref.watch(settingsProvider);

    Widget row({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      Key? key,
    }) {
      final fg = onTap == null ? p.textDim : p.text;
      return InkWell(
        key: key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SkinUi.minTouch),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MenuTexts.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            const SizedBox(height: 6),
            row(
              key: const ValueKey('menu-rehacer'),
              icon: Icons.redo,
              label: MenuTexts.redo,
              onTap: canRedo && !solved
                  ? () {
                      controller.redo();
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
            row(
              key: const ValueKey('menu-limpiar'),
              icon: Icons.cleaning_services_outlined,
              label: MenuTexts.clear,
              onTap: boardEmpty || solved
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(MenuTexts.clearTitle),
                          content: const Text(MenuTexts.clearBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(MenuTexts.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(MenuTexts.clearConfirm),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        controller.clearBoard();
                        nav.pop();
                      }
                    },
            ),
            const SizedBox(height: 8),
            Text(
              MenuTexts.view,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                key: const ValueKey('menu-vista'),
                showSelectedIcon: false,
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: true, label: Text(MenuTexts.viewMap)),
                  ButtonSegment(value: false, label: Text(MenuTexts.viewNotes)),
                ],
                selected: {mapMode},
                onSelectionChanged: (sel) {
                  if (sel.first != mapMode) controller.toggleMapMode();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              key: const ValueKey('menu-autox'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                MenuTexts.autoX,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
              subtitle: Text(
                MenuTexts.autoXHelp,
                style: TextStyle(fontSize: 13, color: p.textDim),
              ),
              value: autoX,
              onChanged: (_) => controller.toggleAutoX(),
            ),
            row(
              key: const ValueKey('menu-leyenda'),
              icon: Icons.menu_book_rounded,
              label: MenuTexts.legend,
              onTap: () {
                Navigator.of(context).pop();
                showLegendSheet(context, pc);
              },
            ),
            const Divider(height: 24),
            const AppearancePicker(),
            const SizedBox(height: 4),
            SwitchListTile(
              key: const ValueKey('menu-fps'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                MenuTexts.fps,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.textDim,
                ),
              ),
              value: settings.fpsMeter,
              onChanged: ref.read(settingsProvider.notifier).setFpsMeter,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- pista completa (H-56) ---------------------------------------------------

/// Abre la pista completa de un personaje en una hoja inferior (H-56): letra
/// de 16 px o más, nombre del personaje y botones para fijar la marca.
Future<void> showFullClueSheet(
  BuildContext context,
  PuzzleCase pc,
  String charId,
  int clueIndex,
) => _showThemedSheet(
  context,
  (_) => _FullClueSheet(pc: pc, charId: charId, clueIndex: clueIndex),
);

class _FullClueSheet extends ConsumerWidget {
  const _FullClueSheet({
    required this.pc,
    required this.charId,
    required this.clueIndex,
  });

  final PuzzleCase pc;
  final String charId;
  final int clueIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final mark = ref.watch(
      gameControllerProvider(pc).select((s) => s.clueMarks[clueIndex]),
    );
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final clue = pc.clues[clueIndex];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pc.character(charId).nameEs,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: mark == ClueMark.highlighted
                    ? Color.alphaBlend(
                        p.accent.withValues(alpha: 0.22),
                        p.surfaceAlt,
                      )
                    : p.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: mark == ClueMark.highlighted ? p.accent : p.line,
                ),
              ),
              child: Text(
                clue.cardTextEs(pc.map, pc.names),
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: mark == ClueMark.struck ? p.textDim : p.text,
                  fontWeight: mark == ClueMark.highlighted
                      ? FontWeight.w700
                      : FontWeight.w500,
                  decoration: mark == ClueMark.struck
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              MenuTexts.clueMark,
              style: TextStyle(fontSize: 14, color: p.textDim),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ClueMark>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, 52)),
                ),
                segments: const [
                  ButtonSegment(
                    value: ClueMark.normal,
                    icon: Icon(Icons.radio_button_unchecked),
                    label: Text(MenuTexts.markNormal),
                  ),
                  ButtonSegment(
                    value: ClueMark.highlighted,
                    icon: Icon(Icons.star_rounded),
                    label: Text(MenuTexts.markHighlight),
                  ),
                  ButtonSegment(
                    value: ClueMark.struck,
                    icon: Icon(Icons.strikethrough_s),
                    label: Text(MenuTexts.markStrike),
                  ),
                ],
                selected: {mark},
                onSelectionChanged: (sel) =>
                    controller.setClueMark(clueIndex, sel.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- leyenda ------------------------------------------------------------------

/// Abre la leyenda: información adicional, habitaciones, muebles y reglas.
Future<void> showLegendSheet(BuildContext context, PuzzleCase pc) =>
    _showThemedSheet(context, (_) => LegendSheet(pc: pc));

class LegendSheet extends ConsumerWidget {
  const LegendSheet({super.key, required this.pc});

  final PuzzleCase pc;

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ChromeBox(
        color: p.surfaceAlt,
        radius: 14,
        depth: 2.5,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: p.accent,
                  letterSpacing: 1.5,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final marks = ref.watch(
      gameControllerProvider(pc).select((s) => s.clueMarks),
    );
    final controller = ref.read(gameControllerProvider(pc).notifier);
    final extras = pc.extraClues;
    final body = TextStyle(fontSize: 14, height: 1.3, color: p.text);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (extras.isNotEmpty)
              _section(
                context,
                title: 'INFORMACIÓN ADICIONAL',
                children: [
                  for (final e in extras)
                    Builder(
                      builder: (context) {
                        final i = pc.clues.indexOf(e);
                        return InkWell(
                          onTap: () => controller.cycleClue(i),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: SkinUi.minTouch - 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '· ${e.textEs(pc.map, pc.names)}',
                                style: switch (marks[i]) {
                                  ClueMark.normal => body,
                                  ClueMark.highlighted => body.copyWith(
                                    color: p.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  ClueMark.struck => body.copyWith(
                                    color: p.textDim,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            _section(
              context,
              title: 'HABITACIONES',
              children: [
                for (final area in pc.map.areas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${area.nameEs}'
                      '${pc.map.weaponsInArea(area.id).isEmpty ? '' : '  ·  armas: ${pc.map.weaponsInArea(area.id).map((w) => w.nameEs).join(', ')}'}',
                      style: body,
                    ),
                  ),
              ],
            ),
            _section(
              context,
              title: 'MUEBLES',
              children: [
                Text(
                  'Pisables: puedes colocar gente encima. '
                  'Los demás bloquean su casilla.',
                  style: TextStyle(fontSize: 13, color: p.textDim),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final type in {for (final o in pc.map.objects) o.type})
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.line),
                        ),
                        child: Text(
                          '${type.nameEs}${type.standable ? ' ◦' : ''}',
                          style: TextStyle(fontSize: 13, color: p.text),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '◦ = pisable',
                  style: TextStyle(fontSize: 13, color: p.textDim),
                ),
              ],
            ),
            _section(
              context,
              title: 'REGLAS',
              children: [
                Text(
                  'Una persona por fila y por columna. El asesino quedó a '
                  'solas con la víctima en la misma habitación. Ubica a '
                  'todos, incluida la víctima.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: p.textDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
