extends Area2D

@export var experience_value := 5
@export var attraction_speed := 400.0

var target: Node2D = null
var being_collected := false
var _in_pool := false

func _ready() -> void:
	# Agregamos al grupo para que el imán pueda encontrarlas
	add_to_group("experience_gem")
	# Conectamos la señal para detectar cuando el jugador entra en el radio
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func set_attraction_speed(new_speed: float) -> void:
	attraction_speed = new_speed

func _on_body_entered(body: Node2D) -> void:
	# Verificamos que sea el jugador
	if body.name == "Player" or body.has_method("add_experience"):
		target = body
		being_collected = true

func _process(delta: float) -> void:
	# Si el jugador entró en el área, la gema se mueve hacia él
	if being_collected and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * attraction_speed * delta
		
		# Si está lo suficientemente cerca, se consume
		if global_position.distance_to(target.global_position) < 15.0:
			collect()

func restart_for_reuse() -> void:
	_in_pool = false
	target = null
	being_collected = false
	# Detectar jugador (capa 1); PoolManager pone mask 2 por defecto
	collision_layer = 4
	collision_mask = 1

func collect() -> void:
	if target and target.has_method("add_experience"):
		target.add_experience(experience_value)
	_release_to_pool()

func _release_to_pool() -> void:
	if _in_pool:
		return
	_in_pool = true
	if PoolManager and PoolManager.has_pool(PoolManager.POOL_KEY_EXPERIENCE_GEM):
		PoolManager.return_to_pool(self)
	else:
		queue_free()
