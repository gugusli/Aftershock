extends CharacterBody2D

# =========================
# SEÑALES
# =========================
signal enemy_died(enemy)

# =========================
# MOVIMIENTO
# =========================
@export var speed := 80.0
var target: Node2D = null

# =========================
# DAÑO POR CONTACTO
# =========================
@export var contact_damage := 5
@export var damage_interval := 0.5

var player_ref: Node = null
var dealing_damage := false

# =========================
# DAMAGEABLE
# =========================
@onready var damageable := $Damageable

# =========================
# READY
# =========================
func _ready() -> void:
	$Hurtbox.body_entered.connect(_on_body_entered)
	$Hurtbox.body_exited.connect(_on_body_exited)

	damageable.died.connect(_on_died)

# =========================
# MOVIMIENTO HACIA EL PLAYER
# =========================
func _physics_process(_delta: float) -> void:
	if target == null:
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

# =========================
# CONTACTO CON EL PLAYER
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

# =========================
# LOOP DE DAÑO CONTINUO
# =========================
func _damage_loop() -> void:
	while dealing_damage and player_ref and is_inside_tree():
		if is_instance_valid(player_ref) and player_ref.has_node("Damageable"):
			player_ref.get_node("Damageable").take_damage(contact_damage)
		await get_tree().create_timer(damage_interval).timeout

# =========================
# MUERTE
# =========================
func _on_died() -> void:
	dealing_damage = false
	emit_signal("enemy_died", self)
	queue_free()
