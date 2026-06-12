// test/widget_test.dart - 工具磁贴组件测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toolbox_scanner/features/scanner/presentation/widgets/tool_tile.dart';
import 'package:toolbox_scanner/design_system/tokens.dart';

void main() {
  group('ToolTile', () {
    testWidgets('renders label and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              icon: Icons.document_scanner_outlined,
              label: '扫描',
              subtitle: 'OCR + 高清',
              color: TBColors.primary,
              route: '/scanner',
            ),
          ),
        ),
      );

      expect(find.text('扫描'), findsOneWidget);
      expect(find.text('OCR + 高清'), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
    });

    testWidgets('does not throw when tapped with route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              icon: Icons.document_scanner_outlined,
              label: '扫描',
              subtitle: 'OCR + 高清',
              color: TBColors.primary,
              route: '/scanner',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ToolTile));
      await tester.pump();

      // 验证无异常(Navigator 会因为没有注册路由而抛错,这里只验证组件本身不崩溃)
    });

    testWidgets('does not trigger navigation when route is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolTile(
              icon: Icons.edit_outlined,
              label: '编辑',
              subtitle: '暂未实现',
              color: Color(0xFFEC4899),
              route: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ToolTile));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
