// lib/features/scanner/data/document_edge_detector.dart
// 集成 google_mlkit_document_scanner 实现自动边缘检测
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../domain/scanned_document.dart';
import 'image_processor.dart';

class DocumentScannerResult {
  final List<ScannedPage> pages;
  final List<String> imagePaths;
  const DocumentScannerResult({required this.pages, required this.imagePaths});
}

class DocumentEdgeDetector {
  final _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.full,        // 完整模式:可拍多页+导入
      isGalleryImport: false,        // 扫描时禁止从相册导入
      pageLimit: 50,                 // 单次最多 50 页
      documentFormat: DocumentFormat.jpeg,
    ),
  );

  /// 启动 ML Kit 内置文档扫描器(全屏体验)
  /// 自动边缘检测 + 透视矫正 + 多页 + 闪光灯
  Future<DocumentScannerResult?> launch() async {
    try {
      final result = await _scanner.getScannedDocument();
      if (result == null || result.images.isEmpty) return null;

      final pages = <ScannedPage>[];
      for (var i = 0; i < result.images.length; i++) {
        final path = result.images[i];
        final bytes = await File(path).readAsBytes();
        pages.add(
          ScannedPage(
            id: DateTime.now().microsecondsSinceEpoch.toString() + '_$i',
            imageBytes: bytes,
            scannedAt: DateTime.now(),
            mode: ScanMode.document,
            dpi: 300,
          ),
        );
      }
      return DocumentScannerResult(pages: pages, imagePaths: result.images);
    } catch (e) {
      debugPrint('ML Kit Document Scanner error: $e');
      return null;
    }
  }

  /// 从单张图片中检测文档四边形(轻量,用于自定义 UI)
  /// 底层调用 google_mlkit_document_scanner 的边缘检测能力
  Future<DocumentCorners?> detectCorners(Uint8List imageBytes) async {
    // ML Kit Document Scanner 本身是封装好的全屏 UI,无独立 API
    // 此处使用 ML Kit 文本识别 + 启发式推断文档边界
    // 或后续切换到 OpenCV Canny + Hough 实现
    // 当前实现:返回全画面角点(作为占位)
    return DocumentCorners.empty;
  }

  void dispose() {
    _scanner.close();
  }
}
