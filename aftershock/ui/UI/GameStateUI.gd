extends CanvasLayer

@onready var label := $Root/Panel/StateLabel
@onready var retry_button := $Root/Panel/RetryButton
@onready var game_manager := get_tree().current_scene.get_node("GameManager")

func _ready() -> void:
	hide()

	# Conectar botón
	retry_button.pressed.connect(_on_retry_pressed)

	# Escuchar cambios de estado del juego
	game_manager.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state) -> void:
	match new_state:
		game_manager.GameState.GAME_OVER:
			label.text = "GAME OVER"
			show()
		game_manager.GameState.VICTORY:
			label.text = "VICTORY"
			show()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
