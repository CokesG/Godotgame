extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	await _verify_view_history_flow(combat_scene)
	if failed:
		return
	var managed_scene: Node = await _create_victory_and_defeat_exports(combat_scene, packed_scene)
	if failed:
		return
	await _verify_csv_and_archive_flow(managed_scene)
	if failed:
		return

	print("PHASE32_HISTORY_MANAGEMENT_CHECK: PASS")
	get_tree().quit(0)


func _verify_view_history_flow(combat_scene: Node) -> void:
	var view_history: Button = combat_scene.find_child("ShellViewHistoryButton", true, false)
	var csv_button: Button = combat_scene.find_child("ShellExportHistoryCsvButton", true, false)
	var archive_button: Button = combat_scene.find_child("ShellArchiveHistoryButton", true, false)
	var history_label: Node = combat_scene.find_child("RunHistoryComparison", true, false)
	if view_history == null or csv_button == null or archive_button == null or history_label == null:
		_fail("Expected history management controls and label.")
		return
	if not bool(view_history.get("visible")) or bool(csv_button.get("visible")) or bool(archive_button.get("visible")):
		_fail("Only View History should be visible before history is requested.")
		return

	view_history.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	if not bool(history_label.get("visible")):
		_fail("View History should reveal the history panel.")
		return
	if not bool(csv_button.get("visible")) or not bool(archive_button.get("visible")):
		_fail("History management actions should appear after View History.")
		return

	var history_text := _get_text(history_label)
	if not history_text.contains("Run History Comparison"):
		_fail("History panel should identify itself.")


func _create_victory_and_defeat_exports(combat_scene: Node, packed_scene: PackedScene) -> Node:
	await _drive_boss_victory(combat_scene)
	if failed:
		return combat_scene
	await _export_summary(combat_scene)
	if failed:
		return combat_scene

	var defeat_scene: Node = packed_scene.instantiate()
	add_child(defeat_scene)
	await get_tree().process_frame
	await _drive_opening_defeat(defeat_scene)
	if failed:
		return defeat_scene
	await _export_summary(defeat_scene)
	if failed:
		return defeat_scene

	var history_label: Node = defeat_scene.find_child("RunHistoryComparison", true, false)
	var history_text := _get_text(history_label)
	if not history_text.contains("Outcome shift") or not history_text.contains("Management:"):
		_fail("History should show management guidance and win/loss changes after exports.")
	return defeat_scene


func _verify_csv_and_archive_flow(combat_scene: Node) -> void:
	var csv_button: Button = combat_scene.find_child("ShellExportHistoryCsvButton", true, false)
	var archive_button: Button = combat_scene.find_child("ShellArchiveHistoryButton", true, false)
	var history_label: Node = combat_scene.find_child("RunHistoryComparison", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if csv_button == null or archive_button == null or history_label == null or run_manager == null:
		_fail("Expected CSV/archive controls, history label, and RunManager.")
		return

	if not bool(csv_button.get("visible")) or not bool(archive_button.get("visible")):
		_fail("CSV and archive buttons should be visible once history is active.")
		return

	csv_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var csv_path := String(combat_scene.get("last_history_csv_path"))
	if csv_path.is_empty() or not FileAccess.file_exists(csv_path):
		_fail("CSV export should produce a real file path.")
		return

	var csv_text := FileAccess.get_file_as_string(csv_path)
	if not csv_text.contains("file_name,result_key,outcome,grade") or not csv_text.contains("delta_label") or not csv_text.contains("route_text"):
		_fail("CSV export should include comparison headers.")
		return
	if not csv_text.contains("victory") or not csv_text.contains("defeat"):
		_fail("CSV export should include recent victory and defeat summaries.")
		return

	archive_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var archive_value: Variant = combat_scene.get("last_history_archive_report")
	if typeof(archive_value) != TYPE_DICTIONARY:
		_fail("Archive action should retain a report on the controller.")
		return
	var archive_report: Dictionary = Dictionary(archive_value)
	if not archive_report.has("kept_count") or not archive_report.has("archived_count"):
		_fail("Archive report should include kept and archived counts.")
		return
	if not _get_text(history_label).contains("Archive:"):
		_fail("History panel should report the archive action.")
		return

	var before_report: Dictionary = run_manager.call("get_run_history_comparison", 10)
	if int(before_report.get("count", 0)) < 2:
		_fail("Expected at least two summaries before direct archive verification.")
		return

	var direct_archive: Dictionary = run_manager.call("archive_old_run_summaries", 1)
	var direct_errors: Array = direct_archive.get("errors", [])
	if not direct_errors.is_empty():
		_fail("Direct archive should not report errors: %s" % str(direct_errors))
		return
	if int(direct_archive.get("kept_count", 0)) != 1 or int(direct_archive.get("archived_count", 0)) < 1:
		_fail("Direct archive should keep one recent summary and archive older ones.")
		return

	var after_report: Dictionary = run_manager.call("get_run_history_comparison", 10)
	if int(after_report.get("count", 0)) > 1:
		_fail("After keep-one archive, root history should contain one recent summary.")


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


func _drive_opening_defeat(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for defeat export.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame


func _export_summary(combat_scene: Node) -> void:
	var export_button: Button = combat_scene.find_child("ShellExportButton", true, false)
	if export_button == null or bool(export_button.get("disabled")):
		_fail("Expected enabled ShellExportButton.")
		return

	export_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var export_path := String(combat_scene.get("last_export_path"))
	if export_path.is_empty() or not FileAccess.file_exists(export_path):
		_fail("Expected run summary export path.")


func _get_text(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
