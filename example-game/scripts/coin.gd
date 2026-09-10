extends Area2D
## Collectible coin.

signal collected

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        collected.emit()
        queue_free()
