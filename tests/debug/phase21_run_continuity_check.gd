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

	_verify_start_continuity(combat_scene)
	if failed:
		return
	await _verify_reward_to_next_table_flow(combat_scene)
	if failed:
		return
	await _verify_results_continuity(combat_scene)
	if failed:
		return

	print("PHASE21_RUN_CONTINUITY_CHECK: PASS")
	get_tree().quit(0)


func _verify_start_continuity(combat_scene: Node) -> void:
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	if continuity == null:
		_fail("Expected RunContinuity.")
		return
	if not _get_text(continuity).contains("Opening Table"):
		_fail("RunContinuity should name the opening table before the run starts.")
		return

	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null:
		_fail("Expected NextEncounterButton.")
		return
	if bool(next_encounter.get("visible")):
		_fail("NextEncounterButton should start hidden.")


func _verify_reward_to_next_table_flow(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if start_button == null or run_manager == null:
		_fail("Expected StartRunButton and RunManager.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if title == null or detail == null or continuity == null or continue_button == null:
		_fail("Expected run shell labels and ContinueButton.")
		return

	if _get_text(title) != "Post-Combat Reward":
		_fail("Victory should move into the reward screen.")
		return
	if not _get_text(continuity).contains("Raised Stakes"):
		_fail("Reward continuity should preview the next table name.")
		return
	if String(continue_button.get("text")) != "Choose Reward" or not bool(continue_button.get("disabled")):
		_fail("ContinueButton should not bypass reward choice.")
		return

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Expected the first card reward to be selectable.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	if _get_text(title) != "Next Table":
		_fail("Reward clear should move into a Next Table screen.")
		return
	if not _get_text(detail).contains("Up next: Raised Stakes"):
		_fail("Next Table detail should preview the upcoming encounter.")
		return
	if not _get_text(continuity).contains("Open Next Table"):
		_fail("RunContinuity should explain how to continue the same run.")
		return

	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null or not bool(next_encounter.get("visible")) or bool(next_encounter.get("disabled")):
		_fail("NextEncounterButton should be visible and enabled on the Next Table screen.")
		return
	if String(continue_button.get("text")) != "Open Next Table" or not bool(continue_button.get("disabled")):
		_fail("ContinueButton should label but not duplicate the next-table shell action.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	if _get_text(title) != "Current Table":
		_fail("Open Next Table should return to live combat shell.")
		return
	if not _get_text(detail).contains("Table 2/5 is live"):
		_fail("The second table should be live after dealing the next table.")
		return
	if bool(next_encounter.get("visible")):
		_fail("NextEncounterButton should hide once combat resumes.")
		return
	if _get_phase_key(combat_scene) != "START_TURN":
		_fail("Next encounter should reset combat to Start Turn.")
		return


func _verify_results_continuity(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	if title == null or continuity == null:
		_fail("Expected results shell labels.")
		return
	if _get_text(title) != "Run Lost":
		_fail("Defeat should move into the results screen.")
		return
	if not _get_text(continuity).contains("Final result"):
		_fail("Results continuity should summarize the final outcome.")
		return

	var new_run: Button = combat_scene.find_child("ShellNewRunButton", true, false)
	var export: Button = combat_scene.find_child("ShellExportButton", true, false)
	if new_run == null or export == null:
		_fail("Expected results action buttons.")
		return
	if not bool(new_run.get("visible")) or not bool(export.get("visible")):
		_fail("Results screen should expose New Run and Export Summary.")


func _get_phase_key(combat_scene: Node) -> String:
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		return ""
	return String(session.get("current_phase_key"))


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
