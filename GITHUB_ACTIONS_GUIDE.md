# GitHub Actions 云构建 - 5 分钟拿 APK

## 什么是云构建?

不安装任何 SDK,把代码推到 GitHub,GitHub 服务器(免费)帮你编译 Flutter 项目,
最后下载编译好的 APK 装到手机。**全程在你的浏览器里完成,不需要命令行**。

## 🎯 完整流程(预计 5-10 分钟)

### 步骤 1:注册 GitHub(1 分钟)

1. 打开 https://github.com/signup
2. 填写邮箱 / 密码 / 用户名
3. 验证邮箱
4. 选择 Free 计划(免费)

### 步骤 2:推送代码到 GitHub(2 分钟)

#### 方式 A:网页上传(最简单,无需 Git 知识)

1. 登录 GitHub → 点击右上角 **+** → **New repository**
2. 仓库名:`toolbox`
3. 选择 **Public**(公开,免费,Actions 无限时长)
4. **不要**勾选 "Add a README file"
5. 点击 **Create repository**
6. 在新页面找到 **uploading an existing file** 链接
7. 拖入整个 `toolbox_scanner/` 文件夹的所有文件
8. 等待上传完成(共 47 个文件)
9. 点击 **Commit changes**

#### 方式 B:Git 命令行(有 Git 基础)

```bash
cd C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner
git init
git add .
git config user.email "your@email.com"
git config user.name "Your Name"
git commit -m "ToolBox scanner initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/toolbox.git
git push -u origin main
```

### 步骤 3:等待自动构建(5-8 分钟)

1. 进入你的 GitHub 仓库页面
2. 点击顶部的 **Actions** 标签
3. 你会看到 "Build Android APK" 正在运行(橙色圆圈)
4. 点击进入查看详细日志
5. 等待 5-8 分钟,出现绿色 ✓ 表示成功
6. **失败?** 展开红色 ❌ 步骤,查看错误日志

### 步骤 4:下载 APK(1 分钟)

1. 在 workflow run 页面,滚到最底部
2. 找到 **Artifacts** 区
3. 点击 `toolbox-release-apk` 下载 zip
4. 解压得到:
   - `toolbox-0.1.0.apk` (~25MB,直接安装)
   - `toolbox-0.1.0.aab` (~20MB,Google Play)

### 步骤 5:装到手机(30 秒)

#### 方式 A:USB + ADB(推荐)

```bash
# USB 连接 Android 手机(开启 USB 调试)
adb devices   # 应显示 device

# 安装
adb install toolbox-0.1.0.apk

# 启动
adb shell am start -n com.toolbox.scanner/.MainActivity
```

#### 方式 B:无线传文件

1. 把 `toolbox-0.1.0.apk` 复制到手机(微信文件传输 / 邮件 / 百度网盘)
2. 在手机文件管理器中找到该 APK
3. 点击安装(首次需允许"未知来源")
4. 完成

## 🔍 故障排查

### Q1: workflow 报 "Gradle not found"
**解决**: 检查 `.github/workflows/build-apk.yml` 第 36-40 行,确保 java-version 是 17。

### Q2: workflow 报 "NDK not configured"
**解决**: 在仓库 Settings → Secrets → 添加 `KEYSTORE_PASSWORD` 和 `KEY_PASSWORD`。
或在 build.gradle.kts 中暂时移除 externalNativeBuild。

### Q3: workflow 报 "flutter pub get failed"
**解决**: 仓库根目录的 `pubspec.yaml` 可能格式错误,本地先 `flutter pub get` 验证。

### Q4: 下载的 APK 安装时 "解析包出现问题"
**原因**: 可能是签名不匹配(不同设备上装过 Debug 版)
**解决**: 卸载旧版:`adb uninstall com.toolbox.scanner`,再装新版本。

### Q5: Actions 标签页看不到 workflow
**解决**: 检查 `.github/workflows/build-apk.yml` 是否在 `main` 分支(默认分支),或者手动触发:
- Actions → 左侧选择 "Build Android APK" → Run workflow

## 💡 进阶:配置自定义签名(可选)

默认 workflow 会自动生成一个测试签名。如果你想用真实签名:

1. 本地用 keytool 生成密钥:
   ```bash
   keytool -genkey -v \
     -keystore upload.jks \
     -keyalg RSA -keysize 2048 \
     -validity 10000 \
     -alias upload \
     -storepass YOUR_PASSWORD \
     -keypass YOUR_PASSWORD \
     -dname "CN=ToolBox,O=YourName"
   ```

2. Base64 编码后存到 GitHub Secrets:
   ```bash
   # Linux/Mac
   base64 -w 0 upload.jks > keystore-base64.txt
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload.jks"))
   ```

3. GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret:
   - `KEYSTORE_BASE64`: 上面生成的 base64
   - `KEYSTORE_PASSWORD`: 你的密码
   - `KEY_PASSWORD`: 你的密码
   - `KEY_ALIAS`: `upload`

4. 修改 `.github/workflows/build-apk.yml`,在签名步骤前添加:
   ```yaml
   - name: Decode keystore
     run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload.jks
   ```

## 🔄 持续集成(每次 push 自动构建)

推送代码后,GitHub Actions 会自动:
1. 检出代码
2. 安装 JDK 17 + Flutter 3.24.5
3. 拉取依赖
4. 运行测试
5. 构建 APK + AAB
6. 上传为 artifact(可下载)

**APK artifact 保留 90 天**(可在 workflow 中修改 retention-days)。

## 🌟 进阶玩法

### 触发自动发布

```yaml
# 在 workflow 末尾加
- name: Create GitHub Release
  if: startsWith(github.ref, 'refs/tags/v')
  uses: softprops/action-gh-release@v2
  with:
    files: dist/*.apk
    generate_release_notes: true
```

然后:
```bash
git tag v0.1.0
git push origin v0.1.0
# 自动在 GitHub Releases 页面生成可下载的 APK
```

### 定时构建(检查 Flutter 升级)

```yaml
on:
  schedule:
    - cron: '0 0 * * 1'  # 每周一 0 点
```

## 📊 资源消耗(免费额度内)

GitHub Actions 免费额度(每月):
- Linux runner:**2000 分钟**
- macOS runner:**200 分钟**
- Windows runner:**200 分钟**

我们每次构建用 ~6 分钟 Linux runner,**每月可免费构建 300+ 次**。

## ⏱️ 时间线

| 步骤 | 耗时 | 难度 |
|------|------|------|
| 1. 注册 GitHub | 1 分钟 | ⭐ |
| 2. 推送代码 | 2 分钟 | ⭐⭐ |
| 3. 等待构建 | 5-8 分钟 | ⏳ |
| 4. 下载 APK | 1 分钟 | ⭐ |
| 5. 装到手机 | 30 秒 | ⭐ |
| **合计** | **~12 分钟** | ⭐⭐ |

---

📌 **下一步**:按上述 5 步操作,5-12 分钟内你就能把 ToolBox 装到手机上!
