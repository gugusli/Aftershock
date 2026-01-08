extends Area2D

@onready var damageable := get_parent().get_node("Damageable")

func receive_hit(amount: int) -> void:
	damageable.take_damage(amount)
