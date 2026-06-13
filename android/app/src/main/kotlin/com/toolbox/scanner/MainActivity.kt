package com.toolbox.scanner

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
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
                        // TODO: integrate google_mlkit_document_scanner
                        result.success(null)
                    }
                    "startAR" -> {
                        // TODO: ARCore measurement
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
