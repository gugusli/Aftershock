extends CanvasLayer

# 🔗 Referencias automáticas a los botones
@onready var buttons = [
	$CenterContainer/PanelContainer/VBoxContainer/CardContainer/ButtonOption1,
	$CenterContainer/PanelContainer/VBoxContainer/CardContainer/ButtonOption2,
	$CenterContainer/PanelContainer/VBoxContainer/CardContainer/ButtonOption3
]

# =========================
# DICCIONARIO DE MEJORAS
# =========================
var upgrades = {
	"dmg": {
		"title": "FUERZA",
		"desc": "+25% Daño",
		"color": Color.INDIAN_RED
	},
	"speed": {
		"title": "AGILIDAD",
		"desc": "+15% Velocidad",
		"color": Color.SEA_GREEN
	},
	"fire_rate": {
		"title": "CADENCIA",
		"desc": "+20% Disparo",
		"color": Color.CORNFLOWER_BLUE
	},
	"health": {
		"title": "VITALIDAD",
		"desc": "+20 Vida Máx",
		"color": Color.ORANGE_RED
	},
	"pierce": { # 🔥 SE DESBLOQUEA EN OLEADA 3
		"title": "PERFORACIÓN",
		"desc": "Atraviesa 1 enemigo extra",
		"color": Color.PURPLE
	},
	"garlic": {
		"title": "AJO",
		"desc": "Área de daño constante",
		"color": Color.YELLOW
	},
	"bouncing": {
		"title": "REBOTES",
		"desc": "Proyectiles que rebotan",
		"color": Color.CYAN
	}
}

var current_options: Array[String] = []

# =========================
# READY
# =========================
func _ready() -> void:
	visible = false

	# Conectamos los 3 botones a una sola función usando un índice
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_upgrade_selected.bind(i))

# =========================
# MOSTRAR MENÚ
# =========================
func show_menu() -> void:
	visible = true
	get_tree().paused = true # ⏸️ Congela el mundo

	for b in buttons:
		b.disabled = false

	current_options.clear()
	
	# 1. Obtenemos todas las claves ["dmg", "speed", "pierce", etc]
	var keys: Array = upgrades.keys()

	# 2. Filtro por oleada: perforación solo desde oleada 3
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	if wave_manager and wave_manager.current_wave < 3:
		keys.erase("pierce")
	
	# 3. Quitar mejoras ya obtenidas (arma única)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_taken_upgrades"):
		for k in p.get_taken_upgrades():
			keys.erase(k)

	# 4. Barajamos y asignamos a los botones
	keys.shuffle()
	for i in range(buttons.size()):
		# Verificamos que existan suficientes cartas (por si filtramos demasiadas)
		if i < keys.size():
			buttons[i].visible = true
			var key: String = keys[i]
			current_options.append(key)

			var data = upgrades[key]
			buttons[i].text = data["title"] + "\n\n" + data["desc"]
			buttons[i].add_theme_color_override("font_color", data["color"])
		else:
			# Si quedan menos de 3 cartas disponibles, ocultamos el botón sobrante
			buttons[i].visible = false

# =========================
# SELECCIÓN DE MEJORA
# =========================
func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return

	var upgrade_key: String = current_options[index]

	# Deshabilitar todos los botones para evitar doble clic
	for btn in buttons:
		btn.disabled = true

	# Buscamos al jugador por su grupo
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade_key)
	else:
		push_warning("UpgradeMenu: No se encontró jugador con apply_upgrade, la mejora no se aplicó.")

	# Pequeño feedback visual antes de cerrar
	var tween = create_tween()
	var selected_btn = buttons[index]
	tween.tween_property(selected_btn, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(selected_btn, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished

	visible = false
	get_tree().paused = false # ▶️ Reanuda el juego

	# Rehabilitar para la próxima vez que se muestre el menú
	for btn in buttons:
		btn.disabled = false
