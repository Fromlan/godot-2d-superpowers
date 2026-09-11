---
name: asset-pipeline
description: "在 2D Godot 项目中添加或修改美术/音频/动画/字体资源时使用,或当用户说"加图片"/"换音乐"/"做动画"/"换字体"。强制命名约定、导入设置、版本管理、依赖追踪。"
last_reviewed: 2026-09-10
---

<!-- argument-hint: [sprite | audio | animation | font | bundle] -->

# 资产管线 (2D Godot)

> 2D 游戏资产生命周期管理:命名、导入、版本、依赖、引用。
> 走完本技能,产出"命名规范、导入配置正确、依赖可追溯"的资源。

## 0. 何时用

- 加/换任何 `.png` / `.svg` / `.wav` / `.ogg` / `.mp3` / `.ttf` / `.otf` / `.json` (TileMap)
- 做 `AnimatedSprite2D` 帧序列 / `AnimationPlayer` 资源
- 改导入设置(过滤、压缩、mipmap、像素吸附)
- 删/移动资源

## 1. 目录结构(强制)

```
assets/
├── sprites/
│   ├── characters/
│   │   ├── player/
│   │   │   ├── player_idle.png
│   │   │   ├── player_run.png
│   │   │   └── player_jump.png
│   │   └── enemy_slime.png
│   ├── environment/
│   │   ├── tile_grass.png
│   │   └── tile_stone.png
│   └── ui/
│       ├── icon_heart.png
│       └── button_normal.png
├── sounds/
│   ├── sfx/
│   │   ├── jump.wav
│   │   └── hit.wav
│   └── bgm/
│       └── theme.ogg
├── fonts/
│   └── main.ttf
└── animations/
    └── player_idle.tres   # AnimationPlayer 资源
```

**规则**:
- `.png` / `.wav` / `.ttf` 永远在 `assets/` 下
- **不放在 `scenes/`**(场景只放 `.tscn`)
- 单一职责:一个资产一个文件,**不靠"图层"区分**

## 2. 命名规范(必须)

### 2.1 通用

格式: `<scope>_<subject>_<variant>.<ext>`

- `<scope>`: `player` / `enemy` / `ui` / `bgm` / `sfx` / `tile`
- `<subject>`: 描述性名称(`run` / `jump` / `hit` / `grass`)
- `<variant>`: 可选(`v1` / `big` / `small` / `frame_001`)

例:
- `player_idle.png` ✓
- `playerIdle.png` ✗ (camelCase, 改 snake_case)
- `Idle.png` ✗ (无 scope)
- `player-idle.png` ✗ (用下划线)
- `Player.png` ✗ (PascalCase 用于类)

### 2.2 动画帧

帧序列用 3 位零填充:
- `player_run_001.png`
- `player_run_002.png`
- ...
- `player_run_024.png`

Godot 的 `SpriteFrames` 资源会自动按字典序排,零填充保证顺序。

### 2.3 音频

- 短音效(`< 1s`): `.wav` (无压缩)
- 长音效 / BGM: `.ogg` (Vorbis)
- **不**用 `.mp3`(Godot 4.7 支持但延迟大)

## 3. 导入设置(必须显式配置)

> **2D 项目默认值**:`compress/mode = 0`(Lossless)。Godot 4 官方文档明确说明 `2=VRAM Compressed` 和 `4=Basis Universal` **仅用于 3D 场景,不用于 2D 元素**(VRAM 压缩会让 2D 像素艺术出现块状瑕疵,Basis Universal 对小尺寸 2D 资源体积反而不优)。3D 项目才需要在这几个 mode 之间权衡。


每个资源第一次导入后,Godot 生成 `.import` 文件。**必须**改对的设置:

### 3.1 像素艺术(`Filter = Off`)

```ini
[params]
compress/mode = 0   # Lossless(2D 默认;VRAM Compressed 仅用于 3D)
texture/filter = 0  # Nearest(像素艺术)
texture/mipmap = 0  # 关
```

**位置**: 选中图片 → Import Dock → preset "2D Pixel"

### 3.2 矢量图 / UI

```
compress/mode = 0   # Lossless(2D 通用);若需在线分发可改 4 Basis Universal
texture/filter = 1  # Linear
```

### 3.3 音频

- `.wav`: 不重压缩,保持 PCM
- `.ogg`: Vorbis @ 128kbps
- `.mp3`: 转 `.ogg` 后再导入(避免授权问题)

### 3.4 字体

- `.ttf` / `.otf`: 直接导入
- 抗锯齿: True(关掉会糊)
- 提示(Hinting): Light

## 4. 资源引用(必须用 `uid://`,Godot 4.4+)

- 代码里引用: 优先 `preload("uid://abc123...")` 或 Godot 自动生成的 `uid`
- `res://` 路径仍可,但**移动/重命名时 Godot 会自动更新 uid**
- 提交前: `godot --headless --quit` 跑一次,确保 uid 重新生成

## 5. 删除/移动资源(必须)

1. 在编辑器里**先**删引用(preload / .tscn 中的引用)
2. **再**删/移文件
3. **不要**用文件系统直接删(会让 .tscn 留下断引用)
4. 提交前 `godot --headless` 验证无缺失资源警告

## 6. 动画资源(`SpriteFrames` / `AnimationPlayer`)

### 6.1 `SpriteFrames`

- 每角色/敌人一份 `.tres`
- 命名: `assets/animations/<scope>_<subject>.tres`
- Animation 名: `idle` / `run` / `jump`(小写 snake_case)
- 帧率: 写 `@export var fps: int = 8` 让美术调

### 6.2 `AnimationPlayer`

- 复杂动画(非 SpriteFrames 切换)用 `AnimationPlayer`
- `.tres` 单独保存,不放 `res://` 根
- 引用: `$AnimationPlayer.queue("hit")`

## 7. 版本与外部工具

- **不**把 `.aseprite` / `.psd` / 源文件入 git
- 只入最终导出( `.png` / `.wav` )
- 源文件用 LFS 或单独 `assets-source/`(不进 git)
- `assets-source/` 加进 `.gitignore`

## 8. 版权与许可

每个资源文件加一行注释或 README:

```
# assets/sprites/player_idle.png
# Author: Kenney.nl
# License: CC0
# Source: https://kenney.nl/assets/...
```

或者在 `assets/ATTRIBUTION.md` 集中管理。

## 9. 性能检查(改后必跑)

- 总资源大小: `du -sh assets/`(或 PowerShell 等价)
- 启动时间: `scripts/headless-smoke.ps1`
- 内存: 编辑器 Performance Monitor

## 10. 反模式

- ❌ 文件名带空格 / 中文 / 大写
- ❌ 像素艺术开了 Linear Filter(糊)
- ❌ 在 `scenes/` 放图片
- ❌ `.mp3` 大量使用
- ❌ 资源引用写死绝对路径
- ❌ 不删断引用,留下空指针
- ❌ 没记来源/许可就上传

## 11. 衔接

- 加资源 → 写 `assets/ATTRIBUTION.md` 记录来源
- 性能问题 → `systematic-debugging-2d`
- 资源相关 bug(图片不显示 / 音效不响)→ `systematic-debugging-2d`
