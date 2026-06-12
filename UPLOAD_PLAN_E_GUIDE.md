# 🌐 方案 E:网页上传 5 步拿 APK(零命令行、零网络风险)

适用:沙箱内无法 push 到 GitHub / 公司网络限制 / 没有 Git 基础。

---

## 步骤 1:打开你的 GitHub 仓库(30 秒)

浏览器打开:
```
https://github.com/watchinglines/toolbox
```

**会看到两种情况**:

### 情况 A:空仓库(显示上传引导) ✅ 推荐走这条
```
Quick setup — if you've done this kind of thing before
Get started by creating a new file or uploading an existing file.
```

### 情况 B:已经有内容(你之前 push 成功了) ✅ 直接跳到步骤 4
如果有 README 显示,说明你之前已经 push 了部分内容,可以**清空重传**或**保留合并**。

---

## 步骤 2:分批上传 56 个文件(5-8 分钟)

### 2.1 启动上传
- 在仓库主页点击 **「uploading an existing file」** 链接
- 或点 **「Add file」→「Upload files」**

### 2.2 打开文件选择对话框
- **方法 1(推荐)**:把 `C:\Users\JACK\WorkBuddy\2026-06-12-15-22-20\toolbox_scanner\` 整个文件夹拖到上传区
  - ⚠️ GitHub 网页单次最多 100 个文件,需要分批
- **方法 2**:在网页文件选择器中按文件夹路径全选

### 2.3 分批策略(避免超时)

| 批次 | 包含内容 | 文件数 |
|------|---------|--------|
| 第 1 批 | `.github/`(workflow 配置,优先) | 2 |
| 第 2 批 | `lib/` 整个目录(核心代码) | 17 |
| 第 3 批 | `android/` + `ios/`(原生平台) | 8 |
| 第 4 批 | `test/` + `scripts/`(测试和脚本) | 8 |
| 第 5 批 | 根目录 `*.md` + `*.yaml` + `pubspec.yaml` | 8 |
| 第 6 批 | `web/` + 其他零散文件 | 13 |

**每批上传后等页面刷新,再传下一批**。

### 2.4 关键文件优先级(如果中途卡住只传这些也能跑)

**最少必要集**(~10 个文件,保证云构建能跑):
```
.github/workflows/build-apk.yml
.github/workflows/build-all.yml
pubspec.yaml
lib/main.dart
lib/app/app.dart
lib/app/di.dart
android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/toolbox/scanner/MainActivity.kt
.gitignore
```

其他文件可以陆续补传,workflow 失败时再补。

---

## 步骤 3:Commit 推送(30 秒)

上传完每批文件后:
1. 滚到页面底部 "Commit changes" 区
2. 消息填:`Initial commit: ToolBox scanner`(或任意)
3. 选 **「Commit directly to the main branch」**
4. 点 **「Commit changes」** 绿色按钮

**重复此流程直到所有文件上传完**。

---

## 步骤 4:触发云构建(30 秒)

推送完成后,GitHub Actions 会**自动开始构建**。

### 4.1 检查 Actions 是否在跑
打开:
```
https://github.com/watchinglines/toolbox/actions
```

**看到黄色 🟡 = 正在跑**(预计 5-8 分钟)
**看到绿色 ✅ = 成功** → 直接跳到步骤 5
**看到红色 ❌ = 失败** → 把日志发我诊断

### 4.2 手动触发(如果没自动跑)
- 左侧列表找到 "Build Android APK"
- 点 "Run workflow" 按钮
- 选 main 分支
- 点绿色 "Run workflow" 按钮

---

## 步骤 5:下载 APK(1 分钟)

### 5.1 进入 workflow 详情页
- 点击刚跑完的 build 任务(绿色 ✓ 那一行)
- 任务标题类似 "Build Android APK #1"

### 5.2 找到 Artifacts
- 滚到页面**最底部**
- 看到 **"Artifacts"** 区域
- 有一个叫 **`toolbox-release-apk`** 的 zip 文件

### 5.3 下载
- 点击 `toolbox-release-apk.zip`
- 浏览器自动下载(约 25MB)
- **注意保留时间:90 天**,过期需重新构建

### 5.4 解压
- 右键 → 解压到当前文件夹
- 得到 `app-release.apk`(25-30MB)

---

## 步骤 6:装到手机(30 秒)

### 方案 1:USB 调试(最快)
```bash
# 1. 手机开发者模式 → 打开 USB 调试
# 2. USB 连接电脑
# 3. 执行:
adb install app-release.apk
```

### 方案 2:无线 ADB(无数据线)
```bash
# 手机和电脑同一 Wi-Fi
# 手机开发者模式 → 无线调试 → 记下 IP:端口
adb pair 192.168.x.x:xxxxx     # 输入配对码
adb connect 192.168.x.x:xxxxx  # 连接
adb install app-release.apk
```

### 方案 3:直接手机装(零电脑操作)
1. 把 `app-release.apk` 拷到手机(微信文件传输/网盘/邮件)
2. 手机文件管理器找到 `app-release.apk`
3. 点击 → 允许"安装未知来源" → 安装
4. 桌面上出现 "ToolBox Scanner" 图标

### 首次启动需要
- 允许相机权限
- 允许存储权限
- 首次 ML Kit 模型下载(约 5MB,Wi-Fi 优先)

---

## 🆘 故障排查

### Q1:上传卡住不动
**原因**:网络不稳或单次文件过多
**解决**:
- 减少每批文件数到 20 个以内
- 切换网络(手机热点试试)
- 刷新页面重新上传

### Q2:显示 "Yowza, that's a lot of files"
**原因**:单次超过 100 个文件
**解决**:分批上传(按上面的 6 批策略)

### Q3:workflow 报 "pubspec.yaml not found"
**原因**:根目录文件没上传
**解决**:确认 `pubspec.yaml` 在仓库根目录(不在子文件夹)

### Q4:构建报 "SDK location not found"
**原因**:`local.properties` 没生成
**解决**:GitHub Actions 会自动处理,正常不需要管

### Q5:构建报 "Gradle daemon disappeared"
**原因**:runner 内存不够
**解决**:重试一次,或用 `build-all.yml` workflow

### Q6:APK 装到手机提示"未安装"
**原因**:签名不一致 / 旧版本残留
**解决**:
```bash
adb uninstall com.toolbox.scanner  # 先卸载
adb install app-release.apk        # 再装
```

### Q7:启动后相机黑屏
**原因**:没给相机权限
**解决**:设置 → 应用 → ToolBox Scanner → 权限 → 相机 → 允许

---

## ⏱️ 完整时间预估

| 阶段 | 耗时 |
|------|------|
| 步骤 1:打开仓库 | 30 秒 |
| 步骤 2:分批上传文件 | 5-8 分钟 |
| 步骤 3:Commit | 30 秒 |
| 步骤 4:触发云构建 | 30 秒 |
| 步骤 5:等构建+下载 | 6-10 分钟 |
| 步骤 6:装到手机 | 30 秒 |
| **合计** | **13-20 分钟** |

---

## 📋 你操作时发给我的格式

每完成一步,告诉我:

- **"上传到第 3 批了"** → 我确认进度
- **"workflow 跑成功了,绿勾"** → 指引下载
- **"红叉了,日志: [贴报错]"** → 我诊断修复
- **"APK 装到手机了"** → 🎉 任务完成!

---

## 🎁 备选:让 GitHub CLI 帮你搞定(如果你装了)

如果你之前安装过 GitHub CLI:
```bash
cd C:\Users\\JACK\\WorkBuddy\\2026-06-12-15-22-20\\toolbox_scanner
gh repo create watchinglines/toolbox --public --source=. --push
```

一行命令搞定推送。但鉴于你之前 push 失败,推荐走纯网页路径。
