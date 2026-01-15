extends CharacterBody2D

# =========================
# SEÑALES (REENVIADAS AL HUD)
# =========================
signal health_changed(current, max)

# =========================
# MOVIMIENTO
# =========================
@export var speed := 220.0

# =========================
# DASH
# =========================
@export var dash_speed := 700.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.6

var is_dashing := false
var can_dash := true
var dash_direction := Vector2.ZERO

# =========================
# DISPARO
# =========================
@export var bullet_scene: PackedScene
@export var fire_rate := 0.1

# =========================
# AUTO-AIM
# =========================
var enemies_in_range: Array[Node2D] = []

# =========================
# DAMAGEABLE
# =========================
@onready var damageable := $Damageable
@onready var game_manager := get_tree().current_scene.get_node("GameManager")

# =========================
# READY
# =========================
func _ready() -> void:
	$AutoAim.area_entered.connect(_on_enemy_entered)
	$AutoAim.area_exited.connect(_on_enemy_exited)

	damageable.health_changed.connect(_on_health_changed)
	damageable.died.connect(_on_died)

	auto_fire()

# =========================
# LOOP PRINCIPAL
# =========================
func _physics_process(_delta: float) -> void:
	# 🛑 Si el juego no está en PLAYING, el player no hace nada
	if game_manager.game_state != game_manager.GameState.PLAYING:
		velocity = Vector2.ZERO
		return

	var move_dir := get_movement_input()

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = move_dir * speed

	move_and_slide()

# =========================
# INPUT MOVIMIENTO
# =========================
func get_movement_input() -> Vector2:
	var x := 0
	var y := 0

	if Input.is_key_pressed(KEY_A):
		x -= 1
	if Input.is_key_pressed(KEY_D):
		x += 1
	if Input.is_key_pressed(KEY_W):
		y -= 1
	if Input.is_key_pressed(KEY_S):
		y += 1

	return Vector2(x, y).normalized()

# =========================
# INPUT DASH
# =========================
func _input(event: InputEvent) -> void:
	if game_manager.game_state != game_manager.GameState.PLAYING:
		return

	if event is InputEventKey:
		if event.pressed and not event.is_echo() and event.keycode == KEY_SHIFT:
			if can_dash and not is_dashing:
				start_dash()

# =========================
# DASH
# =========================
func start_dash() -> void:
	var direction := get_movement_input()
	if direction == Vector2.ZERO:
		return

	can_dash = false
	is_dashing = true
	dash_direction = direction

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# =========================
# AUTO-AIM DETECCIÓN
# =========================
func _on_enemy_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy not in enemies_in_range:
		enemies_in_range.append(enemy)

func _on_enemy_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	enemies_in_range.erase(enemy)

# =========================
# AUTO-AIM OBJETIVO
# =========================
func get_closest_enemy() -> Node2D:
	if enemies_in_range.is_empty():
		return null

	var closest := enemies_in_range[0]
	var min_dist := global_position.distance_squared_to(closest.global_position)

	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue

		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy

	return closest

# =========================
# DISPARO
# =========================
func shoot() -> void:
	if game_manager.game_state != game_manager.GameState.PLAYING:
		return

	if bullet_scene == null:
		return

	var target: Node2D = get_closest_enemy()
	if target == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position

	var dir: Vector2 = (target.global_position - bullet.global_position).normalized()
	bullet.set_direction(dir)

# =========================
# AUTO FIRE
# =========================
func auto_fire() -> void:
	while is_inside_tree():
		if game_manager.game_state == game_manager.GameState.PLAYING:
			shoot()
		await get_tree().create_timer(fire_rate).timeout

# =========================
# VIDA → HUD
# =========================
func _on_health_changed(current: int, max_health: int) -> void:
	emit_signal("health_changed", current, max_health)

# =========================
# MUERTE
# =========================
func _on_died() -> void:
	# ❗ El Player NO reinicia el juego
	game_manager.set_game_over()
