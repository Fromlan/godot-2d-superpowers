# 2D 类型专用模板(本套件扩展)

> 配合 `gdd-author` 使用,根据 2D 子类型提供机制清单。
> 调用方式:在 GDD "Mechanics" 阶段选最贴近的子类型,套用对应清单。

## A. 平台跳跃(Platformer)

**核心机制清单**:
- 移动(地面 + 空中)
- 跳跃(单跳 / 二段跳 / 蹬墙跳)
- 跌落伤害 / 重生
- 收集物(分数 / 解锁)
- 终点 / 检查点
- 简单敌人(巡逻 / 静止射击 / 跟踪)

**数据字段**:
- 玩家: `max_speed`、`jump_velocity`、`gravity`、`coyote_time`、`jump_buffer`
- 关卡: `tile_size`(默认 16/32px)、`parallax_layers`、`checkpoint_position`

**核心循环**:
```
[跑跳] → [避障+收集] → [扣血/加分] → [抵达/死亡] → (回跑跳)
```

## B. 清版射击(Shoot-em-up / Bullet Hell)

**核心机制清单**:
- 玩家飞机/角色(8 向移动)
- 自动开火 / 蓄力射击
- 敌机波次(直线 / 扇形 / 螺旋)
- 弹道(普通 / 跟踪 / 激光)
- Bomb / 护盾
- 评分(连击 / 时间 / 收集)

**数据字段**:
- 玩家: `hitbox`、`hurtbox`、`fire_rate`、`power_level`
- 敌机: `spawn_pattern`、`hp`、`score_value`
- 弹道: `velocity`、`lifetime`、`collision_mask`

**核心循环**:
```
[移动闪避] → [射击] → [击毁敌机] → [得分/掉落] → (回移动闪避)
```

## C. 解谜(Puzzle)

**核心机制清单**:
- 棋盘 / 网格状态
- 移动规则(推箱子 / 滑块 / 旋转)
- 撤销 / 重做(必须)
- 提示系统
- 关卡选择 / 解锁

**数据字段**:
- 关卡: `grid_size`、`initial_state`(JSON)、`solution_steps`(可选)
- 状态: 不可变状态序列(便于撤销)

**核心循环**:
```
[观察] → [操作] → [判定] → [回退/继续] → (回观察)
```

## D. 卡牌 / 牌组构筑(Deckbuilder)

**核心机制清单**:
- 起手牌组 / 抽牌堆 / 弃牌堆
- 能量 / 资源
- 卡牌效果(攻击 / 防御 / buff / 状态)
- 商店 / 奖励(战斗间)
- 敌人意图(Intent 提示)

**数据字段**:
- 卡牌: `cost`、`type`、`effect`、`tags`
- 敌人: `hp`、`intent_pattern`(循环)
- 状态: `player.deck`、`player.hand`、`player.discard`、`player.exhaust`

**核心循环**:
```
[抽牌] → [出牌] → [敌人行动] → [结算/奖励] → (回抽牌)
```

## E. Roguelike / Roguelite

**核心机制清单**:
- 程序生成关卡 / 房间
- 永久死亡 / 元进度(meta-progression)
- 随机道具 / 词条
- 难度递增(每轮强化)
- 解锁 / 收藏

**数据字段**:
- 角色: `base_stats`、`unlocked_characters`
- 道具: `id`、`tags`、`effect`(可堆叠规则)
- 进度: `floor`、`room_count`、`seed`

**核心循环**:
```
[进房间] → [战斗/事件/商店] → [拾取] → [死亡/通关] → (回进房间,种子重置)
```

## F. 塔防(Tower Defense)

**核心机制清单**:
- 路径 / 网格
- 塔类型(单攻 / 范围 / 减速 / 链式)
- 敌人波次 / BOSS
- 经济(金币 / 利息)
- 升级 / 出售

**数据字段**:
- 塔: `range`、`damage`、`fire_rate`、`cost`、`upgrade_path`
- 敌人: `hp`、`speed`、`armor`、`reward`
- 关卡: `path`(网格序列)、`waves`(延迟 + 敌人组)

**核心循环**:
```
[观察波次] → [建塔/升级] → [敌人推进] → [漏怪扣血] → (回观察)
```

## G. 模拟经营(Management Sim)

**核心机制清单**:
- 资源生产链
- 时间推进(快进)
- 顾客 / 事件
- 升级 / 解锁建筑
- 失败条件(破产 / 顾客全跑)

**数据字段**:
- 资源: `type`、`amount`、`production_rate`
- 建筑: `recipe`、`staff_required`、`level`
- 顾客: `patience`、`preferences`

**核心循环**:
```
[生产] → [顾客消费] → [收款/解锁] → [升级/扩张] → (回生产)
```

---

## 使用建议

1. 在 `gdd-author` 的 Phase 2 (Mechanics) 阶段,先选最贴近的子类型
2. 把对应清单的"核心机制清单"作为 GDD §2.1 的种子
3. **不要把整个清单都照抄进 GDD** — 只选服务支柱的 3-5 条
4. 数据字段在 `level-data-flow` 阶段会作为 Resource 类的字段来源
