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

	_verify_feedback_nodes(combat_scene)
	if failed:
		return
	await _advance_to_commit(combat_scene)
	if failed:
		return
	await _verify_card_and_damage_feedback(combat_scene)
	if failed:
		return
	await _verify_guard_feedback(combat_scene)
	if failed:
		return
	await _verify_reveal_feedback(combat_scene)
	if failed:
		return

	print("PHASE18_COMBAT_FEEDBACK_CHECK: PASS")
	get_tree().quit(0)


func _verify_feedback_nodes(combat_scene: Node) -> void:
	var panel: Node = combat_scene.find_child("CombatFeedbackPanel", true, false)
	if panel == null:
		_fail("Expected CombatFeedbackPanel.")
		return

	var banner: Node = combat_scene.find_child("FeedbackBanner", true, false)
	if banner == null:
		_fail("Expected FeedbackBanner.")
		return

	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if feedback == null:
		_fail("Expected CombatFeedback feed.")
		return

	var feedback_text: String = _get_text(feedback)
	if not feedback_text.contains("Feedback"):
		_fail("CombatFeedback should explain that feedback beats land there.")
		return

	var grid: Node = combat_scene.find_child("CombatGrid", true, false)
	if grid == null or not grid.has_method("flash_unit"):
		_fail("CombatGrid should expose flash_unit for play-area pulses.")
		return


func _advance_to_commit(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if start_button == null:
		_fail("Expected StartRunButton.")
		return
	start_button.emit_signal("pressed")
	await get_tree().process_frame

	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return

	for _index in range(3):
		if continue_button.disabled:
			_fail("ContinueButton should stay available through Player Commit.")
			return
		continue_button.emit_signal("pressed")
		await get_tree().process_frame

	var turn_status: Node = combat_scene.find_child("TurnStatus", true, false)
	if turn_status == null or not _get_text(turn_status).contains("Player Commit"):
		_fail("Expected to reach Player Commit before playing a card.")


func _verify_card_and_damage_feedback(combat_scene: Node) -> void:
	var deck_manager: Node = combat_scene.find_child("DeckManager", true, false)
	if deck_manager == null:
		_fail("Expected DeckManager.")
		return

	deck_manager.call("configure_deck", ["res://resources/cards/quick_slash.tres"])
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", 1)
	await get_tree().process_frame

	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if hand_view == null or hand_view.get_child_count() == 0:
		_fail("Expected a playable Quick Slash in hand.")
		return

	var card_button: Button = hand_view.get_child(0)
	card_button.emit_signal("pressed")
	await get_tree().process_frame

	var feedback_text: String = _get_feedback_text(combat_scene)
	if not feedback_text.contains("Card: Quick Slash played"):
		_fail("CombatFeedback should show the played card beat.")
		return
	if not feedback_text.contains("HP"):
		_fail("CombatFeedback should show enemy HP damage after Quick Slash.")
		return


func _verify_guard_feedback(combat_scene: Node) -> void:
	var resolver: Node = combat_scene.find_child("CombatResolver", true, false)
	if resolver == null:
		_fail("Expected CombatResolver.")
		return

	var guard_card: Resource = load("res://resources/cards/guard_up.tres")
	resolver.call("apply_card_with_context", guard_card, {})
	await get_tree().process_frame

	if not _get_feedback_text(combat_scene).contains("Guard +5"):
		_fail("CombatFeedback should show Guard gain.")


func _verify_reveal_feedback(combat_scene: Node) -> void:
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return

	for _index in range(2):
		if continue_button.disabled:
			_fail("ContinueButton should advance from commit to reveal.")
			return
		continue_button.emit_signal("pressed")
		await get_tree().process_frame

	var feedback_text: String = _get_feedback_text(combat_scene)
	if not feedback_text.contains("Reveal:"):
		_fail("CombatFeedback should show revealed enemy intents.")
		return

	var banner: Node = combat_scene.find_child("FeedbackBanner", true, false)
	if banner == null or _get_text(banner) == "Ready":
		_fail("FeedbackBanner should update after combat beats.")


func _get_feedback_text(combat_scene: Node) -> String:
	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if feedback == null:
		return ""
	return _get_text(feedback)


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
