# AnimatedSprite2D flipbook (deep dive)

Reference for SKILL.md §1.

## Use case

A sprite sheet with discrete frames (idle / run / attack / die) flipped frame-by-frame. Cheaper than AnimationPlayer for simple sprite cycles.

## SpriteFrames resource

Create in editor: SpriteFrames (.tres). One resource per character / effect.

- Each Animation = a named state ("idle", "run", "attack")
- Frames = texture + per-frame atlas rects
- fps = frames per second
- loop = whether animation_finished re-fires

### Naming convention

assets/animations/<scope>_<subject>.tres
- player_idle.tres, enemy_slime.tres, explosion_fire.tres

### Frame naming for atlas

If using Texture → Atlas, frames must be named <name>_<idx> zero-padded:
- player_run_001.png, player_run_002.png, ..., player_run_024.png

Godot's SpriteFrames sorts frames lexicographically; zero-pad to keep order.

## AnimatedSprite2D code

```gdscript
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    sprite.sprite_frames = preload("res://assets/animations/player.tres")
    sprite.play("idle")

func _process(_delta: float) -> void:
    if not is_on_floor():
        sprite.play("fall" if velocity.y > 0 else "jump")
    elif abs(velocity.x) > 0.1:
        sprite.play("run")
    else:
        sprite.play("idle")

func attack() -> void:
    sprite.play("attack")
    await sprite.animation_finished
    sprite.play("idle")
```

## AnimatedSprite2D vs AnimationPlayer (sprite)

| Need | Use |
|------|-----|
| Pure sprite cycles, no transform | AnimatedSprite2D |
| Sprite cycle + position/scale/rotate change | AnimationPlayer (single track covers all) |
| Sprite cycle + state machine | AnimationTree + StateMachine |

## Cost vs AnimationPlayer

AnimatedSprite2D uses 1 GPU draw call per frame change; AnimationPlayer uses keyframes. For 10+ identical enemies, prefer single sprite sheet resource shared across instances.

## Pitfall: pixel art + linear filter

Make sure texture filtering is Nearest (Import Dock preset "2D Pixel", or `CanvasItem.texture_filter` / project `canvas_textures/default_texture_filter`), otherwise sprite cycles look blurry. See asset-pipeline skill §3.1.
