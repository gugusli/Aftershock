extends Node

# =========================
# SIGNAL
# =========================
signal game_state_changed(new_state)

# =========================
# ESTADOS DEL JUEGO
# =========================
enum GameState {
	PLAYING,
	GAME_OVER,
	VICTORY
}

# =========================
# ESTADO ACTUAL
# =========================
var game_state : GameState = GameState.PLAYING

# =========================
# READY
# =========================
func _ready() -> void:
	print("GameManager activo")
	set_playing()

# =========================
# CAMBIOS DE ESTADO
# =========================
func set_playing() -> void:
	game_state = GameState.PLAYING
	print("Estado: PLAYING")
	game_state_changed.emit(game_state)

func set_game_over() -> void:
	game_state = GameState.GAME_OVER
	print("Estado: GAME OVER")
	game_state_changed.emit(game_state)

func set_victory() -> void:
	game_state = GameState.VICTORY
	print("Estado: VICTORY")
	game_state_changed.emit(game_state)
