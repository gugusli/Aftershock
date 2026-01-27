extends Area2D

@export var experience_value := 1
@export var attraction_speed := 400.0

var target: Node2D = null
var being_collected := false

func _ready() -> void:
	# Agregamos al grupo para que el imán pueda encontrarlas
	add_to_group("experience_gem")
	# Conectamos la señal para detectar cuando el jugador entra en el radio
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

func collect() -> void:
	if target and target.has_method("add_experience"):
		target.add_experience(experience_value)
	
	# Efecto visual simple (opcional: podrías añadir un sonido aquí)
	queue_free()
