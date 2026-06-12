// lib/app/di.dart - 依赖注入(get_it)
import 'package:get_it/get_it.dart';

import '../features/scanner/data/scanner_repository.dart';
import '../features/scanner/data/image_processor.dart';
import '../features/scanner/data/ocr_engine.dart';
import '../features/scanner/data/pdf_exporter.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 扫描仓储
  getIt.registerLazySingleton<ScannerRepository>(
    () => ScannerRepositoryImpl(
      imageProcessor: getIt<ImageProcessor>(),
      ocrEngine: getIt<OcrEngine>(),
      pdfExporter: getIt<PdfExporter>(),
    ),
  );

  // 图像处理(透视矫正 + 增强)
  getIt.registerLazySingleton<ImageProcessor>(
    () => const ImageProcessor(),
  );

  // OCR 引擎(本地优先)
  getIt.registerLazySingleton<OcrEngine>(
    () => const OcrEngine(),
  );

  // PDF 导出
  getIt.registerLazySingleton<PdfExporter>(
    () => const PdfExporter(),
  );
}
