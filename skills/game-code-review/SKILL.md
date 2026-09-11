---
name: game-code-review
description: "一批实现任务完成、或准备合并功能分支、或用户说"review 一下"/"看看代码"时使用。两阶段审查:规格合规(对照计划/GDD)和 Godot 代码质量(反模式)。按严重度报告问题,仅关键问题阻塞。"
last_reviewed: 2026-09-11
---

<!-- argument-hint: [batch | feature | full-game] -->

# 游戏代码审查 (2D Godot)

> 对一批完成的实现任务做两阶段审查:
> 1. **规格合规**:代码是否做了计划要它做的事
> 2. **代码质量**:是否符合 Godot 2D 项目规范
> 走完本技能,产出"按严重度分级、关键问题阻塞推进"的审查报告。

## 0. 何时用

- 一批任务(game-writing-plans 一次 dispatch 出来的)完成
- PR/分支准备合
- 关键改动后(改了 project.godot、加了资源)

**不调本技能**:
- prototype 阶段 → 不调本技能。`prototype-loop` 第 5 节"通过"路径跳 review,直接进 `game-writing-plans`
- prototype 任务的代码留在 `prototype/` 目录,非正式交付

## 1. 工作流

### Stage 1 — 规格合规(必须先做)

读 plans/<feature>.md,逐任务对账:

```markdown
| 任务 | 计划要求 | 实际产出 | 偏差 |
|last_reviewed: 2026-09-11
------|----------|----------|------|
| T1 | 写 player.gd 含跳跃 | ✓ | — |
| T2 | 在 main.tscn 接入 | ⚠️ 用了不同节点名 | 中 |
| T3 | GUT 测试 | ✗ 缺失 | 高 |
```

**任何"高"偏差** = 阻塞,必须回到 godot-coding-2d 修复。

### Stage 2 — 代码质量(按规范清单)

按下列清单逐项过一遍,**只标记问题,不重写**。

## 2. 严重度分级

| 级别 | 含义 | 动作 |
|------|------|------|
| **🔴 Critical** | 阻塞合入:破坏功能、性能严重退化、引入 bug、违反安全 | 必须修 |
| **🟡 Major** | 应当修:违反项目规范、缺测试、缺文档、扩展性差 | 本批修 |
| **🟢 Minor** | 可修可不修:命名不一致、注释缺失、风格小问题 | 下批修或忽略 |
| **ℹ️ Nit** | 纯建议:重排、措辞、可读性 | 自由 |

## 3. Godot 2D 审查清单(按主题分组)

### 3.1 静态类型与 GDScript 风格

- [ ] 所有 @export 有显式类型
- [ ] 所有 @onready 有显式类型
- [ ] 公共函数有返回类型
- [ ] 无 `var x = 5` 这种无类型变量(除非要刻意)
- [ ] 命名遵循:常量 UPPER_SNAKE,类 PascalCase,变量/函数 snake_case

### 3.2 场景树

- [ ] 场景树深度 ≤ 4 层
- [ ] 节点命名 PascalCase 描述性,无 Node / Node2 这种
- [ ] @onready 节点引用集中放在文件顶部
- [ ] 不用 get_node("path") 散落
- [ ] 节点引用有显式类型

### 3.3 信号

- [ ] 谁的状态变化,谁发信号
- [ ] 信号命名过去时
- [ ] 跨场景广播用 EventBus(单例)
- [ ] 同一项目内连接方式一致(全 .tscn 或全 .gd)
- [ ] 配对 connect/disconnect 或用一次性信号

### 3.4 资源

- [ ] 数据用 Resource 子类,不裸 Dictionary
- [ ] 资源用 uid://(4.4+)
- [ ] 资源命名: <scope>_<subject>.<ext>
- [ ] 资产有 ATTRIBUTION(版权)

### 3.5 物理(2D 重点)

- [ ] CharacterBody2D 配合 move_and_slide,不用 RigidBody 做角色
- [ ] Area2D 用于触发器,不参与物理模拟
- [ ] collision_layer / collision_mask 显式设置,不靠默认
- [ ] 物理 tick 频率合理(默认 60Hz)
- [ ] 移动函数抽成纯函数(便于测试)

### 3.6 动画

- [ ] SpriteFrames 用于帧动画
- [ ] AnimationPlayer 用于非帧动画
- [ ] Animation 名小写 snake_case
- [ ] 动画资源不内联在脚本,存 .tres
- [ ] 帧序列用零填充命名

### 3.7 性能(2D 重点)

- [ ] 不用 get_tree().get_nodes_in_group() 每帧调用
- [ ] 信号比轮询优先
- [ ] 节点缓存(@onready)
- [ ] 大量生成/销毁用对象池
- [ ] 大纹理压缩合理
- [ ] _process 不做重活

### 3.8 测试覆盖(按 godot-coding-2d 分层)

**前置条件**:仅适用于 `game-writing-plans` 派出的任务批。`prototype-loop` 任务不检测试覆盖(prototype 阶段无 TDD,见 `prototype-loop/SKILL.md` 第 1 节原则 5)。

- [ ] 逻辑层有 GUT 测试
- [ ] 装配层有集成测试
- [ ] 体验层有手测 checklist
- [ ] 测试和实现一同提交(同 commit 或相邻 commit)

### 3.9 Git 与工作流

- [ ] 每个任务 = 1 个 commit
- [ ] commit message 含任务 ID
- [ ] 无遗留 print() 调试输出
- [ ] 无遗留注释掉的代码
- [ ] 无 .import / .godot/ 提交

## 4. 输出格式

写到 reviews/<date>-<feature>.md:

```markdown
# Review: <feature-name> (<date>)

## 总结
- 规格合规: <通过/有偏差>
- 代码质量: <优/良/可/差>
- 阻塞项: <N>
- 建议项: <N>

## 规格合规
| 任务 | 状态 | 备注 |
|------|------|------|
| T1 | ✓ | — |
| T2 | ⚠️ | ... |

## 代码质量
### 🔴 Critical(<N> 项)
- [文件:行号] 问题描述
  - 建议: ...

### 🟡 Major(<N> 项)
...

### 🟢 Minor / ℹ️ Nit
...

## 决定
- [ ] 通过,可合入
- [ ] 需修 Critical,修完重审
- [ ] 需修 Major,合入前修
- [ ] Minor 记入 backlog
```

## 5. 反模式(审查时拒绝)

- ❌ "我手动测过了,不用测试" → 逻辑层必须有 GUT
- ❌ "代码能跑就行" → 必须过清单
- ❌ "样式问题不重要" → 至少标 Minor
- ❌ "性能再优化" → 至少标 Major
- ❌ 审查不写具体文件:行号 → 不可操作

## 6. 衔接

- 通过 → 继续下一批 / finishing-a-development-branch
- 阻塞 → 回 godot-coding-2d 修复
- 模式性问题(反复出现同一反模式)→ 考虑加进 godot-coding-2d 或 godot-gdscript-patterns
