// test/perspective_warper_test.dart - 单应矩阵 + 透视矫正单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:toolbox_scanner/features/scanner/data/cv/homography.dart';
import 'package:toolbox_scanner/features/scanner/data/cv/perspective_warper.dart';

void main() {
  group('HomographyEstimator', () {
    test('identity mapping', () {
      final src = [
        const ui.Offset(0, 0),
        const ui.Offset(100, 0),
        const ui.Offset(100, 100),
        const ui.Offset(0, 100),
      ];
      final H = HomographyEstimator.estimate(src, src);
      final result = H.transform(50.0, 50.0);
      expect(result.dx, closeTo(50.0, 0.5));
      expect(result.dy, closeTo(50.0, 0.5));
    });

    test('translation', () {
      final src = [
        const ui.Offset(0, 0),
        const ui.Offset(100, 0),
        const ui.Offset(100, 100),
        const ui.Offset(0, 100),
      ];
      final dst = [
        const ui.Offset(50, 50),
        const ui.Offset(150, 50),
        const ui.Offset(150, 150),
        const ui.Offset(50, 150),
      ];
      final H = HomographyEstimator.estimate(src, dst);
      final result = H.transform(0.0, 0.0);
      expect(result.dx, closeTo(50.0, 1.0));
      expect(result.dy, closeTo(50.0, 1.0));
    });

    test('perspective skew', () {
      // 模拟拍摄倾斜文档:原图是正方形,目标也是正方形,但源点稍微歪斜
      final src = [
        const ui.Offset(0, 5),
        const ui.Offset(100, 0),
        const ui.Offset(95, 100),
        const ui.Offset(5, 95),
      ];
      final dst = [
        const ui.Offset(0, 0),
        const ui.Offset(100, 0),
        const ui.Offset(100, 100),
        const ui.Offset(0, 100),
      ];
      final H = HomographyEstimator.estimate(src, dst);
      // 中心点应映射到中心
      final center = H.transform(50.0, 50.0);
      expect(center.dx, closeTo(50.0, 2.0));
      expect(center.dy, closeTo(50.0, 2.0));
    });
  });

  group('PerspectiveWarper', () {
    test('warps a simple 4x4 test image', () async {
      // 创建 100x100 纯白测试图
      final src = img.Image(width: 100, height: 100);
      img.fill(src, img.ColorRgb8(255, 255, 255));
      final bytes = Uint8List.fromList(img.encodeJpg(src));

      const warper = PerspectiveWarper();
      final srcCorners = [
        const ui.Offset(10, 10),
        const ui.Offset(90, 10),
        const ui.Offset(90, 90),
        const ui.Offset(10, 90),
      ];

      final result = await warper.warp(
        srcImage: bytes,
        srcCorners: srcCorners,
        outputSize: const ui.Size(200, 200),
      );

      expect(result.length, greaterThan(0));
      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 200);
      expect(decoded.height, 200);
    });

    test('handles out-of-bounds source points gracefully', () async {
      final src = img.Image(width: 100, height: 100);
      img.fill(src, img.ColorRgb8(128, 128, 128));
      final bytes = Uint8List.fromList(img.encodeJpg(src));

      const warper = PerspectiveWarper();
      // 故意将角点设置在边界外
      final srcCorners = [
        const ui.Offset(-10, -10),
        const ui.Offset(110, -10),
        const ui.Offset(110, 110),
        const ui.Offset(-10, 110),
      ];

      final result = await warper.warp(
        srcImage: bytes,
        srcCorners: srcCorners,
        outputSize: const ui.Size(50, 50),
      );

      expect(result.length, greaterThan(0));
    });
  });
}
