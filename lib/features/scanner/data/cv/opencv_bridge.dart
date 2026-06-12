// lib/features/scanner/data/cv/opencv_bridge.dart
// OpenCV FFI 桥接(可选,需要 native 库)
// 通过 dart:ffi 调用 OpenCV 编译后的动态库
// iOS: ios/Frameworks/opencv2.framework
// Android: libopencv_java4.so (Android NDK)
//
// 使用方式:
// 1. iOS: 在 ios/Runner/Frameworks/ 中放入 opencv2.framework
// 2. Android: 在 android/app/build.gradle 中配置 externalNativeBuild
// 3. 启用方法: 在 main.dart 中设置 useOpenCV = true
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// 类型别名:用 platform geometry 的 ui.Offset 不必要,直接用 (double, double) 列表
typedef Point2D = ({double x, double y});

/// OpenCV FFI 桥接器 - 包装关键 C 函数
class OpenCVBridge {
  static ffi.DynamicLibrary? _lib;

  /// 加载原生库(按平台)
  static ffi.DynamicLibrary load() {
    if (_lib != null) return _lib!;
    if (Platform.isIOS) {
      _lib = ffi.DynamicLibrary.process(); // iOS 静态链接
    } else if (Platform.isAndroid) {
      _lib = ffi.DynamicLibrary.open('libtoolbox_opencv.so');
    } else {
      _lib = ffi.DynamicLibrary.process();
    }
    return _lib!;
  }

  /// 原生函数: 透视矫正(单应矩阵 + 双线性插值)
  /// 比纯 Dart 快 5-10x
  static Uint8List? warpPerspective({
    required Uint8List srcImage,
    required int srcW,
    required int srcH,
    required List<Point2D> srcCorners,
    required int outW,
    required int outH,
  }) {
    if (!Platform.isIOS && !Platform.isAndroid) return null;
    try {
      final lib = load();
      // 查找原生函数
      final warpFunc = lib.lookupFunction<
        WarpPerspectiveNative,
        WarpPerspectiveDart
      >('toolbox_warp_perspective');

      // 分配堆内存并填充角点
      final cornersPtr = calloc<ffi.Double>(8);
      for (int i = 0; i < 4; i++) {
        cornersPtr[i * 2] = srcCorners[i].x;
        cornersPtr[i * 2 + 1] = srcCorners[i].y;
      }

      // 分配输出缓冲区
      final outPtr = calloc<ffi.Uint8>(outW * outH * 3);
      final srcPtr = calloc<ffi.Uint8>(srcImage.length);
      final srcList = srcPtr.asTypedList(srcImage.length);
      srcList.setAll(0, srcImage);

      try {
        final result = warpFunc(
          srcPtr, srcW, srcH,
          cornersPtr,
          outPtr, outW, outH,
        );

        if (result == 0) {
          final bytes = Uint8List.fromList(outPtr.asTypedList(outW * outH * 3));
          return bytes;
        }
        return null;
      } finally {
        calloc.free(cornersPtr);
        calloc.free(outPtr);
        calloc.free(srcPtr);
      }
    } catch (e) {
      // 原生库未集成,降级到纯 Dart 实现
      return null;
    }
  }
}

// 原生函数签名
typedef WarpPerspectiveNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32,
);
typedef WarpPerspectiveDart = int Function(
  ffi.Pointer<ffi.Uint8>, int, int,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Uint8>, int, int,
);
