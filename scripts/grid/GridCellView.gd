class_name GridCellView
extends Button

signal cell_pressed(grid_position: Vector2i)

var grid_position: Vector2i = Vector2i.ZERO
var occupant_id: StringName = &""
var occupant_label: String = ""
var is_selected: bool = false
var is_valid_target: bool = false
var is_focus_target: bool = false
var map_feature: Dictionary = {}
var feedback_tween: Tween
var focus_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(120, 96)
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressed.connect(_on_pressed)
	_refresh()


func configure(new_position: Vector2i) -> void:
	grid_position = new_position
	_refresh()


func set_occupant(new_occupant_id: StringName, new_label: String) -> void:
	occupant_id = new_occupant_id
	occupant_label = new_label
	_refresh()


func clear_occupant() -> void:
	occupant_id = &""
	occupant_label = ""
	_refresh()


func set_selected(value: bool) -> void:
	is_selected = value
	_refresh()


func set_valid_target(value: bool) -> void:
	is_valid_target = value
	_refresh()


func set_focus_target(value: bool) -> void:
	if is_focus_target == value:
		_refresh()
		return
	is_focus_target = value
	_refresh()
	_animate_focus_target(value)


func configure_map_feature(feature: Dictionary) -> void:
	map_feature = feature.duplicate(true)
	_refresh()


func play_feedback(color: Color) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()

	modulate = color
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_focus_target(active: bool) -> void:
	if focus_tween != null and focus_tween.is_valid():
		focus_tween.kill()

	pivot_offset = size * 0.5 if size != Vector2.ZERO else custom_minimum_size * 0.5
	z_index = 6 if active else 0
	if active:
		focus_tween = create_tween()
		focus_tween.set_loops()
		focus_tween.tween_property(self, "scale", Vector2(1.035, 1.035), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		focus_tween.tween_property(self, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		focus_tween = create_tween()
		focus_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	cell_pressed.emit(grid_position)


func _refresh() -> void:
	text = _get_cell_text()
	icon = null
	expand_icon = false
	tooltip_text = _get_tooltip_text()

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.02, 0.015, 0.012, 0.42)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true

	if is_selected:
		style.bg_color = Color(0.20, 0.33, 0.62, 0.74)
		style.border_color = Color(0.80, 0.92, 1.0)
	elif is_valid_target:
		style.bg_color = Color(0.13, 0.34, 0.23, 0.70)
		style.border_color = Color(0.58, 0.94, 0.64)
	elif occupant_id == &"player":
		style.bg_color = Color(0.11, 0.21, 0.36, 0.76)
		style.border_color = Color(0.48, 0.70, 1.0)
	elif not occupant_id.is_empty():
		style.bg_color = Color(0.38, 0.10, 0.08, 0.76)
		style.border_color = Color(0.94, 0.44, 0.42)
	elif not map_feature.is_empty():
		style.bg_color = _get_feature_color("color", Color(0.08, 0.065, 0.05, 0.44))
		style.bg_color.a = maxf(style.bg_color.a, 0.54)
		style.border_color = _get_feature_color("border_color", Color(0.52, 0.44, 0.26))
	else:
		style.bg_color = Color(0.08, 0.065, 0.05, 0.44)
		style.border_color = Color(0.34, 0.28, 0.18)

	if is_focus_target:
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(1.0, 0.82, 0.28)
		if occupant_id == &"player":
			style.bg_color = Color(0.18, 0.28, 0.48, 0.64)
		elif not occupant_id.is_empty():
			style.bg_color = Color(0.48, 0.16, 0.10, 0.66)
		elif is_valid_target:
			style.bg_color = Color(0.22, 0.44, 0.28, 0.58)

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_font_size_override("font_size", _get_font_size())
	add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.82))
	add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.86))
	add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.012, 0.86))
	add_theme_constant_override("outline_size", 2)


func _get_cell_text() -> String:
	var feature_short := _get_feature_short_label()
	var role_label := _get_feature_role_label()
	if not occupant_label.is_empty():
		if feature_short.is_empty():
			return occupant_label
		return "%s\n%s" % [occupant_label, feature_short]
	if is_valid_target:
		return "MOVE\n%s\n%s" % [feature_short, role_label] if not feature_short.is_empty() else "MOVE"
	if is_focus_target:
		return "FOCUS\n%s\n%s" % [feature_short, role_label] if not feature_short.is_empty() else "FOCUS"
	if not feature_short.is_empty():
		return "%s\n%s" % [feature_short, role_label]
	return ""


func _get_tooltip_text() -> String:
	var feature_text := _get_feature_tooltip_suffix()
	if occupant_id == &"player":
		return "You are here. Click a green MOVE space, then play a movement card.%s" % feature_text
	if not occupant_id.is_empty():
		return "Enemy target: %s. Click this space to target it.%s" % [occupant_label, feature_text]
	if is_focus_target:
		return "Active target: current MOVE destination.%s" % feature_text
	if is_valid_target:
		return "MOVE space. Movement and trap cards can use this destination.%s" % feature_text
	if not map_feature.is_empty():
		return _get_feature_tooltip_text()
	return "Empty arena space."


func _get_feature_short_label() -> String:
	return String(map_feature.get("short_label", ""))


func _get_feature_tooltip_suffix() -> String:
	if map_feature.is_empty():
		return ""
	return "\nMap: %s" % _get_feature_tooltip_text()


func _get_feature_tooltip_text() -> String:
	var label := String(map_feature.get("label", "Arena feature"))
	var note := String(map_feature.get("note", ""))
	var fps_text := _get_feature_fps_link_text()
	if note.is_empty():
		return "%s\nFPS link: %s" % [label, fps_text]
	return "%s - %s\nFPS link: %s" % [label, note, fps_text]


func _get_feature_color(key: String, fallback: Color) -> Color:
	var color_value: Variant = map_feature.get(key, fallback)
	if typeof(color_value) == TYPE_COLOR:
		return color_value
	return fallback


func _get_font_size() -> int:
	if not occupant_label.is_empty():
		return 14
	if is_valid_target or is_focus_target:
		return 13
	return 14


func _get_feature_role_label() -> String:
	match String(map_feature.get("type", "")):
		"objective":
			return "POT"
		"cover":
			return "COVER"
		"angle":
			return "ANGLE"
		"flank":
			return "FLANK"
		"choke":
			return "CHOKE"
		"spawn":
			return "SPAWN"
		_:
			var lane := String(map_feature.get("lane_name", ""))
			if lane.is_empty():
				return "LANE"
			return lane.to_upper().replace(" LANE", "")


func _get_feature_fps_link_text() -> String:
	match String(map_feature.get("type", "")):
		"objective":
			return "same center chip used by Hold Pot, Extract pickup, and payout scoring."
		"cover":
			return "exports safer defend/guard routes and damage mitigation into the arena."
		"angle":
			return "sets up weapon pressure, duel picks, and long sightline bonuses."
		"flank":
			return "feeds movement cards, trap routes, and extract rotations."
		"choke":
			return "marks where enemy pressure, boss gates, and snare control should matter."
		"spawn":
			return "anchors the player's FPS entry side and first card-loadout decision."
		_:
			return "keeps the card table and FPS arena using the same map callout."
