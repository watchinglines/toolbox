// lib/features/scanner/data/pdf_exporter.dart
// PDF 导出
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/scanned_document.dart';

class PdfExportResult {
  final File file;
  final int sizeBytes;
  final int pageCount;

  const PdfExportResult({
    required this.file,
    required this.sizeBytes,
    required this.pageCount,
  });
}

class PdfExporter {
  const PdfExporter();

  /// 导出扫描文档为 PDF
  Future<PdfExportResult> export(
    ScannedDocument doc, {
    bool includeOcrTextLayer = true,
  }) async {
    final pdf = pw.Document(
      title: doc.title,
      author: 'ToolBox',
      creator: 'ToolBox Scanner',
    );

    for (final page in doc.pages) {
      final image = pw.MemoryImage(page.imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Stack(
              children: [
                // 背景:扫描图像
                pw.Positioned.fill(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                // 可选:OCR 文本层(隐藏,用于搜索/复制)
                if (includeOcrTextLayer && page.ocrText.isNotEmpty)
                  pw.Positioned(
                    left: 0, top: 0, right: 0, bottom: 0,
                    child: pw.Opacity(
                      opacity: 0,
                      child: pw.Text(page.ocrText),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!exportsDir.existsSync()) {
      exportsDir.createSync(recursive: true);
    }
    final safeTitle = doc.title.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final file = File('${exportsDir.path}/${safeTitle}_${doc.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(bytes);

    return PdfExportResult(
      file: file,
      sizeBytes: bytes.length,
      pageCount: doc.pageCount,
    );
  }

  /// 导出 OCR 文本为 txt
  Future<File> exportText(ScannedDocument doc) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!exportsDir.existsSync()) {
      exportsDir.createSync(recursive: true);
    }
    final file = File('${exportsDir.path}/${doc.title}.txt');
    await file.writeAsString(doc.fullText);
    return file;
  }

  /// 内存中生成 PDF bytes(用于分享/预览)
  Future<Uint8List> exportBytes(ScannedDocument doc) async {
    final pdf = pw.Document(title: doc.title);
    for (final page in doc.pages) {
      final image = pw.MemoryImage(page.imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Image(image, fit: pw.BoxFit.contain),
        ),
      );
    }
    return pdf.save();
  }
}
