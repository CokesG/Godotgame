class_name GridCellView
extends Button

signal cell_pressed(grid_position: Vector2i)

var grid_position: Vector2i = Vector2i.ZERO
var occupant_id: StringName = &""
var occupant_label: String = ""
var is_selected: bool = false
var is_valid_target: bool = false
var is_focus_target: bool = false
var feedback_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(116, 116)
	focus_mode = Control.FOCUS_NONE
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
	is_focus_target = value
	_refresh()


func play_feedback(color: Color) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()

	modulate = color
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	cell_pressed.emit(grid_position)


func _refresh() -> void:
	text = _get_cell_text()
	if is_focus_target:
		tooltip_text = "Active target - cell %d,%d" % [grid_position.x, grid_position.y]
	else:
		tooltip_text = "Cell %d,%d" % [grid_position.x, grid_position.y]

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if is_selected:
		style.bg_color = Color(0.36, 0.48, 0.72)
		style.border_color = Color(0.84, 0.92, 1.0)
	elif is_valid_target:
		style.bg_color = Color(0.20, 0.40, 0.30)
		style.border_color = Color(0.58, 0.90, 0.64)
	elif occupant_id == &"player":
		style.bg_color = Color(0.16, 0.24, 0.36)
		style.border_color = Color(0.48, 0.66, 0.95)
	elif not occupant_id.is_empty():
		style.bg_color = Color(0.36, 0.13, 0.12)
		style.border_color = Color(0.90, 0.48, 0.48)
	else:
		style.bg_color = Color(0.10, 0.085, 0.07)
		style.border_color = Color(0.34, 0.28, 0.18)

	if is_focus_target:
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(1.0, 0.82, 0.28)
		if occupant_id == &"player":
			style.bg_color = Color(0.22, 0.30, 0.45)
		elif not occupant_id.is_empty():
			style.bg_color = Color(0.45, 0.18, 0.12)
		elif is_valid_target:
			style.bg_color = Color(0.25, 0.46, 0.30)

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.82))


func _get_cell_text() -> String:
	var coord_text := "%d,%d" % [grid_position.x, grid_position.y]
	if not occupant_label.is_empty():
		return "%s\n%s" % [occupant_label, coord_text]
	return coord_text
