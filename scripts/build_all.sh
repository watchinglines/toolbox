#!/usr/bin/env bash
# scripts/build_all.sh - 一键全平台打包
# 同时生成 Android APK/AAB + iOS IPA
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

# Android
info "==========================================="
info "  Android 打包"
info "==========================================="
bash scripts/build_android.sh release both

# iOS(仅 macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    info ""
    info "==========================================="
    info "  iOS 打包"
    info "==========================================="
    bash scripts/build_ios.sh release app-store
else
    info ""
    info "==========================================="
    info "  iOS 跳过(需要 macOS)"
    info "==========================================="
fi

success ""
success "==========================================="
success "  全平台打包完成"
success "==========================================="
success "  Android APK: build/app/outputs/flutter-apk/app-release.apk"
success "  Android AAB: build/app/outputs/bundle/release/app-release.aab"
[[ "$(uname)" == "Darwin" ]] && success "  iOS IPA:     build/ios/ipa/Runner.ipa"
