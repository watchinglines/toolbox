// lib/features/scanner/presentation/widgets/mode_selector.dart
// 扫描模式选择器
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/scanned_document.dart';
import '../bloc/scanner_bloc.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerBloc, ScannerState>(
      buildWhen: (a, b) => a.mode != b.mode,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButton<ScanMode>(
            value: state.mode,
            dropdownColor: Colors.black87,
            icon: const Icon(Icons.expand_more, color: Colors.white, size: 18),
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: const [
              DropdownMenuItem(value: ScanMode.document, child: Text('文档')),
              DropdownMenuItem(value: ScanMode.receipt, child: Text('票据')),
              DropdownMenuItem(value: ScanMode.book, child: Text('书籍')),
              DropdownMenuItem(value: ScanMode.whiteboard, child: Text('白板')),
              DropdownMenuItem(value: ScanMode.idCard, child: Text('证件')),
            ],
            onChanged: (mode) {
              if (mode != null) {
                context.read<ScannerBloc>().add(ScannerModeChanged(mode));
              }
            },
          ),
        );
      },
    );
  }
}
