extends CanvasLayer

# 🔗 Referencias a los nodos
@onready var health_bar := $HUDContainer/HealthSection/HealthRow/HealthBar
@onready var health_label := $HUDContainer/HealthSection/HealthRow/HealthLabel
@onready var exp_bar := $HUDContainer/ExperienceBar
@onready var level_label := $HUDContainer/LevelLabel
@onready var wave_label := $HUDContainer/WaveLabel

# GameManager ahora es un autoload, accesible directamente

var health_tween: Tween

func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	exp_bar.value = 0
	level_label.text = "Nivel: 1"
	
	# 🌊 Conexión con el WaveManager para las rondas
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_label.text = "Oleada: " + str(wave_manager.current_wave)

# 🟢 REVISADO: Ahora conecta directamente con el nodo Damageable
func connect_player(player: Node) -> void:
	var damageable = player.get_node_or_null("Damageable")
	
	if damageable:
		damageable.health_changed.connect(_on_health_changed)
		health_bar.max_value = damageable.max_health
		health_bar.value = damageable.health
		health_label.text = "%d / %d" % [int(damageable.health), int(damageable.max_health)]
		print("HUD: Conectado con éxito al Damageable del jugador")
	else:
		push_error("HUD: No se encontró el nodo Damageable en el jugador")

	if player.has_signal("experience_changed"):
		player.experience_changed.connect(_on_experience_changed)
	if player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_leveled_up)

# === Handler de Vida con Tween ===

func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_label.text = "%d / %d" % [int(current), int(max_health)]
	
	if health_tween:
		health_tween.kill()
	
	health_tween = get_tree().create_tween()
	health_tween.tween_property(health_bar, "value", current, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

# === Handlers de Experiencia y Nivel ===

func _on_experience_changed(current: int, required: int) -> void:
	exp_bar.max_value = required
	exp_bar.value = current

func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Nivel: " + str(new_level)

# === 🆕 Handler de Oleadas con Animación ===

func _on_wave_started(number: int) -> void:
	wave_label.text = "Oleada: " + str(number)
	
	# ✨ Efecto visual: el texto "salta" un poco al cambiar de ronda
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(wave_label, "scale", Vector2(1.0, 1.0), 0.1)

# === Visibilidad del Juego ===

func _on_game_state_changed(state) -> void:
	match state:
		GameManager.GameState.PLAYING:
			visible = true
		GameManager.GameState.GAME_OVER, GameManager.GameState.VICTORY:
			visible = false
