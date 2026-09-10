extends CanvasLayer
## Heads-up display: health, score, restart button.

@onready var health_label: Label = $Panel/Margin/VBox/HealthLabel
@onready var score_label: Label = $Panel/Margin/VBox/ScoreLabel
@onready var restart_btn: Button = $Panel/Margin/VBox/RestartButton
@onready var gameover_label: Label = $GameOverLabel

var _player: Node = null

func _ready() -> void:
    GameManager.score_changed.connect(_on_score_changed)
    GameManager.game_over.connect(_on_game_over)
    restart_btn.pressed.connect(_on_restart_pressed)
    gameover_label.visible = false

func bind_player(p: Node) -> void:
    _player = p
    p.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int) -> void:
    health_label.text = "HP: %d" % new_health

func _on_score_changed(new_score: int) -> void:
    score_label.text = "Score: %d" % new_score

func _on_game_over() -> void:
    gameover_label.visible = true

func _on_restart_pressed() -> void:
    get_tree().reload_current_scene()
