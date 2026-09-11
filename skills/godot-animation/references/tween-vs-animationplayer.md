# Tween vs AnimationPlayer (deep dive)

Reference for SKILL.md §1 + §2 + §3.

## When to use which

| Scenario | Tween | AnimationPlayer |
|----------|-------|-----------------|
| One property, ~0.1-0.5s, code-first | yes | overkill |
| Multi-property choreography, 1-30s, designer-authored | no | yes |
| Designer needs to scrub timeline | no | yes |
| Animation must run without code changes | no | yes (resources in .tres) |
| Quick iteration in code | yes | no (editor round-trip) |
| Designer-friendly tweak without coder | no | yes |

Rule of thumb: Tween for "I need this one thing to change smoothly"; AnimationPlayer for "I have a hand-authored sequence".

## Tween cheat sheet

```gdscript
var t := create_tween()
t.set_parallel(true)
t.set_trans(Tween.TRANS_QUAD)
t.set_ease(Tween.EASE_OUT)
t.tween_property(node, "modulate", Color.RED, 0.08)
t.tween_property(node, "scale",   Vector2.ONE * 1.15, 0.08)
# Sequential follow-up
t.tween_property(node, "position", original_pos, 0.15)
```

- set_parallel(true): all subsequent tween_property calls run at the same time
- chain(): closes the parallel group, next call starts after all parallel finish
- tween_interval(s): insert a delay
- tween_callback(callable): call a function mid-tween
- set_loops(N): ping-pong; LOOP_PING_PONG / LOOP_LINEAR
- kill(): stop the tween early

## AnimationPlayer cheat sheet

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func play(name: String) -> void:
    anim.play(name)

func play_with_crossfade(name: String, fade := 0.2) -> void:
    anim.play(name, fade)

signal attack_landed
func _on_anim_animation_finished(anim_name: StringName) -> void:
    if anim_name == &"attack":
        attack_landed.emit()
```

## queue() vs play() vs stop()

| Call | Behavior |
|------|----------|
| play("a") | start "a" immediately, replacing current |
| play("a", 0.2) | start "a" with 0.2s crossfade from current |
| queue("a") | when current ends, start "a" |
| stop() | halt; fires animation_finished with the stopped name |
| pause() / play() | toggle without restarting |

## Common mistake: play() in _ready()

```gdscript
# Wrong — ordering issues with signals / not-yet-in-tree
func _ready() -> void:
    anim.play("idle")

# Right — defer to next idle frame
func _ready() -> void:
    call_deferred("play", "idle")
```

## Cost vs benefit

| Cost | Mitigation |
|------|------------|
| Many AnimationPlayers per frame | share AnimationLibrary across players |
| Long animations evaluated every frame | lower keyframe rate (0.05s instead of 0.01s) |
| Visual jitter | move transform animation to IDLE, movement to PHYSICS |
