---
name: using-game-dev
description: "在 2D Godot 项目上开始任何对话时使用 — 建立如何查找和使用游戏开发技能的方式,在任何回复(包括澄清问题)前要求调用技能。"
last_reviewed: 2026-09-11
---

<!-- argument-hint: none (this skill is the dispatcher; pick a skill from the decision table) -->

# 使用游戏开发超能力 (2D Godot)

> 调度入口。**所有会话的第一步**:读这个 SKILL.md,查决策表,再行动。

## The Rule

**按决策表查技能,在任何回复或动作前先调用** — 包括澄清问题、探索代码、查文件。

- **关键检查点(必须)**:有明文标 "必须" 的流程类技能不能跳过(测试、review、调试、发布前的 review)。
- **路径选择(建议)**:prototype 选做、scale fence 自由,但用户可以显式说"这次跳过 X"覆盖。
- **默认 vs 显式**:有合理默认,但用户显式覆盖必须明确记录。

**进入 plan 模式前**:若还未 brainstorming,先调 `game-brainstorming`。

然后公告 "Using [skill] to [purpose]" 并严格按技能执行。如有 checklist,每条建一个 todo。

## Decision Table (必须先查,再行动)

| 用户输入特征 | 调用的技能 | 顺序 |
|last_reviewed: 2026-09-11
--------------|------------|------|
| "我想做一款..." / 想法/概念/无 GDD | `game-brainstorming` | 1 |
| "帮我写 GDD" / "写设计文档" / "GDD review" | `gdd-author` | 1 |
| "核心循环" / "原型" / "试一下感觉" / "playtest" | `prototype-loop` | 1 |
| | 通过 → `game-writing-plans`(中间不走 `game-code-review`) | — |
| GDD 已批准,开始开发 / "实现 X" | `game-writing-plans` → `godot-coding-2d` | 1→2 |
| 添加素材 / 换图片 / 改音效 / 字体 / 动画 | `asset-pipeline` | 1 |
| 改关卡 / 加关 / 章节数据 | `level-data-flow` | 1 |
| 报 bug / 现象是... / 性能差 / 帧率低 | `systematic-debugging-2d` | 1 |
| 完成一批任务 / "review 一下" | `game-code-review` | 1 |
| 任务全完,准备合 / "merge 吧" | `finishing-a-development-branch` | 1 |
| 准备发布版本 / "打个包" / "导出" | `release-checklist-2d` | 1 |
| Godot API / GDScript 语法 / 节点用法 | `godot-docs-4-7` | 1 |
| 物理/碰撞/移动/CharacterBody2D | `godot-2d-physics` | 1 |
| AnimationPlayer/AnimatedSprite2D/Tween | `godot-animation` | 1 |
| 音频/音乐/SFX/AudioStreamPlayer | `godot-audio` | 1 |
| GDScript 风格/静态类型/Resource/信号 | `godot-gdscript-patterns` | 1 |
| InputMap/Action/手柄/快捷键 | `godot-input-actions` | 1 |
| UI/Control/CanvasLayer/布局 | `godot-ui-best-practices` | 1 |
| 查不到 | 列出 2-3 个最可能命中的候选,问用户选哪个 | — |
| 输入明显是 3D / 非 Godot 项目 | **主动告知用户本套件不适用**,问是否继续 | — |

## Skill Priority (组合调用顺序)

当多个技能同时命中,**流程类技能先于知识类技能**:

1. 流程类(决定怎么走):`game-brainstorming` → `gdd-author` → `prototype-loop` → `game-writing-plans` → `systematic-debugging-2d` → `game-code-review` → `asset-pipeline` → `level-data-flow` → `finishing-a-development-branch` → `release-checklist-2d`
2. 知识类(回答具体技术问题):`godot-*` 7 个

例:
- "我想做一款平台跳跃,跳跃手感不对" → `game-brainstorming`(先确认设计)→ `systematic-debugging-2d`(查手感问题)→ `godot-2d-physics`(给具体技术)
- "加一个跳跃音效" → `asset-pipeline`(资源命名/导入)→ `godot-audio`(AudioStreamPlayer 用法)
- "给敌人写个 AI" → `gdd-author`(若有 AI 规则)→ `game-writing-plans`(拆任务)→ `godot-coding-2d`(TDD 状态机)

## Red Flags (这些想法 = 你在给自己找借口)

| 想法 | 现实 |
|------|------|
| "这只是简单问题,不需要技能" | 决策表里查不到才简单,查到了就走流程 |
| "我先看眼代码再决定" | 流程类技能告诉你**怎么**探索,先调流程技能 |
| "GDScript 我懂,直接写" | 知识技能 `godot-gdscript-patterns` 里有项目约定的具体规范,先读它 |
| "我先把整个项目扫一遍" | `game-brainstorming` 决定是否值得扫,先调它 |
| "用户没说要测试" | 流程类技能里有"何时必须测试"的检查点,不是用户决定的 |
| "这次跳过计划,简单任务" | 写计划可以很短(1 个任务),但不能跳过 |
| "我先把 GDD 写完再调技能" | `gdd-author` **就是**技能,先调它 |

## Process vs Knowledge (再次强调)

- **流程类技能** = 改变你**怎么工作**(何时拆任务、何时测试、何时发布)
- **知识类技能** = 告诉你**具体技术是什么**(API 用法、最佳实践)
- 二者**不互斥**:流程类会指引你读哪些知识类

## 用户指令优先

User instructions (CLAUDE.md, AGENTS.md, 直接请求) > skills > default behavior.
**只有用户显式说"这次跳过 X"**,才允许跳过技能。否则按决策表走。

## Subagent Dispatch

如果你是作为子代理被派发执行特定任务,可以跳过 `using-game-dev` 查询 — 前提是父代理已经把你路由到具体技能。否则仍查决策表。

## Scope (作用域)

- 覆盖:2D Godot 项目(平台跳跃/动作/解谜/卡牌/roguelike/塔防/清版等)
- 不覆盖:3D Godot、Unity、Unreal、GameMaker、其他引擎
- **强提示**:本套件只覆盖 2D Godot;遇到 3D / 非 Godot 项目,**必须先告知用户再行动**,不允许默默绕过
- 遇到非 2D Godot 项目:明确告知用户本套件不适用,问是否要继续
