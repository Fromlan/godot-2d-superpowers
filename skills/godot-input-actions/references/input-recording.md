# Input Recording (deep dive)

Reference for SKILL.md §7.

## When to record

- Speedrun categories (deterministic playback)
- Replay system for online multiplayer verification
- Automated regression testing of gameplay sequences

For casual games, overkill.

## Recorder

```gdscript
# res://autoloads/replay_recorder.gd
extends Node
var _recording: bool = false
var _events: Array = []
var _start_ms: int = 0

func start() -> void:
    _events.clear()
    _start_ms = Time.get_ticks_msec()
    _recording = true

func stop() -> Array:
    _recording = false
    return _events.duplicate()

func _input(event: InputEvent) -> void:
    if not _recording: return
    var e := {
        "type": event.get_class(),
        "t": Time.get_ticks_msec() - _start_ms,
        "data": event.as_text(),
    }
    if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
        _events.append(e)

func save_recording(path: String) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_var(_events)

func load_recording(path: String) -> void:
    var f := FileAccess.open(path, FileAccess.READ)
    _events = f.get_var()
```

## Playback

```gdscript
func playback(events: Array) -> void:
    var start := Time.get_ticks_msec()
    for e in events:
        var wait_ms := e["t"] - (Time.get_ticks_msec() - start)
        if wait_ms > 0:
            await get_tree().create_timer(wait_ms / 1000.0).timeout
        Input.parse_input_event(_make_event(e))
```

## Determinism caveat

For full determinism, you also need:
- Fixed RNG (save seed + state at recording time)
- Same physics FPS (60 Hz default)
- Same Godot version (binary-compatible replay across versions is not guaranteed)

For casual replay systems, this is overkill — recording visual events is enough.

## Common pitfall

Recording _input catches EVERY event, including mouse hover. Filter to action-like events (key, button, axis), or performance tanks.
