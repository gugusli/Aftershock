extends CharacterBody2D

@export var speed := 80.0
@export var target: Node2D

func _physics_process(_delta):
	if target == null:
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
