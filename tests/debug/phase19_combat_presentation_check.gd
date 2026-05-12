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

	_verify_presentation_nodes(combat_scene)
	if failed:
		return
	await _advance_to_commit(combat_scene)
	if failed:
		return
	await _verify_card_preview(combat_scene)
	if failed:
		return
	await _verify_floating_numbers(combat_scene)
	if failed:
		return

	print("PHASE19_COMBAT_PRESENTATION_CHECK: PASS")
	get_tree().quit(0)


func _verify_presentation_nodes(combat_scene: Node) -> void:
	var intent_icons: Node = combat_scene.find_child("IntentIconStrip", true, false)
	if intent_icons == null:
		_fail("Expected IntentIconStrip.")
		return
	var icon_text: String = _get_text(intent_icons)
	if not icon_text.contains("Intent Icons") or not icon_text.contains("["):
		_fail("IntentIconStrip should show compact intent markers.")
		return

	var card_preview: Node = combat_scene.find_child("CardTargetPreview", true, false)
	if card_preview == null:
		_fail("Expected CardTargetPreview.")
		return
	if not _get_text(card_preview).contains("Preview:"):
		_fail("CardTargetPreview should start with preview guidance.")
		return

	var grid: Node = combat_scene.find_child("CombatGrid", true, false)
	if grid == null:
		_fail("Expected CombatGrid.")
		return
	if not grid.has_method("show_floating_text_for_unit"):
		_fail("CombatGrid should expose floating combat text.")


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


func _verify_card_preview(combat_scene: Node) -> void:
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
		_fail("Expected a card in HandView.")
		return

	var card_button: Button = hand_view.get_child(0)
	card_button.emit_signal("card_hovered", 0)
	await get_tree().process_frame

	var preview: Node = combat_scene.find_child("CardTargetPreview", true, false)
	var preview_text: String = _get_text(preview)
	if not preview_text.contains("Preview: Quick Slash"):
		_fail("CardTargetPreview should name the hovered card.")
		return
	if not preview_text.contains("Target:") or not preview_text.contains("Expected: Deal 4 damage"):
		_fail("CardTargetPreview should show target and expected effect before click.")
		return
	if not bool(card_button.get("is_previewed")):
		_fail("Hovered CardView should enter preview visual state.")


func _verify_floating_numbers(combat_scene: Node) -> void:
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if hand_view == null or hand_view.get_child_count() == 0:
		_fail("Expected a playable card for floating number check.")
		return

	var card_button: Button = hand_view.get_child(0)
	card_button.emit_signal("pressed")
	await get_tree().process_frame

	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if feedback == null or not _get_text(feedback).contains("HP"):
		_fail("Combat feedback should report HP damage.")
		return

	var grid: Node = combat_scene.find_child("CombatGrid", true, false)
	if grid == null:
		_fail("Expected CombatGrid.")
		return
	grid.call("show_floating_text_for_unit", &"player", "+5G", Color(0.38, 0.78, 1.0))
	await get_tree().process_frame

	if grid.find_child("FloatingCombatText", true, false) == null:
		_fail("Floating combat text should be created over the grid.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
