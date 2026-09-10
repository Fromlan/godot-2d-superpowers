extends Node
## Global game state. Autoloaded as GameManager.

signal score_changed(new_score: int)
signal game_over

var score: int = 0:
    set(value):
        if value == score:
            return
        score = value
        score_changed.emit(score)

var is_game_over: bool = false

func reset() -> void:
    score = 0
    is_game_over = false

func add_score(amount: int) -> void:
    score += amount

func trigger_game_over() -> void:
    if is_game_over:
        return
    is_game_over = true
    game_over.emit()
