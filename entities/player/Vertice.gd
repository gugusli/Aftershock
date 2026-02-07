extends "res://entities/player/player.gd"
## VÉRTICE - El Asesino (GDD §5)
## HP: 60, Velocidad 130%, +30% crítico, Dash con 3 cargas

var dash_charges := 3
const MAX_DASH_CHARGES := 3
var dash_recharge_timer := 0.0
const DASH_RECHARGE_TIME := 8.0

func _ready() -> void:
	damageable.max_health = 60
	damageable.health = 60
	base_speed = 286  # 130% de 220
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if dash_charges < MAX_DASH_CHARGES:
		dash_recharge_timer += delta
		if dash_recharge_timer >= DASH_RECHARGE_TIME:
			dash_recharge_timer = 0
			dash_charges = min(dash_charges + 1, MAX_DASH_CHARGES)
