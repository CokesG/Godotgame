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

	_verify_opening_cue(combat_scene)
	if failed:
		return
	await _verify_commit_cue_and_action_focus(combat_scene)
	if failed:
		return
	await _verify_feedback_and_vfx_after_card(combat_scene)
	if failed:
		return
	await _verify_reward_cue(combat_scene)
	if failed:
		return

	print("PHASE40_PLAY_FEEL_QA_CHECK: PASS")
	get_tree().quit(0)


func _verify_opening_cue(combat_scene: Node) -> void:
	var cue_panel: PanelContainer = combat_scene.find_child("ActionCuePanel", true, false)
	var cue_title: Label = combat_scene.find_child("ActionCueTitle", true, false)
	var cue_detail: Label = combat_scene.find_child("ActionCueDetail", true, false)
	var cue_pip: Label = combat_scene.find_child("ActionCuePip", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var opening_steps: Node = combat_scene.find_child("OpeningStepRow", true, false)
	var run_path_buttons: Node = combat_scene.find_child("RunPathButtons", true, false)
	var opening_prompt: Label = combat_scene.find_child("OpeningClickPrompt", true, false)
	if cue_panel == null or cue_title == null or cue_detail == null or cue_pip == null:
		_fail("Expected dealer-style ActionCuePanel with title, detail, and pip labels.")
		return
	if start_button == null or continue_button == null or opening_steps == null or run_path_buttons == null or opening_prompt == null:
		_fail("Expected opening action, click prompt, step row, route chips, and smart action button.")
		return

	if bool(cue_panel.get("visible")):
		_fail("Opening screen should not duplicate the hero Deal In action with a second cue panel.")
		return
	if _get_text(cue_title) != "DEAL IN" or not _get_text(cue_detail).contains("Deal In") or _get_text(cue_pip) != "OPEN":
		_fail("Opening cue data should still describe the Deal In action for later compact states.")
		return
	if not String(start_button.get("text")).contains("DEAL IN") or start_button.custom_minimum_size.x < 280 or not start_button.tooltip_text.contains("Deal"):
		_fail("Deal In button should stay visually dominant and self-explanatory.")
		return
	if not bool(opening_prompt.get("visible")) or not String(opening_prompt.get("text")).contains("DEAL IN"):
		_fail("Opening prompt should explain that selecting a fighter leads to Deal In.")
		return
	if not bool(opening_steps.get("visible")) or opening_steps.get_child_count() < 4:
		_fail("Opening screen should show the four-step Deal In, Target, Card, Resolve path.")
		return
	if not String((opening_steps.get_child(0) as Button).get("text")).contains("DEAL IN"):
		_fail("Opening step row should start with DEAL IN.")
		return
	if not bool(run_path_buttons.get("visible")) or run_path_buttons.get_child_count() < 5:
		_fail("Opening route chips should be visible so the run feels like a route, not a form.")
		return
	if bool(continue_button.get("visible")):
		_fail("ContinueButton should not compete with the opening cue.")


func _verify_commit_cue_and_action_focus(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var cue_title: Label = combat_scene.find_child("ActionCueTitle", true, false)
	var cue_detail: Label = combat_scene.find_child("ActionCueDetail", true, false)
	var cue_pip: Label = combat_scene.find_child("ActionCuePip", true, false)
	var target_chip: Button = combat_scene.find_child("TargetStateChip", true, false)
	var card_step: Button = combat_scene.find_child("FirstPlayStepCard", true, false)
	var live_chips: Node = combat_scene.find_child("LiveStateChips", true, false)
	if start_button == null or continue_button == null or cue_title == null or cue_detail == null:
		_fail("Expected live cue and action controls.")
		return
	if cue_pip == null or target_chip == null or card_step == null or live_chips == null:
		_fail("Expected compact play state controls.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Opening table should land directly in Player Commit.")
		return
	if _get_text(cue_title) != "YOUR PLAY" or _get_text(cue_pip) != "PLAY":
		_fail("Player Commit should use a clear YOUR PLAY cue.")
		return
	if not _get_text(cue_detail).contains("Target") or not _get_text(cue_detail).contains("Resolve Turn"):
		_fail("Commit cue should mention target selection and Resolve Turn.")
		return
	if String(continue_button.get("text")) != "Resolve Turn" or bool(continue_button.get("disabled")):
		_fail("Resolve Turn should be the single live smart action during commit.")
		return
	if not target_chip.tooltip_text.contains("Attack and read") or not card_step.tooltip_text.contains("Active step"):
		_fail("Compact chips should keep target/card intent obvious.")
		return
	if bool(live_chips.get("visible")):
		_fail("Live state chips should stay collapsed during compact combat to protect the arena/hand space.")


func _verify_feedback_and_vfx_after_card(combat_scene: Node) -> void:
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var feedback_banner: Label = combat_scene.find_child("FeedbackBanner", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	var cue_title: Label = combat_scene.find_child("ActionCueTitle", true, false)
	if hand_view == null or feedback_banner == null or vfx_layer == null or cue_title == null:
		_fail("Expected hand, feedback banner, VFX layer, and cue.")
		return
	if hand_view.get_child_count() == 0:
		_fail("Expected at least one playable card.")
		return

	var previous_vfx_count := vfx_layer.get_child_count()
	var first_card: Button = hand_view.get_child(0)
	if bool(first_card.get("disabled")):
		_fail("First hand card should be playable after opening the table.")
		return
	first_card.emit_signal("pressed")
	await get_tree().process_frame

	if not _get_text(feedback_banner).contains("Card:"):
		_fail("Playing a card should produce a punchy feedback banner.")
		return
	if vfx_layer.get_child_count() <= previous_vfx_count:
		_fail("Playing a card should spawn a visible VFX beat.")
		return
	if _get_text(cue_title) != "YOUR PLAY":
		_fail("Card play should keep the player in the live play cue until Resolve Turn.")


func _verify_reward_cue(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var cue_title: Label = combat_scene.find_child("ActionCueTitle", true, false)
	var cue_detail: Label = combat_scene.find_child("ActionCueDetail", true, false)
	var cue_pip: Label = combat_scene.find_child("ActionCuePip", true, false)
	var run_panel: Node = combat_scene.find_child("RunPanel", true, false)
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if run_manager == null or cue_title == null or cue_detail == null or cue_pip == null:
		_fail("Expected run manager and reward cue nodes.")
		return
	if run_panel == null or card_reward == null or continue_button == null:
		_fail("Expected reward panel and action controls.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	if _get_text(cue_title) != "CASH OUT" or _get_text(cue_pip) != "REWARD":
		_fail("Reward flow should switch to a CASH OUT cue.")
		return
	if not _get_text(cue_detail).contains("reward"):
		_fail("Reward cue should explain the reward decision compactly.")
		return
	if not bool(run_panel.get("visible")) or not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Reward choice should be visible and selectable.")
		return
	if bool(continue_button.get("visible")):
		_fail("Smart combat action should hide while reward choice is active.")


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
