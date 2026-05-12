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
	await _verify_export_readback(victory_scene, "victory", "Tables 5/5", "victory_5of5", "5:CLEARED")
	if failed:
		return

	var defeat_scene: Node = packed_scene.instantiate()
	add_child(defeat_scene)
	await get_tree().process_frame

	await _drive_opening_defeat(defeat_scene)
	if failed:
		return
	await _verify_export_readback(defeat_scene, "defeat", "Tables 0/5", "defeat_0of5", "1:LOST")
	if failed:
		return

	print("PHASE30_EXPORT_READBACK_CHECK: PASS")
	get_tree().quit(0)


func _drive_boss_victory(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for victory export.")
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
		_fail("Expected boss victory before export readback.")


func _drive_opening_defeat(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for defeat export.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var state: Dictionary = run_manager.call("get_state")
	if String(state.get("run_outcome", "")) != "defeat":
		_fail("Expected opening defeat before export readback.")


func _verify_export_readback(combat_scene: Node, expected_outcome: String, expected_tables_text: String, expected_key_prefix: String, expected_route_marker: String) -> void:
	var export_button: Button = combat_scene.find_child("ShellExportButton", true, false)
	var readback_label: Node = combat_scene.find_child("RunExportReadback", true, false)
	if export_button == null or readback_label == null:
		_fail("Expected export action and readback label.")
		return
	if bool(export_button.get("disabled")):
		_fail("Export Summary should be enabled on results.")
		return

	export_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	if not bool(readback_label.get("visible")):
		_fail("RunExportReadback should become visible after export.")
		return

	var label_text: String = _get_text(readback_label)
	if not label_text.contains("Export Readback") or not label_text.contains("Compare:"):
		_fail("Readback label should show a comparison summary.")
		return
	if not label_text.contains(expected_tables_text) or not label_text.contains("Key: %s" % expected_key_prefix):
		_fail("Readback label should include table count and stable key. Text: %s" % label_text)
		return
	if not label_text.contains(expected_route_marker):
		_fail("Readback label should include compact route status. Text: %s" % label_text)
		return

	var export_path: String = String(combat_scene.get("last_export_path"))
	if export_path.is_empty() or not FileAccess.file_exists(export_path):
		_fail("Controller should retain a real export path.")
		return

	var readback_value: Variant = combat_scene.get("last_export_readback")
	if typeof(readback_value) != TYPE_DICTIONARY or not bool(Dictionary(readback_value).get("ok", false)):
		_fail("Controller should retain a successful readback dictionary.")
		return

	var data := _read_json_dictionary(export_path)
	if data.is_empty():
		return

	if int(data.get("export_version", 0)) < 2:
		_fail("Export should include the phase 30 export_version.")
		return

	var comparison: Dictionary = data.get("comparison_summary", {})
	var compare_columns: Dictionary = comparison.get("compare_columns", {})
	var result_key: String = String(comparison.get("result_key", ""))
	if not result_key.begins_with(expected_key_prefix):
		_fail("Comparison result key should start with %s, got %s." % [expected_key_prefix, result_key])
		return
	if String(compare_columns.get("outcome", "")) != expected_outcome:
		_fail("Comparison columns should preserve outcome %s." % expected_outcome)
		return

	var route_summary: Array = data.get("route_summary", [])
	if route_summary.size() != 5:
		_fail("Export route summary should include all five tables.")
		return
	if not _route_summary_contains(route_summary, expected_route_marker):
		_fail("Export route summary should include %s." % expected_route_marker)


func _read_json_dictionary(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("Exported summary should parse as a JSON Dictionary.")
		return {}
	return Dictionary(parsed)


func _route_summary_contains(route_summary: Array, expected_marker: String) -> bool:
	for entry_value in route_summary:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_value)
		var marker := "%d:%s" % [
			int(entry.get("table_number", 0)),
			String(entry.get("status_label", "UPCOMING"))
		]
		if marker == expected_marker:
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
