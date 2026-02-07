extends Node

## =========================
## AFTERSHOCK - VFX Manager
## Sistema de efectos visuales según GDD
## =========================

# =========================
# COLORES DEL GDD
# =========================
const COLOR_CRITICO := Color("#FF0033")
const COLOR_NORMAL := Color("#FFFFFF")
const COLOR_FUEGO := Color("#FF6600")
const COLOR_HIELO := Color("#00BFFF")
const COLOR_VENENO := Color("#9900FF")
const COLOR_ELECTRICO := Color("#00BFFF")
const COLOR_DORADO := Color("#FFD700")

# =========================
# CONFIGURACIÓN DE EFECTOS (GDD §11.2: 60 FPS en mid-range)
# =========================
var hitstop_enabled := true
var screen_shake_enabled := true
var damage_numbers_enabled := true
var slowmo_on_crit := true
const MAX_SPARK_PARTICLES := 60  # Límite para mantener FPS
var _active_spark_count := 0

# Constantes (evitar magic numbers)
const SHAKE_INTENSITY_NORMAL := 1.5
const SHAKE_DURATION_NORMAL := 0.08
const SHAKE_INTENSITY_CRIT := 4.0
const SHAKE_DURATION_CRIT := 0.12
const HITSTOP_DURATION_NORMAL := 0.02
const HITSTOP_DURATION_CRIT := 0.05
const SLOWMO_SCALE_CRIT := 0.3
const SLOWMO_DURATION_CRIT := 0.1
const DAMAGE_FONT_SIZE_NORMAL := 18
const DAMAGE_FONT_SIZE_CRIT := 26
const DAMAGE_LABEL_OUTLINE_SIZE := 3
const DAMAGE_LABEL_FLOAT_HEIGHT := 50.0
const DAMAGE_LABEL_FADE_DELAY := 0.3
const DAMAGE_LABEL_FADE_DURATION := 0.4
const DAMAGE_LABEL_ANIM_DURATION := 0.6
const SPARK_SPEED_MIN := 80.0
const SPARK_SPEED_MAX := 150.0
const SPARK_TRAVEL_MULT := 0.3
const SPARK_ANIM_DURATION := 0.25
const IMPACT_FLASH_SIZE := 32
const SYNERGY_SHAKE_INTENSITY := 8.0
const SYNERGY_SHAKE_DURATION := 0.3
const SYNERGY_SLOWMO_SCALE := 0.2
const SYNERGY_SLOWMO_DURATION := 0.3
const DEATH_SPARKS_NORMAL := 8
const DEATH_SPARKS_ELITE := 15
const DEATH_SHAKE_ELITE := 6.0
const EXPLOSION_SHAKE := 7.0
const COLOR_SYNERGY_L3 := Color("#9933FF")

# =========================
# REFERENCIAS
# =========================
var camera: Node = null

func _ready() -> void:
	pass  # Inicialización opcional si se necesita en el futuro

# =========================
# IMPACTO NORMAL
# =========================
func _use_screen_shake() -> bool:
	if GameManager:
		return GameManager.settings.get("screen_shake_enabled", screen_shake_enabled)
	return screen_shake_enabled

func _use_damage_numbers() -> bool:
	if GameManager:
		return GameManager.settings.get("show_damage_numbers", damage_numbers_enabled)
	return damage_numbers_enabled

func play_hit_effect(position: Vector2, damage: float, is_critical: bool = false) -> void:
	if is_critical:
		_play_critical_hit(position, damage)
	else:
		_play_normal_hit(position, damage)

func _play_normal_hit(position: Vector2, damage: float) -> void:
	if _use_damage_numbers():
		_spawn_damage_number(position, damage, COLOR_NORMAL, 1.0)
	
	# Chispas pequeñas
	_spawn_spark_particles(position, 5, COLOR_NORMAL)
	
	if _use_screen_shake():
		get_tree().call_group("camera", "shake", SHAKE_INTENSITY_NORMAL, SHAKE_DURATION_NORMAL)

	# Hitstop breve (1-2 frames)
	if hitstop_enabled:
		_apply_hitstop(HITSTOP_DURATION_NORMAL)

func _play_critical_hit(position: Vector2, damage: float) -> void:
	if _use_damage_numbers():
		_spawn_damage_number(position, damage, COLOR_CRITICO, 1.5, true)
	
	# Más chispas
	_spawn_spark_particles(position, 15, COLOR_CRITICO)
	
	# Flash rojo en el punto de impacto
	_spawn_impact_flash(position, COLOR_CRITICO)
	
	if _use_screen_shake():
		get_tree().call_group("camera", "shake", SHAKE_INTENSITY_CRIT, SHAKE_DURATION_CRIT)

	# Hitstop mayor (3-4 frames)
	if hitstop_enabled:
		_apply_hitstop(HITSTOP_DURATION_CRIT)

	# Slowmo breve
	if slowmo_on_crit:
		_apply_slowmo(SLOWMO_SCALE_CRIT, SLOWMO_DURATION_CRIT)

# =========================
# NÚMEROS DE DAÑO FLOTANTE
# =========================
func _spawn_damage_number(pos: Vector2, damage: float, color: Color, scale_mult: float = 1.0, add_exclaim: bool = false) -> void:
	var label: Label = Label.new()
	var damage_text: String = str(int(damage))
	if add_exclaim:
		damage_text += "!"

	label.text = damage_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var base_size: int = DAMAGE_FONT_SIZE_CRIT if add_exclaim else DAMAGE_FONT_SIZE_NORMAL
	label.add_theme_font_size_override("font_size", int(base_size * scale_mult))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", DAMAGE_LABEL_OUTLINE_SIZE)

	label.global_position = pos + Vector2(randf_range(-10, 10), -20)
	label.z_index = 100
	label.scale = Vector2(scale_mult, scale_mult)

	get_tree().current_scene.add_child(label)

	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - DAMAGE_LABEL_FLOAT_HEIGHT, DAMAGE_LABEL_ANIM_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, DAMAGE_LABEL_FADE_DURATION).set_delay(DAMAGE_LABEL_FADE_DELAY)

	if add_exclaim:
		var scale_tween: Tween = label.create_tween()
		scale_tween.tween_property(label, "scale", Vector2(scale_mult * 1.3, scale_mult * 1.3), 0.1)
		scale_tween.tween_property(label, "scale", Vector2(scale_mult, scale_mult), 0.15)

	tween.chain().tween_callback(label.queue_free)

# =========================
# PARTÍCULAS DE CHISPAS (con límite para rendimiento)
# =========================
func _spawn_spark_particles(pos: Vector2, count: int, color: Color) -> void:
	if _active_spark_count >= MAX_SPARK_PARTICLES:
		count = 0
	else:
		count = mini(count, MAX_SPARK_PARTICLES - _active_spark_count)
	for i in range(count):
		_active_spark_count += 1
		var spark: Sprite2D = Sprite2D.new()
		spark.texture = PlaceholderTexture2D.new()
		spark.texture.size = Vector2(4, 4)
		spark.modulate = color
		spark.global_position = pos
		spark.z_index = 50

		get_tree().current_scene.add_child(spark)

		var angle: float = randf() * TAU
		var speed: float = randf_range(SPARK_SPEED_MIN, SPARK_SPEED_MAX)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var target_pos: Vector2 = pos + direction * speed * SPARK_TRAVEL_MULT

		var tween: Tween = spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "global_position", target_pos, SPARK_ANIM_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, 0.2).set_delay(0.1)
		tween.tween_property(spark, "scale", Vector2(0.3, 0.3), SPARK_ANIM_DURATION)
		tween.chain().tween_callback(func(): _on_spark_freed(spark))

func _on_spark_freed(spark: Node) -> void:
	_active_spark_count = maxi(0, _active_spark_count - 1)
	spark.queue_free()

# =========================
# FLASH DE IMPACTO
# =========================
func _spawn_impact_flash(pos: Vector2, color: Color) -> void:
	var flash: Sprite2D = Sprite2D.new()
	flash.texture = PlaceholderTexture2D.new()
	flash.texture.size = Vector2(IMPACT_FLASH_SIZE, IMPACT_FLASH_SIZE)
	flash.modulate = Color(color.r, color.g, color.b, 0.8)
	flash.global_position = pos
	flash.z_index = 60
	flash.scale = Vector2(0.5, 0.5)
	
	get_tree().current_scene.add_child(flash)
	
	var tween: Tween = flash.create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(flash.queue_free)

# =========================
# HITSTOP (FRAME FREEZE)
# =========================
func _apply_hitstop(duration: float) -> void:
	# Pausar brevemente el tiempo
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05).timeout  # Timer real, no afectado por time_scale
	Engine.time_scale = 1.0

# =========================
# SLOWMO
# =========================
func _apply_slowmo(time_scale: float, duration: float) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0

# =========================
# EFECTOS ESPECIALES
# =========================
func play_synergy_unlock_effect(level: int) -> void:
	var flash_color: Color = COLOR_DORADO if level == 2 else COLOR_SYNERGY_L3
	_screen_flash(flash_color, 0.2)

	get_tree().call_group("camera", "shake", SYNERGY_SHAKE_INTENSITY, SYNERGY_SHAKE_DURATION)
	_apply_slowmo(SYNERGY_SLOWMO_SCALE, SYNERGY_SLOWMO_DURATION)

func play_death_effect(position: Vector2, is_elite: bool = false) -> void:
	var particle_count: int = DEATH_SPARKS_ELITE if is_elite else DEATH_SPARKS_NORMAL
	var color: Color = COLOR_FUEGO if not is_elite else COLOR_DORADO

	_spawn_spark_particles(position, particle_count, color)

	if is_elite:
		get_tree().call_group("camera", "shake", DEATH_SHAKE_ELITE, 0.2)
		_apply_slowmo(0.4, 0.15)

func play_explosion_effect(position: Vector2, radius: float) -> void:
	var wave: Sprite2D = Sprite2D.new()
	wave.texture = PlaceholderTexture2D.new()
	wave.texture.size = Vector2(radius * 2, radius * 2)
	wave.modulate = Color(COLOR_FUEGO.r, COLOR_FUEGO.g, COLOR_FUEGO.b, 0.6)
	wave.global_position = position
	wave.z_index = 40
	wave.scale = Vector2(0.2, 0.2)

	get_tree().current_scene.add_child(wave)

	var tween: Tween = wave.create_tween().set_parallel(true)
	tween.tween_property(wave, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(wave, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(wave.queue_free)

	_spawn_spark_particles(position, 20, COLOR_FUEGO)
	get_tree().call_group("camera", "shake", EXPLOSION_SHAKE, 0.2)

func _screen_flash(color: Color, duration: float) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(color.r, color.g, color.b, 0.3)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().current_scene.add_child(canvas)

	var tween: Tween = overlay.create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration)
	tween.tween_callback(canvas.queue_free)
