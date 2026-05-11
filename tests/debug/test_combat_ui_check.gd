extends Node


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	var guidance := combat_scene.find_child("TurnGuidance", true, false)
	if guidance == null:
		_fail("Expected TurnGuidance panel.")
		return

	var recipe_panel := combat_scene.find_child("RecipePanel", true, false)
	if recipe_panel == null:
		_fail("Expected RecipePanel.")
		return

	var run_panel := combat_scene.find_child("RunPanel", true, false)
	if run_panel == null:
		_fail("Expected RunPanel for the Phase 11 prototype path.")
		return

	var balance_report := combat_scene.find_child("BalanceReport", true, false)
	if balance_report == null:
		_fail("Expected BalanceReport for Phase 12 tuning.")
		return

	var run_results := combat_scene.find_child("RunResults", true, false)
	if run_results == null:
		_fail("Expected RunResults for Phase 12 outcomes.")
		return

	var playtest_report := combat_scene.find_child("PlaytestReport", true, false)
	if playtest_report == null:
		_fail("Expected PlaytestReport for Phase 13 run comparisons.")
		return

	var run_playtests_button := combat_scene.find_child("RunPlaytestsButton", true, false)
	if run_playtests_button == null:
		_fail("Expected RunPlaytestsButton for Phase 13 simulation.")
		return

	var export_summary_button := combat_scene.find_child("ExportSummaryButton", true, false)
	if export_summary_button == null:
		_fail("Expected ExportSummaryButton for Phase 13 run exports.")
		return

	var target_enemy_option := combat_scene.find_child("TargetEnemyOption", true, false)
	if target_enemy_option == null:
		_fail("Expected TargetEnemyOption.")
		return

	var movement_cell_option := combat_scene.find_child("MovementCellOption", true, false)
	if movement_cell_option == null:
		_fail("Expected MovementCellOption.")
		return

	var continue_button := combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return

	if String(continue_button.get("text")) == "Next Phase":
		_fail("ContinueButton should use playable wording, not raw debug wording.")
		return

	var debug_controls := combat_scene.find_child("DebugControls", true, false)
	if debug_controls == null:
		_fail("Expected DebugControls container.")
		return

	if bool(debug_controls.get("visible")):
		_fail("DebugControls should start hidden.")
		return

	var debug_truth := combat_scene.find_child("DebugTruth", true, false)
	if debug_truth == null:
		_fail("Expected DebugTruth panel.")
		return

	if bool(debug_truth.get("visible")):
		_fail("DebugTruth should start hidden.")
		return

	print("TEST_COMBAT_UI_CHECK: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
