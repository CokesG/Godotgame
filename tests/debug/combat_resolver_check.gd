extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func _ready() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	add_child(resolver)

	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	var guard_up: Resource = load("res://resources/cards/guard_up.tres")
	var snare_card: Resource = load("res://resources/cards/snare_card.tres")

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card", guard_up)

	var state: Dictionary = resolver.call("get_state")
	var player: Dictionary = state.get("player", {})
	if int(player.get("guard", -1)) != 5:
		_fail("Guard Up should grant 5 Guard.")
		return

	resolver.call("apply_card", quick_slash)
	state = resolver.call("get_state")
	var brute: Dictionary = state.get("enemies", [])[0]
	if int(brute.get("hp", -1)) != 20:
		_fail("Quick Slash should reduce Brute HP from 24 to 20.")
		return

	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker"
	})
	state = resolver.call("get_state")
	var skulker: Dictionary = state.get("enemies", [])[1]
	if int(skulker.get("hp", -1)) != 10:
		_fail("Targeted Quick Slash should reduce Skulker HP from 14 to 10.")
		return

	resolver.call("apply_revealed_intents", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_name": "Skull Smash",
		"payload": {"damage": 8}
	}])

	state = resolver.call("get_state")
	player = state.get("player", {})
	if int(player.get("hp", -1)) != 27 or int(player.get("guard", -1)) != 0:
		_fail("Brute Smash should deal 3 through 5 Guard, leaving 27 HP and 0 Guard.")
		return

	resolver.call("apply_revealed_intents", [{
		"enemy_id": &"shieldbearer",
		"enemy_name": "Shieldbearer",
		"intent_name": "Raise Shield",
		"payload": {"guard": 9}
	}])

	state = resolver.call("get_state")
	var shieldbearer: Dictionary = state.get("enemies", [])[2]
	if int(shieldbearer.get("guard", -1)) != 9:
		_fail("Shieldbearer should gain 9 Guard.")
		return

	resolver.call("apply_card", snare_card)
	state = resolver.call("get_state")
	if int(state.get("traps_armed", -1)) != 1:
		_fail("Snare Card should arm one trap.")
		return

	for index in range(30):
		resolver.call("apply_card", quick_slash)

	state = resolver.call("get_state")
	if String(state.get("outcome", "")) != "victory":
		_fail("Expected repeated attacks to produce victory.")
		return

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_name": "Catastrophic Smash",
		"payload": {"damage": 40}
	}])

	state = resolver.call("get_state")
	if String(state.get("outcome", "")) != "defeat":
		_fail("Expected lethal enemy damage to produce defeat.")
		return

	print("COMBAT_RESOLVER_CHECK: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
