// android/app/src/main/kotlin/com/toolbox/scanner/NativePlugin.kt
// JNI 桥接 Android 端
package com.toolbox.scanner

class NativePlugin {
    companion object {
        init {
            System.loadLibrary("toolbox_opencv")
        }
    }

    external fun warpPerspective(
        srcBytes: ByteArray,
        srcW: Int,
        srcH: Int,
        corners: DoubleArray,
        outBytes: ByteArray,
        outW: Int,
        outH: Int
    ): Int
}
