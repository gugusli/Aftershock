extends Node2D

# Referencia a la cámara hija
@onready var camera := $Camera2D

# --- Variables para el Shake ---
var time_left := 0.0
var strength := 0.0  # El .0 lo convierte en float
var base_offset := Vector2.ZERO

# --- Referencia al Jugador ---
var player: Node2D = null

func _ready():
	base_offset = camera.offset
	
	# Buscamos al jugador en la escena actual
	# Nota: Asegúrate de que tu nodo Player en Arena.tscn se llame exactamente "Player"
	player = get_tree().current_scene.get_node_or_null("Player")
	
	# Se añade automáticamente al grupo para que el Player pueda llamarlo
	add_to_group("camera")

func _process(delta):
	# 1. SEGUIMIENTO DEL JUGADOR
	if is_instance_valid(player):
		# Usamos lerp para que el movimiento sea fluido (Game Feel)
		# 0.1 es la velocidad de seguimiento. Más alto = más rígido.
		global_position = global_position.lerp(player.global_position, 0.1)

	# 2. LÓGICA DE SHAKE (Tu código original mejorado)
	if time_left > 0:
		time_left -= delta
		camera.offset = base_offset + Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
	else:
		# Volver a la posición original cuando termina el temblor
		camera.offset = base_offset

# Función que será llamada desde otros scripts
func shake(amount: float, duration: float):
	strength = amount
	time_left = duration
