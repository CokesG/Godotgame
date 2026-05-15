extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]

var failed: bool = false


func _ready() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	var logs: Array[String] = []
	add_child(resolver)
	resolver.connect("log_requested", func(message: String) -> void:
		logs.append(message)
	)

	_verify_rage_damage(resolver, logs)
	if failed:
		return
	_verify_suspicion_tax(resolver, logs)
	if failed:
		return
	_verify_false_opening_bait(resolver, logs)
	if failed:
		return
	_verify_follow_up_damage(resolver, logs)
	if failed:
		return
	await _verify_grid_enemy_move()
	if failed:
		return

	print("PHASE45_GAMEPLAY_MECHANICS_CHECK: PASS")
	get_tree().quit(0)


func _verify_rage_damage(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_name": "Rage Roar",
		"payload": {"rage": 1}
	}], {})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 1,
		"payload": {"damage": 8}
	}], {"player_lane": 1})

	var player: Dictionary = resolver.call("get_state").get("player", {})
	if int(player.get("hp", -1)) != 20:
		_fail("Rage should add +2 damage to Brute Smash, leaving 20 HP.")
		return
	if not _logs_contain(logs, "cashes in Rage"):
		_fail("Expected Rage cash-in log.")


func _verify_suspicion_tax(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"shieldbearer",
		"enemy_name": "Shieldbearer",
		"intent_name": "Taunting Knock",
		"payload": {"suspicion": 1}
	}], {})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 1,
		"payload": {"damage": 8}
	}], {
		"player_lane": 1,
		"bluff_state": {
			"last_call_correct": true,
			"last_called_enemy_id": &"brute",
			"last_called_intent_id": &"brute_smash",
			"last_resolved_wager": 1
		}
	})

	var player: Dictionary = resolver.call("get_state").get("player", {})
	if int(player.get("hp", -1)) != 24:
		_fail("Suspicion should reduce 3 mitigation to 2, leaving 24 HP.")
		return
	if int(player.get("suspicion", -1)) != 0:
		_fail("Suspicion should be consumed by the call mitigation tax.")
		return
	if not _logs_contain(logs, "Suspicion cuts call mitigation"):
		_fail("Expected Suspicion mitigation log.")


func _verify_false_opening_bait(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	var false_opening: Resource = load("res://resources/cards/false_opening.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", false_opening, {"player_lane": 1})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"shieldbearer",
		"enemy_name": "Shieldbearer",
		"intent_id": &"shieldbearer_bash",
		"intent_name": "Shield Bash",
		"target_lane": 0,
		"payload": {"damage": 5}
	}], {"player_lane": 0})

	var player: Dictionary = resolver.call("get_state").get("player", {})
	if int(player.get("hp", -1)) != 30:
		_fail("False Opening should redirect the lane attack away from the player.")
		return
	if not _logs_contain(logs, "False Opening pulls"):
		_fail("Expected False Opening redirect log.")


func _verify_follow_up_damage(resolver: Node, _logs: Array[String]) -> void:
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_follow_up_damage", 2, "Hook Step follow-up", {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker"
	})
	var skulker := _get_enemy_state(resolver, &"skulker")
	if int(skulker.get("hp", -1)) != 12:
		_fail("Hook Step follow-up should deal 2 to the selected Skulker.")


func _verify_grid_enemy_move() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene for enemy movement check.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	if start_button == null or combat_grid == null:
		_fail("Expected StartRunButton and CombatGrid.")
		return

	start_button.emit_signal("pressed")
	await _settle()
	var before: Vector2i = combat_grid.call("get_unit_position", &"skulker")
	combat_scene.call("_apply_enemy_grid_moves", [{
		"enemy_id": &"skulker",
		"enemy_name": "Skulker",
		"payload": {"move": 1}
	}])
	await _settle()
	var after: Vector2i = combat_grid.call("get_unit_position", &"skulker")
	if after == before:
		_fail("Move intent should reposition Skulker on the combat grid.")


func _get_enemy_state(resolver: Node, enemy_id: StringName) -> Dictionary:
	var enemies: Array = resolver.call("get_state").get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and StringName(enemy.get("id", &"")) == enemy_id:
			return enemy
	return {}


func _logs_contain(logs: Array[String], text: String) -> bool:
	for log in logs:
		if log.contains(text):
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
