# Game Dev Workflow (2D Godot)

> 整套技能的生命周期视图。
> 配合 `using-game-dev/SKILL.md` 的决策表使用。

## 阶段总览

```
[想法/概念]
    ↓ game-brainstorming
[概念包: hook + 支柱 + 核心循环 + 平台/体量]
    ↓ gdd-author
[GDD: 全档 / lean / one-pager]
    ↓ prototype-loop (选做,推荐)
[原型: 验证手感,2 小时可丢]
    ↓ game-writing-plans
[计划: 5-15 分钟任务列表]
    ↓ godot-coding-2d (TDD 逻辑层 + 装配层集成 + 体验层手动)
[实现: 一批一批]
    ↓ game-code-review
[审查: 规格合规 + 代码质量]
    ↓ godot-coding-2d (修复阻塞)
    ↓ ↓
[下一批 / 调试 / 资源 / 关卡]
    ↓ systematic-debugging-2d (出 bug 时)
    ↓ asset-pipeline (加资源时)
    ↓ level-data-flow (改关卡时)
[全部完成]
    ↓ finishing-a-development-branch
[合入 main / 发 PR / 保留 / 丢弃]
    ↓ release-checklist-2d
[发布: 导出 + 冒烟 + 标记 + 分发]
```

## 决策表(摘要)

| 输入 | 调用的技能 |
|------|------------|
| "我想做一款..." | game-brainstorming |
| "帮我写 GDD" | gdd-author |
| "核心循环" / "原型" | prototype-loop(支持 GDD 前路径 B / GDD 后路径 A) |
| GDD 已批准 | game-writing-plans → godot-coding-2d |
| 极小改动 / 热修 | game-writing-plans(`from-hotfix`)→ godot-coding-2d |
| 添加素材 | asset-pipeline |
| 改关卡 | level-data-flow |
| 报 bug | systematic-debugging-2d |
| 完成一批 | game-code-review |
| 任务全完 | finishing-a-development-branch |
| 准备发布 | release-checklist-2d |
| Godot API / 语法问题 | godot-docs-4-7 + 知识技能 |

完整版见 `skills/using-game-dev/SKILL.md`。

## 测试策略(分层)

```
+-------------------------------------+
|  体验层: 手动 + 录制回放            |  ← 手感/视觉/节奏
+-------------------------------------+
|  装配层: GUT 集成测试               |  ← 多节点组合行为
+-------------------------------------+
|  逻辑层: GUT 严格 TDD               |  ← 算法/状态机/数据
+-------------------------------------+
```

详见 `godot-coding-2d` SKILL.md §7。

## 工作流选择指南

### 我刚启动一个项目

1. `game-brainstorming` — 把想法变成概念包
2. `gdd-author` — 写 GDD(个人用 lean 或 one-pager 档)
3. `prototype-loop` — 验证核心循环
4. `game-writing-plans` — 拆任务
5. 进入实现循环

### 我在已有项目加一个 feature

1. `game-writing-plans`(用 `from-feature` 模式)
2. `godot-coding-2d` 执行任务
3. `game-code-review` 审查
4. `finishing-a-development-branch` 合入

### 我在修一个 bug

1. `systematic-debugging-2d`(4 阶段)
2. `godot-coding-2d` 修 + 加测试
3. `game-code-review`(如果改动大)

### 我在准备发布

1. `release-checklist-2d`(全流程)
2. `finishing-a-development-branch`(如果还没合)

### 我只想改一行 / 调一个参数

1. `game-writing-plans`(`from-hotfix`:单任务短模板,**不跳过**)
2. `godot-coding-2d` 执行 + 对应层级验证
3. 根因未清的 bug 仍先 `systematic-debugging-2d`,不要用 hotfix 代替调试

## 反模式(流程层面)

- ❌ 跳过 brainstorming 直接写代码 → 核心循环跑偏,沉没成本
- ❌ 跳过 GDD 直接实现 → 范围漂移
- ❌ 跳过 prototype 直接写"完整版" → 手感不对回头重写
- ❌ 跳过 writing-plans 直接干 → 子代理乱飞;极小改动应用 `from-hotfix` 而不是「跳过」
- ❌ 跳过 review 直接合入 → 模式性问题反复出现
- ❌ 出 bug 不走 systematic-debugging → 乱 try,浪费时间
- ❌ 跳过 release checklist 直接打包 → 忘签名/忘 changelog
- ❌ 宿主没有 `ask_user` 就替用户选 → 应用等价选项工具或编号等待
