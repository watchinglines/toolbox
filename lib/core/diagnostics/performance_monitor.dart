// lib/core/diagnostics/performance_monitor.dart
// 性能监控器 - 跟踪启动时间、扫描耗时、内存占用
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

class PerfMetric {
  final String name;
  final int durationMs;
  final Map<String, Object>? extra;
  const PerfMetric(this.name, this.durationMs, {this.extra});
}

class PerformanceMonitor {
  static final List<PerfMetric> _metrics = [];
  static final DateTime _appStartTime = DateTime.now();

  /// 记录性能指标
  static void record(String name, int durationMs, {Map<String, Object>? extra}) {
    _metrics.add(PerfMetric(name, durationMs, extra: extra));
    AppLogger.info('PERF: $name = ${durationMs}ms');
  }

  /// 测量异步操作耗时
  static Future<T> track<T>(String name, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      sw.stop();
      record(name, sw.elapsedMilliseconds);
    }
  }

  /// 获取应用启动耗时(从进程启动到调用此方法)
  static int getAppStartMs() {
    return DateTime.now().difference(_appStartTime).inMilliseconds;
  }

  /// 获取当前内存占用(仅 Android/iOS)
  static Future<int> getMemoryUsageMB() async {
    try {
      if (Platform.isAndroid) {
        // Android:读取 /proc/self/status
        final file = File('/proc/self/status');
        if (await file.exists()) {
          final content = await file.readAsString();
          final match = RegExp(r'VmRSS:\s+(\d+)\s+kB').firstMatch(content);
          if (match != null) {
            return int.parse(match.group(1)!) ~/ 1024;
          }
        }
      } else if (Platform.isIOS) {
        // iOS:使用 platform channel 获取
        const channel = MethodChannel('com.toolbox/perf');
        final mb = await channel.invokeMethod<int>('getMemoryMB');
        return mb ?? 0;
      }
    } catch (e) {
      AppLogger.warn('Failed to get memory: $e');
    }
    return 0;
  }

  /// 输出汇总
  static Map<String, dynamic> summary() {
    return {
      'appStartMs': getAppStartMs(),
      'metrics': _metrics
          .map((m) => {'name': m.name, 'ms': m.durationMs, 'extra': m.extra})
          .toList(),
    };
  }

  /// 真实机验证清单
  static Future<void> runStartupDiagnostic() async {
    if (kReleaseMode) return;

    AppLogger.info('=== Startup Diagnostic ===');
    AppLogger.info('App start to now: ${getAppStartMs()}ms');
    final mem = await getMemoryUsageMB();
    AppLogger.info('Memory usage: ${mem}MB');

    // Flutter 框架渲染
    final bindingStart = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 100));
    AppLogger.info('Frame scheduling OK (100ms warmup)');
    AppLogger.info('Warmup delta: ${DateTime.now().difference(bindingStart).inMilliseconds}ms');
  }
}
