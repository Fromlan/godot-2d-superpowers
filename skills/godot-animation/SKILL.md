---
name: godot-animation
description: |
  Godot 4.7 动画:Tween、AnimationPlayer、AnimationTree/StateMachine、AnimatedSprite2D 选型与生命周期。Use when 提到"Tween"、"AnimationPlayer"、"StateMachine"、"精灵动画"、"缓动"、"动画状态机"。Do NOT use for 一次性 UI hover(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [animation type, e.g. 'Tween', 'AnimationTree', 'state machine'] -->

# Godot 动画 (4.7)

Godot 4 动画的实操规则:何时用 Tween vs AnimationPlayer vs AnimationTree vs AnimatedSprite2D,以及状态机模式。深入阅读见 `references/<topic>.md`。

## 1. 四路决策树

按「你在动什么、为什么」选动画 API:

| 问题 | 回答 | 用 |
|------|------|-----|
| 一个属性,一次过渡,~0.1-0.5s | 是 | `Tween` |
| 一个时间轴上多个属性,1-30s | 是 | `AnimationPlayer` |
| 多个命名状态带转换,角色行为 | 是 | `AnimationTree` + StateMachine |
| 精灵表翻页(idle/walk/attack 帧) | 是 | `AnimatedSprite2D` |
| 仅一个「modulate 转红再转回」受击闪烁 | 是 | `Tween` |
| 一个复杂战斗动作带 50 个关键帧属性 | 是 | `AnimationPlayer` |
| Boss 有 6 个状态(idle/attack/hurt/die/summon/teleport) | 是 | `AnimationTree` |
| 一个 4 帧行走循环从精灵表 | 是 | `AnimatedSprite2D` |

**经验法则**:

- Tween 用于「我需要这一个东西平滑变化」(代码优先,迭代快)
- AnimationPlayer 用于「我有一个手工创作的时间序列」(可视化编辑器,设计师友好,可拖时间轴)
- AnimationTree 用于「我有多个序列需要 blend / 切换」(状态机)
- AnimatedSprite2D 用于「我有精灵表带帧」(逐帧)

## 2. Tween — 速查

Tween 在 `godot-ui-best-practices` Rule 6 有详细讲解。要点:

```gdscript
var t := create_tween()
t.set_parallel(true)
t.tween_property(node, "modulate", Color(1.4, 1.4, 1.0), 0.08)
t.tween_property(node, "scale", Vector2.ONE * 1.15, 0.08)
```

对攻击效果:闪烁 + 缩放脉冲 + 位置归位是同一个 `tween` 的 3 个 `tween_property` 调用(前两个 `set_parallel(true)`,归位用 sequential)。

**Tween vs AnimationPlayer**:同样效果,创作方式不同。Tween = 代码优先,迭代快;AnimationPlayer = 可视化编辑器,设计师友好,可拖时间轴。

对于 90% 的一次性效果(受击闪烁、拖拽高亮、菜单滑入),Tween 够了。要设计师无代码改动地迭代时用 AnimationPlayer。

## 3. AnimationPlayer — 当你有时间轴时

使用场景:

- 动画是「设计出来的」(美术师做的)
- 多个属性一起变(位置 + 旋转 + 缩放 + modulate)
- 想在编辑器里拖时间轴
- 动画可能被复用(例如「walk」播给多个角色)

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func play_animation(name: String) -> void:
    anim.play(name)

func play_with_crossfade(name: String, fade := 0.2) -> void:
    anim.play(name, fade)  # 第二个参数 = 交叉淡入时间

# Wait for animation to finish
signal attack_landed
func _on_anim_animation_finished(anim_name: StringName) -> void:
    if anim_name == "attack":
        attack_landed.emit()
```

连 `animation_finished` 信号。参数是动画名;检查是不是你在乎的那个。

**在 `_ready` 中 `call_deferred` 调 `play()`**:直接在尚未入树的节点的 `_ready` 里播的动画会有顺序问题。用 `call_deferred("play", "name")` 排到树建好之后。

## 4. AnimationTree + StateMachine — 角色行为

对复杂角色(Boss、带多种动作的敌人),`AnimationTree` + `StateMachine` 是规范模式。

编辑器中:

1. 加 `AnimationTree` 节点
2. 把 `tree_root` 设为新的 `AnimationNodeStateMachine` 资源
3. 加状态(每个状态 = 一个动画)
4. 加状态间转换(带条件)
5. 把转换连到 triggers / booleans / 其他条件

代码中:

```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    anim_tree.active = true
    # anim_player on AnimationTree is a NodePath, not a node — connect on the player itself
    anim_player.animation_finished.connect(_on_anim_finished)

func request_state(name: String) -> void:
    # Set a parameter on the StateMachine (e.g. a trigger or boolean)
    anim_tree.set("parameters/conditions/" + name, true)
```

对 Z-2 这种自走棋:角色不需要 AnimationTree(战斗是自动,无玩家输入)。将来某章 Boss 敌人用它。

## 5. 状态转换模式

AnimationTree StateMachine 有 4 种转换类型:

| 类型 | 行为 | 用途 |
|------|------|-----|
| **Immediate** | 立即切换,无 blend | 切换瞬间发生(受伤闪红) |
| **Sync** | 同步切换,要求动画帧同步 | 切换后保持相位一致 |
| **At End** | 等待当前动画结束再切换 | 攻击 → 待机;等攻击播完再 idle |
| **Auto** | 条件全满足自动触发(默认) | 连续状态机,根据条件自动切换 |
**反模式**:`request_attack` 在每次切换后忘记重置,导致条件一直 true → 状态机死循环。规则 4 中 `request_attack` 在切换完成后自动重置。

## 6. `queue()` 与 `play()` 语义

| 调用 | 行为 |
|------|-----|
| `play("a")` | 立即开始 "a",替换当前播放 |
| `play("a", 0.2)` | 开始 "a",带 0.2s 从当前淡入 |
| `queue("a")` | 当前动画结束时开始 "a" |
| `stop()` | 停止;动画不再播放 |
| `pause()` / `play()` | 暂停 / 继续,不重新启动 |

`play()` 是重启。要「不在播就播」,先检查:

```gdscript
if not anim.is_playing() or anim.current_animation != "attack":
    anim.play("attack")
```

或者用 `queue()` 串行("attack",然后结束时 "idle"):

```gdscript
anim.play("attack")
anim.queue("idle")
```

## 7. `animation_finished` 信号

当非循环动画到达结尾触发,**或**手动中途停止。

```gdscript
anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: StringName) -> void:
    match anim_name:
        &"attack":
            _apply_attack_damage()
            _return_to_idle()
        &"death":
            queue_free()
        &"_":
            pass  # wildcard
```

对 AnimationTree,信号来自底层 `AnimationPlayer`(不是 AnimationTree)。注意 `AnimationTree.anim_player` 是 **NodePath**,不能直接 `.connect()`。应缓存 AnimationPlayer 节点后连:

```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer
anim_player.animation_finished.connect(_on_anim_finished)
```

官方参考:[AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html) · [AnimationTree](https://docs.godotengine.org/en/stable/classes/class_animationtree.html) · [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)

**循环动画**(`loop = true` 在 inspector)不会每帧迭代都触发 `animation_finished`。只在 `stop()` 调用或动画手动结束时触发。

## 8. `_ready` 中 `call_deferred` 调 `play()`

直接在 `_ready` 里 `play()` 可能与信号、其他组件启动有顺序问题:

```gdscript
func _ready() -> void:
    # Right:
    call_deferred("play", "idle")

func play(name: String) -> void:
    $AnimationPlayer.play(name)
```

`call_deferred` 把调用排到下一帧 idle,树建好之后。

## 9. GPUParticles2D 配 AnimationPlayer

「攻击时放 VFX」:

```gdscript
# VFX node:
# - GPUParticles2D (with process_material)
# - AnimationPlayer with "play" anim that sets emitting=true and resets time

func play_attack_vfx() -> void:
    $VFX/AnimationPlayer.play("play")
```

AnimationPlayer 的 "play" 动画有 2 个关键帧:

- 0.0s: `emitting = true`, `restart = true`(重置粒子系统)
- 0.0s: 结束动画(1 帧时长)

粒子系统在 `emitting` 设 false 时自动清除。要显式控制 lifetime,在 GPUParticles2D 上设 `lifetime`。

## 10. 动画性能

| 成本 | 缓解 |
|------|------|
| 大量节点每帧动 position | 批到一个父节点;动父节点 |
| 多个 `AnimationPlayer` 每帧更新 | 在 player 之间共享动画(设 `animation` 资源) |
| 长动画每帧评估 | 关键帧间隔低更 (0.05s 而不是 0.01s) |
| 进程回调 | 用 `AnimationMixer.callback_mode_process`(IDLE 做视觉;PHYSICS 做与物理对齐的运动)。旧 `process_callback` 枚举已弃用 |

对 Z-2 9×9 棋盘 10-20 棋子,AnimationPlayer 成本可忽略。担心的是几百个同时动画的节点(UI tween + 50 粒子 + 20 敌人)。

## 常见 bug 模式

| 症状 | 根因 | 修复 |
|------|------|------|
| 动画不开始 | `play()` 在尚未入树的节点 `_ready` 中调用 | 用 `call_deferred` |
| 动画从 0 重启而不是续播 | `play()` 重复调;用 `queue()` 或检查 `is_playing` |  |
| 交叉淡入看起来「popped」 | 交叉淡入太短;或动画首帧不同 | 延长淡入 / 对齐首帧 |
| `animation_finished` 对循环动画触发 | 动画没设 `loop = true`;或 `stop()` 被调 | 设 loop 或避免 stop |
| AnimTree 转换不触发 | 转换条件从不在代码里设 | 检查 `parameters/...` 参数名与编辑器匹配 |
| 状态机卡住 | 转换循环;或条件一直 true | 加 hysteresis(状态最小停留时间) |
| 粒子「爆炸一次」后不再出现 | 动画里没设 `restart = true`,或 process_material 不重置 | 在动画里设 restart |
| `play()` 返回 OK 但没效果 | AnimationLibrary 为空,或动画名拼错 | 检查库与名字 |

## 参考索引

- `references/tween-vs-animationplayer.md` — 决策树、并排示例
- `references/animationtree-statemachine.md` — 完整状态机代码 + inspector 演示
- `references/animatedsprite-flipbook.md` — 精灵表导入 + 翻页配置

## 输出契约

只读知识。在写 / 改 Godot 动画时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果动画 bug 不匹配上述任一规则:

- AnimationPlayer:打印 `anim.current_animation`、`anim.is_playing()`、`anim.current_animation_position` 看状态
- AnimationTree:打印 `anim_tree.get("parameters/playback")` 看当前状态
- AnimatedSprite2D:打印 `sprite.frame`、`sprite.animation`、`sprite.is_playing()`

还卡住的话,回退到 `references/tween-vs-animationplayer.md` 的四个诊断。

官方参考:[AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html) · [AnimationTree](https://docs.godotengine.org/en/stable/classes/class_animationtree.html) · [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) · [Animation documentation](https://docs.godotengine.org/en/stable/tutorials/animation/index.html) · [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)
