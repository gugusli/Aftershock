extends CanvasLayer

# Referencias a los nodos de la UI
@onready var panel := $Control/Panel
@onready var start_button := $Control/Panel/VBoxContainer/StartButton
@onready var quit_button := $Control/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	# Conectamos los botones
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectamos señales de hover para efectos visuales
	start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	start_button.mouse_exited.connect(_on_button_exit.bind(start_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))
	quit_button.mouse_exited.connect(_on_button_exit.bind(quit_button))
	
	# Aseguramos que el juego no esté pausado
	get_tree().paused = false
	
	# Reiniciamos el estado del juego
	GameManager.set_playing()
	
	# Animación de entrada del menú
	_animate_menu_entrance()

func _animate_menu_entrance() -> void:
	# Empezamos con el panel invisible y escalado
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	# Animación suave de entrada
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animación escalonada de los botones
	await tween.finished
	_animate_buttons_entrance()

func _animate_buttons_entrance() -> void:
	var delay = 0.1
	for button in [start_button, quit_button]:
		button.modulate.a = 0.0
		button.position.y += 20
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(button, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "position:y", button.position.y - 20, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(delay).timeout

func _on_button_hover(button: Button) -> void:
	# Efecto de hover: escala y brillo
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.2)

func _on_button_exit(button: Button) -> void:
	# Volver a estado normal
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color.WHITE, 0.2)

func _on_start_pressed() -> void:
	# Animación de salida antes de cambiar de escena
	_animate_menu_exit()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://levels/Arenas/Arena.tscn")

func _on_quit_pressed() -> void:
	# Animación de salida antes de cerrar
	_animate_menu_exit()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _animate_menu_exit() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.3).set_trans(Tween.TRANS_CUBIC)
