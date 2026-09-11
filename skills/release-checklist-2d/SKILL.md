---
name: release-checklist-2d
description: Use when user is about to release/build a 2D Godot game, or says 「导出」 / 「打包」 / 「release version」. 平台特定清单(Windows/Mac/Linux/Web/Android)、版本号、changelog、build 产物、发布后冒烟测试。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [windows | mac | linux | web | android | full] -->

# 发布清单 2D (Godot)

> 2D Godot 游戏发布前全流程清单。
> 产出:可分发的 build 产物 + 版本号 + changelog。

## 0. 路由(单题)

| 选项 | 走法 |
|------|------|
| A. 仅 Windows | 1-6 |
| B. Mac | 1-6 + Mac 签名 (7) |
| C. Linux | 1-6 |
| D. Web (itch.io) | 1-6 + Web 导出 (8) |
| E. Android | 1-6 + Android APK (9) |
| F. 全平台 | 1-9 |

## 0.5. Godot API claims 审计(必做,在 bump 之前)

先跑文档对齐校验,任何 FAIL 阻塞发布:

```powershell
.\scripts\verify-godot-claims.ps1 -Strict
```

输出到 `build/audit/godot-claims-<date>.md`。若出现 FAIL,**先**改对应 SKILL.md(本套件),然后重跑。

**新增 fact**:在 `scripts/verify-godot-claims.ps1` 的 `$facts` 数组里追加条目。每个条目需要 id、断言所在 skill 文件、claim、文档 URL、能证明 claim 的 regex。

## 1. 版本号(必做)

> **Skill 时效性**:任何 `godot-*` 知识类技能,如果 frontmatter 里的 `last_reviewed` 超过 90 天,本次发布前必须重新 review。用 `grep -l "last_reviewed" skills/godot-*/SKILL.md` 枚举。

用 SemVer vX.Y.Z:

- X = major(玩法 / 引擎大改)
- Y = minor(新机制 / 新关卡)
- Z = patch(bug 修复 / 平衡)

修改:
- project.godot:config/version = "X.Y.Z"
- README.md:版本号 badge

## 2. Changelog(必做,用户可见)

写到 CHANGELOG.md:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- 新功能 1
- 新功能 2

### Changed
- 行为变更 1

### Fixed
- bug 修复 1

### Removed
- 移除功能(若有)
```

## 3. 导出预设(必做)

导出预设保存在项目根的**独立文件** `export_presets.cfg`(与 `project.godot` 同级,不要合并进 project.godot)。在编辑器 Project → Export 里配置后保存即可生成该文件。

### 3.1 Windows Desktop

- Name: Windows Desktop
- Platform: Windows
- Format: Game.exe(含 PCK)
- Include PDB: false(发布版)
- Encryption: off(影响加载)

### 3.2 Web

- Name: Web
- Format: index.html + index.pck + index.wasm
- 禁用物理多线程:physics/2d/run_on_thread = false(Web 兼容)
- 优化:html/canvas_resize_policy = 1

### 3.3 Android

- Package: com.yourstudio.yourgame
- Min SDK: 24(Android 7.0)
- Target SDK: 34
- 签名:debug keystore(测试)/ release keystore(发布)

## 4. 构建(必做)

跑 scripts/export-build.ps1 <platform>,生成:

```
build/
  windows/yourgame-v1.0.0.exe
  windows/yourgame-v1.0.0.pck
  web/index.html
  web/index.pck
  web/index.wasm
```

## 5. 构建后冒烟(必做)

### Windows

```powershell
# 跑 60s, 无报错即通过
& "build/windows/yourgame.exe" --quit-after 60

# 检查无致命错误
Get-Content build/windows/console.log
```

### Web

```powershell
# 启动本地 HTTP server
cd build/web && python -m http.server 8080

# 在浏览器打开 http://localhost:8080, 手动验证
```

### Android

- adb install build/android/yourgame.apk
- 在真机跑 + 玩 5 分钟
- 验证输入、音频、性能

## 6. 资产 + 许可(必做)

- [ ] 所有资产都有 ATTRIBUTION (assets/ATTRIBUTION.md)
- [ ] 第三方库许可文本已收录 (THIRD_PARTY_LICENSES.md)
- [ ] 字体 / 音乐 / 美术许可覆盖分发范围

## 7. Mac 签名(仅 Mac)

- [ ] Apple Developer 证书
- [ ] codesign --deep --force --options=runtime --sign "Developer ID Application: ..." yourgame.app
- [ ] xcrun notarytool submit yourgame.zip --keychain-profile <profile>
- [ ] 公证完成(staple ticket)

## 8. Web 特定(仅 Web)

- [ ] physics/2d/run_on_thread = false
- [ ] 音频用 AudioStreamPlayer(不是 3D 定位的 AudioStreamPlayer2D)
- [ ] 输入支持触屏 (InputEventScreenTouch) 若需要
- [ ] 上传 itch.io:把整个 web/ 目录打 zip

## 9. Android 特定(仅 Android)

- [ ] editor/export/android keystore 已设置
- [ ] use_apk_expansion = false(除非需要 OBB)
- [ ] 权限最小化(需要联网时才加 INTERNET)
- [ ] 多分辨率支持:stretch/mode = "canvas_items", stretch/aspect = "expand"
- [ ] 后台暂停:Main Loop Type = Standard

## 10. 性能基线对比(推荐)

发布前跑一次,记录:

```
- 启动时间: <X>s
- 主场景 FPS: <X>
- 内存峰值: <X>MB
- 包大小: <X>MB
```

对比上一版本,无回退即通过。

## 11. Git Tag(必做)

```powershell
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## 12. 分发

| 平台 | 渠道 |
|------|------|
| Windows | itch.io / Steam / 自托管 |
| Mac | Steam / Mac App Store |
| Linux | Steam / itch.io / 自托管 |
| Web | itch.io (HTML5) |
| Android | Google Play |

## 13. 反模式(发布前禁止)

- 含调试 print()
- 含 dev-branch TODO
- 含未压缩的开发资产(大文件)
- 含测试场景 (tests/)
- 含 .godot/ 缓存
- 版本号未 bump
- 缺少 changelog
- 发布前没跑冒烟

## 14. 后续

- 发布后:监控反馈,准备 hotfix(Z 版本)
- Steam 集成:独立 skill/wiki(超出本套件范围)

## 附录 — 常用命令

```powershell
# 导出
godot --headless --export-release "Windows Desktop" build/windows/yourgame.exe

# 跑构建产物
& "build/windows/yourgame.exe"

# 查看 console.log
# Windows: 在游戏目录创建 console.log, 游戏会写进去

# 上传 itch.io (用 butler CLI)
butler push build/windows yourname/yourgame:windows --userversion 1.0.0
```
