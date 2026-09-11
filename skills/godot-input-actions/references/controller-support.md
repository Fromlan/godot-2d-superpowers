# Controller Support (deep dive)

Reference for SKILL.md §3 + §9.

## Gamepad layout

Godot uses Xbox-style indices by default. Map common buttons:

```ini
; project.godot
[input]
interact={
"events": [
Object(InputEventKey,"physical_keycode":="E"),
Object(InputEventJoypadButton,"button_index":="2")
]
}
```

Standard Xbox mapping:
- A=0, B=1, X=2, Y=3
- LB=4, RB=5
- LT (axis), RT (axis)
- Back=8, Start=9, L3=10, R3=11
- DPad Up=12, Down=13, Left=14, Right=15

## Hot-swap

Input.get_connected_joypads() returns array of connected gamepad IDs. Poll in _process if you need a "gamepad disconnected" UI:

```gdscript
func _process(_delta: float) -> void:
    var pads := Input.get_connected_joypads()
    if pads.is_empty() and not _was_disconnected:
        _show_disconnected_prompt()
        _was_disconnected = true
    elif not pads.is_empty() and _was_disconnected:
        _hide_disconnected_prompt()
        _was_disconnected = false
```

## Sticks

```gdscript
var aim := Vector2(
    Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
    Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
)
var rt := (Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) + 1.0) / 2.0
```

## Stick deadzone

Default 0.2 is fine. Increase for players with worn sticks:

```gdscript
const STICK_DEADZ := 0.25
var v := Input.get_vector("move_left", "move_right", "move_up", "move_down", STICK_DEADZ)
```

## Common patterns

| Game | Mapping |
|------|---------|
| Platformer | A=jump, B=attack, RT=dash, L-stick=move, R-stick=aim |
| Twin-stick shooter | R-stick=aim, RT=shoot, A=dodge |
| Top-down RPG | A=interact, B=cancel, X=menu, Y=map |

## Common bugs

| Symptom | Cause | Fix |
|---------|-------|-----|
| Stick drift causes unwanted movement | deadzone too small | increase to 0.25+ |
| Trigger reads 0 always | axis range is [-1, 1]; unpressed = -1 | remap: (axis + 1) / 2 |
| Gamepad works in editor but not exported | bindings include keyboard-specific keys only | verify project.godot in exported PCK |
| Player can't aim / move | JOY_AXIS_LEFT_X instead of JOY_AXIS_RIGHT_X | check axis name |
