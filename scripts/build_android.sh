#!/usr/bin/env bash
# scripts/build_android.sh - Android APK/AAB 打包脚本
# 支持: Debug APK / Release APK / Release AAB (Play Store)
set -e

# ============ 配置 ============
APP_NAME="ToolBox"
PACKAGE_ID="com.toolbox.scanner"
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | head -1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
VERSION_NAME=$(echo $VERSION | cut -d'+' -f1)
KEYSTORE_PATH="$HOME/.toolbox/upload-keystore.jks"
KEY_ALIAS="upload"
KEYSTORE_PASS="${KEYSTORE_PASS:-toolbox2026}"
KEY_PASS="${KEY_PASS:-toolbox2026}"

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
info "检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    error "Flutter 未安装,请先安装 Flutter 3.24+"
fi

FLUTTER_VERSION=$(flutter --version | head -1 | awk '{print $2}')
info "Flutter 版本: $FLUTTER_VERSION"
[ "${FLUTTER_VERSION%%.*}" -lt 3 ] && error "需要 Flutter 3.x 或更高版本"

# ============ 步骤 2: 拉取依赖 ============
info "拉取依赖..."
flutter pub get || error "依赖拉取失败"
success "依赖已就绪"

# ============ 步骤 3: 选择构建类型 ============
BUILD_TYPE="${1:-release}"
BUILD_MODE="${2:-apk}"  # apk | aab | both

case "$BUILD_TYPE" in
    debug|profile|release) ;;
    *) error "用法: $0 [debug|profile|release] [apk|aab|both]";;
esac

info "构建类型: $BUILD_TYPE"
info "输出格式: $BUILD_MODE"

# ============ 步骤 4: Release 签名配置 ============
if [ "$BUILD_TYPE" = "release" ]; then
    if [ ! -f "$KEYSTORE_PATH" ]; then
        warn "未找到签名密钥,自动生成..."
        mkdir -p "$(dirname $KEYSTORE_PATH)"
        keytool -genkey -v \
            -keystore "$KEYSTORE_PATH" \
            -keyalg RSA -keysize 2048 \
            -validity 10000 \
            -alias "$KEY_ALIAS" \
            -storepass "$KEYSTORE_PASS" \
            -keypass "$KEY_PASS" \
            -dname "CN=ToolBox, OU=Mobile, O=ToolBox, L=Shenzhen, S=Guangdong, C=CN"
        success "已生成签名密钥: $KEYSTORE_PATH"
    fi

    # 写入 key.properties
    cat > android/key.properties <<EOF
storePassword=$KEYSTORE_PASS
keyPassword=$KEY_PASS
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF
    success "已生成 key.properties"

    # 修改 build.gradle.kts 启用签名
    info "配置 Gradle 签名..."
    if ! grep -q "key.properties" android/app/build.gradle.kts; then
        cat >> android/app/build.gradle.kts <<'GRADLE_EOF'

// Release 签名配置
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
GRADLE_EOF
        success "Gradle 签名已配置"
    fi
fi

# ============ 步骤 5: 清理 + 构建 ============
info "清理旧的构建产物..."
flutter clean
flutter pub get

info "开始构建(这可能需要几分钟)..."
case "$BUILD_MODE" in
    apk)
        flutter build apk --$BUILD_TYPE --build-name=$VERSION_NAME --build-number=$BUILD_NUMBER \
            --dart-define=APP_VERSION=$VERSION_NAME \
            --dart-define=BUILD_NUMBER=$BUILD_NUMBER
        APK_PATH="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
        success "APK 已生成: $APK_PATH"
        ;;
    aab)
        flutter build appbundle --$BUILD_TYPE --build-name=$VERSION_NAME --build-number=$BUILD_NUMBER \
            --dart-define=APP_VERSION=$VERSION_NAME \
            --dart-define=BUILD_NUMBER=$BUILD_NUMBER
        AAB_PATH="build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab"
        success "AAB 已生成: $AAB_PATH"
        ;;
    both)
        flutter build apk --$BUILD_TYPE
        flutter build appbundle --$BUILD_TYPE
        success "APK + AAB 均已生成"
        ;;
esac

# ============ 步骤 6: 包体积分析 ============
info "包体积分析..."
if [ -f "build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk" ]; then
    APK_SIZE=$(du -h "build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk" | cut -f1)
    success "APK 大小: $APK_SIZE"
fi
if [ -f "build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab" ]; then
    AAB_SIZE=$(du -h "build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab" | cut -f1)
    success "AAB 大小: $AAB_SIZE"
fi

# ============ 步骤 7: 输出位置汇总 ============
echo ""
echo "================================================"
echo "  📦 构建完成"
echo "================================================"
echo "App 名称:    $APP_NAME"
echo "版本:        $VERSION_NAME+$BUILD_NUMBER"
echo "包名:        $PACKAGE_ID"
echo ""
echo "输出文件:"
[ -f "build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk" ] && echo "  APK: $(realpath build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk)"
[ -f "build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab" ] && echo "  AAB: $(realpath build/app/outputs/bundle/${BUILD_TYPE}/app-$BUILD_TYPE.aab)"
echo ""
echo "下一步:"
echo "  - Android: adb install build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
echo "  - Play Store: 上传 AAB 到 Google Play Console"
echo "================================================"
