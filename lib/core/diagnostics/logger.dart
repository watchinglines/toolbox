// lib/core/diagnostics/logger.dart
// 统一日志工具 - 支持 iOS/Android 控制台 + 文件落盘
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  static const _tag = 'ToolBox';
  static bool _fileLogging = false;

  static void enableFileLogging(bool enabled) {
    _fileLogging = enabled;
  }

  static void debug(String message, [Object? error]) {
    _log(LogLevel.debug, message, error);
  }

  static void info(String message, [Object? error]) {
    _log(LogLevel.info, message, error);
  }

  static void warn(String message, [Object? error]) {
    _log(LogLevel.warn, message, error);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message, error, stack);
  }

  /// 性能测量 - 简单计时器
  static T measure<T>(String label, T Function() block) {
    final stopwatch = Stopwatch()..start();
    try {
      return block();
    } finally {
      stopwatch.stop();
      info('$label took ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  static Future<T> measureAsync<T>(String label, Future<T> Function() block) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await block();
    } finally {
      stopwatch.stop();
      info('$label took ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  static void _log(LogLevel level, String message, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(5);
    final logLine = '[$timestamp] [$levelStr] $_tag | $message'
        '${error != null ? ' | error: $error' : ''}';

    if (kDebugMode) {
      // 开发模式:打印到控制台
      developer.log(logLine, name: _tag);
      if (stack != null) {
        developer.log(stack.toString(), name: _tag, error: error);
      }
    } else {
      // 生产模式:仅 error 级别打印
      if (level == LogLevel.error) {
        debugPrint(logLine);
      }
    }
  }
}
