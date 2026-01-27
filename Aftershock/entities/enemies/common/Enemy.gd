extends CharacterBody2D

# =========================
# SEÑALES
# =========================
signal enemy_died(enemy)

# =========================
# EXPORTACIONES Y VARIABLES
# =========================
@export_group("Movimiento")
@export var speed := 80.0

@export_group("Knockback")
@export var knockback_strength := 220.0
@export var knockback_friction := 900.0

@export_group("Lógica de Furia")
@export var can_enrage := false      
@export var enrage_threshold := 0.3  
@export var enrage_speed_mult := 1.8  

@export_group("Combate")
@export var contact_damage := 5.0
@export var damage_interval := 0.5
@export var exp_gem_scene: PackedScene
@export var health_potion_scene: PackedScene
@export var magnet_scene: PackedScene
@export var drop_chance_health := 0.05 # 5% de chance de dropear poción
@export var drop_chance_magnet := 0.02 # 2% de chance de dropear imán 

# =========================
# REFERENCIAS
# =========================
@onready var sprite_visual: Sprite2D = $Sprite2D 
@onready var damageable := $Damageable

var target: Node2D = null
var is_enraged := false
var dead := false 

# Daño al jugador
var player_ref: Node = null
var dealing_damage := false

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO

# =========================
# MÉTODOS BASE
# =========================
func _ready() -> void:
	# 🔥 Evita que el flash afecte a otros enemigos
	if sprite_visual.material:
		sprite_visual.material = sprite_visual.material.duplicate()

	$Hurtbox.body_entered.connect(_on_body_entered)
	$Hurtbox.body_exited.connect(_on_body_exited)

	damageable.died.connect(_on_died)
	damageable.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	if target == null or dead:
		return

	# Movimiento normal hacia el jugador
	var direction := (target.global_position - global_position).normalized()
	var move_velocity := direction * speed

	# Aplicar knockback (se suma)
	velocity = move_velocity + knockback_velocity
	move_and_slide()

	# Reducir knockback progresivamente
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)
	
	# Actualizar animación de caminar
	update_walk_animation(direction)

# =========================
# KNOCKBACK
# =========================
func apply_knockback(from_direction: Vector2) -> void:
	knockback_velocity += from_direction.normalized() * knockback_strength

# =========================
# SISTEMA DE FLASH
# =========================
func flash() -> void:
	if sprite_visual and sprite_visual.material:
		sprite_visual.material.set_shader_parameter("flash_modifier", 1.0)
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(sprite_visual):
			sprite_visual.material.set_shader_parameter("flash_modifier", 0.0)

# =========================
# DAÑO Y ESTADOS
# =========================
func _on_health_changed(current: float, max_hp: float) -> void:
	if current < max_hp and current > 0:
		flash()

	if not can_enrage or is_enraged or current <= 0:
		return

	var health_pct := float(current) / float(max_hp)
	if health_pct <= enrage_threshold:
		enter_enrage_mode()

func enter_enrage_mode() -> void:
	is_enraged = true
	speed *= enrage_speed_mult
	modulate = Color(1.5, 0.3, 0.3) # Rojo intenso para modo furia (valores ajustados)

# =========================
# CONTACTO CON EL JUGADOR
# =========================
func _on_body_entered(body: Node) -> void:
	if body.has_node("Damageable"):
		player_ref = body
		if not dealing_damage:
			dealing_damage = true
			_damage_loop()

func _on_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		dealing_damage = false

func _damage_loop() -> void:
	while dealing_damage and player_ref and is_inside_tree():
		if is_instance_valid(player_ref):
			var player_damageable = player_ref.get_node_or_null("Damageable")
			if player_damageable:
				player_damageable.take_damage(contact_damage)
		await get_tree().create_timer(damage_interval).timeout

# =========================
# MUERTE
# =========================
func _on_died() -> void:
	if dead: return

	dead = true
	dealing_damage = false
	set_physics_process(false)

	# Drops aleatorios
	if exp_gem_scene:
		call_deferred("_spawn_gem")
	
	# Drop de poción de vida (raro)
	if health_potion_scene and randf() < drop_chance_health:
		call_deferred("_spawn_health_potion")
	
	# Drop de imán (muy raro)
	if magnet_scene and randf() < drop_chance_magnet:
		call_deferred("_spawn_magnet")

	emit_signal("enemy_died", self)
	visible = false
	call_deferred("queue_free")

func _spawn_gem() -> void:
	var gem = exp_gem_scene.instantiate()
	get_tree().current_scene.add_child(gem)
	gem.global_position = global_position

func _spawn_health_potion() -> void:
	var potion = health_potion_scene.instantiate()
	get_tree().current_scene.add_child(potion)
	potion.global_position = global_position

func _spawn_magnet() -> void:
	var magnet = magnet_scene.instantiate()
	get_tree().current_scene.add_child(magnet)
	magnet.global_position = global_position

# =========================
# ANIMACIONES
# =========================
func update_walk_animation(direction: Vector2) -> void:
	if not sprite_visual or dead:
		return
	
	# Solo rotamos para que mire hacia el jugador (sin efecto de estiramiento)
	if direction.length() > 0.1:
		sprite_visual.rotation = direction.angle() + PI/2
