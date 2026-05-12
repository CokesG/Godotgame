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

	_verify_initial_interactive_map(combat_scene)
	if failed:
		return
	await _verify_selected_table_preview(combat_scene)
	if failed:
		return
	await _verify_marker_movement_preview(combat_scene)
	if failed:
		return

	print("PHASE26_INTERACTIVE_RUN_MAP_CHECK: PASS")
	get_tree().quit(0)


func _verify_initial_interactive_map(combat_scene: Node) -> void:
	var preview: Node = combat_scene.find_child("RunPathPreview", true, false)
	var table_0: Button = combat_scene.find_child("RunPathTable0", true, false)
	var table_1: Button = combat_scene.find_child("RunPathTable1", true, false)
	if preview == null or table_0 == null or table_1 == null:
		_fail("Expected interactive run-map preview and table buttons.")
		return

	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Selected Table 1: Opening Table") or not preview_text.contains("House Rules"):
		_fail("Initial preview should select Opening Table and show its table rule.")
		return
	if not preview_text.contains("Enemies: Skulker, Shieldbearer"):
		_fail("Initial preview should show Opening Table enemies.")
		return

	var first_text: String = String(table_0.get("text"))
	var second_text: String = String(table_1.get("text"))
	if not first_text.contains("CURRENT") or not first_text.contains(">>"):
		_fail("Current table button should be strongly highlighted.")
		return
	if not second_text.contains("UPCOMING"):
		_fail("Upcoming table button should show its status.")


func _verify_selected_table_preview(combat_scene: Node) -> void:
	var preview: Node = combat_scene.find_child("RunPathPreview", true, false)
	var elite_button: Button = combat_scene.find_child("RunPathTable3", true, false)
	if preview == null or elite_button == null:
		_fail("Expected preview and elite table button.")
		return

	elite_button.emit_signal("pressed")
	await get_tree().process_frame

	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Selected Table 4: Elite: Grave Dealer"):
		_fail("Clicking a map table should update the selected-table preview.")
		return
	if not preview_text.contains("Marked Deal") or not preview_text.contains("offers a relic"):
		_fail("Selected-table preview should show rule and reward stakes.")
		return
	if not String(elite_button.get("text")).contains("*"):
		_fail("Selected non-current table should show selected emphasis.")


func _verify_marker_movement_preview(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if start_button == null or run_manager == null:
		_fail("Expected StartRunButton and RunManager.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or bool(card_reward.get("disabled")):
		_fail("Expected selectable card reward.")
		return

	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var preview: Node = combat_scene.find_child("RunPathPreview", true, false)
	var table_1: Button = combat_scene.find_child("RunPathTable1", true, false)
	var combat_feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if preview == null or table_1 == null or combat_feedback == null:
		_fail("Expected preview, second table button, and feedback feed after movement.")
		return

	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Selected Table 2: Raised Stakes") or not preview_text.contains("Last route move: Opening Table -> Raised Stakes."):
		_fail("Reward resolution should auto-select the new current table and show the route move.")
		return
	if not String(table_1.get("text")).contains("CURRENT") or not String(table_1.get("text")).contains(">>"):
		_fail("New current table should have strong current emphasis.")
		return
	if not _get_text(combat_feedback).contains("Run map: rewards clear. Marker moves to Table 2/5 - Raised Stakes."):
		_fail("Reward resolution should keep a movement feedback beat.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
