extends Area2D

## =========================
## Proyectil del jugador
## Actualizado con sistema de críticos
## =========================

# =========================
# CONFIGURACIÓN
# =========================
@export var speed: float = 800.0
@export var lifetime: float = 3.0

var damage: float = 50.0
var direction: Vector2 = Vector2.ZERO
var pierce_count: int = 0
var _in_pool := false
var _lifetime_remaining := 0.0

# Sistema de críticos
var crit_chance: float = 0.05  # 5% base
var crit_damage_mult: float = 1.5  # 150% base

# =========================
# SETTERS
# =========================
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func set_damage(amount: float) -> void:
	damage = amount

func set_pierce(amount: int) -> void:
	pierce_count = amount

# =========================
# CICLO DE VIDA
# =========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_lifetime_remaining = lifetime

func restart_for_reuse() -> void:
	_in_pool = false
	_lifetime_remaining = lifetime

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime_remaining -= delta
	if _lifetime_remaining <= 0.0:
		_release_to_pool()

# =========================
# COLISIÓN
# =========================
func _on_body_entered(body: Node2D) -> void:
	if !is_inside_tree():
		return

	var damageable = body.get_node_or_null("Damageable")
	if damageable:
		# Obtener stats de UpgradeManager
		if UpgradeManager:
			crit_chance = UpgradeManager.stats.crit_chance
			crit_damage_mult = UpgradeManager.stats.crit_damage
		
		var is_critical := randf() < crit_chance
		var final_damage := damage * (crit_damage_mult if is_critical else 1.0)
		
		# Aplicar daño
		damageable.take_damage(final_damage)
		
		# Efectos elementales (UpgradeManager)
		if UpgradeManager:
			if UpgradeManager.stats.has_fire and body.has_method("apply_burn"):
				body.apply_burn(3.0, 15.0)
			if UpgradeManager.stats.has_ice and body.has_method("apply_slow"):
				body.apply_slow(2.0, 0.7)
			if UpgradeManager.stats.has_poison and body.has_method("apply_poison"):
				body.apply_poison(5.0, 10.0)
			if UpgradeManager.stats.has_chain_lightning:
				_apply_chain_lightning(body, final_damage * 0.6)
			if UpgradeManager.stats.has_explosive:
				_apply_explosion(body.global_position, final_damage * 0.5)
		
		# VFX
		if VFXManager:
			VFXManager.play_hit_effect(body.global_position, final_damage, is_critical)
		
		# Robo de vida
		if UpgradeManager and UpgradeManager.stats.lifesteal > 0:
			var heal_amount = final_damage * UpgradeManager.stats.lifesteal
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var player_damageable = player.get_node_or_null("Damageable")
				if player_damageable:
					player_damageable.heal(heal_amount)

		# Knockback
		if body.has_method("apply_knockback"):
			var kb_dir: Vector2 = (body.global_position - global_position).normalized()
			var kb_strength = 1.5 if is_critical else 1.0
			body.apply_knockback(kb_dir * kb_strength)

		# Perforación
		if pierce_count > 0:
			pierce_count -= 1
			damage = damage * 0.8
		else:
			_release_to_pool()

func _apply_chain_lightning(exclude_body: Node2D, chain_damage: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var near_enemies: Array[Node2D] = []
	for node in enemies:
		if not node is Node2D or node == exclude_body or not is_instance_valid(node):
			continue
		var dmg = node.get_node_or_null("Damageable")
		if dmg and node.global_position.distance_squared_to(global_position) < 120000.0:  # ~346 px
			near_enemies.append(node)
	near_enemies.sort_custom(func(a, b): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	for i in range(min(3, near_enemies.size())):
		var target_dmg = near_enemies[i].get_node_or_null("Damageable")
		if target_dmg:
			target_dmg.take_damage(chain_damage)
			if VFXManager:
				VFXManager.play_hit_effect(near_enemies[i].global_position, chain_damage, false)

func _apply_explosion(center: Vector2, explosion_damage: float) -> void:
	var area_mult := 1.0
	if UpgradeManager:
		area_mult = UpgradeManager.stats.area_mult
	var radius := 80.0 * area_mult
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # enemigos
	var results = space.intersect_shape(query, 32)
	for result in results:
		var collider = result.collider
		if collider.get_node_or_null("Damageable"):
			collider.get_node("Damageable").take_damage(explosion_damage)
			if collider.has_method("apply_knockback"):
				var kb_dir = (collider.global_position - center).normalized()
				collider.apply_knockback(kb_dir)
	if VFXManager:
		VFXManager.play_explosion_effect(center, radius)

func _release_to_pool() -> void:
	if _in_pool:
		return
	_in_pool = true
	if PoolManager and PoolManager.is_initialized():
		PoolManager.release_bullet(self)
	else:
		queue_free()
