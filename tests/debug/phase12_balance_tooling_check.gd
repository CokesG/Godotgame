extends Node

var failed: bool = false


func _ready() -> void:
	_verify_simulator_snapshot()
	if failed:
		return
	_verify_reward_tuning_and_results()
	if failed:
		return

	print("PHASE12_BALANCE_TOOLING_CHECK: PASS")
	get_tree().quit(0)


func _verify_simulator_snapshot() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	var simulator = load("res://scripts/run/RunBalanceSimulator.gd").new()
	var evaluation: Dictionary = simulator.call(
		"evaluate_encounter",
		run.call("get_deck_paths"),
		run.call("get_current_enemy_paths"),
		run.call("get_relic_modifiers"),
		run.call("get_player_hp")
	)
	var deck: Dictionary = evaluation.get("deck", {})
	var encounter: Dictionary = evaluation.get("encounter", {})
	if float(deck.get("projected_damage_per_turn", 0.0)) <= 0.0:
		_fail("Expected starter deck to have positive projected damage.")
		return
	if float(encounter.get("expected_damage_per_turn", 0.0)) <= 0.0:
		_fail("Expected opening encounter to have positive threat.")
		return
	if int(evaluation.get("projected_turns", 0)) < 1:
		_fail("Expected projected turns to be at least one.")
		return
	if not ["favorable", "close", "danger"].has(String(evaluation.get("rating", ""))):
		_fail("Encounter rating should be a known balance band.")
		return

	var snapshot: Dictionary = run.call("get_balance_snapshot")
	var fast_run: Dictionary = snapshot.get("fast_run", {})
	if int(fast_run.get("total_nodes", 0)) != 5:
		_fail("Fast run preview should evaluate all five nodes.")
		return
	if int(fast_run.get("predicted_clears", -1)) < 1:
		_fail("Fast run preview should predict at least one clear for the starter slice.")
		return


func _verify_reward_tuning_and_results() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	for expected_index in range(3):
		run.call("mark_combat_victory", {"player": {"hp": 24 - expected_index * 2}})
		var reward_report: Array = run.call("get_reward_tuning_report")
		if reward_report.size() != 3:
			_fail("Expected three scored card rewards after normal combat.")
			return
		if not _scores_descending(reward_report):
			_fail("Card rewards should be sorted by tuning score.")
			return
		run.call("claim_card_reward", 0)

	run.call("mark_combat_victory", {"player": {"hp": 18}})
	var state: Dictionary = run.call("get_state")
	if int(state.get("pending_relic_rewards", []).size()) != 2:
		_fail("Elite should produce two relic reward options.")
		return

	run.call("claim_card_reward", 0)
	run.call("claim_relic_reward", 0)
	state = run.call("get_state")
	if String(state.get("current_node_kind", "")) != "boss":
		_fail("Expected boss node after elite rewards.")
		return

	run.call("mark_combat_victory", {"player": {"hp": 12}})
	var results: Dictionary = run.call("get_run_results")
	if String(results.get("outcome", "")) != "victory":
		_fail("Boss victory should produce victory results.")
		return
	if int(results.get("combats_won", 0)) != 5:
		_fail("Run results should count all five won combats.")
		return
	if int(results.get("cards_claimed", 0)) != 4:
		_fail("Run results should count claimed card rewards.")
		return
	if int(results.get("relics_claimed", 0)) != 1:
		_fail("Run results should count claimed relic rewards.")
		return
	if String(results.get("title", "")).is_empty() or String(results.get("grade", "")).is_empty():
		_fail("Run results should include a title and grade.")
		return


func _scores_descending(rewards: Array) -> bool:
	var previous := 9999.0
	for reward in rewards:
		if typeof(reward) != TYPE_DICTIONARY:
			return false
		var score := float(reward.get("score", -999.0))
		if score > previous:
			return false
		previous = score
	return true


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
