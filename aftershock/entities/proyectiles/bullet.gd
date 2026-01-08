extends Area2D

@export var speed := 800.0
@export var damage := 1

var direction: Vector2 = Vector2.ZERO

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage)
		queue_free()
