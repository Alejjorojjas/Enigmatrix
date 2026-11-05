package com.enigmatrix.enigmatrix

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Modo de timbre del teléfono (0 silencio, 1 vibrar, 2 normal), para que
    // el juego respete el modo silencio. No necesita permisos.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.enigmatrix/ringer")
            .setMethodCallHandler { call, result ->
                if (call.method == "mode") {
                    val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audio.ringerMode)
                } else {
                    result.notImplemented()
                }
            }
    }
}
