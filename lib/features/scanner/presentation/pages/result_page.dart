// lib/features/scanner/presentation/pages/result_page.dart
// 结果页:展示扫描图像 + OCR 文本 + 导出
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/tokens.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描结果'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: const _ResultBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF 导出功能演示')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('导出 PDF'),
                ),
              ),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('文本已复制到剪贴板')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制文本'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: '图像'), Tab(text: '文本')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 图像预览(占位 - 实际应展示 ScannedPage.imageBytes)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(TBSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(TBRadius.md),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: TBSpacing.sm),
                          Text('扫描图像预览', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                // OCR 文本
                Padding(
                  padding: const EdgeInsets.all(TBSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TBSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(TBRadius.md),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const SingleChildScrollView(
                      child: Text(
                        '这是 OCR 识别的文本占位内容。\n\n实际使用中,这里会展示从扫描图像中提取的所有文字,支持选中复制、编辑、翻译等操作。',
                        style: TextStyle(height: 1.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
