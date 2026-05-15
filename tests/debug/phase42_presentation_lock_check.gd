extends Node

var failed: bool = false


func _ready() -> void:
	_verify_project_viewport()
	if failed:
		return

	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	_verify_opening_presentation(combat_scene)
	if failed:
		return
	await _verify_compact_live_presentation(combat_scene)
	if failed:
		return
	await _verify_reward_and_approach_presentation(combat_scene)
	if failed:
		return

	print("PHASE42_PRESENTATION_LOCK_CHECK: PASS")
	get_tree().quit(0)


func _verify_project_viewport() -> void:
	var viewport_width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var viewport_height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	if viewport_width != 1152 or viewport_height != 648:
		_fail("Project viewport should stay locked to 1152x648 for first-viewport visual QA.")


func _verify_opening_presentation(combat_scene: Node) -> void:
	var title_plate: Node = combat_scene.find_child("TitlePlaque", true, false)
	var action_cue_panel: Node = combat_scene.find_child("ActionCuePanel", true, false)
	var action_cue_title: Node = combat_scene.find_child("ActionCueTitle", true, false)
	var action_cue_detail: Node = combat_scene.find_child("ActionCueDetail", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var run_path: Node = combat_scene.find_child("RunPath", true, false)
	var run_path_buttons: Node = combat_scene.find_child("RunPathButtons", true, false)
	var opening_steps: Node = combat_scene.find_child("OpeningStepRow", true, false)
	var encounter_approach: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	var debug_drawer: Node = combat_scene.find_child("DebugDrawer", true, false)
	var log_column: Node = combat_scene.find_child("LogColumn", true, false)
	if title_plate == null or action_cue_panel == null or action_cue_title == null or action_cue_detail == null:
		_fail("Opening screen should have title and cue data nodes.")
		return
	if start_button == null or continue_button == null or combat_body == null:
		_fail("Opening screen should have primary action and play body nodes.")
		return
	if run_panel == null or run_path == null or run_path_buttons == null or opening_steps == null or encounter_approach == null:
		_fail("Opening screen should keep route/reward nodes available but gated.")
		return
	if debug_drawer == null or log_column == null:
		_fail("Opening screen should keep debug/log nodes available but hidden.")
		return

	if not _is_visible(title_plate):
		_fail("Opening screen should show the branded title plaque.")
		return
	if _is_visible(action_cue_panel):
		_fail("Opening screen should not show a duplicate dealer cue above the Deal In hero action.")
		return
	if _get_text(action_cue_title) != "DEAL IN":
		_fail("Opening cue data should still lead with DEAL IN.")
		return
	if not _get_text(action_cue_detail).contains("Deal In"):
		_fail("Opening cue data should point at the one obvious first action.")
		return
	if not _is_visible(start_button) or bool(start_button.get("disabled")):
		_fail("Deal In should be visible and enabled on the first screen.")
		return
	if not String(start_button.get("text")).contains("DEAL IN"):
		_fail("First action should read Deal In.")
		return
	if not _is_visible(opening_steps) or opening_steps.get_child_count() < 4:
		_fail("Opening screen should show the four-step action path.")
		return
	if not _get_text(run_path).contains("Deal In now"):
		_fail("Opening route copy should point at Deal In.")
		return
	if _is_visible(continue_button):
		_fail("ContinueButton should not compete with the opening action.")
		return
	if _is_visible(run_panel) or _is_visible(debug_drawer) or _is_visible(log_column):
		_fail("Opening screen should not show reward/tuning/debug/log panels.")
		return
	if not _is_visible(run_path_buttons) or _is_visible(encounter_approach):
		_fail("Opening screen should show colorful route chips while keeping report-style approach detail hidden.")


func _verify_compact_live_presentation(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if start_button == null:
		_fail("Expected StartRunButton.")
		return

	start_button.emit_signal("pressed")
	await _wait_frames(2)

	var hidden_chrome := [
		"TitlePlaque",
		"RunHeader",
		"RunPathPanel",
		"RunShellTitle",
		"RunShellActions",
		"ActionCuePanel",
		"TargetControlsPanel",
		"ActionPrompt",
		"FirstPlayPath",
		"FirstPlayCoachPanel",
		"FirstPlayStepButtons",
		"TurnStatus",
		"TableRuleStatus",
		"ThreatSummary",
		"IntentPreview",
		"BluffState",
		"CardActionHint",
		"CardTargetPreview",
		"CombatFeedback",
		"RunPanel",
		"DebugDrawer",
		"LogColumn"
	]
	for node_name in hidden_chrome:
		var node := combat_scene.find_child(node_name, true, false)
		if node == null:
			_fail("Expected presentation node: %s" % node_name)
			return
		if _is_visible(node):
			_fail("%s should stay collapsed in compact live combat." % node_name)
			return

	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var table_row: Node = combat_scene.find_child("TableRow", true, false)
	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var enemy_target_cards: Node = combat_scene.find_child("EnemyTargetCards", true, false)
	var live_chips: Node = combat_scene.find_child("LiveStateChips", true, false)
	var hand_status: Node = combat_scene.find_child("HandActionStatus", true, false)
	if combat_body == null or table_row == null or deck_panel == null:
		_fail("Expected live combat body, table row, and hand rail.")
		return
	if continue_button == null:
		_fail("Expected compact live smart action.")
		return
	if enemy_target_cards == null or live_chips == null or hand_status == null:
		_fail("Expected compact target, chip, and hand-status controls.")
		return

	if not _is_visible(combat_body) or not _is_visible(table_row) or not _is_visible(deck_panel):
		_fail("Live combat should keep table, enemy state, and hand visible.")
		return
	if table_row.get_parent() != combat_body or deck_panel.get_parent() != combat_body:
		_fail("Table row and hand rail should stay inside the live combat body.")
		return
	if _child_index(combat_body, table_row) > _child_index(combat_body, deck_panel):
		_fail("The table should sit above the hand rail in live combat.")
		return
	if not _is_visible(continue_button) or bool(continue_button.get("disabled")):
		_fail("Resolve Turn should be the visible live smart action.")
		return
	if String(continue_button.get("text")) != "Resolve Turn":
		_fail("Opening live combat should expose Resolve Turn as the dominant action.")
		return
	if not _is_visible(enemy_target_cards) or enemy_target_cards.get_child_count() <= 0:
		_fail("Clickable enemy target cards should be visible in compact live combat.")
		return
	if _is_visible(live_chips) or not _is_visible(hand_status):
		_fail("Compact live combat should hide state chips and keep the hand status visible.")
		return


func _verify_reward_and_approach_presentation(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await _wait_frames(2)

	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	var skip_reward: Button = combat_scene.find_child("SkipRewardsButton", true, false)
	var reward_impact: Node = combat_scene.find_child("RewardImpact", true, false)
	var enemy_target_cards: Node = combat_scene.find_child("EnemyTargetCards", true, false)
	var run_path_panel: Node = combat_scene.find_child("RunPathPanel", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var cue_title: Node = combat_scene.find_child("ActionCueTitle", true, false)
	if combat_body == null or run_panel == null or card_reward == null or skip_reward == null:
		_fail("Expected reward shell nodes.")
		return
	if reward_impact == null or enemy_target_cards == null or run_path_panel == null or continue_button == null:
		_fail("Expected reward impact and collapsed live-combat nodes.")
		return
	if cue_title == null:
		_fail("Expected action cue title.")
		return

	if _is_visible(combat_body) or _is_visible(enemy_target_cards):
		_fail("Reward screen should clear live combat target/table controls.")
		return
	if _is_visible(run_path_panel):
		_fail("Reward screen should stay focused on take/skip instead of route detail.")
		return
	if not _is_visible(run_panel) or not _is_visible(card_reward) or not _is_visible(skip_reward):
		_fail("Reward screen should expose clear card and skip choices.")
		return
	if bool(card_reward.get("disabled")) or bool(skip_reward.get("disabled")):
		_fail("Reward take/skip choices should be enabled.")
		return
	if not _is_visible(reward_impact) or not _get_text(reward_impact).contains("deck"):
		_fail("Reward screen should show before/after deck impact.")
		return
	if _is_visible(continue_button):
		_fail("Combat smart action should stay hidden during reward decisions.")
		return
	if _get_text(cue_title) != "CASH OUT":
		_fail("Reward decision should use the CASH OUT cue.")
		return

	card_reward.emit_signal("pressed")
	await _wait_frames(2)

	var encounter_approach: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	var approach_title: Node = combat_scene.find_child("ApproachTitle", true, false)
	if encounter_approach == null or next_encounter == null or approach_title == null:
		_fail("Expected next-table approach presentation nodes.")
		return
	if not _is_visible(encounter_approach) or not _is_visible(next_encounter):
		_fail("Taking a reward should move into a visible next-table approach.")
		return
	if bool(next_encounter.get("disabled")) or not String(next_encounter.get("text")).contains("Open"):
		_fail("Next-table approach should expose one enabled Open action.")
		return
	if not _get_text(approach_title).contains("Approach Table 2/5"):
		_fail("Approach title should show movement to Table 2/5.")
		return
	if _is_visible(combat_body) or _is_visible(enemy_target_cards):
		_fail("Approach screen should not re-show live combat until the next table opens.")
		return
	if not _is_visible(run_path_panel):
		_fail("Approach screen should bring the route map back as movement context.")
		return

	next_encounter.emit_signal("pressed")
	await _wait_frames(2)

	if not _is_visible(combat_body) or not _is_visible(enemy_target_cards):
		_fail("Opening the next table should return to compact live combat.")
		return
	if _is_visible(combat_scene.find_child("TargetControlsPanel", true, false)):
		_fail("Second table should keep detailed target dropdowns collapsed by default.")
		return
	if _get_text(combat_scene.find_child("ActionCueTitle", true, false)) != "YOUR PLAY":
		_fail("Second table should return to the YOUR PLAY cue.")


func _child_index(parent: Node, child: Node) -> int:
	for index in range(parent.get_child_count()):
		if parent.get_child(index) == child:
			return index
	return 999


func _is_visible(node: Node) -> bool:
	if node is CanvasItem:
		return (node as CanvasItem).is_visible_in_tree()
	return false


func _get_text(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
