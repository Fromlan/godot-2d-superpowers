# AnimationTree + StateMachine (deep dive)

Reference for SKILL.md §4 + §5.

## When to use AnimationTree

- Character with 5+ named states (idle / walk / run / attack / hurt / die)
- Transitions depend on multiple conditions (is_attacking AND is_grounded)
- Need blending between two animations (idle → run smoothly)

For 2-3 states with simple condition, AnimationPlayer + script is fine.

## Editor setup

1. Add AnimationTree node as child of the character root
2. In Inspector, tree_root → New AnimationNodeStateMachine
3. Inside the state machine:
   - Add states (each = one AnimationNodeAnimation pointing to an animation in AnimationLibrary)
   - Add transitions between states
   - Each transition has: switch_mode (IMMEDIATE / SYNC / AT_END), advance mode, conditions
4. Set AnimationPlayer reference on the tree's anim_player property

## In code: drive conditions

```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
    anim_tree.active = true

func _physics_process(_delta: float) -> void:
    anim_tree.set("parameters/conditions/is_attacking", _is_attacking)
    anim_tree.set("parameters/conditions/is_grounded", is_on_floor())
    anim_tree.set("parameters/conditions/want_jump", Input.is_action_just_pressed("jump"))
    anim_tree.set("parameters/IdleRun/blend_position", _speed / max_speed)
```

## Transition types

| Type | When to use |
|------|-------------|
| Immediate | Cut-style (damage → hurt) |
| Sync | Same-length animations |
| At End | Wait for current to finish (attack → idle when attack finishes) |
| Auto | When all conditions true (default) |
| Disabled | Triggered only by travel() |

## Common bug patterns

| Symptom | Cause | Fix |
|---------|-------|-----|
| Transitions never fire | condition never set to true in parameters/conditions/... | check param name matches editor exactly |
| State stuck in loop | cycle of transitions all true | add hysteresis (min time in state) |
| Blend looks popped | blend param updated outside [-1, 1] | clamp before set("parameters/...blend_position", ...) |
| AnimationTree signals don't fire | connected to AnimationPlayer, not AnimationTree | use anim_tree.anim_player.animation_finished.connect(...) |
