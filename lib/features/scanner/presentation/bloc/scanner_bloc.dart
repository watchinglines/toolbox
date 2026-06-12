// lib/features/scanner/presentation/bloc/scanner_bloc.dart
// 扫描状态管理(BLoC)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../data/scanner_repository.dart';
import '../../data/pdf_exporter.dart';
import '../../domain/scanned_document.dart';

/// ---------------- Events ----------------
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();
  @override
  List<Object?> get props => const [];
}

class ScannerInitialized extends ScannerEvent {
  const ScannerInitialized();
}

class ScannerModeChanged extends ScannerEvent {
  final ScanMode mode;
  const ScannerModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class ScannerCaptureRequested extends ScannerEvent {
  const ScannerCaptureRequested();
}

class ScannerImportFromGallery extends ScannerEvent {
  const ScannerImportFromGallery();
}

class ScannerExportRequested extends ScannerEvent {
  const ScannerExportRequested();
}

class ScannerDocumentCleared extends ScannerEvent {
  const ScannerDocumentCleared();
}

/// ---------------- State ----------------
enum ScannerStatus {
  initial,
  initializing,
  ready,
  capturing,
  processing,
  ocrRunning,
  exporting,
  success,
  error,
}

class ScannerState extends Equatable {
  final ScannerStatus status;
  final ScanMode mode;
  final String? errorMessage;
  final ScannedDocument? document;
  final PdfExportResult? lastExport;
  final String? progressMessage;

  const ScannerState({
    this.status = ScannerStatus.initial,
    this.mode = ScanMode.document,
    this.errorMessage,
    this.document,
    this.lastExport,
    this.progressMessage,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    ScanMode? mode,
    String? errorMessage,
    ScannedDocument? document,
    PdfExportResult? lastExport,
    String? progressMessage,
    bool clearError = false,
    bool clearExport = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      document: document ?? this.document,
      lastExport: clearExport ? null : (lastExport ?? this.lastExport),
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, mode, errorMessage, document, lastExport, progressMessage];
}

/// ---------------- Bloc ----------------
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerRepository _repo;

  ScannerBloc({ScannerRepository? repo})
      : _repo = repo ?? getIt<ScannerRepository>(),
        super(const ScannerState()) {
    on<ScannerInitialized>(_onInitialized);
    on<ScannerModeChanged>(_onModeChanged);
    on<ScannerCaptureRequested>(_onCaptureRequested);
    on<ScannerImportFromGallery>(_onImportFromGallery);
    on<ScannerExportRequested>(_onExportRequested);
    on<ScannerDocumentCleared>(_onDocumentCleared);
  }

  Future<void> _onInitialized(
    ScannerInitialized event,
    Emitter<ScannerState> emit,
  ) async {
    emit(state.copyWith(status: ScannerStatus.initializing));
    try {
      await _repo.getAvailableCameras();
      emit(state.copyWith(status: ScannerStatus.ready, clearError: true));
    } catch (e) {
      emit(state.copyWith(
        status: ScannerStatus.error,
        errorMessage: '相机初始化失败: $e',
      ));
    }
  }

  void _onModeChanged(ScannerModeChanged event, Emitter<ScannerState> emit) {
    emit(state.copyWith(mode: event.mode));
  }

  Future<void> _onCaptureRequested(
    ScannerCaptureRequested event,
    Emitter<ScannerState> emit,
  ) async {
    // 真实实现需要从 UI 传入 CameraController
    // 此处仅演示 Bloc 状态流转
    emit(state.copyWith(
      status: ScannerStatus.capturing,
      progressMessage: '正在拍摄...',
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    emit(state.copyWith(
      status: ScannerStatus.processing,
      progressMessage: '正在矫正与增强...',
    ));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(
      status: ScannerStatus.ocrRunning,
      progressMessage: '正在识别文字...',
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    emit(state.copyWith(status: ScannerStatus.ready, clearError: true));
  }

  Future<void> _onImportFromGallery(
    ScannerImportFromGallery event,
    Emitter<ScannerState> emit,
  ) async {
    emit(state.copyWith(status: ScannerStatus.processing, progressMessage: '导入图片中...'));
    // 实际由 UI 层调用 image_picker 选图后,通过事件传入路径
    await Future.delayed(const Duration(milliseconds: 400));
    emit(state.copyWith(status: ScannerStatus.ready, progressMessage: null));
  }

  Future<void> _onExportRequested(
    ScannerExportRequested event,
    Emitter<ScannerState> emit,
  ) async {
    final doc = state.document;
    if (doc == null) {
      emit(state.copyWith(
        status: ScannerStatus.error,
        errorMessage: '没有可导出的文档',
      ));
      return;
    }
    emit(state.copyWith(status: ScannerStatus.exporting, progressMessage: '正在生成 PDF...'));
    try {
      final result = await _repo.exportToPdf(doc);
      emit(state.copyWith(
        status: ScannerStatus.success,
        lastExport: result,
        progressMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScannerStatus.error,
        errorMessage: '导出失败: $e',
      ));
    }
  }

  void _onDocumentCleared(ScannerDocumentCleared event, Emitter<ScannerState> emit) {
    emit(state.copyWith(
      status: ScannerStatus.ready,
      document: null,
      lastExport: null,
      clearError: true,
    ));
  }
}
