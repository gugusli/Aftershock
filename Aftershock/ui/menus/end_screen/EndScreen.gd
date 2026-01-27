extends CanvasLayer

# Referencias a los nodos de la UI
@onready var panel := $Control/Panel
@onready var title_label := $Control/Panel/VBoxContainer/Title
@onready var retry_button := $Control/Panel/VBoxContainer/Retry
@onready var quit_button := $Control/Panel/VBoxContainer/Quit

# GameManager ahora es un autoload, accesible directamente
var active := false # 🛑 Evita que se active dos veces seguidas

func _ready() -> void:
	hide() # Nos aseguramos de que empiece oculto
	
	# Conectamos la señal para saber cuándo se gana o pierde
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Conectamos los botones
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectamos efectos de hover
	retry_button.mouse_entered.connect(_on_button_hover.bind(retry_button))
	retry_button.mouse_exited.connect(_on_button_exit.bind(retry_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))
	quit_button.mouse_exited.connect(_on_button_exit.bind(quit_button))

func _on_game_state_changed(state: int) -> void:
	if active:
		return

	match state:
		GameManager.GameState.GAME_OVER:
			active = true
			title_label.text = "GAME OVER"
			title_label.add_theme_color_override("font_color", Color.RED)
			show()
			get_tree().paused = true
			_animate_game_over()

		GameManager.GameState.VICTORY:
			active = true
			title_label.text = "¡VICTORIA!"
			title_label.add_theme_color_override("font_color", Color.GOLD)
			show()
			get_tree().paused = true
			_animate_victory()

func _animate_game_over() -> void:
	# Animación dramática de derrota
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.5, 0.5)
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(2.0, 2.0)
	
	# Fondo aparece primero
	var panel_tween = create_tween()
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await panel_tween.finished
	
	# Título aparece con efecto de "impacto"
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Efecto de "shake" en el título
	await title_tween.finished
	_shake_title()
	
	# Botones aparecen después
	await get_tree().create_timer(0.3).timeout
	_animate_buttons_entrance()

func _animate_victory() -> void:
	# Animación épica de victoria
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.5, 0.5)
	
	# Panel con efecto de "explosión"
	var panel_tween = create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	
	await panel_tween.finished
	
	# Título con efecto de "zoom" y brillo
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	title_tween.tween_property(title_label, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	
	# Efecto de pulso continuo en victoria
	await title_tween.finished
	_pulse_title()
	
	# Botones aparecen
	await get_tree().create_timer(0.2).timeout
	_animate_buttons_entrance()

func _shake_title() -> void:
	# Efecto de shake para GAME OVER
	var original_pos = title_label.position
	for i in range(5):
		var shake_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		title_label.position = original_pos + shake_offset
		await get_tree().create_timer(0.05).timeout
	title_label.position = original_pos

func _pulse_title() -> void:
	# Efecto de pulso continuo para VICTORIA
	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0).set_delay(1.0)

func _animate_buttons_entrance() -> void:
	for button in [retry_button, quit_button]:
		button.modulate.a = 0.0
		button.scale = Vector2(0.9, 0.9)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(button, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.12).timeout

func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.2)

func _on_button_exit(button: Button) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color.WHITE, 0.2)

func _on_retry_pressed() -> void:
	# Restaurar estado de juego para que la Arena cargada empiece en PLAYING
	GameManager.set_playing()
	# Despausar antes de reiniciar, si no el juego recarga pausado
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
