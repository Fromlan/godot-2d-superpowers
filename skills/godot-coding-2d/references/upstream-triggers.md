---
name: upstream-triggers
description: "godot-coding-2d 第 1 节触发判据的扩展表:常见 15-20 个 2D Godot 任务场景 → 必读的 SKILL.md 清单。供父代理派子代理时按表填 message 中的'上游必读'字段。"
last_reviewed: 2026-09-11
---

# 上游必读触发表(常见场景 → 必读 SKILL.md)

> 本文件扩展 `godot-coding-2d/SKILL.md` 第 1 节触发判据表。父代理派子代理时,按"任务名"查本表,把"必读"列复制到 message 模板的 `skills/<X>/SKILL.md` 部分。

## 怎么用

1. 父代理拿到任务描述(如"写血条")
2. 在本表查"任务名"列最接近的一行
3. 把"必读"列里每个技能路径填进 message 模板:

```
Using godot-coding-2d to <purpose>. 上游必读: skills/<A>/SKILL.md, skills/<B>/SKILL.md, ... . 禁止绕过先读直接写代码。
```

4. 任何 GDScript 写出场景,**必须包含 `godot-gdscript-patterns`**

## 常见场景表

| # | 任务名 | 必读 SKILL.md(逗号分隔,按本表顺序) |
|---|--------|-------------------------------------|
| 1 | 写玩家 CharacterBody2D 移动 + 跳跃 | godot-2d-physics, godot-input-actions, godot-gdscript-patterns |
| 2 | 写玩家 RigidBody2D 物理(箱子、布偶) | godot-2d-physics, godot-gdscript-patterns |
| 3 | 写 Area2D 触发器(拾取、伤害区、终点) | godot-2d-physics, godot-gdscript-patterns |
| 4 | 写敌人 AI 状态机(FSM) | godot-gdscript-patterns, godot-animation, godot-2d-physics |
| 5 | 写帧动画(AnimatedSprite2D + SpriteFrames) | godot-animation, asset-pipeline, godot-gdscript-patterns |
| 6 | 写 AnimationPlayer 复杂动画(战斗动作、过场) | godot-animation, godot-gdscript-patterns |
| 7 | 写 AnimationTree 状态机(Boss、多状态角色) | godot-animation, godot-gdscript-patterns |
| 8 | 用 Tween 做 UI 反馈(闪烁、缩放、滑入) | godot-ui-best-practices, godot-animation, godot-gdscript-patterns |
| 9 | 写 UI Control 场景(主菜单、设置面板、HUD) | godot-ui-best-practices, godot-animation, godot-gdscript-patterns |
| 10 | 写按钮 + 信号处理(主菜单"开始"按钮) | godot-ui-best-practices, godot-gdscript-patterns |
| 11 | 写拖拽逻辑(棋子、卡牌、库存物品) | godot-ui-best-practices, godot-2d-physics, godot-gdscript-patterns |
| 12 | 写血条(进度条 + 数值变化 + 受伤闪红) | godot-ui-best-practices, godot-animation, godot-gdscript-patterns |
| 13 | 写音效播放(跳跃、命中、UI 点击) | godot-audio, asset-pipeline, godot-gdscript-patterns |
| 14 | 写 BGM 管理(autoload + 交叉淡入) | godot-audio, godot-gdscript-patterns |
| 15 | 写音量设置 UI + 持久化 | godot-audio, godot-ui-best-practices, godot-gdscript-patterns |
| 16 | 接入 InputMap action(跳跃、攻击、移动) | godot-input-actions, godot-gdscript-patterns |
| 17 | 加新资源(图、音、字体)或改导入设置 | asset-pipeline, godot-gdscript-patterns |
| 18 | 写关卡布局数据(LevelLayout + EntitySpawn) | level-data-flow, godot-gdscript-patterns |
| 19 | 加新关卡 / 调难度(改 .tres / JSON) | level-data-flow, godot-gdscript-patterns |
| 20 | 程序生成关卡(Roguelike 房间、波次) | level-data-flow, godot-gdscript-patterns |
| 21 | 写存档 / 读档(ConfigFile / user://) | godot-gdscript-patterns |
| 22 | 接入多人/网络(@rpc / MultiplayerSpawner) | godot-gdscript-patterns |
| 23 | 自定义 Shader / 着色器效果 | godot-docs-4-7, godot-gdscript-patterns |
| 24 | 优化帧率 / 性能基线 | godot-docs-4-7, godot-gdscript-patterns |

## 必读列的固定项

**任何** 2D GDScript 写出场景,`godot-gdscript-patterns` **永远在必读列**(本项目唯一权威源,覆盖静态类型、@export / @onready、Signal、Resource、autoload 边界、preload vs load)。

涉及动画、Tween、状态机的任何代码,`godot-animation` 在必读列。

涉及 UI / Control / HUD 的任何代码,`godot-ui-best-practices` 在必读列。

涉及移动 / 碰撞 / 物理 body 的任何代码,`godot-2d-physics` 在必读列。

涉及音频播放的任何代码,`godot-audio` 在必读列。

涉及 InputMap / 手柄 / 快捷键的任何代码,`godot-input-actions` 在必读列。

## 查不到的场景

新场景不在表 1-24?按以下顺序判断:

1. 关键词搜本表"任务名"列找最相近行
2. 看"必读"列首项是哪类技能(物理/动画/UI/音频/输入),同类的就是必读
3. `godot-gdscript-patterns` 必加
4. 加 / 改资源就加 `asset-pipeline`
5. 改关卡数据就加 `level-data-flow`

## 反模式

- ❌ 跳过 `godot-gdscript-patterns`——它是基础,任何 GDScript 都吃它的规范
- ❌ 漏读相关技能——写出违反规范的代码,后续 review 会标 Major
- ❌ 多读不相关技能(如写 UI 时读 2d-physics)——浪费 token,稀释注意力
- ❌ 子代理派发时漏写 message 模板,只在父代理回复里说"我会让子代理先读 X"——子代理看不到

## 维护

新增常见任务模式时,append 到表(不重排),编号递增;`last_reviewed` 字段同步刷新。