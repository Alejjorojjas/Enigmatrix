/// Bandeja de sospechosos: fila de retratos y recuadro con la pista del
/// personaje seleccionado. Los retratos los dibuja la piel activa.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../board/scene/skin.dart';
import '../game/game_controller.dart' show ClueMark;
import 'clue_text.dart';
import 'game_chrome.dart';
import 'layout_metrics.dart';
import 'skin_theme.dart';

/// Aviso de "tocaste a este sospechoso": el retrato se hunde y rebota.
class TrayPulse {
  final int serial;
  final String charId;
  const TrayPulse(this.serial, this.charId);
}

/// Bandeja: fila de retratos y, debajo, el recuadro de la pista. En la
/// distribución compacta (pantallas bajas) la pista queda en una línea y
/// [trailing] (el botón Resolver) va a su lado.
class SuspectPanel extends StatelessWidget {
  const SuspectPanel({
    super.key,
    required this.pc,
    required this.skin,
    required this.pulse,
    required this.selectedChar,
    required this.placed,
    required this.enabled,
    required this.onSelect,
    required this.clueMark,
    required this.onCycleClue,
    required this.onOpenClue,
    this.compact = false,
    this.trailing,
    this.wrapPortraits,
  });

  final PuzzleCase pc;
  final BoardSkin skin;
  final ValueNotifier<TrayPulse?> pulse;
  final String? selectedChar;
  final Set<String> placed;
  final bool enabled;
  final ValueChanged<String> onSelect;

  /// Marca de la pista del sospechoso elegido.
  final ClueMark clueMark;
  final VoidCallback onCycleClue;
  final VoidCallback onOpenClue;
  final bool compact;
  final Widget? trailing;

  /// Permite envolver la fila de retratos (el tutorial la señala con un
  /// marco sin tocar la pista ni el botón Resolver).
  final Widget Function(Widget portraits)? wrapPortraits;

  @override
  Widget build(BuildContext context) {
    final hint = HintBox(
      pc: pc,
      selectedChar: selectedChar,
      mark: clueMark,
      compact: compact,
      onCycleMark: onCycleClue,
      onOpenFull: onOpenClue,
    );
    final portraits = PortraitRow(
      pc: pc,
      skin: skin,
      pulse: pulse,
      selectedChar: selectedChar,
      placed: placed,
      enabled: enabled,
      onSelect: onSelect,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        wrapPortraits == null ? portraits : wrapPortraits!(portraits),
        SizedBox(height: compact ? 3 : 4),
        if (compact && trailing != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: hint),
              const SizedBox(width: 6),
              trailing!,
            ],
          )
        else
          hint,
      ],
    );
  }
}

class PortraitRow extends StatefulWidget {
  const PortraitRow({
    super.key,
    required this.pc,
    required this.skin,
    required this.pulse,
    required this.selectedChar,
    required this.placed,
    required this.enabled,
    required this.onSelect,
  });

  final PuzzleCase pc;
  final BoardSkin skin;
  final ValueNotifier<TrayPulse?> pulse;
  final String? selectedChar;
  final Set<String> placed;
  final bool enabled;
  final ValueChanged<String> onSelect;

  @override
  State<PortraitRow> createState() => _PortraitRowState();
}

class _PortraitRowState extends State<PortraitRow> {
  final ScrollController _scroll = ScrollController();
  bool _more = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final more = _scroll.position.pixels < _scroll.position.maxScrollExtent - 4;
    if (more != _more && mounted) setState(() => _more = more);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.pc;
    final chars = pc.characters;
    const chip = ScreenMetrics.portraitBox;
    return SizedBox(
      height: ScreenMetrics.portraitRowFor(MediaQuery.textScalerOf(context)),
      child: LayoutBuilder(
        builder: (context, box) {
          // Si todos caben, se reparten el ancho; si no, se deslizan.
          final fits = chars.length * chip <= box.maxWidth;
          final gap = fits && chars.length > 1
              ? (box.maxWidth - chars.length * chip) / (chars.length - 1)
              : 4.0;
          return Stack(
            children: [
              ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: fits ? const NeverScrollableScrollPhysics() : null,
                itemCount: chars.length,
                separatorBuilder: (_, _) => SizedBox(width: gap),
                itemBuilder: (context, i) {
                  final ch = chars[i];
                  return _PortraitChip(
                    key: ValueKey('retrato-${ch.id}'),
                    skin: widget.skin,
                    index: i,
                    charId: ch.id,
                    name: ch.nameEs,
                    female: ch.female,
                    victim: ch.id == pc.victimId,
                    selected: widget.selectedChar == ch.id,
                    placed: widget.placed.contains(ch.id),
                    enabled: widget.enabled,
                    pulse: widget.pulse,
                    onTap: () => widget.onSelect(ch.id),
                  );
                },
              ),
              // Indicio de que se puede deslizar.
              if (_more && !fits)
                Positioned(
                  right: 0,
                  top: 0,
                  height: chip,
                  child: IgnorePointer(
                    child: Container(
                      width: 30,
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.pal.bg.withValues(alpha: 0),
                            context.pal.bg,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: context.pal.accent,
                        size: 26,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PortraitChip extends StatefulWidget {
  const _PortraitChip({
    super.key,
    required this.skin,
    required this.index,
    required this.charId,
    required this.name,
    required this.female,
    required this.victim,
    required this.selected,
    required this.placed,
    required this.enabled,
    required this.pulse,
    required this.onTap,
  });

  final BoardSkin skin;
  final int index;
  final String charId;
  final String name;
  final bool female;
  final bool victim;
  final bool selected;
  final bool placed;
  final bool enabled;
  final ValueNotifier<TrayPulse?> pulse;
  final VoidCallback onTap;

  @override
  State<_PortraitChip> createState() => _PortraitChipState();
}

class _PortraitChipState extends State<_PortraitChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  int _lastSerial = -1;

  @override
  void initState() {
    super.initState();
    widget.pulse.addListener(_onPulse);
  }

  void _onPulse() {
    final p = widget.pulse.value;
    if (p == null || p.serial == _lastSerial || p.charId != widget.charId) {
      return;
    }
    _lastSerial = p.serial;
    _c.forward(from: 0); // se hunde, rebota y se asienta en 120 ms
  }

  @override
  void dispose() {
    widget.pulse.removeListener(_onPulse);
    _c.dispose();
    super.dispose();
  }

  double _scale(double t) {
    if (t < 0.4) return 1 - 0.12 * (t / 0.4);
    if (t < 0.75) return 0.88 + 0.18 * ((t - 0.4) / 0.35);
    return 1.06 - 0.06 * ((t - 0.75) / 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final label = widget.victim
        ? context.l10n.gameHintVictimLabel(
            widget.name,
            context.l10n.gameToolbarVictim,
          )
        : widget.name;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.placed ? context.l10n.gameHintPlaced(label) : label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.scale(
            scale: _c.isAnimating ? _scale(_c.value) : 1.0,
            child: child,
          ),
          child: SizedBox(
            width: ScreenMetrics.portraitBox,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: ScreenMetrics.portraitBox,
                  height: ScreenMetrics.portraitBox,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: widget.placed ? 0.5 : 1,
                        child: CustomPaint(
                          painter: _PortraitPainter(
                            widget.skin,
                            TokenStyle(
                              charIndex: widget.index,
                              initial: tokenInitial(
                                widget.name,
                                victim: widget.victim,
                              ),
                              victim: widget.victim,
                              female: widget.female,
                            ),
                            widget.selected,
                          ),
                        ),
                      ),
                      if (widget.placed)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: p.good,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.bg, width: 2),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: p.onColor(p.good),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.victim ? context.l10n.gameToolbarVictim : widget.name,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: widget.selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: widget.placed ? p.textDim : p.text,
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

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.skin, this.style, this.selected);
  final BoardSkin skin;
  final TokenStyle style;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    // El retrato mide unos 50 px; el resto es el aro de selección y el grosor
    // del recorte.
    final frame = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    skin.paintPortrait(canvas, frame, style, selected: selected);
  }

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.skin != skin ||
      old.selected != selected ||
      old.style.charIndex != style.charIndex ||
      old.style.victim != style.victim;
}

/// Recuadro con la pista del personaje seleccionado. En la distribución
/// normal crece según el texto, hasta 3 líneas. En la compacta muestra una
/// sola línea y, al tocarlo, se expande en una tarjeta que flota sobre la
/// interfaz (no empuja el tablero ni la barra de herramientas).
///
/// Marcas de la pista (H-56): en la distribución normal, tocar la pista la
/// destaca o la tacha (la estrella y el tachado se ven sin depender del
/// color); mantenerla oprimida abre la pista completa en una hoja, donde
/// también se fija la marca. "ver más" aparece solo si el texto queda cortado.
class HintBox extends StatefulWidget {
  const HintBox({
    super.key,
    required this.pc,
    required this.selectedChar,
    required this.mark,
    required this.onCycleMark,
    required this.onOpenFull,
    this.compact = false,
  });

  final PuzzleCase pc;
  final String? selectedChar;
  final ClueMark mark;
  final VoidCallback onCycleMark;
  final VoidCallback onOpenFull;
  final bool compact;

  @override
  State<HintBox> createState() => _HintBoxState();
}

class _HintBoxState extends State<HintBox> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  String? _lastId;
  double _width = 0;

  @override
  void didUpdateWidget(HintBox old) {
    super.didUpdateWidget(old);
    // Al cambiar de personaje, la pista expandida se pliega.
    if (_overlay.isShowing && widget.selectedChar != _lastId) {
      _overlay.hide();
    }
  }

  String? _clueText(BuildContext context) {
    final id = widget.selectedChar;
    if (id == null) return null;
    final clue = widget.pc.clueFor(id);
    if (clue == null) return null;
    return clueText(widget.pc, clue, locale: Localizations.localeOf(context));
  }

  TextSpan _span(BuildContext context) {
    final p = context.pal;
    final id = widget.selectedChar;
    final fontSize = widget.compact ? 14.0 : 15.0;
    if (id == null) {
      return TextSpan(
        text: context.l10n.gameHintEmpty,
        style: TextStyle(fontSize: fontSize, height: 1.2, color: p.textDim),
      );
    }
    final name = widget.pc.character(id).nameEs;
    final struck = widget.mark == ClueMark.struck;
    final hi = widget.mark == ClueMark.highlighted;
    final color = struck ? p.textDim : p.text;
    return TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        height: 1.2,
        color: color,
        fontWeight: hi ? FontWeight.w700 : FontWeight.w400,
        decoration: struck ? TextDecoration.lineThrough : null,
      ),
      children: [
        TextSpan(
          text: '${name.toUpperCase()}  ',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: p.accent,
            decoration: TextDecoration.none,
          ),
        ),
        TextSpan(text: _clueText(context) ?? context.l10n.gameHintEmpty),
      ],
    );
  }

  Widget _text(BuildContext context, {required int maxLines}) => Text.rich(
    _span(context),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );

  /// ¿El texto queda cortado con [maxLines] líneas en [width] píxeles?
  bool _truncated(BuildContext context, double width, int maxLines) {
    if (widget.selectedChar == null || width <= 0) return false;
    final painter = TextPainter(
      text: _span(context),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final cut = painter.didExceedMaxLines;
    painter.dispose();
    return cut;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final id = widget.selectedChar;
    _lastId = id;
    final compact = widget.compact;
    final maxLines = compact ? 1 : 3;
    final hi = widget.mark == ClueMark.highlighted;
    final fill = hi
        ? Color.alphaBlend(p.accent.withValues(alpha: 0.22), p.surfaceAlt)
        : p.surfaceAlt;

    final box = ChromeBox(
      color: fill,
      radius: 14,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 7 : 8),
      depth: 2.5,
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) {
            // Ancho que le queda al texto (menos los iconos del costado).
            final cut = _truncated(context, c.maxWidth - 28, maxLines);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hi)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.star_rounded, size: 20, color: p.accent),
                  ),
                Expanded(child: _text(context, maxLines: maxLines)),
                if (id != null && cut)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onOpenFull,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        context.l10n.gameHintMore,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ),
                if (compact && id != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _overlay.isShowing
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 22,
                      color: p.accent,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    final tappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: id == null ? null : widget.onOpenFull,
      onTap: id == null
          ? null
          : (compact
                ? () {
                    _overlay.toggle();
                    setState(() {});
                  }
                : widget.onCycleMark),
      child: Semantics(
        container: true,
        label: id == null
            ? context.l10n.gameHintEmpty
            : context.l10n.gameHintClueSemantics(
                widget.pc.character(id).nameEs,
                _clueText(context) ?? '',
              ),
        excludeSemantics: true,
        child: box,
      ),
    );

    if (!compact) return tappable;

    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (ctx) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.bottomLeft,
          showWhenUnlinked: false,
          child: SizedBox(
            width: _width,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _overlay.hide();
                setState(() {});
              },
              onLongPress: widget.onOpenFull,
              child: Semantics(
                label: context.l10n.gameHintExpandLabel,
                child: ChromeBox(
                  color: fill,
                  radius: 14,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  depth: 2.5,
                  child: SizedBox(
                    width: double.infinity,
                    child: _text(ctx, maxLines: 6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: LayoutBuilder(
          builder: (context, c) {
            _width = c.maxWidth;
            return tappable;
          },
        ),
      ),
    );
  }
}
