/// La escena del tablero: UN juego de Flame con tres capas (fondo fijo,
/// fichas, efectos) más una capa de pantalla. Aquí no hay widgets por casilla.
///
/// El juego recibe los efectos que decide el director de feedback
/// ([VisualSink]) y los reparte entre las capas. También interpreta el dedo
/// (toque y mantener oprimido) y avanza el reloj de la secuencia de resolver.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../feedback/feedback_director.dart';
import '../feedback/feedback_event.dart';
import '../feedback/feedback_plan.dart';
import '../feedback/reveal_timeline.dart';
import '../scene_session.dart';
import '../gesture_interpreter.dart';
import '../board_settings.dart';
import '../board_strings.dart';
import 'board_geometry.dart';
import 'layers.dart';
import 'skin.dart';

/// Estado de la secuencia de resolver para la interfaz.
enum RevealPhase { idle, running, runningCanSkip, done }

class BoardGame extends FlameGame implements VisualSink {
  BoardGame({
    required this.session,
    required this.settings,
    required this.skin,
    this.pixelRatio = 2.0,
  });

  final SceneSession session;
  BoardSettings settings;
  BoardSkin skin;
  final double pixelRatio;

  final CellGestureInterpreter interpreter = CellGestureInterpreter();
  final CameraRig rig = CameraRig();
  final Stopwatch _clock = Stopwatch()..start();

  late BoardGeometry geometry = BoardGeometry.fit(session.size, ui.Size.zero);

  late final SceneRoot _root = SceneRoot();
  late final BackgroundLayer background = BackgroundLayer();
  late final PiecesLayer pieces = PiecesLayer();
  late final EffectsLayer effects = EffectsLayer();
  late final FxOverlay overlay = FxOverlay();

  /// Fase de la secuencia de resolver (la interfaz muestra "Saltar").
  final ValueNotifier<RevealPhase> revealPhase =
      ValueNotifier(RevealPhase.idle);
  VoidCallback? onRevealStarted;
  VoidCallback? onRevealFinished;

  bool _loaded = false;

  /// Tamaño del área de juego (lo da Flutter al medir el widget).
  ui.Size viewSize = ui.Size.zero;

  // Sacudida amortiguada y golpe de cámara.
  double _shakeT = 99, _shakeAmp = 0;
  double _punchT = 99, _punchAmp = 0;
  double _zoomStartT = -1;

  // Secuencia de resolver.
  RevealTimeline? _timeline;
  double _revealMs = 0;
  bool _revealRunning = false;
  bool _revealReduced = false;

  double get nowMs => _clock.elapsedMicroseconds / 1000.0;

  @override
  Color backgroundColor() => skin.backdrop;

  @override
  Future<void> onLoad() async {
    _root.addAll([background, pieces, effects]);
    await addAll([_root, overlay]);
    _loaded = true;
    _relayout(); // si el tamaño ya llegó; si no, lo hace onGameResize
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    viewSize = ui.Size(size.x, size.y);
    if (_loaded) _relayout();
  }

  /// Cambia de piel o de modo en vivo: se vuelve a dibujar el fondo y la
  /// viñeta; las fichas y animaciones siguen donde estaban.
  void setSkin(BoardSkin next) {
    if (identical(next, skin)) return;
    skin = next;
    if (_loaded) _relayout();
  }

  /// Cambia entre la vista de mapa (muebles y nombres) y la de notas (solo la
  /// cuadrícula con las marcas). Las fichas no se mueven.
  void setMapMode(bool map) {
    if (session.mapMode == map) return;
    session.mapMode = map;
    if (_loaded) _relayout();
  }

  void _relayout() {
    final s = viewSize;
    if (s.isEmpty) return;
    // 12 px a los lados: el tablero ocupa el ancho disponible.
    geometry = BoardGeometry.fit(session.size, s, margin: 12, marginY: 2);
    background.rebuild(s, pixelRatio);
    overlay.rebuild(s);
  }

  // ---------------------------------------------------------------------------
  // Dedo
  // ---------------------------------------------------------------------------

  ui.Offset _toScene(ui.Offset p) => rig.toScene(p, viewSize);

  void pointerDown(int pointer, ui.Offset local) {
    // Tras 1 s de la secuencia, tocar el tablero la salta.
    if (revealPhase.value == RevealPhase.runningCanSkip) {
      skipReveal();
      return;
    }
    if (!session.interactive) return;
    final cell = geometry.cellAt(_toScene(local));
    interpreter.down(pointer, local, cell, nowMs);
  }

  void pointerMove(int pointer, ui.Offset local) =>
      interpreter.move(pointer, local);

  void pointerUp(int pointer, ui.Offset local) {
    final g = interpreter.up(pointer, nowMs);
    if (g is TapGesture && session.interactive) {
      session.onTapCell?.call(g.cell);
    }
  }

  void pointerCancel(int pointer) => interpreter.cancel(pointer);

  // ---------------------------------------------------------------------------
  // Reloj del juego
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    dt = math.min(dt, 0.05);
    super.update(dt);

    // "Mantener oprimido": se confirma en el cuadro en que se cumple el tiempo.
    final hold = interpreter.update(nowMs);
    if (hold is HoldGesture && session.interactive) {
      session.onHoldCell?.call(hold.cell);
    }

    _updateCamera(dt);
    _updateReveal(dt);
  }

  void _updateCamera(double dt) {
    // Sacudida amortiguada: seno que decae rápido.
    if (_shakeT < 1.0) {
      _shakeT += dt;
      final decay = math.exp(-_shakeT * 6.5);
      rig.shake = ui.Offset(
        math.sin(_shakeT * 58) * _shakeAmp * decay,
        math.sin(_shakeT * 41 + 1.3) * _shakeAmp * 0.45 * decay,
      );
      if (_shakeT >= 0.5) rig.shake = ui.Offset.zero;
    }
    // Golpe de cámara: un pequeño acercamiento que se asienta.
    if (_punchT < 0.4) {
      _punchT += dt;
      final u = (_punchT / 0.22).clamp(0.0, 1.0);
      rig.punch = _punchAmp * 0.016 * math.sin(math.pi * u) * math.exp(-u * 1.5);
      if (_punchT >= 0.22) rig.punch = 0;
    }
    // Zoom al asesino.
    if (_zoomStartT >= 0) {
      final u = ((time - _zoomStartT) / 0.6).clamp(0.0, 1.0);
      rig.zoomT = u < 0.5 ? 4 * u * u * u : 1 - math.pow(-2 * u + 2, 3) / 2;
    }
  }

  // Tiempo propio acumulado.
  double time = 0;

  void _updateReveal(double dt) {
    time += dt;
    if (!_revealRunning) return;
    final prev = _revealMs;
    _revealMs += dt * 1000;
    final tl = _timeline!;
    for (final m in tl.between(prev, _revealMs)) {
      session.director.handle(tl.beatFor(m));
      if (!_revealRunning) return; // el último momento cierra la secuencia
    }
    if (revealPhase.value == RevealPhase.running &&
        _revealMs >= RevealTimeline.skipAfterMs) {
      revealPhase.value = RevealPhase.runningCanSkip;
    }
  }

  /// El jugador salta la secuencia (solo disponible tras 1 s).
  void skipReveal() {
    if (!_revealRunning) return;
    if (_revealMs < RevealTimeline.skipAfterMs) return;
    session.director.handle(RevealSkipped(_timeline!.reveal));
  }

  // ---------------------------------------------------------------------------
  // Efectos que decide el director
  // ---------------------------------------------------------------------------

  @override
  void play(VisualEffect e) {
    switch (e.kind) {
      case VisualKind.selectPulse:
        pieces.pulseSelection();
      case VisualKind.pencilMark:
        pieces.addPencil(e.cell!, session.indexOfChar(e.charId!),
            reduced: e.reduced);
      case VisualKind.erasePuff:
        effects.addGlow(e.cell!, 0.22, 0.2);
      case VisualKind.rejectNudge:
        pieces.addNudge(e.cell!);
      case VisualKind.confirmDrop:
        pieces.addDrop(e.cell!);
      case VisualKind.confirmFade:
        pieces.addFade(e.cell!);
      case VisualKind.ripple:
        effects.addRipple(e.cell!);
      case VisualKind.confetti:
        effects.confetti(e.cell!, e.count);
      case VisualKind.flash:
        effects.addFlash(e.cell!);
      case VisualKind.fadeGlow:
        effects.addGlow(e.cell!, 0.4, 0.24);
      case VisualKind.cameraPunch:
        _punchT = 0;
        _punchAmp = e.strength;
      case VisualKind.crossWave:
        pieces.addCrossWave(e.cell!, e.cells, fade: false);
      case VisualKind.crossFade:
        pieces.addCrossWave(e.cell!, e.cells, fade: true);
      case VisualKind.shake:
        _shakeT = 0;
        _shakeAmp = e.strength;
      case VisualKind.errorFade:
        overlay.errorFade = 1;
      case VisualKind.errorText:
        overlay.showError(e.text ?? '', reduced: e.reduced);
      case VisualKind.message:
        break; // lo muestra la interfaz de Flutter
      case VisualKind.revealStart:
        _startReveal(e.reveal!, e.reduced);
      case VisualKind.revealRow:
        pieces.addRowLight(e.count);
        effects.addRowBar(e.count, reduced: e.reduced);
      case VisualKind.revealHop:
        pieces.addHop(e.cell!, reduced: e.reduced);
      case VisualKind.revealZoom:
        overlay.spotTarget = 1;
        overlay.darkTarget = 0.8;
        overlay.spotCell = e.cell;
        if (!e.reduced) {
          rig.focus = geometry.cellCenter(e.cell!);
          _zoomStartT = time;
        }
      case VisualKind.revealStar:
        overlay.popStar(e.count);
      case VisualKind.revealConfetti:
        // Ráfaga fuerte desde el asesino.
        effects.confetti(e.cell!, e.count, speed: 330, upward: 0.9, size: 7);
      case VisualKind.revealEnd:
        _finishReveal();
      case VisualKind.revealSkip:
        _skipToEnd(e.reveal!);
    }
  }

  void _startReveal(RevealData reveal, bool reduced) {
    _timeline = RevealTimeline.build(reveal);
    _revealMs = 0;
    _revealRunning = true;
    _revealReduced = reduced;
    overlay.resetReveal();
    overlay.darkTarget = 0.55;
    overlay.label = BoardStrings.murdererIs(reveal.murdererName);
    revealPhase.value = RevealPhase.running;
    onRevealStarted?.call();
  }

  void _finishReveal() {
    _revealRunning = false;
    revealPhase.value = RevealPhase.done;
    onRevealFinished?.call();
  }

  void _skipToEnd(RevealData reveal) {
    // Estado final de golpe: asesino en primer plano, estrellas y rótulo.
    overlay.finishReveal();
    overlay.spotCell = reveal.murdererCell;
    if (!_revealReduced) {
      rig.focus = geometry.cellCenter(reveal.murdererCell);
      _zoomStartT = time - 1;
      rig.zoomT = 1;
    }
    _finishReveal();
  }

  /// Vuelve la escena a su estado de reposo (para jugar de nuevo).
  void resetScene() {
    pieces.clearAll();
    effects.clearAll();
    overlay.resetReveal();
    rig.reset();
    _zoomStartT = -1;
    _revealRunning = false;
    revealPhase.value = RevealPhase.idle;
  }
}
