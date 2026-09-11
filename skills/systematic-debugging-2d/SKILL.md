---
name: systematic-debugging-2d
description: 当用户报告 2D Godot 项目中的 bug、性能问题或意外行为时使用,或说「有 bug」/「现象是...」/「帧率低」/「卡顿」。4 阶段根因分析流程,针对 2D 物理、动画、渲染问题专项。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [physics | animation | rendering | performance | logic] -->

# 系统化调试 2D (Godot)

> 4 阶段根因分析,专门针对 2D Godot 常见问题类型。
> 走完本技能,产出"症状 → 假设 → 验证 → 修复 → 防御"的完整链条。

## 0. 路由(单题)

| 选项 | 走法 |
|------|------|
| **A. 物理 / 碰撞** | 走 4.1 物理专项 |
| **B. 动画** | 走 4.2 动画专项 |
| **C. 渲染** | 走 4.3 渲染专项 |
| **D. 性能 / 帧率** | 走 4.4 性能专项 |
| **E. 逻辑 / 状态** | 走标准 4 阶段 |

## 1. Phase 1 — 复现(必须稳定)

- **最小复现**: 5-10 步内能复现的最短路径
- **可重复**: 100% 出现,非偶发
- **可观测**: 写下来"现象 A → 操作 B → 结果 C"
- **不修任何东西**,先把复现路径固化

输出到 debug/<issue-id>/REPRO.md:

```
## 复现路径
1. 启动游戏,加载 level_01
2. 走到第三屏
3. 跳到平台上
→ 玩家穿过平台,落到坑里

## 期望
玩家落在平台上

## 实际
玩家下落,无碰撞
```

## 2. Phase 2 — 假设(列至少 3 个)

针对 2D 常见根因,列假设清单:

**物理相关**:
- collision_layer / collision_mask 不匹配
- CollisionShape 形状不对(Rectangle / Circle / Capsule)
- 玩家 CharacterBody2D 但子节点是 Area2D
- move_and_slide 返回 false 但代码当 true 用

**动画相关**:
- 帧动画用了 AnimationPlayer(反之亦然)
- animation.finished 没连,看起来"卡住"
- 帧率不匹配,看起来"加速/减速"

**渲染相关**:
- z_index / z_as_relative 设置冲突
- CanvasLayer 没隔离 HUD
- 像素艺术开了 Linear Filter,糊

**性能相关**:
- _process 里调 get_tree().get_nodes_in_group()
- 信号没断开,旧节点累积
- 大纹理未压缩,显存爆炸

**逻辑相关**:
- 状态机转移条件不互斥
- 初始化顺序依赖(在 `_enter_tree` / 父节点 `_ready` 之前访问 `@onready` 节点)
- preload 路径不存在,运行时报错

## 3. Phase 3 — 验证(逐个排除)

对每个假设,做最小验证:

**关键原则**: **一次只改一个变量**。改完跑复现。

例(碰撞问题):

| 假设 | 验证 | 结果 |
|------|------|------|
| collision_layer 不匹配 | 打印双方 mask | ✗ 匹配 |
| CollisionShape 形状不对 | 临时换 Rectangle | ✗ 仍穿过 |
| move_and_slide 返回处理 | 加 assert | ✗ 正常 |
| 子节点是 Area2D | 检查场景树 | ✓ 找到了 |

**找到根因** → 进 Phase 4
**未找到** → 加新假设,回 Phase 2

## 4. Phase 4 — 修复 + 防御

### 4.1 修复(最小改动)

- **最小 diff**,只改根因
- 不顺手"重构"其他代码
- 不"为以后准备"加新东西

### 4.2 加测试(逻辑层必须)

如果根因在逻辑层 → 写 GUT 测试覆盖,**确保不回归**

### 4.3 加防御(可选但推荐)

- assert / 显式检查: 防同类错误
- 文档: 在 godot-coding-2d 或对应技能加 "踩坑" 条目
- 日志: 关键节点状态打点

## 5. 4 类专项检查

### 4.1 物理专项(2D 高频)

```
□ CharacterBody2D 而不是 RigidBody2D 做角色?
□ CollisionShape2D 子节点形状正确?
□ collision_layer 显式设(不是 layer 1 默认)?
□ collision_mask 显式设?
□ move_and_slide 用了,不是 move_and_collide?
□ 速度单位是 pixel/sec(不是 pixel/frame)?
□ 物理过程用 _physics_process(不是 _process)?
□ 地面检测用 raycast 或 Area2D,不是 is_on_floor() 误用?
□ Input.get_action_strength vs is_action_pressed 选择对?
```

### 4.2 动画专项

```
□ AnimatedSprite2D 用 SpriteFrames 资源(.tres)?
□ AnimationPlayer 用 AnimationLibrary 资源?
□ 帧率一致(8/12/24/30 fps)?
□ animation.finished 信号连接正确?
□ Queue 替代 play 处理切换?
□ 动画资源不内联在脚本?
□ Animation 名小写 snake_case?
```

### 4.3 渲染专项

```
□ 像素艺术 texture_filter = Nearest?(节点/项目 `canvas_textures/default_texture_filter`,不是 `.import` 的 texture/filter)
□ mipmaps/generate = false?(`.import` 键)
□ 节点 z_index 显式设?
□ CanvasLayer 用于 HUD 不参与场景变换?
□ 视口拉伸设置 vs 美术分辨率一致?
□ 视口(1920x1080) vs 美术(320x180)缩放策略?
```

### 4.4 性能专项

```
□ _process 函数轻?
□ get_tree().get_nodes_in_group() 不每帧调?
□ 节点 @onready 缓存?
□ 信号 vs 轮询?
□ 大量生成/销毁用对象池?
□ 纹理压缩合理?
□ Physics Layers 数量不爆?
□ _draw 重绘节制?
```

## 6. 何时停下来问用户

- 复现路径不稳定(100 次复现 50 次成功) → 问"是否环境相关"
- 假设都排除仍找不到 → 问"是否最近改了什么"
- 性能问题,改了一通无改善 → 回 Phase 3 加性能 profile

## 7. 反模式

- ❌ "先 try 一改" → 必须 Phase 3 验证假设
- ❌ "我猜是 X" → 猜要变成可验证假设
- ❌ 一次改 5 个变量 → 一次改一个
- ❌ 修完不复现 → 修完必须跑原始 REPRO
- ❌ 不写测试 → 逻辑层根因必加 GUT 测试

## 8. 衔接

- 修完 → 跑 `scripts/run-tests.ps1` + 原始 REPRO
- 模式性问题 → 加进 `godot-coding-2d` 防同类
- 文档问题 → 同步到对应技能 SKILL.md
