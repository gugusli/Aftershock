extends "res://entities/player/player.gd"
## REVERBERACIÓN - El Controlador (GDD §5)
## HP: 80, Velocidad 90%, Controla 3 torretas, Activa: spawn torreta

var turrets: Array[Node] = []
const MAX_TURRETS := 3
var turret_cooldown := 0.0
const TURRET_COOLDOWN_MAX := 12.0

func _ready() -> void:
	damageable.max_health = 80
	damageable.health = 80
	base_speed = 198  # 90% de 220
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if turret_cooldown > 0:
		turret_cooldown -= delta
