// scripts/deploy_android.sh - Android 真机部署脚本
#!/usr/bin/env bash
set -e

echo "========================================="
echo "  ToolBox Android 真机部署"
echo "========================================="

# 1. 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    exit 1
fi

# 2. 检查 ADB
if ! command -v adb &> /dev/null; then
    echo "❌ ADB 未找到,请安装 Android SDK Platform-Tools"
    echo "brew install --cask android-platform-tools"
    exit 1
fi

# 3. 拉取依赖
echo "📦 拉取 Flutter 依赖..."
flutter pub get

# 4. 检测设备
echo "📱 检测 Android 设备..."
adb devices -l
DEVICE_COUNT=$(adb devices | grep -c "device$")
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ 未发现 Android 设备"
    echo "请确认: 1) USB 连接  2) 开启开发者模式  3) 启用 USB 调试"
    exit 1
fi

# 5. 检查 NDK + OpenCV 库(必须先下载)
NDK_PATH=$ANDROID_HOME/ndk/25.1.8937393
if [ ! -d "$NDK_PATH" ]; then
    echo "⚠️  NDK 未找到,某些功能可能受限"
    echo "请通过 Android Studio SDK Manager 安装 NDK 25.x"
fi

# 6. 检查 OpenCV SDK
OPENCV_PATH=android/app/src/main/cpp/opencv
if [ ! -d "$OPENCV_PATH" ]; then
    echo "⚠️  OpenCV SDK 未配置"
    echo "请下载 OpenCV Android SDK 并解压到: $OPENCV_PATH"
    echo "下载地址: https://opencv.org/releases/"
    echo "或使用预编译 AAR: 在 app/build.gradle.kts 中添加"
    echo "  implementation(files('libs/opencv-4.8.0.aar'))"
fi

# 7. 构建并部署
echo "🚀 开始构建 Debug APK..."
flutter run -d android --debug \
    --dart-define=PERF_MONITOR=true \
    --dart-define=LOG_LEVEL=debug

echo ""
echo "✅ 部署完成"
echo ""
echo "调试提示:"
echo "  - Logcat 实时日志:   flutter logs"
echo "  - 性能分析:         Flutter DevTools"
echo "  - 内存/CPU:         Android Studio Profiler"
echo "  - 检查 OpenCV:      adb logcat | grep -i opencv"
