class_name GridCellView
extends Button

signal cell_pressed(grid_position: Vector2i)

var grid_position: Vector2i = Vector2i.ZERO
var occupant_id: StringName = &""
var occupant_label: String = ""
var is_selected: bool = false
var is_valid_target: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(104, 104)
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


func _on_pressed() -> void:
	cell_pressed.emit(grid_position)


func _refresh() -> void:
	text = _get_cell_text()
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
		style.bg_color = Color(0.18, 0.25, 0.38)
		style.border_color = Color(0.48, 0.66, 0.95)
	elif not occupant_id.is_empty():
		style.bg_color = Color(0.38, 0.18, 0.18)
		style.border_color = Color(0.90, 0.48, 0.48)
	else:
		style.bg_color = Color(0.12, 0.12, 0.15)
		style.border_color = Color(0.35, 0.35, 0.40)

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_font_size_override("font_size", 18)


func _get_cell_text() -> String:
	var coord_text := "%d,%d" % [grid_position.x, grid_position.y]
	if not occupant_label.is_empty():
		return "%s\n%s" % [occupant_label, coord_text]
	return coord_text
