// lib/features/scanner/presentation/pages/home_page.dart
// 首页:工具九宫格入口
import 'package:flutter/material.dart';

import '../../../../design_system/tokens.dart';
import '../widgets/tool_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToolBox'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '工具集',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: TBSpacing.xs),
              Text(
                '选择工具,开始处理',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: TBSpacing.md,
                  crossAxisSpacing: TBSpacing.md,
                  childAspectRatio: 1.1,
                  children: const [
                    ToolTile(
                      icon: Icons.document_scanner_outlined,
                      label: '扫描',
                      subtitle: 'OCR + 高清',
                      color: TBColors.primary,
                      route: '/scanner',
                    ),
                    ToolTile(
                      icon: Icons.straighten,
                      label: 'AR 测量',
                      subtitle: '距离/面积',
                      color: Color(0xFF8B5CF6),
                      route: null, // 暂未实现
                    ),
                    ToolTile(
                      icon: Icons.edit_outlined,
                      label: '图片编辑',
                      subtitle: '滤镜/裁剪',
                      color: Color(0xFFEC4899),
                      route: null,
                    ),
                    ToolTile(
                      icon: Icons.swap_horiz,
                      label: '格式转换',
                      subtitle: 'PDF/Office',
                      color: TBColors.secondary,
                      route: null,
                    ),
                    ToolTile(
                      icon: Icons.cloud_sync_outlined,
                      label: '云同步',
                      subtitle: '跨设备',
                      color: Color(0xFFF59E0B),
                      route: null,
                    ),
                    ToolTile(
                      icon: Icons.folder_open,
                      label: '我的文档',
                      subtitle: '已扫描',
                      color: Color(0xFF6B7280),
                      route: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
