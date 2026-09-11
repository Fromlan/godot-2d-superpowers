---
name: godot-input-actions
description: |
  Godot 4.7 输入:InputMap、action-based 输入、手柄/键盘/触屏绑定、编程式注册 action、输入回放。Use when 提到"InputMap"、"input action"、"快捷键"、"手柄"、"gamepad"、"is_action_pressed"、"get_vector"、"pause key"、"rebind"。Do NOT use for UI Button clicks(见 godot-ui-best-practices Rule 4)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [topic, e.g. 'action', 'gamepad', 'rebind', 'is_action_pressed'] -->

# Godot Input Actions (4.7)

Actionable rules for Godot 4 input: InputMap actions, action-based queries, controller support, programmatic registration, input recording. Deep dives in `references/<topic>.md`.

## 1. Action-based input, not raw `KeyEvent`

Define actions in **Project Settings → Input Map**. Bind keys / gamepad buttons / mouse buttons to the same action. Read with `Input.is_action_pressed(&"action_name")`.

```gdscript
# Right — action-based
if Input.is_action_pressed(&"jump"):
    velocity.y = -JUMP_VELOCITY

# Wrong — raw key event
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        velocity.y = -JUMP_VELOCITY
```

**Why**: action-based input lets the user rebind keys (Steam Input, accessibility settings, language-specific keyboards). Raw `KEY_SPACE` locks you to one key forever. Same code works on gamepad, keyboard, mobile touch.

For mouse-only games, `_unhandled_input` with `InputEventMouseButton` is fine — but **still define an InputMap action** for the click (e.g. `select_piece`) so rebinding is possible.

## 2. `is_action_pressed` vs `is_action_just_pressed` vs `is_action_just_released`

| API | Behavior | Use |
|last_reviewed: 2026-09-10
---|---|---|
| `is_action_pressed(action)` | true every frame the action is held | continuous (held): walk, run, look-around |
| `is_action_just_pressed(action)` | true only the frame it became pressed | edge: jump, attack, confirm |
| `is_action_just_released(action)` | true only the frame it was released | edge: release-grenade, cancel-action |

`_input` and `_unhandled_input` receive the input event regardless. `is_action_just_pressed` returns true on the frame the action transitioned from "not pressed" to "pressed". On the next frame, it's false even if the action is still pressed.

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

**Anti-pattern**: using `is_action_pressed` for "jump" — the player has to release and re-press to jump again after landing. Use `is_action_just_pressed`.

## 3. `Input.get_vector` for 4-way / analog input

```gdscript
# 4-direction: returns Vector2 in [-1, 1] range
var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
velocity = dir * SPEED
```

Handles:
- Keyboard: 4 separate actions (one per direction)
- Gamepad left stick: synthesized as a single 2D vector
- Combined keyboard + gamepad: sums both

`Input.get_vector` accepts an optional 5th argument `deadzone` (default 0.2). Below this magnitude, the result is zero — prevents stick drift from causing unwanted movement.

```gdscript
# 2-direction: 1D axis (e.g. menu navigation)
var axis := Input.get_axis(&"move_left", &"move_right")
```

## 4. Programmatic InputMap registration (mod-friendly)

For games that load mods at runtime, define actions in code so mods can add bindings without editing `project.godot`:

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

`InputMap.has_action(name)` checks if the action exists. `InputMap.add_action(name)` creates it. `InputMap.action_add_event(name, event)` binds an event to it.

For mods, expose a `register_action` helper that the mod can call.

## 5. Device detection (keyboard / gamepad / touch)

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

`Input.get_connected_joypads()` returns an `Array[int]` of connected gamepad device IDs. For "any gamepad", use `Input.JOY_BUTTON_ANY` (a constant = -1).

For "show gamepad UI when gamepad is active":

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        show_gamepad_prompts()
    elif event is InputEventKey:
        show_keyboard_prompts()
```

## 6. Default InputMap actions

Godot 4 ships with a default InputMap. Useful ones for your game:

| Action | Default binding | Use |
|---|---|---|
| `ui_accept` | Enter, Space, gamepad A | confirm dialog, accept |
| `ui_cancel` | Escape, gamepad B | cancel, back |
| `ui_left` / `ui_right` / `ui_up` / `ui_down` | Arrows, gamepad d-pad / left stick | menu navigation |
| `ui_focus_next` / `ui_focus_prev` | Tab / Shift+Tab | focus traversal |
| `ui_select` | Enter, gamepad A | select in list |
| `ui_menu` | (none by default) | open menu |
| `ui_pause` | (none by default) | pause |

Use these for UI navigation. For gameplay actions, define your own.

## 7. Input event recording (replay / save states)

For "save the game" or "playback recording":

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

For deterministic gameplay (speedrun categories, competitive integrity), record input + RNG state and play back. For Z-2's auto-chess, this is overkill — the game has no real-time player input.

## 8. Action modifiers (Shift + click = secondary)

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

`InputEvent` has `shift_pressed`, `ctrl_pressed`, `alt_pressed`, `meta_pressed`, `command_or_control_autoremap` modifiers. Use them for "modifier + click" patterns.

For action-based modifier combinations, use `_input` with both checks:

```gdscript
func _physics_process(_delta: float) -> void:
    if Input.is_action_pressed(&"sprint") and Input.is_action_pressed(&"move_forward"):
        velocity *= 1.5
```

## 9. Mouse sensitivity / deadzone

For gamepad:
```gdscript
const STICK_DEADZONE := 0.2
var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down", STICK_DEADZONE)
```

Project Settings → Input Map → each action has a "Deadzone" field. For gamepad axes, set to 0.2-0.3 (drift threshold).

For mouse sensitivity (camera-look type games):
```gdscript
@export var mouse_sensitivity := 0.002
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        camera.rotation.y -= event.relative.x * mouse_sensitivity
```

Settings menu slider for mouse sensitivity:
```gdscript
@onready var sensitivity_slider: HSlider = %SensitivitySlider
func _on_sensitivity_value_changed(value: float) -> void:
    mouse_sensitivity = value
```

Persist to `user://settings.cfg` like audio settings.

## 10. Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| Action always false | Action not defined in InputMap | Add to Project Settings → Input Map |
| Gamepad does nothing | Action bound only to keyboard | Add gamepad binding to same action |
| `is_action_just_pressed` doesn't fire | `is_action_just_pressed` only true on transition frame; in long loops you might miss it | Use in `_physics_process` (60 Hz) not `_process` for fixed timing |
| Two actions both fire on same key | Same event bound to multiple actions | Check InputMap for duplicates |
| Programmatic action doesn't show in editor | `InputMap.add_action` only affects runtime; `project.godot` is the source of truth for editor | Add to project.godot for editor visibility |
| Mouse position reports wrong value | Window scaled; mouse coords are in window pixel space, not viewport | Use `get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()` |
| Gamepad stick drift causes movement | Deadzone too small | Set deadzone to 0.2+ |

## Reference index

- `references/inputmap-setup.md` — full InputMap project.godot section walkthrough
- `references/controller-support.md` — gamepad layouts, deadzones, hot-swap
- `references/input-recording.md` — full input recording / playback template

## Output contract

Read-only knowledge. Apply the rules when building / fixing Godot input handling. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If an input bug doesn't match any rule above:
- `InputMap.has_action(name)` to verify action exists
- `InputMap.action_get_events(name)` to see all bound events
- `print(event.as_text())` in `_input` to see what events actually fire
- `Input.get_connected_joypads()` to see gamepad count
- `print(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))` to read stick values

If still stuck, fall back to the four diagnostics in `references/inputmap-setup.md`.
