# Signals as Decoupling (deep dive)

Reference for SKILL.md §4.

## The anti-pattern

```gdscript
# Wrong: Node A reaches into Node B
get_node("/root/Main/Battle/HUD/ScoreLabel").text = "Score: 100"
```

This breaks if:
- The path changes (refactor)
- The label doesn't exist yet (initialization order)
- The label moves to a different scene

## The right pattern

```gdscript
# Emitter
signal score_changed(new_score: int)
func add_score(amount: int) -> void:
    score += amount
    score_changed.emit(score)

# Listener (anywhere in the project)
score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
    label.text = "Score: %d" % new_score
```

Why signals:
- Type-checked parameters (editor flags mismatches at connect time)
- Multiple listeners (1 emitter → N receivers)
- Decoupled: emitter doesn't know or care who listens
- Survives node reparenting / scene changes

## Connection flags

| Flag | When |
|------|------|
| (default) | synchronous, in caller |
| CONNECT_DEFERRED | run at idle — safe when listener mutates emitter's state mid-emission |
| CONNECT_PERSIST | saved in scene; survives reload |
| CONNECT_ONE_SHOT | auto-disconnect after one fire |
| CONNECT_REFERENCE_COUNTED | tracks ref count; allows multiple disconnects |

```gdscript
piece_killed.connect(_on_piece_killed, CONNECT_DEFERRED)
```

## EventBus (autoload) for cross-scene broadcast

For events that cross scenes (player died, level cleared), use an autoload singleton:

```gdscript
# res://autoloads/event_bus.gd
extends Node
signal player_died
signal level_cleared
signal score_changed(new_score: int)
```

Register in Project Settings → Autoload as "EventBus". Listeners anywhere:

```gdscript
EventBus.player_died.connect(_on_player_died)
```

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Signal declared without typed params | type them: signal x(a: int, b: String) |
| Signal connected in _ready() of not-yet-in-tree node | use CONNECT_DEFERRED or call_deferred |
| Many listeners on one signal causing lag | check for tight loops emitting every frame |
| emit_signal("typo") | always use name.emit(...); IDE autocomplete catches typos |
| Signal fired in _process 60Hz | events should be discrete; throttling signal is OK |
