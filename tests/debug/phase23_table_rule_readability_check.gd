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

	_verify_opening_rule_readability(combat_scene)
	if failed:
		return
	await _verify_next_table_rule_trigger(combat_scene)
	if failed:
		return

	print("PHASE23_TABLE_RULE_READABILITY_CHECK: PASS")
	get_tree().quit(0)


func _verify_opening_rule_readability(combat_scene: Node) -> void:
	var table_rule_status: Node = combat_scene.find_child("TableRuleStatus", true, false)
	if table_rule_status == null:
		_fail("Expected TableRuleStatus.")
		return

	var rule_text: String = _get_text(table_rule_status)
	if not rule_text.contains("Table Rule: House Rules"):
		_fail("Opening table rule should stay visible in the play area.")
		return
	if not rule_text.contains("2 opening Guard"):
		_fail("Opening table rule should explain its active Guard effect.")
		return
	if not rule_text.contains("Triggered: Table Rule: House Rules grants 2 opening Guard."):
		_fail("Opening table rule should show that its Guard effect triggered.")
		return

	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if feedback == null or not _get_text(feedback).contains("Table Rule: House Rules grants 2 opening Guard."):
		_fail("CombatFeedback should show the opening table rule trigger.")
		return

	var resolver: Node = combat_scene.find_child("CombatResolver", true, false)
	if resolver == null:
		_fail("Expected CombatResolver.")
		return
	var player: Dictionary = Dictionary(resolver.call("get_state")).get("player", {})
	if int(player.get("guard", 0)) != 2:
		_fail("House Rules should still apply 2 opening Guard.")


func _verify_next_table_rule_trigger(combat_scene: Node) -> void:
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
		_fail("Expected a card reward to reach the next table.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null or bool(next_encounter.get("disabled")):
		_fail("Expected NextEncounterButton.")
		return
	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	var table_rule_status: Node = combat_scene.find_child("TableRuleStatus", true, false)
	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	var banner: Node = combat_scene.find_child("FeedbackBanner", true, false)
	if table_rule_status == null or feedback == null or banner == null:
		_fail("Expected table rule and feedback nodes.")
		return

	var rule_text: String = _get_text(table_rule_status)
	if not rule_text.contains("Table Rule: High Ante"):
		_fail("High Ante should stay visible once Raised Stakes starts.")
		return
	if not rule_text.contains("+1 max Energy -> 4"):
		_fail("High Ante should explain the active Energy effect.")
		return
	if not rule_text.contains("Triggered: Table Rule: High Ante +1 max Energy; cap is 4."):
		_fail("High Ante should show its Energy trigger.")
		return

	var feedback_text: String = _get_text(feedback)
	if not feedback_text.contains("Table Rule: High Ante +1 max Energy; cap is 4."):
		_fail("CombatFeedback should show the High Ante trigger.")
		return
	if not _get_text(banner).contains("High Ante"):
		_fail("FeedbackBanner should call out the active table rule trigger.")
		return

	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		_fail("Expected CombatSession.")
		return
	if int(session.get("max_energy")) != 4 or int(session.get("energy")) != 4:
		_fail("High Ante should still apply +1 Energy.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
