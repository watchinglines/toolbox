// lib/main.dart - App 入口(采纳建议:从 dart:async 导入 unawaited,删除本地定义)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/diagnostics/performance_monitor.dart';
import 'core/diagnostics/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 记录启动开始
  AppLogger.info('App starting...');

  // 锁定竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 权限预申请
  await PerformanceMonitor.track('init.permissions', _requestPermissions);

  // 依赖注入
  await PerformanceMonitor.track('init.di', configureDependencies);

  // 启动诊断
  unawaited(PerformanceMonitor.runStartupDiagnostic());

  AppLogger.info('App ready in ${PerformanceMonitor.getAppStartMs()}ms');

  runApp(const ToolBoxApp());
}

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.storage.request();
}
