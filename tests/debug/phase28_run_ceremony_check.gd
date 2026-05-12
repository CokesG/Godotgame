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

	await _verify_victory_to_reward_ceremony(combat_scene)
	if failed:
		return
	await _verify_reward_to_approach_ceremony(combat_scene)
	if failed:
		return
	await _verify_approach_to_combat_ceremony(combat_scene)
	if failed:
		return

	print("PHASE28_RUN_CEREMONY_CHECK: PASS")
	get_tree().quit(0)


func _verify_victory_to_reward_ceremony(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if start_button == null or run_manager == null:
		_fail("Expected StartRunButton and RunManager.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	combat_scene.call("_record_run_ceremony", "Victory: Opening Table cleared. Reward choice opens the route forward.")
	await get_tree().process_frame

	var ceremony_panel: Node = combat_scene.find_child("RunCeremonyPanel", true, false)
	var ceremony: Node = combat_scene.find_child("RunCeremony", true, false)
	if ceremony_panel == null or ceremony == null:
		_fail("Expected RunCeremony panel and text.")
		return
	if not bool(ceremony_panel.get("visible")):
		_fail("RunCeremony should be visible on the reward ceremony step.")
		return

	var ceremony_text: String = _get_text(ceremony)
	if not ceremony_text.contains("Run Ceremony") or not ceremony_text.contains("[DONE] Victory"):
		_fail("Reward ceremony should show the shared ceremony track.")
		return
	if not ceremony_text.contains("[ACTIVE] Reward") or not ceremony_text.contains("Opening Table cleared"):
		_fail("Reward ceremony should make victory-to-reward feel continuous.")


func _verify_reward_to_approach_ceremony(combat_scene: Node) -> void:
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or bool(card_reward.get("disabled")):
		_fail("Expected selectable card reward.")
		return

	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var ceremony: Node = combat_scene.find_child("RunCeremony", true, false)
	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var approach_title: Node = combat_scene.find_child("ApproachTitle", true, false)
	if ceremony == null or title == null or approach_title == null:
		_fail("Expected ceremony, shell title, and approach title after reward.")
		return

	var ceremony_text: String = _get_text(ceremony)
	if _get_text(title) != "Next Table":
		_fail("Reward should still land on the next-table approach shell.")
		return
	if not ceremony_text.contains("[DONE] Reward") or not ceremony_text.contains("[DONE] Map Move") or not ceremony_text.contains("[ACTIVE] Approach"):
		_fail("Reward-to-approach ceremony should advance through reward and map movement.")
		return
	if not ceremony_text.contains("Map: marker moves to Table 2/5 - Raised Stakes") or not ceremony_text.contains("Reward: card added"):
		_fail("Ceremony thread should preserve reward and map movement events.")
		return
	if not _get_text(approach_title).contains("Approach Table 2/5: Raised Stakes"):
		_fail("Approach preview should be staged after map movement.")


func _verify_approach_to_combat_ceremony(combat_scene: Node) -> void:
	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null or bool(next_encounter.get("disabled")):
		_fail("Expected enabled NextEncounterButton.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	var ceremony: Node = combat_scene.find_child("RunCeremony", true, false)
	var ceremony_panel: Node = combat_scene.find_child("RunCeremonyPanel", true, false)
	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var approach_panel: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	if ceremony == null or ceremony_panel == null or title == null or approach_panel == null:
		_fail("Expected ceremony, shell title, and approach panel after dealing table.")
		return

	var ceremony_text: String = _get_text(ceremony)
	if _get_text(title) != "Current Table":
		_fail("Dealing the next table should enter live combat.")
		return
	if bool(approach_panel.get("visible")):
		_fail("Approach panel should hide once the ceremony hands back to combat.")
		return
	if not bool(ceremony_panel.get("visible")):
		_fail("Ceremony panel should stay visible briefly as combat begins.")
		return
	if not ceremony_text.contains("[ACTIVE] Combat") or not ceremony_text.contains("Approach: Raised Stakes dealt into combat"):
		_fail("Approach-to-combat ceremony should preserve the final handoff beat.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
