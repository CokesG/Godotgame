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
	if not status_text.contains("Ready:") or not status_text.contains("1 Target") or not status_text.contains("2 Play") or not status_text.contains("3 Resolve"):
		_fail("Live hand status should keep the first action sequence visible. Got: %s" % status_text)
		return

	continue_button.emit_signal("button_down")
	await get_tree().process_frame
	if not _has_vfx_child(vfx_layer, "VFXButtonSheen"):
		_fail("Pressing the dominant action button should spawn immediate sheen feedback.")
		return
	if not _has_vfx_child(vfx_layer, "VFXRing"):
		_fail("Pressing the dominant action button should spawn immediate ring feedback.")


func _verify_target_and_card_press_feedback(combat_scene: Node) -> void:
	var target_cards: Node = combat_scene.find_child("EnemyTargetCards", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if target_cards == null or combat_grid == null or hand_view == null or vfx_layer == null:
		_fail("Expected target cards, combat grid, hand, and VFX layer.")
		return
	if target_cards.get_child_count() <= 0 or hand_view.get_child_count() <= 0:
		_fail("Expected clickable target cards and hand cards after opening.")
		return

	var target_card: Button = target_cards.get_child(0)
	var enemy_id: StringName = StringName(target_card.get_meta("enemy_id", &""))
	target_card.emit_signal("button_down")
	await get_tree().process_frame

	var focus: Dictionary = combat_grid.call("get_focus_snapshot")
	if StringName(focus.get("unit_id", &"")) != enemy_id:
		_fail("Pressing a target card should immediately focus that enemy on the table.")
		return
	if not _has_vfx_child(vfx_layer, "VFXTargetLock"):
		_fail("Pressing a target card should spawn immediate target-lock feedback.")
		return

	var first_card: Button = _get_first_playable_hand_card(hand_view)
	if first_card == null:
		_fail("Expected at least one playable hand card.")
		return

	first_card.emit_signal("button_down")
	if first_card.modulate == Color.WHITE:
		_fail("Pressing a hand card should flash the card immediately before resolver work.")
		return

	first_card.emit_signal("pressed")
	await get_tree().process_frame
	if not _has_vfx_child(vfx_layer, "VFXCardFly"):
		_fail("Playing a hand card should still spawn traveling card feedback.")


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
