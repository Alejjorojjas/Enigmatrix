/// Bandeja de sospechosos: fila de retratos y recuadro con la pista del
/// personaje seleccionado. Los retratos los dibuja la piel activa.
library;

import 'package:flutter/material.dart';

import '../game/game_session.dart';
import '../scene/skin.dart';
import '../strings.dart';
import 'chrome.dart';
import 'layout_metrics.dart';
import 'prototype_theme.dart';

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
    required this.session,
    required this.skin,
    required this.pulse,
    this.compact = false,
    this.trailing,
  });

  final GameSession session;
  final BoardSkin skin;
  final ValueNotifier<TrayPulse?> pulse;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PortraitRow(session: session, skin: skin, pulse: pulse),
        SizedBox(height: compact ? 3 : 4),
        if (compact && trailing != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: HintBox(session: session, compact: true)),
              const SizedBox(width: 6),
              trailing!,
            ],
          )
        else
          HintBox(session: session, compact: compact),
      ],
    );
  }
}

class PortraitRow extends StatefulWidget {
  const PortraitRow({
    super.key,
    required this.session,
    required this.skin,
    required this.pulse,
  });

  final GameSession session;
  final BoardSkin skin;
  final ValueNotifier<TrayPulse?> pulse;

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
    final session = widget.session;
    final placed = <String>{
      for (final c in session.board.confirmedCells)
        if (session.board.cell(c).confirmed != null)
          session.board.cell(c).confirmed!
    };
    final chars = session.pc.characters;
    const chip = ScreenMetrics.portraitBox;
    return SizedBox(
      height: ScreenMetrics.portraitRow,
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
                    key: ValueKey(ch.id),
                    skin: widget.skin,
                    index: i,
                    charId: ch.id,
                    name: ch.nameEs,
                    female: ch.female,
                    victim: ch.id == session.pc.victimId,
                    selected: session.selectedChar == ch.id,
                    placed: placed.contains(ch.id),
                    enabled: !session.solved,
                    pulse: widget.pulse,
                    onTap: () => session.selectSuspect(ch.id),
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
                        gradient: LinearGradient(colors: [
                          context.pal.bg.withValues(alpha: 0),
                          context.pal.bg,
                        ]),
                      ),
                      child: Icon(Icons.chevron_right, color: context.pal.accent, size: 26),
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
    if (p == null || p.serial == _lastSerial || p.charId != widget.charId) return;
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
    final label = widget.victim ? '${widget.name} (${Strings.victim})' : widget.name;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.placed ? '$label, ya colocado' : label,
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
                              initial: widget.name.isEmpty
                                  ? '?'
                                  : widget.name.characters.first.toUpperCase(),
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
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.victim ? Strings.victim : widget.name,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
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
class HintBox extends StatefulWidget {
  const HintBox({super.key, required this.session, this.compact = false});

  final GameSession session;
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
    if (_overlay.isShowing && widget.session.selectedChar != _lastId) {
      _overlay.hide();
    }
  }

  Widget _text(BuildContext context, {required int maxLines}) {
    final p = context.pal;
    final session = widget.session;
    final id = session.selectedChar;
    final fontSize = widget.compact ? 14.0 : 15.0;
    if (id == null) {
      return Text(Strings.hintEmpty,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: fontSize, height: 1.2, color: p.textDim));
    }
    final pc = session.pc;
    final name = pc.character(id).nameEs;
    final clue = pc.clueFor(id)?.cardTextEs(pc.map, pc.names);
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '${name.toUpperCase()}  ',
          style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: p.accent),
        ),
        TextSpan(text: clue ?? Strings.hintEmpty, style: TextStyle(color: p.text)),
      ]),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: fontSize, height: 1.2, color: p.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final id = widget.session.selectedChar;
    _lastId = id;
    final compact = widget.compact;

    final box = ChromeBox(
      color: p.surfaceAlt,
      radius: 14,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 7 : 8),
      depth: 2.5,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(child: _text(context, maxLines: compact ? 1 : 3)),
            if (compact && id != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  _overlay.isShowing ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: p.accent,
                ),
              ),
          ],
        ),
      ),
    );

    if (!compact) return box;

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
              child: Semantics(
                label: Strings.hintExpandLabel,
                child: ChromeBox(
                  color: p.surfaceAlt,
                  radius: 14,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  depth: 2.5,
                  child: SizedBox(
                      width: double.infinity, child: _text(ctx, maxLines: 6)),
                ),
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: LayoutBuilder(builder: (context, c) {
          _width = c.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: id == null
                ? null
                : () {
                    _overlay.toggle();
                    setState(() {});
                  },
            child: box,
          );
        }),
      ),
    );
  }
}
