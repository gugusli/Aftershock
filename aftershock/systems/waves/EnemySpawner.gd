extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval := 2.0
@export var spawn_radius := 400.0

@onready var player := get_tree().current_scene.get_node("Player")

func _ready():
	spawn_loop()

func spawn_loop() -> void:
	while true:
		spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout

func spawn_enemy():
	if enemy_scene == null or player == null:
		return

	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_radius

	enemy.global_position = player.global_position + offset
	enemy.target = player
