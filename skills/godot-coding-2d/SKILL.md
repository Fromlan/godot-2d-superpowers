---
name: godot-coding-2d
description: "在写或修改 2D Godot 代码,或执行计划任务时使用。强制 Godot 2D 编码约定、静态类型、信号所有权,以及分层测试策略(逻辑 TDD / 集成 / 手动)。读 godot-gdscript-patterns 和 godot-2d-physics 作为技术来源。"
last_reviewed: 2026-09-10
---

<!-- argument-hint: [logic | integration | experience | refactor] -->

# Godot 2D 编码 (含分层测试策略)

> 写 2D Godot 代码时的统一规范 + **分层测试策略**。
> 走完本技能,产出"符合项目约定、覆盖对应层级测试"的代码改动。

## 0. 何时用

- 任何 `game-writing-plans` 出来的任务执行
- 重构现有 Godot 代码
- 用户说"加个 X"且 X 偏代码而非设计

## 1. 上游先读(必须)

写任何代码前,**先读这两份**:

1. `skills/godot-gdscript-patterns/SKILL.md` — GDScript 风格/静态类型/Resource/信号
2. `skills/godot-2d-physics/SKILL.md` — 物理/碰撞/移动规范

如果涉及动画/UI/音频,再对应读 `godot-animation` / `godot-ui-best-practices` / `godot-audio`。

**禁止**靠"我记着"写代码 — 规范会演进,以 SKILL.md 为准。

### 1.1 子代理派发时的强制(当通过 Codex `multi_agent_v1__spawn_agent` 派子任务时)

子代理有**独立上下文**,父代理的"先读"指令不会自动带入。`using-game-dev` 的强制约束只对父 agent 生效,不能直接传导到子代理。因此:

- 派发任务时,**父代理必须在 `message` 中显式写明**:`先读 skills/godot-gdscript-patterns/SKILL.md 和 skills/godot-2d-physics/SKILL.md 再写代码`。
- 若任务涉及动画/UI/音频,追加对应"先读"指令(如 `再读 skills/godot-animation/SKILL.md`)。

反模式:仅在父代理自身的回复里说"我会让子代理先读 X"——子代理看不到。

## 2. 静态类型与命名(必须)

参考 `godot-gdscript-patterns`,核心点:
- 全文件 `@tool` 显式标注(仅编辑器脚本)
- 公共方法必须显式参数/返回类型
- `@export` 变量必须显式类型
- `@onready` 节点引用必须显式类型
- `class_name` 顶层声明,避免循环依赖
- 命名:常量 `UPPER_SNAKE`、类 `PascalCase`、函数/变量 `snake_case`、私有前缀 `_`

## 3. 信号所有权(必须)

- **谁的状态变化,谁发信号** — 不要在外部脚本里发别人的信号
- 信号命名:过去时( `health_changed`、`died`、`item_collected` )
- 连接方式:场景编辑器内连接 vs `connect()` 视情况而定,但**同一项目保持一致**
- 跨场景广播用 **EventBus**(单例 `autoload`),不直接互相引用

## 4. 场景/资源/脚本的边界(必须)

| 元素 | 谁拥有 | 改动原则 |
|last_reviewed: 2026-09-10
------|--------|----------|
| 场景(`.tscn`) | 该场景的根脚本 | 改场景树结构先动 `.tscn`,再动脚本 |
| 资源(`.tres`) | 数据的 Resource 类 | 数据驱动,代码不持有常量数值 |
| 脚本(`.gd`) | 该脚本文件 | 函数单一职责,跨脚本用信号/依赖注入 |

## 5. 节点引用与 `@onready`

- 节点路径不写死(避免 `get_node("Path/To/Node")` 散落)
- 用 `@onready var x: Node = $X` + 显式类型
- 节点重命名 → 必须同步改 `.tscn`,**不让子代理悄悄改路径**

## 6. 资源 UID(4.4+ 必须)

- 优先用 `uid://` 而非 `res://` 路径
- 移动/重命名资源:Godot 自动重写 uid,无需手动改
- 提交前: `godot --headless --quit` 让 UID 重新生成

## 7. **分层测试策略**(核心,必须遵守)

游戏代码不能一刀切 TDD。按"在哪一层"决定怎么测:

### 7.1 逻辑层(必须 TDD)

**范围**:无副作用的纯函数 / 状态机 / 数据计算

**典型**:伤害公式、暴击计算、库存增减、状态机转移、AI 决策、关卡解析、存档序列化

**TDD 流程**(严格 RED-GREEN-REFACTOR):

1. **RED**: 在 `tests/test_logic_<name>.gd` 写一个失败测试
   ```gdscript
   extends GutTest

   func test_damage_with_armor() -> void:
       var dmg := DamageCalc.compute(100, 30)
       assert_eq(dmg, 70)
   ```
2. **跑**: `scripts/run-tests.ps1` 确认失败
3. **GREEN**: 写最小代码让测试通过
4. **跑**: 确认通过
5. **REFACTOR**: 清理(不破坏测试)
6. **commit**

**禁止**:
- ❌ 先写实现再补测试
- ❌ "我觉得这个函数太简单不用测" → 简单 = 好测,必须测
- ❌ 跳过 RED 直接 GREEN → 等于没 TDD

### 7.2 装配层(集成测试,推荐)

**范围**:多节点组合行为、信号流、场景树交互

**典型**:玩家碰到道具后状态正确、状态机在固定输入序列下转移正确、UI 按钮触发场景切换

**方式**: GUT 场景测试

```gdscript
extends GutTest

func test_player_picks_up_coin() -> void:
    var player := preload("res://tests/scenes/test_player.tscn").instantiate()
    var coin := preload("res://tests/scenes/test_coin.tscn").instantiate()
    add_child_autofree(player)
    add_child_autofree(coin)
    coin.global_position = player.global_position
    await get_tree().process_frame
    assert_eq(player.coins, 1)
    assert_false(coin.is_inside_tree())
```

**不要做**:
- ❌ 拆成 N 个 mock 节点测"逻辑层假设"
- ❌ 把 UI/动画也塞进集成测试

### 7.3 体验层(手动 + 录制回放,**禁止自动测**)

**范围**:手感、节奏、视觉、声音、镜头

**为什么禁自动测**:主观、无 oracle、慢

**手动 checklist**(写到 PR 描述或 `notes.md`):
- [ ] 跳跃 10 次,手感到位
- [ ] 战斗 1 局(2 分钟),节奏合适
- [ ] 走完 1 关,无视觉 bug
- [ ] 听 1 局,BGM/SFX 平衡

**录制回放**(可选,适合反复打磨的循环):
- 录制 30 秒标准操作
- CI/本地回放,断言关键节点状态没退化(如血量>0)
- 不替代手动,只防回归

## 8. 性能基线(必须意识,不必须每次跑)

每改一处物理/动画,跑一次:
```powershell
godot --headless --quit-after 600 res://scenes/main.tscn
```
或在编辑器内看 Performance Monitor。

## 9. 静态检查(提交前必跑)

```powershell
godot --headless --check-only --script res://scripts/your_script.gd
```

## 10. 反模式(立即拒绝)

- ❌ `get_node("foo/bar")` 散落各处 → 用 `@onready`
- ❌ `export var x = 10`(无类型) → 必须 `@export var x: int = 10`
- ❌ `_process` 里做重活 → 缓存 / 移到 `_ready`
- ❌ 节点命名 `Node1` / `Node2` → PascalCase 描述性
- ❌ 跨场景 `get_tree().get_first_node_in_group()` 滥用 → 用 EventBus
- ❌ `preload("res://scenes/X.tscn")` 在 `_process` → 用 `@onready` 缓存
- ❌ 信号连接忘记断开 → 配对 `connect` / `disconnect`,或用一次性信号

## 11. 衔接

- 任务完成 → commit
- 一批完成 → `game-code-review`
- 出 bug → `systematic-debugging-2d`
