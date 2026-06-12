// test/scanner_bloc_test.dart - BLoC 单元测试示例
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:toolbox_scanner/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:toolbox_scanner/features/scanner/data/scanner_repository.dart';
import 'package:toolbox_scanner/features/scanner/domain/scanned_document.dart';

class _MockRepo extends Mock implements ScannerRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getAvailableCameras()).thenAnswer((_) async => []);
  });

  group('ScannerBloc', () {
    blocTest<ScannerBloc, ScannerState>(
      'emits [initializing, ready] when ScannerInitialized succeeds',
      build: () => ScannerBloc(repo: repo),
      act: (bloc) => bloc.add(const ScannerInitialized()),
      expect: () => [
        const ScannerState(status: ScannerStatus.initializing),
        const ScannerState(status: ScannerStatus.ready),
      ],
    );

    blocTest<ScannerBloc, ScannerState>(
      'emits mode change on ScannerModeChanged',
      build: () => ScannerBloc(repo: repo),
      seed: () => const ScannerState(status: ScannerStatus.ready),
      act: (bloc) => bloc.add(const ScannerModeChanged(ScanMode.receipt)),
      expect: () => [
        const ScannerState(status: ScannerStatus.ready, mode: ScanMode.receipt),
      ],
    );

    blocTest<ScannerBloc, ScannerState>(
      'emits error when no cameras available',
      build: () {
        when(() => repo.getAvailableCameras())
            .thenThrow(const CameraException('NoCamera', '未找到相机'));
        return ScannerBloc(repo: repo);
      },
      act: (bloc) => bloc.add(const ScannerInitialized()),
      expect: () => [
        const ScannerState(status: ScannerStatus.initializing),
        const ScannerState(
          status: ScannerStatus.error,
          errorMessage: '相机初始化失败: CameraException(NoCamera, 未找到相机)',
        ),
      ],
    );
  });
}
