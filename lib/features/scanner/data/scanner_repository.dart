// lib/features/scanner/data/scanner_repository.dart
// 扫描仓储:整合相机/图像处理/OCR/PDF
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../domain/scanned_document.dart';
import 'image_processor.dart';
import 'ocr_engine.dart';
import 'pdf_exporter.dart';

abstract class ScannerRepository {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initCamera({CameraLensDirection direction = CameraLensDirection.back});

  /// 完整流程:拍照 → 矫正 → 增强 → OCR
  Future<ScannedPage> captureAndProcess({
    required CameraController controller,
    required ScanMode mode,
    DocumentCorners? manualCorners,
  });

  /// 从图片库导入
  Future<ScannedPage> importFromGallery({
    required String imagePath,
    required ScanMode mode,
  });

  Future<PdfExportResult> exportToPdf(ScannedDocument doc);
  Future<OcrResult> runOcr(Uint8List imageBytes);
}

class ScannerRepositoryImpl implements ScannerRepository {
  final ImageProcessor imageProcessor;
  final OcrEngine ocrEngine;
  final PdfExporter pdfExporter;

  ScannerRepositoryImpl({
    required this.imageProcessor,
    required this.ocrEngine,
    required this.pdfExporter,
  });

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  @override
  Future<CameraController> initCamera({
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    final cameras = await getAvailableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', '未找到可用相机');
    }
    final target = cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      target,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    return controller;
  }

  @override
  Future<ScannedPage> captureAndProcess({
    required CameraController controller,
    required ScanMode mode,
    DocumentCorners? manualCorners,
  }) async {
    // 1. 拍摄高分辨率原图
    final xfile = await controller.takePicture();
    final rawBytes = await xfile.readAsBytes();

    // 2. 透视矫正(默认全画面,后续可接入 ML Kit DocumentScanner 自动检测角点)
    final corners = manualCorners ?? DocumentCorners.empty;
    final corrected = await imageProcessor.perspectiveCorrect(
      rawBytes: rawBytes,
      corners: corners,
      targetDpi: 300,
      mode: mode,
    );

    // 3. 增强
    final enhanced = await imageProcessor.enhance(
      bytes: corrected,
      mode: mode,
    );

    // 4. OCR(异步,不阻塞返回)
    final ocrResult = await ocrEngine.recognize(enhanced);

    return ScannedPage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageBytes: enhanced,
      originalBytes: rawBytes,
      ocrText: ocrResult.fullText,
      scannedAt: DateTime.now(),
      mode: mode,
      dpi: 300,
    );
  }

  @override
  Future<ScannedPage> importFromGallery({
    required String imagePath,
    required ScanMode mode,
  }) async {
    // 直接用 dart:io File 同步读取,避免 isolate 嵌套
    final rawBytes = await File(imagePath).readAsBytes();
    final corrected = await imageProcessor.perspectiveCorrect(
      rawBytes: rawBytes,
      corners: DocumentCorners.empty,
      targetDpi: 300,
      mode: mode,
    );
    final enhanced = await imageProcessor.enhance(bytes: corrected, mode: mode);
    final ocrResult = await ocrEngine.recognize(enhanced);

    return ScannedPage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageBytes: enhanced,
      originalBytes: rawBytes,
      ocrText: ocrResult.fullText,
      scannedAt: DateTime.now(),
      mode: mode,
    );
  }

  @override
  Future<PdfExportResult> exportToPdf(ScannedDocument doc) {
    return pdfExporter.export(doc);
  }

  @override
  Future<OcrResult> runOcr(Uint8List imageBytes) {
    return ocrEngine.recognize(imageBytes);
  }
}
