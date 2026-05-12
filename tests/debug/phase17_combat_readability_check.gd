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

	_verify_default_readability(combat_scene)
	if failed:
		return
	await _advance_to_commit(combat_scene)
	if failed:
		return
	_verify_commit_readability(combat_scene)
	if failed:
		return
	_verify_card_affordance(combat_scene)
	if failed:
		return

	print("PHASE17_COMBAT_READABILITY_CHECK: PASS")
	get_tree().quit(0)


func _verify_default_readability(combat_scene: Node) -> void:
	var turn_status: Node = combat_scene.find_child("TurnStatus", true, false)
	if turn_status == null:
		_fail("Expected TurnStatus readout.")
		return
	var turn_text: String = _get_text(turn_status)
	if not turn_text.contains("Balance:") or not turn_text.contains("Start Run"):
		_fail("TurnStatus should show balance and start-run feedback.")
		return

	var enemy_status: Node = combat_scene.find_child("EnemyStatus", true, false)
	if enemy_status == null:
		_fail("Expected EnemyStatus readout.")
		return
	var enemy_text: String = _get_text(enemy_status)
	if not enemy_text.contains("Blood") or not enemy_text.contains("Threat"):
		_fail("EnemyStatus should show player Blood and enemy threat.")
		return

	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	if card_hint == null:
		_fail("Expected CardActionHint readout.")
		return
	var hint_text: String = _get_text(card_hint)
	if not hint_text.contains("Target:") or not hint_text.contains("Cards wait"):
		_fail("CardActionHint should show current target and why cards are locked.")
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

	for _index in range(4):
		if _get_phase_key(combat_scene) == "PLAYER_COMMIT":
			return
		if continue_button.disabled:
			_fail("ContinueButton should stay available while advancing to Player Commit.")
			return
		continue_button.emit_signal("pressed")
		await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Expected smart flow to land on Player Commit.")


func _verify_commit_readability(combat_scene: Node) -> void:
	var turn_status: Node = combat_scene.find_child("TurnStatus", true, false)
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	var enemy_status: Node = combat_scene.find_child("EnemyStatus", true, false)
	if turn_status == null or card_hint == null or enemy_status == null:
		_fail("Expected Phase 17 readability readouts after advancing.")
		return

	var turn_text: String = _get_text(turn_status)
	if not turn_text.contains("Player Commit") or not turn_text.contains("cards are playable"):
		_fail("TurnStatus should make the Player Commit action state obvious.")
		return

	var hint_text: String = _get_text(card_hint)
	if not hint_text.contains("Cards are playable now") or not hint_text.contains("Move:"):
		_fail("CardActionHint should show card click affordance and movement target.")
		return

	var enemy_text: String = _get_text(enemy_status)
	if not enemy_text.contains("HP") or not enemy_text.contains("Threat"):
		_fail("EnemyStatus should keep HP and threat visible during commit.")
		return


func _verify_card_affordance(combat_scene: Node) -> void:
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if hand_view == null:
		_fail("Expected HandView.")
		return

	for child in hand_view.get_children():
		if child is Button:
			var card_text: String = String(child.get("text"))
			if card_text.contains("Cost") and card_text.contains("Target:"):
				return

	_fail("Expected at least one card to show cost and target affordance.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _get_phase_key(combat_scene: Node) -> String:
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		return ""
	return String(session.get("current_phase_key"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
