---
name: godot-animation
description: |
  Godot 4.7 动画:Tween、AnimationPlayer、AnimationTree/StateMachine、AnimatedSprite2D 选型与生命周期。Use when 提到"Tween"、"AnimationPlayer"、"StateMachine"、"精灵动画"、"缓动"、"动画状态机"。Do NOT use for 一次性 UI hover(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [animation type, e.g. 'Tween', 'AnimationTree', 'state machine'] -->

# Godot Animation (4.7)

Actionable rules for Godot 4 animation: when to use Tween vs AnimationPlayer vs AnimationTree vs AnimatedSprite2D, plus state machine patterns. Deep dives in `references/<topic>.md`.

## 1. The 4-way decision tree

Pick the animation API by what you're animating and why:

| Question | Answer | Use |
|last_reviewed: 2026-09-10
---|---|---|
| One property, one transition, ~0.1-0.5s | "Yes" | `Tween` |
| Multiple properties on a timeline, 1-30s | "Yes" | `AnimationPlayer` |
| Multiple named states with transitions, character behavior | "Yes" | `AnimationTree` + StateMachine |
| Sprite-sheet flipbook (idle/walk/attack frames) | "Yes" | `AnimatedSprite2D` |
| Just a single "modulate to red then back" hit flash | "Yes" | `Tween` |
| A complex combat move with 50 keyframed properties | "Yes" | `AnimationPlayer` |
| Boss with 6 states (idle/attack/hurt/die/summon/teleport) | "Yes" | `AnimationTree` |
| A 4-frame walk loop from a sprite sheet | "Yes" | `AnimatedSprite2D` |

**Rule of thumb**:
- Tween for "I need this one thing to change smoothly" (always procedural in code)
- AnimationPlayer for "I have a hand-authored sequence" (visual editor)
- AnimationTree for "I have multiple sequences and need to blend / transition" (state machine)
- AnimatedSprite2D for "I have a sprite sheet with frames" (frame-by-frame)

## 2. Tween — quick reference

Tweens are covered in detail in `godot-ui-best-practices` Rule 6. Highlights:

```gdscript
var t := create_tween()
t.set_parallel(true)
t.tween_property(node, "modulate", Color(1.4, 1.4, 1.0), 0.08)
t.tween_property(node, "scale", Vector2.ONE * 1.15, 0.08)
```

For attack effects: a flash + a scale pulse + a position reset is 3 `tween_property` calls in one `tween` (set `set_parallel(true)` for the first two, then a sequential one for the reset).

**Tween vs AnimationPlayer**: same outcome, different authoring. Tween = code-first, fast iteration. AnimationPlayer = visual editor, designer-friendly, scrubbable timeline.

For 90% of one-shot effects (hit flash, drag highlight, menu slide), Tween is fine. Reach for AnimationPlayer when you want designers to iterate without code edits.

## 3. AnimationPlayer — when you need a timeline

Use when:
- The animation is "designed" (an animator authored it)
- Multiple properties change together (position + rotation + scale + modulate)
- You want to scrub the timeline in the editor
- The animation might be reused (e.g. "walk" plays on multiple characters)

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func play_animation(name: String) -> void:
    anim.play(name)

func play_with_crossfade(name: String, fade := 0.2) -> void:
    anim.play(name, fade)  # second arg = crossfade time

# Wait for animation to finish
signal attack_landed
func _on_anim_animation_finished(anim_name: StringName) -> void:
    if anim_name == "attack":
        attack_landed.emit()
```

Connect `animation_finished` signal. The parameter is the animation name; check if it's the one you care about.

**Call `play()` deferred during `_ready`**: animations played directly in `_ready` of a node that's not yet in the tree can have ordering issues. Use `call_deferred("play", "name")` to schedule after the tree settles.

## 4. AnimationTree + StateMachine — character behavior

For complex characters (boss, enemy with multiple moves), `AnimationTree` with a `StateMachine` is the canonical pattern.

In the editor:
1. Add `AnimationTree` node
2. Set `tree_root` to a new `AnimationNodeStateMachine` resource
3. Add states (each state = one animation)
4. Add transitions between states (with conditions)
5. Connect transitions to triggers / booleans / other conditions

In code:

```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
    anim_tree.active = true
    anim_tree.anim_player.connect("animation_finished", _on_anim_finished)

func request_state(name: String) -> void:
    # Set a parameter on the StateMachine (e.g. a trigger or boolean)
    anim_tree.set("parameters/conditions/" + name, true)
```

For Z-2 style auto-chess: characters don't need AnimationTree (combat is auto, no player input). Use it for the boss enemy in a future chapter.

## 5. State transition patterns

AnimationTree StateMachine has 4 transition types:

| Type | Behavior | Use |
|---|---|---|
| **Immediate** | jump now, no blend | death, hard cutscenes |
| **Sync** | wait for current to reach same time position | cutscenes with sync |
| **At End** | wait for current to finish | attack → idle after attack ends |

Most game state transitions are "At End" (play attack fully, then return to idle).

For "request" pattern (player presses attack during idle):
1. Set a `request_attack` condition in the StateMachine
2. StateMachine has `idle → attack` transition with condition `request_attack`
3. Attack plays; transition `attack → idle` is "At End" of attack
4. `request_attack` auto-resets after transition

## 6. `queue()` and `play()` semantics

| Call | Behavior |
|---|---|
| `play("a")` | start "a" immediately, replacing whatever is playing |
| `play("a", 0.2)` | start "a" with 0.2s crossfade from current |
| `queue("a")` | when current animation finishes, start "a" |
| `stop()` | halt; the animation is no longer playing |
| `pause()` / `play()` | toggle playback without restarting |

`play()` is restart. To "play if not playing", check first:

```gdscript
if not anim.is_playing() or anim.current_animation != "attack":
    anim.play("attack")
```

Or use `queue()` for sequencing ("attack", then on finish, "idle"):

```gdscript
anim.play("attack")
anim.queue("idle")
```

## 7. `animation_finished` signal

Fires when a non-looping animation reaches its end, OR when manually stopped mid-way.

```gdscript
anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: StringName) -> void:
    match anim_name:
        &"attack":
            _apply_attack_damage()
            _return_to_idle()
        &"death":
            queue_free()
        &"_":
            pass  # wildcard
```

For AnimationTree, the signal comes from the underlying `AnimationPlayer`. Connect via `anim_tree.anim_player.animation_finished`.

**Looping animations** (`loop = true` in the inspector) don't fire `animation_finished` per loop iteration. They fire only when `stop()` is called or the animation manually ends.

## 8. `call_deferred` for `play()` in `_ready`

Direct `play()` in `_ready` can have ordering issues with signals, other components starting up, etc.:

```gdscript
func _ready() -> void:
    # Right:
    call_deferred("play", "idle")

func play(name: String) -> void:
    $AnimationPlayer.play(name)
```

`call_deferred` schedules the call for the next idle frame, after the tree is fully built.

## 9. GPUParticles2D with AnimationPlayer

For "play VFX on attack":

```gdscript
# VFX node:
# - GPUParticles2D (with process_material)
# - AnimationPlayer with "play" anim that sets emitting=true and resets time

func play_attack_vfx() -> void:
    $VFX/AnimationPlayer.play("play")
```

The AnimationPlayer's "play" animation has 2 keyframes:
- 0.0s: `emitting = true`, `restart = true` (resets the particle system)
- 0.0s: end the animation (1 frame duration)

Particle system auto-clears when `emitting` is set to false. To control lifetime explicitly, set `lifetime` on GPUParticles2D.

## 10. Animation performance

| Cost | Mitigation |
|---|---|
| Animating `position` on many nodes | batch into a single parent; animate parent |
| Many `AnimationPlayer`s updating every frame | share animations between players (set `animation` resource) |
| Long animations evaluated every frame | keyframe at lower rate (0.05s instead of 0.01s) |
| `process_callback` set to `IDLE` (default) for visual anims; `PHYSICS` for movement | keep movement keyframed in PHYSICS to align with physics ticks |

For Z-2's 9×9 board with 10-20 pieces, AnimationPlayer cost is negligible. The concern is for hundreds of simultaneously animating nodes (UI tween + 50 particles + 20 enemies).

## Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| Animation never starts | `play()` called in `_ready` of a not-yet-in-tree node | 8 |
| Animation restarts from 0 instead of continuing | `play()` re-called; use `queue()` or check `is_playing` | 6 |
| Crossfade looks "popped" | Crossfade too short; or animations have different first frames | 3 |
| `animation_finished` fires for looping anim | Animation not set to `loop = true`; or `stop()` was called | 7 |
| AnimTree transitions don't fire | Transition condition never set in code | 4 |
| State machine stuck | Cycle of transitions; or condition always true | 4 |
| Particle "explodes once" then never again | `restart = true` not in animation, or process_material doesn't reset | 9 |
| `play()` returns OK but nothing happens | AnimationLibrary empty, or animation name typo | 3 |

## Reference index

- `references/tween-vs-animationplayer.md` — decision tree, side-by-side examples
- `references/animationtree-statemachine.md` — full state machine code + inspector walkthrough
- `references/animatedsprite-flipbook.md` — sprite sheet import + flipbook config

## Output contract

Read-only knowledge. Apply the rules when building / fixing Godot animations. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If an animation bug doesn't match any rule above:
- AnimationPlayer: print `anim.current_animation`, `anim.is_playing()`, `anim.current_animation_position` to see state
- AnimationTree: print `anim_tree.get("parameters/playback")` to see current state
- AnimatedSprite2D: print `sprite.frame`, `sprite.animation`, `sprite.is_playing()`

If still stuck, fall back to the four diagnostics in `references/tween-vs-animationplayer.md`.
