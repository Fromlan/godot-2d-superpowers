# SFX Patterns (deep dive)

Reference for SKILL.md §4 + §8 + §9.

## Random pitch for procedural variety

Same sample × 10 feels monotonous. ±10% pitch shifts makes each instance feel distinct.

```gdscript
func play_hit_sfx() -> void:
    var p := AudioStreamPlayer.new()
    p.bus = "SFX"
    p.stream = preload("res://assets/audio/sfx/hit.ogg")
    p.pitch_scale = randf_range(0.9, 1.1)
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()
```

## Pool to avoid GC pressure

Instantiating AudioStreamPlayer per play is fine for low-volume use. For repeated SFX (hit / click / footstep), pool 8 players:

```gdscript
class_name SfxPool extends Node
const POOL_SIZE := 8
var _pool: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _pool.append(p)

func play(stream: AudioStream, pitch := 1.0) -> void:
    var p := _pool[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = stream
    p.pitch_scale = pitch
    p.play()
```

If play() is called while the pool slot is still playing its previous sound, the previous is cut. For overlap (e.g. rapid fire), use more pool slots or create-on-demand + finished → queue_free.

## Throttle with Timer (e.g. footsteps)

```gdscript
@export var footstep_interval := 0.3
var _t := 0.0
func _physics_process(delta: float) -> void:
    if is_on_floor() and abs(velocity.x) > 50.0:
        _t += delta
        if _t >= footstep_interval:
            _t = 0.0
            SfxPool.play(preload("res://assets/audio/sfx/footstep.ogg"))
```

## UI clicks

```gdscript
# Use the UI bus, never lower
@onready var click: AudioStreamPlayer = $Click
func _ready() -> void:
    click.bus = "UI"
    click.stream = preload("res://assets/audio/sfx/ui_click.ogg")

# In a Button.pressed handler:
click.play()
```

## Common bug patterns

| Symptom | Cause | Fix |
|---------|-------|-----|
| First SFX plays late | MP3 decoding | use OGG or preload |
| 100 SFX causes frame stutter | per-play new + GC | use pool |
| queue_free cuts sound short | manual timer instead of finished signal | use finished.connect(p.queue_free) |
| Footstep audible across map | max_distance too high (3D) | set to gameplay-relevant range |
| Music and SFX tied together | all on Master | split into Music / SFX / UI buses |
