# Area2D Signals (deep dive)

Reference for SKILL.md §3.

## Signal matrix

On the Area2D:
  area_entered(area: Area2D)         # another Area2D entered
  area_exited(area: Area2D)
  body_entered(body: Node2D)         # CharacterBody2D / RigidBody2D / TileMapLayer entered
  body_exited(body: Node2D)

On any CollisionObject2D:
  area_entered(area: Area2D)         # an Area2D entered THIS body

## Trigger cookbook

### Pickup

```gdscript
# res://pickup/coin.gd
extends Area2D
func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.add_coin(1)
        queue_free()
```

### Damage zone (throttled)

```gdscript
# res://hazards/spike.gd
extends Area2D
@export var damage_per_tick := 1
@export var tick_interval := 0.5
var _timer: float = 0.0
var _bodies_in: Array[Node2D] = []

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(b: Node2D) -> void:
    if b.is_in_group("player"):
        _bodies_in.append(b)
        _timer = 0.0

func _on_body_exited(b: Node2D) -> void:
    _bodies_in.erase(b)

func _process(delta: float) -> void:
    if _bodies_in.is_empty(): return
    _timer += delta
    if _timer >= tick_interval:
        _timer = 0.0
        for b in _bodies_in:
            if b.has_method("take_damage"):
                b.take_damage(damage_per_tick)
```

### Detection (AI vision)

```gdscript
extends Area2D
@export var vision_range := 200.0
func _ready() -> void:
    pass
func _on_body_entered(b: Node2D) -> void:
    if b.is_in_group("player"):
        owner.can_see_player = true
        owner.last_known_position = b.global_position
func _on_body_exited(b: Node2D) -> void:
    if b.is_in_group("player"):
        owner.can_see_player = false
```

## Monitoring vs monitorable

| Setting | Means | Damage zone needs? | Pickup needs? |
|---------|-------|--------------------|----------------|
| monitoring = true | area detects others via its mask | YES (sees bodies) | (usually false) |
| monitorable = true | others detect this area via their mask | (usually false) | YES (seen by player) |

Damage zone: monitoring = true, monitorable = false.
Pickup hitbox on player: monitoring = false, monitorable = true.

## Type the signal parameter

```gdscript
# Right — editor catches mismatches
func _on_body_entered(body: Node2D) -> void: ...

# Wrong — runtime error if wrong type arrives
func _on_body_entered(body) -> void: ...
```
