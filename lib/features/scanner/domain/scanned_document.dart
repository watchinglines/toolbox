// lib/features/scanner/domain/scanned_document.dart
// 领域模型:已扫描的文档
import 'dart:typed_data';

enum ScanMode { document, receipt, book, whiteboard, idCard }

enum DocumentStage { captured, perspectiveCorrected, enhanced, ocrCompleted, exported }

class ScannedPage {
  final String id;
  final Uint8List imageBytes;          // 原始/矫正后图像
  final Uint8List? originalBytes;      // 拍照原图(用于回退)
  final String ocrText;
  final DateTime scannedAt;
  final ScanMode mode;
  final int dpi;

  const ScannedPage({
    required this.id,
    required this.imageBytes,
    this.originalBytes,
    this.ocrText = '',
    required this.scannedAt,
    this.mode = ScanMode.document,
    this.dpi = 300,
  });

  ScannedPage copyWith({
    String? id,
    Uint8List? imageBytes,
    Uint8List? originalBytes,
    String? ocrText,
    DateTime? scannedAt,
    ScanMode? mode,
    int? dpi,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      originalBytes: originalBytes ?? this.originalBytes,
      ocrText: ocrText ?? this.ocrText,
      scannedAt: scannedAt ?? this.scannedAt,
      mode: mode ?? this.mode,
      dpi: dpi ?? this.dpi,
    );
  }
}

class ScannedDocument {
  final String id;
  final String title;
  final List<ScannedPage> pages;
  final DateTime createdAt;

  const ScannedDocument({
    required this.id,
    required this.title,
    required this.pages,
    required this.createdAt,
  });

  String get fullText => pages.map((p) => p.ocrText).join('\n\n--- Page ---\n\n');
  int get pageCount => pages.length;
}
