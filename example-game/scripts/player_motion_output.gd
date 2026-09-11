extends RefCounted
## Output type for Player.compute_motion (pure function).
## Holds the post-physics-tick state in a typed shape, so callers don't pay Variant dispatch
## and the analyzer catches field-name typos at edit time.

class_name PlayerMotionOutput

var linear_velocity: Vector2 = Vector2.ZERO
var should_jump: bool = false
var new_coyote_timer: float = 0.0
var new_jump_buffer_timer: float = 0.0
