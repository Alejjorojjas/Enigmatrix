/// Opciones del prototipo. Viven solo en memoria (no hay persistencia a
/// propósito: es una prueba, no la app).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

class GameSettings extends ChangeNotifier {
  GameSettings({
    bool soundOn = true,
    bool hapticsOn = true,
    bool reduceMotion = false,
    int particleCap = 40,
    bool fpsMeter = false,
    bool doubleTapConfirm = true,
    bool autoX = true,
    String skinId = defaultSkin,
    ThemeMode themeMode = ThemeMode.system,
  })  : _skinId = skinId,
        _themeMode = themeMode,
        _soundOn = soundOn,
        _hapticsOn = hapticsOn,
        _reduceMotion = reduceMotion,
        _particleCap = particleCap,
        _fpsMeter = fpsMeter,
        _doubleTapConfirm = doubleTapConfirm,
        _autoX = autoX;

  /// Piel con la que arranca el prototipo.
  static const defaultSkin = 'ilustrada';

  /// Valores de tope de partículas que ofrece el menú (gama baja a alta).
  static const particleCapChoices = [0, 20, 40, 80];

  bool _soundOn;
  bool _hapticsOn;
  bool _reduceMotion;
  int _particleCap;
  bool _fpsMeter;
  bool _doubleTapConfirm;
  bool _autoX;
  String _skinId;
  ThemeMode _themeMode;

  bool get soundOn => _soundOn;
  bool get hapticsOn => _hapticsOn;
  bool get reduceMotion => _reduceMotion;
  int get particleCap => _particleCap;
  bool get fpsMeter => _fpsMeter;
  bool get doubleTapConfirm => _doubleTapConfirm;
  bool get autoX => _autoX;

  /// Piel activa ("ilustrada", "papel" o "neutra").
  String get skinId => _skinId;

  /// Modo claro u oscuro. Arranca en [ThemeMode.system] (el del teléfono).
  ThemeMode get themeMode => _themeMode;

  set soundOn(bool v) => _set(() => _soundOn = v, _soundOn != v);
  set hapticsOn(bool v) => _set(() => _hapticsOn = v, _hapticsOn != v);
  set reduceMotion(bool v) => _set(() => _reduceMotion = v, _reduceMotion != v);
  set particleCap(int v) =>
      _set(() => _particleCap = v.clamp(0, 150), _particleCap != v);
  set fpsMeter(bool v) => _set(() => _fpsMeter = v, _fpsMeter != v);
  set doubleTapConfirm(bool v) =>
      _set(() => _doubleTapConfirm = v, _doubleTapConfirm != v);
  set autoX(bool v) => _set(() => _autoX = v, _autoX != v);
  set skinId(String v) => _set(() => _skinId = v, _skinId != v);
  set themeMode(ThemeMode v) => _set(() => _themeMode = v, _themeMode != v);

  void _set(VoidCallback apply, bool changed) {
    if (!changed) return;
    apply();
    notifyListeners();
  }
}
