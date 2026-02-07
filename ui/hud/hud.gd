extends CanvasLayer

## =========================
## HUD - Interfaz durante gameplay
## Actualizado según GDD Visual v4
## =========================

@onready var stats_panel := $StatsPanel
@onready var health_bar := $StatsPanel/Margin/Content/HPSection/HealthBar
@onready var health_label := $StatsPanel/Margin/Content/HPSection/HealthBar/HealthLabel
@onready var exp_bar := $StatsPanel/Margin/Content/ExpBar
@onready var level_label := $StatsPanel/Margin/Content/Header/LevelNumber
@onready var wave_label := $WaveLabel
@onready var synergy_icons := $SynergyIcons
@onready var intensity_label := $IntensityLabel
@onready var timer_label := $TimerLabel

var health_tween: Tween
var alert_tween: Tween
var is_low_hp := false
var _connected_player: Node = null
var _wave_manager_ref: Node = null

# Colores del GDD
const COLOR_CIAN := Color("#00D9FF")
const COLOR_VERDE := Color("#00FF66")
const COLOR_AMARILLO := Color("#FFFF00")
const COLOR_ROJO := Color("#CC0000")
const COLOR_DORADO := Color("#FFD700")
const COLOR_PURPURA := Color("#9933FF")

func _ready() -> void:
	# Validar nodos requeridos (@onready)
	var required_nodes: Array = [stats_panel, health_bar, health_label, exp_bar, level_label, wave_label]
	for node in required_nodes:
		if not is_instance_valid(node):
			push_error("HUD: Nodo requerido no encontrado o inválido")
			return

	visible = true
	level_label.pivot_offset = level_label.size / 2
	wave_label.pivot_offset = wave_label.size / 2

	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	if GameManager and GameManager.has_signal("game_state_changed"):
		GameManager.game_state_changed.connect(_on_game_state_changed)

	if UpgradeManager and not UpgradeManager.synergy_unlocked.is_connected(_on_synergy_unlocked):
		UpgradeManager.synergy_unlocked.connect(_on_synergy_unlocked)

	var wm = tree.current_scene.get_node_or_null("WaveManager")
	if wm:
		_wave_manager_ref = wm
		set_wave(wm.current_wave)
		if not wm.wave_started.is_connected(set_wave):
			wm.wave_started.connect(set_wave)

func connect_player(player: Node) -> void:
	if not is_instance_valid(player):
		return
	_connected_player = player
	var damageable = player.get_node_or_null("Damageable")
	if damageable and is_instance_valid(damageable):
		if damageable.health_changed.is_connected(_on_health_changed):
			damageable.health_changed.disconnect(_on_health_changed)
		damageable.health_changed.connect(_on_health_changed)
		_update_hp_visual(damageable.health, damageable.max_health)

	if player.has_signal("experience_changed"):
		player.experience_changed.connect(_on_experience_changed)
	if player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_leveled_up)
	_refresh_synergy_icons()

func _on_health_changed(current: float, max_health: float) -> void:
	if not is_instance_valid(health_bar):
		return
	var old_val = health_bar.value
	_update_hp_visual(current, max_health)
	if health_tween: health_tween.kill()
	health_tween = create_tween().set_parallel(true)
	health_tween.tween_property(health_bar, "value", current, 0.2).set_trans(Tween.TRANS_CUBIC)
	if current < old_val:
		_apply_damage_fx()

func _update_hp_visual(curr: float, m_hp: float) -> void:
	health_bar.max_value = m_hp
	health_label.text = "%d / %d" % [int(curr), int(m_hp)]
	
	# Colores según GDD: verde > amarillo > rojo
	var health_percent := curr / m_hp
	if health_percent > 0.5:
		health_bar.modulate = COLOR_VERDE
	elif health_percent > 0.25:
		health_bar.modulate = COLOR_AMARILLO
	else:
		health_bar.modulate = COLOR_ROJO
	
	if health_percent <= 0.3:
		if not is_low_hp: _start_low_hp_alert()
	else:
		_stop_low_hp_alert()

func _apply_damage_fx() -> void:
	var t = create_tween()
	stats_panel.modulate = Color(2, 1, 1)
	t.tween_property(stats_panel, "modulate", Color.WHITE, 0.2)
	_shake_ui(stats_panel, 5.0)

func _start_low_hp_alert() -> void:
	is_low_hp = true
	if alert_tween: alert_tween.kill()
	alert_tween = create_tween().set_loops()
	alert_tween.tween_property(health_bar, "modulate", Color(2, 0.5, 0.5), 0.5)
	alert_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.5)

func _stop_low_hp_alert() -> void:
	is_low_hp = false
	if alert_tween: 
		alert_tween.kill()
		health_bar.modulate = Color.WHITE

func _on_experience_changed(current: int, required: int) -> void:
	exp_bar.max_value = required
	create_tween().tween_property(exp_bar, "value", current, 0.3).set_trans(Tween.TRANS_SINE)

func _on_leveled_up(new_level: int) -> void:
	level_label.text = "LVL %02d" % new_level
	var t = create_tween()
	t.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.1)
	t.tween_property(level_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func set_wave(number: int) -> void:
	wave_label.text = "— OLEADA %02d —" % number
	var t = create_tween()
	wave_label.modulate.a = 0
	t.tween_property(wave_label, "modulate:a", 1.0, 0.4)
	t.tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	t.tween_property(wave_label, "scale", Vector2.ONE, 0.2).set_delay(0.2)

func _shake_ui(node: Control, intensity: float) -> void:
	var orig_pos = node.position
	var t = create_tween()
	for i in range(4):
		var rand_pos = orig_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		t.tween_property(node, "position", rand_pos, 0.05)
	t.tween_property(node, "position", orig_pos, 0.05)

func _on_synergy_unlocked(synergy_name: String, level: int) -> void:
	show_synergy_popup(synergy_name, level)
	_refresh_synergy_icons()

func _on_game_state_changed(state: int) -> void:
	if not GameManager:
		return
	match state:
		GameManager.GameState.PLAYING:
			visible = true
		_:
			visible = false
			_stop_low_hp_alert()

# =========================
# INDICADOR DE SINERGIAS
# =========================
func show_synergy_popup(synergy_name: String, level: int) -> void:
	var synergy_label := Label.new()
	synergy_label.text = "¡SINERGIA NIVEL %d!\n%s" % [level, synergy_name]
	synergy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	synergy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if level == 2:
		synergy_label.modulate = COLOR_DORADO
	else:
		synergy_label.modulate = COLOR_PURPURA
	
	synergy_label.position = Vector2(get_viewport().size.x / 2 - 150, 200)
	synergy_label.size = Vector2(300, 80)
	
	add_child(synergy_label)
	
	var tween = create_tween()
	synergy_label.scale = Vector2(0.5, 0.5)
	synergy_label.modulate.a = 0
	tween.parallel().tween_property(synergy_label, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(synergy_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(synergy_label, "scale", Vector2.ONE, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(synergy_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(synergy_label.queue_free)

# =========================
# INDICADOR DE INTENSIDAD (Director IA)
# =========================
func update_intensity_indicator() -> void:
	if not DirectorAI or not is_instance_valid(intensity_label):
		return
	intensity_label.text = "DIRECTOR: %s" % DirectorAI.get_intensity_state_name()
	intensity_label.add_theme_color_override("font_color", DirectorAI.get_intensity_color())

func _update_timer() -> void:
	if not is_instance_valid(timer_label) or not GameManager:
		return
	if GameManager.game_state != GameManager.GameState.PLAYING:
		return
	var elapsed = (Time.get_ticks_msec() / 1000.0) - GameManager.current_session.get("start_time", 0.0)
	timer_label.text = GameManager.format_time(elapsed)

func _process(_delta: float) -> void:
	if not GameManager:
		return
	if GameManager.game_state == GameManager.GameState.PLAYING:
		update_intensity_indicator()
		_update_timer()

# =========================
# INDICADORES DE SINERGIAS ACTIVAS (GDD §2.5 - centro superior)
# =========================
func _refresh_synergy_icons() -> void:
	if not is_instance_valid(synergy_icons):
		return
	for c in synergy_icons.get_children():
		c.queue_free()
	if not UpgradeManager:
		return
	for syn_id in UpgradeManager.active_synergies_l2:
		var data = UpgradeManager.get_synergy_data(syn_id)
		if data.is_empty() and SynergyManager:
			data = SynergyManager.get_synergy_data(syn_id)
		_add_synergy_badge(data.get("name", syn_id), 2, data.get("color", COLOR_DORADO))
	for syn_id in UpgradeManager.active_synergies_l3:
		var data = UpgradeManager.get_synergy_data(syn_id)
		if data.is_empty() and SynergyManager:
			data = SynergyManager.get_synergy_data(syn_id)
		_add_synergy_badge(data.get("name", syn_id), 3, data.get("color", COLOR_PURPURA))

func _add_synergy_badge(name_text: String, level: int, color: Color) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(32, 32)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(color.r, color.g, color.b, 0.5)
	style.shadow_size = 3
	panel.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = str(level)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	synergy_icons.add_child(panel)
	panel.tooltip_text = name_text

func _exit_tree() -> void:
	# Desconectar señales para evitar leaks y lógica zombie
	if GameManager and GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.disconnect(_on_game_state_changed)
	if UpgradeManager and UpgradeManager.synergy_unlocked.is_connected(_on_synergy_unlocked):
		UpgradeManager.synergy_unlocked.disconnect(_on_synergy_unlocked)
	if _wave_manager_ref and is_instance_valid(_wave_manager_ref) and _wave_manager_ref.wave_started.is_connected(set_wave):
		_wave_manager_ref.wave_started.disconnect(set_wave)
	_wave_manager_ref = null
	if _connected_player and is_instance_valid(_connected_player):
		var damageable = _connected_player.get_node_or_null("Damageable")
		if damageable and is_instance_valid(damageable) and damageable.health_changed.is_connected(_on_health_changed):
			damageable.health_changed.disconnect(_on_health_changed)
		if _connected_player.has_signal("experience_changed") and _connected_player.experience_changed.is_connected(_on_experience_changed):
			_connected_player.experience_changed.disconnect(_on_experience_changed)
		if _connected_player.has_signal("leveled_up") and _connected_player.leveled_up.is_connected(_on_leveled_up):
			_connected_player.leveled_up.disconnect(_on_leveled_up)
	_connected_player = null
