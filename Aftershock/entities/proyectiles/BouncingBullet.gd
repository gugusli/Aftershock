extends Area2D

# =========================
# PROYECTIL QUE REBOTA
# =========================
@export var speed: float = 800.0
@export var lifetime: float = 5.0
@export var max_bounces := 3

var damage: float = 10.0
var direction: Vector2 = Vector2.ZERO
var bounces_left: int = 3
var has_hit_enemies: Array[Node2D] = [] # Para evitar dañar el mismo enemigo múltiples veces

# =========================
# SETTERS
# =========================
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func set_damage(amount: float) -> void:
	damage = amount

func set_bounces(amount: int) -> void:
	bounces_left = amount
	max_bounces = amount

# =========================
# READY
# =========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_start_lifetime")

# =========================
# VIDA ÚTIL
# =========================
func _start_lifetime() -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

# =========================
# MOVIMIENTO
# =========================
func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + movement)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Rebotamos
		if bounces_left > 0:
			var normal = result.normal
			direction = direction.bounce(normal)
			bounces_left -= 1
			# Rotamos el sprite para que apunte en la dirección correcta
			rotation = direction.angle()
		else:
			queue_free()
	else:
		global_position += movement

# =========================
# COLISIÓN CON ENEMIGOS
# =========================
func _on_body_entered(body: Node2D) -> void:
	if !is_inside_tree():
		return
	
	# Solo dañamos enemigos, no paredes
	var damageable = body.get_node_or_null("Damageable")
	if damageable and body not in has_hit_enemies:
		# DAÑO
		damageable.take_damage(damage)
		has_hit_enemies.append(body)
		
		# KNOCKBACK (tipo explícito para evitar error de inferencia)
		if body.has_method("apply_knockback"):
			var kb_dir: Vector2 = (body.global_position - global_position).normalized()
			body.apply_knockback(kb_dir)
		
		# No destruimos el proyectil, puede rebotar y seguir dañando
