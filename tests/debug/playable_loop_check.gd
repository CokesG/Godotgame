extends Node

const STARTER_CARD_PATHS := [
	"res://resources/cards/quick_slash.tres",
	"res://resources/cards/low_stab.tres",
	"res://resources/cards/guard_up.tres",
	"res://resources/cards/iron_vow.tres",
	"res://resources/cards/sidestep.tres",
	"res://resources/cards/hook_step.tres",
	"res://resources/cards/read_tell.tres",
	"res://resources/cards/false_opening.tres",
	"res://resources/cards/snare_card.tres",
	"res://resources/cards/blood_ritual.tres"
]
const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func _ready() -> void:
	var session: Node = load("res://scripts/combat/CombatSession.gd").new()
	var deck: Node = load("res://scripts/cards/DeckManager.gd").new()
	var intents: Node = load("res://scripts/enemies/EnemyIntentSystem.gd").new()
	var bluff: Node = load("res://scripts/combat/BluffSystem.gd").new()
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	add_child(session)
	add_child(deck)
	add_child(intents)
	add_child(bluff)
	add_child(resolver)

	session.call("reset_session")
	deck.call("configure_deck", STARTER_CARD_PATHS)
	deck.call("reset_deck")
	resolver.call("reset_combat", ENEMY_PATHS)
	intents.call("configure_enemies", ENEMY_PATHS)
	bluff.call("reset_bluff")

	session.call("enter_phase", "DRAW", 1)
	deck.call("draw_cards", session.get("hand_target"))
	if not _expect_counts(deck, 5, 5, 0, 0, 0, "opening draw"):
		return

	session.call("enter_phase", "ENEMY_INTENT_PREVIEW", 1)
	intents.call("roll_intents")
	var previews: Array = intents.call("get_public_previews")
	if previews.size() != 3:
		_fail("Expected three enemy intent previews.")
		return

	session.call("enter_phase", "PLAYER_COMMIT", 1)
	var committed_card: Resource = deck.call("get_card_at", 0)
	var committed_cost := int(committed_card.get("cost"))
	if not bool(session.call("spend_energy", committed_cost, "Commit test card")):
		_fail("Expected enough Energy to commit the first card.")
		return

	var committed: Resource = deck.call("commit_card_at", 0)
	if committed == null:
		_fail("Expected first hand card to commit.")
		return
	bluff.call("set_committed_card", committed)

	var playable_card: Resource = deck.call("get_card_at", 0)
	var playable_cost := int(playable_card.get("cost"))
	if not bool(session.call("spend_energy", playable_cost, "Play test card")):
		_fail("Expected enough Energy to play a card after committing.")
		return
	if not bool(deck.call("play_card_at", 0)):
		_fail("Expected card play to succeed.")
		return
	resolver.call("apply_card", playable_card)

	var session_state: Dictionary = session.call("get_state")
	var expected_energy: int = int(session.get("max_energy")) - committed_cost - playable_cost
	if int(session_state.get("energy", -1)) != expected_energy:
		_fail("Expected Energy to fall to %d after commit and play costs." % expected_energy)
		return

	session.call("enter_phase", "BLUFF_WAGER", 1)
	var first_preview: Dictionary = previews[0]
	var first_options: Array = first_preview.get("options", [])
	if first_options.is_empty():
		_fail("Expected first enemy preview to include options.")
		return
	var first_option: Dictionary = first_options[0]
	bluff.call("set_call",
		StringName(first_preview.get("enemy_id", &"")),
		String(first_preview.get("enemy_name", "Enemy")),
		StringName(first_option.get("intent_id", &"")),
		String(first_option.get("intent_name", "Intent")),
		-1
	)
	if not bool(bluff.call("raise_wager", 1)):
		_fail("Expected Raise +1 to spend Nerve.")
		return

	session.call("enter_phase", "REVEAL", 1)
	var revealed: Array = intents.call("reveal_intents")
	bluff.call("reveal", revealed)
	var resolved_card: Resource = deck.call("resolve_committed_card")
	if resolved_card == null:
		_fail("Expected committed card to resolve during Reveal.")
		return
	resolver.call("apply_card", resolved_card)
	resolver.call("apply_revealed_intents", revealed)

	var resolver_state: Dictionary = resolver.call("get_state")
	var player: Dictionary = resolver_state.get("player", {})
	if int(player.get("hp", -1)) < 0 or String(resolver_state.get("outcome", "")) == "":
		_fail("Expected resolver state to remain readable after reveal.")
		return

	session.call("enter_phase", "CLEANUP", 1)
	deck.call("discard_hand")
	if not _expect_counts(deck, 5, 0, 4, 1, 0, "cleanup"):
		return

	session.call("enter_phase", "START_TURN", 2)
	session_state = session.call("get_state")
	if int(session_state.get("energy", -1)) != int(session.get("max_energy")):
		_fail("Expected Energy refill at next Start Turn.")
		return

	print("PLAYABLE_LOOP_CHECK: PASS")
	get_tree().quit(0)


func _expect_counts(deck: Node, draw_count: int, hand_count: int, discard_count: int, exhaust_count: int, committed_count: int, label: String) -> bool:
	var counts: Dictionary = deck.call("get_counts")
	if counts.get("draw", -1) != draw_count:
		_fail("%s expected draw %d but got %d." % [label, draw_count, counts.get("draw", -1)])
		return false
	if counts.get("hand", -1) != hand_count:
		_fail("%s expected hand %d but got %d." % [label, hand_count, counts.get("hand", -1)])
		return false
	if counts.get("discard", -1) != discard_count:
		_fail("%s expected discard %d but got %d." % [label, discard_count, counts.get("discard", -1)])
		return false
	if counts.get("exhaust", -1) != exhaust_count:
		_fail("%s expected exhaust %d but got %d." % [label, exhaust_count, counts.get("exhaust", -1)])
		return false
	if counts.get("committed", -1) != committed_count:
		_fail("%s expected committed %d but got %d." % [label, committed_count, counts.get("committed", -1)])
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
