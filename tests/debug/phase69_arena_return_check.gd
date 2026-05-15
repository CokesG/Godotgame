extends Node

var failed := false


func _ready() -> void:
	await _run_check()


func _run_check() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge == null:
		_fail("ArenaBridge autoload should exist for arena return checks.")
		return

	bridge.call("set_result", {
		"source": "fps_arena",
		"map_name": "Crossfire Table",
		"cleared": true,
		"wave": 1,
		"kills": 4,
		"clear_time": 18.4,
		"shots_fired": 8,
		"shots_hit": 6,
		"hit_rate": 0.75,
		"critical_hits": 2,
		"damage_dealt": 180,
		"damage_taken": 12,
		"remaining_health": 28,
		"remaining_armor": 5,
		"loadout": {"weapon": "Ace Cutter Revolver", "abilities": 1, "armor": 5, "ammo": 24, "chips": 2},
		"selected_reward": {"label": "Damage Payout", "kind": "damage", "amount": 3, "chip_bonus": 2},
		"chips_awarded": 9,
		"cards_to_draw": 5
	})

	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return
	var combat_scene := packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()

	var panel: Control = combat_scene.find_child("ArenaPayoutPanel", true, false)
	var label: RichTextLabel = combat_scene.find_child("ArenaPayoutLabel", true, false)
	var button: Button = combat_scene.find_child("ArenaPayoutContinueButton", true, false)
	if panel == null or label == null or button == null:
		_fail("Returned card table should expose the arena payout panel, label, and continue button.")
		return
	if not panel.visible:
		_fail("Arena payout panel should be visible after a pending FPS result.")
		return
	if not String(label.text).contains("Damage Payout") or not String(label.text).contains("+9 Chips"):
		_fail("Arena payout label should summarize the selected reward and chip grant.")
		return
	if int(combat_scene.get("shooter_chips")) != 16:
		_fail("Arena payout should add 9 chips to the fresh prep economy.")
		return
	var deck_manager: Node = combat_scene.get("deck_manager")
	var counts: Dictionary = deck_manager.call("get_counts") if deck_manager != null else {}
	if int(counts.get("hand", 0)) != 5:
		_fail("Arena payout should leave the table on a five-card next hand.")
		return

	button.emit_signal("pressed")
	await _settle()
	if bool(combat_scene.get("arena_payout_pending")):
		_fail("Start Next Hand should clear the pending arena payout.")
		return
	if panel.visible:
		_fail("Start Next Hand should hide the arena payout panel.")
		return

	print("PHASE69_ARENA_RETURN_CHECK: PASS")
	get_tree().quit(0)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error(message)
	get_tree().quit(1)
