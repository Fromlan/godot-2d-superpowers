# InputMap Setup (deep dive)

Reference for SKILL.md §1 + §9.

## Project structure (project.godot)

```ini
[input]
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":="A")]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":="D")]
}
jump={
"deadzone": 0.5,
"events": [
Object(InputEventKey,"physical_keycode":="Space"),
Object(InputEventJoypadButton,"button_index":="0")
]
}
```

## Reading in code

```gdscript
# Continuous (held): walks, looks around
var dir := Input.get_axis("move_left", "move_right")

# Edge (pressed this frame): jump, attack, confirm
if Input.is_action_just_pressed("jump"):
    velocity.y = -JUMP_VELOCITY

# Edge (released): release-grenade, cancel
if Input.is_action_just_released("charge"):
    fire_charged_shot(_charge_time)

# 4-direction (analog + keyboard synthesized)
var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
```

## Deadzone

- Input.get_vector(..., deadzone) 5th argument: clamp below this magnitude to zero
- Per-action in Project Settings: Input Map → action → Deadzone field
- Recommended: 0.2 for gamepad (drift threshold)

## Action modifiers

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var secondary := event.shift_pressed
```

Use shift_pressed, ctrl_pressed, alt_pressed, meta_pressed, command_or_control_autoremap.

## Programmatic registration (mods)

For mods that add bindings without editing project.godot:

```gdscript
func register_dash_action() -> void:
    if InputMap.has_action("dash"): return
    InputMap.add_action("dash")
    var space := InputEventKey.new()
    space.physical_keycode = KEY_SPACE
    InputMap.action_add_event("dash", space)
    var shift := InputEventKey.new()
    shift.physical_keycode = KEY_SHIFT
    InputMap.action_add_event("dash", shift)
```

InputMap.has_action(name), add_action(name), action_add_event(name, event), action_get_events(name), action_erase_events(name).

## Touch / mobile

Define actions with InputEventScreenTouch and InputEventScreenDrag. Read with the same Input.is_action_pressed API.

## Common bugs

| Symptom | Cause | Fix |
|---------|-------|-----|
| Action always false | not defined in InputMap | add to Project Settings |
| Gamepad does nothing | action bound only to keyboard | add gamepad binding to same action |
| is_action_just_pressed skipped | called in a tight loop missing the transition frame | use _physics_process (60Hz) for fixed timing |
| Mouse position in scaled viewport | coords in window pixels, not viewport | use get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position() |
| Programmatic action not in editor | add_action is runtime only | add to project.godot for editor visibility |
