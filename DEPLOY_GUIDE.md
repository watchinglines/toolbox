# 📱 真机验证手册

## 部署前准备

### 设备要求

| 平台 | 最低 | 推荐 |
|------|------|------|
| iOS | iPhone X / iOS 15.0 | iPhone 13+ / iOS 17+ |
| Android | API 26 (8.0) | API 31+ (12+) |
| 内存 | 3GB | 6GB+ |

### 开发机要求

- **macOS**: Xcode 15+, CocoaPods, Flutter 3.24+, iOS 真机调试需要 Apple Developer 账号(免费即可)
- **Windows/Linux**: Android Studio Hedgehog+, Android SDK 34, NDK 25.x, Flutter 3.24+
- **USB 数据线**:必须支持数据传输(纯充电线无效)

---

## iOS 真机部署

### 一键脚本(推荐)

```bash
cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner
bash scripts/deploy_ios.sh
```

### 手动步骤

1. **真机连接**
   - iPhone 用 USB 连接 Mac
   - 首次连接需在 iPhone 点击「信任此电脑」

2. **配置签名**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - 选择 Runner target → Signing & Capabilities
   - Team: 选择你的 Apple ID
   - Bundle Identifier: `com.toolbox.scanner`(需唯一,改成你的)

3. **启动应用**
   ```bash
   flutter run -d <device_id>
   ```

### 验证清单

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 1 | 启动 App | 3 秒内看到工具九宫格首页 |
| 2 | 点击「扫描」 | 弹出相机权限 → 允许 |
| 3 | 扫描页 | 实时预览 + 四角动画 + 扫描线 |
| 4 | 拍摄 A4 纸 | 看到「处理中...」→ 提示识别字符数 |
| 5 | 拍摄倾斜文档 | 自动检测角点 + 黄色高亮边框 |
| 6 | 切换扫描模式 | 文档/票据/书籍等下拉切换 |
| 7 | 从相册导入 | 选图 → 处理 → 跳转结果页 |
| 8 | 查看性能日志 | `flutter logs` 中看到 `App ready in XXXXms` |

### 调试技巧

```bash
# 实时日志
flutter logs

# 性能面板(打开 DevTools)
flutter run --observatory-port=9200
# 浏览器打开显示的 URL

# 检查 Vision 框架是否生效
# 在 Xcode 控制台搜索: CIPerspectiveCorrection
```

---

## Android 真机部署

### 一键脚本(推荐)

```bash
cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner
bash scripts/deploy_android.sh
```

### 手动步骤

1. **开启开发者模式**
   - 设置 → 关于本机 → 连续点击「版本号」7 次
   - 返回 → 系统 → 开发者选项 → 启用「USB 调试」

2. **真机连接**
   - USB 连接电脑
   - 手机弹出「是否允许 USB 调试」→ 勾选「始终允许」→ 确定

3. **验证连接**
   ```bash
   adb devices
   # 应显示: <device_id>  device
   ```

4. **配置 OpenCV SDK**(可选,首次)
   - 见 `scripts/setup_opencv.md`
   - 不配置也能运行,会自动降级到纯 Dart 实现

5. **启动应用**
   ```bash
   flutter run -d android --debug
   ```

### 验证清单

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 1 | 启动 App | 3 秒内看到首页(Logcat 搜 `ToolBox`) |
| 2 | 第一次扫描 | 弹 ML Kit 模型下载进度(约 5MB) |
| 3 | 相机预览 | 60fps 稳定(用 DevTools Performance 检查) |
| 4 | 拍摄文档 | Toast「识别到 N 个字符」 |
| 5 | 倾斜文档 | 黄色边框自动跟随 + 透视矫正 |
| 6 | 内存占用 | Android Studio Profiler 显示 < 280MB |

### 调试技巧

```bash
# Logcat 过滤
adb logcat | grep -E "ToolBox|flutter|MLKit|OpenCV"

# 性能分析
adb shell am start -W -n com.toolbox.scanner/.MainActivity
# -W: 等待启动完成,输出启动耗时

# 检查 OpenCV 库是否加载
adb logcat | grep "toolbox_opencv"

# 截图取证
adb exec-out screencap -p > screenshot.png
```

---

## 性能基线测试

部署完成后,在控制台运行:

```dart
// 在 main.dart 临时加入
await PerformanceMonitor.runStartupDiagnostic();
```

### 目标指标

| 指标 | 优秀 | 合格 | 不合格 |
|------|------|------|--------|
| 冷启动到首页 | < 1.5s | < 2.5s | > 3s |
| 相机首帧 | < 500ms | < 1s | > 1.5s |
| 单页扫描到完成 | < 1.5s | < 3s | > 5s |
| 内存(扫描中) | < 200MB | < 300MB | > 400MB |
| 帧率 | 58+ fps | 50+ fps | < 45fps |
| OCR 准确率(印刷体) | > 95% | > 85% | < 80% |

### 收集证据

```bash
# 启动时间
adb shell am start -W -n com.toolbox.scanner/.MainActivity | grep "TotalTime"

# CPU 占用
adb shell top -p $(adb shell pidof com.toolbox.scanner) -n 1

# 内存占用
adb shell dumpsys meminfo com.toolbox.scanner
```

---

## 常见问题

### iOS

| 问题 | 解决 |
|------|------|
| `Could not build for iOS` | `cd ios && pod install --repo-update` |
| `Code Signing Error` | Xcode → Runner → Signing → 选择 Team |
| `Permission denied for camera` | 设置 → ToolBox → 相机 → 开启 |
| `ML Kit 模型下载失败` | 检查网络,模型在首次使用自动下载 |

### Android

| 问题 | 解决 |
|------|------|
| `Gradle build failed` | 升级 NDK 到 25.x,`flutter clean` |
| `OpenCV 链接失败` | 见 `scripts/setup_opencv.md` 配置 SDK |
| `ML Kit 不可用` | 检查 `google-services.json` 或网络 |
| `相机黑屏` | 真机型号过旧,降级到 Android 7 编译 |

---

## 验证通过后的下一步

1. **提交性能数据**:把 `adb shell am start -W` 的输出记录到 `MEMORY.md`
2. **录制演示视频**:用屏幕录制捕获扫描流程(3-5 分钟)
3. **填写 App Store 截图**:准备 6.5" / 6.7" 截图各 5 张
4. **更新文档**:把发现的性能瓶颈和修复记录到 `CHANGELOG.md`
