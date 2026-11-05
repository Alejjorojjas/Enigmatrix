/// Partículas de papel (confeti). Un solo arreglo fijo, sin crear objetos por
/// cuadro. El tope de partículas vivas se pasa en cada ráfaga, así el menú de
/// opciones lo cambia en caliente.
library;

import 'dart:math' as math;
import 'dart:ui';

class ParticlePool {
  ParticlePool({this.capacity = 160, int seed = 7}) : _rng = math.Random(seed) {
    _x = List.filled(capacity, 0.0);
    _y = List.filled(capacity, 0.0);
    _vx = List.filled(capacity, 0.0);
    _vy = List.filled(capacity, 0.0);
    _rot = List.filled(capacity, 0.0);
    _vrot = List.filled(capacity, 0.0);
    _life = List.filled(capacity, 0.0);
    _maxLife = List.filled(capacity, 1.0);
    _size = List.filled(capacity, 4.0);
    _color = List.filled(capacity, 0);
  }

  final int capacity;
  final math.Random _rng;

  late final List<double> _x, _y, _vx, _vy, _rot, _vrot, _life, _maxLife, _size;
  late final List<int> _color;

  final Paint _paint = Paint();

  int get active {
    var n = 0;
    for (var i = 0; i < capacity; i++) {
      if (_life[i] > 0) n++;
    }
    return n;
  }

  /// Lanza [count] trozos desde [origin]. No pasa de [cap] partículas vivas.
  /// Devuelve cuántas lanzó realmente.
  int burst(
    Offset origin,
    int count,
    List<Color> colors, {
    required int cap,
    double speed = 170,
    double upward = 0.6,
    double size = 5,
    double life = 0.9,
  }) {
    var spawned = 0;
    var alive = active;
    final limit = cap.clamp(0, capacity);
    for (var i = 0; i < capacity && spawned < count && alive < limit; i++) {
      if (_life[i] > 0) continue;
      final ang = _rng.nextDouble() * math.pi * 2;
      final sp = speed * (0.45 + _rng.nextDouble() * 0.75);
      _x[i] = origin.dx;
      _y[i] = origin.dy;
      _vx[i] = math.cos(ang) * sp;
      _vy[i] = math.sin(ang) * sp - speed * upward;
      _rot[i] = _rng.nextDouble() * math.pi;
      _vrot[i] = (_rng.nextDouble() - 0.5) * 14;
      _maxLife[i] = life * (0.75 + _rng.nextDouble() * 0.5);
      _life[i] = _maxLife[i];
      _size[i] = size * (0.7 + _rng.nextDouble() * 0.7);
      _color[i] = colors[_rng.nextInt(colors.length)].toARGB32();
      spawned++;
      alive++;
    }
    return spawned;
  }

  void update(double dt) {
    for (var i = 0; i < capacity; i++) {
      if (_life[i] <= 0) continue;
      _life[i] -= dt;
      _vy[i] += 520 * dt; // gravedad
      _vx[i] *= (1 - 1.6 * dt).clamp(0.0, 1.0); // roce del aire
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      _rot[i] += _vrot[i] * dt;
    }
  }

  void render(Canvas canvas) {
    for (var i = 0; i < capacity; i++) {
      final l = _life[i];
      if (l <= 0) continue;
      final t = l / _maxLife[i];
      final a = t < 0.3 ? t / 0.3 : 1.0;
      _paint.color = Color(_color[i]).withValues(alpha: a);
      canvas.save();
      canvas.translate(_x[i], _y[i]);
      canvas.rotate(_rot[i]);
      // Un trozo de papel: rectángulo que "gira" de canto con el seno.
      final w = _size[i] * (0.35 + 0.65 * math.sin(_rot[i] * 2).abs());
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: w, height: _size[i]),
          _paint);
      canvas.restore();
    }
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      _life[i] = 0;
    }
  }
}
