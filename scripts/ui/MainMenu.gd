class_name MainMenu
extends Control

const CARD_SCENE := "res://scenes/combat/TestCombat.tscn"
const SHOOTER_SCENE := "res://scenes/fps/FPSPrototype.tscn"
const MAP_VIEWER_SCENE := "res://scenes/ui/TacticalMapViewer.tscn"
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")

const PHASE_CHECKS := [
	{"label": "FPS Smoke Check", "scene": "res://tests/debug/FPSPrototypeCheck.tscn"},
	{"label": "Map Rules Check", "scene": "res://tests/debug/Phase61TacticalMapCheck.tscn"},
	{"label": "Card Gameplay Check", "scene": "res://tests/debug/Phase45GameplayMechanicsCheck.tscn"},
	{"label": "Responsive UI Check", "scene": "res://tests/debug/Phase44ResponsivenessGuidanceCheck.tscn"}
]

var status_label: Label
var map_data: Dictionary = {}


func _ready() -> void:
	map_data = TACTICAL_MAP_SCRIPT.get_default_map()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "MenuBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.035, 0.030, 0.026)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "MenuMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.name = "MenuLayout"
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)

	var nav := VBoxContainer.new()
	nav.name = "NavigationColumn"
	nav.custom_minimum_size = Vector2(360, 0)
	nav.add_theme_constant_override("separation", 12)
	layout.add_child(nav)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "DEAD MAN'S ANTE"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.35))
	nav.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "DEV HUB"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.66, 0.90, 0.92))
	nav.add_child(subtitle)

	_add_divider(nav)
	nav.add_child(_make_button("Full Game Experience", CARD_SCENE, "FullGameButton"))
	nav.add_child(_make_button("Card Board + Loadout", CARD_SCENE, "CardLabButton"))
	nav.add_child(_make_button("Shooter Arena", SHOOTER_SCENE, "ShooterArenaButton"))
	nav.add_child(_make_button("Tactical Map Viewer", MAP_VIEWER_SCENE, "MapViewerButton"))

	_add_divider(nav)
	var checks_title := Label.new()
	checks_title.text = "PHASE CHECKS"
	checks_title.add_theme_font_size_override("font_size", 15)
	checks_title.add_theme_color_override("font_color", Color(0.72, 0.74, 0.70))
	nav.add_child(checks_title)
	for check in PHASE_CHECKS:
		nav.add_child(_make_button(String(check.get("label", "Check")), String(check.get("scene", "")), "PhaseCheckButton"))

	status_label = Label.new()
	status_label.name = "LaunchStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.88, 0.64, 0.38))
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(status_label)

	var details := VBoxContainer.new()
	details.name = "DetailsColumn"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 16)
	layout.add_child(details)

	var map_title := Label.new()
	map_title.name = "MapTitle"
	map_title.text = String(map_data.get("name", "Crossfire Table"))
	map_title.add_theme_font_size_override("font_size", 25)
	map_title.add_theme_color_override("font_color", Color(0.94, 0.96, 0.88))
	details.add_child(map_title)

	var map_summary := RichTextLabel.new()
	map_summary.name = "MapSummary"
	map_summary.bbcode_enabled = false
	map_summary.fit_content = true
	map_summary.text = "%s\n%s" % [
		String(map_data.get("summary", "")),
		String(map_data.get("rules_summary", ""))
	]
	map_summary.add_theme_color_override("default_color", Color(0.78, 0.82, 0.80))
	details.add_child(map_summary)

	details.add_child(_build_map_preview())

	var lanes := Label.new()
	lanes.name = "ModeSummary"
	lanes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lanes.text = "Full Game starts the card run. Card Board jumps to the current hand/loadout lab. Shooter Arena opens the FPS branch. Tactical Map Viewer opens the shared Crossfire Table data."
	lanes.add_theme_color_override("font_color", Color(0.72, 0.80, 0.78))
	details.add_child(lanes)


func _make_button(label: String, scene_path: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_go_to_scene.bind(scene_path))
	return button


func _build_map_preview() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "CrossfireMapPreview"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for y in range(3):
		for x in range(3):
			var cell := Vector2i(x, y)
			grid.add_child(_build_map_cell(cell))
	return grid


func _build_map_cell(cell: Vector2i) -> PanelContainer:
	var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(map_data, cell)
	var panel := PanelContainer.new()
	panel.name = "MapCell_%s" % TACTICAL_MAP_SCRIPT.cell_key(cell)
	panel.custom_minimum_size = Vector2(160, 112)
	var style := StyleBoxFlat.new()
	style.bg_color = _get_feature_color(feature, "bg_color", Color(0.12, 0.14, 0.14))
	style.border_color = _get_feature_color(feature, "border_color", Color(0.42, 0.48, 0.48))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var short := Label.new()
	short.text = String(feature.get("short_label", ""))
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	short.add_theme_font_size_override("font_size", 26)
	short.add_theme_color_override("font_color", _get_feature_color(feature, "text_color", Color.WHITE))
	box.add_child(short)
	var label := Label.new()
	label.text = String(feature.get("label", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)
	return panel


func _get_feature_color(feature: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = feature.get(key, fallback)
	if typeof(value) == TYPE_COLOR:
		return value
	return fallback


func _go_to_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK and status_label != null:
		status_label.text = "Could not open %s" % scene_path


func _add_divider(parent: VBoxContainer) -> void:
	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(0, 8)
	parent.add_child(divider)
