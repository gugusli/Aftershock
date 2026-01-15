extends Node

@export var enemy_scene: PackedScene
@export var spawn_radius := 400.0
@export var base_enemies := 3
@export var wave_delay := 2.0

@onready var player := get_tree().current_scene.get_node("Player")

var current_wave := 0
var enemies_alive := 0

func _ready() -> void:
	print("WaveManager activo")
	call_deferred("start_next_wave")

func start_next_wave() -> void:
	current_wave += 1
	var enemies_to_spawn := base_enemies + current_wave - 1

	print("Iniciando oleada", current_wave, "con", enemies_to_spawn, "enemigos")

	enemies_alive = enemies_to_spawn
	spawn_enemies(enemies_to_spawn)

func spawn_enemies(count: int) -> void:
	if enemy_scene == null or player == null:
		return

	for i in count:
		var enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(enemy)

		var angle := randf() * TAU
		var offset := Vector2(cos(angle), sin(angle)) * spawn_radius

		enemy.global_position = player.global_position + offset
		enemy.target = player
		enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(_enemy) -> void:
	enemies_alive -= 1
	print("Enemigos vivos:", enemies_alive)

	if enemies_alive <= 0:
		on_wave_completed()

func on_wave_completed() -> void:
	print("OLEADA", current_wave, "COMPLETADA")
	call_deferred("wait_and_start_next_wave")

func wait_and_start_next_wave() -> void:
	await get_tree().create_timer(wave_delay).timeout
	start_next_wave()
