#!/usr/bin/env bash
# scripts/build_ios.sh - iOS IPA 打包脚本
# 支持: Debug / Release / Ad-Hoc / App Store
set -e

# ============ 配置 ============
APP_NAME="ToolBox"
BUNDLE_ID="com.toolbox.scanner"
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | head -1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
VERSION_NAME=$(echo $VERSION | cut -d'+' -f1)
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
EXPORT_PATH="build/ios/ipa"
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

# ============ 颜色输出 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ============ 步骤 1: 环境检查 ============
info "检查 macOS / Xcode 环境..."
if [[ "$(uname)" != "Darwin" ]]; then
    error "iOS 打包必须在 macOS 上执行"
fi

if ! command -v xcodebuild &> /dev/null; then
    error "Xcode 未安装,请安装 Xcode 15+"
fi

if ! command -v pod &> /dev/null; then
    error "CocoaPods 未安装: sudo gem install cocoapods"
fi

XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
info "Xcode 版本: $XCODE_VERSION"

# ============ 步骤 2: 选择构建类型 ============
BUILD_TYPE="${1:-release}"
EXPORT_METHOD="${2:-app-store}"  # app-store | ad-hoc | development | enterprise

case "$BUILD_TYPE" in
    debug|profile|release) ;;
    *) error "用法: $0 [debug|profile|release] [app-store|ad-hoc|development]";;
esac

case "$EXPORT_METHOD" in
    app-store|ad-hoc|development|enterprise) ;;
    *) error "导出方式必须是: app-store | ad-hoc | development | enterprise";;
esac

info "构建类型: $BUILD_TYPE"
info "导出方式: $EXPORT_METHOD"

# ============ 步骤 3: 拉取依赖 ============
info "拉取依赖..."
flutter pub get || error "依赖拉取失败"

info "安装 CocoaPods..."
cd ios && pod install --repo-update && cd ..
success "Pods 已就绪"

# ============ 步骤 4: 准备 ExportOptions.plist ============
EXPORT_PLIST="ios/ExportOptions.plist"
if [ ! -f "$EXPORT_PLIST" ]; then
    warn "未找到 ExportOptions.plist,使用默认模板..."
    if [ "$EXPORT_METHOD" = "app-store" ]; then
        cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
EOF
    else
        cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
    fi
    success "已生成 $EXPORT_PLIST"
fi

# ============ 步骤 5: 清理 + 预构建 ============
info "清理旧的构建产物..."
flutter clean
flutter pub get
cd ios && pod install && cd ..

# ============ 步骤 6: Flutter 构建 ============
info "开始 Flutter 构建(这可能需要几分钟)..."
flutter build ios --$BUILD_TYPE --no-codesign \
    --build-name=$VERSION_NAME \
    --build-number=$BUILD_NUMBER \
    --dart-define=APP_VERSION=$VERSION_NAME \
    --dart-define=BUILD_NUMBER=$BUILD_NUMBER

success "Flutter 构建完成"

# ============ 步骤 7: Xcode Archive ============
info "开始 Xcode Archive..."
cd ios

xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration $BUILD_TYPE \
    -archivePath "../$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    archive 2>&1 | tail -50

cd ..
success "Archive 已生成: $ARCHIVE_PATH"

# ============ 步骤 8: 导出 IPA ============
info "导出 IPA..."
mkdir -p "$EXPORT_PATH"

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" 2>&1 | tail -20

IPA_PATH="$EXPORT_PATH/Runner.ipa"
if [ -f "$IPA_PATH" ]; then
    IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
    success "IPA 已生成: $IPA_PATH ($IPA_SIZE)"
else
    error "IPA 导出失败"
fi

# ============ 步骤 9: 验证 IPA ============
info "验证 IPA..."
if command -v xcrun &> /dev/null; then
    info="Bundle ID: $(unzip -p $IPA_PATH Payload/Runner.app/Info.plist 2>/dev/null | grep -A1 'CFBundleIdentifier' | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' || echo 'N/A')"
    info "$info"
fi

# ============ 步骤 10: 输出汇总 ============
echo ""
echo "================================================"
echo "  📦 构建完成"
echo "================================================"
echo "App 名称:    $APP_NAME"
echo "版本:        $VERSION_NAME ($BUILD_NUMBER)"
echo "Bundle ID:   $BUNDLE_ID"
echo "导出方式:    $EXPORT_METHOD"
echo ""
echo "输出文件:"
echo "  IPA:     $(realpath $IPA_PATH)"
echo "  Archive: $(realpath $ARCHIVE_PATH)"
echo ""
echo "下一步:"
case "$EXPORT_METHOD" in
    app-store)
        echo "  - 上传到 App Store Connect:"
        echo "    xcrun altool --upload-app --type ios --file \"$IPA_PATH\" --username YOUR_APPLE_ID"
        echo "  - 或使用 Transporter 应用"
        ;;
    ad-hoc)
        echo "  - 分发给测试设备: ios-deploy --id <udid> --bundle \"$IPA_PATH\""
        echo "  - 或使用 Firebase App Distribution"
        ;;
    development)
        echo "  - 直接安装到设备: ideviceinstaller -i \"$IPA_PATH\""
        ;;
esac
echo "================================================"
