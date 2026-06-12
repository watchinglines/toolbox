// lib/features/scanner/presentation/widgets/scan_frame_overlay.dart
// 扫描框遮罩(带四角动画)
import 'package:flutter/material.dart';

class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({super.key});

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final frameW = c.maxWidth - 48;
        final frameH = frameW * 1.414; // A4 比例
        return Stack(
          children: [
            // 暗色遮罩
            CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _DimMaskPainter(
                frame: Rect.fromLTWH(24, (c.maxHeight - frameH) / 2, frameW, frameH),
              ),
            ),
            // 扫描线
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _ScanLinePainter(
                    progress: _ctrl.value,
                    frame: Rect.fromLTWH(24, (c.maxHeight - frameH) / 2, frameW, frameH),
                  ),
                );
              },
            ),
            // 四角
            Positioned(
              left: 24, top: (c.maxHeight - frameH) / 2,
              child: _Corner(rotation: 0),
            ),
            Positioned(
              right: 24, top: (c.maxHeight - frameH) / 2,
              child: _Corner(rotation: 1),
            ),
            Positioned(
              left: 24, bottom: (c.maxHeight - frameH) / 2,
              child: _Corner(rotation: 3),
            ),
            Positioned(
              right: 24, bottom: (c.maxHeight - frameH) / 2,
              child: _Corner(rotation: 2),
            ),
            // 提示文字
            Positioned(
              left: 0, right: 0,
              top: (c.maxHeight - frameH) / 2 - 36,
              child: const Center(
                child: Text(
                  '将文档对准取景框',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {
  final int rotation; // 0=TL, 1=TR, 2=BR, 3=BL
  const _Corner({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 1.5708, // 90°
      child: SizedBox(
        width: 28, height: 28,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DimMaskPainter extends CustomPainter {
  final Rect frame;
  _DimMaskPainter({required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
    final border = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)), border);
  }

  @override
  bool shouldRepaint(covariant _DimMaskPainter old) => old.frame != frame;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Rect frame;
  _ScanLinePainter({required this.progress, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final y = frame.top + frame.height * progress;
    final gradient = LinearGradient(
      colors: [Colors.transparent, Colors.greenAccent.withOpacity(0.9), Colors.transparent],
    );
    final rect = Rect.fromLTWH(frame.left, y - 1, frame.width, 2);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.progress != progress || old.frame != frame;
}
