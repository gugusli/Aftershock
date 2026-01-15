extends Node

signal health_changed(current, max)
signal died

@export var max_health := 100
var health: int

func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount
	health = max(health, 0)

	emit_signal("health_changed", health, max_health)

	if health <= 0:
		emit_signal("died")
