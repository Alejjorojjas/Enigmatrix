/// Servicios de sonido, vibración y modo silencio de la partida. Cada uno se
/// puede cambiar en las pruebas con un `override` del proveedor.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/audio/audio_service.dart' show SilentSoundSink;
import '../board/audio/haptics_service.dart';
import '../board/feedback/feedback_director.dart';

/// Destino de los sonidos. Por omisión no suena; main.dart lo reemplaza con
/// el servicio de flutter_soloud (SoloudSoundService).
final soundSinkProvider = Provider<SoundSink>((ref) => const SilentSoundSink());

/// Destino de la vibración.
final hapticSinkProvider = Provider<HapticSink>(
  (ref) => FlutterHapticService(),
);

/// Modo de timbre del teléfono.
enum RingerMode { normal, vibrate, silent }

abstract class RingerProbe {
  Future<RingerMode> read();
}

/// Lee el modo de timbre de Android con un canal propio (ver MainActivity.kt).
/// Donde no existe (web, pruebas, iOS) se asume modo normal.
class AndroidRingerProbe implements RingerProbe {
  static const _channel = MethodChannel('com.enigmatrix/ringer');

  @override
  Future<RingerMode> read() async {
    try {
      final v = await _channel.invokeMethod<int>('mode');
      return switch (v) {
        0 => RingerMode.silent,
        1 => RingerMode.vibrate,
        _ => RingerMode.normal,
      };
    } catch (_) {
      return RingerMode.normal;
    }
  }
}

final ringerProbeProvider = Provider<RingerProbe>(
  (ref) => AndroidRingerProbe(),
);
