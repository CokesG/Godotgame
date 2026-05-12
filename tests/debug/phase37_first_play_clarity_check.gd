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

	_verify_opening_step(combat_scene)
	if failed:
		return
	await _verify_begin_turn_step(combat_scene)
	if failed:
		return
	await _verify_commit_step(combat_scene)
	if failed:
		return
	await _verify_target_focus(combat_scene)
	if failed:
		return

	print("PHASE37_FIRST_PLAY_CLARITY_CHECK: PASS")
	get_tree().quit(0)


func _verify_opening_step(combat_scene: Node) -> void:
	var first_play_path: Node = combat_scene.find_child("FirstPlayPath", true, false)
	var action_prompt: Node = combat_scene.find_child("ActionPrompt", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if first_play_path == null or action_prompt == null or start_button == null or hand_view == null:
		_fail("Expected first-play guidance, start button, and hand.")
		return
	if hand_view.get_child_count() == 0:
		_fail("Expected opening hand cards.")
		return

	var path_text: String = _get_text(first_play_path)
	if not path_text.contains("ACTIVE: 1 Open Table") or not path_text.contains("2 Pick Target") or not path_text.contains("4 Resolve Turn"):
		_fail("FirstPlayPath should show the full first-play sequence and active open-table step.")
		return
	if not _get_text(action_prompt).contains("Open Opening Table") or not _get_text(action_prompt).contains("pick Target"):
		_fail("ActionPrompt should explain the first click and the next few actions.")
		return
	if not start_button.tooltip_text.contains("Dominant next action"):
		_fail("StartRunButton should be styled as the dominant next action.")
		return

	var first_card: Button = hand_view.get_child(0)
	if not bool(first_card.get("disabled")) or not first_card.tooltip_text.contains("Open Opening Table"):
		_fail("Opening hand cards should be visibly locked until the table opens.")


func _verify_begin_turn_step(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var first_play_path: Node = combat_scene.find_child("FirstPlayPath", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if start_button == null or continue_button == null or first_play_path == null or hand_view == null:
		_fail("Expected start, continue, path, and hand nodes.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if not bool(continue_button.get("visible")) or bool(continue_button.get("disabled")):
		_fail("ContinueButton should become the live Begin Turn action after opening the table.")
		return
	if String(continue_button.get("text")) != "Begin Turn" or not continue_button.tooltip_text.contains("Dominant next action"):
		_fail("ContinueButton should clearly be the dominant Begin Turn action.")
		return
	if not _get_text(first_play_path).contains("ACTIVE: Begin Turn"):
		_fail("FirstPlayPath should move to the Begin Turn step after opening.")
		return

	var first_card: Button = hand_view.get_child(0)
	if not bool(first_card.get("disabled")) or not first_card.tooltip_text.contains("Begin Turn"):
		_fail("Hand cards should stay locked with a Begin Turn hint before Player Commit.")


func _verify_commit_step(combat_scene: Node) -> void:
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var first_play_path: Node = combat_scene.find_child("FirstPlayPath", true, false)
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if continue_button == null or first_play_path == null or card_hint == null or hand_view == null:
		_fail("Expected commit-step controls and readouts.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Begin Turn should land on Player Commit.")
		return
	if not _get_text(first_play_path).contains("ACTIVE: 2 Pick Target -> 3 Play Card"):
		_fail("FirstPlayPath should show target/card as the active commit step.")
		return
	var hint_text: String = _get_text(card_hint)
	if not hint_text.contains("Step 2") or not hint_text.contains("Step 3") or not hint_text.contains("Step 4"):
		_fail("CardActionHint should show the pick-target, play-card, resolve-turn sequence.")
		return

	var first_card: Button = hand_view.get_child(0)
	if bool(first_card.get("disabled")) or not first_card.tooltip_text.contains("Click to play"):
		_fail("Playable commit cards should unlock and advertise click-to-play.")
		return
	if not continue_button.tooltip_text.contains("Pick Target or Move"):
		_fail("Resolve Turn button should explain the target/card prerequisite.")


func _verify_target_focus(combat_scene: Node) -> void:
	var target_enemy: OptionButton = combat_scene.find_child("TargetEnemyOption", true, false)
	var move_target: OptionButton = combat_scene.find_child("MovementCellOption", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	var cells: Node = combat_scene.find_child("Cells", true, false)
	var deck_manager: Node = combat_scene.find_child("DeckManager", true, false)
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if target_enemy == null or move_target == null or combat_grid == null or cells == null:
		_fail("Expected target controls and combat grid.")
		return
	if deck_manager == null or hand_view == null:
		_fail("Expected deck manager and hand view.")
		return

	var selected_target: Dictionary = target_enemy.get_item_metadata(target_enemy.selected)
	var focus: Dictionary = combat_grid.call("get_focus_snapshot")
	if String(focus.get("type", "")) != "unit" or StringName(focus.get("unit_id", &"")) != StringName(selected_target.get("id", &"")):
		_fail("Grid focus should follow the selected enemy target.")
		return
	if _find_focus_cell(cells) == null:
		_fail("A grid cell should expose the active enemy target highlight.")
		return

	deck_manager.call("configure_deck", ["res://resources/cards/sidestep.tres"])
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", 1)
	await get_tree().process_frame

	if hand_view.get_child_count() == 0:
		_fail("Expected a movement card for focus testing.")
		return
	var card_button: Button = hand_view.get_child(0)
	card_button.emit_signal("card_hovered", 0)
	await get_tree().process_frame

	var selected_cell: Vector2i = move_target.get_item_metadata(move_target.selected)
	focus = combat_grid.call("get_focus_snapshot")
	if String(focus.get("type", "")) != "cell" or Vector2i(focus.get("cell", Vector2i(-1, -1))) != selected_cell:
		_fail("Grid focus should move to the selected Move cell when hovering a movement card.")
		return

	var focus_cell: Node = _find_focus_cell(cells)
	if focus_cell == null or not String(focus_cell.get("tooltip_text")).contains("Active target"):
		_fail("Focused move cell should show an active-target tooltip.")


func _find_focus_cell(cells: Node) -> Node:
	for child in cells.get_children():
		if bool(child.get("is_focus_target")):
			return child
	return null


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
