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


func _ready() -> void:
	var deck_script: Script = load("res://scripts/cards/DeckManager.gd")
	var deck: Node = deck_script.new()
	deck.shuffle_on_reset = false
	add_child(deck)

	deck.call("configure_deck", STARTER_CARD_PATHS)
	deck.call("reset_deck")
	deck.call("draw_cards", 5)

	if not _expect_counts(deck, 5, 5, 0, 0, "opening draw"):
		return

	if not bool(deck.call("play_card_at", 0)):
		_fail("Expected first card to play.")
		return

	if not _expect_counts(deck, 5, 4, 0, 1, "blood ritual exhaust"):
		return

	if not bool(deck.call("play_card_at", 0)):
		_fail("Expected second card to play.")
		return

	if not _expect_counts(deck, 5, 3, 1, 1, "second card discard"):
		return

	deck.call("discard_hand")
	if not _expect_counts(deck, 5, 0, 4, 1, "discard remaining hand"):
		return

	deck.call("draw_cards", 5)
	if not _expect_counts(deck, 0, 5, 4, 1, "draw remaining pile"):
		return

	deck.call("draw_cards", 1)
	if not _expect_counts(deck, 3, 6, 0, 1, "forced discard reshuffle"):
		return

	print("DECK_MANAGER_CHECK: PASS")
	deck.free()
	get_tree().quit(0)


func _expect_counts(deck: Node, draw_count: int, hand_count: int, discard_count: int, exhaust_count: int, label: String) -> bool:
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
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
