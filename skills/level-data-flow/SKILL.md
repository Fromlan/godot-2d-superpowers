---
name: level-data-flow
description: 设计、修改或扩展 2D 关卡时的使用,或当用户说「改关卡」/「加关」/「调整难度」。把 GDD 设计意图桥接到 Godot 场景/资源:关卡数据作为 .tres 或 JSON、场景由数据组合、确定性加载。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [design-to-data | data-to-scene | tune-balance] -->

# 关卡数据流 (2D Godot)

> 把"关卡设计意图"映射到 Godot 资源,再从数据生成/调整场景。
> 走完本技能,产出"数据驱动、可一键生成、参数化调难度"的关卡。

## 0. 何时用

- 第一次做关卡系统
- 改现有关卡布局/敌人配置/收集物位置
- 调难度曲线(数据层面)
- 加新关卡

## 1. 三层数据模型(强制)

任何 2D 关卡都分三层:

```
设计意图(GDD/手稿)
   ↓
数据层(.tres / .json / .csv)
   ↓
场景层(.tscn 程序化生成 / 编辑器手摆)
```

**禁止**让"设计意图"直接到"场景层",中间必须有数据层。

## 2. 数据层选型(决策树)

```
关卡数据
├── 网格 / 瓦片? → TileMapLayer + TileSet(.tres)(TileMap 已弃用)
├── 实体布局(敌人/道具/触发器)? → LevelLayout(.tres) + JSON
├── 波形 / 时间轴(清版/Roguelike)? → WaveConfig(.tres) + 计时
└── 简单纯静态 → 直接在 .tscn 摆(限 ≤ 10 个实体)
```

**默认**: `LevelLayout` (Resource) + 实体数据 JSON

## 3. LevelLayout Resource 模板

```gdscript
# scripts/level_layout.gd
class_name LevelLayout extends Resource

@export var level_id: StringName
@export var display_name: String
@export var tile_size: Vector2i = Vector2i(16, 16)
@export var grid_size: Vector2i = Vector2i(40, 23)
@export var player_spawn: Vector2i
@export var goal_position: Vector2i
@export var entities: Array[EntitySpawn] = []
@export var checkpoints: Array[Vector2i] = []
@export var background_layers: Array[PackedScene] = []
@export var music: AudioStream
@export var time_limit_sec: float = 0.0  # 0 = 无限制

class EntitySpawn extends Resource:
    @export var type: StringName  # 实体类型 key,从全局 EntityRegistry 查表
    @export var entity_scene: PackedScene  # 可选,优先用;否则查 EntityRegistry
    @export var position: Vector2i
    @export var rotation: float = 0.0
    @export var data: Dictionary = {}  # 类型专属参数
```

## 4. 数据存储

- **代码内常量**: `@export` 字段默认
- **关卡实例**: `resources/levels/level_01.tres`
- **大批量数据**(Roguelike 房间库、卡牌库): `data/<thing>.json`,运行时 `JSON.parse_string`

```gdscript
# 加载关卡
const Level01 = preload("res://resources/levels/level_01.tres")
```

## 5. 场景层生成

### 5.1 实体摆放脚本

```gdscript
# scripts/level_builder.gd
class_name LevelBuilder extends Node

func build(layout: LevelLayout) -> void:
    # 清场
    for child in get_children():
        child.queue_free()
    # 玩家
    $Player.global_position = Vector2(layout.player_spawn) * layout.tile_size
    # 实体:优先用 EntitySpawn.entity_scene,否则从 EntityRegistry 查表
    for e in layout.entities:
        var scene: PackedScene = e.entity_scene if e.entity_scene else EntityRegistry.get_scene(e.type)
        if scene == null:
            push_warning("Unknown entity type: %s" % e.type)
            continue
        var node := scene.instantiate()
        node.global_position = Vector2(e.position) * layout.tile_size
        for k in e.data:
            node.set(k, e.data[k])
        add_child(node)
    # 检查点
    for cp in layout.checkpoints:
        var cp_node := preload("res://scenes/checkpoint.tscn").instantiate()
        cp_node.global_position = Vector2(cp) * layout.tile_size
        add_child(cp_node)
    # 音乐
    if layout.music:
        $Music.stream = layout.music
        $Music.play()
```

**EntityRegistry autoload**(强制注册表,杜绝字符串拼接路径):

> 方法名用 `get_scene` 而不是 `get`——`Object.get()` 是引擎内置方法,子类再定义 `get` 会遮蔽并造成难以排查的调用错误。

```gdscript
# res://autoloads/entity_registry.gd
extends Node

var _scenes: Dictionary[StringName, PackedScene] = {}

func register(type: StringName, scene: PackedScene) -> void:
    _scenes[type] = scene

func get_scene(type: StringName) -> PackedScene:
    return _scenes.get(type, null)

func has(type: StringName) -> bool:
    return type in _scenes
```

项目根 `project.godot` autoload 段:

```ini
[autoload]
EntityRegistry="*res://autoloads/entity_registry.gd"
```

各实体在 `_ready` 注册:

```gdscript
# res://autoloads/entity_registry_init.gd 或 main.gd
func _ready() -> void:
    EntityRegistry.register(&"enemy_slime", preload("res://scenes/entities/enemy_slime.tscn"))
    EntityRegistry.register(&"coin", preload("res://scenes/entities/coin.tscn"))
    EntityRegistry.register(&"spike", preload("res://scenes/entities/spike.tscn"))
```

**为什么用注册表**:与 `godot-gdscript-patterns` 第 9 节"preload vs load"保持一致——避免运行时字符串拼接路径(错路径运行时报错,IDE 抓不到);所有实体 `preload` 在解析时加载,重命名后 UID 自动更新。

### 5.2 何时手摆 vs 程序化

| 情况 | 推荐 |
|------|------|
| 简单静态关卡(≤ 20 实体) | 编辑器手摆,无需数据层 |
| 复杂关卡 / 关卡多 | 数据 + 程序化 |
| 调试中的单个关卡 | 先手摆,稳定后转数据 |
| 程序生成(Roguelike) | 必须数据驱动 |

## 6. TileMapLayer 集成(可选,瓦片地图;TileMap 已弃用)

- `TileSet` 资源 → `resources/tilesets/terrain.tres`
- 关卡用 `TileMapLayer` + 关联 TileSet(一层一个节点)
- 数据可放 `level_01_tile_data.tres` 或编辑器绘制后保存
- 官方参考:[TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html) · [Using Tilemaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)

## 7. 难度调参(数据驱动)

- 不要在代码里写 `enemy_hp = 3 * level_id`
- 用 `@export` 在 `LevelLayout` 暴露:
  - `enemy_hp_multiplier: float`
  - `enemy_speed_multiplier: float`
  - `spawn_density: float`
- 在 `LevelBuilder` 里读 layout,做乘法

```gdscript
for e in layout.entities:
    if e.type.begins_with("enemy_"):
        node.hp = node.base_hp * layout.enemy_hp_multiplier
```

## 8. 关卡选择 / 解锁

```gdscript
# scripts/level_select.gd
class_name LevelSelect extends Resource

@export var levels: Array[LevelLayout]
@export var unlocked: Array[StringName] = []
```

存档时只存 `unlocked`,代码里 `levels` 是固定列表。

## 9. 加载流程

```gdscript
# 启动加载某关
func load_level(id: StringName) -> void:
    var layout: LevelLayout = load("res://resources/levels/%s.tres" % id)
    $LevelBuilder.build(layout)
```

## 10. 反模式

- ❌ 实体位置写死在 `_ready()` 里 → 改不动
- ❌ 关卡数据散落在多个 `.tscn` → 难批量调
- ❌ `global_position` 写绝对值 → 瓦片尺寸一变全错
- ❌ 难度硬编码在脚本 → 设计师改不了
- ❌ 不用 `Resource` 直接用 `Dictionary` → 无类型,IDE 跳转失效
- ❌ 关卡用 `Dictionary` 传参 → 类型丢失

## 11. 工具脚本

- `scripts/init-project.ps1` — 创建 `resources/levels/` 目录和默认 `LevelLayout` 模板
- 编辑器插件: `addons/level_editor/`(可选,自己写)

## 12. 衔接

- 关卡改完 → 跑 `scripts/run-tests.ps1`(关卡加载单测)
- 性能问题 → `systematic-debugging-2d`
- 玩家反馈"难度不对" → 调 `LevelLayout` 的 multiplier,不动代码
