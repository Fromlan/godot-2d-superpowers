---
name: godot-input-actions
description: |
  Godot 4.7 输入:InputMap、action-based 输入、手柄/键盘/触屏绑定、编程式注册 action、输入回放。Use when 提到"InputMap"、"input action"、"快捷键"、"手柄"、"gamepad"、"is_action_pressed"、"get_vector"、"pause key"、"rebind"。Do NOT use for UI Button clicks(见 godot-ui-best-practices Rule 4)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [topic, e.g. 'action', 'gamepad', 'rebind', 'is_action_pressed'] -->

# Godot 输入操作 (4.7)

Godot 4 输入的实操规则:InputMap action、基于 action 的查询、手柄支持、编程式注册、输入录制。深入阅读见 `references/<topic>.md`。

## 1. 基于 Action 的输入,而不是裸 `KeyEvent`

在 **Project Settings → Input Map** 中定义 action。把键位 / 手柄按钮 / 鼠标按钮都绑到同一个 action。用 `Input.is_action_pressed(&"action_name")` 读取。

```gdscript
# Right — action-based
if Input.is_action_pressed(&"jump"):
    velocity.y = -JUMP_VELOCITY

# Wrong — raw key event
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        velocity.y = -JUMP_VELOCITY
```

**为什么**:基于 action 的输入允许用户重新绑定键位(Steam Input、无障碍设置、不同语言键盘)。裸 `KEYSPACE` 永远锁死在一个键上。同一份代码可工作在手柄、键盘、触屏。

纯鼠标游戏用 `_unhandled_input` + `InputEventMouseButton` 可以 — 但 **仍然** 给点击定义 InputMap action(如 `select_piece`),这样支持重绑定。

## 2. `is_action_pressed` vs `is_action_just_pressed` vs `is_action_just_released`

| API | 行为 | 用途 |
|---|---|---|
| `is_action_pressed(action)` | action 按住期间每帧 true | 持续(按住):行走、奔跑、视角转动 |
| `is_action_just_pressed(action)` | 仅在按下状态变化的当帧 true | 边缘:跳跃、攻击、确认 |
| `is_action_just_released(action)` | 仅在松开瞬间 true | 边缘:投雷、取消动作 |

`_input` 和 `_unhandled_input` 总会收到输入事件。`is_action_just_pressed` 仅在 action 由「未按下」变为「已按下」的那一帧返回 true。下一帧即使 action 仍处于按下状态,也是 false。

```gdscript
# Continuous: hold to walk
if Input.is_action_pressed(&"move_right"):
    velocity.x += SPEED

# Edge: tap to jump
if Input.is_action_just_pressed(&"jump") and is_on_floor():
    velocity.y = -JUMP_VELOCITY

# Edge: released
if Input.is_action_just_released(&"charge_attack"):
    fire_charged_shot(charge_time)
```

**反模式**:把 `is_action_pressed` 用作「跳跃」 — 玩家得松开再按一次才能在落地后再次跳。用 `is_action_just_pressed`。

## 3. `Input.get_vector` 用于四方向 / 模拟输入

```gdscript
# 4-direction: returns Vector2 in [-1, 1] range
var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
velocity = dir * SPEED
```

处理:
- 键盘:4 个独立 action(每个方向一个)
- 手柄左摇杆:合成为单个 2D 向量
- 键盘 + 手柄:两者累加

`Input.get_vector` 第 5 个可选参数是 `deadzone`(默认 0.2)。低于该模长的输入会被夹到零 — 防止摇杆漂移造成误移动。

```gdscript
# 2-direction: 1D axis (e.g. menu navigation)
var axis := Input.get_axis(&"move_left", &"move_right")
```

## 4. 编程式 InputMap 注册(mod 友好)

对于需要在运行时加载 mod 的游戏,把 action 定义写在代码里,mod 就能添加绑定而不用改 `project.godot`:

```gdscript
func _ready() -> void:
    if not InputMap.has_action("dash"):
        InputMap.add_action("dash")
        var ev_space := InputEventKey.new()
        ev_space.physical_keycode = KEY_SPACE
        InputMap.action_add_event("dash", ev_space)
        var ev_lshift := InputEventKey.new()
        ev_lshift.physical_keycode = KEY_SHIFT
        InputMap.action_add_event("dash", ev_lshift)
```

`InputMap.has_action(name)` 检查 action 是否存在。`InputMap.add_action(name)` 创建。`InputMap.action_add_event(name, event)` 绑定事件。

为 mod 暴露一个 `register_action` 辅助函数供 mod 调用。

## 5. 设备检测(键盘 / 手柄 / 触屏)

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        # keyboard input
        pass
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        # gamepad input
        pass
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        # touch input (mobile)
        pass
    elif event is InputEventMouseButton or event is InputEventMouseMotion:
        # mouse input (desktop)
        pass
```

`Input.get_connected_joypads()` 返回已连接手柄的 ID 列表。

```gdscript
# Verify the action exists
InputMap.has_action(name)
# See all bound events
InputMap.action_get_events(name)
# Print what events actually fire
print(event.as_text()) in _input
# Gamepad count
Input.get_connected_joypads()
# Read stick values
Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
```

## 6. 默认 InputMap actions

| Action | Default binding | 用途 |
|---|---|---|
| `ui_accept` | Enter / Space | 确认 |
| `ui_select` | Enter / Space | 选中(主要用于 ItemList/Tree) |
| `ui_cancel` | Escape | 取消 |
| `ui_focus_next` / `ui_focus_prev` | Tab / Shift+Tab | 焦点切换 |
| `ui_left` / `ui_right` / `ui_up` / `ui_down` | 方向键 | UI 导航 |
| `ui_page_up` / `ui_page_down` | PageUp / PageDown | 翻页 |
| `ui_home` / `ui_end` | Home / End | 跳到首/末 |
| `ui_text_*` | (无默认) | 文本输入 |
| `ui_pause` | (无默认) | 暂停 |

用于 UI 导航。游戏动作自己定义。

## 7. 输入事件录制(回放 / 存档)

「保存游戏」或「回放录制」:

```gdscript
var _recorded_events: Array = []

func _input(event: InputEvent) -> void:
    if not _recording:
        return
    # Record only relevant events
    if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
        _recorded_events.append({
            "type": event.get_class(),
            "t": Time.get_ticks_msec(),
            "data": event.as_text(),
        })

func save_recording() -> void:
    var f := FileAccess.open("user://replay.dat", FileAccess.WRITE)
    f.store_var(_recorded_events)

func load_and_play_recording() -> void:
    var f := FileAccess.open("user://replay.dat", FileAccess.READ)
    var events: Array = f.get_var()
    var start := Time.get_ticks_msec()
    for e in events:
        await get_tree().create_timer((e["t"] - start) / 1000.0).timeout
        Input.parse_input_event(make_event_from_record(e))
```

要做确定性回放(speedrun 段位、竞技完整性),录制输入 + RNG 状态再回放。对自走棋这种没有实时玩家输入的游戏,过度了。

## 8. Action 修饰键(Shift + 点击 = 次要动作)

```gdscript
@export var secondary_action_with_shift := true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var secondary := event.shift_pressed  # shift held during click
        if secondary and secondary_action_with_shift:
            do_secondary_action()
        else:
            do_primary_action()
```

`InputEvent` 含 `shift_pressed`、`ctrl_pressed`、`alt_pressed`、`meta_pressed`、`command_or_control_autoremap` 修饰键。用于「修饰键 + 点击」类操作。

要基于 action 的修饰键组合,在 `_input` 里同时检查两个 action:

```gdscript
func _physics_process(_delta: float) -> void:
    if Input.is_action_pressed(&"sprint") and Input.is_action_pressed(&"move_forward"):
        velocity *= 1.5
```

## 9. 鼠标灵敏度 / 死区

手柄:

```gdscript
const STICK_DEADZONE := 0.2
var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down", STICK_DEADZONE)
```

Project Settings → Input Map → 每个 action 有「Deadzone」字段。手柄轴设 0.2-0.3(漂移阈值)。

鼠标灵敏度(摄像机视角类游戏):

```gdscript
@export var mouse_sensitivity := 0.002
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        camera.rotation.y -= event.relative.x * mouse_sensitivity
```

设置菜单里的鼠标灵敏度滑块:

```gdscript
@onready var sensitivity_slider: HSlider = %SensitivitySlider
func _on_sensitivity_value_changed(value: float) -> void:
    mouse_sensitivity = value
```

像音频设置一样持久化到 `user://settings.cfg`。

## 10. 常见 bug 模式

| 症状 | 根因 | 修复 |
|------|------|------|
| Action 始终 false | 没在 InputMap 中定义 | 加到 Project Settings → Input Map |
| 手柄没反应 | action 只绑了键盘 | 同一 action 加手柄绑定 |
| `is_action_just_pressed` 没触发 | 该 API 只在 transition 帧返回 true;在长循环里可能错过 | 在 `_physics_process` (60Hz) 用,不要在 `_process` |
| 两个 action 同一键都触发 | 同一事件绑到多个 action | 检查 InputMap 去重 |
| 编程注册的 action 在编辑器不可见 | `InputMap.add_action` 仅影响运行时;编辑器的真相在 `project.godot` | 编辑器可见性需写 `project.godot` |
| 鼠标位置值不对 | 窗口缩放后,鼠标坐标是窗口像素空间,不是视口 | 用 `get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()` |
| 手柄摇杆漂移引起移动 | 死区太小 | 死区调到 0.2+ |

## 参考索引

- `references/inputmap-setup.md` — 完整的 InputMap project.godot 章节演示
- `references/controller-support.md` — 手柄布局、死区、热插拔
- `references/input-recording.md` — 完整输入录制 / 回放模板

## 输出契约

只读知识。在写 / 改 Godot 输入处理时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果输入 bug 不匹配上述任一规则:
- `InputMap.has_action(name)` 验证 action 是否存在
- `InputMap.action_get_events(name)` 看所有绑定事件
- 在 `_input` 里 `print(event.as_text())` 看实际触发的事件
- `Input.get_connected_joypads()` 看手柄数量
- `print(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))` 读摇杆值

还卡住的话,回退到 `references/inputmap-setup.md` 里的四个诊断。
