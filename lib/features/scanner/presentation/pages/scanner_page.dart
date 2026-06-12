// lib/features/scanner/presentation/pages/scanner_page.dart
// 扫描页:相机预览 + 拍照 + 模式切换
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/di.dart';
import '../../../../design_system/tokens.dart';
import '../../data/scanner_repository.dart';
import '../../domain/scanned_document.dart';
import '../bloc/scanner_bloc.dart';
import '../widgets/mode_selector.dart';
import '../widgets/scan_frame_overlay.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能扫描')),
        );
      }
      return;
    }
    setState(() {
      _initFuture = _initController();
    });
  }

  Future<void> _initController() async {
    final repo = getIt<ScannerRepository>();
    _controller = await repo.initCamera();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    final mode = context.read<ScannerBloc>().state.mode;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = getIt<ScannerRepository>();
      final page = await repo.captureAndProcess(
        controller: _controller!,
        mode: mode,
      );

      if (!mounted) return;
      // 跳转到结果页(简化:用 SnackBar + Navigator)
      messenger.showSnackBar(
        SnackBar(
          content: Text('扫描完成!识别到 ${page.ocrText.length} 个字符'),
          backgroundColor: TBColors.secondary,
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/result');
            },
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('扫描失败: $e'), backgroundColor: TBColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null) return;

    setState(() => _isProcessing = true);
    try {
      final mode = context.read<ScannerBloc>().state.mode;
      final repo = getIt<ScannerRepository>();
      final page = await repo.importFromGallery(
        imagePath: file.path,
        mode: mode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入完成!识别到 ${page.ocrText.length} 个字符'),
          backgroundColor: TBColors.secondary,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: TBColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 相机预览
            Positioned.fill(
              child: FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError || _controller == null) {
                    return _ErrorView(
                      message: snapshot.error?.toString() ?? '相机初始化失败',
                      onRetry: _initCamera,
                    );
                  }
                  return _CameraPreview(controller: _controller!);
                },
              ),
            ),

            // 扫描框遮罩
            if (_controller != null && _controller!.value.isInitialized)
              const Positioned.fill(child: ScanFrameOverlay()),

            // 顶部:模式选择 + 关闭
            Positioned(
              top: TBSpacing.md,
              left: TBSpacing.md,
              right: TBSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const ModeSelector(),
                  _CircleButton(
                    icon: Icons.flash_on,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('闪光灯功能开发中'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 底部:导入 + 拍照 + 历史
            Positioned(
              bottom: TBSpacing.xl,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CircleButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _isProcessing ? null : _importFromGallery,
                  ),
                  _ShutterButton(
                    isProcessing: _isProcessing,
                    onTap: _isProcessing ? null : _capture,
                  ),
                  _CircleButton(
                    icon: Icons.history,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/result');
                    },
                  ),
                ],
              ),
            ),

            // 加载指示
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: TBSpacing.md),
                        Text('处理中...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- 内部组件 ----------------
class _CameraPreview extends StatelessWidget {
  final CameraController controller;
  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 0,
            height: controller.value.previewSize?.width ?? 0,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback? onTap;
  const _ShutterButton({required this.isProcessing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isProcessing ? Colors.grey : Colors.white,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 4),
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Container(
                margin: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: TBSpacing.md),
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: TBSpacing.md),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
