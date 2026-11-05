/// Servicio de sonido con flutter_soloud (baja latencia, varias voces a la
/// vez). Carga los 12 .wav propios una sola vez al arrancar y los dispara
/// sin esperar. Si el audio no arranca (emulador sin sonido, por ejemplo), el
/// prototipo sigue funcionando en silencio y lo avisa en Opciones.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../feedback/feedback_director.dart';
import '../feedback/feedback_plan.dart';

class SoloudSoundService implements SoundSink {
  final Map<SoundId, AudioSource> _sources = {};
  final Map<SoundId, SoundHandle> _longHandles = {};
  bool _ready = false;

  /// Mensaje si algo falló al iniciar (null si todo bien).
  String? error;

  bool get ready => _ready;

  Future<void> init() async {
    // En el navegador no se inicia el audio: flutter_soloud necesita cargar
    // un módulo extra y, para las capturas, no hace falta. En Android sí suena.
    if (kIsWeb) {
      error = 'desactivado en el navegador (en Android sí suena)';
      return;
    }
    try {
      final soloud = SoLoud.instance;
      await soloud.init();
      for (final id in SoundId.values) {
        _sources[id] = await soloud.loadAsset(id.asset);
      }
      _ready = true;
    } catch (e) {
      error = '$e';
      _ready = false;
      debugPrint('Audio no disponible: $e');
    }
  }

  @override
  void play(SoundCue cue) {
    if (!_ready) return;
    final src = _sources[cue.id];
    if (src == null) return;
    try {
      final soloud = SoLoud.instance;
      final handle = soloud.play(src, volume: cue.volume);
      if (cue.speed != 1.0) soloud.setRelativePlaySpeed(handle, cue.speed);
      if (cue.id.isLong) _longHandles[cue.id] = handle;
    } catch (e) {
      debugPrint('No se pudo reproducir ${cue.id}: $e');
    }
  }

  /// Corta los sonidos largos (redoble, golpe, estrellas, fanfarria): se usa
  /// al saltar la secuencia de resolver.
  @override
  void stopLong() {
    if (!_ready) return;
    for (final h in _longHandles.values) {
      try {
        SoLoud.instance.stop(h);
      } catch (_) {}
    }
    _longHandles.clear();
  }

  void dispose() {
    if (!_ready) return;
    try {
      SoLoud.instance.deinit();
    } catch (_) {}
    _ready = false;
  }
}

/// Sonido apagado: se usa en pruebas y donde no hay audio.
class SilentSoundSink implements SoundSink {
  const SilentSoundSink();

  @override
  void play(SoundCue cue) {}

  @override
  void stopLong() {}
}
