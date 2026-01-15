extends CanvasLayer

@onready var health_bar := $HealthBar
@onready var game_manager := get_tree().current_scene.get_node("GameManager")

func _ready() -> void:
	# Escuchar cambios de estado del juego
	game_manager.game_state_changed.connect(_on_game_state_changed)

func connect_player(player: Node) -> void:
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _on_game_state_changed(state) -> void:
	match state:
		game_manager.GameState.PLAYING:
			visible = true
		game_manager.GameState.GAME_OVER, game_manager.GameState.VICTORY:
			visible = false
