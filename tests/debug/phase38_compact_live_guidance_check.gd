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

	_verify_opening_chips(combat_scene)
	if failed:
		return
	await _verify_live_compact_mode(combat_scene)
	if failed:
		return
	await _verify_commit_chips(combat_scene)
	if failed:
		return
	await _verify_debug_restores_detail(combat_scene)
	if failed:
		return

	print("PHASE38_COMPACT_LIVE_GUIDANCE_CHECK: PASS")
	get_tree().quit(0)


func _verify_opening_chips(combat_scene: Node) -> void:
	var chip_row: Node = combat_scene.find_child("LiveStateChips", true, false)
	var step_row: Node = combat_scene.find_child("FirstPlayStepButtons", true, false)
	var open_step: Button = combat_scene.find_child("FirstPlayStepOpen", true, false)
	var rule_chip: Button = combat_scene.find_child("RuleStateChip", true, false)
	if chip_row == null or step_row == null or open_step == null or rule_chip == null:
		_fail("Expected compact state chips and first-play step buttons.")
		return
	if not bool(chip_row.get("visible")) or not bool(step_row.get("visible")):
		_fail("Compact chips and step buttons should be visible from the opening screen.")
		return
	if not open_step.tooltip_text.contains("Active step"):
		_fail("Opening step button should identify the active first action.")
		return
	if not String(rule_chip.get("text")).contains("RULE"):
		_fail("Rule chip should summarize the table rule compactly.")


func _verify_live_compact_mode(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if start_button == null:
		_fail("Expected StartRunButton.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	var chip_row: Node = combat_scene.find_child("LiveStateChips", true, false)
	var phase_chip: Button = combat_scene.find_child("PhaseStateChip", true, false)
	var energy_chip: Button = combat_scene.find_child("EnergyStateChip", true, false)
	var threat_chip: Button = combat_scene.find_child("ThreatStateChip", true, false)
	var action_prompt: Node = combat_scene.find_child("ActionPrompt", true, false)
	var first_play_path: Node = combat_scene.find_child("FirstPlayPath", true, false)
	var turn_status: Node = combat_scene.find_child("TurnStatus", true, false)
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	var feedback_feed: Node = combat_scene.find_child("CombatFeedback", true, false)
	if chip_row == null or phase_chip == null or energy_chip == null or threat_chip == null:
		_fail("Expected compact chip controls after opening.")
		return
	if action_prompt == null or first_play_path == null or turn_status == null or card_hint == null or feedback_feed == null:
		_fail("Expected detailed guidance nodes to still exist.")
		return

	if not bool(chip_row.get("visible")):
		_fail("Live state chips should remain visible during combat.")
		return
	if not String(phase_chip.get("text")).contains("PHASE"):
		_fail("Phase chip should compactly show the current phase.")
		return
	if not String(energy_chip.get("text")).contains("ENERGY"):
		_fail("Energy chip should compactly show current Energy.")
		return
	if not String(threat_chip.get("text")).contains("THREAT"):
		_fail("Threat chip should compactly show table danger.")
		return

	if bool(action_prompt.get("visible")) or bool(first_play_path.get("visible")):
		_fail("Long first-play text should collapse during live compact combat.")
		return
	if bool(turn_status.get("visible")) or bool(card_hint.get("visible")) or bool(feedback_feed.get("visible")):
		_fail("Detailed live readouts should collapse while compact chips teach the state.")


func _verify_commit_chips(combat_scene: Node) -> void:
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var target_chip: Button = combat_scene.find_child("TargetStateChip", true, false)
	var move_chip: Button = combat_scene.find_child("MoveStateChip", true, false)
	var rule_chip: Button = combat_scene.find_child("RuleStateChip", true, false)
	var target_step: Button = combat_scene.find_child("FirstPlayStepTarget", true, false)
	var card_step: Button = combat_scene.find_child("FirstPlayStepCard", true, false)
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	if continue_button == null or target_chip == null or move_chip == null or rule_chip == null:
		_fail("Expected commit chips and ContinueButton.")
		return
	if target_step == null or card_step == null or card_hint == null:
		_fail("Expected first-play step buttons and hidden card hint.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Begin Turn should land on Player Commit.")
		return
	if not String(target_chip.get("text")).contains("TARGET") or not String(move_chip.get("text")).contains("MOVE"):
		_fail("Target and move chips should show current target controls.")
		return
	if not String(rule_chip.get("text")).contains("RULE") or rule_chip.tooltip_text.is_empty():
		_fail("Rule chip should keep the table modifier visible with a tooltip.")
		return
	if not target_step.tooltip_text.contains("Active step") or not card_step.tooltip_text.contains("Active step"):
		_fail("Target and card step buttons should be active during Player Commit.")
		return
	if bool(card_hint.get("visible")):
		_fail("CardActionHint should stay collapsed in compact live mode.")
		return
	if not _get_text(card_hint).contains("Step 2"):
		_fail("Collapsed CardActionHint should still retain detailed debug/readback text.")


func _verify_debug_restores_detail(combat_scene: Node) -> void:
	var toggle_debug: Button = combat_scene.find_child("ToggleDebugButton", true, false)
	var action_prompt: Node = combat_scene.find_child("ActionPrompt", true, false)
	var first_play_path: Node = combat_scene.find_child("FirstPlayPath", true, false)
	var turn_status: Node = combat_scene.find_child("TurnStatus", true, false)
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	var feedback_feed: Node = combat_scene.find_child("CombatFeedback", true, false)
	if toggle_debug == null or action_prompt == null or first_play_path == null:
		_fail("Expected debug toggle and detailed guidance labels.")
		return
	if turn_status == null or card_hint == null or feedback_feed == null:
		_fail("Expected detailed live readouts.")
		return

	toggle_debug.emit_signal("pressed")
	await get_tree().process_frame

	if not bool(action_prompt.get("visible")) or not bool(first_play_path.get("visible")):
		_fail("Debug mode should restore detailed first-play text.")
		return
	if not bool(turn_status.get("visible")) or not bool(card_hint.get("visible")) or not bool(feedback_feed.get("visible")):
		_fail("Debug mode should restore detailed live readouts.")


func _get_phase_key(combat_scene: Node) -> String:
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		return ""
	return String(session.get("current_phase_key"))


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
