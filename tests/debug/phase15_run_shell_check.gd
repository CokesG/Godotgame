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

	_verify_start_shell(combat_scene)
	if failed:
		return
	await _verify_combat_reward_and_results_shell(combat_scene)
	if failed:
		return

	print("PHASE15_RUN_SHELL_CHECK: PASS")
	get_tree().quit(0)


func _verify_start_shell(combat_scene: Node) -> void:
	var run_shell: Node = combat_scene.find_child("RunShellPanel", true, false)
	if run_shell == null:
		_fail("Expected RunShellPanel.")
		return

	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if start_button == null:
		_fail("Expected StartRunButton.")
		return
	if not bool(start_button.get("visible")) or bool(start_button.get("disabled")):
		_fail("StartRunButton should be visible and enabled before the run begins.")
		return

	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return
	if not bool(continue_button.get("disabled")):
		_fail("ContinueButton should be blocked by the start shell.")
		return

	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	if detail == null:
		_fail("Expected RunShellDetail.")
		return
	if not _get_text(detail).contains("five-table"):
		_fail("RunShellDetail should describe the five-table run start.")
		return


func _verify_combat_reward_and_results_shell(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	start_button.emit_signal("pressed")
	await get_tree().process_frame

	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if bool(start_button.get("visible")):
		_fail("StartRunButton should hide once combat flow begins.")
		return
	if bool(continue_button.get("disabled")):
		_fail("ContinueButton should unlock after Start Run.")
		return
	if not _get_text(detail).contains("Table 1/5 is live"):
		_fail("RunShellDetail should show the live first table.")
		return

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return
	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	if _get_text(title) != "Post-Combat Reward":
		_fail("RunShellTitle should switch to reward flow after combat victory.")
		return
	if not _get_text(detail).contains("Choose"):
		_fail("RunShellDetail should prompt reward choice after victory.")
		return

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("First card reward should be available in reward flow.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	if _get_text(title) != "Next Table":
		_fail("RunShellTitle should switch to a next-table screen after rewards clear.")
		return
	if not _get_text(detail).contains("Raised Stakes"):
		_fail("RunShellDetail should preview the next table after reward claim.")
		return

	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null or not bool(next_encounter.get("visible")) or bool(next_encounter.get("disabled")):
		_fail("NextEncounterButton should become available after rewards clear.")
		return
	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	if not _get_text(detail).contains("Table 2/5 is live"):
		_fail("RunShellDetail should advance to the next table after Deal Next Table.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var shell_new_run: Button = combat_scene.find_child("ShellNewRunButton", true, false)
	var shell_export: Button = combat_scene.find_child("ShellExportButton", true, false)
	if shell_new_run == null or shell_export == null:
		_fail("Results shell should expose New Run and Export Summary buttons.")
		return
	if not bool(shell_new_run.get("visible")) or not bool(shell_export.get("visible")):
		_fail("Results shell actions should become visible after run end.")
		return
	if not _get_text(detail).contains("Won"):
		_fail("Results shell should summarize run performance.")
		return


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
