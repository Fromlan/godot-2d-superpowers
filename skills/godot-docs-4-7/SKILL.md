---
name: godot-docs-4-7
description: "Godot 4.7 约定与 API 模式。Use when 问到 Godot/GDScript、场景组合、信号、CharacterBody vs RigidBody、InputMap、@export/@onready/@rpc、Forward+/GI、AnimationTree/Tween、shader、多人、导出/插件。"
last_reviewed: 2026-09-10
---

<!-- argument-hint: [topic, framework name, or chapter number, e.g. 'signal', '@rpc', 'CharacterBody3D', 'ch07'] -->

# Godot 文档 4.7 (蒸馏参考)
**作者**:Godot Engine 贡献者(社区驱动,MIT)|**页数**:~1,679 spine items |**章节**:12 个主题 |**生成时间**:2026-08-01

## 怎么用这个 skill

1. 用 **Topic Index**(或 Chapter Index / cheatsheet / patterns / glossary)映射问题。
2. **回答前**:读完所有匹配的章节文件;yes/no 或矩阵决策也读 [cheatsheet.md](cheatsheet.md);recipe 类读 [patterns.md](patterns.md)。
3. **完成条件**:已读完那些文件,答案引用了相关 framework(仅 Core 不够)。

浏览:请求章节列表、`cheatsheet`、`patterns` 或 `glossary`。

## Core Frameworks & 心智模型

详见 [references/core-frameworks.md](references/core-frameworks.md),涵盖 Godot 4.7 15 个最常用的框架:组合优于继承、信号、action-based 输入、静态类型、@export/@onready、renderer 选择、body 矩阵、多人 @rpc、Resources、user:// 持久化、Tween、WorldEnvironment、@tool、autoload 边界、headless CI。

## Chapter Index

| # | 标题 | 关键框架 |
|---|-------|----------|
| [ch01](chapters/ch01-introduction-and-philosophy.md) | 介绍与设计哲学 | Scene/Node/Tree 组合、信号、all-inclusive package |
| [ch02](chapters/ch02-step-by-step-first-2d-3d.md) | 逐步:第一个 2D / 3D 游戏 | Player + Mob + Main + HUD 骨架;@onready & InputMap |
| [ch03](chapters/ch03-gdscript-overview.md) | GDScript 概述与语言参考 | 静态类型、@export / @onready / @rpc、class_name |
| [ch04](chapters/ch04-signals-resources-scenes.md) | 信号、资源与场景 | Signal flags、Resource、PackedScene.instantiate() |
| [ch05](chapters/ch05-best-practices.md) | 最佳实践与项目工作流 | Autoload、文件约定、VCS `.gitignore` |
| [ch06](chapters/ch06-2d-graphics-physics.md) | 2D 图形、工具与物理 | CanvasItem、TileMap、CharacterBody2D、layers/masks |
| [ch07](chapters/ch07-3d-graphics-physics.md) | 3D 图形、工具与物理 | Forward+/Mobile/Compatibility、NavigationAgent3D、LightmapGI |
| [ch08](chapters/ch08-shaders-audio-animation.md) | Shader、音频、动画 | .gdshader、AudioBus、AnimationTree/StateMachine、Tween |
| [ch09](chapters/ch09-rendering-materials.md) | 渲染、材质与光照 | WorldEnvironment、GI 模式、SubViewport、LOD |
| [ch10](chapters/ch10-inputs-ui-tween.md) | 输入、UI (Control)、Tween | InputMap actions、Container 布局、Tween 链 |
| [ch11](chapters/ch11-networking-files.md) | 多人、文件 | @rpc、Spawner/Synchronizer、FileAccess、uid:// |
| [ch12](chapters/ch12-editor-export-plugin.md) | 编辑器、导出、插件与调试 | EditorPlugin、--export-pack、@tool、performance monitor |

## Topic Index

所有 Topic 链接文件名保留英文(ch01-ch12 + glossary / cheatsheet / patterns 等)。简要说明:

- **2D body** → ch06
- **3D body** → ch07
- **`@onready`** → ch03
- **`@export` / `@export_range` / `@export_resource`** → ch03, ch10
- **`@rpc`** → ch11
- **`@tool`** → ch12
- **AnimationPlayer / AnimationTree** → ch08
- **Area2D / Area3D** → ch06, ch07
- **AudioStreamPlayer** → ch08
- **Autoloads** → ch05
- **`CanvasLayer`** → ch06, ch10
- **`CanvasModulate`** → ch06
- **CharacterBody2D / 3D** → ch06, ch07
- **`class_name`** → ch03, ch05
- **Collision layers / masks** → ch06, ch07
- **Compatibility renderer** → ch07, ch09
- **`CONNECT_DEFERRED`** → ch04
- **`CONNECT_PERSIST`** → ch04
- **`Container` (VBox/HBox/Grid)** → ch10
- **EditorPlugin** → ch12
- **ENet** → ch11
- **`export-pack`** → ch12
- **Forward+ renderer** → ch07, ch09
- **GI mode** → ch09
- **`@global` Constants** → ch03
- **High-level multiplayer** → ch11
- **InputMap actions** → ch10
- **`Input.get_vector`** → ch10
- **JSON save** → ch11
- **`LightmapGI`** → ch09
- **Material override** → ch09
- **Mobile renderer** → ch07, ch09
- **MultiplayerSpawner** → ch11
- **MultiplayerSynchronizer** → ch11
- **`move_and_slide`** → ch06, ch07
- **NavigationAgent3D** → ch07
- **`PackedScene`** → ch04
- **Path2D / Path3D** → ch02, ch07
- **Pixel-y retro games** → ch06
- **Pixel style shaders** → ch08
- **Plugins** → ch12
- **Project organization** → ch05
- **Render layers (2D)** → ch09
- **Resource (.tres)** → ch04, ch05
- **`res://` vs `user://`** → ch05, ch11
- **RigidBody2D / 3D** → ch06, ch07
- **ShaderMaterial** → ch08, ch09
- **Signals (typed)** → ch04
- **`Sprite2D` / `AnimatedSprite2D`** → ch06
- **StateMachine (AnimationTree)** → ch08
- **StaticBody2D / 3D** → ch06, ch07
- **`SubViewport`** → ch09
- **TileMap** → ch06
- **Tween** → ch08, ch10
- **`uid://`** → ch11
- **Variant** → ch03
- **`VoxelGI`** → ch09
- **WorldEnvironment** → ch09

## 辅助文件

- [glossary.md](glossary.md) — 每个关键术语按字母排序(Ch 引用)
- [patterns.md](patterns.md) — 15 个可复用 recipe 含权衡
- [cheatsheet.md](cheatsheet.md) — body 决策矩阵、layer-bit 约定、反模式表、tells-and-smells

## 作用域与限制

此 skill 覆盖 **Godot 4.7 参考**。它是 **引擎导向** — 不含项目特定业务逻辑、资源管线、或自定义编辑器工具。当问题漂移到你项目的细节,结合项目工具、项目的 CLAUDE.md、运行时检视。对 *本蒸馏外* 的内容(如移动平台签名、Steam 集成、主机 SDK),查官方文档 https://docs.godotengine.org 或相关供应商指南。
