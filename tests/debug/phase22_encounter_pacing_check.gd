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

	_verify_all_tables_have_identity()
	if failed:
		return
	_verify_start_preview(combat_scene)
	if failed:
		return
	await _verify_next_table_preview_and_modifier(combat_scene)
	if failed:
		return

	print("PHASE22_ENCOUNTER_PACING_CHECK: PASS")
	get_tree().quit(0)


func _verify_all_tables_have_identity() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	var modifier_names: Dictionary = {}
	for index in range(5):
		var state: Dictionary = run.call("get_state")
		var node_name: String = String(state.get("current_node_name", ""))
		var intro: String = String(state.get("encounter_intro", ""))
		var reward_stakes: String = String(state.get("reward_stakes", ""))
		var modifier: Dictionary = state.get("table_modifier", {})
		var modifier_name: String = String(modifier.get("name", ""))
		var reward_tags: Array = state.get("reward_tag_names", [])
		var enemy_names: Array = state.get("current_enemy_names", [])

		if node_name.is_empty() or intro.length() < 24:
			_fail("Every table should have a readable encounter intro.")
			return
		if modifier_name.is_empty() or modifier_names.has(modifier_name):
			_fail("Every table should have a unique table modifier name.")
			return
		modifier_names[modifier_name] = true
		if String(modifier.get("summary", "")).is_empty():
			_fail("%s should explain its table modifier." % node_name)
			return
		if reward_stakes.is_empty():
			_fail("%s should explain reward stakes." % node_name)
			return
		if enemy_names.is_empty():
			_fail("%s should preview its enemies." % node_name)
			return
		if index < 4 and reward_tags.is_empty():
			_fail("%s should expose reward tag names before the boss." % node_name)
			return

		if index < 4:
			run.call("mark_combat_victory", {"player": {"hp": 24}})
			var reward_state: Dictionary = run.call("get_state")
			if not reward_state.get("pending_card_rewards", []).is_empty():
				run.call("claim_card_reward", 0)
			reward_state = run.call("get_state")
			if not reward_state.get("pending_relic_rewards", []).is_empty():
				run.call("claim_relic_reward", 0)


func _verify_start_preview(combat_scene: Node) -> void:
	var preview: Node = combat_scene.find_child("EncounterPreview", true, false)
	if preview == null:
		_fail("Expected EncounterPreview.")
		return

	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Opening Table") or not preview_text.contains("Skulker") or not preview_text.contains("Shieldbearer"):
		_fail("Opening preview should name the table and enemies.")
		return
	if not preview_text.contains("Modifier: House Rules") or not preview_text.contains("Reward stakes:"):
		_fail("Opening preview should explain modifier and reward stakes.")
		return

	var resolver: Node = combat_scene.find_child("CombatResolver", true, false)
	if resolver == null:
		_fail("Expected CombatResolver.")
		return
	var player: Dictionary = Dictionary(resolver.call("get_state")).get("player", {})
	if int(player.get("guard", 0)) != 2:
		_fail("Opening table modifier should apply 2 starting Guard.")


func _verify_next_table_preview_and_modifier(combat_scene: Node) -> void:
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
		_fail("Expected a card reward before the next-table preview.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var preview: Node = combat_scene.find_child("EncounterPreview", true, false)
	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if preview == null or detail == null or next_encounter == null:
		_fail("Expected next-table preview controls.")
		return

	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Raised Stakes") or not preview_text.contains("Brute") or not preview_text.contains("Needle-Eye"):
		_fail("Next table preview should name Raised Stakes and its enemies.")
		return
	if not preview_text.contains("Modifier: High Ante") or not preview_text.contains("Attack"):
		_fail("Next table preview should show modifier and reward tags.")
		return
	if not _get_text(detail).contains("Table rule: High Ante"):
		_fail("Next table shell detail should call out the table rule.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		_fail("Expected CombatSession.")
		return
	if int(session.get("max_energy")) != 4 or int(session.get("energy")) != 4:
		_fail("High Ante should apply +1 Energy when the next table starts.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
