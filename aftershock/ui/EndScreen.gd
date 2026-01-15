extends CanvasLayer

@onready var title_label := $Control/Panel/VBoxContainer/Title
@onready var retry_button := $Control/Panel/VBoxContainer/Retry
@onready var quit_button := $Control/Panel/VBoxContainer/Quit

var game_manager : Node

func _ready() -> void:
	hide()

	game_manager = get_tree().current_scene.get_node("GameManager")
	game_manager.game_state_changed.connect(_on_game_state_changed)

	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_game_state_changed(state: int) -> void:
	# 0 = PLAYING
	# 1 = GAME_OVER
	# 2 = VICTORY
	match state:
		1:
			show()
			title_label.text = "GAME OVER"
			get_tree().paused = true
		2:
			show()
			title_label.text = "VICTORY"
			get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
