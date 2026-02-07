extends CharacterBody2D

# =========================
# CONSTANTES DE CONFIGURACIÓN
# =========================
const BASE_FIRE_RATE: float = 1.0
const FIRE_RATE_REDUCTION_PER_LEVEL: float = 0.1
const MIN_FIRE_RATE: float = 0.1

# =========================
# SEÑALES (HUD)
# =========================
signal health_changed(current, max)
signal experience_changed(current, required)
signal leveled_up(new_level)

# =========================
# MOVIMIENTO (base; multiplicadores vienen de UpgradeManager)
# =========================
@export var base_speed := 220.0

# =========================
# DASH
# =========================
@export var dash_speed := 700.0
@export var dash_duration := 0.15
@export var base_dash_cooldown := 0.6

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
# DISPARO (base; multiplicadores vienen de UpgradeManager)
# =========================
@export var base_bullet_damage := 18.0
@export var base_fire_rate := 0.5

# =========================
# DISPARO & AUTO-AIM
# =========================
@export var bullet_scene: PackedScene
@export var bouncing_bullet_scene: PackedScene
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

# =========================
# ANIMACIONES
# =========================
var last_direction := Vector2.DOWN
var is_moving := false

# =========================
# READY
# =========================
func _ready() -> void:
	if not has_node("AutoAim"):
		push_error("Player: Nodo AutoAim no encontrado")
		return
	if not has_node("Muzzle"):
		push_error("Player: Nodo Muzzle no encontrado")
		return

	$AutoAim.area_entered.connect(_on_enemy_entered)
	$AutoAim.area_exited.connect(_on_enemy_exited)

	if not is_instance_valid(damageable):
		push_error("Player: Componente Damageable no encontrado o inválido")
		return
	if not is_instance_valid(sprite):
		push_error("Player: Sprite2D no encontrado o inválido")
		return

	damageable.health_changed.connect(_on_health_changed)
	damageable.died.connect(_on_died)

	auto_fire()
	call_deferred("_initialize_hud")

func _initialize_hud() -> void:
	emit_signal("health_changed", damageable.health, damageable.max_health)
	emit_signal("experience_changed", experience, experience_required)
	emit_signal("leveled_up", level)
	# Sincronizar escudo si UpgradeManager ya tiene mejoras (p. ej. al cargar partida)
	if UpgradeManager and UpgradeManager.stats.shield_amount > 0:
		damageable.set_max_shield(UpgradeManager.stats.shield_amount)

func _get_speed() -> float:
	if UpgradeManager:
		return base_speed * UpgradeManager.stats.speed_mult
	return base_speed

func _get_fire_rate() -> float:
	var fire_rate_level: int = 0
	if UpgradeManager:
		fire_rate_level = UpgradeManager.get_upgrade_level(UpgradeManager.UPGRADE_FIRE_RATE)
	return maxf(MIN_FIRE_RATE, BASE_FIRE_RATE - FIRE_RATE_REDUCTION_PER_LEVEL * fire_rate_level)

func _get_bullet_damage() -> float:
	if UpgradeManager:
		return base_bullet_damage * UpgradeManager.stats.damage_mult
	return base_bullet_damage

func _get_pierce() -> int:
	if UpgradeManager:
		return UpgradeManager.stats.pierce
	return 0

func _get_dash_cooldown() -> float:
	if UpgradeManager:
		return base_dash_cooldown * UpgradeManager.stats.dash_cooldown_mult
	return base_dash_cooldown

# =========================
# REGENERACIÓN (mejora regen)
# =========================
func _process(delta: float) -> void:
	if not GameManager or GameManager.game_state != GameManager.GameState.PLAYING:
		return
	if UpgradeManager and UpgradeManager.stats.regen_per_sec > 0 and damageable and damageable.health > 0:
		damageable.heal(UpgradeManager.stats.regen_per_sec * delta)

# =========================
# LOOP FÍSICO
# =========================
func _physics_process(_delta: float) -> void:
	if not GameManager or GameManager.game_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		return

	var move_dir := get_movement_input()

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = move_dir * _get_speed()

	move_and_slide()
	_clamp_to_world_border()
	update_animation(move_dir)

# =========================
# BORDER DEL MUNDO
# =========================
func _clamp_to_world_border() -> void:
	var tree = get_tree()
	if not tree:
		return
	var arena = tree.current_scene
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
	if not GameManager or GameManager.game_state != GameManager.GameState.PLAYING:
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
	var tree = get_tree()
	if not tree:
		can_dash = true
		return
	await tree.create_timer(dash_duration).timeout

	is_dashing = false
	damageable.is_invulnerable = false

	tree = get_tree()
	if not tree:
		can_dash = true
		return
	await tree.create_timer(_get_dash_cooldown()).timeout
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

	var tree = get_tree()
	if not tree:
		return
	var menu = tree.current_scene.get_node_or_null("UpgradeMenu")
	if menu and menu.has_method("show_menu"):
		menu.show_menu()

# =========================
# MEJORAS (solo las que modifican nodos directos; el resto está en UpgradeManager.stats)
# =========================
func apply_upgrade(upgrade_type: String) -> void:
	# MEJORADO: Solo aplicar mejoras que modifican nodos directos del jugador
	# Todos los stats numéricos se manejan en UpgradeManager y se leen con _get_*()
	match upgrade_type:
		UpgradeManager.UPGRADE_HEALTH:
			# +20 vida máxima por nivel (GDD)
			var current_level = UpgradeManager.get_upgrade_level(UpgradeManager.UPGRADE_HEALTH)
			damageable.max_health = 100.0 + (20.0 * current_level)  # Base 100 + 20 por nivel
			damageable.health = minf(damageable.health + 20.0, damageable.max_health)
			emit_signal("health_changed", damageable.health, damageable.max_health)
		UpgradeManager.UPGRADE_SHIELD:
			if UpgradeManager:
				damageable.set_max_shield(UpgradeManager.stats.shield_amount)
		UpgradeManager.UPGRADE_GARLIC:
			if not has_garlic and UpgradeManager.stats.has_garlic:
				has_garlic = true
				var garlic_scene = load("res://entities/weapons/GarlicWeapon.tscn")
				if garlic_scene:
					var tree = get_tree()
					if tree:
						var garlic = garlic_scene.instantiate()
						tree.current_scene.add_child(garlic)
						active_weapons.append(garlic)
		UpgradeManager.UPGRADE_BOUNCING:
			if UpgradeManager.stats.has_bouncing:
				has_bouncing_bullets = true
		_:
			# Todas las demás mejoras (dmg, speed, fire_rate, pierce, crit_*, regen, lifesteal, extra_projectiles, elementales)
			# se manejan completamente en UpgradeManager y se leen dinámicamente con _get_*()
			pass

# =========================
# AUTO-AIM
# =========================
func _on_enemy_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy not in enemies_in_range:
		enemies_in_range.append(enemy)

func _on_enemy_exited(area: Area2D) -> void:
	var enemy := area.get_parent()
	if is_instance_valid(enemy):
		enemies_in_range.erase(enemy)

func get_closest_enemy() -> Node2D:
	# Limpiar referencias inválidas (evita leaks y targets zombie)
	var to_remove: Array[Node2D] = []
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			to_remove.append(enemy)
	for e in to_remove:
		enemies_in_range.erase(e)
	if enemies_in_range.is_empty():
		return null
	var closest: Node2D = null
	var min_dist := INF
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
	var target := get_closest_enemy()
	if not target or not is_instance_valid(target):
		return
	if not has_node("Muzzle"):
		return

	var tree := get_tree()
	if tree:
		tree.call_group("camera", "shake", 2.0, 0.1)

	var base_dir := Vector2(target.global_position - $Muzzle.global_position).normalized()
	var extra := _get_extra_projectiles()
	var spread_angle := 0.15  # radianes entre proyectiles

	if has_bouncing_bullets and bouncing_bullet_scene != null:
		_spawn_bouncing_bullets(base_dir, extra, spread_angle)
	else:
		_spawn_bullets(base_dir, extra, spread_angle)

func _get_extra_projectiles() -> int:
	if UpgradeManager:
		return UpgradeManager.stats.extra_projectiles
	return 0

func _spawn_bullets(base_dir: Vector2, extra_count: int, spread: float) -> void:
	if bullet_scene == null or not has_node("Muzzle"):
		return
	var use_pool := PoolManager != null and PoolManager.is_initialized()
	var tree := get_tree()
	if not use_pool and (not tree or not tree.current_scene):
		return
	var count := 1 + extra_count
	for i in range(count):
		var dir := base_dir
		if count > 1:
			var offset := (float(i) - (count - 1) * 0.5) * spread
			dir = base_dir.rotated(offset)
		var bullet: Node = null
		if use_pool:
			bullet = PoolManager.get_bullet()
		else:
			bullet = bullet_scene.instantiate()
			tree.current_scene.add_child(bullet)
		if not bullet:
			continue
		bullet.global_position = $Muzzle.global_position
		bullet.set_direction(dir)
		bullet.set_damage(_get_bullet_damage())
		bullet.set_pierce(_get_pierce())

func _spawn_bouncing_bullets(base_dir: Vector2, extra_count: int, spread: float) -> void:
	if bouncing_bullet_scene == null:
		return
	var use_pool := PoolManager != null and PoolManager.is_initialized()
	var count := 1 + extra_count
	for i in range(count):
		var dir := base_dir
		if count > 1:
			var offset := (float(i) - (count - 1) * 0.5) * spread
			dir = base_dir.rotated(offset)
		var bullet: Node = null
		if use_pool:
			bullet = PoolManager.get_bouncing_bullet()
		else:
			bullet = bouncing_bullet_scene.instantiate()
			var tree := get_tree()
			if tree and tree.current_scene:
				tree.current_scene.add_child(bullet)
		if not bullet:
			continue
		if has_node("Muzzle"):
			bullet.global_position = $Muzzle.global_position
		bullet.set_direction(dir)
		bullet.set_damage(_get_bullet_damage())
		bullet.set_bounces(3)

func auto_fire() -> void:
	while is_inside_tree():
		if GameManager and GameManager.game_state == GameManager.GameState.PLAYING:
			shoot()
		var tree := get_tree()
		if not tree:
			break
		await tree.create_timer(_get_fire_rate()).timeout
		if not is_inside_tree():
			break

# =========================
# VIDA & MUERTE
# =========================
func _on_health_changed(current: float, max_health_val: float) -> void:
	emit_signal("health_changed", current, max_health_val)
	if current < max_health_val:
		var tree = get_tree()
		if tree:
			tree.call_group("camera", "shake", 5.0, 0.2)
		modulate = Color(2.0, 2.0, 2.0)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
	if GameManager:
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
		update_sprite_direction(last_direction)

func update_sprite_direction(dir: Vector2) -> void:
	var abs_x = abs(dir.x)
	var abs_y = abs(dir.y)
	if abs_x > abs_y:
		sprite.texture = load("res://assets/sprites/east.png") if dir.x > 0 else load("res://assets/sprites/west.png")
	else:
		sprite.texture = load("res://assets/sprites/south.png") if dir.y > 0 else load("res://assets/sprites/north.png")

func _exit_tree() -> void:
	# Desconectar signals de AutoAim
	if has_node("AutoAim"):
		var auto_aim = $AutoAim
		if auto_aim.area_entered.is_connected(_on_enemy_entered):
			auto_aim.area_entered.disconnect(_on_enemy_entered)
		if auto_aim.area_exited.is_connected(_on_enemy_exited):
			auto_aim.area_exited.disconnect(_on_enemy_exited)

	# Desconectar signals de Damageable
	if damageable and is_instance_valid(damageable):
		if damageable.health_changed.is_connected(_on_health_changed):
			damageable.health_changed.disconnect(_on_health_changed)
		if damageable.died.is_connected(_on_died):
			damageable.died.disconnect(_on_died)
