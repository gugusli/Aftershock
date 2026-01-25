extends Area2D

# =========================
# CONFIGURACIÓN
# =========================
@export var speed: float = 800.0
@export var lifetime: float = 3.0

var damage: float = 50.0
var direction: Vector2 = Vector2.ZERO
var pierce_count: int = 0

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
	global_position += direction * speed * delta

# =========================
# COLISIÓN
# =========================
func _on_body_entered(body: Node2D) -> void:
	if !is_inside_tree():
		return

	var damageable = body.get_node_or_null("Damageable")
	if damageable:
		# DAÑO
		damageable.take_damage(damage)

		# KNOCKBACK
		if body.has_method("apply_knockback"):
			var kb_dir: Vector2 = (body.global_position - global_position).normalized()
			body.apply_knockback(kb_dir)

		# PIERCING
		if pierce_count > 0:
			pierce_count -= 1
			damage = damage * 0.8
		else:
			queue_free()
