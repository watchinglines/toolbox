# 一键安装脚本 - Windows PowerShell 管理员模式
# 用法:右键 PowerShell → 以管理员身份运行 → 执行此脚本
# 安装: Flutter 3.24.5 + JDK 17 + Android Studio(含 SDK + NDK 25.x)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

# 颜色
function Info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red; exit 1 }

# 检查管理员权限
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "请右键 PowerShell → 以管理员身份运行"
}

# 检查 winget
Info "检查 winget..."
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCmd) {
    Warn "winget 未安装。请先安装 App Installer(从 Microsoft Store)"
    Warn "或手动安装: https://aka.ms/getwinget"
    $useWinget = $false
} else {
    $useWinget = $true
    Success "winget 已就绪"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ToolBox 环境一键安装" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "将安装以下组件:" -ForegroundColor White
Write-Host "  1. Flutter SDK 3.24.5 (stable) - ~1.2GB"
Write-Host "  2. Temurin JDK 17 - ~200MB"
Write-Host "  3. Android Studio (含 SDK + NDK) - ~2GB"
Write-Host ""
$choice = Read-Host "是否继续? [y/N]"
if ($choice -ne "y" -and $choice -ne "Y") {
    Write-Host "已取消" -ForegroundColor Yellow
    exit 0
}

if ($useWinget) {
    # 1. Flutter
    Info "正在安装 Flutter SDK 3.24.5 (此步骤约 3-5 分钟)..."
    winget install --id Google.Flutter -e --source winget --accept-package-agreements --accept-source-agreements
    Success "Flutter 已安装"

    # 2. JDK
    Info "正在安装 Temurin JDK 17 (此步骤约 1-2 分钟)..."
    winget install --id EclipseAdoptium.Temurin.17.JDK -e --source winget --accept-package-agreements --accept-source-agreements
    Success "JDK 17 已安装"

    # 3. Android Studio
    Info "正在安装 Android Studio (此步骤约 5-10 分钟)..."
    winget install --id Google.AndroidStudio -e --source winget --accept-package-agreements --accept-source-agreements
    Success "Android Studio 已安装"
} else {
    # 手动下载提示
    Write-Host ""
    Write-Host "winget 不可用,请手动下载:" -ForegroundColor Yellow
    Write-Host "  1. Flutter: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor White
    Write-Host "  2. JDK 17:   https://adoptium.net/temurin/releases/?version=17" -ForegroundColor White
    Write-Host "  3. Android Studio: https://developer.android.com/studio" -ForegroundColor White
    Write-Host ""
    Write-Host "下载后请按 WINDOWS_SETUP_GUIDE.md 完成配置" -ForegroundColor Cyan
    exit 0
}

# 设置环境变量
Info "配置环境变量..."
$flutterBin = "C:\src\flutter\bin"
if (Test-Path $flutterBin) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterBin", "User")
        Success "已添加 $flutterBin 到用户 PATH"
    } else {
        Success "PATH 已包含 $flutterBin"
    }
    $env:Path = "$flutterBin;$env:Path"
}

# 设置 PUB 国内镜像(加速)
[Environment]::SetEnvironmentVariable("PUB_HOSTED_URL", "https://pub.flutter-io.cn", "User")
[Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", "https://storage.flutter-io.cn", "User")
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
Success "已配置 Flutter 国内镜像"

# 验证 Flutter
Info "验证 Flutter 安装..."
$env:Path = "$flutterBin;$env:Path"
$flutterVer = & "$flutterBin\flutter.exe" --version 2>&1 | Select-Object -First 1
if ($flutterVer) {
    Success "Flutter: $flutterVer"
} else {
    Error "Flutter 验证失败,请重启 PowerShell"
}

# 接受 Android 许可
Info "接受 Android SDK 许可..."
& "$flutterBin\flutter.exe" doctor --android-licenses 2>&1 | Out-Null

# 完成
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ✅ 安装完成" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor White
Write-Host "  1. 重启 PowerShell 使环境变量生效" -ForegroundColor White
Write-Host "  2. 进入项目目录:" -ForegroundColor White
Write-Host "     cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner" -ForegroundColor Yellow
Write-Host "  3. 构建 APK:" -ForegroundColor White
Write-Host "     powershell -ExecutionPolicy Bypass -File scripts\build_android.ps1 release apk" -ForegroundColor Yellow
Write-Host ""
Write-Host "注意: 首次构建会下载 Gradle + 依赖,需要 5-15 分钟" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
