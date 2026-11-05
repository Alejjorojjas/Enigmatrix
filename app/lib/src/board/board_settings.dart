/// Lo que la escena y el director de feedback necesitan saber de las
/// opciones del jugador. La app lo implementa con `AppSettings`
/// (lib/src/game/app_settings.dart), que se guarda en shared_preferences.
library;

abstract class BoardSettings {
  /// Efectos de sonido encendidos.
  bool get soundOn;

  /// Vibración encendida.
  bool get hapticsOn;

  /// Cambia sacudidas, saltos y destellos por fundidos suaves.
  bool get reduceMotion;

  /// Tope de partículas por ráfaga (0 las apaga).
  int get particleCap;
}
