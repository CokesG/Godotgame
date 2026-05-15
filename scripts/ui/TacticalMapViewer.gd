class_name TacticalMapViewer
extends Control

const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const CARD_SCENE := "res://scenes/combat/TestCombat.tscn"
const SHOOTER_SCENE := "res://scenes/fps/FPSPrototype.tscn"
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")

var map_data: Dictionary = {}
var detail_label: RichTextLabel


func _ready() -> void:
	map_data = TACTICAL_MAP_SCRIPT.get_default_map()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "MapViewerBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.030, 0.032)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "MapViewerLayout"
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)

	var title := Label.new()
	title.name = "MapViewerTitle"
	title.text = String(map_data.get("name", "Crossfire Table"))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	header.add_child(_make_nav_button("Menu", MENU_SCENE))
	header.add_child(_make_nav_button("Card Board", CARD_SCENE))
	header.add_child(_make_nav_button("Shooter", SHOOTER_SCENE))

	var body := HBoxContainer.new()
	body.name = "MapViewerBody"
	body.add_theme_constant_override("separation", 20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	body.add_child(_build_map_grid())

	detail_label = RichTextLabel.new()
	detail_label.name = "MapDetail"
	detail_label.bbcode_enabled = false
	detail_label.fit_content = false
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_label.add_theme_color_override("default_color", Color(0.80, 0.84, 0.82))
	body.add_child(detail_label)
	_set_detail_for_cell(Vector2i(1, 1))


func _build_map_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "TacticalMapGrid"
	grid.columns = 3
	grid.custom_minimum_size = Vector2(620, 500)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for y in range(3):
		for x in range(3):
			var cell := Vector2i(x, y)
			grid.add_child(_build_map_button(cell))
	return grid


func _build_map_button(cell: Vector2i) -> Button:
	var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(map_data, cell)
	var button := Button.new()
	button.name = "MapCell_%s" % TACTICAL_MAP_SCRIPT.cell_key(cell)
	button.custom_minimum_size = Vector2(196, 156)
	button.text = "%s\n%s" % [
		String(feature.get("short_label", "")),
		String(feature.get("label", ""))
	]
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", _get_feature_color(feature, "text_color", Color.WHITE))
	button.pressed.connect(_set_detail_for_cell.bind(cell))

	var normal := StyleBoxFlat.new()
	normal.bg_color = _get_feature_color(feature, "bg_color", Color(0.12, 0.14, 0.14))
	normal.border_color = _get_feature_color(feature, "border_color", Color(0.42, 0.48, 0.48))
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = normal.border_color.lightened(0.18)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button


func _set_detail_for_cell(cell: Vector2i) -> void:
	if detail_label == null:
		return
	var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(map_data, cell)
	var lines := [
		String(feature.get("label", "")),
		"Cell %s | %s" % [TACTICAL_MAP_SCRIPT.cell_key(cell), String(feature.get("type", "")).capitalize()],
		"",
		String(feature.get("description", "")),
		"",
		"Map: %s" % String(map_data.get("summary", "")),
		"Rules: %s" % String(map_data.get("rules_summary", ""))
	]
	var damage_bonus := int(feature.get("card_damage_bonus", 0))
	var mitigation := int(feature.get("incoming_damage_mitigation", 0))
	if damage_bonus != 0:
		lines.append("Card pressure: +%d damage from this position." % damage_bonus)
	if mitigation != 0:
		lines.append("Cover: -%d incoming lane damage here." % mitigation)
	detail_label.text = "\n".join(lines)


func _make_nav_button(label: String, scene_path: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(130, 40)
	button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)
	return button


func _get_feature_color(feature: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = feature.get(key, fallback)
	if typeof(value) == TYPE_COLOR:
		return value
	return fallback
