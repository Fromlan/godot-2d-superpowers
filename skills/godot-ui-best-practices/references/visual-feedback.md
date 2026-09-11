# Visual Feedback (deep dive)

Reference for SKILL.md §5 + §6.

## Hit flash

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color(2.0, 0.7, 0.7), 0.08)
    t.tween_property(sprite, "modulate", Color.WHITE, 0.18)
```

## Scale pulse (button feedback)

```gdscript
func _on_button_pressed() -> void:
    var t := create_tween()
    t.set_parallel(true)
    t.tween_property(button, "scale", Vector2.ONE * 1.1, 0.08)
    t.tween_property(button, "modulate", Color(1.3, 1.3, 1.3), 0.08)
    t.tween_property(button, "scale", Vector2.ONE, 0.15).set_delay(0.08)
    t.tween_property(button, "modulate", Color.WHITE, 0.15).set_delay(0.08)
```

## Damage number popup

```gdscript
extends Label
func setup(amount: int, at_pos: Vector2) -> void:
    text = str(amount)
    position = at_pos
    modulate = Color(1, 1, 1, 1)
    var t := create_tween()
    t.set_parallel(true)
    t.tween_property(self, "position", at_pos + Vector2(0, -40), 0.6)
    t.tween_property(self, "modulate:a", 0.0, 0.6)
    t.tween_callback(queue_free).set_delay(0.6)
```

## Camera shake

```gdscript
@onready var camera: Camera2D = $Camera2D
var _shake_amount := 0.0
var _shake_decay := 5.0

func shake(amount: float) -> void:
    _shake_amount = max(_shake_amount, amount)

func _process(delta: float) -> void:
    if _shake_amount > 0.0:
        camera.offset = Vector2(
            randf_range(-_shake_amount, _shake_amount),
            randf_range(-_shake_amount, _shake_amount)
        )
        _shake_amount = max(0, _shake_amount - _shake_decay * delta)
    else:
        camera.offset = Vector2.ZERO
```

## Highlight selected (board game piece)

```gdscript
var _tween: Tween = null
func set_selected(selected: bool) -> void:
    if _tween: _tween.kill()
    var target := Color(1.5, 1.5, 1.0) if selected else Color.WHITE
    _tween = create_tween()
    _tween.tween_property(sprite, "modulate", target, 0.15)
```

## Drag preview

```gdscript
func highlight_valid_drops(zones: Array[Node2D]) -> void:
    for z in zones:
        var t := create_tween().set_loops()
        t.tween_property(z, "modulate", Color(1.2, 1.2, 1.2), 0.4)
        t.tween_property(z, "modulate", Color.WHITE, 0.4)
```

Remember to kill() and reset on drop.

## Tween pitfalls

| Pitfall | Fix |
|---------|-----|
| Tween continues after queue_free | kill() before queue_free, or use tween_callback(queue_free).set_delay(...) |
| Tween freezes on scene change | autoload tweens survive; local tweens die with parent |
| Many tweens pile up | pool or check is_running() before starting new |
