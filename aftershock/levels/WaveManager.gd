extends Node

# =========================
# CONFIGURACIÓN
# =========================
@export var enemy_scene: PackedScene
@export var spawn_radius := 400.0
@export var base_enemies := 5
@export var max_waves := 10
@export var wave_delay := 1.5

# =========================
# REFERENCIAS
# =========================
@onready var player := get_tree().current_scene.get_node("Player")
@onready var game_manager := get_tree().current_scene.get_node("GameManager")

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
	call_deferred("start_next_wave")

# =========================
# OLEADAS
# =========================
func start_next_wave() -> void:
	# 🛑 El juego debe estar en estado PLAYING
	if game_manager.game_state != game_manager.GameState.PLAYING:
		return

	# 🛑 Evita spawns duplicados o timers solapados
	if wave_in_progress or waiting_next_wave:
		return

	# 🏁 Victoria: no iniciar más oleadas
	if current_wave >= max_waves:
		print("VICTORY")
		if game_manager:
			game_manager.set_victory()
		return

	wave_in_progress = true
	current_wave += 1

	var enemies_to_spawn := base_enemies + current_wave - 1
	enemies_alive = enemies_to_spawn

	print("Iniciando oleada", current_wave, "con", enemies_to_spawn, "enemigos")

	spawn_enemies(enemies_to_spawn)

func spawn_enemies(count: int) -> void:
	# 🛑 Seguridad de estado
	if game_manager.game_state != game_manager.GameState.PLAYING:
		return

	if enemy_scene == null or player == null:
		return

	for i in range(count):
		var enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(enemy)

		var angle := randf() * TAU
		var offset := Vector2(cos(angle), sin(angle)) * spawn_radius
		enemy.global_position = player.global_position + offset

		enemy.target = player
		enemy.enemy_died.connect(_on_enemy_died)

# =========================
# ENEMIGOS
# =========================
func _on_enemy_died(_enemy) -> void:
	# 🛑 Si el juego no está activo, ignorar señales
	if game_manager.game_state != game_manager.GameState.PLAYING:
		return

	if enemies_alive <= 0:
		return

	enemies_alive -= 1
	print("Enemigos vivos:", enemies_alive)

	if enemies_alive == 0:
		on_wave_completed()

# =========================
# FIN DE OLEADA
# =========================
func on_wave_completed() -> void:
	if not wave_in_progress:
		return

	wave_in_progress = false
	print("OLEADA", current_wave, "COMPLETADA")

	start_wave_delay()

func start_wave_delay() -> void:
	if waiting_next_wave:
		return

	waiting_next_wave = true

	await get_tree().create_timer(wave_delay).timeout

	waiting_next_wave = false
	start_next_wave()
