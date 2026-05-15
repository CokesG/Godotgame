extends Node

var failed := false


func _ready() -> void:
	await _run_check()


func _run_check() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge == null:
		_fail("ArenaBridge autoload should exist for arena return checks.")
		return

	bridge.call("set_return_state", _build_return_state())
	bridge.call("set_result", {
		"source": "fps_arena",
		"map_name": "Crossfire Table",
		"outcome": "win",
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
		"objective_score": 94,
		"wounds_taken": 0,
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
	var table_row: Control = combat_scene.find_child("TableRow", true, false)
	var deck_panel: Control = combat_scene.find_child("DeckPanel", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if panel == null or label == null or button == null:
		_fail("Returned card table should expose the arena payout panel, label, and continue button.")
		return
	if not panel.visible:
		_fail("Arena payout panel should be visible after a pending FPS result.")
		return
	if table_row == null or table_row.visible:
		_fail("Arena payout should hide the tactical board; no target/move choice exists until the reward is collected.")
		return
	if deck_panel == null or deck_panel.visible:
		_fail("Arena payout should hide the deck/loadout controls so the only live decision is collecting the reward.")
		return
	if continue_button == null or continue_button.disabled or not String(continue_button.text).contains("Collect"):
		_fail("The primary top action should be an enabled Collect Payout button during the return reward state.")
		return
	if not String(label.text).contains("Damage Payout") or not String(label.text).contains("+9 Chips"):
		_fail("Arena payout label should summarize the selected reward and chip grant.")
		return
	if not String(label.text).contains("ARENA PAYOUT READY") or not String(label.text).contains("slot/burn/upgrade"):
		_fail("Arena payout copy should explain that the next step is collecting the payout before rebuilding the next loadout.")
		return
	if not String(label.text).contains("Next arena weapon +3 damage") or not String(label.text).contains("Objective bonus +2 Chips"):
		_fail("Arena payout label should summarize concrete payout effects.")
		return
	if int(combat_scene.get("shooter_chips")) != 15:
		_fail("Arena payout should restore the previous 4 chips, add 9 payout chips, and apply +2 objective bonus.")
		return
	if int(combat_scene.get("arena_weapon_damage_bonus")) != 3:
		_fail("Damage payout should carry a weapon damage bonus into the next arena payload.")
		return
	var deck_manager: Node = combat_scene.get("deck_manager")
	var counts: Dictionary = deck_manager.call("get_counts") if deck_manager != null else {}
	if int(counts.get("hand", 0)) != 5:
		_fail("Arena payout should leave the table on a five-card next hand.")
		return
	if int(counts.get("discard", 0)) != 3 or int(counts.get("loadout", -1)) != 0:
		_fail("Arena payout should preserve piles, discard the old hand, and resolve spent loadout cards.")
		return
	var run_manager: Node = combat_scene.get("run_manager")
	var run_state: Dictionary = run_manager.call("get_state") if run_manager != null else {}
	if int(run_state.get("current_node_index", -1)) != 1:
		_fail("Arena return should restore the exact run node from before the FPS scene.")
		return

	button.emit_signal("pressed")
	await _settle()
	if bool(combat_scene.get("arena_payout_pending")):
		_fail("Start Next Hand should clear the pending arena payout.")
		return
	if panel.visible:
		_fail("Start Next Hand should hide the arena payout panel.")
		return
	if table_row != null and not table_row.visible:
		_fail("Collecting payout should restore the tactical board for the next card/loadout decision.")
		return
	if deck_panel != null and not deck_panel.visible:
		_fail("Collecting payout should restore deck/loadout controls for the next hand.")
		return

	print("PHASE69_ARENA_RETURN_CHECK: PASS")
	get_tree().quit(0)


func _build_return_state() -> Dictionary:
	return {
		"schema": 1,
		"run_flow_state": "combat",
		"run_manager": {
			"current_node_index": 1,
			"player_current_hp": 22,
			"deck_paths": [
				"res://resources/cards/quick_slash.tres",
				"res://resources/cards/low_stab.tres",
				"res://resources/cards/guard_up.tres",
				"res://resources/cards/sidestep.tres",
				"res://resources/cards/read_tell.tres",
				"res://resources/cards/false_opening.tres",
				"res://resources/cards/sure_cut.tres",
				"res://resources/cards/center_cut.tres"
			],
			"relic_paths": [],
			"pending_card_reward_paths": [],
			"pending_relic_reward_paths": [],
			"run_outcome": "running",
			"last_completed_node_name": "",
			"combats_won": 0,
			"cards_claimed": 0,
			"relics_claimed": 0,
			"damage_taken_total": 3,
			"lowest_blood": 22,
			"reward_history": [],
			"last_reward_decision": {}
		},
		"deck_manager": {
			"starting_card_paths": [
				"res://resources/cards/quick_slash.tres",
				"res://resources/cards/low_stab.tres",
				"res://resources/cards/guard_up.tres",
				"res://resources/cards/sidestep.tres",
				"res://resources/cards/read_tell.tres",
				"res://resources/cards/false_opening.tres",
				"res://resources/cards/sure_cut.tres",
				"res://resources/cards/center_cut.tres"
			],
			"shuffle_on_reset": false,
			"starting_deck_paths": [
				"res://resources/cards/quick_slash.tres",
				"res://resources/cards/low_stab.tres",
				"res://resources/cards/guard_up.tres",
				"res://resources/cards/sidestep.tres",
				"res://resources/cards/read_tell.tres",
				"res://resources/cards/false_opening.tres",
				"res://resources/cards/sure_cut.tres",
				"res://resources/cards/center_cut.tres"
			],
			"draw_pile_paths": [
				"res://resources/cards/sure_cut.tres",
				"res://resources/cards/center_cut.tres",
				"res://resources/cards/read_tell.tres",
				"res://resources/cards/guard_up.tres",
				"res://resources/cards/sidestep.tres"
			],
			"hand_paths": ["res://resources/cards/false_opening.tres"],
			"discard_pile_paths": ["res://resources/cards/low_stab.tres"],
			"exhaust_pile_paths": [],
			"loadout_pile_paths": ["res://resources/cards/quick_slash.tres"],
			"committed_card_path": ""
		},
		"shooter_chips": 4,
		"arena_carryover_armor": 0,
		"arena_carryover_ammo": 0,
		"arena_weapon_damage_bonus": 0,
		"held_hand_indices": {},
		"selected_hand_index": -1,
		"arena_bridge_payload": {},
		"arena_round_armed": true,
		"loadout_slot_paths": {"weapon": "res://resources/cards/quick_slash.tres"}
	}


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
