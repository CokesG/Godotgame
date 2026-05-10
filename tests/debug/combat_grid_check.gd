extends SceneTree


func _initialize() -> void:
	var grid_script: Script = load("res://scripts/grid/CombatGrid.gd")
	var grid: Node = grid_script.new()
	var logs: Array[String] = []
	root.add_child(grid)

	grid.log_requested.connect(func(message: String) -> void:
		logs.append(message)
	)

	grid.reset_grid()

	if grid.get_unit_position(&"player") != Vector2i(1, 2):
		push_error("Player did not start at (1,2).")
		quit(1)
		return

	if grid.get_unit_position(&"enemy_1") != Vector2i(1, 0):
		push_error("Enemy did not start at (1,0).")
		quit(1)
		return

	grid.select_cell(Vector2i(1, 2))

	if not grid.move_selected_unit_to(Vector2i(1, 1)):
		push_error("Expected player to move from (1,2) to (1,1).")
		quit(1)
		return

	if grid.get_unit_position(&"player") != Vector2i(1, 1):
		push_error("Player position did not update after valid move.")
		quit(1)
		return

	if grid.move_selected_unit_to(Vector2i(1, 0)):
		push_error("Expected occupied enemy cell to reject movement.")
		quit(1)
		return

	if grid.move_selected_unit_to(Vector2i(2, 2)):
		push_error("Expected diagonal movement to be rejected.")
		quit(1)
		return

	if logs.size() < 4:
		push_error("Expected grid actions to emit log messages.")
		quit(1)
		return

	print("COMBAT_GRID_CHECK: PASS")
	root.remove_child(grid)
	grid.free()
	quit(0)
