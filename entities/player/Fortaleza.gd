extends "res://entities/player/player.gd"
## FORTALEZA - El Tanque (GDD §5)
## HP: 200, Velocidad 70%, Reducción daño +20%, Escudo activo

var shield_active := false
var shield_hp := 0.0
var shield_cooldown := 0.0
const SHIELD_COOLDOWN_MAX := 15.0

func _ready() -> void:
	damageable.max_health = 200
	damageable.health = 200
	base_speed = 154  # 70% de 220
	super._ready()

func _process(delta: float) -> void:
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return
	super._process(delta)
	if shield_cooldown > 0:
		shield_cooldown -= delta
	if UpgradeManager and UpgradeManager.stats.regen_per_sec > 0:
		pass  # Regen handled in parent

func preprocess_damage(amount: float) -> float:
	amount *= 0.8  # -20% daño (pasiva)
	if shield_active and shield_hp > 0:
		var absorbed = minf(amount, shield_hp)
		shield_hp -= absorbed
		if shield_hp <= 0:
			shield_active = false
		return amount - absorbed  # resto va a vida
	return amount

func activate_shield() -> void:
	if shield_cooldown > 0 or shield_active:
		return
	shield_hp = damageable.max_health * 0.5
	shield_active = true
	shield_cooldown = SHIELD_COOLDOWN_MAX
