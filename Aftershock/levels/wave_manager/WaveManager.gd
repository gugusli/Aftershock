extends Node

# =========================
# SEÑALES
# =========================
signal wave_started(number)

# =========================
# CONFIGURACIÓN (Escenas)
# =========================
@export_group("Escenas de Enemigos")
@export var standard_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_scene: PackedScene

@export_group("Ajustes de Oleada")
@export var spawn_radius := 400.0
@export var base_enemies := 5
@export var max_waves := 10        
@export var boss_wave := 10           
@export var wave_delay := 2.0         

# =========================
# REFERENCIAS
# =========================
var player: Node2D = null
# GameManager ahora es un autoload, accesible directamente

# =========================
# ESTADO
# =========================
var current_wave := 0
var enemies_alive := 0
var wave_in_progress := false
var waiting_next_wave := false

# =========================
# READY
# =========================
func _ready() -> void:
	print("WaveManager activo")
	# Buscar el player de forma segura
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		push_error("WaveManager: No se encontró al jugador")
	call_deferred("start_next_wave")

# =========================
# OLEADAS
# =========================
func start_next_wave() -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return

	if wave_in_progress or waiting_next_wave:
		return

	if current_wave >= max_waves and enemies_alive == 0:
		GameManager.set_victory()
		return

	wave_in_progress = true
	current_wave += 1
	
	wave_started.emit(current_wave)
	_update_wave_ui()

	if current_wave == boss_wave:
		spawn_boss()
	else:
		# Escalado de cantidad: +2 enemigos por cada ronda
		var enemies_to_spawn := base_enemies + ((current_wave - 1) * 2)
		enemies_alive = enemies_to_spawn
		print("Iniciando oleada ", current_wave, " con ", enemies_to_spawn, " enemigos ")
		spawn_enemies(enemies_to_spawn)

func _update_wave_ui() -> void:
	var wave_label = get_tree().current_scene.find_child("WaveLabel", true, false)
	if wave_label:
		wave_label.text = "OLEADA: " + str(current_wave)

func spawn_enemies(count: int) -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return

	for i in range(count):
		var scene_to_use = _get_random_enemy_by_wave()
		if scene_to_use != null:
			_instantiate_enemy(scene_to_use)
		await get_tree().create_timer(0.2).timeout 

# 🧠 LÓGICA DE SELECCIÓN DE ENEMIGOS
func _get_random_enemy_by_wave() -> PackedScene:
	var roll = randf() # Genera un número entre 0.0 y 1.0
	
	# Oleadas 1-2: Solo normales
	if current_wave <= 2:
		return standard_enemy_scene
		
	# Oleadas 3-5: Aparecen los rápidos (30% de probabilidad)
	elif current_wave <= 5:
		if roll < 0.3: return fast_enemy_scene
		return standard_enemy_scene
		
	# Oleadas 6-9: Aparecen los tanques (20% tanque, 30% rápido, 50% normal)
	else:
		if roll < 0.2: return tank_enemy_scene
		if roll < 0.5: return fast_enemy_scene
		return standard_enemy_scene

func spawn_boss() -> void:
	if boss_scene == null:
		on_wave_completed()
		return
	
	print("!!! ALERTA DE JEFE FINAL !!!")
	enemies_alive = 1
	_instantiate_enemy(boss_scene)

func _instantiate_enemy(scene: PackedScene) -> void:
	if not player or not is_instance_valid(player):
		push_error("WaveManager: No hay jugador válido para spawnear enemigos")
		return
		
	var enemy = scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", enemy)

	# 1. Posicionamiento
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	enemy.target = player

	# 2. 📈 ESCALADO DE DIFICULTAD (Vida extra por cada ronda)
	var multiplier = 1.0 + (current_wave - 1) * 0.1
	var damageable = enemy.get_node_or_null("Damageable")
	if damageable:
		damageable.max_health = int(damageable.max_health * multiplier)
		damageable.health = damageable.max_health

	# 3. Conexión de muerte
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)

# =========================
# ENEMIGOS
# =========================
func _on_enemy_died(_enemy) -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return

	enemies_alive -= 1
	if enemies_alive <= 0:
		on_wave_completed()

# =========================
# FIN DE OLEADA
# =========================
func on_wave_completed() -> void:
	wave_in_progress = false
	if current_wave >= max_waves:
		GameManager.set_victory()
		return
	start_wave_delay()

func start_wave_delay() -> void:
	if waiting_next_wave: return
	waiting_next_wave = true
	await get_tree().create_timer(wave_delay).timeout
	waiting_next_wave = false
	start_next_wave()
