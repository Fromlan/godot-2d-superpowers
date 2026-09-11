---
name: finishing-a-development-branch
description: "Use when implementation is complete, all tests pass, and you need to decide how to integrate the work. 适用于 2D Godot 项目收尾;对非 Godot 项目或非游戏项目保留 superpowers 原英文版。"
last_reviewed: 2026-09-10
---

<!-- argument-hint: [merge | pr | keep | discard] -->

# 收尾开发分支 (Finishing a Development Branch)

## 概述

**核心原则**:验证测试 → 检测环境 → 给出选项 → 执行选择 → 清理。

**开始时公告**:"正在使用 finishing-a-development-branch 技能完成本次工作。"

## Step 1:验证测试

跑项目完整测试套件(`npm test` / `cargo test` / `pytest` / `go test ./...` / Godot 项目 `scripts/run-tests.ps1` + `scripts/headless-smoke.ps1`)。

**若测试失败**,报告失败并停下 — 菜单在绿色套件之后才出现:

```
测试失败 (<N> 处失败)。必须修完才能进入收尾:

[展示失败]
```

**若测试通过**:继续 Step 2。

## Step 2:检测环境

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# 现在捕获,还在工作区里 — Step 5 切换目录前(Step 6 清理)需要这个值
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

这决定显示哪个菜单和怎么清理:

| 状态 | 菜单 | 清理 |
|------|------|------|
| `GIT_DIR == GIT_COMMON`(常规仓库) | 标准 3 选项 | 无 worktree 可清 |
| `GIT_DIR != GIT_COMMON`且命名分支 | 标准 3 选项 | 基于出处(见 Step 6) |
| `GIT_DIR != GIT_COMMON`且 detached HEAD | 精简 2 选项(无 merge) | 外部管理 — 保持现状 |

## Step 3:确定基分支

基分支是本工作分叉自的分支 — 通常在计划、对话、或上游分支名里能找到。如果还没明确,问:"本分支从 <你的最佳猜测> 分叉 — 对吗?" 在合并前确认:合到错的基分支撤销成本很高。

## Step 4:给出选项

**常规仓库 + 命名分支 worktree — 精确展示以下 3 选项:**

```
实现完成。你想怎么处理?

1. 合并回 <base-branch>(本地)
2. 推送并创建 Pull Request
3. 保持分支原样(稍后我自己处理)

选哪个?
```

**detached HEAD — 精确展示以下 2 选项:**

```
实现完成。你当前在 detached HEAD(外部管理的工作区)。

1. 推送为新分支并创建 Pull Request
2. 保持现状(稍后我自己处理)

选哪个?
```

按原文展示菜单 — 简洁,每个选项来自上面的清单。**丢弃工作**只发生在你的合作伙伴明确要求时(见下方"若用户要求丢弃工作")。等他的回答;集成决策是他的。

## Step 5:执行选择

### 选项 1:本地合并

```bash
# 获取主仓库根用于 CWD 安全
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# 先合 — 确认成功再删任何东西
git checkout <base-branch>
git pull
git merge <feature-branch>

# 在合并结果上验证测试
<test command>
```

若合并结果上测试失败:停下,worktree 和分支保持原位,排查 — 还没推送,合是本地可恢复的。

合并结果绿色后:清理 worktree(Step 6),然后删分支:

```bash
git branch -d <feature-branch>
```

### 选项 2:推送并创建 PR

```bash
git push -u origin <feature-branch>
# 从 detached HEAD,在远端为新分支命名:
# git push origin HEAD:refs/heads/<new-branch>
```

然后用 forge 工具创建针对 <base-branch> 的 PR — 用它的 CLI(若有),或 forge 在推送后打印的创建 URL;遵循仓库的 PR 模板和约定(若存在),并向用户报告 URL。

保留 worktree — 合作伙伴在那里迭代 PR 反馈。

### 选项 3:保持现状

报告:"保持分支 <name>。Worktree 保留在 <path>。"

### 若用户要求丢弃工作

这条路径**只**作为对显式"丢弃"请求的回应。先确认:

```
这会永久删除:
- 分支 <name>
- 所有提交: <commit-list>
- Worktree 在 <path>

输入 'discard' 确认。
```

等待那个确切的确认。当它到达时:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

然后清理 worktree(Step 6),并强制删除分支:

```bash
git branch -D <feature-branch>
```

## Step 6:清理工作区

**对选项 1 和已确认的丢弃运行**。选项 2 和 3 始终保留 worktree。两个调用方都已切换到主仓库根目录 — worktree 删除必须从 worktree 外运行 — 并使用 Step 2 中捕获的 `GIT_DIR`/`GIT_COMMON`/`WORKTREE_PATH` 值,即目录切换前的值。

**若 `GIT_DIR == GIT_COM`**:常规仓库,无可清理 worktree。完成。

**若 `WORKTREE_PATH` 在 `.worktrees/` 或 `worktrees/` 下**:superpowers 创建的 — 我们负责清理:

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune  # 自愈:清理任何陈旧注册
```

**若删除被拒绝**(`contains modified or untracked files`):worktree 里有只存在于这里的文件 — 未提交的计划、笔记、scratch work。永远不要自行 `--force`。给合作伙伴展示利害并询问:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree 删除被拒绝 — 这些文件从未提交:

<file list>

1. 提交到 <branch> 后清理
2. 移到 <main repo root>
3. 删除(不可恢复)

选哪个?
```

执行选择,然后移除 worktree。

**否则**:宿主环境拥有该工作区 — 保持原状。若平台提供 workspace-exit 工具,使用它。

## 速查

| 选项 | 合并 | 推送 | 保留 Worktree | 清理分支 |
|------|------|------|--------------|----------|
| 1. 本地合并 | 是 | — | — | 是 |
| 2. 创建 PR | — | 是 | 是 | — |
| 3. 保持原状 | — | — | 是 | — |
| 丢弃(仅显式请求) | — | — | — | 是(强制) |

## 常见借口

| 借口 | 现实 |
|------|------|
| "这次会话早些时候测过了" | 在你要集成的树上跑套件。绿色运行只能证明它跑的树。 |
| "他显然想合并" | 集成是合作伙伴的决策。展示菜单并等待。 |
| "他看起来做完了 — 我提议丢弃" | 菜单就是上面那样写。丢弃只在合作伙伴明说要丢时发生。 |
| "'嗯,删掉吧'算确认" | 只有打出的 `discard` 字面词授权删除。 |
| "PR 起来了,worktree 现在是垃圾" | PR 反馈在那个 worktree 里修。它待到工作落地。 |
| "这另一个 worktree 看起来很陈旧 — 我顺手清一下" | 只清理 `.worktrees/` 或 `worktrees/` 下的。其余归宿主。 |
| "删除被拒绝 — `--force` 就是收尾" | 拒绝意味着文件只存在于那个 worktree。`--force` 永久销毁。展示给合作伙伴并问。 |
| "合并结果失败可能是 flaky" | 失败的合并结果停一切。分支和 worktree 留在原地等待排查。 |
| "基分支显然是 main" | 确认分叉点或问。合到错的基分支撤销成本很高。 |
| "推送被拒 — force-push 能修" | 推送被拒意味着远端动了。排查;只在合作伙伴显式要求时 force-push。 |
