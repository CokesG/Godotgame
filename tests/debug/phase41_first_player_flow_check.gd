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

	_verify_opening_coach(combat_scene)
	if failed:
		return
	await _verify_click_target_card_grid_and_play_card(combat_scene)
	if failed:
		return
	await _verify_reward_map_to_second_table(combat_scene)
	if failed:
		return

	print("PHASE41_FIRST_PLAYER_FLOW_CHECK: PASS")
	get_tree().quit(0)


func _verify_opening_coach(combat_scene: Node) -> void:
	var coach_panel: Node = combat_scene.find_child("FirstPlayCoachPanel", true, false)
	var coach: Node = combat_scene.find_child("FirstPlayCoach", true, false)
	var hand_status: Label = combat_scene.find_child("HandActionStatus", true, false)
	if coach_panel == null or coach == null or hand_status == null:
		_fail("Expected first-play coach and hand status.")
		return
	if not bool(coach_panel.get("visible")):
		_fail("First-play coach should be visible before the first table opens.")
		return
	var coach_text := _get_text(coach)
	if not coach_text.contains("OPEN") or not coach_text.contains("TARGET") or not coach_text.contains("CARD") or not coach_text.contains("RESOLVE"):
		_fail("First-play coach should show the full open-target-card-resolve sequence.")
		return
	if not String(hand_status.get("text")).contains("Cards locked"):
		_fail("Hand status should explain the wrong-phase lock before opening.")


func _verify_click_target_card_grid_and_play_card(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var target_cards: Node = combat_scene.find_child("EnemyTargetCards", true, false)
	var target_option: OptionButton = combat_scene.find_child("TargetEnemyOption", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var hand_status: Label = combat_scene.find_child("HandActionStatus", true, false)
	var coach_panel: Node = combat_scene.find_child("FirstPlayCoachPanel", true, false)
	var coach: Node = combat_scene.find_child("FirstPlayCoach", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if start_button == null or target_cards == null or target_option == null or combat_grid == null:
		_fail("Expected opening button, direct target cards, target option, and grid.")
		return
	if hand_view == null or hand_status == null or coach_panel == null or coach == null or continue_button == null:
		_fail("Expected hand, hand status, coach, and continue button.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Opening table should deal directly into Player Commit.")
		return
	if not _get_text(coach).contains("OPEN OK"):
		_fail("Coach should mark Open complete after the table opens.")
		return
	if target_cards.get_child_count() <= 0:
		_fail("Enemy target cards should be visible and clickable.")
		return

	var target_card: Button = target_cards.get_child(0)
	if not target_card.has_meta("enemy_id"):
		_fail("Enemy target card should carry target metadata.")
		return
	var enemy_id: StringName = StringName(target_card.get_meta("enemy_id"))
	target_card.emit_signal("pressed")
	await get_tree().process_frame

	if _get_selected_target_id(target_option) != enemy_id:
		_fail("Clicking an enemy card should update the selected enemy target.")
		return
	if not _get_text(coach).contains("TARGET OK"):
		_fail("Coach should mark Target complete after direct target selection.")
		return

	var enemy_cell: Vector2i = combat_grid.call("get_unit_position", enemy_id)
	combat_grid.call("select_cell", enemy_cell)
	await get_tree().process_frame

	if _get_selected_target_id(target_option) != enemy_id:
		_fail("Clicking the enemy on the grid should keep/select that target.")
		return
	if not String(combat_grid.find_child("GridFrame", true, false).find_child("TableTitle", true, false).get("text")).contains("The Table"):
		_fail("Grid should remain in the live table presentation after direct target clicks.")
		return

	if not String(hand_status.get("text")).contains("Ready:"):
		_fail("Hand status should show ready lit cards during Player Commit.")
		return
	if hand_view.get_child_count() <= 0:
		_fail("Expected playable hand cards.")
		return

	var first_card: Button = hand_view.get_child(0)
	if bool(first_card.get("disabled")):
		_fail("First card should be playable after selecting a target.")
		return
	var style: StyleBox = first_card.get_theme_stylebox("normal")
	if not (style is StyleBoxFlat) or (style as StyleBoxFlat).border_width_left < 3:
		_fail("Playable cards should have a stronger glowing border.")
		return

	first_card.emit_signal("pressed")
	await get_tree().process_frame

	if not _get_text(coach).contains("CARD OK"):
		_fail("Coach should mark Card complete after playing a card.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().create_timer(0.9).timeout

	if not bool(combat_scene.get("first_play_coach_complete")):
		_fail("Coach should complete after Open, Target, Card, and Resolve.")
		return
	if bool(coach_panel.get("visible")):
		_fail("Completed first-play coach should fade out of the live screen.")


func _verify_reward_map_to_second_table(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Expected selectable card reward after victory.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var approach_title: Node = combat_scene.find_child("ApproachTitle", true, false)
	if next_encounter == null or title == null or approach_title == null:
		_fail("Expected next-table approach controls.")
		return
	if _get_text(title) != "Next Table" or not _get_text(approach_title).contains("Approach Table 2/5"):
		_fail("Reward should move to a clear Table 2 approach preview.")
		return
	if not bool(next_encounter.get("visible")) or bool(next_encounter.get("disabled")):
		_fail("Open Next Table should be the live route action after reward.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Second table should deal into playable combat.")
		return
	if bool(combat_scene.find_child("FirstPlayCoachPanel", true, false).get("visible")):
		_fail("First-table coach should stay faded on later tables.")
		return
	if combat_scene.find_child("EnemyTargetCards", true, false).get_child_count() <= 0:
		_fail("Second table should still expose direct enemy target cards.")


func _get_selected_target_id(target_option: OptionButton) -> StringName:
	if target_option == null or target_option.selected < 0:
		return &""
	var metadata = target_option.get_item_metadata(target_option.selected)
	if typeof(metadata) != TYPE_DICTIONARY:
		return &""
	return StringName(metadata.get("id", &""))


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
