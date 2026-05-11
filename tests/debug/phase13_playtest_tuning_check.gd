extends Node

var failed: bool = false


func _ready() -> void:
	_verify_five_playtest_runs()
	if failed:
		return
	_verify_reward_explanations_and_export()
	if failed:
		return
	_verify_tuned_values()
	if failed:
		return

	print("PHASE13_PLAYTEST_TUNING_CHECK: PASS")
	get_tree().quit(0)


func _verify_five_playtest_runs() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	var batch: Dictionary = run.call("get_playtest_batch")
	var runs: Array = batch.get("runs", [])
	if runs.size() != 5:
		_fail("Expected five strategy playtest runs.")
		return
	if int(batch.get("wins", 0)) < 3:
		_fail("At least three of five simulated runs should clear after tuning. %s Danger: %s" % [
			batch.get("summary", ""),
			str(batch.get("danger_nodes", []))
		])
		return
	if float(batch.get("average_ending_hp", 0.0)) <= 0.0:
		_fail("Average ending Blood should be positive.")
		return

	var strategies: Dictionary = {}
	for report in runs:
		if typeof(report) != TYPE_DICTIONARY:
			_fail("Playtest run report should be a Dictionary.")
			return
		strategies[String(report.get("strategy", ""))] = true
		var nodes: Array = report.get("nodes", [])
		if nodes.is_empty():
			_fail("Each playtest run should include per-node reports.")
			return

	for strategy in ["balanced", "aggressive", "defensive", "control", "greedy"]:
		if not strategies.has(strategy):
			_fail("Missing playtest strategy: %s." % strategy)
			return


func _verify_reward_explanations_and_export() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")
	run.call("mark_combat_victory", {"player": {"hp": 24}})

	var rewards: Array = run.call("get_reward_tuning_report")
	if rewards.size() != 3:
		_fail("Expected three scored rewards after combat.")
		return
	for reward in rewards:
		if String(reward.get("explanation", "")).is_empty():
			_fail("Reward should explain why it is recommended.")
			return
		if float(reward.get("score", 0.0)) <= 0.0:
			_fail("Reward score should be positive.")
			return

	var export_path: String = String(run.call("export_run_summary"))
	if export_path.is_empty():
		_fail("Expected run summary export path.")
		return
	if not FileAccess.file_exists(export_path):
		_fail("Exported run summary file should exist.")
		return

	var text := FileAccess.get_file_as_string(export_path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("Exported run summary should be JSON Dictionary.")
		return
	var playtest: Dictionary = parsed.get("playtest_batch", {})
	if int(playtest.get("runs_requested", 0)) != 5:
		_fail("Export should include five-run playtest batch.")
		return


func _verify_tuned_values() -> void:
	var sure_cut: Resource = load("res://resources/cards/sure_cut.tres")
	if not String(sure_cut.get("rules_text")).contains("6 damage"):
		_fail("Sure Cut should reflect tuned 6 damage text.")
		return

	var boss: Resource = load("res://resources/enemies/house_champion.tres")
	if int(boss.get("max_hp")) != 44:
		_fail("House Champion should be tuned to 44 HP.")
		return

	var royal_flush: Resource = load("res://resources/intents/champion_royal_flush.tres")
	var payload: Dictionary = royal_flush.get("payload")
	if int(payload.get("damage", 0)) != 8:
		_fail("Royal Flush should be tuned to 8 damage.")
		return


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
