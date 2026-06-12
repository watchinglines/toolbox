# scripts/setup_opencv.md - OpenCV Android SDK 配置指南

## 为什么需要 OpenCV?

`PerspectiveWarper` 已经内置了纯 Dart 单应矩阵实现,但在低端设备上可能:
- 30MB 图片处理耗时 > 1s
- 占用大量 CPU,影响相机预览流畅度
- 电池消耗大

接入 OpenCV 后,透视矫正性能可提升 **5-10 倍**。

## 配置步骤(Android)

### 1. 下载 OpenCV Android SDK

```bash
# 创建目录
mkdir -p android/app/src/main/cpp/opencv
cd android/app/src/main/cpp/opencv

# 下载 4.8.0
wget https://github.com/opencv/opencv/releases/download/4.8.0/opencv-4.8.0-android-sdk.zip
unzip opencv-4.8.0-android-sdk.zip

# 重命名
mv OpenCV-android-sdk sdk
```

### 2. 配置 CMake

`android/app/src/main/cpp/CMakeLists.txt` 已就位,会自动链接 `${CMAKE_SOURCE_DIR}/opencv/sdk/native/jni`。

### 3. 验证

```bash
cd android && ./gradlew assembleDebug
# 成功: 生成包含 libtoolbox_opencv.so 的 APK
# 失败: 检查 NDK 版本(必须 25.x)+ OpenCV 路径
```

## 配置步骤(iOS)

iOS 端使用 Apple Vision 框架,无需额外 OpenCV 库:

```swift
// ios/Runner/NativePlugins/ScannerOpenCV.swift
// 已使用 CIPerspectiveCorrection(零依赖)+ VNDetectRectanglesRequest
```

如需 OpenCV iOS:

```ruby
# ios/Podfile
pod 'OpenCV', '~> 4.1'
```

## 验证清单

- [ ] Android 编译通过
- [ ] libtoolbox_opencv.so 出现在 APK 中:
  `unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep opencv`
- [ ] iOS Vision 框架可调用(无需 OpenCV)
- [ ] `lib/features/scanner/data/cv/opencv_bridge.dart` 中 `warpPerspective` 返回非 null

## 性能对比(预期)

| 方案 | 30MB 图片处理耗时 | CPU 占用 | 内存峰值 |
|------|------------------|---------|---------|
| 纯 Dart | 1.2s | 95% | 280MB |
| OpenCV FFI | 0.2s | 35% | 180MB |
| Apple Vision (iOS) | 0.1s | 20% | 150MB |
