/// Pantalla del prototipo: barra superior, escena de Flame, medidor de FPS,
/// barra de herramientas, retratos con la pista del personaje y botón
/// Resolver. La piel (Ilustrada, Papel o Neutra) y el modo (claro u oscuro)
/// salen del tema y se pueden cambiar en vivo.
library;

import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../audio/haptics_service.dart';
import '../feedback/feedback_director.dart';
import '../feedback/feedback_plan.dart';
import '../game/case_library.dart';
import '../game/fps_recorder.dart';
import '../game/game_session.dart';
import '../scene/board_game.dart';
import '../scene/palette.dart';
import '../scene/skin.dart';
import '../scene/skins.dart';
import '../settings.dart';
import '../strings.dart';
import 'chrome.dart';
import 'fps_overlay.dart';
import 'layout_metrics.dart';
import 'options_sheet.dart';
import 'prototype_theme.dart';
import 'toolbar.dart';
import 'tray.dart';

/// Reparte los efectos visuales entre la escena de Flame y la interfaz.
class _VisualRouter implements VisualSink {
  BoardGame? game;
  void Function(String text)? onMessage;
  void Function(String charId)? onSelect;
  int _serial = 0;

  @override
  void play(VisualEffect e) {
    game?.play(e);
    switch (e.kind) {
      case VisualKind.message:
        onMessage?.call(e.text ?? '');
      case VisualKind.selectPulse:
        onSelect?.call(e.charId!);
        _serial++;
      default:
        break;
    }
  }

  int get serial => _serial;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.cases,
    required this.settings,
    required this.audio,
    required this.fps,
  });

  final List<CaseEntry> cases;
  final GameSettings settings;
  final SoloudSoundService audio;
  final FpsMonitor fps;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _haptics = FlutterHapticService();
  final ValueNotifier<TrayPulse?> _trayPulse = ValueNotifier(null);
  final ValueNotifier<String?> _toast = ValueNotifier(null);
  Timer? _toastTimer;
  Timer? _clock;

  int _caseIndex = 0;
  int _attempt = 0;
  late BoardSkin _skin;
  late GameSession _session;
  late BoardGame _game;
  late FeedbackDirector _director;
  late _VisualRouter _router;
  FpsReport? _lastReport;
  bool _built = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _session.tickSecond());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enx = context.enx;
    if (!_built) {
      _built = true;
      // Si el sistema pide menos animaciones, arranca en modo reducido.
      if (MediaQuery.of(context).disableAnimations) {
        widget.settings.reduceMotion = true;
      }
      _skin = SkinRegistry.create(enx.skinId, enx.palette.mode);
      _build();
    } else if (_skin.id != enx.skinId || _skin.mode != enx.palette.mode) {
      // Cambió la piel o el modo: se redibuja el tablero sin perder la partida.
      _skin = SkinRegistry.create(enx.skinId, enx.palette.mode);
      _game.setSkin(_skin);
    }
  }

  void _build() {
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    _router = _VisualRouter();
    _director = FeedbackDirector(
      settings: widget.settings,
      visuals: _router,
      sounds: widget.audio,
      haptics: _haptics,
    );
    _session = GameSession(
      pc: widget.cases[_caseIndex].puzzle,
      director: _director,
      settings: widget.settings,
    );
    _game = BoardGame(
      session: _session,
      settings: widget.settings,
      skin: _skin,
      pixelRatio: pixelRatio.clamp(1.0, 3.0),
    );
    _router.game = _game;
    _router.onMessage = _showToast;
    _router.onSelect = (id) => _trayPulse.value = TrayPulse(_router.serial, id);
    _game.onRevealStarted = widget.fps.startRecording;
    _game.onRevealFinished = () {
      final r = widget.fps.stopRecording();
      if (mounted && r != null) {
        setState(() => _lastReport = r);
        // El resultado sale en un aviso (con "Copiar") solo si el medidor de
        // FPS está activo; siempre queda en Opciones.
        if (widget.settings.fpsMeter) showFpsReport(context, r);
      }
    };
  }

  void _showToast(String text) {
    _toast.value = text;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1900), () {
      _toast.value = null;
    });
  }

  void _restart({int? caseIndex}) {
    widget.audio.stopLong();
    widget.fps.recorder.stop();
    setState(() {
      if (caseIndex != null) _caseIndex = caseIndex;
      _attempt++;
      _toast.value = null;
      _build();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _toastTimer?.cancel();
    _trayPulse.dispose();
    _toast.dispose();
    super.dispose();
  }

  void _cycleSkin() {
    final ids = SkinRegistry.ids;
    final next = ids[(ids.indexOf(widget.settings.skinId) + 1) % ids.length];
    widget.settings.skinId = next;
    _showToast('${Strings.skin}: ${SkinRegistry.spec(next).displayName}');
  }

  void _toggleMode() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    widget.settings.themeMode = dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PaperFibers()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final m = ScreenMetrics.of(box.biggest);
                return Column(
                  children: [
                    SizedBox(height: m.compact ? ScreenMetrics.headerTopCompact : ScreenMetrics.headerTopNormal),
                    _pad(_topBar(p)),
                    SizedBox(height: m.compact ? 0 : ScreenMetrics.headerGapNormal),
                    _pad(_titleRow(p, m)),
                    SizedBox(height: m.compact ? ScreenMetrics.headerGapCompact : ScreenMetrics.gapNormal),
                    // El tablero ocupa todo el ancho, sin márgenes de página.
                    SizedBox(
                      width: double.infinity,
                      height: m.stageHeight,
                      child: _stage(p),
                    ),
                    SizedBox(height: m.gap),
                    Expanded(
                      child: _pad(
                        ListenableBuilder(
                          listenable: Listenable.merge([_session, widget.settings]),
                          builder: (context, _) => m.compact ? _bottomCompact(m) : _bottomNormal(m),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ScreenMetrics.sidePad),
        child: child,
      );

  /// Distribución normal: herramientas, retratos, pista (crece hasta 3 líneas)
  /// y Resolver en su fila, pegado abajo.
  Widget _bottomNormal(ScreenMetrics m) => Column(
        children: [
          ToolBar(session: _session, height: m.toolbarHeight),
          SizedBox(height: m.gap),
          SuspectPanel(session: _session, skin: _skin, pulse: _trayPulse),
          const Spacer(),
          ResolveBar(
              session: _session,
              onPlayAgain: _restart,
              height: ScreenMetrics.resolveNormal),
          SizedBox(height: m.gap),
        ],
      );

  /// Distribución compacta (pantallas bajas): la pista en una línea que se
  /// expande al tocarla y Resolver a su lado.
  Widget _bottomCompact(ScreenMetrics m) => Column(
        children: [
          ToolBar(session: _session, height: m.toolbarHeight),
          SizedBox(height: m.gap),
          SuspectPanel(
            session: _session,
            skin: _skin,
            pulse: _trayPulse,
            compact: true,
            trailing: ResolveBar(
              session: _session,
              onPlayAgain: _restart,
              height: ScreenMetrics.resolveCompact,
              fill: false,
            ),
          ),
        ],
      );

  Widget _topBar(SkinPalette p) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: Listenable.merge([_session, widget.settings]),
      builder: (context, _) => Row(
        children: [
          IconSquare(
            icon: Icons.tune,
            label: Strings.options,
            onTap: () => showOptionsSheet(
              context,
              settings: widget.settings,
              lastReport: _lastReport,
              audioError: widget.audio.error,
              onAutofill: _session.autofillForMeasuring,
            ),
          ),
          const Spacer(),
          // El medidor de FPS (si se activó en Opciones) va aquí, bajo el
          // cronómetro: en la barra superior, nunca sobre el tablero.
          TimerPill(
            seconds: _session.elapsedSeconds,
            subline: widget.settings.fpsMeter ? FpsReadout(monitor: widget.fps) : null,
          ),
          const Spacer(),
          IconSquare(
            icon: Icons.undo,
            label: Strings.undo,
            onTap: _session.canUndo ? _session.undo : null,
          ),
          const SizedBox(width: 4),
          IconSquare(
            icon: Icons.palette_outlined,
            label: Strings.skin,
            onTap: _cycleSkin,
          ),
          const SizedBox(width: 4),
          IconSquare(
            icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: dark ? Strings.modeToggleToLight : Strings.modeToggleToDark,
            onTap: _toggleMode,
          ),
        ],
      ),
    );
  }

  Widget _titleRow(SkinPalette p, ScreenMetrics m) {
    final h = m.compact ? ScreenMetrics.headerRow2Compact : ScreenMetrics.headerRow2Normal;
    return SizedBox(
      height: h,
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _session.pc.map.nameEs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: p.text),
                  ),
                  Text(
                    '${Strings.caseSubtitle(_session.pc.difficulty, _session.size)} · '
                    '${Strings.errorsLabel}: ${_session.errors}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.15, color: p.textDim),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < widget.cases.length; i++) ...[
              const SizedBox(width: 6),
              ChromeButton(
                onTap: () => _restart(caseIndex: i),
                color: i == _caseIndex ? p.toolActive : p.surface,
                selected: i == _caseIndex,
                semanticsLabel: widget.cases[i].label,
                radius: 14,
                minSize: Size(52, h),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  widget.cases[i].label.split(' ').first,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: i == _caseIndex ? p.onToolActive : p.text,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stage(SkinPalette p) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _game.pointerDown(e.pointer, e.localPosition),
            onPointerMove: (e) => _game.pointerMove(e.pointer, e.localPosition),
            onPointerUp: (e) => _game.pointerUp(e.pointer, e.localPosition),
            onPointerCancel: (e) => _game.pointerCancel(e.pointer),
            child: GameWidget(key: ValueKey('game$_attempt$_caseIndex'), game: _game),
          ),
          // Aviso corto ("Elige primero a un sospechoso").
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: IgnorePointer(
              child: ValueListenableBuilder<String?>(
                valueListenable: _toast,
                builder: (context, text, _) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: text == null ? 0 : 1,
                  child: Center(
                    child: ChromeBox(
                      color: p.pill,
                      radius: 20,
                      depth: 2.5,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: Text(text ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: p.onPill)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Saltar la secuencia (disponible tras 1 s).
          Positioned(
            right: 10,
            bottom: 10,
            child: ValueListenableBuilder<RevealPhase>(
              valueListenable: _game.revealPhase,
              builder: (context, phase, _) => phase == RevealPhase.runningCanSkip
                  ? ChromeButton(
                      onTap: _game.skipReveal,
                      color: p.accent,
                      radius: 18,
                      semanticsLabel: Strings.skip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward, color: p.onAccent),
                          const SizedBox(width: 6),
                          Text(Strings.skip,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: p.onAccent)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
