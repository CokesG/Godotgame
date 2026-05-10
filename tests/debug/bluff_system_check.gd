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
	var deck: Node = load("res://scripts/cards/DeckManager.gd").new()
	var intent_system: Node = load("res://scripts/enemies/EnemyIntentSystem.gd").new()
	var bluff: Node = load("res://scripts/combat/BluffSystem.gd").new()
	add_child(deck)
	add_child(intent_system)
	add_child(bluff)

	deck.call("configure_deck", STARTER_CARD_PATHS)
	deck.call("reset_deck")
	deck.call("draw_cards", 5)

	var committed: Resource = deck.call("commit_card_at", 0)
	if committed == null:
		_fail("Expected a card to commit.")
		return
	bluff.call("set_committed_card", committed)

	intent_system.call("configure_enemies", ENEMY_PATHS)
	intent_system.call("set_seed", 7)
	intent_system.call("roll_intents")

	var truth: Array = intent_system.call("get_debug_truth")
	if truth.is_empty():
		_fail("Expected debug truth entries.")
		return

	var entry: Dictionary = truth[0]
	bluff.call("set_call",
		StringName(entry.get("enemy_id", &"")),
		String(entry.get("enemy_name", "Enemy")),
		StringName(entry.get("intent_id", &"")),
		String(entry.get("intent_name", "Intent")),
		int(entry.get("target_lane", -1))
	)

	if not bool(bluff.call("raise_wager", 1)):
		_fail("Expected raise to succeed.")
		return

	var raised_state: Dictionary = bluff.call("get_state")
	if int(raised_state.get("nerve", -1)) != 2 or int(raised_state.get("current_wager", -1)) != 1:
		_fail("Expected raise to spend 1 Nerve and set wager to 1.")
		return

	var revealed: Array = intent_system.call("reveal_intents")
	bluff.call("reveal", revealed)
	deck.call("resolve_committed_card")

	var success_state: Dictionary = bluff.call("get_state")
	if int(success_state.get("nerve", -1)) != 5:
		_fail("Expected correct call payout to leave 5 Nerve, got %d." % int(success_state.get("nerve", -1)))
		return

	var counts_after_success: Dictionary = deck.call("get_counts")
	if int(counts_after_success.get("committed", -1)) != 0:
		_fail("Expected committed card to clear after reveal.")
		return

	deck.call("reset_deck")
	deck.call("draw_cards", 5)
	bluff.call("reset_bluff")

	var folded_card: Resource = deck.call("commit_card_at", 0)
	if folded_card == null:
		_fail("Expected a card to commit before folding.")
		return
	bluff.call("set_committed_card", folded_card)

	if not bool(bluff.call("fold")):
		_fail("Expected fold to succeed.")
		return
	deck.call("fold_committed_card")

	var fold_state: Dictionary = bluff.call("get_state")
	if int(fold_state.get("nerve", -1)) != 2:
		_fail("Expected fold penalty to leave 2 Nerve.")
		return

	var counts_after_fold: Dictionary = deck.call("get_counts")
	if int(counts_after_fold.get("discard", -1)) != 1 or int(counts_after_fold.get("committed", -1)) != 0:
		_fail("Expected folded card in discard and no committed card.")
		return

	print("BLUFF_SYSTEM_CHECK: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
