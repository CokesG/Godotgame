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

	_verify_default_layout_order(combat_scene)
	if failed:
		return
	await _verify_live_play_path(combat_scene)
	if failed:
		return
	await _verify_debug_and_reward_separation(combat_scene)
	if failed:
		return

	print("PHASE35_DEFAULT_PLAY_LAYOUT_CHECK: PASS")
	get_tree().quit(0)


func _verify_default_layout_order(combat_scene: Node) -> void:
	var layout: Node = combat_scene.find_child("Layout", true, false)
	var run_shell: Node = combat_scene.find_child("RunShellPanel", true, false)
	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var table_row: Node = combat_scene.find_child("TableRow", true, false)
	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var debug_drawer: Node = combat_scene.find_child("DebugDrawer", true, false)
	var log_column: Node = combat_scene.find_child("LogColumn", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if layout == null or run_shell == null or combat_body == null or table_row == null or deck_panel == null:
		_fail("Expected core play layout nodes.")
		return
	if run_panel == null or debug_drawer == null or log_column == null:
		_fail("Expected secondary/debug layout nodes.")
		return
	if start_button == null or continue_button == null:
		_fail("Expected shell and smart action controls.")
		return

	if _child_index(layout, run_shell) > _child_index(layout, combat_body):
		_fail("Run shell should sit before the play area.")
		return
	if deck_panel.get_parent() != combat_body:
		_fail("Hand/deck panel should live inside the combat body play area.")
		return
	if _child_index(combat_body, table_row) > _child_index(combat_body, deck_panel):
		_fail("Board/intent table row should sit before the hand/deck strip.")
		return
	if _child_index(layout, combat_body) > _child_index(layout, run_panel):
		_fail("Combat body should sit before tuning/reward panels.")
		return
	if _child_index(layout, run_panel) > _child_index(layout, debug_drawer):
		_fail("Run panel should sit before the debug drawer.")
		return

	if not bool(combat_body.get("visible")) or not bool(deck_panel.get("visible")):
		_fail("Board and hand should be visible in the default play path.")
		return
	if bool(run_panel.get("visible")) or bool(debug_drawer.get("visible")) or bool(log_column.get("visible")):
		_fail("Run tuning, debug drawer, and log column should start hidden.")
		return
	if not bool(start_button.get("visible")) or bool(start_button.get("disabled")):
		_fail("Open Opening Table should be the single enabled first action.")
		return
	if bool(continue_button.get("visible")) or not bool(continue_button.get("disabled")):
		_fail("Smart ContinueButton should not compete with the opening-table action.")


func _verify_live_play_path(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var enemy_status: Node = combat_scene.find_child("EnemyStatus", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var log_column: Node = combat_scene.find_child("LogColumn", true, false)
	if start_button == null or continue_button == null or combat_body == null or deck_panel == null:
		_fail("Expected live play path controls.")
		return
	if enemy_status == null or hand_view == null or run_panel == null or log_column == null:
		_fail("Expected enemy, hand, run, and log nodes.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if bool(start_button.get("visible")):
		_fail("Opening action should hide after the table opens.")
		return
	if not bool(continue_button.get("visible")) or bool(continue_button.get("disabled")):
		_fail("Smart action should become the live combat action.")
		return
	if String(continue_button.get("text")) != "Resolve Turn":
		_fail("Opening the table should deal straight into card play.")
		return
	if not bool(combat_body.get("visible")) or not bool(deck_panel.get("visible")):
		_fail("Combat body and hand should remain visible after opening the table.")
		return
	if not _get_text(enemy_status).contains("Threat"):
		_fail("Enemy state should stay in the default play area.")
		return
	if hand_view.get_child_count() <= 0:
		_fail("Hand cards should be visible in the default play area.")
		return
	if bool(run_panel.get("visible")) or bool(log_column.get("visible")):
		_fail("Tuning panel and combat log should remain out of the default live play path.")


func _verify_debug_and_reward_separation(combat_scene: Node) -> void:
	var toggle: Button = combat_scene.find_child("ToggleDebugButton", true, false)
	var debug_drawer: Node = combat_scene.find_child("DebugDrawer", true, false)
	var log_column: Node = combat_scene.find_child("LogColumn", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var run_state: Node = combat_scene.find_child("RunState", true, false)
	var balance_report: Node = combat_scene.find_child("BalanceReport", true, false)
	var playtest_report: Node = combat_scene.find_child("PlaytestReport", true, false)
	if toggle == null or debug_drawer == null or log_column == null or run_panel == null:
		_fail("Expected debug separation controls.")
		return
	if run_state == null or balance_report == null or playtest_report == null:
		_fail("Expected tuning panels.")
		return

	toggle.emit_signal("pressed")
	await get_tree().process_frame
	if not bool(debug_drawer.get("visible")) or not bool(log_column.get("visible")):
		_fail("Debug toggle should reveal the debug drawer and combat log column.")
		return
	if not bool(run_panel.get("visible")) or not bool(run_state.get("visible")):
		_fail("Debug toggle should reveal run tuning details.")
		return
	if not bool(balance_report.get("visible")) or not bool(playtest_report.get("visible")):
		_fail("Debug toggle should reveal balance and playtest panels.")
		return

	toggle.emit_signal("pressed")
	await get_tree().process_frame
	if bool(debug_drawer.get("visible")) or bool(log_column.get("visible")):
		_fail("Closing debug should hide the debug drawer and combat log again.")
		return

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return
	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var reward_prompt: Node = combat_scene.find_child("RewardPrompt", true, false)
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if reward_prompt == null or card_reward == null or continue_button == null:
		_fail("Expected reward and action controls.")
		return
	if not bool(run_panel.get("visible")) or not bool(reward_prompt.get("visible")):
		_fail("Run panel should return when the player has a reward decision.")
		return
	if not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Reward card should be selectable when the reward panel opens.")
		return
	if bool(continue_button.get("visible")):
		_fail("Smart action should not compete with the reward choice.")


func _child_index(parent: Node, child: Node) -> int:
	for index in range(parent.get_child_count()):
		if parent.get_child(index) == child:
			return index
	return 999


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
