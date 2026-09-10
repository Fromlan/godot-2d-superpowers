# Game Dev Superpowers for 2D (Godot)

> 一套仿照 [obra/superpowers](https://github.com/obra/superpowers) 的技能集合,专门面向 **2D Godot 个人独立开发**。
> 装上之后,你的 Codex Desktop / Claude Code 会被强制调度,沿游戏开发全生命周期推进。

## 包含什么

**20 个技能** 分两类:

- **12 个工作流/调度型技能**(本套件新增,带工作流)
- **8 个 Godot 知识型技能**(从 [godot-mcp-connector](https://github.com/Fromlan/godot-mcp-connector) 搬运,纯参考)

| 阶段 | 技能 |
|------|------|
| 调度 | `using-game-dev` |
| 设计 | `game-brainstorming`, `gdd-author`, `prototype-loop` |
| 实现 | `game-writing-plans`, `godot-coding-2d`, `asset-pipeline`, `level-data-flow` |
| 质量 | `game-code-review`, `systematic-debugging-2d`, `finishing-a-development-branch` |
| 交付 | `release-checklist-2d` |
| 知识 | `godot-docs-4-7`, `godot-2d-physics`, `godot-animation`, `godot-audio`, `godot-gdscript-patterns`, `godot-input-actions`, `godot-ui-best-practices` |

## 30 秒快速开始

### Codex Desktop

1. 打开 Codex 桌面 app
2. 侧边栏 **Plugins** → 搜索 `godot-2d-superpowers` → 点 `+` 安装
3. 在任意会话开头说"做一个 2D 平台跳跃游戏",agent 会自动调 `game-brainstorming`

### Claude Code

```bash
/plugin marketplace add https://github.com/Fromlan/godot-2d-superpowers
/plugin install godot-2d-superpowers
```

### 本地试用(克隆即用)

```bash
git clone https://github.com/Fromlan/godot-2d-superpowers.git
# 然后把仓库根的 AGENTS.md 软链接/复制到你的 Godot 项目里
```

## 核心设计

- **强制调度**:`AGENTS.md` / `CLAUDE.md` bootstrap 强制 agent 读 `using-game-dev` 决策表
- **流程闭环**:头脑风暴 → GDD → 原型 → 计划 → 实现(分场景/资源/脚本) → 审查 → 调试 → 收尾 → 发布
- **2D 优先**:所有编码规范、测试策略、调试清单针对 2D 物理/动画/UI 优化
- **分层测试**:逻辑层严格 TDD,装配层集成测试,体验层手动+录制回放
- **个人友好**:任务粒度 5-15 分钟,样例项目开箱即跑

## 样例项目

`example-game/` 是一个最小可跑的 2D 平台跳跃:

- 玩家移动 + 跳跃 + 收集物
- 一个简单敌人(巡逻+碰撞伤害)
- 主菜单 + 游戏场景 + 死亡重开
- GUT 测试覆盖逻辑层(状态机/伤害公式)
- `scripts/run-tests.ps1` 一键验证

## 文档

- `docs/workflow.md` — 流程图与决策树
- `docs/philosophy.md` — 设计理念
- `docs/migration-from-superpowers.md` — 从 superpowers 迁移对照表

## 许可

MIT(本仓库新增内容);godot-mcp-connector 搬运部分保留其原始许可。
