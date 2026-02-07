extends "res://entities/player/player.gd"
## ECO - El Híbrido (GDD §5) - DESBLOQUEABLE
## HP: 90, Velocidad 110%, Transformación mutante (+100% daño, +50% velocidad, 15s)

enum Form { HUMAN, MUTANT }
var current_form := Form.HUMAN
var transformation_meter := 0.0
var mutant_duration := 0.0
const MUTANT_DURATION_MAX := 15.0

func _ready() -> void:
	damageable.max_health = 90
	damageable.health = 90
	base_speed = 242  # 110% de 220
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if current_form == Form.MUTANT:
		mutant_duration -= delta
		if mutant_duration <= 0:
			_transform_to_human()
	elif transformation_meter >= 100:
		_transform_to_mutant()

func add_resonance(amount: float) -> void:
	if current_form == Form.MUTANT:
		return
	transformation_meter = min(transformation_meter + amount, 100.0)

func _transform_to_mutant() -> void:
	current_form = Form.MUTANT
	transformation_meter = 0
	mutant_duration = MUTANT_DURATION_MAX
	# Bonificaciones: se aplican via multiplicadores en _get_bullet_damage etc.

func _transform_to_human() -> void:
	current_form = Form.HUMAN
