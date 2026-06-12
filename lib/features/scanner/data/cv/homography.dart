// lib/features/scanner/data/cv/homography.dart
// 单应矩阵 (Homography) 数学库 - 纯 Dart 实现,4 点对计算 3x3 变换矩阵
// 用于替换简化仿射变换,实现真正的透视矫正
import 'dart:math' as math;
import 'dart:ui' as ui;

/// 3x3 单应矩阵(齐次坐标)
class Homography {
  final double h00, h01, h02;
  final double h10, h11, h12;
  final double h20, h21;

  const Homography({
    required this.h00, required this.h01, required this.h02,
    required this.h10, required this.h11, required this.h12,
    required this.h20, required this.h21,
  });

  static const identity = Homography(
    h00: 1, h01: 0, h02: 0,
    h10: 0, h11: 1, h12: 0,
    h20: 0, h21: 0,
  );

  /// 应用单应变换:将 (x, y) 映射到新坐标
  ui.Offset transform(double x, double y) {
    final w = h20 * x + h21 * y + 1;
    return ui.Offset(
      (h00 * x + h01 * y + h02) / w,
      (h10 * x + h11 * y + h12) / w,
    );
  }

  /// 计算 4 个角点变换后的目标坐标
  List<ui.Offset> transformCorners(List<ui.Offset> corners) {
    return corners.map((p) => transform(p.dx, p.dy)).toList();
  }
}

/// 单应矩阵求解器(Direct Linear Transform + 归一化 DLT)
/// 输入 4 组源点→目标点,输出 3x3 单应矩阵 H
class HomographyEstimator {
  /// 从 4 对点估算单应矩阵(使用归一化 DLT 算法)
  /// 精度远高于简化仿射
  static Homography estimate(List<ui.Offset> src, List<ui.Offset> dst) {
    assert(src.length == 4 && dst.length == 4, '需要 4 对点');

    // 1. 数据归一化(提升数值稳定性)
    final _NormData normSrcData = _normalize(src);
    final _NormData normDstData = _normalize(dst);
    final normSrc = normSrcData.normalized;
    final normDst = normDstData.normalized;

    // 2. 构建 8x8 线性方程组 Ax = 0
    // 每对点贡献 2 行:[-X,-Y,-1,0,0,0,xX,xY,x] 和 [0,0,0,-X,-Y,-1,yX,yY,y]
    final A = List.generate(8, (_) => List<double>.filled(9, 0));
    for (int i = 0; i < 4; i++) {
      final X = normSrc[i].dx;
      final Y = normSrc[i].dy;
      final x = normDst[i].dx;
      final y = normDst[i].dy;

      A[i * 2][0] = -X;
      A[i * 2][1] = -Y;
      A[i * 2][2] = -1;
      A[i * 2][6] = x * X;
      A[i * 2][7] = x * Y;
      A[i * 2][8] = x;

      A[i * 2 + 1][3] = -X;
      A[i * 2 + 1][4] = -Y;
      A[i * 2 + 1][5] = -1;
      A[i * 2 + 1][6] = y * X;
      A[i * 2 + 1][7] = y * Y;
      A[i * 2 + 1][8] = y;
    }

    // 3. SVD / 最小二乘求解(简化为高斯消元)
    final h = _solveLinearSystem(A);

    // 4. 反归一化
    final H = Homography(
      h00: h[0], h01: h[1], h02: h[2],
      h10: h[3], h11: h[4], h12: h[5],
      h20: h[6], h21: h[7],
    );

    return _denormalize(H, normSrcData.norm, normDstData.norm);
  }

  static _NormData _normalize(List<ui.Offset> pts) {
    final cx = pts.map((p) => p.dx).reduce((a, b) => a + b) / pts.length;
    final cy = pts.map((p) => p.dy).reduce((a, b) => a + b) / pts.length;

    double sumDist = 0;
    for (final p in pts) {
      sumDist += math.sqrt(math.pow(p.dx - cx, 2) + math.pow(p.dy - cy, 2));
    }
    final meanDist = sumDist / pts.length;
    final scale = math.sqrt(2) / (meanDist == 0 ? 1 : meanDist);

    final normalized = pts
        .map((p) => ui.Offset((p.dx - cx) * scale, (p.dy - cy) * scale))
        .toList();

    return _NormData(
      normalized: normalized,
      norm: _Matrix3(
        m00: scale, m01: 0, m02: -cx * scale,
        m10: 0, m11: scale, m12: -cy * scale,
        m20: 0, m21: 0, m22: 1,
      ),
      cx: cx, cy: cy, scale: scale,
    );
  }

  static Homography _denormalize(
    Homography Hn,
    _Matrix3 Tsrc,
    _Matrix3 Tdst,
  ) {
    // H = inv(Tdst) * Hn * Tsrc
    final HnMat = _Matrix3(
      m00: Hn.h00, m01: Hn.h01, m02: Hn.h02,
      m10: Hn.h10, m11: Hn.h11, m12: Hn.h12,
      m20: Hn.h20, m21: Hn.h21, m22: 1,
    );
    final invTdst = Tdst.inverse();
    final result = invTdst.multiply(HnMat).multiply(Tsrc);

    return Homography(
      h00: result.m00, h01: result.m01, h02: result.m02,
      h10: result.m10, h11: result.m11, h12: result.m12,
      h20: result.m20, h21: result.m21,
    );
  }

  /// 高斯消元求解 9 变量齐次方程(取最小特征向量,简化为求解 b=0 的最小二乘)
  static List<double> _solveLinearSystem(List<List<double>> A) {
    // 简化:对 A^T * A 求最小特征向量
    // 生产建议改用 SVD (e.g. ml_linalg 或 C++ Eigen via FFI)
    final n = A.length;
    final m = A[0].length;

    // 计算 A^T * A
    final AtA = List.generate(m, (_) => List<double>.filled(m, 0));
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < m; j++) {
        double sum = 0;
        for (int k = 0; k < n; k++) {
          sum += A[k][i] * A[k][j];
        }
        AtA[i][j] = sum;
      }
    }

    // 幂迭代求最小特征向量(替代 SVD,O(n^3) 一次,9x9 矩阵很快)
    var v = List<double>.generate(m, (i) => i == m - 1 ? 1.0 : 0.0);
    for (int iter = 0; iter < 50; iter++) {
      // v = AtA * v
      final newV = List<double>.filled(m, 0);
      for (int i = 0; i < m; i++) {
        for (int j = 0; j < m; j++) {
          newV[i] += AtA[i][j] * v[j];
        }
      }
      // 归一化
      var norm = 0.0;
      for (final x in newV) norm += x * x;
      norm = math.sqrt(norm);
      if (norm < 1e-12) break;
      for (int i = 0; i < m; i++) {
        v[i] = newV[i] / norm;
      }
    }
    return v;
  }
}

class _NormData {
  final List<ui.Offset> normalized;
  final _Matrix3 norm;
  final double cx, cy, scale;
  _NormData({required this.normalized, required this.norm, required this.cx, required this.cy, required this.scale});
}

class _Matrix3 {
  final double m00, m01, m02;
  final double m10, m11, m12;
  final double m20, m21, m22;
  const _Matrix3({
    required this.m00, required this.m01, required this.m02,
    required this.m10, required this.m11, required this.m12,
    required this.m20, required this.m21, required this.m22,
  });

  _Matrix3 multiply(_Matrix3 other) {
    return _Matrix3(
      m00: m00 * other.m00 + m01 * other.m10 + m02 * other.m20,
      m01: m00 * other.m01 + m01 * other.m11 + m02 * other.m21,
      m02: m00 * other.m02 + m01 * other.m12 + m02 * other.m22,
      m10: m10 * other.m00 + m11 * other.m10 + m12 * other.m20,
      m11: m10 * other.m01 + m11 * other.m11 + m12 * other.m21,
      m12: m10 * other.m02 + m11 * other.m12 + m12 * other.m22,
      m20: m20 * other.m00 + m21 * other.m10 + m22 * other.m20,
      m21: m20 * other.m01 + m21 * other.m11 + m22 * other.m21,
      m22: m20 * other.m02 + m21 * other.m12 + m22 * other.m22,
    );
  }

  _Matrix3 inverse() {
    final det = m00 * (m11 * m22 - m12 * m21) -
        m01 * (m10 * m22 - m12 * m20) +
        m02 * (m10 * m21 - m11 * m20);
    if (det.abs() < 1e-10) {
      throw StateError('矩阵不可逆');
    }
    final invDet = 1.0 / det;
    return _Matrix3(
      m00: (m11 * m22 - m12 * m21) * invDet,
      m01: (m02 * m21 - m01 * m22) * invDet,
      m02: (m01 * m12 - m02 * m11) * invDet,
      m10: (m12 * m20 - m10 * m22) * invDet,
      m11: (m00 * m22 - m02 * m20) * invDet,
      m12: (m02 * m10 - m00 * m12) * invDet,
      m20: (m10 * m21 - m11 * m20) * invDet,
      m21: (m01 * m20 - m00 * m21) * invDet,
      m22: (m00 * m11 - m01 * m10) * invDet,
    );
  }
}
