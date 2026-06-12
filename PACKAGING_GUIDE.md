# 📦 App 打包完整指南

将 `toolbox_scanner` 打包成可在 iOS / Android 设备上安装的格式,以及发布到应用商店。

## 🎯 目标产物

| 平台 | 文件格式 | 用途 |
|------|---------|------|
| iOS | `Runner.ipa` | TestFlight / App Store / 内部分发 |
| Android | `app-release.apk` | 直接安装 / 第三方市场 |
| Android | `app-release.aab` | Google Play(必传格式) |

## ⚙️ 前置准备

### Android 端

1. **JDK 17**(Flutter 3.24 要求)
2. **Android SDK + NDK 25.x**
3. **签名密钥**(Release 必需,自动生成)
4. **Google Play Console 账号**(发布 AAB 时)

### iOS 端(必须在 macOS)

1. **Xcode 15+**
2. **Apple Developer 账号**(免费即可开发,发布需 $99/年)
3. **CocoaPods**(`sudo gem install cocoapods`)
4. **Bundle Identifier** 唯一(App Store 全局唯一)
5. **Team ID**(登录 developer.apple.com 获取)

## 🚀 快速打包

### Android

```bash
cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner
bash scripts/build_android.sh release apk    # 生成 APK
bash scripts/build_android.sh release aab    # 生成 AAB (Play Store)
bash scripts/build_android.sh release both   # 两者都生成
bash scripts/build_android.sh debug apk      # Debug 版
```

### iOS(macOS)

```bash
cd ~/path/to/toolbox_scanner

# Debug 包(开发测试)
bash scripts/build_ios.sh debug development

# Ad-Hoc(内测,最多 100 设备)
bash scripts/build_ios.sh release ad-hoc

# App Store(发布)
TEAM_ID=ABC123XYZ bash scripts/build_ios.sh release app-store
```

## 📍 输出位置

| 平台 | 路径 |
|------|------|
| Android APK | `toolbox_scanner/build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `toolbox_scanner/build/app/outputs/bundle/release/app-release.aab` |
| iOS IPA | `toolbox_scanner/build/ios/ipa/Runner.ipa` |
| iOS Archive | `toolbox_scanner/build/ios/archive/Runner.xcarchive` |

## 🏪 发布到应用商店

### Google Play(Android)

1. **创建应用**
   - 访问 https://play.google.com/console
   - "创建应用" → 填写名称、默认语言、应用类型

2. **上传 AAB**
   ```
   测试 → 内部测试 → 创建新版本 → 上传 app-release.aab
   ```

3. **填写商店信息**
   - 应用图标(512x512 高分辨率)
   - 屏幕截图(手机 6.7" + 平板 10")
   - 简短描述(80 字符)+ 完整描述(4000 字符)
   - 类别、标签、隐私政策 URL

4. **内容分级**
   - 填写内容分级问卷
   - 目标受众年龄段

5. **定价与分发**
   - 选择免费 / 付费
   - 包含的国家/地区

6. **提交审核**
   - 内部测试 → 关闭 → 正式版 → 提交
   - 审核时长:首次 3-7 天

### App Store(iOS)

1. **创建 App Store Connect 记录**
   - 访问 https://appstoreconnect.apple.com
   - "我的 App" → "+" → "新建 App"
   - 填写名称、Bundle ID、SKU

2. **准备上架素材**
   - 6.5" 显示屏截图(至少 3 张,最多 10 张):1242×2688
   - 6.7" 显示屏截图(必填):1290×2796
   - 5.5" 显示屏截图(可选):1242×2208
   - iPad 12.9" 截图(若支持 iPad):2048×2732
   - App 图标:1024×1024 PNG(无透明度、无圆角)
   - 推广文本(170 字符)
   - 描述(4000 字符)
   - 关键词(100 字符,逗号分隔)
   - 类别、技术网址、营销网址

3. **上传 IPA**
   - 方式 A:Xcode → Organizer → Distribute App
   - 方式 B:`xcrun altool --upload-app --type ios --file Runner.ipa --username YOUR_APPLE_ID`
   - 方式 C:Transporter 应用

4. **配置 App 信息**
   - 隐私政策 URL(必需)
   - 加密声明(标准加密 = 豁免)
   - 出口合规

5. **提交审核**
   - "为 App Store 审核添加版本"
   - 填写审核信息(联系信息、登录凭据、备注)
   - 提交
   - 审核时长:首次 1-3 天,加急 1 天

## 🔐 签名配置(必做)

### Android 自动签名

`build_android.sh` 会自动:
1. 检测 `~/.toolbox/upload-keystore.jks` 是否存在
2. 不存在 → 自动生成 10000 天有效期密钥
3. 写入 `android/key.properties`
4. 修改 `android/app/build.gradle.kts` 启用签名

**安全建议**:
```bash
# 把密钥同步到密码管理器(1Password / Bitwarden)
KEYSTORE_PASS=$(security find-generic-password -s "toolbox-keystore" -w)
```

### iOS 手动配置

1. **登录 Apple Developer**
2. **创建 Bundle ID**:`com.toolbox.scanner`
3. **创建 App Store Connect API Key**
4. **设置 Team ID**:在 `~/.zshrc` 写入
   ```bash
   export TEAM_ID="ABC123XYZ"
   ```
5. **首次打包需在 Xcode 中登录账号**:Xcode → Settings → Accounts

## 🧪 内部测试分发

### Firebase App Distribution(推荐,免费)

```bash
# 安装
npm install -g firebase-tools
firebase login

# 上传 Android APK
firebase appdistribution:distribute \
    build/app/outputs/flutter-apk/app-release.apk \
    --app <FIREBASE_ANDROID_APP_ID> \
    --groups "internal-testers"

# 上传 iOS IPA
firebase appdistribution:distribute \
    build/ios/ipa/Runner.ipa \
    --app <FIREBASE_IOS_APP_ID> \
    --groups "internal-testers"
```

### 蒲公英 / fir.im(国内,免登录)

```bash
# 上传到蒲公英
curl -F "file=@build/app/outputs/flutter-apk/app-release.apk" \
     -F "_api_key=YOUR_PG_KEY" \
     https://www.pgyer.com/apiv2/app/upload
```

## 📊 包体积优化

| 优化项 | 节省 | 操作 |
|--------|------|------|
| 启用 R8/ProGuard | 30-50% | `build.gradle.kts`: `isMinifyEnabled = true` |
| 移除未使用资源 | 5-10% | `isShrinkResources = true` |
| ABI 分包 | 30-50% | `splits.abi.enable = true` |
| 字体子集化 | 2-5MB | 仅打包用到的字重 |
| 图标压缩 | 1-2MB | 使用 WebP 替代 PNG |
| 动态加载 ML Kit | 5MB | 用户首次使用再下载 |

### ABI 分包配置示例(`android/app/build.gradle.kts`)

```kotlin
android {
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = true  // 保留通用包
        }
    }
}
```

## ⚠️ 常见打包错误

| 错误 | 解决方案 |
|------|---------|
| `Keystore was tampered with` | 重新生成密钥,确认 `key.properties` 路径正确 |
| `Execution failed for task ':app:minifyReleaseWithR8'` | 暂时关闭 `isMinifyEnabled`,先验证其他配置 |
| `Provisioning profile doesn't include the Bundle ID` | Xcode → Runner → Signing → 重新选择 Team |
| `BUILD FAILED - iOS deployment target too low` | 升级 iOS 最低版本到 15.0(`ios/Podfile`) |
| `Could not find method abiFilters()` | 升级 Gradle Plugin 到 8.0+ |
| `NDK not configured` | `sdkmanager --install "ndk;25.1.8937393"` |
| `App Store Connect API key invalid` | 重新下载 .p8 密钥,设置环境变量 |

## ✅ 发布前清单

### Android

- [ ] 包名正确(`com.toolbox.scanner`)
- [ ] 版本号递增(`pubspec.yaml` 中 version)
- [ ] 应用图标 5 个分辨率齐全
- [ ] ProGuard 规则覆盖所有反射类
- [ ] 64 位 ABI 支持(arm64-v8a)
- [ ] targetSdk 34(Google Play 强制)
- [ ] 数据安全声明(Play Console)
- [ ] 隐私政策 URL
- [ ] 目标 API 等级问卷

### iOS

- [ ] Bundle ID 全局唯一
- [ ] 启动屏(LaunchScreen.storyboard)配置
- [ ] 应用图标含完整尺寸(1024x1024)
- [ ] Info.plist 权限说明完整
- [ ] iOS 15+ 兼容性测试
- [ ] iPhone / iPad 适配
- [ ] App Tracking Transparency(若使用 IDFA)
- [ ] 出口合规信息
- [ ] 加密声明(`ITSAppUsesNonExemptEncryption: false`)

## 📈 上线后监控

### Firebase Crashlytics(崩溃监控)

```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.0.0
  firebase_analytics: ^11.0.0
```

### 友盟统计(国内)

```yaml
dependencies:
  umeng_analytics: ^2.0.0
```

### Sentry(应用性能)

```yaml
dependencies:
  sentry_flutter: ^8.0.0
```

## 🎁 快捷命令汇总

```bash
# 一键 Android Release
bash scripts/build_android.sh release both

# 一键 iOS Release
bash scripts/build_ios.sh release app-store

# 仅 Debug(开发用,5 秒出包)
flutter build apk --debug          # Android
flutter build ios --debug --no-codesign  # iOS

# 安装到当前连接的真机
flutter install

# 完整清理
flutter clean && flutter pub get
```

---

📌 **下一步建议**:
1. 跑通 `bash scripts/build_android.sh release apk` 生成第一个 APK
2. 用 `adb install` 安装到真机测试核心流程
3. 配置签名密钥并出 Release 包
4. 接入 Firebase / Sentry 开始监控
5. 准备商店素材(截图 + 描述 + 隐私政策)
