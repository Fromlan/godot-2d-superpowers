extends CharacterBody2D
## Simple patrolling enemy.

@export var patrol_distance: float = 120.0
@export var speed: float = 80.0
@export var damage: int = 1

@onready var start_x: float = global_position.x
@onready var sprite: Sprite2D = $Sprite

var _direction: int = 1

func _physics_process(delta: float) -> void:
    velocity.x = speed * _direction
    if global_position.x > start_x + patrol_distance:
        _direction = -1
    elif global_position.x < start_x - patrol_distance:
        _direction = 1
    sprite.flip_h = _direction < 0
    move_and_slide()

func _ready() -> void:
    $DamageArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player") and body.has_method("take_damage"):
        body.take_damage(damage)
