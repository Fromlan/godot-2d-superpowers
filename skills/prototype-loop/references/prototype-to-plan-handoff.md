---
name: prototype-to-plan-handoff
description: "prototype-loop 通过后,把 NOTES.md 的 @export 调参结果迁移到 game-writing-plans T1 任务的字段模板与规则。仅用于 prototype → 正式开发衔接,不替代任何已有技能。"
last_reviewed: 2026-09-11
---

# Prototype → Plan 衔接模板(NOTES.md 数值迁移)

> 本文件定义 prototype-loop 第 5 节"通过"路径的具体抽取规则与 game-writing-plans T1 字段填法。
> 与 `game-writing-plans/SKILL.md` 第 1 节计划模板配套使用。

## 1. 抽取范围(只抽这些,不抽这些)

| 抽 | 不抽 |
|----|------|
| `NOTES.md`"复盘"区每次 `@export` 调参的**最终值** | prototype 代码本身 |
| 字段名、单位、取值范围 | 程序化几何脚本 |
| 调试中得出的关键常量(重力、跳跃速度等) | 时间盒记录、临时笔记 |
| 单一变量验证的结论文字 | "好玩/不好玩"的主观描述 |

**反模式**:
- ❌ 把 prototype 的 `.gd` / `.tscn` 复制到正式项目
- ❌ 把"我想再玩一次"这种主观评论作为参数迁过去
- ❌ 把调参过程中的中间值(不是最终值)迁过去

## 2. NOTES.md"复盘"区标准格式

prototype-loop 已要求在 `NOTES.md` 底部写"复盘"。为方便抽取,推荐结构:

```markdown
## 复盘

### 调参记录(每次尝试的最终值)

- `JUMP_VELOCITY`: 380.0(单位 px/s,范围 300~450,起跳手感"轻→重"测试,第 5 次定)
- `MOVE_SPEED`: 220.0(单位 px/s,范围 180~260,横向速度,第 3 次定)
- `GRAVITY`: 980.0(单位 px/s²,默认 Godot 推荐值,未调)
- `SPAWN_RATE`: 1.5(单位 次/s,生成节奏测试,第 2 次定)

### 单一变量结论(选填)
- 起跳速度 ≤ 320 显得飘;≥ 420 显得重;380 是平衡点
- 移动速度 220 与跳跃 380 配合手感最自然

### 时间盒
- 开始: 14:00
- 截止: 16:00(实际用 90 分钟)
```

## 3. 抽取规则(逐条)

每条调参记录抽取 4 个字段:

| 字段 | 来源 | 必填 |
|------|------|------|
| `key` | `@export var` 名(如 `JUMP_VELOCITY`) | ✓ |
| `value` | 调参记录的"最终值"数字 | ✓ |
| `unit` | 括号里的"单位 px/s"等 | ✗(可省) |
| `range` | "范围 300~450"(如有) | ✗(可省) |
| `note` | "第 N 次定"或简短结论(选填) | ✗ |

**冲突时**:同一字段出现多次,以**最后一次"最终值"**为准。

## 4. game-writing-plans T1 参数字段填法

把抽取结果写到 plan 第一条任务的"参数"段:

```markdown
### T1. 写玩家移动脚本(10m)
**类型**: 脚本
**文件**:
  - 新建: `scripts/player.gd`
**前置**: T0
**参数**(来自 prototype-loop/NOTES.md):
  - `JUMP_VELOCITY = 380.0`(px/s,380 平衡点)
  - `MOVE_SPEED = 220.0`(px/s,220 移动 + 380 跳 配合最好)
  - `GRAVITY = 980.0`(px/s²,默认)
  - `SPAWN_RATE = 1.5`(次/s,第 2 次定)
**步骤**:
1. ...
**验证**:
- [ ] `scripts/run-tests.ps1` 通过
- [ ] `godot --headless` 启动主场景无错
- [ ] 手测: 起跳手感与 prototype 一致
```

## 5. 衔接校验清单(实施前 agent 自查)

把 NOTES.md 数值迁到 T1 之前,确认:

- [ ] NOTES.md"复盘"区有 4 行以上的"最终值"记录
- [ ] 每条记录符合"字段名 / 单位 / 范围"至少其中 1 个
- [ ] T1"参数"段每行 1 条,不堆在一行
- [ ] T1 任务的"验证"段含"手测: 起跳手感与 prototype 一致"(或其他与 prototype 对照项)
- [ ] prototype 代码**不复制**到正式项目

## 6. 衔接的失败模式

| 现象 | 根因 | 修复 |
|------|------|------|
| 正式版手感与 prototype 不一致 | 数值未迁或迁错 | 重读 NOTES.md 复盘区,逐字段比对 |
| 正式项目混入 prototype 代码 | agent 偷懒复制 .gd | 检查 git diff,删除 prototype 文件引用 |
| T1 任务粒度超 15 分钟 | 把"接入资产"等也写进 T1 | 拆 T2 = 接入资产 |
| "参数"段写成 narrative | 没有按 key=value 格式 | 重写为 4 字段结构 |
| prototype 中多次调同一字段 | 取了中间值 | 取最后一次"最终值" |

## 7. 衔接后的下游

T1 执行 → T2 → ... → 全批完成 → `game-code-review`(批量审查,不针对 prototype)