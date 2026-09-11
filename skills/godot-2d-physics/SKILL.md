---
name: godot-2d-physics
description: |
  Godot 4.7 2D 物理:Body 选择、collision_layer/mask、Area2D 触发器、CharacterBody2D 移动与拖拽检测。Use when 提到"2D 碰撞"、"Area2D"、"CharacterBody"、"move_and_slide"、"is_on_floor" 等 2D 物理关键词。Do NOT use for 3D physics(见 godot-3d-superpowers)或纯 UI 拖拽(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [body type or topic, e.g. 'CharacterBody2D', 'collision_layer', 'Area2D 触发器'] -->

# Godot 2D 物理 (4.7)

Godot 4 2D 物理的实操规则。每条规则说明失败模式、修复、一句话总结。深入阅读见 `references/<topic>.md`。

## 1. Body 决策矩阵

按「谁控制运动」而不是「它是什么」选 body:

| 场景 | Body | 为什么 |
|------|------|--------|
| 玩家、NPC、每帧用逻辑驱动的物体 | `CharacterBody2D` | 你驱动 `velocity` 调 `move_and_slide`;确定性、帧精确输入 |
| 箱子、球、碎片、布偶,引擎模拟 | `RigidBody2D` | 重力、冲量、摩擦由物理服务器处理 |
| 触发 / 拾取 / 伤害区 / 拖拽命中测试 | `Area2D` | 仅重叠检测,无物理响应 |
| 静态关卡几何(墙、地板、平台) | `StaticBody2D` | 不动,为非移动碰撞体优化 |

**错误选择**:玩家用 `RigidBody2D`。物理服务器跨机器非确定性(对回放 / 多人不好),且你的输入被重力混合到你无法完全控制。`CharacterBody2D` 是「我用代码移动它」的正确选择。

## 2. `collision_layer` vs `collision_mask` — 32 位位域

每个 `CollisionObject2D`(Area2D、CharacterBody2D 等的父类)有两个位域:

- `collision_layer` — **我是谁**(广播的位)
- `collision_mask` — **我撞谁**(检查的位)

碰撞发生 iff (A.mask & B.layer) != 0 **且** (B.mask & A.layer) != 0。

```
Player.collision_layer   = 0b0001  (LAYER_PLAYER)
Player.collision_mask    = 0b1110  (除自身外全部)

Enemy.collision_layer    = 0b0010  (LAYER_ENEMY)
Enemy.collision_mask     = 0b0001  (只看到 Player)

Wall.collision_layer     = 0b0100  (LAYER_WORLD)
Wall.collision_mask      = 0b0011  (看到 Player + Enemy)
```

**为什么胜过 `if` 检查**:改一个 body 的「我撞什么」是 Inspector 单字段编辑,不用改代码,不会有「我忘了同步两个对象」的 bug。

**`Area2D` 规则**:`monitoring`(广播 `area_entered`)vs `monitorable`(别人通过它们的 mask 检测)。伤害区:`monitoring = true` 看 body;玩家身上的拾取 hitbox:`monitorable = true` 让拾取能检测到。

## 3. Area2D 信号驱动的触发器

`Area2D` 仅用于 overlap-only。信号:

```gdscript
# On Area2D node
area_entered(area: Area2D)         # 另一个 Area2D 进入
area_exited(area: Area2D)          # 另一个 Area2D 离开
body_entered(body: Node2D)         # CharacterBody2D / RigidBody2D / TileMap 进入
body_exited(body: Node2D)          # body 离开

# On any CollisionObject2D
area_entered(area: Area2D)         # 一个 Area2D 进入 THIS body
```

代码或编辑器 Signals 面板连接。给信号参数加类型让编辑器抓错:

```gdscript
func _on_pickup_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.add_coin(1)
        queue_free()
```

伤害区用 `Timer` 节流:区不应该每帧都触发 body 在内的时候。

## 4. CharacterBody2D 移动模板

```gdscript
extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -380.0
const GRAVITY := 980.0

@export var can_double_jump := false

func _physics_process(_delta: float) -> void:
    # Add gravity
    if not is_on_floor():
        velocity.y += GRAVITY * _delta

    # Jump
    if Input.is_action_just_pressed(&"jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Horizontal
    var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    velocity.x = dir.x * SPEED

    move_and_slide()
```

`move_and_slide` 移动 body,应用速度,沿墙滑。发生任何 slide 返回 `true`。`is_on_floor()` 读最后一次碰撞的 floor 标志。

**用 `_physics_process` 而非 `_process`** 处理移动。物理以 `physics_fps` tick(默认 60)。变时间步长 `_process` 会导致帧率相关物理。

## 5. `_physics_process` 中重构 motion 计算

**反模式**:玩家逻辑、敌人 AI 写满 `_physics_process` 且不可测。

**正确**:抽成纯函数,GUT 测:

```gdscript
# In player.gd
static func compute_motion(
    prev_velocity: Vector2,
    input_dir: float,
    grounded: bool,
    delta: float,
    max_speed: float,
    acceleration: float,
    friction: float,
    jump_velocity: float,
    gravity: float
) -> PlayerMotionOutput:
    # 纯逻辑 — 不调引擎 API, 不访问节点
    ...

func _physics_process(delta: float) -> void:
    var motion := compute_motion(velocity, input_dir, is_on_floor(), delta, ...)
    velocity = motion.linear_velocity
    move_and_slide()
```

## 6. 拖拽命中测试

对棋盘 / 卡牌:玩家拖一张卡到目标格。

**不要** 用 `get_node` 或 `_input` + `Control.get_global_rect().has_point()`。这些不走 2D 世界。

**正确**:每张卡 / 每个棋盘格子有自己的 `Area2D` + `CollisionShape2D`。信号驱动:

- `area_entered(area)` / `area_exited` — 卡进入 / 离开格子
- `input_event(viewport, event, shape_idx)` — 直接在 Area2D 上点击

这给你空间查询,包括旋转和形状精度(矩形 / 圆 / 胶囊)。

多个 `Area2D` 可在同一物体上(例如可点击 body + 较大「选择范围」)。

权衡:每件多一个 CollisionShape2D,空间查询略增 CPU。对 9×9 棋盘 50 个格子可忽略。

## 7. CollisionShape2D 选择

| 形状 | 用途 | 注意 |
|-------|------|------|
| `RectangleShape2D` | 矩形(卡、墙) | 最便宜 |
| `CircleShape2D` | 圆形(金币、球) | 旋转不变;鼠标点击 hitbox 好 |
| `CapsuleShape2D` | 有身高角色(平台跳跃) | 2D 版的胶囊 |
| `SegmentShape2D` | 细线(平台边缘、剑弧) | 1D 碰撞 |
| `WorldBoundaryShape2D` | 无限平面(地板、竞技场墙) | 仅 `StaticBody2D` |
| `ConvexPolygonShape2D` | 不规则形状 | 最多 8 顶点;子节点定义点用 `CollisionPolygon2D` |
| `SeparationRayShape2D` | 1D 射线 | 仅 `CharacterBody2D`,用于「前面有墙吗」 |

俯视 2D 棋子:`CircleShape2D` 半径匹配视觉范围。

## 8. 层位命名约定

在 autoload(`layer_names.gd` 或类似):

```gdscript
const LAYER_PLAYER     := 1 << 0   # 1
const LAYER_ENEMY      := 1 << 1   # 2
const LAYER_WORLD      := 1 << 2   # 4
const LAYER_PICKUP     := 1 << 3   # 8
const LAYER_HAZARD     := 1 << 4   # 16
const LAYER_PROJECTILE := 1 << 5   # 32
const LAYER_VISION     := 1 << 6   # 64  (AI sees you)
const LAYER_PREDICTION := 1 << 7   # 128 (ghost bodies, ignored by gameplay)
```

用常量而不是裸数字。编辑器也有位域编辑器(任何 CollisionObject2D inspector 顶部),若在 **Project Settings → Layer Names → 2D Physics** 设了层名,可以按名勾选。

## 9. `physics_fps` 调优

默认 60。需要慢模拟(RTS、大世界)省 CPU 降到;格斗游戏(帧精确命中)提高。

```ini
[physics]
common/physics_fps = 60
```

与 `_physics_process` 间隔挂钩。设 `physics_fps = 30`,`_physics_process(delta)` 收 `delta ≈ 0.0333`。速度驱动的移动正确缩放(乘 delta),所以 30 Hz 物理不会让世界变慢。

**反模式**:设 `physics_fps = 1000` 想「修抖动」。修在代码里(平滑、子步)。1000 Hz 烧 CPU 没收益。

## 10. `_process` vs `_physics_process` — 何时用哪个

| 用途 | 在哪 |
|-------|---------|
| 移动(`move_and_slide`、`move_and_collide`) | `_physics_process` |
| 读物理状态(碰撞、重叠) | `_physics_process`(或 Area2D / body 的信号) |
| 视觉插值(物理 tick 间平滑) | `_process` |
| AI 决策(目标、寻路) | 任一;`_process` 更平滑,`_physics_process` 与 tick 对齐 |
| 输入响应 | `_process` 或 `_unhandled_input` |
| Tween 动画 | `_process`(或通过 Tween autoplay) |

需要时混用:CharacterBody 在 `_physics_process` 移动,sprite 在 `_process` 在物理 tick 间平滑插值,用于高 Hz 视觉。

## 常见 bug 模式

| 症状 | 根因 | 规则 |
|------|------|------|
| 玩家掉穿地板 | `collision_mask` 不含 `LAYER_WORLD` | 2 |
| `area_entered` 从不触发 | `monitoring` 关,或两个 body 同层且不在对方 mask | 2 + 3 |
| `move_and_slide` 不动 | 速度为 0,或 `freeze` / `freeze_mode` 已被设 | 4 |
| 沿墙滑不工作 | `slide_on_ceiling = false`,或墙法线边缘不可达 | 4 |
| 在斜坡上抖动 | `up_direction` 错,或 `floor_max_angle` 太小 | 4 |
| 拖拽仍漏点击 | `Area2D` 没 `CollisionShape2D`,或形状位置错 | 6 + 7 |
| Body 与一切碰撞 | `collision_mask = 0xFFFFFFFF`(所有位) | 2 |
| Area2D 检测自身 | `monitorable = true` 且自身 body 在被观察的层 | 2 |

## 参考索引

- `references/body-decision.md` — 4 种 body 类型,完整对比与代码模板
- `references/collision-layers.md` — 32 位层位、常见项目布局
- `references/area-signals.md` — Area2D 信号矩阵、触发器模式 cookbook

## 输出契约

只读知识。在写 / 修 Godot 2D 物理代码时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果物理 bug 不匹配上述任一规则,bug 要么是:

- 层 / mask 配置错(规则 2)— `print(self.collision_layer, " ", self.collision_mask)` 以及对方 body
- 形状几何错(规则 7)— 在编辑器开启「Visible Collision Shapes」可视化 `CollisionShape2D`
- 自定义代码驱动 motion 错(规则 4 / 5)— 在 `move_and_slide` 前后 `print(position)`

还卡住的话,回退到 `references/body-decision.md` 里的四个诊断。
