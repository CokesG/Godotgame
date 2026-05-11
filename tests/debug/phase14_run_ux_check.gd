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

	_verify_player_facing_header(combat_scene)
	if failed:
		return
	_verify_intent_threat_summary(combat_scene)
	if failed:
		return
	await _verify_reward_prompt(combat_scene)
	if failed:
		return

	print("PHASE14_RUN_UX_CHECK: PASS")
	get_tree().quit(0)


func _verify_player_facing_header(combat_scene: Node) -> void:
	var title: Node = combat_scene.find_child("ScreenTitle", true, false)
	if title == null:
		_fail("Expected named ScreenTitle.")
		return
	if _get_text(title).contains("Harness"):
		_fail("ScreenTitle should use player-facing run wording.")
		return

	var subtitle: Node = combat_scene.find_child("ScreenSubtitle", true, false)
	if subtitle == null:
		_fail("Expected named ScreenSubtitle.")
		return
	if _get_text(subtitle).contains("Phase 10"):
		_fail("ScreenSubtitle should not show stale phase implementation copy.")
		return

	var run_header: Node = combat_scene.find_child("RunHeader", true, false)
	if run_header == null:
		_fail("Expected RunHeader.")
		return
	var header_text := _get_text(run_header)
	if not header_text.contains("Table 1/5") or not header_text.contains("Blood"):
		_fail("RunHeader should show table progress and Blood.")
		return

	var action_prompt: Node = combat_scene.find_child("ActionPrompt", true, false)
	if action_prompt == null:
		_fail("Expected ActionPrompt.")
		return
	if not _get_text(action_prompt).contains("Next:"):
		_fail("ActionPrompt should name the next useful action.")
		return


func _verify_intent_threat_summary(combat_scene: Node) -> void:
	var threat_summary: Node = combat_scene.find_child("ThreatSummary", true, false)
	if threat_summary == null:
		_fail("Expected ThreatSummary.")
		return
	var threat_text := _get_text(threat_summary)
	if not threat_text.contains("Threat:") or not threat_text.contains("Response:"):
		_fail("ThreatSummary should show the highest threat and response.")
		return

	var intent_preview: Node = combat_scene.find_child("IntentPreview", true, false)
	if intent_preview == null:
		_fail("Expected IntentPreview.")
		return
	if not _get_text(intent_preview).contains("Top threat:"):
		_fail("IntentPreview should mark each enemy's top threat.")
		return


func _verify_reward_prompt(combat_scene: Node) -> void:
	var reward_prompt: Node = combat_scene.find_child("RewardPrompt", true, false)
	if reward_prompt == null:
		_fail("Expected RewardPrompt.")
		return
	if bool(reward_prompt.get("visible")):
		_fail("RewardPrompt should start hidden before rewards are pending.")
		return

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return
	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	if not bool(reward_prompt.get("visible")):
		_fail("RewardPrompt should become visible when rewards are pending.")
		return
	var prompt_text := _get_text(reward_prompt)
	if not prompt_text.contains("Best card:") or not prompt_text.contains("deck gap"):
		_fail("RewardPrompt should explain the best card and deck gap context.")
		return


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
