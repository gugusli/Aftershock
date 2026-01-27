extends Area2D

# =========================
# POCIÓN DE VIDA
# =========================
@export var health_restored := 50
@export var attraction_speed := 300.0

var target: Node2D = null
var being_collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos que sea el jugador
	if body.name == "Player" or body.has_node("Damageable"):
		target = body
		being_collected = true

func _process(delta: float) -> void:
	# Si el jugador entró en el área, la poción se mueve hacia él
	if being_collected and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * attraction_speed * delta
		
		# Si está lo suficientemente cerca, se consume
		if global_position.distance_to(target.global_position) < 15.0:
			collect()

func collect() -> void:
	if target and target.has_node("Damageable"):
		var damageable = target.get_node("Damageable")
		damageable.health = min(damageable.health + health_restored, damageable.max_health)
		damageable.emit_signal("health_changed", damageable.health, damageable.max_health)
	
	# Efecto visual (opcional: podrías añadir un sonido aquí)
	queue_free()
