// ios/Runner/DiagnosticsPlugin.swift
// iOS 内存/性能监控
import Foundation
import UIKit
import Flutter

class DiagnosticsPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.toolbox/perf",
      binaryMessenger: registrar.messenger()
    )
    let instance = DiagnosticsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getMemoryMB":
      result(getMemoryUsageMB())
    case "getCpuUsage":
      result(0.0)  // iOS 无公开 API 获取 CPU
    case "getDeviceModel":
      result(UIDevice.current.model)
    case "getOSVersion":
      result(UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getMemoryUsageMB() -> Int {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    if kerr == KERN_SUCCESS {
      return Int(info.phys_footprint / 1024 / 1024)
    }
    return 0
  }
}
