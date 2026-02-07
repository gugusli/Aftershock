extends CanvasLayer

# --- REFERENCIAS DE UI ---
@onready var main_control = $MainControl
@onready var panel = $MainControl/Panel
@onready var title = $MainControl/Panel/VBox/Title
@onready var status_msg = $MainControl/Panel/VBox/StatusMsg

@onready var value_time = $MainControl/Panel/VBox/StatsGrid/ValueTime
@onready var value_kills = $MainControl/Panel/VBox/StatsGrid/ValueKills
@onready var value_sinergy = $MainControl/Panel/VBox/StatsGrid/ValueSinergy

@onready var retry_btn = $MainControl/Panel/VBox/Buttons/RetryBtn
@onready var quit_btn = $MainControl/Panel/VBox/Buttons/QuitBtn
@onready var bg_overlay = $BackgroundBlur

# --- CONFIGURACIÓN ---
var is_victory := false
var defeat_messages: Array[String] = [
	"ABRUMADO POR LAS MUTACIONES",
	"SISTEMAS CRÍTICOS DAÑADOS",
	"CONEXIÓN NEURAL INTERRUMPIDA",
	"BIOMASA CONSUMIDA POR EL DISTRITO 0",
	"FALLO EN EL NÚCLEO DE PODER"
]

func _ready() -> void:
	hide()
	main_control.modulate.a = 0
	
	# Conectar señales
	retry_btn.pressed.connect(_on_retry_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# Efectos de hover para botones
	for btn in [retry_btn, quit_btn]:
		btn.mouse_entered.connect(func(): _animate_button(btn, true))
		btn.mouse_exited.connect(func(): _animate_button(btn, false))

# Función principal para disparar la pantalla
func setup_and_show(stats: Dictionary) -> void:
	is_victory = stats.get("victory", false)
	
	# 1. Configurar textos según el resultado
	if is_victory:
		title.text = "PROTOCOLO COMPLETADO"
		title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4)) # Verde Neón
		status_msg.text = "DATOS EXPORTADOS - DISTRITO 0 ASEGURADO"
	else:
		title.text = "PROTOCOLO ABORTADO"
		title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15)) # Rojo Alerta
		status_msg.text = defeat_messages.pick_random()

	# 2. Resetear valores para la animación
	value_time.text = stats.get("time", "00:00")
	value_kills.text = "0"
	value_sinergy.text = stats.get("sinergy", "Ninguna")

	# 3. Mostrar y Pausar
	show()
	var tree = get_tree()
	if tree:
		tree.paused = true
	_animate_entrance(stats.get("kills", 0))

func _animate_entrance(final_kills: int) -> void:
	var tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Aparecer fondo con glitch
	tween.tween_property(main_control, "modulate:a", 1.0, 0.4)
	bg_overlay.material.set_shader_parameter("intensity", 0.05)
	
	# Efecto "Pop" del panel
	panel.scale = Vector2(0.8, 0.8)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animar el conteo de bajas (Dopamina rápida)
	var count_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	count_tween.tween_method(func(v): value_kills.text = str(v), 0, final_kills, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	retry_btn.grab_focus()

func _animate_button(btn: Button, hovered: bool) -> void:
	var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if hovered:
		t.tween_property(btn, "modulate", Color(1.5, 1.5, 1.5), 0.1) # Brillo neón
	else:
		t.tween_property(btn, "modulate", Color.WHITE, 0.1)

# --- ACCIONES ---
func _on_retry_pressed() -> void:
	var tree = get_tree()
	if not tree:
		push_warning("EndScreen: get_tree() no disponible")
		return
	# Efecto de "Apagado" antes de reiniciar
	var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(main_control, "scale:y", 0.0, 0.2).set_trans(Tween.TRANS_QUART)
	await t.finished

	tree.paused = false
	tree.reload_current_scene()

func _on_quit_pressed() -> void:
	var tree = get_tree()
	if not tree:
		push_warning("EndScreen: get_tree() no disponible")
		return
	tree.paused = false
	tree.change_scene_to_file("res://ui/menus/main_menu/MainMenu.tscn")
