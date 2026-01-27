extends CanvasLayer

# Referencias a los nodos de la UI
@onready var panel := $Control/Panel
@onready var resume_button := $Control/Panel/VBoxContainer/ResumeButton
@onready var restart_button := $Control/Panel/VBoxContainer/RestartButton
@onready var main_menu_button := $Control/Panel/VBoxContainer/MainMenuButton
@onready var quit_button := $Control/Panel/VBoxContainer/QuitButton

var is_paused := false
var buttons: Array[Button] = []

func _ready() -> void:
	# Empezamos oculto
	visible = false
	buttons = [resume_button, restart_button, main_menu_button, quit_button]
	
	# Conectamos los botones
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectamos efectos de hover
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_exit.bind(button))

func _input(event: InputEvent) -> void:
	# ESC para pausar/despausar (solo durante el juego)
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if GameManager.game_state == GameManager.GameState.PLAYING:
			toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	
	if is_paused:
		show()
		get_tree().paused = true
		_animate_menu_entrance()
	else:
		_animate_menu_exit()
		await get_tree().create_timer(0.2).timeout
		hide()
		get_tree().paused = false

func _animate_menu_entrance() -> void:
	# Panel empieza invisible y escalado
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animación escalonada de botones
	await tween.finished
	for i in range(buttons.size()):
		var button = buttons[i]
		button.modulate.a = 0.0
		button.position.x -= 30
		
		var btn_tween = create_tween()
		btn_tween.set_parallel(true)
		btn_tween.tween_property(button, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
		btn_tween.tween_property(button, "position:x", button.position.x + 30, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(0.05).timeout

func _animate_menu_exit() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color(1.15, 1.15, 1.15), 0.15)

func _on_button_exit(button: Button) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color.WHITE, 0.15)

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	# Despausamos antes de reiniciar
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	# Despausamos antes de cambiar de escena
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/menus/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
