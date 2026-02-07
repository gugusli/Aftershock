extends CanvasLayer

## Códice de sinergias descubiertas.

const COLOR_DORADO := Color("#FFD700")
const COLOR_PURPURA := Color("#9933FF")

@onready var panel := $Panel
@onready var list_container: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/SynergyList
@onready var back_button: Button = $Panel/Margin/VBox/BackButton
@onready var count_label: Label = $Panel/Margin/VBox/CountLabel

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh_list()

func _refresh_list() -> void:
	for c in list_container.get_children():
		c.queue_free()
	if not UpgradeManager:
		count_label.text = "SINERGIAS: 0"
		return
	var discovered: Array = UpgradeManager.discovered_synergies
	count_label.text = "SINERGIAS DESCUBIERTAS: %d" % discovered.size()
	for syn_id in discovered:
		var data: Dictionary = UpgradeManager.get_synergy_data(syn_id)
		if data.is_empty():
			continue
		var level: int = 3 if syn_id in UpgradeManager.SYNERGIES_LEVEL_3 else 2
		var card := _make_synergy_card(data.get("name", syn_id), data.get("desc", ""), level)
		list_container.add_child(card)
	if discovered.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Juega partidas y desbloquea sinergias para verlas aqui."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list_container.add_child(empty_label)

func _make_synergy_card(name_str: String, desc: String, level: int) -> PanelContainer:
	var panel_card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style.set_border_width_all(2)
	style.border_color = COLOR_DORADO if level == 2 else COLOR_PURPURA
	style.set_corner_radius_all(4)
	panel_card.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(vbox)
	panel_card.add_child(margin)
	var title := Label.new()
	title.text = name_str
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_DORADO if level == 2 else COLOR_PURPURA)
	vbox.add_child(title)
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	return panel_card

func _on_back_pressed() -> void:
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 0.0, 0.2)
	await t.finished
	queue_free()
