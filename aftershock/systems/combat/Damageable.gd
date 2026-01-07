extends Node

@export var max_health := 5
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	print("DAÑO:", amount, " VIDA:", health)

	if health <= 0:
		die()

func die() -> void:
	get_parent().queue_free()
