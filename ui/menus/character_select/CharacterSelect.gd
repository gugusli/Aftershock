extends CanvasLayer

## Menu de seleccion de personaje. Desbloqueo con Fragmentos.

const COLOR_CIAN := Color("#00D9FF")
const COLOR_DORADO := Color("#FFD700")
const COLOR_GRIS := Color("#444444")

@onready var panel := $Panel
@onready var list_container: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/CharacterList
@onready var back_button: Button = $Panel/Margin/VBox/BackButton
@onready var fragments_label: Label = $Panel/Margin/VBox/FragmentsLabel

var character_descriptions := {
	"RECLUTA": "Equilibrado. Adaptabilidad.",
	"FORTALEZA": "Tanque. Armadura pesada.",
	"VÉRTICE": "Asesino. Dash mortal.",
	"REVERBERACIÓN": "Controlador. Torretas.",
	"ECO": "Hibrido. Resonancia corrupta."
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_character_list()
	_update_fragments()

func _build_character_list() -> void:
	for ch in list_container.get_children():
		ch.queue_free()
	var order: Array = ["RECLUTA", "FORTALEZA", "VÉRTICE", "REVERBERACIÓN", "ECO"]
	for char_name in order:
		var cost: int = GameManager.CHARACTER_COSTS.get(char_name, 0) if char_name != "RECLUTA" else 0
		var desc: String = character_descriptions.get(char_name, "")
		var unlocked: bool = GameManager.is_character_unlocked(char_name)
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 56
		var name_label := Label.new()
		name_label.text = char_name
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", COLOR_DORADO if unlocked else COLOR_GRIS)
		name_label.custom_minimum_size.x = 200
		row.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc_label)
		var status_label := Label.new()
		if unlocked:
			status_label.text = "DESBLOQUEADO"
			status_label.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
		else:
			status_label.text = "%d F" % cost
			status_label.add_theme_color_override("font_color", COLOR_CIAN)
		status_label.add_theme_font_size_override("font_size", 18)
		row.add_child(status_label)
		var select_btn := Button.new()
		select_btn.text = "SELECCIONAR" if unlocked else "DESBLOQUEAR"
		select_btn.disabled = not unlocked and not GameManager.can_afford(cost)
		select_btn.pressed.connect(_on_character_action.bind(char_name, unlocked, cost))
		row.add_child(select_btn)
		list_container.add_child(row)

func _on_character_action(char_name: String, unlocked: bool, _cost: int) -> void:
	if unlocked:
		GameManager.current_session["character"] = char_name
		_close()
	else:
		if GameManager.unlock_character(char_name):
			_update_fragments()
			_build_character_list()

func _update_fragments() -> void:
	fragments_label.text = "FRAGMENTOS: %d" % GameManager.resonance_fragments

func _on_back_pressed() -> void:
	_close()

func _close() -> void:
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 0.0, 0.2)
	await t.finished
	queue_free()
