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

	await _verify_focused_first_screen(combat_scene)
	if failed:
		return
	await _verify_reward_decision_and_deck_filter(combat_scene)
	if failed:
		return

	print("PHASE34_DECK_REWARD_DECISION_CHECK: PASS")
	get_tree().quit(0)


func _verify_focused_first_screen(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var run_path_buttons: Node = combat_scene.find_child("RunPathButtons", true, false)
	var run_path_preview: Node = combat_scene.find_child("RunPathPreview", true, false)
	var shell_detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var inspect_button: Button = combat_scene.find_child("ShellInspectRunButton", true, false)
	var history_button: Button = combat_scene.find_child("ShellViewHistoryButton", true, false)
	var encounter_preview: Node = combat_scene.find_child("EncounterPreview", true, false)
	var approach_panel: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	if start_button == null or run_path == null or run_path_buttons == null or run_path_preview == null:
		_fail("Expected first-screen route controls.")
		return
	if shell_detail == null or inspect_button == null or history_button == null:
		_fail("Expected focused first-screen shell controls.")
		return
	if encounter_preview == null or approach_panel == null:
		_fail("Expected encounter preview/approach nodes.")
		return

	if not bool(start_button.get("visible")) or bool(start_button.get("disabled")):
		_fail("Open Opening Table should be the visible first action.")
		return
	if String(start_button.get("text")) != "Open Opening Table":
		_fail("Start button should use open-table language.")
		return

	var path_text := _get_text(run_path)
	if not path_text.contains("Opening Table ready") or not path_text.contains("Press Open Opening Table"):
		_fail("First map copy should be short and action-focused.")
		return
	if path_text.contains("Selected Table") or path_text.contains("Raised Stakes"):
		_fail("First map copy should not dump future table details.")
		return
	if bool(run_path_buttons.get("visible")) or bool(run_path_preview.get("visible")):
		_fail("Interactive route details should wait until the first table opens.")
		return
	if not _get_text(shell_detail).contains("Open Opening Table"):
		_fail("Shell detail should point at the only required first action.")
		return
	if bool(inspect_button.get("visible")) or bool(history_button.get("visible")):
		_fail("Inspector/history tools should not compete with the first action.")
		return
	if bool(encounter_preview.get("visible")) or bool(approach_panel.get("visible")):
		_fail("Opening preview panels should stay hidden until the table opens.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if bool(start_button.get("visible")):
		_fail("Open Opening Table should hide after combat begins.")
		return
	if not bool(run_path_buttons.get("visible")) or not bool(run_path_preview.get("visible")):
		_fail("Detailed map controls should appear after the first table opens.")
		return
	if not bool(inspect_button.get("visible")) or not bool(history_button.get("visible")):
		_fail("Inspector/history tools should appear after the first table opens.")
		return
	if bool(encounter_preview.get("visible")) or bool(approach_panel.get("visible")):
		_fail("Live combat should hide report-style encounter panels from the default play surface.")


func _verify_reward_decision_and_deck_filter(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var inspect_button: Button = combat_scene.find_child("ShellInspectRunButton", true, false)
	var filters: Node = combat_scene.find_child("RunInspectorFilters", true, false)
	var attack_filter: Button = combat_scene.find_child("RunInspectorFilterAttack", true, false)
	var inspector: Node = combat_scene.find_child("RunInspector", true, false)
	var reward_impact: Node = combat_scene.find_child("RewardImpact", true, false)
	if run_manager == null or inspect_button == null or filters == null or attack_filter == null:
		_fail("Expected RunManager, inspector controls, and filter buttons.")
		return
	if inspector == null or reward_impact == null:
		_fail("Expected inspector and reward impact panels.")
		return

	inspect_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	if not bool(filters.get("visible")):
		_fail("Inspect Run should reveal deck filters.")
		return
	var inspector_text := _get_text(inspector)
	if not inspector_text.contains("Deck cards (All):") or not inspector_text.contains("Recent rewards:"):
		_fail("Inspector should show deck card rows and reward decisions.")
		return

	attack_filter.emit_signal("pressed")
	await get_tree().process_frame
	inspector_text = _get_text(inspector)
	if not inspector_text.contains("Deck cards (Attack):"):
		_fail("Attack filter should refresh the inspector card list.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or bool(card_reward.get("disabled")):
		_fail("Expected first card reward after victory.")
		return
	var reward_text := String(card_reward.get("text"))
	if not reward_text.contains("#1 Recommended") or not card_reward.tooltip_text.contains("Reasons:") or not card_reward.tooltip_text.contains("Impact:"):
		_fail("Reward cards should keep recommendation and before/after impact available without bloating the button.")
		return
	if not bool(reward_impact.get("visible")) or not _get_text(reward_impact).contains("Before/after deck impact"):
		_fail("Reward impact panel should show before/after deck data before picking.")
		return

	card_reward.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame

	var state: Dictionary = run_manager.call("get_state")
	var decision: Dictionary = state.get("last_reward_decision", {})
	if decision.is_empty():
		_fail("Run state should retain the last reward decision.")
		return
	if int(decision.get("before_deck_size", 0)) != 10 or int(decision.get("after_deck_size", 0)) != 11:
		_fail("Last reward decision should retain before/after deck size.")
		return
	if not String(decision.get("deck_change", "")).contains("Deck 10 -> 11"):
		_fail("Last reward decision should summarize the deck change.")
		return

	var post_pick_impact := _get_text(reward_impact)
	if not bool(reward_impact.get("visible")) or not post_pick_impact.contains("Last reward change"):
		_fail("Reward impact panel should keep the taken reward visible after picking.")
		return
	if not post_pick_impact.contains("Before:") or not post_pick_impact.contains("After:"):
		_fail("Taken reward impact should show before and after deck snapshots.")
		return

	inspector_text = _get_text(inspector)
	if not inspector_text.contains("Deck: 11 cards") or not inspector_text.contains("Deck 10 -> 11"):
		_fail("Inspector should refresh after card addition with updated deck and recent reward.")


func _get_text(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
