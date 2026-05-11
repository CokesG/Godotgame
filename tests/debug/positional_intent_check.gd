extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func _ready() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	var logs: Array[String] = []
	add_child(resolver)
	resolver.connect("log_requested", func(message: String) -> void:
		logs.append(message)
	)

	_verify_center_lane_hit(resolver, logs)
	_verify_lane_miss(resolver, logs)
	_verify_tracking_hit(resolver, logs)
	_verify_call_mitigation(resolver, logs)
	_verify_trap_trigger(resolver, logs)

	print("POSITIONAL_INTENT_CHECK: PASS")
	get_tree().quit(0)


func _verify_center_lane_hit(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [_brute_smash_entry()], {
		"player_lane": 1
	})

	var player: Dictionary = _get_player_state(resolver)
	if int(player.get("hp", -1)) != 22:
		_fail("Brute Smash should hit center lane player for 8 damage.")
		return
	if not _logs_contain(logs, "hits lane Center"):
		_fail("Expected center lane hit log.")
		return


func _verify_lane_miss(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [_brute_smash_entry()], {
		"player_lane": 0
	})

	var player: Dictionary = _get_player_state(resolver)
	if int(player.get("hp", -1)) != 30:
		_fail("Brute Smash should miss when player leaves center lane.")
		return
	if not _logs_contain(logs, "misses lane Center"):
		_fail("Expected center lane miss log.")
		return


func _verify_tracking_hit(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [_skulker_tracking_entry()], {
		"player_lane": 2
	})

	var player: Dictionary = _get_player_state(resolver)
	if int(player.get("hp", -1)) != 26:
		_fail("Tracking attack should hit regardless of player lane.")
		return
	if not _logs_contain(logs, "tracks the player"):
		_fail("Expected tracking hit log.")
		return


func _verify_call_mitigation(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [_brute_smash_entry()], {
		"player_lane": 1,
		"bluff_state": {
			"last_call_correct": true,
			"last_called_enemy_id": &"brute",
			"last_called_intent_id": &"brute_smash",
			"last_resolved_wager": 1
		}
	})

	var player: Dictionary = _get_player_state(resolver)
	if int(player.get("hp", -1)) != 25:
		_fail("Correct Call + Raise should reduce 8 damage by 3, leaving 25 HP.")
		return
	if not _logs_contain(logs, "Called read reduces incoming damage by 3"):
		_fail("Expected call mitigation log.")
		return


func _verify_trap_trigger(resolver: Node, logs: Array[String]) -> void:
	logs.clear()
	var snare_card: Resource = load("res://resources/cards/snare_card.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", snare_card, {
		"target_cell": Vector2i(1, 1),
		"target_cell_label": "(1,1)"
	})
	resolver.call("apply_revealed_intents_with_context", [_brute_smash_entry()], {
		"player_lane": 0
	})

	var brute: Dictionary = _get_enemy_state(resolver, &"brute")
	if int(brute.get("hp", -1)) != 19:
		_fail("Snare trap should deal 3 damage to Brute when it targets trapped center lane.")
		return

	var state: Dictionary = resolver.call("get_state")
	if int(state.get("traps_armed", -1)) != 0:
		_fail("Snare trap should be consumed after triggering.")
		return
	if not _logs_contain(logs, "Snare trap at (1,1) catches Brute"):
		_fail("Expected trap trigger log.")
		return


func _brute_smash_entry() -> Dictionary:
	return {
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 1,
		"payload": {"damage": 8}
	}


func _skulker_tracking_entry() -> Dictionary:
	return {
		"enemy_id": &"skulker",
		"enemy_name": "Skulker",
		"intent_id": &"skulker_cut",
		"intent_name": "Cut Purse",
		"target_lane": -1,
		"payload": {"damage": 4}
	}


func _get_player_state(resolver: Node) -> Dictionary:
	var state: Dictionary = resolver.call("get_state")
	return state.get("player", {})


func _get_enemy_state(resolver: Node, enemy_id: StringName) -> Dictionary:
	var state: Dictionary = resolver.call("get_state")
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and StringName(enemy.get("id", &"")) == enemy_id:
			return enemy
	return {}


func _logs_contain(logs: Array[String], text: String) -> bool:
	for log in logs:
		if log.contains(text):
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
