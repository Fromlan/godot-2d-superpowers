---
name: godot-ui-best-practices
description: |
  Godot 4.7 UI/HUD:Control、CanvasLayer、mouse_filter、Theme、Container 布局、锚点、点击链。Use when 提到"UI"、"HUD"、"Control"、"CanvasLayer"、"godot 拖拽"、"按钮没响应"、"HUD 适配视口"。Do NOT use for 纯 GDScript 逻辑或非 Godot 引擎。Read-only knowledge。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [rule number or symptom, e.g. '3', 'mouse_filter', '拖 不触发'] -->

# Godot UI 最佳实践 (4.7)

构建 Godot 4 Control / HUD UI 的实操规则。每条规则说明失败模式、修复、一句话代码片段。深入阅读见 `references/<topic>.md`。

## 1. Container 驱动布局,不用手写 `position`

每个布局问题都源于同一个错:在 `Container` 里给子节点手写 `position`。Container 是引擎;让它工作。

| 坏 | 好 |
|----|------|
| 5 个子节点在 node 里 `position = Vector2(0, 60 * i)` | `VBoxContainer` + `theme_override_constants/separation = 8` |
| 3 个子节点在 `Node2D` 里手写 x/y | `HBoxContainer`(或 `GridContainer` 用于固定列) |
| 4 角 popup 手摆 | `MarginContainer` + `VBoxContainer` 嵌套 |

Container 类型与何时用:

- `VBoxContainer` / `HBoxContainer` — 垂直 / 水平流
- `GridContainer` — 固定 N×M 网格
- `MarginContainer` — 父节点内部统一 padding
- `CenterContainer` — 单子节点居中
- `PanelContainer` — 自适应子节点 + `content_margin_*`(见规则 9)
- `ScrollContainer` — 自滚动区

**为什么**:手写 `position` 在换字体、加子节点或调窗口大小时立刻坏。Container 自动重排。

## 2. `size_flags_*` 控制子节点 fill/shrink 行为

`Container` 排子节点;每个子节点的 `size_flags_*` 告诉它怎么排。默认值对 HUD bar、header、动态内容是错的。

```gdscript
# Expand fill horizontal + shrink end vertical — header bar pattern
header.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 3
header.size_flags_vertical   = Control.SIZE_SHRINK_END   # 8
```

官方 SizeFlags 枚举([Control](https://docs.godotengine.org/en/stable/classes/class_control.html#enum-control-sizeflags)):

| 常量 | 值 | 含义 |
|------|-----|------|
| `SIZE_SHRINK_BEGIN` | 0 | 缩到内容大小、对齐起点(等同无 flag) |
| `SIZE_FILL` | 1 | 填满可用空间(属性默认) |
| `SIZE_EXPAND` | 2 | 请求父 Container 扩槽 |
| `SIZE_EXPAND_FILL` | 3 | EXPAND + FILL |
| `SIZE_SHRINK_CENTER` | 4 | 缩到内容、居中 |
| `SIZE_SHRINK_END` | 8 | 缩到内容、对齐终点 |

`EXPAND` + `FILL` 是常见的「可拉伸」组合。

**陷阱**:`PanelContainer` 套 `VBoxContainer` 子。如果内层 `VBoxContainer` 默认 `size_flags_vertical = SIZE_FILL`(1),它要填满父。`PanelContainer` 就扩展适配 `VBoxContainer`。结果:panel 长过 `offset_bottom`,溢进相邻 UI。**修复**:内层 `VBoxContainer.size_flags_vertical = 0`(SHRINK_END)让 panel 用 its offset rect。

## 3. `mouse_filter` 是「点击不触发」的头号原因

每个 `Control` 有 `mouse_filter`:

- `STOP = 0`(默认)— 吃掉事件,不传给兄弟或 `_unhandled_input`
- `PASS = 1` — 看到事件,传给兄弟 + `_unhandled_input`
- `IGNORE = 2` — 对鼠标不可见,事件完全穿过

**默认 STOP** 意味着游戏物体旁边的装饰性 `Label` 会在 `_unhandled_input` 收到事件前静默吃掉点击。这是「拖拽不工作」最常见的原因。

```gdscript
# 装饰性 Control 必须显式设 IGNORE, 否则吞掉点击
label.mouse_filter   = Control.MOUSE_FILTER_IGNORE   # 2
hp_bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE   # 2

# 真正要点击的 Button 保持 STOP
button.mouse_filter  = Control.MOUSE_FILTER_STOP     # 0
```

**诊断**:在 `_unhandled_input` 第一行 `print(event.position, " ", event.pressed)`。如果没打印,某个 `Control` 在游戏物体上方吃掉了它。嫌疑节点设 `mouse_filter = 2`。

## 4. 点击事件链:`_input` → `_gui_input` → `_unhandled_input`

对 UI Button,**始终** 连 `Button.pressed` 信号。**不要**在 `_unhandled_input` 里轮询点击去驱动 button 动作。

```gdscript
# Right — 信号驱动式
shop_buy_btn.pressed.connect(_on_shop_buy)

# Wrong — 轮询 Button 点击
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if Rect2(shop_buy_btn.global_position, shop_buy_btn.size).has_point(event.position):
            _on_shop_buy()  # 重复 Button 自身逻辑, 输入设备一换就坏
```

`_unhandled_input` 仅用于游戏动作(不是按钮):拖拽、游戏命令热键、镜头平移等。即使如此,实际游戏对象的命中测试还是你来做 — `Container` 不帮忙。

## 5. `_input` vs `_unhandled_input` vs `_gui_input`

| Hook | 何时触发 | 用途 |
|------|---------|------|
| `_input` | 每个事件,GUI 处理前 | 输入录制 / 回放、调试覆盖 |
| `_gui_input` | 仅 GUI Control | Control 脚本内部 |
| `_unhandled_input` | GUI 未未处理的事件 | 游戏动作(不是 Button 点击) |

## 6. Tween 用于一次性视觉插值

对 UI / 镜头 / shader 脉冲用 `Tween` 而不是 `_process`:

```gdscript
var t := create_tween()
t.set_parallel(true)
t.tween_property(node, "modulate", Color.RED, 0.1)
t.tween_property(node, "scale", Vector2.ONE * 1.2, 0.1)
t.tween_interval(0.05)  # pause briefly
t.tween_property(node, "modulate", Color.WHITE, 0.2)
t.tween_callback(queue_free)
```

详见 `godot-animation` 技能。

## 7. Button 状态 + 主题

Button 有多个状态:normal、hover、pressed、disabled、focus。每个可以设不同 stylebox。

```gdscript
# Apply at runtime
var style := StyleBoxFlat.new()
style.bg_color = Color(0.2, 0.4, 0.8)
style.corner_radius_top_left = 8
style.corner_radius_top_right = 8
style.corner_radius_bottom_left = 8
style.corner_radius_bottom_right = 8
button.add_theme_stylebox_override("normal", style)
button.add_theme_stylebox_override("hover", hover_style)
button.add_theme_stylebox_override("pressed", pressed_style)

# Or use a Theme resource
$Root.theme = preload("res://theme.tres")
```

**不要**手动轮询 `button.is_pressed()` 然后再驱动状态。Button 自己处理所有状态。

## 8. CanvasLayer 用于 HUD

HUD 应该在 `CanvasLayer`(不参与世界变换),世界物体在 `Node2D`(参与变换):

```
Main (Node2D)
├── World (Node2D)            # 跟随镜头
│   ├── Player (CharacterBody2D)
│   └── Enemies (Node2D)
└── HUD (CanvasLayer)         # 屏幕固定
    ├── HP (ProgressBar)
    └── Score (Label)
```

CanvasLayer 让 HUD 不受相机移动 / 缩放影响。

## 9. PanelContainer + content_margin

`PanelContainer` 自动 sizing 到 child。用 `content_margin_*` 加 padding:

```gdscript
var style := StyleBoxFlat.new()
style.content_margin_left = 16
style.content_margin_right = 16
style.content_margin_top = 8
style.content_margin_bottom = 8
panel.add_theme_stylebox_override("panel", style)
```

## 10. viewport 大小 vs 设计大小

```ini
[display]
window/size/viewport_width=1152
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

**始终显式设**。否则 viewport 大小可能与你设计的不匹配;在某些 viewport 上 HUD 被切底,`get_viewport_rect().size` 返回实际大小而不是你的设计大小。

每次布局变化验证:在 `_ready()` 打印 `get_viewport_rect().size`。

## 11. Anchor + offset,不是绝对 position,用于 resize-friendly UI

要「贴」到边缘的顶层 HUD 节点:

- Top bar:`anchor_left=0, anchor_right=1, anchor_top=0, offset_right=0`(全宽,顶)
- Bottom bar:`anchor_left=0, anchor_right=1, anchor_bottom=1, offset_top=-X`(全宽,距底 X 像素)
- Side panel:`anchor_left=1, anchor_right=1, anchor_top=0, anchor_bottom=1`(右边缘,全高)

没有锚点,resize 后 panel 会留在屏幕中间。

对固定尺寸游戏窗口(如 1152×720 Steam 目标),锚点可选。对浏览器 / 移动 / 响应式,锚点必填。

## 12. 命中测试:`hit_radius` 应该比视觉大

你要点击的游戏对象(棋子、卡、单位)应暴露 `hit_radius` 大于可见精灵。9×9 棋盘 56px 格子 22×9 可见棋子 → `hit_radius=36` 舒适,`hit_radius=28` 太紧。

可见边界定义用户 *看到* 的;hit radius 定义用户 *能点* 的。不是同一个数。

## 13. 不要在 `Container` 里手摆 Label 位置

| 坏 | 好 |
|----|------|
| 5 个 `Label` 子节点 `position = Vector2(0, 32 * i)` | `VBoxContainer` 默认 separation |
| `Label` 挨着 `Button` 手 x 偏移 | `HBoxContainer` `add_child(label)` 后 `add_child(button)` |

`Container` 自动对齐、自适应字体大小、可主题化。手写位置是每个未来字体 / 主题变更的敌人。

## 14. Resource 主题化,不用 inline color

`Theme` 资源(`res://theme.tres`)是一个文件,给项目所有 `Button` / `Label` 设样式。每个按钮 inline `theme_override_colors/font_color = Color(...)` 是维护陷阱。

```gdscript
# 项目主题: 单一 .tres 文件含 stylebox、font、color
# 应用在项目根或场景根:
$Root.theme = preload("res://theme.tres")
```

一次性 override(如错误文本红),用 `theme_override_*` — 但保持最少。

## 15. `@export` 用于设计师可调,`@onready` 用于子节点缓存

```gdscript
@export_range(50.0, 800.0) var piece_drag_speed: float = 220.0
@export var piece_scene: PackedScene

@onready var board: Board = $Board
@onready var shop_panel: PanelContainer = $HUD/ShopPanel
```

`@onready var` 在 `_ready()` 解析所以 `$Path` 永远非 null。`@export` 暴露给 Inspector 设计师调不重编。

## 16. 四个最小诊断

UI 坏时按顺序:

1. 在 `_ready()` 打印 `get_viewport_rect().size` — 确认 viewport 大小匹配设计
2. 对每个重叠的 `Control` 打印 `node.global_position, node.size, node.mouse_filter` — 找到 click-eater
3. 在 `_unhandled_input` 第一行 `print(event.position, " ", event.pressed)` — 确认事件到达父节点
4. 打印 `piece.position, piece.hit_radius, "d=", mouse.distance_to(piece.position)` — 确认命中测试算式

这四次打印能解 90%「UI 不工作」调试。

## 常见 bug 模式

| 症状 | 根因 | 修复 |
|------|------|------|
| Button 点击无效 | `_input` 处理函数吃了它 | 用 `pressed` 信号(规则 4) |
| 拖拽在物体上可以但不在其 label 上 | Label `mouse_filter=STOP` | 设 `MOUSE_FILTER_IGNORE`(规则 3) |
| Panel 长过 `offset_bottom` | 内层 `VBox` 是 `SIZE_FILL` | 设 `size_flags_vertical = Control.SIZE_SHRINK_BEGIN` (0) 或 `SIZE_SHRINK_END` (8)(规则 2) |
| HUD 被切底 | viewport 小于设计 | stretch mode `expand` 或重设设计 |
| resize 后 Panel 位置错 | 用了绝对 `position`,不是锚点 | 用锚点(规则 11) |
| Tween 在场景切换时冻结 | autoload 管理的 tween;在 `queue_free` 前取消 | 在 `_exit_tree` `kill()`(规则 6) |
| HUD 后面的游戏对象点击不到 | HUD `Control` 在 `CanvasLayer` 顶层 | 检查 mouse层 / Z(规则 3 + 8) |

## 参考索引

深入阅读:

- `references/container-layout.md` — 完整 container / size_flags 参考与图示
- `references/mouse-and-click.md` — `_input` 链、拖拽模式、`mouse_filter` 深入
- `references/visual-feedback.md` — Tween 模式、modulate、自定义鼠标
- `references/responsive-layout.md` — 锚点、stretch 模式、多分辨率

官方参考:[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) · [GUI documentation](https://docs.godotengine.org/en/stable/tutorials/ui/index.html) · [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) · [Container](https://docs.godotengine.org/en/stable/classes/class_container.html)

## 输出契约

此 skill 只读知识。在写 /修 Godot UI 时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果 UI bug 不匹配上述任一规则,bug 要么是:

- viewport 大小不匹配(规则 10)— 打印并验证
- 非 `Control` 父节点问题(例如 `Node2D` 是父,拖拽是自定义 `hit_radius` — 见 `references/mouse-and-click.md`)
- 处理函数里的脚本 bug — 在处理函数内 print

还卡住的话,回退到规则 16 的四个诊断,按顺序试。
