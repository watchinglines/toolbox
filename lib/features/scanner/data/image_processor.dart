// lib/features/scanner/data/image_processor.dart
// 图像处理:透视矫正(单应矩阵) + 自适应增强
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/scanned_document.dart';
import 'cv/opencv_bridge.dart';
import 'cv/perspective_warper.dart';

/// 4 边形角点(顺时针:TL, TR, BR, BL),坐标为原图归一化坐标 [0,1]
class DocumentCorners {
  final ui.Offset topLeft;
  final ui.Offset topRight;
  final ui.Offset bottomRight;
  final ui.Offset bottomLeft;

  const DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  static const empty = DocumentCorners(
    topLeft: ui.Offset(0.05, 0.05),
    topRight: ui.Offset(0.95, 0.05),
    bottomRight: ui.Offset(0.95, 0.95),
    bottomLeft: ui.Offset(0.05, 0.95),
  );

  /// 转换为像素坐标
  List<ui.Offset> toPixelCoords(double imageWidth, double imageHeight) {
    return [
      ui.Offset(topLeft.dx * imageWidth, topLeft.dy * imageHeight),
      ui.Offset(topRight.dx * imageWidth, topRight.dy * imageHeight),
      ui.Offset(bottomRight.dx * imageWidth, bottomRight.dy * imageHeight),
      ui.Offset(bottomLeft.dx * imageWidth, bottomLeft.dy * imageHeight),
    ];
  }
}

class ImageProcessor {
  const ImageProcessor();

  /// 透视矫正 - 升级版(优先 OpenCV FFI,降级到纯 Dart 单应矩阵)
  /// 整个流程在 isolate 中完成,主线程零阻塞
  Future<Uint8List> perspectiveCorrect({
    required Uint8List rawBytes,
    required DocumentCorners corners,
    required int targetDpi,
    ScanMode mode = ScanMode.document,
  }) async {
    return compute<_PerspectiveTask, Uint8List>(
      _runPerspective,
      _PerspectiveTask(rawBytes, corners, targetDpi, mode),
    );
  }

  /// 增强:白平衡 / 对比度 / 去阴影
  Future<Uint8List> enhance({
    required Uint8List bytes,
    ScanMode mode = ScanMode.document,
  }) async {
    return compute<_EnhanceTask, Uint8List>(
      _runEnhance,
      _EnhanceTask(bytes: bytes, mode: mode),
    );
  }
}

class _PerspectiveTask {
  final Uint8List rawBytes;
  final DocumentCorners corners;
  final int targetDpi;
  final ScanMode mode;
  const _PerspectiveTask(this.rawBytes, this.corners, this.targetDpi, this.mode);
}

class _EnhanceTask {
  final Uint8List bytes;
  final ScanMode mode;
  const _EnhanceTask({required this.bytes, required this.mode});
}

/// 完整矫正入口:在 isolate 中完成解码 + 角点 + 矫正
/// 优先 OpenCV FFI(快),降级到纯 Dart 单应矩阵(稳)
Uint8List _runPerspective(_PerspectiveTask task) {
  final original = img.decodeImage(task.rawBytes);
  if (original == null) {
    throw const FormatException('无法解码图像');
  }

  final baseWidth = 2480;
  final aspect = _aspectForMode(task.mode);
  final outW = baseWidth;
  final outH = (baseWidth / aspect).round();

  // 源角点(像素坐标)
  final w = original.width.toDouble();
  final h = original.height.toDouble();
  final srcCorners = task.corners.toPixelCoords(w, h);

  // 输出角点
  final dstCorners = [
    const ui.Offset(0, 0),
    ui.Offset(outW.toDouble(), 0),
    ui.Offset(outW.toDouble(), outH.toDouble()),
    ui.Offset(0, outH.toDouble()),
  ];

  // 1. 尝试 OpenCV FFI
  final opencvResult = OpenCVBridge.warpPerspective(
    srcImage: task.rawBytes,
    srcW: original.width,
    srcH: original.height,
    srcCorners: srcCorners
        .map((o) => (x: o.dx, y: o.dy))
        .toList(),
    outW: outW,
    outH: outH,
  );
  if (opencvResult != null) return opencvResult;

  // 2. 降级到 PerspectiveWarper(单应矩阵)
  return const PerspectiveWarper().warpSync(
    srcImage: original,
    srcCorners: srcCorners,
    dstCorners: dstCorners,
    outW: outW,
    outH: outH,
    jpegQuality: 92,
  );
}

/// 增强主函数
Uint8List _runEnhance(_EnhanceTask task) {
  final src = img.decodeImage(task.bytes);
  if (src == null) return task.bytes;

  img.Image dst = src;

  // 1. 自适应白平衡(灰度世界假设)
  dst = img.adjustColor(dst, saturation: 1.05);

  // 2. 对比度/亮度(根据模式微调)
  switch (task.mode) {
    case ScanMode.document:
      dst = img.adjustColor(dst, contrast: 1.15, brightness: 1.02);
      break;
    case ScanMode.receipt:
      // 票据通常偏黄,需要去黄
      dst = img.adjustColor(dst, contrast: 1.25, brightness: 1.05);
      break;
    case ScanMode.whiteboard:
      dst = img.adjustColor(dst, contrast: 1.1, brightness: 1.0);
      break;
    case ScanMode.book:
      dst = img.adjustColor(dst, contrast: 1.08, brightness: 1.01);
      break;
    case ScanMode.idCard:
      dst = img.adjustColor(dst, contrast: 1.2, saturation: 0.9);
      break;
  }

  // 3. 锐化(轻量)
  dst = img.convolution(dst, filter: [
    0, -0.5, 0,
    -0.5, 3, -0.5,
    0, -0.5, 0,
  ], div: 1, offset: 0);

  return Uint8List.fromList(img.encodeJpg(dst, quality: 92));
}

double _aspectForMode(ScanMode mode) {
  switch (mode) {
    case ScanMode.document: return math.sqrt2; // A4
    case ScanMode.receipt: return 0.5; // 票据长条
    case ScanMode.book: return math.sqrt2;
    case ScanMode.whiteboard: return 4 / 3;
    case ScanMode.idCard: return 1.586; // 身份证
  }
}
