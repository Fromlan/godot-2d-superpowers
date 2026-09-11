# Collision Layers (deep dive)

Reference for SKILL.md §2 + §8.

## The 32-bit bitfield

Bit 31 ... 8 7 6 5 4 3 2 1 0
LAYER_PLAYER = 1
LAYER_ENEMY = 2
LAYER_WORLD = 4
LAYER_PICKUP = 8
LAYER_HAZARD = 16
LAYER_PROJECTILE = 32
LAYER_VISION = 64
LAYER_PREDICTION = 128

collision_layer = "what I am" (bits I broadcast).
collision_mask = "what I collide with" (bits I check).

A collision happens iff both directions match:
(A.mask & B.layer) != 0  AND  (B.mask & A.layer) != 0

## Layer naming convention (autoload)

```gdscript
# res://autoloads/layer_names.gd
extends Node
const LAYER_PLAYER     := 1 << 0
const LAYER_ENEMY      := 1 << 1
const LAYER_WORLD      := 1 << 2
const LAYER_PICKUP     := 1 << 3
const LAYER_HAZARD     := 1 << 4
const LAYER_PROJECTILE := 1 << 5
const LAYER_VISION     := 1 << 6
const LAYER_PREDICTION := 1 << 7
```

In Project Settings → Layer Names → 2D Physics, register the names — the Inspector shows them by name.

## Common project layouts

**Platformer** (8 layers enough):
- player / enemy / world / pickup / hazard / projectile / vision / prediction

**Top-down / Roguelike** (10+ layers):
- player / enemy / ally / neutral_npc / world / pickup / hazard / projectile / vision / trigger / prediction

**Multi-team** (12+):
- add team1 / team2 / team3 / team4 to allow team-vs-team without enemy=ally confusion

## Common mistakes

| Mistake | Fix |
|---------|-----|
| collision_mask = 0xFFFFFFFF (all bits) | use only the bits you actually need; "detect everything" usually means bugs |
| Both bodies on same layer, neither mask includes each other | one of them needs that layer in its mask |
| Area2D doesn't fire body_entered | monitoring is off, or the other body isn't in the mask |
| Walls block projectiles | projectiles' mask includes world layer — usually wrong if they're homing |
