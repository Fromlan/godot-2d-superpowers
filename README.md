# Godot 2D Superpowers

> 一套面向 **2D Godot 独立开发者**的工作流技能集。把 AI 编程助手从一个会写代码的工具,变成一个会按游戏开发节奏推进的协作伙伴。

## 设计理念与哲学

本套件围绕五件事建立:

1. **流程优先于工具**。"我想做一款游戏"必须先走头脑风暴 → GDD → 原型 → 计划 → 实现,而不是直接动手写代码。技能先调度,代码后写。
2. **强制但不过度**。关键检查点(测试、review、调试、发布)是硬性的;其他给余地。个人项目的节奏不该被流程碾碎。
3. **分层测试,一刀切是错的**。逻辑层严格 TDD,装配层集成测试,体验层(手感、节奏、声音)手动 + 录制回放。游戏代码不是普通业务代码,强制 RED-GREEN-REFACTOR 一切只会写出无意义的 mock。
4. **任务粒度匹配引擎**。5-15 分钟而不是通用敏捷的 2-5 分钟。Godot 场景 + 资源耦合度高,拆太细反而乱。
5. **2D 优先,3D 让路**。所有编码规范、调试清单、测试策略针对 2D 物理/动画/UI 优化。本套件不接管 3D Godot 项目;遇 3D 项目会先告知并问是否继续。

更深的论述见 [`docs/philosophy.md`](docs/philosophy.md)。

## 包含什么

**19 个技能** 分两类:

- **12 个工作流/调度型技能**(本套件新增或重塑,带工作流)
- **7 个 Godot 知识型技能**(从 godot-mcp-connector 搬运,纯参考)

| 阶段 | 技能 |
|------|------|
| 调度 | `using-game-dev` |
| 设计 | `game-brainstorming`, `gdd-author`, `prototype-loop` |
| 实现 | `game-writing-plans`, `godot-coding-2d`, `asset-pipeline`, `level-data-flow` |
| 质量 | `game-code-review`, `systematic-debugging-2d`, `finishing-a-development-branch` |
| 交付 | `release-checklist-2d` |
| 知识 | `godot-docs-4-7`, `godot-2d-physics`, `godot-animation`, `godot-audio`, `godot-gdscript-patterns`, `godot-input-actions`, `godot-ui-best-practices` |

## 安装

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

## 典型操作流程

日常使用**不需要手动调用技能**——agent 会自动读 `using-game-dev` 的决策表,根据你的输入触发对应技能。一个典型会话:

1. 你说:"我想做一款 2D 平台跳跃,跳跃手感要好"
2. agent 自动调 `game-brainstorming`,引导你产出**概念包**(hook + 支柱 + 核心循环 + 体量)
3. 概念 OK 后,自动接 `gdd-author` 写 GDD
4. GDD 批准后,`game-writing-plans` 拆任务 → `godot-coding-2d` 逐任务执行(逻辑层 TDD、装配层集成测试)
5. 任务批次完成 → `game-code-review` 审查
6. 报 bug → `systematic-debugging-2d` 四阶段根因
7. 改资源 → `asset-pipeline`;加关卡 → `level-data-flow`
8. 准备发布 → `release-checklist-2d`(会自动跑 `verify-godot-claims.ps1` 对照官方文档核对)

**关键检查点(必须)**:测试、review、调试、发布前必走对应技能。其他可自由跳过,但要在回复里明确记录"这次跳过 X"。

决策表里查不到的输入,agent 会列 2-3 候选技能让你选,不直接干活。

## 样例项目

`example-game/` 是一个最小可跑的 2D 平台跳跃:

- 玩家移动 + 跳跃 + 收集物
- 一个简单敌人(巡逻 + 碰撞伤害)
- 主菜单 + 游戏场景 + 死亡重开
- GUT 测试覆盖逻辑层(状态机 / 伤害公式)
- `scripts/run-tests.ps1` 一键验证

## 文档

- [`docs/workflow.md`](docs/workflow.md) — 流程图与决策树
- [`docs/philosophy.md`](docs/philosophy.md) — 详细设计理念
- [`docs/migration-from-superpowers.md`](docs/migration-from-superpowers.md) — 从 superpowers 迁移对照表

## 许可

MIT(本仓库新增内容);godot-mcp-connector 搬运部分保留其原始许可。

## 致谢

设计骨架来自 [obra/superpowers](https://github.com/obra/superpowers);7 个 Godot 知识技能搬运自 [godot-mcp-connector](https://github.com/Fromlan/godot-mcp-connector)。详细迁移对照见 [`docs/migration-from-superpowers.md`](docs/migration-from-superpowers.md)。