extends CanvasLayer

@onready var health_bar := $HealthBar

func connect_player(player: Node) -> void:
	var dmg: Node = player.get_node("Damageable")
	dmg.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
