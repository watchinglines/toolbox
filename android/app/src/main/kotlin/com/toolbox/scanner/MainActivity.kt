// android/app/src/main/kotlin/com/toolbox/scanner/MainActivity.kt
package com.toolbox.scanner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.toolbox/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformVersion" -> {
                        result.success("Android ${android.os.Build.VERSION.RELEASE}")
                    }
                    "scanDocument" -> {
                        // 实际集成 google_mlkit_document_scanner
                        result.success(null)
                    }
                    "startAR" -> {
                        // ARCore 测量
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
