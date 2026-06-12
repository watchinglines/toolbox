// scripts/deploy_ios.sh - iOS 真机部署脚本
#!/usr/bin/env bash
set -e

echo "========================================="
echo "  ToolBox iOS 真机部署"
echo "========================================="

# 1. 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    echo "请运行: brew install --cask flutter 或访问 https://flutter.dev"
    exit 1
fi

# 2. 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode 未安装,请安装 Xcode 15+"
    exit 1
fi

# 3. 拉取依赖
echo "📦 拉取 Flutter 依赖..."
flutter pub get

# 4. 安装 Pod
echo "🍫 安装 iOS CocoaPods 依赖..."
cd ios && pod install --repo-update && cd ..

# 5. 检测连接设备
echo "📱 检测 iOS 设备..."
flutter devices | grep -E "ios|iPhone|iPad" || {
    echo "❌ 未发现 iOS 设备"
    echo "请通过 USB 连接设备并在 Xcode 中信任此电脑"
    exit 1
}

# 6. 启动构建
echo "🚀 开始构建 Debug 版本..."
DEVICE_ID=$(flutter devices | grep -E "ios|iPhone" | head -1 | awk -F'•' '{print $2}' | xargs)
echo "目标设备: $DEVICE_ID"

# 7. 启动应用
flutter run -d "$DEVICE_ID" --debug \
    --dart-define=PERF_MONITOR=true \
    --dart-define=LOG_LEVEL=debug

echo ""
echo "✅ 部署完成"
echo ""
echo "调试提示:"
echo "  - 在 Xcode 中查看: open ios/Runner.xcworkspace"
echo "  - 查看日志:        flutter logs"
echo "  - 性能分析:        Flutter DevTools (启动后 URL 会显示)"
