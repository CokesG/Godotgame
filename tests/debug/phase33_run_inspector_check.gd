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

	await _verify_initial_inspector(combat_scene)
	if failed:
		return
	await _verify_rewards_relics_and_history(combat_scene)
	if failed:
		return

	print("PHASE33_RUN_INSPECTOR_CHECK: PASS")
	get_tree().quit(0)


func _verify_initial_inspector(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var inspect_button: Button = combat_scene.find_child("ShellInspectRunButton", true, false)
	var inspector_panel: Node = combat_scene.find_child("RunInspectorPanel", true, false)
	var inspector: Node = combat_scene.find_child("RunInspector", true, false)
	var filters: Node = combat_scene.find_child("RunInspectorFilters", true, false)
	if start_button == null or inspect_button == null or inspector_panel == null or inspector == null or filters == null:
		_fail("Expected Inspect Run controls and inspector panel.")
		return
	if bool(inspect_button.get("visible")):
		_fail("Inspect Run should stay hidden on the first open-table screen.")
		return
	if bool(inspector_panel.get("visible")):
		_fail("Run inspector should start hidden.")
		return
	if bool(filters.get("visible")):
		_fail("Inspector filters should start hidden.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if not bool(inspect_button.get("visible")):
		_fail("Inspect Run should appear after the opening table starts.")
		return

	inspect_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	if not bool(inspector_panel.get("visible")):
		_fail("Inspect Run should reveal the inspector panel.")
		return
	if not bool(filters.get("visible")):
		_fail("Inspect Run should reveal deck filter controls.")
		return

	var text := _get_text(inspector)
	if not text.contains("Run/Deck Inspector") or not text.contains("Deck:") or not text.contains("Relics:"):
		_fail("Inspector should combine deck and relic inspection.")
		return
	if not text.contains("Deck cards (All):") or not text.contains("Recent rewards:") or not text.contains("Recent history:"):
		_fail("Inspector should include filtered deck cards, rewards, and run history sections.")


func _verify_rewards_relics_and_history(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var inspect_button: Button = combat_scene.find_child("ShellInspectRunButton", true, false)
	var inspector: Node = combat_scene.find_child("RunInspector", true, false)
	if run_manager == null or inspect_button == null or inspector == null:
		_fail("Expected RunManager, inspect button, and inspector.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame
	run_manager.call("claim_card_reward", 0)
	await get_tree().process_frame
	var export_path: String = String(run_manager.call("export_run_summary"))
	if export_path.is_empty() or not FileAccess.file_exists(export_path):
		_fail("Expected direct run summary export for inspector history.")
		return

	for _index in range(2):
		run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
		await get_tree().process_frame
		run_manager.call("skip_rewards")
		await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 22}})
	await get_tree().process_frame
	run_manager.call("claim_relic_reward", 0)
	await get_tree().process_frame

	inspect_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var text := _get_text(inspector)
	if not text.contains("Card reward") or not text.contains("Relic reward"):
		_fail("Inspector should show recent card and relic reward decisions. Text: %s" % text)
		return
	if not text.contains("Deck gaps:") or not text.contains("Tuning:"):
		_fail("Inspector should show tuning-oriented deck gaps and projected deck stats.")
		return
	if not text.contains("Recent history:") or not text.contains("running"):
		_fail("Inspector should show recent exported run history.")
		return

	var report: Dictionary = run_manager.call("get_run_inspection_report", 5)
	var deck: Dictionary = report.get("deck", {})
	var relics: Dictionary = report.get("relics", {})
	var rewards: Array = report.get("recent_rewards", [])
	var history_rows: Array = report.get("history_rows", [])
	if int(deck.get("size", 0)) <= 10:
		_fail("Inspection report should reflect the claimed card in deck size.")
		return
	if int(relics.get("count", 0)) < 1:
		_fail("Inspection report should reflect claimed relics.")
		return
	if rewards.size() < 3:
		_fail("Inspection report should retain recent reward decisions.")
		return
	if history_rows.is_empty():
		_fail("Inspection report should include recent exported history rows.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
