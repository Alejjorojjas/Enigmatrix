/// Opciones del jugador que se guardan en el teléfono (shared_preferences).
///
/// Claves (solo cache local de preferencias, nunca fuente de verdad):
///  - `cfg:piel`      "ilustrada" o "papel" (la "neutra" solo existe como
///                    respaldo de desarrollo y no se ofrece al jugador).
///  - `cfg:modo`      "sistema", "claro" u "oscuro".
///  - `cfg:sonido`    bool, por omisión true.
///  - `cfg:vibracion` bool, por omisión true.
///  - `cfg:movimiento-reducido` bool, "Reducir movimiento" (apagado; el
///                    sistema también puede pedirlo desde el teléfono).
///  - `cfg:fps`       bool, medidor de FPS de depuración (apagado).
library;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../board/board_settings.dart';
import 'feedback_providers.dart' show RingerMode;

/// Pieles que ve el jugador en Configuración.
const kPlayerSkins = ['ilustrada', 'papel'];

/// Piel con la que arranca la app.
const kDefaultSkin = 'ilustrada';

class AppSettings implements BoardSettings {
  const AppSettings({
    this.skinId = kDefaultSkin,
    this.themeMode = ThemeMode.system,
    this.soundOn = true,
    this.hapticsOn = true,
    this.reduceMotion = false,
    this.particleCap = 40,
    this.fpsMeter = false,
  });

  static const defaults = AppSettings();

  static const skinKey = 'cfg:piel';
  static const modeKey = 'cfg:modo';
  static const soundKey = 'cfg:sonido';
  static const hapticsKey = 'cfg:vibracion';
  static const reduceMotionKey = 'cfg:movimiento-reducido';
  static const fpsKey = 'cfg:fps';

  final String skinId;
  final ThemeMode themeMode;
  @override
  final bool soundOn;
  @override
  final bool hapticsOn;
  @override
  final bool reduceMotion;
  @override
  final int particleCap;
  final bool fpsMeter;

  AppSettings copyWith({
    String? skinId,
    ThemeMode? themeMode,
    bool? soundOn,
    bool? hapticsOn,
    bool? reduceMotion,
    int? particleCap,
    bool? fpsMeter,
  }) => AppSettings(
    skinId: skinId ?? this.skinId,
    themeMode: themeMode ?? this.themeMode,
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    particleCap: particleCap ?? this.particleCap,
    fpsMeter: fpsMeter ?? this.fpsMeter,
  );

  // ---- texto guardado <-> valor ------------------------------------------------

  static String modeToText(ThemeMode m) => switch (m) {
    ThemeMode.light => 'claro',
    ThemeMode.dark => 'oscuro',
    ThemeMode.system => 'sistema',
  };

  static ThemeMode modeFromText(String? t) => switch (t) {
    'claro' => ThemeMode.light,
    'oscuro' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Una piel guardada que ya no existe (o está dañada) vuelve a la de
  /// arranque. La neutra se acepta solo si alguien la dejó guardada a mano.
  static String skinFromText(String? t) =>
      (t == 'ilustrada' || t == 'papel' || t == 'neutra') ? t! : kDefaultSkin;

  /// Lee lo guardado; todo lo que falte o esté dañado toma su valor de
  /// arranque.
  static AppSettings fromPrefs(SharedPreferences prefs) {
    String? str(String k) {
      final v = prefs.get(k);
      return v is String ? v : null;
    }

    bool flag(String k, bool fallback) {
      final v = prefs.get(k);
      return v is bool ? v : fallback;
    }

    return AppSettings(
      skinId: skinFromText(str(skinKey)),
      themeMode: modeFromText(str(modeKey)),
      soundOn: flag(soundKey, true),
      hapticsOn: flag(hapticsKey, true),
      reduceMotion: flag(reduceMotionKey, false),
      fpsMeter: flag(fpsKey, false),
    );
  }

  /// Lee las opciones guardadas sin lanzar nunca (si no hay almacenamiento,
  /// devuelve los valores de arranque).
  static Future<AppSettings> load() async {
    try {
      return fromPrefs(await SharedPreferences.getInstance());
    } catch (_) {
      return defaults;
    }
  }

  /// Opciones tal como las usa la escena en este momento: el movimiento se
  /// reduce si el jugador o el sistema lo piden, y el modo silencio del
  /// teléfono manda sobre los interruptores (silencio: ni sonido ni
  /// vibración; vibrar: sin sonido).
  AppSettings effective({
    required bool systemReduceMotion,
    RingerMode ringer = RingerMode.normal,
  }) => copyWith(
    reduceMotion: reduceMotion || systemReduceMotion,
    soundOn: soundOn && ringer == RingerMode.normal,
    hapticsOn: hapticsOn && ringer != RingerMode.silent,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.skinId == skinId &&
      other.themeMode == themeMode &&
      other.soundOn == soundOn &&
      other.hapticsOn == hapticsOn &&
      other.reduceMotion == reduceMotion &&
      other.particleCap == particleCap &&
      other.fpsMeter == fpsMeter;

  @override
  int get hashCode => Object.hash(
    skinId,
    themeMode,
    soundOn,
    hapticsOn,
    reduceMotion,
    particleCap,
    fpsMeter,
  );
}

/// Opciones ya leídas al arrancar (main.dart las carga antes del primer
/// cuadro para que el tema no parpadee). En pruebas vale lo de arranque.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => AppSettings.defaults,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final initial = ref.read(initialSettingsProvider);
    // Si no se precargaron (pruebas, o el primer cuadro llegó antes), se
    // leen ahora y se aplican sin pisar un cambio hecho mientras tanto.
    var alive = true;
    ref.onDispose(() => alive = false);
    if (identical(initial, AppSettings.defaults)) {
      Future<void>(() async {
        final loaded = await AppSettings.load();
        if (alive && state == AppSettings.defaults) state = loaded;
      });
    }
    return initial;
  }

  Future<void> _save(Future<void> Function(SharedPreferences p) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {
      // Es solo una preferencia: si no se puede guardar, se usa igual.
    }
  }

  void setSkin(String id) {
    final v = AppSettings.skinFromText(id);
    if (v == state.skinId) return;
    state = state.copyWith(skinId: v);
    _save((p) => p.setString(AppSettings.skinKey, v));
  }

  void setThemeMode(ThemeMode m) {
    if (m == state.themeMode) return;
    state = state.copyWith(themeMode: m);
    _save((p) => p.setString(AppSettings.modeKey, AppSettings.modeToText(m)));
  }

  void setSound(bool on) {
    if (on == state.soundOn) return;
    state = state.copyWith(soundOn: on);
    _save((p) => p.setBool(AppSettings.soundKey, on));
  }

  void setHaptics(bool on) {
    if (on == state.hapticsOn) return;
    state = state.copyWith(hapticsOn: on);
    _save((p) => p.setBool(AppSettings.hapticsKey, on));
  }

  /// "Reducir movimiento": sin rebotes, sacudidas ni partículas. El director
  /// de feedback lo aplica (junto con la opción del sistema).
  void setReduceMotion(bool on) {
    if (on == state.reduceMotion) return;
    state = state.copyWith(reduceMotion: on);
    _save((p) => p.setBool(AppSettings.reduceMotionKey, on));
  }

  void setFpsMeter(bool on) {
    if (on == state.fpsMeter) return;
    state = state.copyWith(fpsMeter: on);
    _save((p) => p.setBool(AppSettings.fpsKey, on));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
