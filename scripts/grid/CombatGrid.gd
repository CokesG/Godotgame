class_name CombatGrid
extends Control

signal log_requested(message: String)
signal unit_moved(unit_id: StringName, from_cell: Vector2i, to_cell: Vector2i)
signal cell_selected(cell: Vector2i)

const GRID_CELL_VIEW_SCRIPT := preload("res://scripts/grid/GridCellView.gd")
const PLAYER_ID := &"player"
const PLAYER_LABEL := "Gambler-Knight"
const DEFAULT_ENEMY_SPAWNS := [
	{
		"id": &"skulker",
		"cell": Vector2i(0, 0),
		"label": "Skulker"
	},
	{
		"id": &"brute",
		"cell": Vector2i(1, 0),
		"label": "Brute"
	},
	{
		"id": &"shieldbearer",
		"cell": Vector2i(2, 0),
		"label": "Shieldbearer"
	}
]

@export var grid_size: Vector2i = Vector2i(3, 3)

var grid_container: GridContainer
var status_label: Label
var cells_by_position: Dictionary = {}
var occupants_by_cell: Dictionary = {}
var unit_positions: Dictionary = {}
var unit_labels: Dictionary = {}
var selected_unit_id: StringName = &""
var valid_move_cells: Array[Vector2i] = []
var floating_text_layer: Control


func _ready() -> void:
	_build_ui()
	reset_grid()


func reset_grid(enemy_spawns: Array = []) -> void:
	occupants_by_cell.clear()
	unit_positions.clear()
	unit_labels.clear()
	selected_unit_id = &""
	valid_move_cells.clear()

	place_unit(PLAYER_ID, Vector2i(1, 2), PLAYER_LABEL)
	var spawns: Array = DEFAULT_ENEMY_SPAWNS if enemy_spawns.is_empty() else enemy_spawns
	for spawn in spawns:
		if typeof(spawn) != TYPE_DICTIONARY:
			continue
		place_unit(
			StringName(spawn.get("id", &"")),
			spawn.get("cell", Vector2i(-1, -1)),
			String(spawn.get("label", "Enemy"))
		)
	_refresh_cells()
	_update_status("Select the Gambler-Knight, then choose an adjacent green cell.")
	log_requested.emit("Grid reset: player at (1,2), enemies on the top row.")


func place_unit(unit_id: StringName, cell: Vector2i, display_label: String) -> bool:
	if not is_cell_in_bounds(cell):
		log_requested.emit("Cannot place %s outside the grid at %s." % [display_label, format_cell(cell)])
		return false

	if is_cell_occupied(cell):
		log_requested.emit("Cannot place %s at %s because the cell is occupied." % [display_label, format_cell(cell)])
		return false

	occupants_by_cell[cell] = unit_id
	unit_positions[unit_id] = cell
	unit_labels[unit_id] = display_label
	return true


func select_cell(cell: Vector2i) -> void:
	if not is_cell_in_bounds(cell):
		log_requested.emit("Cannot select %s because it is outside the grid." % format_cell(cell))
		return

	cell_selected.emit(cell)
	var occupant_id := get_occupant_at(cell)

	if selected_unit_id.is_empty():
		if occupant_id == PLAYER_ID:
			_select_unit(PLAYER_ID)
			return

		if _is_enemy_unit(occupant_id):
			log_requested.emit("%s is not controllable in this prototype." % get_unit_label(occupant_id))
			return

		log_requested.emit("No unit at %s. Select the Gambler-Knight first." % format_cell(cell))
		return

	if cell == get_unit_position(selected_unit_id):
		_clear_selection()
		log_requested.emit("Selection cleared.")
		return

	if occupant_id == PLAYER_ID:
		_select_unit(PLAYER_ID)
		return

	if not move_selected_unit_to(cell):
		_refresh_cells()


func move_selected_unit_to(destination: Vector2i) -> bool:
	if selected_unit_id.is_empty():
		log_requested.emit("No selected unit. Select the Gambler-Knight first.")
		return false

	return move_unit(selected_unit_id, destination)


func move_unit(unit_id: StringName, destination: Vector2i) -> bool:
	if not unit_positions.has(unit_id):
		log_requested.emit("Cannot move unknown unit '%s'." % String(unit_id))
		return false

	var origin := get_unit_position(unit_id)
	var unit_label := String(unit_labels.get(unit_id, String(unit_id)))

	if not is_cell_in_bounds(destination):
		log_requested.emit("%s cannot move to %s because it is outside the grid." % [unit_label, format_cell(destination)])
		return false

	if is_cell_occupied(destination):
		log_requested.emit("%s cannot move to %s because %s occupies it." % [
			unit_label,
			format_cell(destination),
			get_unit_label(get_occupant_at(destination))
		])
		return false

	if not is_adjacent(origin, destination):
		log_requested.emit("%s cannot move from %s to %s. Phase 2 movement is one orthogonal cell." % [
			unit_label,
			format_cell(origin),
			format_cell(destination)
		])
		return false

	occupants_by_cell.erase(origin)
	occupants_by_cell[destination] = unit_id
	unit_positions[unit_id] = destination
	unit_moved.emit(unit_id, origin, destination)
	log_requested.emit("%s moved from %s to %s." % [unit_label, format_cell(origin), format_cell(destination)])
	_select_unit(unit_id)
	return true


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func is_cell_occupied(cell: Vector2i) -> bool:
	return occupants_by_cell.has(cell)


func get_occupant_at(cell: Vector2i) -> StringName:
	return occupants_by_cell.get(cell, &"")


func get_unit_position(unit_id: StringName) -> Vector2i:
	return unit_positions.get(unit_id, Vector2i(-1, -1))


func get_unit_label(unit_id: StringName) -> String:
	return String(unit_labels.get(unit_id, String(unit_id)))


func get_unit_lane(unit_id: StringName) -> int:
	var position := get_unit_position(unit_id)
	if not is_cell_in_bounds(position):
		return -1
	return position.x


func get_player_context() -> Dictionary:
	var player_cell := get_unit_position(PLAYER_ID)
	return {
		"cell": player_cell,
		"lane": player_cell.x if is_cell_in_bounds(player_cell) else -1
	}


func get_unit_position_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for unit_id in unit_positions.keys():
		var unit_id_name: StringName = StringName(unit_id)
		var position: Vector2i = unit_positions[unit_id_name]
		snapshot[unit_id_name] = {
			"cell": position,
			"lane": position.x,
			"label": get_unit_label(unit_id_name)
		}
	return snapshot


func is_adjacent(origin: Vector2i, destination: Vector2i) -> bool:
	var delta := destination - origin
	return abs(delta.x) + abs(delta.y) == 1


func get_valid_moves_for(unit_id: StringName) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	if not unit_positions.has(unit_id):
		return moves

	var origin := get_unit_position(unit_id)
	var offsets := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for offset in offsets:
		var candidate: Vector2i = origin + offset
		if is_cell_in_bounds(candidate) and not is_cell_occupied(candidate):
			moves.append(candidate)

	return moves


func get_empty_adjacent_cells_for(unit_id: StringName) -> Array[Vector2i]:
	return get_valid_moves_for(unit_id)


func format_cell(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x, cell.y]


func flash_unit(unit_id: StringName, color: Color) -> void:
	if not unit_positions.has(unit_id):
		return
	flash_cell(unit_positions[unit_id], color)


func flash_cell(cell: Vector2i, color: Color) -> void:
	if not cells_by_position.has(cell):
		return

	var cell_view: Button = cells_by_position[cell]
	if cell_view.has_method("play_feedback"):
		cell_view.call("play_feedback", color)


func show_floating_text_for_unit(unit_id: StringName, message: String, color: Color) -> void:
	if not unit_positions.has(unit_id):
		return
	show_floating_text_at_cell(unit_positions[unit_id], message, color)


func show_floating_text_at_cell(cell: Vector2i, message: String, color: Color) -> void:
	if not cells_by_position.has(cell) or message.is_empty():
		return

	var cell_view: Button = cells_by_position[cell]
	var label := Label.new()
	label.name = "FloatingCombatTextLabel"
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	label.modulate = color
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02))
	label.add_theme_constant_override("outline_size", 4)
	var layer := _get_floating_text_layer()
	layer.add_child(label)

	var start_position: Vector2 = cell_view.get_global_rect().get_center() - get_global_rect().position + Vector2(-34, -28)
	label.position = start_position
	var end_color := Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -30), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate", end_color, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var frame := VBoxContainer.new()
	frame.name = "GridFrame"
	frame.add_theme_constant_override("separation", 8)
	add_child(frame)

	var title := Label.new()
	title.name = "TableTitle"
	title.text = "The Table"
	title.add_theme_font_size_override("font_size", 18)
	frame.add_child(title)

	grid_container = GridContainer.new()
	grid_container.name = "Cells"
	grid_container.columns = grid_size.x
	grid_container.add_theme_constant_override("h_separation", 8)
	grid_container.add_theme_constant_override("v_separation", 8)
	frame.add_child(grid_container)

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Button.new()
			cell.set_script(GRID_CELL_VIEW_SCRIPT)
			var grid_position := Vector2i(x, y)
			cell.call("configure", grid_position)
			cell.connect("cell_pressed", _on_cell_pressed)
			cells_by_position[grid_position] = cell
			grid_container.add_child(cell)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(380, 0)
	frame.add_child(status_label)

	_get_floating_text_layer()


func _get_floating_text_layer() -> Control:
	if floating_text_layer != null and is_instance_valid(floating_text_layer):
		return floating_text_layer

	floating_text_layer = Control.new()
	floating_text_layer.name = "FloatingCombatText"
	floating_text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_text_layer.z_index = 30
	add_child(floating_text_layer)
	return floating_text_layer


func _select_unit(unit_id: StringName) -> void:
	selected_unit_id = unit_id
	valid_move_cells = get_valid_moves_for(unit_id)
	_refresh_cells()
	_update_status("%s selected. Valid moves are highlighted green." % get_unit_label(unit_id))
	log_requested.emit("%s selected at %s." % [get_unit_label(unit_id), format_cell(get_unit_position(unit_id))])


func _clear_selection() -> void:
	selected_unit_id = &""
	valid_move_cells.clear()
	_refresh_cells()
	_update_status("Select the Gambler-Knight, then choose an adjacent green cell.")


func _refresh_cells() -> void:
	for cell_position in cells_by_position.keys():
		var cell: Button = cells_by_position[cell_position]
		var occupant_id := get_occupant_at(cell_position)
		if occupant_id.is_empty():
			cell.call("clear_occupant")
		else:
			cell.call("set_occupant", occupant_id, _get_short_label(occupant_id))

		cell.call("set_selected", not selected_unit_id.is_empty() and cell_position == get_unit_position(selected_unit_id))
		cell.call("set_valid_target", valid_move_cells.has(cell_position))


func _get_short_label(unit_id: StringName) -> String:
	if unit_id == PLAYER_ID:
		return "GK"
	return String(unit_id).substr(0, 2).to_upper()


func _is_enemy_unit(unit_id: StringName) -> bool:
	return not unit_id.is_empty() and unit_id != PLAYER_ID


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = message


func _on_cell_pressed(cell: Vector2i) -> void:
	select_cell(cell)
