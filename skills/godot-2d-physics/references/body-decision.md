# Body Decision Matrix (deep dive)

Reference for SKILL.md §1.

## Full comparison

| Body | Inputs | Outputs | Simulated by | Determinism | Use case |
|------|--------|---------|--------------|-------------|----------|
| CharacterBody2D | velocity (you drive) | collision result | your code via move_and_slide | fully deterministic | player / NPC / boss / anything logic-driven |
| RigidBody2D | impulses / forces | position, rotation | physics server | non-deterministic across machines | crates, balls, ragdoll, debris |
| Area2D | none | overlap events | overlap queries | deterministic | triggers, pickups, damage zones, hit-tests |
| StaticBody2D | none | collision result | physics server | fully static | level geometry, walls, floors |

## Code template: CharacterBody2D vs RigidBody2D

```gdscript
# CharacterBody2D (preferred for player)
extends CharacterBody2D
const SPEED := 220.0
@export var gravity := 980.0
func _physics_process(delta: float) -> void:
    if not is_on_floor(): velocity.y += gravity * delta
    velocity.x = Input.get_axis("move_left","move_right") * SPEED
    move_and_slide()

# RigidBody2D (engine simulates; YOU apply impulses)
extends RigidBody2D
@export var throw_force := 800.0
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("throw"):
        apply_impulse(Vector2.RIGHT * throw_force)
```

## Why CharacterBody2D for player

- Input → velocity → move_and_slide is a 1:1 mapping; you know the next frame's state
- Frame-rate independent because _physics_process ticks at physics_fps (default 60)
- Replay-friendly: the same input produces the same trajectory
- RigidBody2D blends your impulses with physics solver → results drift between machines

## When RigidBody2D is correct

- A crate on a slope, knocked by the player's melee: gravity + impulses are exactly what you want
- A ragdoll on death: physics solver handles joint constraints
- Anything with momentum that the player doesn't directly control each frame

## Pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| Player can't move up slopes smoothly | floor_max_angle too low (default 45 deg) or wrong up_direction | floor_max_angle = deg_to_rad(60) if slopes are steep |
| RigidBody player feels mushy | gravity blends with your input | switch to CharacterBody2D |
| CharacterBody slides through walls | velocity set, but freeze enabled | remove freeze / freeze_mode |
| Player gets stuck on seams | tiles have separate StaticBody2D per cell | merge into single StaticBody2D with multiple shapes |
