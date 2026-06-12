# 🚧 Windows 端构建前置依赖安装指南

> 当前机器检查结果:
> - ❌ Flutter SDK 未安装
> - ❌ JDK 17 未安装
> - ❌ Android SDK 完整包未安装(只有 `D:\android\platform-tools`)
> - ✅ ADB 已存在于 `D:\android\platform-tools\adb.exe`

## 📋 三步完成环境搭建

### 第一步:安装 Flutter SDK(约 5 分钟)

1. **下载 Flutter SDK**
   - 访问: https://docs.flutter.dev/get-started/install/windows
   - 或直接下载: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip
   - 建议版本: **3.24.5**(稳定版,与项目匹配)

2. **解压到 C 盘**
   ```
   解压到: C:\flutter
   ```
   ⚠️ 不要放在 `C:\Program Files\`(权限问题)

3. **配置 PATH**
   - 右键「此电脑」→ 属性 → 高级系统设置 → 环境变量
   - 在「系统变量」中找到 `Path` → 编辑 → 新建
   - 添加: `C:\flutter\bin`
   - 确定保存

4. **验证安装**(新开 PowerShell)
   ```powershell
   flutter --version
   # 期望: Flutter 3.24.5 ... Dart 3.5.4
   ```

5. **设置中国镜像**(可选,加速下载)
   ```powershell
   # 设置 PUB 国内镜像
   $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
   $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

   # 永久设置
   [System.Environment]::SetEnvironmentVariable("PUB_HOSTED_URL", "https://pub.flutter-io.cn", "User")
   [System.Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", "https://storage.flutter-io.cn", "User")
   ```

6. **首次运行诊断**
   ```powershell
   flutter doctor -v
   # 会提示需要安装: Android Toolchain, Android Studio, Chrome, Visual Studio 等
   ```

### 第二步:安装 JDK 17(约 3 分钟)

1. **下载 Temurin 17**(推荐 Adoptium)
   - 访问: https://adoptium.net/temurin/releases/?version=17
   - 选择: **Windows x64 JDK / .msi**
   - 下载并安装

2. **设置 JAVA_HOME**
   - 系统变量 → 新建
   - 变量名: `JAVA_HOME`
   - 变量值: `C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot`
   - (实际路径以你的安装位置为准)

3. **更新 PATH**
   - 在 `Path` 中新建: `%JAVA_HOME%\bin`

4. **验证**
   ```powershell
   java -version
   # 期望: openjdk version "17.0.13" ...

   $env:JAVA_HOME
   # 期望: C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot
   ```

### 第三步:安装 Android SDK(约 10 分钟)

#### 方式 A:Android Studio(推荐,适合新手)

1. **下载 Android Studio**
   - https://developer.android.com/studio
   - 安装时勾选 "Android Virtual Device"

2. **打开 SDK Manager**
   - Settings → Languages & Frameworks → Android SDK
   - SDK Platforms 勾选:**Android 14 (API 34)** + **Android 8.0 (API 26)**
   - SDK Tools 勾选:
     - [x] Android SDK Build-Tools 34.0.0
     - [x] Android SDK Platform-Tools
     - [x] Android SDK Command-line Tools
     - [x] NDK (Side by side) **25.1.8937393**
   - Apply → Accept → Install(约 1.5GB,需 5-10 分钟)

3. **设置 ANDROID_HOME**
   - 系统变量 → 新建
   - 变量名: `ANDROID_HOME`
   - 变量值: `C:\Users\JACK\AppData\Local\Android\Sdk`(Studio 默认路径)

4. **更新 PATH**
   - 新建: `%ANDROID_HOME%\platform-tools`
   - 新建: `%ANDROID_HOME%\cmdline-tools\latest\bin`
   - 新建: `%ANDROID_HOME%\emulator`

5. **接受许可**
   ```powershell
   sdkmanager --licenses
   # 全部输入 y
   ```

#### 方式 B:命令行工具(适合老手)

```powershell
# 1. 下载 commandlinetools
Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile "cmdline-tools.zip"

# 2. 解压到正确位置
Expand-Archive cmdline-tools.zip -DestinationPath $env:LOCALAPPDATA\Android\Sdk\cmdline-tools
Rename-Item "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\cmdline-tools" "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest"

# 3. 安装必需组件
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;25.1.8937393"

# 4. 接受许可
sdkmanager --licenses
```

### 第四步:接受 Android 许可(必须)

```powershell
flutter doctor --android-licenses
# 全部输入 y
```

## 🚀 构建第一个 APK

环境就绪后,在项目根目录执行:

```powershell
cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner

# 方式 1:PowerShell 脚本(推荐,Windows 原生)
powershell -ExecutionPolicy Bypass -File scripts\build_android.ps1 release apk

# 方式 2:Bash 脚本(如果已安装 Git Bash)
bash scripts/build_android.sh release apk
```

### 预期输出

```
ℹ️  检查 Flutter 环境...
✅ Flutter 已就绪: C:\flutter\bin\flutter.exe
ℹ️  版本: Flutter 3.24.5 ...
ℹ️  拉取依赖...
✅ 依赖已就绪
ℹ️  版本: 0.1.0+1
⚠️  未找到签名密钥,自动生成...
✅ 已生成签名密钥: C:\Users\JACK\.toolbox\upload-keystore.jks
✅ 已写入 android\key.properties
✅ Gradle 签名已配置
ℹ️  清理旧的构建产物...
ℹ️  开始构建(首次可能需要 5-10 分钟下载依赖)...
✅ APK 构建完成
ℹ️  包体积分析...
✅ APK 大小: 23.45 MB
✅ 已复制到: C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner\dist\android\toolbox-0.1.0.apk

================================================
  📦 构建完成
================================================
App 名称:    ToolBox
版本:        0.1.0+1
包名:        com.toolbox.scanner
签名:        已签名
```

### 输出位置

| 类型 | 路径 |
|------|------|
| 原始 APK | `build\app\outputs\flutter-apk\app-release.apk` |
| 复制到 dist | `dist\android\toolbox-0.1.0.apk` |
| 签名密钥 | `C:\Users\JACK\.toolbox\upload-keystore.jks` |

## 📱 安装到真机

```powershell
# 1. USB 连接 Android 手机
# 2. 开启 USB 调试: 设置 → 开发者选项 → USB 调试
# 3. 验证连接
adb devices
# 应显示: <device_id>  device

# 4. 安装 APK
adb install dist\android\toolbox-0.1.0.apk

# 5. 启动 App
adb shell am start -n com.toolbox.scanner/.MainActivity
```

## 🔍 常见问题

### Q1: `flutter doctor` 报错 "Unable to locate Android SDK"
**原因**: `ANDROID_HOME` 未设置
**解决**: 按上面第三步设置 `ANDROID_HOME` 环境变量,重启 PowerShell

### Q2: `BUILD FAILED - Unsupported class file major version 65`
**原因**: JDK 版本不匹配(用了 JDK 21)
**解决**: 安装 JDK 17 并设置 `JAVA_HOME`

### Q3: `NDK not configured`
**原因**: 没装 NDK
**解决**: `sdkmanager "ndk;25.1.8937393"`

### Q4: Gradle 下载慢
**解决**: 在 `android/build.gradle.kts` 中添加阿里云镜像
```kotlin
allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
    }
}
```

### Q5: Flutter 下载依赖慢
**解决**: 已设置 `PUB_HOSTED_URL` 国内镜像(见第一步)

### Q6: 第一次构建超过 30 分钟
**原因**: 下载 Gradle 8.x + Android Gradle Plugin + Kotlin 编译器
**正常**: 首次构建 5-15 分钟属正常,后续会缓存

## ⏱️ 预估时间

| 阶段 | 首次 | 后续 |
|------|------|------|
| 环境安装 | 30-60 分钟 | - |
| 依赖下载 | 5-10 分钟 | 10 秒 |
| Gradle 首次构建 | 10-15 分钟 | 30 秒 |
| APK 打包 | 2-3 分钟 | 30 秒 |
| **合计** | **~60 分钟** | **~1 分钟** |

## ✅ 安装完所有依赖后,执行验证

```powershell
flutter doctor -v
```

期望输出(关键 4 项 ✓):
```
[✓] Flutter (Channel stable, 3.24.5, on Microsoft Windows ...)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Android Studio (version 2024.1)
[✓] Connected device (1 available)
```

确认 4 个绿勾后,即可开始构建 APK。
