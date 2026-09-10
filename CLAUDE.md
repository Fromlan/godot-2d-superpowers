# Game Dev Superpowers for 2D (Godot)

> 本文件是 Claude Code 的 bootstrap。等价于 `AGENTS.md`,描述保持一致。

## 第一步(必须)

读取 `skills/using-game-dev/SKILL.md`,根据用户输入查决策表,再行动。

不要跳过这一步。即使是"简单问题",也要先查表。

## 强制约束

- 任何"我想做一款游戏" / "我想做X类游戏" → 必须先调 `game-brainstorming`
- 任何"开始写代码" / "实现X" → 必须先调 `game-writing-plans` 拆任务
- 任何"出了 bug" / "现象是..." → 必须先调 `systematic-debugging-2d`
- 任何"加资源" / "换图片" / "改音效" → 必须先调 `asset-pipeline`
- 任何"改关卡" / "加关" → 必须先调 `level-data-flow`
- 任何"做完一批" → 必须先调 `game-code-review`
- 任何"准备发布" → 必须先调 `release-checklist-2d`

决策表里查不到的:优先列 2-3 个候选技能让用户选,不直接干活。

## 作用域

本套件只覆盖 **2D Godot 项目**。遇到 3D 或非 Godot 项目,先告知用户,问是否仍要继续。

## 语气

- 准强制型:关键检查点用"必须",其他用"建议"或"默认"
- 拒绝"我来帮你快速搞定"——快速 = 跳过流程,会被反噬
- 用户可以显式覆盖任何约束(用"这次跳过 X"等表述),但要在回复里明确记录

## 工作目录约定

- 仓库根:本文件所在目录
- 技能目录:`skills/<skill-name>/SKILL.md`
- 样例项目:`example-game/`(可作为模板复制)
- 辅助脚本:`scripts/`(Windows PowerShell)
- 文档:`docs/`

## 不做的事

- 不做 3D 游戏工作流(参见 godot-3d-superpowers,如存在)
- 不接管用户的项目根目录(用户自己管理)
- 不写 CI 配置(个人项目,本地验证)
