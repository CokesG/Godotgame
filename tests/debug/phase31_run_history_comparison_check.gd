extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var victory_scene: Node = packed_scene.instantiate()
	add_child(victory_scene)
	await get_tree().process_frame

	await _drive_boss_victory(victory_scene)
	if failed:
		return
	await _export_summary(victory_scene)
	if failed:
		return

	var defeat_scene: Node = packed_scene.instantiate()
	add_child(defeat_scene)
	await get_tree().process_frame

	await _drive_opening_defeat(defeat_scene)
	if failed:
		return
	await _export_summary(defeat_scene)
	if failed:
		return
	await _verify_history_comparison(defeat_scene)
	if failed:
		return

	print("PHASE31_RUN_HISTORY_COMPARISON_CHECK: PASS")
	get_tree().quit(0)


func _drive_boss_victory(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for victory history.")
		return

	for _index in range(4):
		run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
		await get_tree().process_frame
		run_manager.call("skip_rewards")
		await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 18}})
	await get_tree().process_frame

	var state: Dictionary = run_manager.call("get_state")
	if String(state.get("run_outcome", "")) != "victory":
		_fail("Expected boss victory before history export.")


func _drive_opening_defeat(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for defeat history.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var state: Dictionary = run_manager.call("get_state")
	if String(state.get("run_outcome", "")) != "defeat":
		_fail("Expected opening defeat before history export.")


func _export_summary(combat_scene: Node) -> void:
	var export_button: Button = combat_scene.find_child("ShellExportButton", true, false)
	if export_button == null or bool(export_button.get("disabled")):
		_fail("Expected enabled ShellExportButton for history export.")
		return

	export_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var export_path := String(combat_scene.get("last_export_path"))
	if export_path.is_empty() or not FileAccess.file_exists(export_path):
		_fail("Expected export path after pressing Export Summary.")


func _verify_history_comparison(combat_scene: Node) -> void:
	var history_label: Node = combat_scene.find_child("RunHistoryComparison", true, false)
	if history_label == null:
		_fail("Expected RunHistoryComparison label.")
		return
	if not bool(history_label.get("visible")):
		_fail("RunHistoryComparison should be visible after export.")
		return

	var history_text: String = _get_text(history_label)
	if not history_text.contains("Run History Comparison") or not history_text.contains("Rows loaded:"):
		_fail("History comparison should show a loaded-row heading.")
		return
	if not history_text.contains("Outcome shift") or not history_text.contains("victory") or not history_text.contains("defeat"):
		_fail("History comparison should highlight win/loss changes. Text: %s" % history_text)
		return
	if not history_text.contains("Tables") or not history_text.contains("Blood") or not history_text.contains("Dmg") or not history_text.contains("Deck"):
		_fail("History comparison rows should expose comparable run columns.")
		return

	var report_value: Variant = combat_scene.get("last_run_history_report")
	if typeof(report_value) != TYPE_DICTIONARY:
		_fail("Controller should retain the run history report.")
		return

	var report: Dictionary = Dictionary(report_value)
	if int(report.get("count", 0)) < 2:
		_fail("Run history report should load at least two exported summaries.")
		return
	if not bool(report.get("has_outcome_shift", false)):
		_fail("Run history report should flag the outcome shift.")
		return

	var rows: Array = report.get("rows", [])
	if not _has_key_prefix(rows, "victory_5of5") or not _has_key_prefix(rows, "defeat_0of5"):
		_fail("Run history should include the newly exported victory and defeat summaries.")
		return

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for direct history report.")
		return
	var direct_report: Dictionary = run_manager.call("get_run_history_comparison", 6)
	if int(direct_report.get("count", 0)) < 2 or not bool(direct_report.get("has_outcome_shift", false)):
		_fail("RunManager should provide comparable run history data directly.")


func _has_key_prefix(rows: Array, key_prefix: String) -> bool:
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_value)
		if String(row.get("result_key", "")).begins_with(key_prefix):
			return true
	return false


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
