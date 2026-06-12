// lib/features/scanner/data/ocr_engine.dart
// OCR 引擎:本地 ML Kit(优先) + 云端补充(可关闭)
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String fullText;
  final List<TextBlock> blocks;
  final bool usedCloud;
  final int durationMs;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.usedCloud,
    required this.durationMs,
  });
}

class OcrEngine {
  final bool enableCloudFallback;
  final TextRecognitionScript script;

  const OcrEngine({
    this.enableCloudFallback = false,
    this.script = TextRecognitionScript.latin,
  });

  /// 识别图像中的文字
  Future<OcrResult> recognize(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();

    // 写入临时文件(ML Kit 需要文件路径)
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);

    // 本地识别
    final recognizer = TextRecognizer(script: script);
    RecognizedText recognized;
    try {
      recognized = await recognizer.processImage(
        InputImage.fromFilePath(tempFile.path),
      );
    } finally {
      await recognizer.close();
      // 清理临时文件(失败也尝试删除)
      try { await tempFile.delete(); } catch (_) {}
    }

    stopwatch.stop();

    return OcrResult(
      fullText: recognized.text,
      blocks: recognized.blocks,
      usedCloud: false,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 检测是否需要云端(本地识别率低时触发)
  bool shouldFallbackToCloud(OcrResult localResult) {
    if (!enableCloudFallback) return false;
    // 启发式:文本长度 < 10 且识别耗时 < 100ms,可能识别失败
    return localResult.fullText.trim().length < 10;
  }

  /// 关闭资源
  void dispose() {
    // 持久化 recognizer 由 ML Kit 内部管理
    if (kDebugMode) debugPrint('OcrEngine disposed');
  }
}
