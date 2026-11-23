package ar.gramonia.rpg

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // El juego pregunta si el celular está en modo silencio para no
        // tocar música. En modo vibración, la música suena.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gramonia/sonido")
            .setMethodCallHandler { call, result ->
                if (call.method == "enSilencio") {
                    val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audio.ringerMode == AudioManager.RINGER_MODE_SILENT)
                } else {
                    result.notImplemented()
                }
            }
    }
}
