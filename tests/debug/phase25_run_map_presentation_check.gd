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

	_verify_start_map(combat_scene)
	if failed:
		return
	await _verify_reward_map(combat_scene)
	if failed:
		return
	await _verify_next_table_movement(combat_scene)
	if failed:
		return
	await _verify_defeat_map(combat_scene)
	if failed:
		return

	print("PHASE25_RUN_MAP_PRESENTATION_CHECK: PASS")
	get_tree().quit(0)


func _verify_start_map(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	if run_manager == null or run_path == null or continuity == null:
		_fail("Expected RunManager, RunPath, and RunContinuity.")
		return

	var state: Dictionary = run_manager.call("get_state")
	var path_entries: Array = state.get("run_path", [])
	if path_entries.size() != 5:
		_fail("RunManager should expose a five-table run path.")
		return

	var first_entry: Dictionary = Dictionary(path_entries[0])
	var second_entry: Dictionary = Dictionary(path_entries[1])
	if String(first_entry.get("status", "")) != "current":
		_fail("Opening Table should start as the current run-map stop.")
		return
	if String(second_entry.get("status", "")) != "upcoming":
		_fail("Raised Stakes should start as an upcoming run-map stop.")
		return

	var path_text: String = _get_text(run_path)
	if not path_text.contains("Route 1/5") or not path_text.contains("Deal In now"):
		_fail("RunPath should give a focused Deal In prompt.")
		return
	if path_text.contains("Selected Table") or path_text.contains("[UPCOMING] 2. Raised Stakes"):
		_fail("RunPath should keep detailed route selection hidden before the first deal-in.")
		return
	var continuity_text := _get_text(continuity)
	if not continuity_text.contains("Blood") or not continuity_text.contains("First fight is ready"):
		_fail("RunContinuity should frame the start state as a focused first fight.")


func _verify_reward_map(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if start_button == null or run_manager == null:
		_fail("Expected StartRunButton and RunManager.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	if run_path == null or continuity == null:
		_fail("Expected RunPath and RunContinuity after victory.")
		return

	var path_text: String = _get_text(run_path)
	if not path_text.contains("[REWARD] 1. Opening Table") or not path_text.contains("[NEXT] 2. Raised Stakes"):
		_fail("Reward flow should mark the cleared table for rewards and preview the next table.")
		return
	if not path_text.contains("1/5 cleared") or not path_text.contains("marked NEXT"):
		_fail("Reward map should show one cleared table and a next marker.")
		return
	if not _get_text(continuity).contains("Raised Stakes") or not _get_text(continuity).contains("marked NEXT"):
		_fail("Reward continuity should name and mark the next table.")


func _verify_next_table_movement(combat_scene: Node) -> void:
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or bool(card_reward.get("disabled")):
		_fail("Expected selectable first card reward before moving the map marker.")
		return

	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	if run_path == null or continuity == null or next_encounter == null or title == null:
		_fail("Expected run-map, continuity, next encounter, and shell title controls.")
		return

	var path_text: String = _get_text(run_path)
	if not path_text.contains("[CLEARED] 1. Opening Table") or not path_text.contains("[CURRENT] 2. Raised Stakes"):
		_fail("Taking a reward should move the current marker to Raised Stakes.")
		return
	if _get_text(title) != "Next Table":
		_fail("Reward clear should land on the Next Table shell.")
		return
	if not _get_text(continuity).contains("marker has moved to Raised Stakes"):
		_fail("Continuity should explain that the route marker moved.")
		return
	if not bool(next_encounter.get("visible")) or bool(next_encounter.get("disabled")):
		_fail("NextEncounterButton should be ready after reward movement.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	var combat_feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if combat_feedback == null or not _get_text(combat_feedback).contains("Run map: moving to Table 2/5 - Raised Stakes"):
		_fail("Dealing the next table should give a map movement feedback beat.")
		return
	if _get_text(title) != "Current Table":
		_fail("Dealing the next table should return to the live combat shell.")


func _verify_defeat_map(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var continuity: Node = combat_scene.find_child("RunContinuity", true, false)
	if run_path == null or continuity == null:
		_fail("Expected RunPath and RunContinuity after defeat.")
		return

	var path_text: String = _get_text(run_path)
	if not path_text.contains("[CLEARED] 1. Opening Table") or not path_text.contains("[LOST] 2. Raised Stakes"):
		_fail("Defeat should preserve cleared tables and mark the lost table.")
		return
	if not path_text.contains("[UPCOMING] 3. Cursed Pair"):
		_fail("Defeat should leave later tables visible as upcoming.")
		return
	if not _get_text(continuity).contains("Final result"):
		_fail("Defeat continuity should still summarize the final result.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
