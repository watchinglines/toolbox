// lib/features/scanner/data/cv/perspective_warper.dart
// 基于单应矩阵的透视矫正器(替换原 _warpAffineApprox)
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'homography.dart';

class PerspectiveWarper {
  const PerspectiveWarper();

  /// 异步接口 - 内部走 isolate
  Future<Uint8List> warp({
    required Uint8List srcImage,
    required List<ui.Offset> srcCorners,
    required ui.Size outputSize,
    int jpegQuality = 92,
  }) async {
    return compute<_WarpTask, Uint8List>(
      _runWarp,
      _WarpTask(
        imageBytes: srcImage,
        srcCorners: srcCorners,
        outW: outputSize.width.round(),
        outH: outputSize.height.round(),
        quality: jpegQuality,
      ),
    );
  }

  /// 同步接口 - 接受已解码的 img.Image,避免在 isolate 中二次解码
  /// 由 image_processor.dart 在 isolate 中调用
  Uint8List warpSync({
    required img.Image srcImage,
    required List<ui.Offset> srcCorners,
    required List<ui.Offset> dstCorners,
    required int outW,
    required int outH,
    int jpegQuality = 92,
  }) {
    // 计算单应矩阵 H(将源点映射到目标点)
    final H = HomographyEstimator.estimate(srcCorners, dstCorners);
    final invH = _invertHomography(H);

    final dst = img.Image(width: outW, height: outH);
    for (int y = 0; y < outH; y++) {
      for (int x = 0; x < outW; x++) {
        final srcPt = invH.transform(x.toDouble(), y.toDouble());
        final sampled = _bilinearSample(srcImage, srcPt.dx, srcPt.dy);
        dst.setPixel(x, y, sampled);
      }
    }
    return Uint8List.fromList(img.encodeJpg(dst, quality: jpegQuality));
  }
}

class _WarpTask {
  final Uint8List imageBytes;
  final List<ui.Offset> srcCorners;
  final int outW, outH;
  final int quality;
  const _WarpTask({
    required this.imageBytes,
    required this.srcCorners,
    required this.outW,
    required this.outH,
    required this.quality,
  });
}

Uint8List _runWarp(_WarpTask task) {
  final src = img.decodeImage(task.imageBytes);
  if (src == null) throw const FormatException('无法解码图像');

  // 目标角点(输出图像的四个角)
  final dstCorners = <ui.Offset>[
    const ui.Offset(0, 0),
    ui.Offset(task.outW.toDouble(), 0),
    ui.Offset(task.outW.toDouble(), task.outH.toDouble()),
    ui.Offset(0, task.outH.toDouble()),
  ];

  // 计算单应矩阵 H(将源点映射到目标点)
  final H = HomographyEstimator.estimate(task.srcCorners, dstCorners);

  // 反向映射(避免空洞):对每个输出像素,求源像素位置
  final dst = img.Image(width: task.outW, height: task.outH);
  final invH = _invertHomography(H);

  for (int y = 0; y < task.outH; y++) {
    for (int x = 0; x < task.outW; x++) {
      final srcPt = invH.transform(x.toDouble(), y.toDouble());
      // 双线性插值
      final sampled = _bilinearSample(src, srcPt.dx, srcPt.dy);
      dst.setPixel(x, y, sampled);
    }
  }

  return Uint8List.fromList(img.encodeJpg(dst, quality: task.quality));
}

Homography _invertHomography(Homography H) {
  // 计算 3x3 矩阵的逆
  final a = H.h00, b = H.h01, c = H.h02;
  final d = H.h10, e = H.h11, f = H.h12;
  final g = H.h20, h = H.h21, i = 1.0;

  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  if (det.abs() < 1e-10) {
    throw StateError('单应矩阵不可逆');
  }
  final invDet = 1.0 / det;

  return Homography(
    h00: (e * i - f * h) * invDet,
    h01: (c * h - b * i) * invDet,
    h02: (b * f - c * e) * invDet,
    h10: (f * g - d * i) * invDet,
    h11: (a * i - c * g) * invDet,
    h12: (c * d - a * f) * invDet,
    h20: (d * h - e * g) * invDet,
    h21: (b * g - a * h) * invDet,
  );
}

img.Color _bilinearSample(img.Image src, double x, double y) {
  final w = src.width;
  final h = src.height;
  if (x < 0 || y < 0 || x >= w || y >= h) {
    return img.ColorRgb8(255, 255, 255);
  }

  final x0 = x.floor();
  final y0 = y.floor();
  final x1 = math.min(x0 + 1, w - 1);
  final y1 = math.min(y0 + 1, h - 1);
  final dx = x - x0;
  final dy = y - y0;

  final p00 = src.getPixel(x0, y0);
  final p10 = src.getPixel(x1, y0);
  final p01 = src.getPixel(x0, y1);
  final p11 = src.getPixel(x1, y1);

  final r = ((1 - dx) * (1 - dy) * p00.r +
            dx * (1 - dy) * p10.r +
            (1 - dx) * dy * p01.r +
            dx * dy * p11.r)
      .round();
  final g = ((1 - dx) * (1 - dy) * p00.g +
            dx * (1 - dy) * p10.g +
            (1 - dx) * dy * p01.g +
            dx * dy * p11.g)
      .round();
  final b = ((1 - dx) * (1 - dy) * p00.b +
            dx * (1 - dy) * p10.b +
            (1 - dx) * dy * p01.b +
            dx * dy * p11.b)
      .round();

  return img.ColorRgb8(r, g, b);
}

// 显式声明 utils 中间函数(供测试访问)
@visibleForTesting
Uint8List debugRunWarp(
  Uint8List imageBytes,
  List<ui.Offset> srcCorners,
  int outW,
  int outH,
) {
  return _runWarp(_WarpTask(
    imageBytes: imageBytes,
    srcCorners: srcCorners,
    outW: outW,
    outH: outH,
    quality: 92,
  ));
}
