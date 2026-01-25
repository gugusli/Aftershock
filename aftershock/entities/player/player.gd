extends CharacterBody2D

# =========================
# SEÑALES (HUD)
# =========================
signal health_changed(current, max)
signal experience_changed(current, required)
signal leveled_up(new_level)

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
# PROGRESIÓN
# =========================
var level := 1
var experience := 0
var experience_required := 10

# =========================
# DISPARO (STATS)
# =========================
var bullet_damage := 18.0
var current_pierce := 0 

# =========================
# DISPARO & AUTO-AIM
# =========================
@export var bullet_scene: PackedScene
@export var bouncing_bullet_scene: PackedScene
@export var fire_rate := 0.5 # ⏱️ Valor inicial sugerido
var enemies_in_range: Array[Node2D] = []

# =========================
# SISTEMA DE ARMAS
# =========================
var active_weapons: Array[Node] = []
var has_garlic := false
var has_bouncing_bullets := false

# =========================
# REFERENCIAS
# =========================
@onready var damageable := $Damageable
@onready var sprite := $Sprite2D
# GameManager ahora es un autoload, accesible directamente

# =========================
# ANIMACIONES
# =========================
var last_direction := Vector2.DOWN
var is_moving := false

# =========================
# READY
# =========================
func _ready() -> void:
	$AutoAim.area_entered.connect(_on_enemy_entered)
	$AutoAim.area_exited.connect(_on_enemy_exited)

	damageable.health_changed.connect(_on_health_changed)
	damageable.died.connect(_on_died)

	auto_fire()
	call_deferred("_initialize_hud")

func _initialize_hud() -> void:
	emit_signal("health_changed", damageable.health, damageable.max_health)
	emit_signal("experience_changed", experience, experience_required)
	emit_signal("leveled_up", level)

# =========================
# LOOP FÍSICO
# =========================
func _physics_process(_delta: float) -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		return

	var move_dir := get_movement_input()

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = move_dir * speed

	move_and_slide()
	_clamp_to_world_border()
	update_animation(move_dir)

# =========================
# BORDER DEL MUNDO
# =========================
func _clamp_to_world_border() -> void:
	var arena = get_tree().current_scene
	if arena == null:
		return
	var mn = arena.get("world_limit_min")
	var mx = arena.get("world_limit_max")
	if mn is Vector2 and mx is Vector2:
		global_position = global_position.clamp(mn, mx)

# =========================
# INPUT MOVIMIENTO
# =========================
func get_movement_input() -> Vector2:
	var x := 0.0
	var y := 0.0

	if Input.is_key_pressed(KEY_A): x -= 1
	if Input.is_key_pressed(KEY_D): x += 1
	if Input.is_key_pressed(KEY_W): y -= 1
	if Input.is_key_pressed(KEY_S): y += 1

	return Vector2(x, y).normalized()

# =========================
# INPUT DASH
# =========================
func _input(event: InputEvent) -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SHIFT and can_dash and not is_dashing:
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

	damageable.is_invulnerable = true
	await get_tree().create_timer(dash_duration).timeout

	is_dashing = false
	damageable.is_invulnerable = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# =========================
# EXPERIENCIA
# =========================
func add_experience(amount: int) -> void:
	experience += amount
	if experience >= experience_required:
		level_up()
	emit_signal("experience_changed", experience, experience_required)

func level_up() -> void:
	level += 1
	experience -= experience_required
	experience_required = int(experience_required * 1.5)
	emit_signal("leveled_up", level)

	var menu = get_tree().current_scene.get_node_or_null("UpgradeMenu")
	if menu and menu.has_method("show_menu"):
		menu.show_menu()

# =========================
# MEJORAS
# =========================
func get_taken_upgrades() -> Array[String]:
	var taken: Array[String] = []
	if has_garlic: taken.append("garlic")
	if has_bouncing_bullets: taken.append("bouncing")
	return taken

func apply_upgrade(upgrade_type: String) -> void:
	print("--- MEJORA RECIBIDA: ", upgrade_type, " ---")
	match upgrade_type:
		"dmg":
			bullet_damage *= 1.25 # +25% (coherente con la descripción del menú)
			print("Poder de ataque: ", bullet_damage)

		"speed":
			speed += 50.0
			print("Velocidad: ", speed)

		"fire_rate":
			fire_rate = max(0.1, fire_rate - 0.1)
			print("Nueva Cadencia: ", fire_rate)

		"health":
			damageable.max_health += 25
			damageable.health += 25
			emit_signal("health_changed", damageable.health, damageable.max_health)

		"pierce":
			current_pierce += 1
			print("Perforación: ", current_pierce)
		
		"garlic":
			if not has_garlic:
				has_garlic = true
				var garlic_scene = load("res://entities/weapons/GarlicWeapon.tscn")
				if garlic_scene:
					var garlic = garlic_scene.instantiate()
					get_tree().current_scene.add_child(garlic)
					active_weapons.append(garlic)
					print("¡Ajo desbloqueado!")
		
		"bouncing":
			has_bouncing_bullets = true
			print("Proyectiles que rebotan desbloqueados")

# =========================
# AUTO-AIM
# =========================
func _on_enemy_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy not in enemies_in_range:
		enemies_in_range.append(enemy)

func _on_enemy_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	enemies_in_range.erase(enemy)

func get_closest_enemy() -> Node2D:
	if enemies_in_range.is_empty():
		return null
	var closest: Node2D = null
	var min_dist := INF
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy): continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	return closest

# =========================
# DISPARO
# =========================
func shoot() -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return
	
	var target := get_closest_enemy()
	if target == null:
		return

	# 🔥 SHAKE AL DISPARAR (Suave: 2.0 de fuerza, 0.1 seg)
	get_tree().call_group("camera", "shake", 2.0, 0.1)

	# Disparamos el tipo de proyectil según las mejoras
	if has_bouncing_bullets and bouncing_bullet_scene != null:
		var bullet = bouncing_bullet_scene.instantiate()
		bullet.global_position = $Muzzle.global_position
		var dir := Vector2(target.global_position - bullet.global_position).normalized()
		bullet.set_direction(dir)
		bullet.set_damage(bullet_damage)
		bullet.set_bounces(3)
		get_tree().current_scene.add_child(bullet)
	elif bullet_scene != null:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = $Muzzle.global_position
		var dir := Vector2(target.global_position - bullet.global_position).normalized()
		bullet.set_direction(dir)
		bullet.set_damage(bullet_damage)
		bullet.set_pierce(current_pierce)
		get_tree().current_scene.add_child(bullet)

func auto_fire() -> void:
	while is_inside_tree():
		if GameManager.game_state == GameManager.GameState.PLAYING:
			shoot()
		await get_tree().create_timer(fire_rate).timeout

# =========================
# VIDA & MUERTE
# =========================
func _on_health_changed(current: float, max_health_val: float) -> void:
	emit_signal("health_changed", current, max_health_val)
	
	# SHAKE al recibir daño (solo si es daño real, no al iniciar)
	if current < max_health_val:
		get_tree().call_group("camera", "shake", 5.0, 0.2)
		
		# ✨ HIT FLASH (Feedback visual rápido)
		modulate = Color(2.0, 2.0, 2.0) # Brillo blanco intenso (valores > 1.0 para brillo)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
	GameManager.set_game_over()

# =========================
# ANIMACIONES
# =========================
func update_animation(move_dir: Vector2) -> void:
	is_moving = move_dir.length() > 0.1
	
	if is_moving:
		last_direction = move_dir
		update_sprite_direction(move_dir)
	else:
		# Idle - mantener última dirección
		update_sprite_direction(last_direction)

func update_sprite_direction(dir: Vector2) -> void:
	# Determinamos la dirección principal
	var abs_x = abs(dir.x)
	var abs_y = abs(dir.y)
	
	# Cargamos el sprite según la dirección
	if abs_x > abs_y:
		# Movimiento horizontal
		if dir.x > 0:
			sprite.texture = load("res://assets/sprites/east.png")
		else:
			sprite.texture = load("res://assets/sprites/west.png")
	else:
		# Movimiento vertical
		if dir.y > 0:
			sprite.texture = load("res://assets/sprites/south.png")
		else:
			sprite.texture = load("res://assets/sprites/north.png")
