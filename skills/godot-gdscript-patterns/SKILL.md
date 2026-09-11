---
name: godot-gdscript-patterns
description: |
  Godot 4.7 GDScript:静态类型、@export / @onready、Signal 解耦合、Resource 数据驱动、class_name、autoload 边界、preload vs load。Use when 提到"GDScript 静态类型"、"@export"、"@onready"、"Signal 解耦合"、"Resource 数据"、"class_name"。Do NOT use for UI 布局(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [pattern, e.g. 'signal', '@export', 'autoload', 'class_name', 'Resource'] -->

# Godot GDScript 模式 (4.7)

GDScript 的实操规则:静态类型、注解、信号解耦合、Resource 作为数据、autoload 边界。深入阅读见 `references/<topic>.md`。

## 1. 静态类型不是风格问题

`var x: int = 5` 在运行时 **不是** 等同于 `var x = 5`:

| 维度 | 无类型 | 有类型 |
|----------|----------|----------|
| 运行时路径 | Variant 分发(装箱) | 直接 C 路径(无装箱) |
| 性能 | 每操作约 2-4 倍慢 | 接近 C |
| 静态分析 | 仅警告 | 编辑时报错 |
| 内存 | Variant 开销 | 栈或直接成员 |

超出 demo 范围的项目都要严格类型化。分析器在运行前就抓到类型错误。

```gdscript
# Right
var hp: int = 100
var name: String = "hero"
var position: Vector2 = Vector2.ZERO
var allies: Array[Piece] = []   # typed array (Godot 4 only)

# Wrong (untyped, slower, less safe)
var hp = 100
var name = "hero"
var position = Vector2.ZERO
var allies = []
```

对于真正 Variant / 动态的类型(如 JSON 解析、值混合的 Dictionary),用 `Variant`:

```gdscript
var data: Variant = JSON.parse_string(raw_text)
```

## 2. `@export` 用于设计师可调的数值

`@export` 把属性暴露给 Inspector,设计师(和你)能在不修改代码的前提下调整。

```gdscript
@export var speed: float = 220.0
@export_range(50.0, 800.0) var speed_clamped: float = 220.0
@export_enum("Easy", "Normal", "Hard") var difficulty: int = 1
@export var piece_data: Resource
@export var initial_position: Vector2 = Vector2(100, 100)
@export_group("Combat")
@export var attack_damage: int = 50
@export var attack_range: int = 1
```

`@export_range(min, max)` 加滑块。`@export_enum(...)` 加下拉。`@export_group("name")` 在 Inspector 分组。

**规则**:不需重新编译就能调的数值都用 `@export`。玩法数值、美术引用、阈值。内部标志 / 计数器不用。

## 3. `@onready` 用于子节点缓存

`@onready` 在 `_ready()` 解析,所以 `$Path` 之后访问不会是 null:

```gdscript
@onready var board: Board = $Board
@onready var shop_panel: PanelContainer = $HUD/ShopPanel
@onready var attack_line_pool: Array[Line2D] = $AttackLines.get_children()
```

**为什么不直接用内联的 `$Path`?** 因为 `$Path` 每次访问都调用函数,路径错返回 null 然后在难调的位置崩溃。`@onready` 在 `_ready` 一次性解析;路径错就立即报错指向出错行。

**反模式**:用 `@onready` 引用场景里不存在的节点。改用 `@export var piece_scene: PackedScene` 然后运行时 `instantiate()`。

## 4. 信号解耦合(代替 `get_node` 跨树访问)

**反模式**:A 节点钻进 B 节点的树里调方法:

```gdscript
# Node A wants to notify Node B
get_node("/root/Main/Battle/HUD/SomeLabel").text = "Score: 100"
```

**正确**:A 发信号,B(或任何人)连接:

```gdscript
# Emitter
signal score_changed(new_score: int)
func add_score(amount: int) -> void:
    score += amount
    score_changed.emit(score)

# Listener (anywhere)
score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
    label.text = "Score: %d" % new_score
```

**为什么用信号**:

- 类型化参数(编辑器在连接时就会报错)
- 多接收者(1 个 emitter → N receivers)
- 解耦合:emitter 不关心谁在听
- 节点重 parent / 换场景时连接仍生效

**给信号参数加类型**以便编辑器保护:

```gdscript
signal piece_killed(piece: Piece, killer: Piece)
signal hp_changed(new_hp: int, max_hp: int)
signal turn_started(turn_number: int)
```

**连接标志**:

```gdscript
piece_killed.connect(_on_piece_killed)                              # default; runs in caller
piece_killed.connect(_on_piece_killed, CONNECT_DEFERRED)            # runs at idle (safe mid-iteration)
piece_killed.connect(_on_piece_killed, CONNECT_PERSIST)              # survives scene reload
piece_killed.connect(_on_piece_killed, CONNECT_ONE_SHOT)             # auto-disconnect after one fire
```

`CONNECT_DEFERRED` 是接收者可能在 emitter 触发中改其状态时的安全网(比如在迭代中改 list)。

## 5. Resource 作为数据(`extends Resource` + `.tres`)

可复用资源(贴图、声音、材质、武器)做成 `Resource` 存为 `.tres`;实体(`Node`)有行为并引用资源。

```gdscript
# scripts/piece_data.gd
class_name PieceData extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cost: int = 1
@export var base_hp: int = 100
@export var base_attack: int = 50
@export var icon: Texture2D
```

**为什么 Resource 而不是 Dictionary**:

- 类型化(Dictionary 运行时才能发现错误)
- Inspector 可绑(`@export var data: PieceData` 可在 Inspector 选资源)
- IDE 跳转(在 Resource 子类定义上点击跳转)
- 可序列化为 `.tres`

**UID vs 路径**(`asset_uid` 系统,Godot 4.4+):

```gdscript
# Brittle: 改名就坏
var scene := load("res://data/pieces/ply_001.tres")

# Robust: UID 在重命名后保持稳定
var scene := load("uid://b1234abcde")
```

## 6. `class_name` 全局脚本引用

顶层声明 `class_name X` 让 X 在整个项目全局可引用(自动出现在「Create Node」对话框):

```gdscript
# scripts/piece.gd (top of file)
class_name Piece extends Node2D

# Anywhere else in the project
var p: Piece = Piece.new()
```

避免循环依赖:如果 A 引 B、B 引 A,改成单向引用或用 EventBus。

**复制本仓库 `class_name` 时务必重命名**(否则触发 "class_name already registered")。建议 `PieceData` → `YourGamePiece`,或加项目前缀。

## 7. Autoload 边界(仅用于跨场景基础设施)

`Project Settings → Autoload` 留给真正跨场景的状态:save manager、audio bus、networking peer。**不要**把所有东西都塞 autoload。

```gdscript
# res://autoloads/event_bus.gd
extends Node
signal player_died
signal level_cleared
signal score_changed(new_score: int)
```

注册:`Project Settings → Autoload → "EventBus"`。

## 8. `@warning_ignore` 用于有理由的忽略

代码分析器抛警告时,先**真的修**它。如果有充分理由必须忽略,在行尾加 `@warning_ignore("...")` 注释:

```gdscript
func _ready() -> void:
    if some_global_thing != null:
        do_work()  # @warning_ignore("unsafe_method_access") 外部 init 早于 _ready,已知
```

**反模式**:`@warning_ignore` 用来盖掉"我不知道"的警告。永远先查为什么,再决定忽略。

## 9. `preload()` vs `load()`

| | preload | load |
|----------|---------|------|
| 时机 | 解析时(脚本加载) | 运行时 |
| 性能 | 一次加载,可缓存 | 每次调用都解析路径 |
| 路径错 | 立即报错 | 运行时崩溃 |
| 用于 | 自己的资源 | 动态路径(如 mod) |

```gdscript
# Right: preload your own assets
const PieceData := preload("res://data/pieces/ply_001.tres")

# Right: load mod assets at runtime
var mod_path := "res://mods/%s/piece.tres" % mod_name
var piece := load(mod_path) as PieceData
```

## 10. `Variant` 边界

`Variant` 只用在边界:

- JSON 解析(`JSON.parse_string` 返回 `Variant`)
- 值混合的 Dictionary(`Dictionary[String, Variant]`)
- 真正类型混合的 signal 参数(罕见)

代码内部一律加类型:

```gdscript
# At the boundary
var raw_data: Variant = JSON.parse_string(text)

# After parsing, narrow
if typeof(raw_data) == TYPE_DICTIONARY:
    var dict: Dictionary = raw_data
    var name: String = dict.get("name", "")
    var hp: int = dict.get("hp", 0)
```

`unsafe_method_access` 和 `unsafe_property_access` 警告会标记这种代码。看到警告就加类型。

## 11. Resource UID vs 硬编码路径

```gdscript
# Brittle: 改名就坏
var scene := load("res://data/pieces/ply_001.tres")

# Robust: UID 跨重命名稳定
var scene := load("uid://b1234abcde")
```

`uid://...` 是文件首次导入时生成的。UID 存在文件的 `.import` 侧车。右键编辑器文件 → "Copy Resource Path" 或 "Copy UID"。

`@export` 属性用 UID 派生引用最稳。普通路径对一次性脚本代码够用,但 `@export var data: PieceData` 用 UID 更稳。

## 12. Typed Dictionary (Godot 4.4+)

```gdscript
var stats: Dictionary[String, int] = {"hp": 100, "attack": 50, "defense": 30}
var config: Dictionary[String, Variant] = {"name": "hero", "level": 5, "alive": true}
```

Typed Dictionary 在编辑时抓错值类型访问:

```gdscript
stats["hp"] = "100"   # analyzer error: expected int, got String
```

schema 已知(存档、配置、消息总线)时用 typed。真正动态数据用普通 `Dictionary`。

## 13. 静态函数(无 `self`)

```gdscript
static func is_valid_position(pos: Vector2) -> bool:
    return pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT

# Called without instance
if Board.is_valid_position(some_pos):
    ...
```

不需要实例状态的工具方法用 `static func`。可以从任何地方调用,无需实例引用。

## 14. 常量 vs export vs 魔法数字

| 类型 | 位置 | 何时改 |
|------|------|--------|
| `const X := 5` | 脚本,编译时 | 极少(需重编译) |
| `@export var x: int = 5` | Inspector | 设计师调 |
| `var x: int = 5`(可变) | 运行时,实例状态 | 非设计意图 |

数学常量(PI、gravity、max int)、布局常量(default font size、default spacing)、查找表用 const;玩法数值用 export;可变 var 用于每实例状态。

**不要把所有东西都做成 `@export`** — 设计师会被淹没。每个脚本只暴露 5-10 个可调值。

## 常见 bug 模式

| 症状 | 根因 | 修复 |
|------|------|------|
| `$Path` 返回 null | 拼错或路径改了 | 用 `@onready`,拿到解析时报错 |
| `_ready` 里 null 引用 | 场景树建好前访问了 `$Path` | 用 `@onready`(在对的时机解析) |
| 静态分析噪声 | 无类型声明 | 全部加类型(规则 1) |
| 信号不触发 | `emit_signal` 拼错,或信号连错 | 给信号参数加类型,IDE 自动补全 |
| `class_name already registered` 警告 | 同一名字在同一项目里重复 | 重命名或移除重复 |
| 资源修改游戏里没体现 | 忘了 `@export var data: Resource` 并在编辑器赋值 | 在 Inspector 绑资源 |
| `load()` 运行时失败 | 路径拼错 | 用 `preload` 改为解析时 |
| Mod 加载不到 | 给 mod 路径用了 `preload`(必须运行时) | 运行时用 `load` |

## 参考索引

- `references/static-typing.md` — 完整类型指南、何时用 `Variant`、性能影响
- `references/signals-decoupling.md` — 信号作为架构、连接模式
- `references/resource-data-driven.md` — Resource 作为数据、存读、版本化资产

## 输出契约

只读知识。在写 /改 GDScript 时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果 GDScript bug 不匹配上述任一规则:

- 路径 / 节点树错(规则 3)— 在嫌疑节点上 `print(get_path())`
- 信号连接错(规则 4)— `print(Object.get_signal_connection_list(signal_name))`
- 类型不匹配(规则 1)— 加类型注解;警告变错误
- Resource 加载错(规则 5)— 检查 `.import` 侧车;检查 `ResourceLoader.exists(path)`

还卡住的话,静态分析器是你的朋友:`godot --headless --check-only res://path/to/script.gd` 会暴露类型错误。
