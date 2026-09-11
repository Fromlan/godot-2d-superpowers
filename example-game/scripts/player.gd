extends CharacterBody2D
## Player controller for the example 2D platformer.
## Demonstrates: @export, @onready, signals, move_and_slide, pure function extraction.

signal health_changed(new_health: int)
signal died

@export var max_speed: float = 280.0
@export var acceleration: float = 1500.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -480.0
@export var gravity: float = 980.0
@export var max_health: int = 3
@export var coyote_time: float = 0.08
@export var jump_buffer: float = 0.1

@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var health: int = 0:
    set(value):
        var clamped := clampi(value, 0, max_health)
        if clamped == health:
            return
        health = clamped
        health_changed.emit(health)
        if health == 0:
            died.emit()

func _ready() -> void:
    health = max_health

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_axis("move_left", "move_right")
    var motion := compute_motion(
        velocity, input_dir, is_on_floor(), delta,
        max_speed, acceleration, friction, jump_velocity, gravity
    )
    velocity = motion.linear_velocity
    _coyote_timer = motion.new_coyote_timer
    _jump_buffer_timer = motion.new_jump_buffer_timer

    if motion.should_jump and (is_on_floor() or _coyote_timer > 0.0):
        velocity.y = jump_velocity
        _coyote_timer = 0.0

    move_and_slide()
    _update_animation(input_dir)

func _update_animation(input_dir: float) -> void:
    if not is_on_floor():
        if velocity.y < 0:
            anim.play("jump")
        else:
            anim.play("fall")
    elif abs(input_dir) > 0.1:
        anim.play("run")
    else:
        anim.play("idle")

func take_damage(amount: int) -> void:
    health -= amount

# === Pure functions (TDD-friendly, see tests/test_player_physics.gd) ===

static func compute_motion(
    prev_velocity: Vector2,
    input_dir: float,
    grounded: bool,
    delta: float,
    max_speed: float,
    acceleration: float,
    friction: float,
    jump_velocity: float,
    gravity: float
) -> PlayerMotionOutput:
    var out := PlayerMotionOutput.new()
    out.linear_velocity = prev_velocity

    # Gravity
    if not grounded:
        out.linear_velocity.y += gravity * delta

    # Horizontal movement
    if abs(input_dir) > 0.01:
        out.linear_velocity.x = move_toward(out.linear_velocity.x, input_dir * max_speed, acceleration * delta)
    else:
        out.linear_velocity.x = move_toward(out.linear_velocity.x, 0.0, friction * delta)

    return out
