/// Las capas de la escena de Flame:
///  - [BackgroundLayer]: fondo fijo (piso, paredes, muebles). Se dibuja UNA
///    vez a una imagen y después solo se estampa.
///  - [PiecesLayer]: capa interactiva (fichas, notas, X) con sus animaciones.
///  - [EffectsLayer]: ondas, destellos, partículas y barras de luz.
///  - [FxOverlay]: lo que va sobre todo en pantalla (viñeta, tinte de error,
///    texto de error, estrellas y rótulo del asesino).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'board_game.dart';
import 'particles.dart';
import 'skin.dart';

// -----------------------------------------------------------------------------
// Utilidades de animación
// -----------------------------------------------------------------------------

/// Animación con retardo. [t] avanza en segundos.
class Anim {
  Anim(this.dur, {this.delay = 0, this.flag = false});
  final double dur;
  final double delay;

  /// Marca libre (por ejemplo "versión reducida").
  final bool flag;
  double t = 0;

  bool get started => t >= delay;
  bool get done => t >= delay + dur;

  /// Avance 0..1 (0 antes de empezar).
  double get p => ((t - delay) / dur).clamp(0.0, 1.0);
}

double easeOutCubic(double x) => 1 - math.pow(1 - x, 3).toDouble();
double easeInQuad(double x) => x * x;
double easeOutBack(double x) {
  const c1 = 1.70158, c3 = c1 + 1;
  final v = x - 1;
  return 1 + c3 * v * v * v + c1 * v * v;
}

/// Resorte amortiguado: arranca en 1 y se asienta en 0.
double spring(double u) =>
    math.exp(-5.2 * u) * math.cos(2 * math.pi * 1.35 * u);

void _tickAll(Map<int, Anim> m, double dt) {
  if (m.isEmpty) return;
  for (final a in m.values) {
    a.t += dt;
  }
  m.removeWhere((_, a) => a.done);
}

// -----------------------------------------------------------------------------
// Fondo fijo
// -----------------------------------------------------------------------------

class BackgroundLayer extends Component with HasGameReference<BoardGame> {
  BackgroundLayer() : super(priority: 0);

  ui.Image? _image;
  ui.Picture? _fallback;
  ui.Size _logical = ui.Size.zero;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Vuelve a dibujar el fondo (al cambiar el tamaño o la piel).
  void rebuild(ui.Size size, double pixelRatio) {
    _image?.dispose();
    _image = null;
    _fallback?.dispose();
    _fallback = null;
    _logical = size;
    if (size.isEmpty) return;

    final k = math.min(pixelRatio * 1.5, 2400 / math.max(size.width, size.height));
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(k);
    game.skin.paintBackdrop(canvas, size, game.geometry, game.session.pc.map);
    final picture = recorder.endRecording();
    try {
      _image = picture.toImageSync(
          (size.width * k).ceil(), (size.height * k).ceil());
      picture.dispose();
    } catch (_) {
      // Si el motor no puede, se repite el dibujo cada cuadro (más lento).
      _fallback = picture;
    }
  }

  @override
  void render(Canvas canvas) {
    final img = _image;
    if (img != null) {
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        ui.Offset.zero & _logical,
        _paint,
      );
    } else if (_fallback != null) {
      canvas.save();
      canvas.drawPicture(_fallback!);
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    _image?.dispose();
    _fallback?.dispose();
    super.onRemove();
  }
}

// -----------------------------------------------------------------------------
// Capa interactiva: fichas, notas y X
// -----------------------------------------------------------------------------

class PiecesLayer extends Component with HasGameReference<BoardGame> {
  PiecesLayer() : super(priority: 1);

  // Animaciones por casilla (clave = casilla).
  final Map<int, Anim> _drops = {};
  final Map<int, Anim> _fades = {}; // confirmar en movimiento reducido
  final Map<int, Anim> _crosses = {};
  final Map<int, Anim> _hops = {};
  final Map<int, Anim> _nudges = {};
  final Map<int, Anim> _rowLights = {}; // clave = fila
  // Anotar: clave = casilla * 16 + índice del personaje.
  final Map<int, Anim> _pencils = {};

  /// Al elegir sospechoso: el resplandor de casillas candidatas "late" una vez.
  Anim? _selectPulse;
  double _selFade = 0;

  // Parpadeo: próxima hora de parpadeo por personaje.
  final math.Random _rng = math.Random(11);
  final Map<int, double> _nextBlink = {};

  double _time = 0;

  /// Reposo vivo: respiración 1,00 -> 1,02 cada 3 s.
  static const breathPeriod = 3.0;
  static const blinkDuration = 0.14;

  // ---- entradas desde el director -----------------------------------------------

  void addDrop(int cell) => _drops[cell] = Anim(0.36);
  void addFade(int cell) => _fades[cell] = Anim(0.24);
  void addNudge(int cell) => _nudges[cell] = Anim(0.22);
  void addHop(int cell, {required bool reduced}) =>
      _hops[cell] = Anim(reduced ? 0.4 : 0.38, flag: reduced);
  void addRowLight(int row) => _rowLights[row] = Anim(0.45);
  void addPencil(int cell, int charIndex, {required bool reduced}) =>
      _pencils[cell * 16 + charIndex] = Anim(0.14, flag: reduced);

  void pulseSelection() => _selectPulse = Anim(0.32);

  /// Ola de X: la X de cada casilla empieza según su distancia al origen
  /// (efecto dominó en las cuatro direcciones a la vez).
  void addCrossWave(int origin, List<int> cells, {required bool fade}) {
    final g = game.geometry;
    for (final c in cells) {
      if (fade) {
        _crosses[c] = Anim(0.22, flag: true);
        continue;
      }
      final d = (g.rowOf(c) - g.rowOf(origin)).abs() +
          (g.colOf(c) - g.colOf(origin)).abs();
      _crosses[c] = Anim(0.16, delay: 0.09 + (d - 1) * 0.045);
    }
  }

  void clearAll() {
    _drops.clear();
    _fades.clear();
    _crosses.clear();
    _hops.clear();
    _nudges.clear();
    _rowLights.clear();
    _pencils.clear();
    _selectPulse = null;
  }

  // ---- actualización -------------------------------------------------------------

  @override
  void update(double dt) {
    _time += dt;
    _tickAll(_drops, dt);
    _tickAll(_fades, dt);
    _tickAll(_crosses, dt);
    _tickAll(_hops, dt);
    _tickAll(_nudges, dt);
    _tickAll(_rowLights, dt);
    _tickAll(_pencils, dt);
    final sp = _selectPulse;
    if (sp != null) {
      sp.t += dt;
      if (sp.done) _selectPulse = null;
    }
    // Resplandor de candidatas: entra y sale en ~120 ms.
    final sel = game.session.selectedChar;
    final target = sel != null && game.session.highlightsCandidates ? 1.0 : 0.0;
    _selFade += (target - _selFade) * math.min(1.0, dt * 14);
  }

  // ---- dibujo --------------------------------------------------------------------

  double _eyeOpenFor(int charIndex) {
    final next = _nextBlink.putIfAbsent(
        charIndex, () => _time + 1.5 + _rng.nextDouble() * 5.0);
    final phase = _time - next;
    if (phase < 0) return 1;
    if (phase >= blinkDuration) {
      _nextBlink[charIndex] = _time + 4.0 + _rng.nextDouble() * 3.0; // 4 a 7 s
      return 1;
    }
    return 1 - math.sin(math.pi * phase / blinkDuration);
  }

  @override
  void render(Canvas canvas) {
    final game = this.game;
    final g = game.geometry;
    final skin = game.skin;
    final session = game.session;
    final board = session.board;
    final n = g.n;
    final cell = g.cell;
    final reduced = game.settings.reduceMotion;

    // 1) Resplandor leve de las casillas candidatas del sospechoso elegido.
    if (_selFade > 0.02 && session.selectedChar != null) {
      final id = session.selectedChar!;
      if (board.confirmedCellOf(id) == null) {
        final usedRows = <int>{}, usedCols = <int>{};
        for (final c in board.confirmedCells) {
          usedRows.add(g.rowOf(c));
          usedCols.add(g.colOf(c));
        }
        var pulse = 0.0;
        final sp = _selectPulse;
        if (sp != null && !reduced) pulse = math.sin(math.pi * sp.p) * 0.5;
        final base = _selFade * (0.14 + pulse * 0.5);
        for (var i = 0; i < n * n; i++) {
          if (usedRows.contains(g.rowOf(i)) || usedCols.contains(g.colOf(i))) {
            continue;
          }
          final c = board.cell(i);
          if (c.confirmed != null || c.hasX) continue;
          if (!session.pc.map.isOccupiable(i)) continue;
          skin.paintCellGlow(canvas, g.cellRect(i), base);
        }
      }
    }

    // 2) Luz de la ola de resolver (fila por fila).
    if (_rowLights.isNotEmpty) {
      for (final e in _rowLights.entries) {
        final a = e.value;
        final r = ui.Rect.fromLTWH(g.board.left, g.board.top + e.key * cell, g.board.width, cell);
        skin.paintCellGlow(canvas, r, math.sin(math.pi * a.p) * 0.55);
      }
    }

    // 3) Presión del dedo: resaltado y anillo de "mantener oprimido".
    final pressed = game.interpreter.pressedCell;
    if (pressed != null) {
      final p = game.interpreter.progressAt(game.nowMs);
      final r = g.cellRect(pressed);
      skin.paintCellGlow(canvas, r, 0.22 + 0.2 * p);
      if (p > 0.12) {
        skin.paintHoldRing(canvas, r.center, cell * 0.43, p, 1.0);
      }
    }

    // 4) X y notas.
    for (var i = 0; i < n * n; i++) {
      final c = board.cell(i);
      if (c.isEmpty) continue;
      final r = g.cellRect(i);
      var dx = 0.0;
      final nud = _nudges[i];
      if (nud != null) {
        dx = math.sin(nud.p * math.pi * 6) * (1 - nud.p) * cell * 0.06;
      }
      if (dx != 0) {
        canvas.save();
        canvas.translate(dx, 0);
      }
      if (c.hasX && (c.x != null || session.pc.map.isOccupiable(i))) {
        final cr = _crosses[i];
        var progress = 1.0, alpha = 1.0;
        if (cr != null) {
          if (cr.flag) {
            progress = 1;
            alpha = cr.p;
          } else {
            progress = easeOutCubic(cr.p);
            if (cr.started) {
              skin.paintCellGlow(canvas, r, math.sin(math.pi * cr.p) * 0.45);
            }
          }
          if (!cr.started) progress = 0;
        }
        skin.paintCross(canvas, r, progress,
            automatic: c.x == null, alpha: alpha);
      }
      if (c.candidates.isNotEmpty && c.confirmed == null) {
        _drawCandidates(canvas, i, r, c.candidates);
      }
      if (dx != 0) canvas.restore();
    }

    // 5) Fichas confirmadas: primero las quietas, al final las que saltan.
    final hopping = <int>[];
    for (var i = 0; i < n * n; i++) {
      final id = board.cell(i).confirmed;
      if (id == null) continue;
      if (_hops.containsKey(i)) {
        hopping.add(i);
        continue;
      }
      _drawToken(canvas, i, id);
    }
    for (final i in hopping) {
      _drawToken(canvas, i, board.cell(i).confirmed!);
    }
  }

  void _drawCandidates(ui.Canvas canvas, int cellIndex, ui.Rect r, Set<String> ids) {
    final game = this.game;
    final session = game.session;
    final sorted = ids.toList()
      ..sort((a, b) => session.indexOfChar(a).compareTo(session.indexOfChar(b)));
    final k = sorted.length;
    final cell = r.width;
    final double size;
    final List<double> centers;
    final int cols;
    if (k == 1) {
      size = cell * 0.46;
      centers = const [0.5];
      cols = 1;
    } else if (k <= 4) {
      size = cell * 0.38;
      centers = const [0.3, 0.7];
      cols = 2;
    } else {
      size = cell * 0.30;
      centers = const [0.2, 0.5, 0.8];
      cols = 3;
    }
    for (var j = 0; j < k; j++) {
      final id = sorted[j];
      final idx = session.indexOfChar(id);
      final cx = r.left + centers[j % cols] * cell;
      final cy = r.top + centers[(j ~/ cols) % centers.length] * cell;
      var scale = 1.0, rot = 0.0, alpha = 1.0;
      final pa = _pencils[cellIndex * 16 + idx];
      if (pa != null) {
        final u = pa.p;
        if (pa.flag) {
          alpha = u; // reducido: aparece con un fundido
        } else {
          // Aplastamiento al aparecer y 3 grados de giro.
          scale = u < 0.55 ? easeOutCubic(u / 0.55) * 1.22 : 1.22 - 0.22 * ((u - 0.55) / 0.45);
          rot = (1 - u) * 3 * math.pi / 180;
        }
      }
      final style = TokenStyle(
        charIndex: idx,
        initial: _initialOf(id),
        female: _femaleOf(id),
      );
      if (scale != 1.0 || rot != 0.0) {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rot);
        canvas.scale(scale);
        game.skin.paintCandidate(canvas, ui.Offset.zero, size, style, alpha);
        canvas.restore();
      } else {
        game.skin.paintCandidate(canvas, ui.Offset(cx, cy), size, style, alpha);
      }
    }
  }

  bool _femaleOf(String charId) => game.session.pc.character(charId).female;

  String _initialOf(String charId) {
    final name = game.session.pc.character(charId).nameEs;
    return name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
  }

  void _drawToken(ui.Canvas canvas, int cellIndex, String charId) {
    final game = this.game;
    final g = game.geometry;
    final session = game.session;
    final skin = game.skin;
    final cell = g.cell;
    final idx = session.indexOfChar(charId);
    final victim = charId == session.pc.victimId;
    final r = g.cellRect(cellIndex);
    final radius = cell * 0.33 * skin.tokenScale;
    final center = r.center + ui.Offset(0, cell * 0.02);
    final feet = center + ui.Offset(0, radius * 0.92);

    // Reposo vivo: respira (escala 1,00 a 1,02) con fase propia por personaje.
    var breath = 1.0;
    if (!victim && !game.settings.reduceMotion) {
      breath = 1.01 + 0.01 * math.sin(2 * math.pi * _time / breathPeriod + idx * 1.3);
    }
    var sx = 1.0, sy = 1.0, lift = 0.0, alpha = 1.0;

    final drop = _drops[cellIndex];
    if (drop != null) {
      const fallEnd = 0.16 / 0.36;
      final u = drop.p;
      if (u < fallEnd) {
        // Cae con estiramiento.
        final f = u / fallEnd;
        lift = (1 - easeInQuad(f)) * cell * 0.95;
        sx = 0.90;
        sy = 1.16;
      } else {
        // Aterriza aplastada y se asienta con resorte.
        final s = spring((u - fallEnd) / (1 - fallEnd));
        sy = 1 - 0.26 * s;
        sx = 1 + 0.20 * s;
      }
    }
    final fade = _fades[cellIndex];
    if (fade != null) alpha = fade.p;

    final hop = _hops[cellIndex];
    if (hop != null) {
      if (hop.flag) {
        // Reducido: sin salto; la casilla se ilumina con un fundido.
        skin.paintCellGlow(canvas, r, math.sin(math.pi * hop.p) * 0.4);
      } else {
        final u = hop.p;
        lift = math.sin(math.pi * u) * cell * 0.48;
        if (u < 0.12) {
          sy = 1 - 0.14 * (u / 0.12);
          sx = 1 + 0.10 * (u / 0.12);
        } else if (u > 0.88) {
          final k = (u - 0.88) / 0.12;
          sy = 0.88 + 0.12 * k;
          sx = 1.1 - 0.1 * k;
        } else {
          sy = 1.06;
          sx = 0.96;
        }
      }
    }

    skin.paintTokenShadow(canvas, center, radius, lift: lift, alpha: alpha);

    canvas.save();
    canvas.translate(feet.dx, feet.dy - lift);
    canvas.scale(sx * breath, sy * breath);
    canvas.translate(-feet.dx, -feet.dy);
    skin.paintToken(
      canvas,
      center,
      radius,
      TokenStyle(
        charIndex: idx,
        initial: _initialOf(charId),
        victim: victim,
        eyeOpen: victim ? 1 : _eyeOpenFor(idx),
        alpha: alpha,
        female: _femaleOf(charId),
      ),
    );
    canvas.restore();
  }
}

// -----------------------------------------------------------------------------
// Efectos: ondas, destellos, barras de luz y partículas
// -----------------------------------------------------------------------------

class _Ring {
  _Ring(this.center, this.dur);
  final ui.Offset center;
  final double dur;
  double t = 0;
}

class _Glow {
  _Glow(this.cell, this.peak, this.dur);
  final int cell;
  final double peak;
  final double dur;
  double t = 0;
}

class _Bar {
  _Bar(this.row, this.reduced);
  final int row;
  final bool reduced;
  double t = 0;
}

class EffectsLayer extends Component with HasGameReference<BoardGame> {
  EffectsLayer() : super(priority: 2);

  final ParticlePool particles = ParticlePool();
  final List<_Ring> _rings = [];
  final List<_Glow> _glows = [];
  final List<_Bar> _bars = [];
  // Destello de 1 cuadro: casilla + cuadros restantes.
  final Map<int, int> _flashes = {};

  void addRipple(int cell) {
    _rings.add(_Ring(game.geometry.cellCenter(cell), 0.34));
    if (_rings.length > 12) _rings.removeAt(0);
  }

  void addFlash(int cell) => _flashes[cell] = 2;

  void addGlow(int cell, double peak, double dur) {
    _glows.add(_Glow(cell, peak, dur));
    if (_glows.length > 16) _glows.removeAt(0);
  }

  void addRowBar(int row, {required bool reduced}) {
    _bars.add(_Bar(row, reduced));
  }

  void confetti(int cell, int count,
      {double speed = 170, double upward = 0.6, double size = 5}) {
    particles.burst(
      game.geometry.cellCenter(cell),
      count,
      game.skin.confettiColors,
      cap: game.settings.particleCap,
      speed: speed,
      upward: upward,
      size: size,
    );
  }

  void clearAll() {
    _rings.clear();
    _glows.clear();
    _bars.clear();
    _flashes.clear();
    particles.clear();
  }

  @override
  void update(double dt) {
    for (final r in _rings) {
      r.t += dt;
    }
    _rings.removeWhere((r) => r.t >= r.dur);
    for (final x in _glows) {
      x.t += dt;
    }
    _glows.removeWhere((x) => x.t >= x.dur);
    for (final b in _bars) {
      b.t += dt;
    }
    _bars.removeWhere((b) => b.t >= 0.55);
    if (_flashes.isNotEmpty) {
      _flashes.updateAll((_, v) => v - 1);
      _flashes.removeWhere((_, v) => v <= 0);
    }
    particles.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final g = game.geometry;
    final skin = game.skin;
    final cell = g.cell;

    // Ondas de papel: un anillo que se abre desde la casilla.
    for (final r in _rings) {
      final u = r.t / r.dur;
      final radius = cell * (0.25 + 0.75 * easeOutCubic(u));
      canvas.drawCircle(
        r.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07 * (1 - u)
          ..color = skin.light.withValues(alpha: 0.75 * (1 - u)),
      );
    }

    // Fundidos suaves.
    for (final x in _glows) {
      final u = x.t / x.dur;
      skin.paintCellGlow(canvas, g.cellRect(x.cell), x.peak * math.sin(math.pi * u));
    }

    // Barras de luz de la ola de resolver.
    for (final b in _bars) {
      final u = (b.t / 0.55).clamp(0.0, 1.0);
      final rowRect = ui.Rect.fromLTWH(
          g.board.left, g.board.top + b.row * cell, g.board.width, cell);
      if (b.reduced) continue; // en reducido la fila se ilumina en PiecesLayer
      final w = cell * 3.0;
      final cx = g.board.left - w / 2 + (g.board.width + w) * easeOutCubic(u);
      final bar = ui.Rect.fromLTWH(cx - w / 2, rowRect.top, w, rowRect.height)
          .intersect(rowRect);
      if (bar.isEmpty) continue;
      canvas.drawRect(
        bar,
        Paint()
          ..shader = LinearGradient(
            colors: [
              skin.light.withValues(alpha: 0),
              skin.light.withValues(alpha: 0.65),
              skin.light.withValues(alpha: 0),
            ],
          ).createShader(ui.Rect.fromLTWH(cx - w / 2, 0, w, 1)),
      );
    }

    // Destello de un solo cuadro.
    for (final c in _flashes.keys) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(g.cellRect(c).deflate(1), Radius.circular(cell * 0.1)),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }

    particles.render(canvas);
  }
}

// -----------------------------------------------------------------------------
// Sobre todo: viñeta, error, estrellas
// -----------------------------------------------------------------------------

class FxOverlay extends Component with HasGameReference<BoardGame> {
  FxOverlay() : super(priority: 10);

  ui.Image? _vignette;
  ui.Size _size = ui.Size.zero;

  /// Oscurecimiento de la revelación (0..1).
  double dark = 0;
  double darkTarget = 0;

  /// Foco sobre el asesino (0..1) y su casilla.
  double spot = 0;
  double spotTarget = 0;
  int? spotCell;

  /// Tinte de error (0..1) que se desvanece.
  double errorFade = 0;

  String? errorText;
  double _errorAge = 99;
  bool _errorReduced = false;

  /// Edad de cada estrella (-1 = aún no aparece).
  final List<double> starAge = [-1, -1, -1];
  String? label;
  double labelAge = -1;

  final Map<String, TextPainter> _text = {};

  void rebuild(ui.Size size) {
    _vignette?.dispose();
    _vignette = null;
    _size = size;
    if (size.isEmpty) return;
    // Viñeta de luz: se hornea una vez en media resolución.
    const k = 0.5;
    final w = (size.width * k).ceil(), h = (size.height * k).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rect = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    // Luz cálida desde arriba a la izquierda.
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 0.95,
          colors: [
            game.skin.light.withValues(alpha: 0.16),
            game.skin.light.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
    // Bordes oscuros.
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.98,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            // Viñeta de la piel: más suave en modo claro.
            Color.fromRGBO(24, 12, 6, game.skin.palette.isDark ? 0.5 : 0.34),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    final pic = rec.endRecording();
    try {
      _vignette = pic.toImageSync(w, h);
    } catch (_) {
      _vignette = null;
    }
    pic.dispose();
  }

  void showError(String text, {required bool reduced}) {
    errorText = text;
    _errorAge = 0;
    _errorReduced = reduced;
  }

  void popStar(int i) {
    if (i >= 0 && i < starAge.length) starAge[i] = 0;
  }

  void resetReveal() {
    dark = darkTarget = 0;
    spot = spotTarget = 0;
    spotCell = null;
    for (var i = 0; i < starAge.length; i++) {
      starAge[i] = -1;
    }
    label = null;
    labelAge = -1;
  }

  /// Salta al final: todo queda en su estado final.
  void finishReveal() {
    dark = darkTarget = math.max(darkTarget, 0.8);
    spot = spotTarget = 1;
    for (var i = 0; i < starAge.length; i++) {
      starAge[i] = 5;
    }
    labelAge = 5;
  }

  @override
  void update(double dt) {
    dark += (darkTarget - dark) * math.min(1.0, dt * 5);
    spot += (spotTarget - spot) * math.min(1.0, dt * 5);
    if (errorFade > 0) errorFade = math.max(0, errorFade - dt * 2.4);
    if (_errorAge < 10) _errorAge += dt;
    for (var i = 0; i < starAge.length; i++) {
      if (starAge[i] >= 0) starAge[i] += dt;
    }
    if (starAge[0] >= 0.15 && labelAge < 0) labelAge = 0;
    if (labelAge >= 0) labelAge += dt;
  }

  TextPainter _tp(String s, double size, Color color, {FontWeight w = FontWeight.w800}) {
    final key = '$s|${size.toStringAsFixed(1)}|${color.toARGB32()}';
    return _text.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontSize: size, color: color, fontWeight: w, height: 1.1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: _size.width * 0.9),
    );
  }

  @override
  void render(Canvas canvas) {
    final size = _size;
    if (size.isEmpty) return;
    final screen = ui.Offset.zero & size;
    final skin = game.skin;

    // Viñeta de luz (siempre) y oscurecimiento de la revelación.
    final v = _vignette;
    if (v != null) {
      canvas.drawImageRect(
        v,
        ui.Rect.fromLTWH(0, 0, v.width.toDouble(), v.height.toDouble()),
        screen,
        Paint()..filterQuality = FilterQuality.low,
      );
      if (dark > 0.01) {
        canvas.drawImageRect(
          v,
          ui.Rect.fromLTWH(0, 0, v.width.toDouble(), v.height.toDouble()),
          screen,
          Paint()
            ..filterQuality = FilterQuality.low
            ..color = Color.fromRGBO(0, 0, 0, dark.clamp(0.0, 1.0)),
        );
      }
    }
    if (dark > 0.01) {
      canvas.drawRect(screen, Paint()..color = Color.fromRGBO(8, 8, 14, 0.5 * dark));
    }

    // Foco sobre el asesino.
    if (spot > 0.01 && spotCell != null) {
      final c = game.rig.toScreen(game.geometry.cellCenter(spotCell!), size);
      final radius = game.geometry.cell * game.rig.scale * 1.7;
      canvas.drawRect(
        screen,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0x00000000),
              const Color(0x00000000),
              Color.fromRGBO(0, 0, 0, 0.55 * spot),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(ui.Rect.fromCircle(center: c, radius: radius * 2.2)),
      );
    }

    // Tinte de error (versión con fundido, también refuerza la sacudida).
    if (errorFade > 0.01) {
      canvas.drawRect(
          screen, Paint()..color = skin.errorTint.withValues(alpha: 0.30 * errorFade));
    }

    // Texto del error: "N casillas no cuadran".
    if (errorText != null && _errorAge < 1.9) {
      final a = _errorAge;
      final alpha = a < 0.12 ? a / 0.12 : (a > 1.5 ? (1.9 - a) / 0.4 : 1.0);
      final scale = _errorReduced ? 1.0 : 0.9 + 0.1 * easeOutBack((a / 0.2).clamp(0.0, 1.0));
      final tp = _tp(errorText!, math.min(size.width * 0.062, 26), const Color(0xFFFFFFFF));
      final w = tp.width + 36, h = tp.height + 22;
      canvas.save();
      canvas.translate(size.width / 2, size.height * 0.5);
      canvas.scale(scale);
      final pill = RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: ui.Offset.zero, width: w, height: h),
          Radius.circular(h / 2));
      canvas.drawRRect(
          pill, Paint()..color = Color.lerp(skin.palette.errorTint, const Color(0xFF000000), 0.3)!.withValues(alpha: 0.94 * alpha));
      canvas.drawRRect(
          pill,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xFFFFD2C8).withValues(alpha: 0.8 * alpha));
      final tpa = _tp(errorText!, math.min(size.width * 0.062, 26),
          const Color(0xFFFFFFFF).withValues(alpha: alpha));
      tpa.paint(canvas, ui.Offset(-tpa.width / 2, -tpa.height / 2));
      canvas.restore();
    }

    // Estrellas y rótulo del asesino.
    final anyStar = starAge.any((a) => a >= 0);
    if (anyStar) {
      final r = math.min(size.width, size.height) * 0.075;
      final y = size.height * 0.2;
      for (var i = 0; i < starAge.length; i++) {
        final a = starAge[i];
        if (a < 0) continue;
        final u = (a / 0.38).clamp(0.0, 1.0);
        final reduced = game.settings.reduceMotion;
        final s = reduced ? 1.0 : easeOutBack(u);
        final x = size.width / 2 + (i - 1) * r * 2.5;
        final yy = y - (i == 1 ? r * 0.35 : 0);
        canvas.save();
        canvas.translate(x, yy);
        canvas.scale(s);
        if (!reduced) canvas.rotate((1 - u) * 0.5 * (i.isEven ? -1 : 1));
        skin.paintStar(canvas, ui.Offset.zero, r, reduced ? u : 1.0);
        canvas.restore();
      }
    }
    if (label != null && labelAge >= 0) {
      final alpha = (labelAge / 0.35).clamp(0.0, 1.0);
      final tp = _tp(label!, math.min(size.width * 0.07, 28), const Color(0xFFFFFFFF));
      final w = tp.width + 40, h = tp.height + 22;
      final c = ui.Offset(size.width / 2, size.height * 0.2 + math.min(size.width, size.height) * 0.19);
      final pill = RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: c, width: w, height: h), Radius.circular(h / 2));
      canvas.drawRRect(pill, Paint()..color = skin.palette.pill.withValues(alpha: 0.82 * alpha));
      final tpa = _tp(label!, math.min(size.width * 0.07, 28),
          const Color(0xFFFFFFFF).withValues(alpha: alpha));
      tpa.paint(canvas, c - ui.Offset(tpa.width / 2, tpa.height / 2));
    }
  }

  @override
  void onRemove() {
    _vignette?.dispose();
    super.onRemove();
  }
}

/// Estado de la cámara de la escena (sacudida, golpe y zoom al asesino).
class CameraRig {
  double zoomT = 0;
  ui.Offset focus = ui.Offset.zero;
  static const zoomMax = 1.85;
  ui.Offset shake = ui.Offset.zero;
  double punch = 0;

  double get scale => (1 + (zoomMax - 1) * zoomT) * (1 + punch);

  ui.Offset _pivot(ui.Size size) =>
      ui.Offset.lerp(size.center(ui.Offset.zero), focus, zoomT)!;

  void apply(Canvas canvas, ui.Size size) {
    final c = size.center(ui.Offset.zero);
    final f = _pivot(size);
    canvas.translate(c.dx + shake.dx, c.dy + shake.dy);
    canvas.scale(scale);
    canvas.translate(-f.dx, -f.dy);
  }

  ui.Offset toScene(ui.Offset screen, ui.Size size) {
    final c = size.center(ui.Offset.zero);
    final f = _pivot(size);
    return f + (screen - c - shake) / scale;
  }

  ui.Offset toScreen(ui.Offset scene, ui.Size size) {
    final c = size.center(ui.Offset.zero);
    final f = _pivot(size);
    return c + shake + (scene - f) * scale;
  }

  void reset() {
    zoomT = 0;
    shake = ui.Offset.zero;
    punch = 0;
  }
}

/// La raíz de la escena: aplica la cámara a sus capas.
class SceneRoot extends Component with HasGameReference<BoardGame> {
  SceneRoot() : super(priority: 5);

  @override
  void render(Canvas canvas) {
    canvas.save();
    game.rig.apply(canvas, game.viewSize);
  }

  @override
  void afterChildrenRendered(Canvas canvas) {
    canvas.restore();
  }
}
