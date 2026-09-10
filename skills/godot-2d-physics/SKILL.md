---
name: godot-2d-physics
description: |
  Godot 4.7 2D 物理 / Body 选择 / 碰撞层级 / Area2D 触发器 / CharacterBody2D 移动 / 拖拽检测。Use when the user mentions "Godot 物理"、"2D 碰撞"、"Area2D"、"CharacterBody"、"RigidBody"、"collision_layer"、"碰撞层"、"范围攻击"、"触发器"、"拖拽判定"、"move_and_slide"、"is_on_floor". Do NOT use for 3D physics or pure UI drag (see godot-ui-best-practices). Read-only; applies rules when building / fixing Godot 2D scenes.
last_reviewed: 2026-09-10
---

<!-- argument-hint: [body type or topic, e.g. 'CharacterBody2D', 'collision_layer', 'Area2D 触发器'] -->

# Godot 2D Physics (4.7)

Actionable rules for Godot 4 2D physics. Each rule states the failure mode, the fix, and a one-liner. Deep dives in `references/<topic>.md`.

## 1. The body decision matrix

Pick the body by what controls motion, not what it "is":

| Use case | Body | Why |
|last_reviewed: 2026-09-10
---|---|---|
| Player, NPC, anything you move with logic each frame | `CharacterBody2D` | you drive `velocity` and call `move_and_slide`; deterministic, frame-accurate input |
| Crate, ball, debris, ragdoll, anything the engine should simulate | `RigidBody2D` | gravity, impulses, friction handled by the physics server |
| Trigger / pickup / damage zone / drag hit-test | `Area2D` | overlap detection only, no physics response |
| Static level geometry (walls, floor, platforms) | `StaticBody2D` | immobile, optimized for non-moving colliders |

**The wrong call**: `RigidBody2D` for the player. The physics server is non-deterministic across machines (bad for replays / multiplayer), and your input gets blended with gravity in ways you can't fully control. `CharacterBody2D` is the right answer for "I move this with code".

## 2. `collision_layer` vs `collision_mask` — the 32-bit bitfield

Every `CollisionObject2D` (parent of Area2D, CharacterBody2D, etc.) has two bitfields:

- `collision_layer` — **what I am** (bits I broadcast)
- `collision_mask` — **what I collide with** (bits I check against)

A collision happens iff (A's mask & B's layer) != 0 AND (B's mask & A's layer) != 0.

```
Player.collision_layer   = 0b0001  (LAYER_PLAYER)
Player.collision_mask    = 0b1110  (everything except LAYER_PLAYER)

Enemy.collision_layer    = 0b0010  (LAYER_ENEMY)
Enemy.collision_mask     = 0b0001  (only sees Player)

Wall.collision_layer     = 0b0100  (LAYER_WORLD)
Wall.collision_mask      = 0b0011  (sees Player + Enemy)
```

**Why this beats `if`-checks**: changing a body's "what I hit" is a one-field edit in the Inspector, no code change, no "I forgot to update both objects" bug.

**`Area2D` rule**: Area2D's `monitoring` (broadcasts `area_entered`) vs `monitorable` (others can detect it via their mask). For a damage zone: `monitoring = true` so it sees bodies; for a pickup hitbox on a player: `monitorable = true` so pickups can detect it.

## 3. Area2D signal-driven triggers

`Area2D` is for overlap-only. The signals:

```gdscript
# On Area2D node
signal_pairs = {
    "area_entered": "another Area2D entered me",
    "area_exited":  "another Area2D left me",
    "body_entered": "a CharacterBody2D / RigidBody2D / TileMap entered me",
    "body_exited":  "a body left me",
}
# On CollisionObject2D (any body)
"area_entered": "an Area2D entered this body",
```

Connect in code or via the editor's Signals panel. Type the signal parameter so the editor catches errors:

```gdscript
func _on_pickup_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.add_coin()
        queue_free()
```

For damage zones, use a `Timer` to throttle: the zone shouldn't fire every frame the body is inside.

## 4. CharacterBody2D movement template

```gdscript
extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -380.0
const GRAVITY := 980.0

@export var can_double_jump := false

func _physics_process(_delta: float) -> void:
    # Add gravity
    if not is_on_floor():
        velocity.y += GRAVITY * _delta

    # Jump
    if Input.is_action_just_pressed(&"jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Horizontal
    var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    velocity.x = dir.x * SPEED

    move_and_slide()
```

`move_and_slide` moves the body, applies velocity, and slides along walls. Returns `true` if the body collided. `is_on_floor()` reads the last collision's floor flag.

**Use `_physics_process`, not `_process`** for any movement. Physics ticks at `physics_fps` (default 60). Variable timestep `_process` causes frame-rate-dependent physics.

**`move_and_slide` vs collision-query patterns** (Godot 4):
- `move_and_slide()` — slide along walls; keep moving along velocity. Returns `true` if any slide occurred. Default for players / NPCs.
- For projectile / one-shot patterns, call `move_and_slide()` once, then iterate `get_slide_collision_count()` / `get_slide_collision(i)` to read the `KinematicCollision2D`.
- `test_move(motion)` — non-destructive test (does not actually move the body). Use for "would I collide if I moved by X?" checks.
- **Note**: CharacterBody2D has **no** `move_and_collide` (that was Godot 3 KinematicBody2D). Use `move_and_slide` + `get_slide_collision` instead.

## 5. Top-down 2D movement (no gravity, no floor)

Z-2 is a top-down auto-chess; pieces don't fall. Drop the gravity / jump logic:

```gdscript
extends CharacterBody2D
const SPEED := 220.0

func _physics_process(_delta: float) -> void:
    var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    velocity = dir * SPEED
    move_and_slide()
```

That's it. No `is_on_floor` checks, no gravity.

## 6. Drag hit-test with Area2D `input_event` (replaces custom `hit_radius`)

The Z-2 board currently uses a custom `hit_radius` field on `Piece` and an `Area2D`-less manual loop. Replace with `Area2D` on each piece:

```gdscript
# On each piece (Node2D + Area2D + CollisionShape2D)
@onready var area: Area2D = $Area2D

func _ready() -> void:
    area.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # 通知 Battle 拖拽这个 piece
        battle.begin_drag(self, event.position)
```

**Why better than custom `hit_radius`**:
- `Area2D` does its own spatial query, including rotation and shape precision (Rectangle / Circle / Capsule)
- Multiple `Area2D`s can be on a single piece (e.g. clickable body + larger "selection range")
- The `CollisionShape2D` is the visual + clickable; no separate `hit_radius` field to keep in sync

Trade-off: each piece gets a CollisionShape2D, which adds a tiny CPU cost per spatial query. For 10-50 pieces on a 9×9 board, this is negligible.

## 7. CollisionShape2D choice

| Shape | Use | Notes |
|---|---|---|
| `RectangleShape2D` | axis-aligned boxes (cards, walls) | cheapest |
| `CircleShape2D` | round things (coins, orbs) | rotation-invariant; great for click hitboxes |
| `CapsuleShape2D` | characters with height (platformer) | 2D analog of capsule |
| `SegmentShape2D` | thin lines (platform edges, sword arc) | 1D collision |
| `WorldBoundaryShape2D` | infinite plane (floor, walls of arena) | only StaticBody2D |
| `ConvexPolygonShape2D` | irregular shapes | up to 8 vertices; use `CollisionPolygon2D` for child-defined points |
| `SeparationRayShape2D` | 1D raycast | CharacterBody2D only, for "is there a wall in front of me" |

For a top-down 2D piece: `CircleShape2D` with radius matching visual extent.

## 8. Layer-bit naming convention

In an autoload (`layer_names.gd` or similar):

```gdscript
const LAYER_PLAYER     := 1 << 0   # 1
const LAYER_ENEMY      := 1 << 1   # 2
const LAYER_WORLD      := 1 << 2   # 4
const LAYER_PICKUP     := 1 << 3   # 8
const LAYER_HAZARD     := 1 << 4   # 16
const LAYER_PROJECTILE := 1 << 5   # 32
const LAYER_VISION     := 1 << 6   # 64  (AI sees you)
const LAYER_PREDICTION := 1 << 7   # 128 (ghost bodies, ignored by gameplay)
```

Reference by constant, not by raw number. The editor also has a bitfield editor (top of any CollisionObject2D inspector) where you tick bits by name if you set the project's layer names in **Project Settings → Layer Names → 2D Physics**.

## 9. `physics_fps` tuning

Default 60. Lower for slow sims (RTS, large worlds) to save CPU; raise for fighting games (frame-perfect hits).

```ini
[physics]
common/physics_fps = 60
```

Tied to `_physics_process` interval. If you set `physics_fps = 30`, `_physics_process(delta)` receives `delta ≈ 0.0333`. Velocity-driven movement scales correctly (multiply by delta), so 30 Hz physics doesn't slow the world.

**Anti-pattern**: setting `physics_fps = 1000` to "fix" jitter. The fix is in your code (smoothing, sub-stepping). 1000 Hz burns CPU for nothing.

## 10. `_process` vs `_physics_process` — when each

| Use | Where |
|---|---|
| Movement (`move_and_slide`, `move_and_collide`) | `_physics_process` |
| Reading physics state (collisions, overlaps) | `_physics_process` (or signals from Area2D / body) |
| Visual interpolation (smooth between physics ticks) | `_process` |
| AI decisions (targeting, pathing) | either; `_process` for smoother, `_physics_process` for tick-aligned |
| Input response | `_process` or `_unhandled_input` |
| Tween animations | `_process` (or via `Tween` autoplay) |

Mix them when needed: a CharacterBody moves in `_physics_process`, but its sprite smoothly interpolates in `_process` between physics ticks for high-Hz visuals.

## Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| Player falls through floor | `collision_mask` doesn't include `LAYER_WORLD` | 2 |
| `area_entered` never fires | `monitoring` off, or both bodies on same layer not in each other's mask | 2 + 3 |
| `move_and_slide` doesn't move | velocity is zero, or `freeze` / `freeze_mode` set | 4 |
| Wall sliding doesn't work | `slide_on_ceiling = false`, or wall's normal edge is unreachable | 4 |
| Body jittery on slopes | `up_direction` is wrong, or `floor_max_angle` too small | 4 |
| Drag still misses clicks | `Area2D` has no `CollisionShape2D`, or shape is at wrong position | 6 + 7 |
| Bodies collide with everything | `collision_mask` = 0xFFFFFFFF (all bits set) | 2 |
| Area2D detects self | `monitorable = true` and own body is on a watched layer | 2 |

## Reference index

- `references/body-decision.md` — 4 body types, full comparison with code templates
- `references/collision-layers.md` — 32-bit layer bits, common project layouts
- `references/area-signals.md` — Area2D signal matrix, trigger pattern cookbook

## Output contract

Read-only knowledge. Apply the rules when writing / fixing Godot 2D physics code. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If a physics bug doesn't match any rule above, the bug is either:
- Layer/mask misconfiguration (Rule 2) — print `print(self.collision_layer, " ", self.collision_mask)` and the other body
- Shape geometry wrong (Rule 7) — visualize `CollisionShape2D` in the editor with "Visible Collision Shapes" on
- Custom code driving motion wrong (Rule 4 / 5) — print `position` before / after `move_and_slide`

If still stuck, fall back to the four diagnostics in `references/body-decision.md`.
