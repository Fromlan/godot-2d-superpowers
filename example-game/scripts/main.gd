extends Node2D
## Main scene controller.

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
    GameManager.reset()
    hud.bind_player(player)
    player.died.connect(_on_player_died)
    for coin in get_tree().get_nodes_in_group("coins"):
        coin.collected.connect(_on_coin_collected)

func _on_player_died() -> void:
    GameManager.trigger_game_over()

func _on_coin_collected() -> void:
    GameManager.add_score(1)
