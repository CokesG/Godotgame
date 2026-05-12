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

	await _verify_reward_screen_polish(combat_scene)
	if failed:
		return
	await _verify_skip_flow_keeps_deck_lean(combat_scene)
	if failed:
		return

	print("PHASE24_REWARD_SCREEN_POLISH_CHECK: PASS")
	get_tree().quit(0)


func _verify_reward_screen_polish(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var reward_prompt: Node = combat_scene.find_child("RewardPrompt", true, false)
	var reward_impact: Node = combat_scene.find_child("RewardImpact", true, false)
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	var skip_button: Button = combat_scene.find_child("SkipRewardsButton", true, false)
	if reward_prompt == null or reward_impact == null or card_reward == null or skip_button == null:
		_fail("Expected reward prompt, impact, card reward, and skip controls.")
		return

	if not bool(reward_prompt.get("visible")) or not bool(reward_impact.get("visible")):
		_fail("Reward prompt and impact panel should be visible during reward flow.")
		return

	var prompt_text: String = _get_text(reward_prompt)
	if not prompt_text.contains("deck gap") or not prompt_text.contains("Deck impact:"):
		_fail("RewardPrompt should explain deck gap and deck impact.")
		return

	var impact_text: String = _get_text(reward_impact)
	if not impact_text.contains("Before/after deck impact") or not impact_text.contains("Best pick:"):
		_fail("RewardImpact should show before/after and best-pick details.")
		return
	if not impact_text.contains("Impact: Deck") or not impact_text.contains("Reasons:"):
		_fail("RewardImpact should show impact and recommendation reasons.")
		return

	var button_text: String = String(card_reward.get("text"))
	if not button_text.contains("#1 Recommended") or not button_text.contains("Take "):
		_fail("Best card button should read like a take action and highlight the recommendation.")
		return
	if not button_text.contains("Reasons:") or not button_text.contains("Impact: Deck"):
		_fail("Best card button should include recommendation reasons and deck impact.")
		return

	if String(skip_button.get("text")) != "Skip Reward - keep deck lean":
		_fail("Skip button should explain the tradeoff.")


func _verify_skip_flow_keeps_deck_lean(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var skip_button: Button = combat_scene.find_child("SkipRewardsButton", true, false)
	if run_manager == null or skip_button == null:
		_fail("Expected RunManager and SkipRewardsButton.")
		return

	var before_state: Dictionary = run_manager.call("get_state")
	var before_deck_size: int = int(before_state.get("deck_size", 0))
	if bool(skip_button.get("disabled")):
		_fail("Skip should be available during reward flow.")
		return

	skip_button.emit_signal("pressed")
	await get_tree().process_frame

	var after_state: Dictionary = run_manager.call("get_state")
	if int(after_state.get("deck_size", -1)) != before_deck_size:
		_fail("Skipping rewards should keep the deck size unchanged.")
		return
	if int(after_state.get("current_node_index", -1)) != 1:
		_fail("Skipping rewards should still advance to the next table.")
		return

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	if title == null or _get_text(title) != "Next Table":
		_fail("Skipping rewards should land on the Next Table screen.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
