// scripts/build_android.ps1 - Windows PowerShell 版 Android 打包脚本
# 用法: .\scripts\build_android.ps1 -BuildType release -BuildMode apk
# 或:   powershell -ExecutionPolicy Bypass -File scripts\build_android.ps1 release apk

param(
    [ValidateSet('debug','profile','release')]
    [string]$BuildType = 'release',

    [ValidateSet('apk','aab','both')]
    [string]$BuildMode = 'apk'
)

$ErrorActionPreference = 'Stop'

# ============ 配置 ============
$APP_NAME = "ToolBox"
$PACKAGE_ID = "com.toolbox.scanner"
$KEYSTORE_DIR = Join-Path $env:USERPROFILE ".toolbox"
$KEYSTORE_PATH = Join-Path $KEYSTORE_DIR "upload-keystore.jks"
$KEY_ALIAS = "upload"
$KEYSTORE_PASS = if ($env:KEYSTORE_PASS) { $env:KEYSTORE_PASS } else { "toolbox2026" }
$KEY_PASS = if ($env:KEY_PASS) { $env:KEY_PASS } else { "toolbox2026" }

# 颜色
function Info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red; exit 1 }

# ============ 步骤 1: 环境检查 ============
Info "检查 Flutter 环境..."
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    # 尝试常见路径
    $commonPaths = @(
        "C:\flutter\bin",
        "C:\Program Files\flutter\bin",
        "C:\src\flutter\bin",
        "C:\tools\flutter\bin"
    )
    foreach ($p in $commonPaths) {
        $flutterExe = Join-Path $p "flutter.exe"
        if (Test-Path $flutterExe) {
            $env:Path = "$p;$env:Path"
            $flutterCmd = Get-Command flutter
            break
        }
    }
}
if (-not $flutterCmd) {
    $msg = @"
Flutter 未安装。请先安装 Flutter 3.24+:
  1. 下载: https://docs.flutter.dev/get-started/install/windows
  2. 解压到 C:\flutter
  3. 添加 C:\flutter\bin 到 PATH
  4. 重启 PowerShell

也可以从国内镜像加速下载(推荐):
  https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

或者一键安装命令(需管理员 PowerShell):
  winget install --id Google.Flutter -e --source winget
"@
    Write-Host $msg -ForegroundColor Yellow
    exit 1
}
Success "Flutter 已就绪: $($flutterCmd.Source)"

$flutterVer = & flutter --version 2>&1 | Select-Object -First 1
Info "版本: $flutterVer"

# ============ 步骤 2: 拉取依赖 ============
Info "拉取依赖..."
& flutter pub get
if ($LASTEXITCODE -ne 0) { Error "依赖拉取失败" }
Success "依赖已就绪"

# 解析版本
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*(\S+)') {
    $versionFull = $matches[1]
    if ($versionFull -match '^(.+)\+(\d+)$') {
        $VERSION_NAME = $matches[1]
        $BUILD_NUMBER = $matches[2]
    } else {
        $VERSION_NAME = $versionFull
        $BUILD_NUMBER = "1"
    }
} else {
    $VERSION_NAME = "0.1.0"
    $BUILD_NUMBER = "1"
}
Info "版本: $VERSION_NAME+$BUILD_NUMBER"

# ============ 步骤 3: Release 签名配置 ============
if ($BuildType -eq "release") {
    if (-not (Test-Path $KEYSTORE_PATH)) {
        Warn "未找到签名密钥,自动生成..."
        if (-not (Test-Path $KEYSTORE_DIR)) {
            New-Item -ItemType Directory -Path $KEYSTORE_DIR -Force | Out-Null
        }

        # 检查 keytool
        $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
        if (-not $keytoolCmd) {
            $javaHome = $env:JAVA_HOME
            if ($javaHome) {
                $keytoolExe = Join-Path $javaHome "bin\keytool.exe"
                if (Test-Path $keytoolExe) {
                    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
                }
            }
        }

        $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
        if (-not $keytoolCmd) {
            $msg = @"
keytool 未找到(在 JAVA_HOME 或 PATH 中)。请安装 JDK 17:
  1. 下载 Temurin 17: https://adoptium.net/temurin/releases/?version=17
  2. 安装到默认路径
  3. 设置系统环境变量 JAVA_HOME = C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot
  4. 重启 PowerShell

或者一键安装:
  winget install --id EclipseAdoptium.Temurin.17.JDK -e
"@
            Write-Host $msg -ForegroundColor Yellow
            exit 1
        }

        & keytool -genkey -v `
            -keystore $KEYSTORE_PATH `
            -keyalg RSA -keysize 2048 `
            -validity 10000 `
            -alias $KEY_ALIAS `
            -storepass $KEYSTORE_PASS `
            -keypass $KEY_PASS `
            -dname "CN=ToolBox, OU=Mobile, O=ToolBox, L=Shenzhen, S=Guangdong, C=CN" 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) { Error "密钥生成失败" }
        Success "已生成签名密钥: $KEYSTORE_PATH"
    } else {
        Success "使用现有签名密钥: $KEYSTORE_PATH"
    }

    # 写入 key.properties
    $keyPropsPath = "android\key.properties"
    @"
storePassword=$KEYSTORE_PASS
keyPassword=$KEY_PASS
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
"@ | Set-Content -Path $keyPropsPath -Encoding UTF8
    Success "已写入 $keyPropsPath"

    # 修改 build.gradle.kts 启用签名(仅首次)
    $gradleFile = "android\app\build.gradle.kts"
    $gradleContent = Get-Content $gradleFile -Raw
    if (-not $gradleContent.Contains("key.properties")) {
        Info "配置 Gradle 签名..."

        # 替换默认 debug 签名为 release
        $gradleContent = $gradleContent -replace 'signingConfig = signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")'

        $signatureBlock = @"


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
}
"@

        Set-Content -Path $gradleFile -Value ($gradleContent + $signatureBlock) -Encoding UTF8
        Success "Gradle 签名已配置"
    } else {
        Success "Gradle 签名已存在"
    }
}

# ============ 步骤 4: 清理 + 构建 ============
Info "清理旧的构建产物..."
& flutter clean | Out-Null
& flutter pub get | Out-Null

Info "开始构建(首次可能需要 5-10 分钟下载依赖)..."
switch ($BuildMode) {
    "apk" {
        & flutter build apk --$BuildType `
            --build-name=$VERSION_NAME `
            --build-number=$BUILD_NUMBER `
            --dart-define=APP_VERSION=$VERSION_NAME `
            --dart-define=BUILD_NUMBER=$BUILD_NUMBER
        if ($LASTEXITCODE -ne 0) { Error "APK 构建失败" }
        Success "APK 构建完成"
    }
    "aab" {
        & flutter build appbundle --$BuildType `
            --build-name=$VERSION_NAME `
            --build-number=$BUILD_NUMBER `
            --dart-define=APP_VERSION=$VERSION_NAME `
            --dart-define=BUILD_NUMBER=$BUILD_NUMBER
        if ($LASTEXITCODE -ne 0) { Error "AAB 构建失败" }
        Success "AAB 构建完成"
    }
    "both" {
        & flutter build apk --$BuildType
        if ($LASTEXITCODE -ne 0) { Error "APK 构建失败" }
        & flutter build appbundle --$BuildType
        if ($LASTEXITCODE -ne 0) { Error "AAB 构建失败" }
        Success "APK + AAB 均已生成"
    }
}

# ============ 步骤 5: 包体积分析 ============
Info "包体积分析..."
$apkPath = "build\app\outputs\flutter-apk\app-$BuildType.apk"
$aabPath = "build\app\outputs\bundle\$BuildType\app-$BuildType.aab"

if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length
    $apkSizeStr = "{0:N2} MB" -f ($apkSize / 1MB)
    Success "APK 大小: $apkSizeStr"
}
if (Test-Path $aabPath) {
    $aabSize = (Get-Item $aabPath).Length
    $aabSizeStr = "{0:N2} MB" -f ($aabSize / 1MB)
    Success "AAB 大小: $aabSizeStr"
}

# ============ 步骤 6: 复制到 dist/ 目录(便于查找) ============
$distDir = "dist\android"
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir -Force | Out-Null }

if (Test-Path $apkPath) {
    $distApk = Join-Path $distDir "toolbox-$VERSION_NAME.apk"
    Copy-Item $apkPath $distApk -Force
    Success "已复制到: $distApk"
}
if (Test-Path $aabPath) {
    $distAab = Join-Path $distDir "toolbox-$VERSION_NAME.aab"
    Copy-Item $aabPath $distAab -Force
    Success "已复制到: $distAab"
}

# ============ 步骤 7: 输出汇总 ============
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  📦 构建完成" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "App 名称:    $APP_NAME"
Write-Host "版本:        $VERSION_NAME+$BUILD_NUMBER"
Write-Host "包名:        $PACKAGE_ID"
Write-Host "签名:        $(if ($BuildType -eq 'release') { '已签名' } else { 'Debug' })"
Write-Host ""
Write-Host "输出文件:"
if (Test-Path $apkPath) {
    Write-Host "  APK: " -NoNewline
    Write-Host "$((Resolve-Path $apkPath).Path)" -ForegroundColor Yellow
}
if (Test-Path $aabPath) {
    Write-Host "  AAB: " -NoNewline
    Write-Host "$((Resolve-Path $aabPath).Path)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 安装到真机(USB 连接后):"
Write-Host "     adb install " -NoNewline
Write-Host $apkPath -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. 上传到 Google Play(需 $25 开发者账号):"
if (Test-Path $aabPath) {
    Write-Host "     Google Play Console → 内部测试 → 上传 " -NoNewline
    Write-Host $aabPath -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  3. 内测分发(推荐):"
Write-Host "     Firebase App Distribution / 蒲公英 / fir.im"
Write-Host "================================================" -ForegroundColor Cyan
