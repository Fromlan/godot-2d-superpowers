# Migration: from superpowers to godot-2d-superpowers

> 如果你已经在用 superpowers(obra/superpowers),本对照表帮你过渡。

## 技能映射

| superpowers | godot-2d-superpowers | 差异 |
|-------------|----------------------|------|
| `using-superpowers` | `using-game-dev` | 决策表加上 2D Godot 专有场景 |
| `brainstorming` | `game-brainstorming` | 加上 2D 类型 hook / 核心循环强调 |
| (无) | `gdd-author` | 继承自 godot-mcp-connector,自带 |
| (无) | `prototype-loop` | 新增,游戏独有 |
| `writing-plans` | `game-writing-plans` | 任务粒度 2-5m → 5-15m,加类型标签 |
| `test-driven-development` | `godot-coding-2d`(内含分层测试章节) | 改"全栈 TDD"为分层 |
| (无) | `asset-pipeline` | 游戏独有 |
| (无) | `level-data-flow` | 游戏独有 |
| `requesting-code-review` | `game-code-review` | 加上 Godot 反模式清单 |
| `systematic-debugging` | `systematic-debugging-2d` | 加上 2D 物理/动画/渲染专项 |
| `finishing-a-development-branch` | (同名,直接复用) | 完全相同 |
| (无) | `release-checklist-2d` | 游戏独有 |
| (无) | `godot-*` x7 | 知识库 |

## 使用建议

### 场景 A:从零开始

- 卸载 superpowers,只装本套件
- 本套件覆盖了 2D Godot 项目的所有 superpowers 能力,且更贴合

### 场景 B:同时用 superpowers + 本套件

- 可以共存(都通过 plugin.json 注册)
- 注意 `using-superpowers` 和 `using-game-dev` 都想当入口,会冲突
- 建议:**在 `AGENTS.md` 里强制指定用 `using-game-dev`**(本套件已做)
- 非 Godot 项目才退到 `using-superpowers`

### 场景 C:从 superpowers 改造而来

- 已写的设计文档、计划文档**不需要重写**
- 计划文档建议加 `<- parallel` / `<- sequential` / `<- review` 标签(本套件约定)
- 测试代码无需改,但建议把体验层手动测试从 CI 移到本地 checklist

## 主要工作流差异

### 任务粒度

- superpowers: 2-5 分钟
- 本套件: 5-15 分钟
- 原因:Godot 场景+资源耦合高,拆太细反而乱

### 测试策略

- superpowers: 强制 RED-GREEN-REFACTOR 一切
- 本套件:
  - 逻辑层:严格 TDD
  - 装配层:集成测试
  - 体验层:手动 + 录制回放

### 调度严格度

- superpowers: 强制("ABSOLUTELY MUST")
- 本套件: 准强制(关键点"必须",其他"建议")
- 原因:个人独立开发节奏灵活,过度约束会适得其反

## 升级路径

如果你的项目长大了(从个人 → 小团队),建议:

1. 升 `game-code-review` 严格度到"必做"
2. 加 GitHub Actions 模板(`tests/ci.yml`)
3. 把 `release-checklist-2d` 拆给专门 release engineer
4. 引入 `requesting-code-review` 风格的多人 review

届时本套件可能不够,考虑回到 superpowers 或写 godot-team-superpowers。
