// ios/Runner/AppDelegate.swift - 升级版注册插件
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 注册自定义插件
    if let controller = window?.rootViewController as? FlutterViewController {
      DiagnosticsPlugin.register(
        with: self.registrar(forPlugin: "DiagnosticsPlugin")!
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
