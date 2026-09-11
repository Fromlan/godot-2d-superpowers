# Mouse, Click, and Drag (deep dive)

Reference for SKILL.md §3 + §4 + §5.

## mouse_filter (the #1 cause of "click doesn't fire")

```
STOP = 0       (default) — eats the event; doesn't pass to siblings or _unhandled_input
PASS = 1       — sees it; passes to siblings + _unhandled_input
IGNORE = 2     — invisible to mouse; event goes through
```

Default STOP means a decorative Label next to a game object silently eats clicks before they reach the parent's _unhandled_input.

```gdscript
label.mouse_filter = Control.MOUSE_FILTER_IGNORE
hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
button.mouse_filter = Control.MOUSE_FILTER_STOP
```

## Click event chain

```
_input → _gui_input → _unhandled_input
```

| Hook | When | Use for |
|------|------|---------|
| _input | every event, before GUI | recording, debug overlays |
| _gui_input | GUI controls only | inside Control scripts |
| _unhandled_input | events that GUI didn't consume | game actions (NOT button clicks) |

## Button clicks — always signal

```gdscript
shop_buy_btn.pressed.connect(_on_shop_buy)
```

Never poll for button clicks in _unhandled_input — it duplicates Button's logic and breaks with input devices.

## Drag-and-drop pattern

```gdscript
extends Control
var _dragging := false
var _offset := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = true
            _offset = event.position - position
            accept_event()
        elif not event.pressed:
            _dragging = false
    elif event is InputEventMouseMotion and _dragging:
        position = get_global_mouse_position() - _offset
```

For HUD over game world, use CanvasLayer for the HUD and game objects in Node2D — they don't share click space.

## 3D/2D world click hit-test

```gdscript
# For 2D: convert mouse to world position
var world_pos := get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
```

## Hover / focus

```gdscript
control.focus_mode = Control.FOCUS_ALL
control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
```

## Custom cursor

```gdscript
Input.set_default_cursor_shape(Control.CURSOR_CROSS)
Input.set_custom_mouse_cursor(load("res://assets/ui/cursor.png"))
```

## The four minimum diagnostics

1. print(get_viewport_rect().size) in _ready() — confirm viewport size
2. print(node.global_position, node.size, node.mouse_filter) — find click-eater
3. print(event.position, event.pressed) in _unhandled_input first line
4. print(piece.position, piece.hit_radius) — hit-test math
