extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()

	await _verify_live_guidance_and_fast_button_feedback(combat_scene)
	if failed:
		return
	await _verify_target_and_card_press_feedback(combat_scene)
	if failed:
		return

	print("PHASE44_RESPONSIVENESS_GUIDANCE_CHECK: PASS")
	get_tree().quit(0)


func _verify_live_guidance_and_fast_button_feedback(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var hand_status: Label = combat_scene.find_child("HandActionStatus", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if start_button == null or hand_status == null or continue_button == null or vfx_layer == null:
		_fail("Expected opening button, hand status, continue button, and VFX layer.")
		return

	start_button.emit_signal("pressed")
	await _settle()

	var status_text := String(hand_status.get("text"))
	if not status_text.contains("ECONOMY") or not status_text.contains("Gun, Q, E, Passive"):
		_fail("Live hand status should explain kit attachment. Got: %s" % status_text)
		return

	continue_button.emit_signal("button_down")
	await get_tree().process_frame
	if not _has_vfx_child(vfx_layer, "VFXButtonSheen"):
		_fail("Pressing the dominant action button should spawn immediate sheen feedback.")
		return
	if not _has_vfx_child(vfx_layer, "VFXRing"):
		_fail("Pressing the dominant action button should spawn immediate ring feedback.")


func _verify_target_and_card_press_feedback(combat_scene: Node) -> void:
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var equip_best_button: Button = combat_scene.find_child("SlotSelectedCardButton", true, false)
	var hand_status: Label = combat_scene.find_child("HandActionStatus", true, false)
	if hand_view == null or equip_best_button == null or hand_status == null:
		_fail("Expected hand, Equip Best button, and hand status.")
		return
	if hand_view.get_child_count() <= 0:
		_fail("Expected clickable hand cards after opening.")
		return

	var first_card: Button = _get_first_playable_hand_card(hand_view)
	if first_card == null:
		_fail("Expected at least one selectable hand card.")
		return

	first_card.emit_signal("button_down")
	if first_card.modulate == Color.WHITE:
		_fail("Pressing a hand card should flash the card immediately before kit attachment.")
		return

	first_card.emit_signal("pressed")
	await get_tree().process_frame
	var selected_status := String(hand_status.get("text"))
	if not selected_status.contains("SELECTED") and not selected_status.contains("LOADOUT:"):
		_fail("Clicking a hand card should select it for slot attachment.")
		return

	equip_best_button.emit_signal("pressed")
	await get_tree().process_frame
	var loadout_slots: Dictionary = combat_scene.get("loadout_slots")
	if loadout_slots.is_empty():
		_fail("Pressing Equip Best should attach the selected card to the kit.")


func _get_first_playable_hand_card(hand_view: Node) -> Button:
	for child in hand_view.get_children():
		if child is Button and not bool(child.get("disabled")):
			return child as Button
	return null


func _has_vfx_child(vfx_layer: Node, child_name: String) -> bool:
	for child in vfx_layer.get_children():
		if String(child.name).begins_with(child_name):
			return true
	return false


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
