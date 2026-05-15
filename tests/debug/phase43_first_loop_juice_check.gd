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
	await get_tree().process_frame

	_verify_vfx_api(combat_scene)
	if failed:
		return
	await _verify_target_hover_and_selection_feedback(combat_scene)
	if failed:
		return
	await _verify_card_travel_and_impact_feedback(combat_scene)
	if failed:
		return
	await _verify_reward_shimmer(combat_scene)
	if failed:
		return

	print("PHASE43_FIRST_LOOP_JUICE_CHECK: PASS")
	get_tree().quit(0)


func _verify_vfx_api(combat_scene: Node) -> void:
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if vfx_layer == null:
		_fail("Expected CombatVFX layer.")
		return

	for method_name in ["play_card_fly_between", "play_target_lock_on", "play_target_lock_at", "play_reward_shimmer_on", "play_button_sheen_on"]:
		if not vfx_layer.has_method(method_name):
			_fail("CombatVFX missing Phase 43 method %s." % method_name)
			return


func _verify_target_hover_and_selection_feedback(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var target_cards: Node = combat_scene.find_child("EnemyTargetCards", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if start_button == null or target_cards == null or combat_grid == null or vfx_layer == null:
		_fail("Expected opening, target cards, grid, and VFX layer.")
		return

	start_button.emit_signal("pressed")
	await _settle()

	if target_cards.get_child_count() < 2:
		_fail("Expected at least two direct enemy target cards.")
		return

	var target_card: Button = target_cards.get_child(1)
	var enemy_id: StringName = StringName(target_card.get_meta("enemy_id", &""))
	target_card.emit_signal("mouse_entered")
	await get_tree().process_frame

	var focus: Dictionary = combat_grid.call("get_focus_snapshot")
	if StringName(focus.get("unit_id", &"")) != enemy_id:
		_fail("Hovering an enemy target card should focus that enemy on the table.")
		return
	if not _has_vfx_child(vfx_layer, "VFXTargetLock"):
		_fail("Hovering an enemy target card should spawn a target-lock VFX.")
		return

	target_card.emit_signal("pressed")
	await get_tree().process_frame
	if not _has_vfx_child(vfx_layer, "VFXTargetLock"):
		_fail("Selecting an enemy target should keep target-lock feedback visible.")
		return


func _verify_card_travel_and_impact_feedback(combat_scene: Node) -> void:
	var deck_manager: Node = combat_scene.find_child("DeckManager", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if deck_manager == null or hand_view == null or vfx_layer == null:
		_fail("Expected deck, hand, and VFX layer.")
		return

	deck_manager.call("configure_deck", ["res://resources/cards/quick_slash.tres"])
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", 1)
	await _settle()

	if hand_view.get_child_count() <= 0:
		_fail("Expected deterministic Quick Slash in hand.")
		return

	var card_button: Button = hand_view.get_child(0)
	card_button.emit_signal("pressed")
	await get_tree().process_frame

	if not _has_vfx_child(vfx_layer, "VFXCardFly"):
		_fail("Playing a card should spawn a traveling card VFX.")
		return
	if not _has_vfx_child(vfx_layer, "VFXSlash"):
		_fail("Playing an attack card should spawn a slash VFX.")
		return
	if not _has_vfx_child(vfx_layer, "VFXParticle"):
		_fail("Playing an attack card should spawn impact particles.")
		return


func _verify_reward_shimmer(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if run_manager == null or card_reward == null or vfx_layer == null:
		_fail("Expected run manager, reward card, and VFX layer.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await _settle()

	if not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Reward card should be visible before checking shimmer.")
		return
	if not _has_vfx_child(vfx_layer, "VFXRewardShimmer"):
		_fail("Reward screen should shimmer the recommended card.")


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
