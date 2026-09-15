---
name: gdd-author
description: 撰写 GDD(游戏设计文档):按规模自适应 Game jam / Solo / Team 三档模板。当用户提到「GDD」、「核心循环」、「玩法机制」、「设计支柱」等时使用。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [from-scratch | review | section-fix | scale-jam | scale-solo | scale-team] -->

# GDD 作者

游戏设计文档（Game Design Document, GDD）撰写。从一句话创意到完整 GDD, 按规模自适应输出 Game jam / Solo / Team 三档模板, 文档默认落到项目 `design/<游戏名>/` 目录。

## 1. 触发路由 (Phase 0)

进入 skill 后, 用宿主**选项工具**(`question` / `ask_user` / 等价;见 `using-game-dev` §宿主中立约定)**单题 ≤ 4 选 1** 让用户确认: ①请求类型 + ②规模档。**不堆 4 题**。无选项工具则列出编号等待用户回复,禁止替用户选。

### 1.1 请求类型 (7 类)

| 选项 | 含义 | 主走阶段 |
|---|---|---|
| A. 概念设计 | 有想法但还没成文 | 1 Vision |
| B. 玩法 / 机制 | 已有 GDD, 细化机制 | 2 Mechanics |
| C. 叙事 / 世界观 | 已有 GDD, 补故事 | 3 Content |
| D. 商业化 | 已有 GDD, 补变现 (team 档) | 4 Production §4.7 |
| E. 竞品分析 | 已有 GDD, 补定位 | 4 Production §4.5 |
| **F. GDD 撰写** | **从零或重写 (核心)** | 1→2→3→4 全流程 |
| G. 综合 | A-E 任 2+ 组合 | 按子集阶段 |

### 1.2 规模档 (3 档)

| 档位 | 节数 | 行数上限 | 模板 |
|---|---|---|---|
| **jam** (Game jam / 48h) | 4 | 200 | `references/one-pager-template.md` |
| **solo** (个人 / 独立) | 5–9 | 500 | `references/lean-gdd-template.md` (默认) |
| **team** (2 人以上) | 12 | 1500 | `references/full-gdd-template.md` |

## 2. 工作流 (5 阶段)

### 2.1 Phase 1 — Vision (稳定层, 必写)

四节, 每节不超过 1 段:

- **1.1 一句话定位** — `<genre> + <hook> + <platform>`, 1 句 ≤ 30 字
- **1.2 设计支柱** — 3–5 条短句, 每条 ≤ 12 字 (用作决策过滤器, 见 `references/pillars-questions.md`)
- **1.3 目标玩家 + 平台** — 1 段 (谁玩 / 在哪玩 / 多久)
- **1.4 核心循环** — 1 段 + 1 个 ASCII 流程图 (不可省, 没它就没 prototype)
- **1.5 与同品类的区别** *(team 档补)* — 1 表格, 1-2 行 / 列

**失败模式**: 用户说不出 1.1 → 引 Drafft stopping rule: "再做一天构思, 不是再写一天"。

### 2.2 Phase 2 — Mechanics (细节层)

按规模选节:

| 档位 | 必填节 |
|---|---|
| jam | 1 节 (核心循环 + 主要操作) |
| solo | 3 节 (主要操作 / 输赢条件 / +1 自由) |
| team | 4 节 (+ 进阶与经济 / 难度曲线) |

每机制写 4 行: **输入 → 系统响应 → 失败态 → UI 反馈** (程序员读了要能 prototype)。

**失败模式**: 程序员读了写不出 prototype → 退回 Phase 2。

### 2.3 Phase 3 — Content (细节层)

按游戏类型, 选 2–4 个填 (其余留 TBD):

- 3.1 故事 / 世界观 (1–2 段)
- 3.2 角色 (主要 NPC, 每角色 3 行: 名字 / 弧线 / 与玩家关系)
- 3.3 关卡 / 世界 (布局 + 节奏, 1 段)
- 3.4 美术方向 (参考图链接 + 色板 + 情绪词, **3 选 1 必填一项**)
- 3.5 音频方向 (3 个参考曲链接 + 情绪词, 1 段)

**失败模式**: 写了"丰富细腻的东方玄幻世界" → 替换为参考图链接 / 色板 / 情绪词 3 选 1, 否则标 TBD。反例见 `references/scope-fence-examples.md`。

### 2.4 Phase 4 — Production (细节层, 含硬性闸门)

| 节 | jam | solo | team |
|---|---|---|---|
| 4.1 Scope IN (做什么) | ✓ | ✓ | ✓ |
| **4.2 Scope OUT (不做什么)** | **✓ 硬性闸门** | **✓ 硬性闸门** | **✓ 硬性闸门** |
| 4.3 里程碑 (prototype/alpha/beta/ship) | ✓ | ✓ | ✓ |
| 4.4 风险 (3 条 + 缓解) | – | ✓ | ✓ |
| 4.5 竞品与定位 (2-3 对比表) | – | – | ✓ |
| 4.6 团队 / 工具链 | – | – | ✓ |
| 4.7 商业化 / 变现 | – | – | ✓ |

**4.2 OUT 列表是 GDD 抗 scope creep 的命门, 不可空**。空则拒绝标 "完成"。

### 2.5 Phase 5 — 收尾 + handoff

1. 渲染主文档, 含 YAML frontmatter (`title / type / version / synced / status / tags`, 6 字段必填)
2. 决定是否拆子模块: **≥ 3 个内容子主题** → 拆目录 (`02-xxx/`, `03-xxx/`...); 否则单文件
3. 写入项目内 `design/<游戏名>/00-主设计文档.md` (用户显式指定其他路径时优先用户路径; 若用户使用 Obsidian 等外部笔记库, 再写到其指定目录)
4. **handoff** — 显式告诉用户下一步:
   > "GDD 已完成。下一步: 调 `game-writing-plans` 把 §2 核心机制拆成 5-15 分钟任务;关卡/数表调到 `level-data-flow` 把 §3 内容落成 .tres;实现层走 `godot-coding-2d`。"
5. 提示用户: "这是 living document, 改设计时同步回这里。"

## 3. 模板

主文档骨架 (solo 档默认; jam/team 档从 `references/` 拉):

```markdown
---
title: <游戏名> - 主设计文档
type: gdd-master
version: 0.1
synced: <YYYY-MM-DD>
status: 框架草稿
tags: [<genre>, <platform>, ...]
---

# 《<游戏名>》系统设计文档

> 本文档为总纲, 所有具体数值/列表/效果/剧情均以子模块文档为准。

## 0. 文档说明
## 1. 游戏概述
## 2. 核心机制
## 3. 内容
## 4. 生产
## 子模块索引
```

完整结构 + 各节填写规范见 `references/section-rubric.md`。

## 4. 失败模式 (skill 内置回复)

| 失败 | 表现 | skill 行为 |
|---|---|---|
| 写不出 1.1 一句话 | 含糊 / 超长 | 引 Drafft stopping rule |
| Scope OUT 列表为空 | 4.2 留白 | **硬性拒绝** "完成" |
| 描述用 "丰富细腻" 等空话 | 美术 / 世界章节 | 替换为参考图 / 色板 / 情绪词 3 选 1, 否则 TBD |
| 用户问实现细节 (Godot 节点) | Phase 1–4 中混入 | 切 `godot-coding-2d` / `godot-gdscript-patterns` |
| 输入超长 (已有 500 行 GDD) | 用户贴了完整稿 | **审计模式**: 不重写, 按本 skill 节号映射打勾, 输出 "差异清单" |
| 用户没说游戏名 | Phase 0 | 占位 `<新游戏-001>`, 收尾前用宿主选项工具确认改名 |
| 已有项目要 "扩展 GDD" | 不是从零 | "按节修订" 子流程: 读现状, 只补缺节, 不重写已有节 |

## 5. 触发关键词 (frontmatter 内含)

**zh**: 游戏设计 / GDD / 游戏设计文档 / 核心循环 / 玩法机制 / 叙事设计 / 商业化 / 竞品分析 / 关卡设计 / 数值设计 / 世界观 / 策划案 / 写 GDD / 设计支柱 / 核心玩法

**en**: game design / game design document / core loop / mechanics / narrative design / monetization / competitive analysis / level design

## 6. 不触发 (路由到其他 skill)

- "拆解 XX 游戏怎么设计的" → `systematic-debugging-2d`(机制层) 或 `game-brainstorming`(重审方向)
- "Godot 里怎么实现战斗 / 动画 / 物理" → `godot-coding-2d` / `godot-2d-physics` / `godot-animation`
- "数值表怎么设计" → `godot-gdscript-patterns`(Resource 数据驱动)
- "画个角色 / 美术风格" → `asset-pipeline`(命名 + 导入规范)
- "加新关卡 / 改难度" → `level-data-flow`
- "关卡数据已准备好,开始实现" → `game-writing-plans`(拆任务)

## 7. 与本套件其他 skill 的协作

GDD 是设计文档,不含 Godot 节点结构 / 引擎 API / 性能数据。完成 handoff 后,引导用户走实现层:

```
gdd-author (设计层)
  ├─→ game-writing-plans (拆任务到 5-15 分钟粒度)
  ├─→ godot-coding-2d (实现机制 + 分层测试)
  ├─→ level-data-flow (§3 关卡数据落成 .tres)
  ├─→ asset-pipeline (§3 美术 / 音频资源命名与导入)
  ├─→ godot-gdscript-patterns (Resource 数据驱动 + 静态类型规范)
  └─→ godot-2d-physics / godot-animation / godot-audio (子领域落地)
```


## 8. 状态与并发

- **无运行时状态**: skill 是 procedural, 每次调用基于用户当前输入 + 已落盘文档。
- **不写 session 之外的文件**: 落盘只写当前游戏的 `design/<游戏名>/` 目录, 不动项目外笔记库或其他技能产物。
- **多人协作**: skill 自身不解决, 留待用户 git/笔记同步工具自行管理。
- **恢复**: 落盘前不写临时文件, 中断即放弃; 已落盘文档可被用户任意修订, 再次调用时只 diff "用户修改 vs 模板默认", 不重写用户已改节。
