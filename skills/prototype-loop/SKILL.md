---
name: prototype-loop
description: "当用户已批准 GDD 的核心循环,想在全面实现前验证"手感",或说"原型"/"试一下感觉"/"playtest this"时使用。Godot 2D 专项:极简场景、极简美术、脚本驱动验证、时间盒迭代。"
last_reviewed: 2026-09-11
---

<!-- argument-hint: [core-loop | mechanic | full-game] -->

# 原型循环 (2D Godot)

> 验证**核心循环是否好玩**的工作流。不是写"完整游戏",而是写"最小可玩切片"。
> 走完本技能,产出"能跑 2 分钟、让人知道这游戏大致感觉"的 `prototype.tscn`。

## 0. 何时用 / 何时不用

**用**:
- GDD 已批准,核心循环已定
- 想验证"跳跃手感"、"射击节奏"、"战斗循环"
- 不确定某机制是否好玩(代价低,先验证再写 GDD)
- A/B 候选机制对比

**不用**:
- 还没 GDD → 先 `game-brainstorming` / `gdd-author`
- 已经进入正式开发 → 直接 `game-writing-plans`
- 美术/UI 验证 → 这不是循环验证,用 `asset-pipeline`
- 原型关卡用程序化几何(ColorRect / StaticBody2D / CollisionShape2D),**不写 LevelLayout、`.tres`、`@export var data: Resource`** — 这些都属 `level-data-flow` 正式开发范畴

## 1. 原则(必须遵守)

1. **丑但能跑**:程序化几何(矩形 / 圆形 / Label)代替美术,只求能玩
2. **可丢弃**:原型代码**不进正式项目**,放到 `prototype/` 目录或独立分支
3. **时间盒**:1 个原型 ≤ 2 小时,超过就砍范围,不追加
4. **单一变量**:一次只验证一个机制,其他全部用最简实现
5. **手测驱动**:原型阶段无 TDD,靠"自己玩过去"判断

## 2. 工作流(5 步)

### Step 1 — 圈定变量(必填)

写 `prototype/NOTES.md`:

```markdown
# 原型: <机制名>

## 验证的问题
- 这手感对吗?
- 这节奏玩家会腻吗?
- 这难度梯度合理吗?

## 单一变量
- 本次只改: <X>
- 其他保持: 矩形玩家 + 矩形敌人 + 1 个关卡

## 验收标准
- [ ] 玩 10 次, <X%> 觉得好玩
- [ ] 录制 30 秒,看动作流畅
- [ ] 朋友试玩 1 次,反馈"想再玩"

## 时间盒
- 开始: __:__
- 截止: __:__ (≤ 2 小时)
```

### Step 2 — 最小场景

在 `prototype/` 下创建:
- `prototype.tscn` — 单场景,只放必要节点
- `scripts/prototype_player.gd` — 玩家(矩形 + CharacterBody2D)
- `scripts/prototype_enemy.gd` — 敌人(占位)
- `scripts/prototype_main.gd` — 场景根脚本,管游戏循环

**禁止**:
- ❌ 写 Resource / 信号总线 / 全局管理器
- ❌ 用正式项目的脚本文件
- ❌ 添加任何"为以后准备"的代码

### Step 3 — 调参优先于重构

- 所有数值(`JUMP_VELOCITY`、`MOVE_SPEED`、`SPAWN_RATE`)写成 `@export`
- 改了就跑,跑完就改
- 不做"先抽象再调"
- 调参记录: `@export var current_attempt: int` + 注释哪次改成多少

### Step 4 — 录制 + 复盘

每次跑 30 秒,问:
- 我(开发者)觉得好玩吗?
- 这感觉我想再玩一次吗?
- 哪个瞬间最爽 / 最不爽?
- 玩家会卡在哪? 多久会腻?

写到 `prototype/NOTES.md` 底部"复盘"区。

### Step 5 — 决策(三选一)

| 结果 | 动作 |
|last_reviewed: 2026-09-11
------|------|
| **A. 通过** | 把数值带进 `game-writing-plans`,原型代码扔掉 |
| **B. 局部调** | 改 `NOTES.md` 的"单一变量",再做 1 个原型(共 ≤ 2 个) |
| **C. 失败** | 回 `game-brainstorming` 重审核心循环,或回 `gdd-author` 改机制 |

**关键**:不要带"先做了再说"心态进正式项目。每个原型都是**可丢弃**的。

## 3. 反模式(禁止)

- ❌ "我顺便加了存档系统" → 偏离单一变量
- ❌ "我重构成正式架构了" → 原型不重写,只调参
- ❌ "美术先用开源的" → 程序化几何即可
- ❌ "我优化到 60 FPS 了" → 原型不优化
- ❌ "我加了个测试" → 原型无 TDD

## 4. 工具支持

- **程序化角色**: `ColorRect` + `CharacterBody2D` 即可
- **程序化敌人**: `Sprite2D` + 简单巡逻脚本
- **关卡边界**: `StaticBody2D` + `CollisionShape2D` (Rectangle)
- **调试输出**: `print()` 在控制台
- **录制**: Windows 自带录屏(Game Bar: Win+G),或 OBS
- **输入**: 直接读 `Input.is_action_pressed`,不写 InputMap(原型阶段)

## 5. 衔接(prototype → plan,NOTES.md 数值迁移)

**通过**:
1. 从 `prototype/NOTES.md` 的"复盘"区抽取每次 `@export` 调参的**最终值**
   - 字段名、单位、取值范围
   - 模板与字段定义见 `references/prototype-to-plan-handoff.md`
2. 把抽取结果作为 `game-writing-plans` 第一条任务(T1)的**"参数"**字段
3. prototype **代码全部留在 `prototype/` 目录,不复制到正式项目**(只迁"参数",不迁代码)
4. 跳 `game-code-review`(prototype 是"丑但能跑",非正式交付,不走审查)

**失败 / 部分通过**:
- 失败 → 回 `game-brainstorming` 或 `gdd-author`
- 部分通过 → 决定保留哪些机制,删哪些,然后回到上面"通过"路径
