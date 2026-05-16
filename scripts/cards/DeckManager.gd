class_name DeckManager
extends Node

signal log_requested(message: String)
signal hand_changed(cards: Array[Resource])
signal piles_changed(counts: Dictionary)
signal card_played(card: Resource)
signal committed_card_changed(card: Resource)

@export var starting_card_paths: Array[String] = []
@export var shuffle_on_reset: bool = false

var starting_deck: Array[Resource] = []
var draw_pile: Array[Resource] = []
var hand: Array[Resource] = []
var discard_pile: Array[Resource] = []
var exhaust_pile: Array[Resource] = []
var loadout_pile: Array[Resource] = []
var committed_card: Resource


func configure_deck(card_paths: Array) -> void:
	starting_card_paths.clear()
	for path in card_paths:
		starting_card_paths.append(String(path))
	load_starting_deck()


func load_starting_deck() -> void:
	starting_deck.clear()

	for path in starting_card_paths:
		var card := load(path)
		if card == null:
			log_requested.emit("Failed to load card resource: %s" % path)
			continue
		starting_deck.append(card)

	log_requested.emit("Loaded %d cards into the starting deck." % starting_deck.size())
	_emit_state()


func reset_deck() -> void:
	if starting_deck.is_empty():
		load_starting_deck()

	draw_pile = starting_deck.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	loadout_pile.clear()
	committed_card = null

	if shuffle_on_reset:
		draw_pile.shuffle()

	log_requested.emit("Deck reset. Draw pile has %d cards." % draw_pile.size())
	_emit_state()


func draw_cards(amount: int) -> Array[Resource]:
	var drawn: Array[Resource] = []

	for index in range(amount):
		if draw_pile.is_empty():
			_reshuffle_discard_into_draw()

		if draw_pile.is_empty():
			log_requested.emit("No cards left to draw.")
			break

		var card: Resource = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
		log_requested.emit("Drew %s." % _get_card_name(card))

	_emit_state()
	return drawn


func play_card_at(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		log_requested.emit("Cannot play card at hand index %d." % hand_index)
		return false

	var card: Resource = hand[hand_index]
	hand.remove_at(hand_index)

	if _card_should_exhaust(card):
		exhaust_pile.append(card)
		log_requested.emit("Played %s. It exhausts." % _get_card_name(card))
	else:
		discard_pile.append(card)
		log_requested.emit("Played %s. It goes to discard." % _get_card_name(card))

	card_played.emit(card)
	_emit_state()
	return true


func burn_card_at(hand_index: int) -> Resource:
	if hand_index < 0 or hand_index >= hand.size():
		log_requested.emit("Cannot burn card at hand index %d." % hand_index)
		return null

	var card: Resource = hand[hand_index]
	hand.remove_at(hand_index)
	exhaust_pile.append(card)
	log_requested.emit("Burned %s." % _get_card_name(card))
	_emit_state()
	return card


func slot_card_at(hand_index: int) -> Resource:
	if hand_index < 0 or hand_index >= hand.size():
		log_requested.emit("Cannot slot card at hand index %d." % hand_index)
		return null

	var card: Resource = hand[hand_index]
	hand.remove_at(hand_index)
	loadout_pile.append(card)
	log_requested.emit("Slotted %s into loadout." % _get_card_name(card))
	_emit_state()
	return card


func replace_loadout_card_at(hand_index: int, replaced_card: Resource) -> Resource:
	if hand_index < 0 or hand_index >= hand.size():
		log_requested.emit("Cannot slot card at hand index %d." % hand_index)
		return null

	var card: Resource = hand[hand_index]
	hand.remove_at(hand_index)

	var returned_name := ""
	if replaced_card != null:
		var loadout_index := loadout_pile.find(replaced_card)
		if loadout_index >= 0:
			loadout_pile.remove_at(loadout_index)
			hand.append(replaced_card)
			returned_name = _get_card_name(replaced_card)

	loadout_pile.append(card)
	if returned_name.is_empty():
		log_requested.emit("Slotted %s into loadout." % _get_card_name(card))
	else:
		log_requested.emit("Replaced %s with %s in loadout." % [returned_name, _get_card_name(card)])
	_emit_state()
	return card


func commit_card_at(hand_index: int) -> Resource:
	if committed_card != null:
		log_requested.emit("A card is already committed face-down.")
		return null

	if hand_index < 0 or hand_index >= hand.size():
		log_requested.emit("Cannot commit card at hand index %d." % hand_index)
		return null

	committed_card = hand[hand_index]
	hand.remove_at(hand_index)
	log_requested.emit("Committed a card face-down.")
	_emit_state()
	return committed_card


func fold_committed_card() -> Resource:
	if committed_card == null:
		log_requested.emit("No committed card to fold.")
		return null

	var folded_card := committed_card
	discard_pile.append(folded_card)
	committed_card = null
	log_requested.emit("Folded %s into discard." % _get_card_name(folded_card))
	_emit_state()
	return folded_card


func resolve_committed_card() -> Resource:
	if committed_card == null:
		log_requested.emit("No committed card to resolve.")
		return null

	var resolved_card := committed_card
	committed_card = null

	if _card_should_exhaust(resolved_card):
		exhaust_pile.append(resolved_card)
		log_requested.emit("Resolved %s. It exhausts." % _get_card_name(resolved_card))
	else:
		discard_pile.append(resolved_card)
		log_requested.emit("Resolved %s into discard." % _get_card_name(resolved_card))

	_emit_state()
	return resolved_card


func discard_hand() -> void:
	if hand.is_empty():
		log_requested.emit("No cards in hand to discard.")
		return

	var count := hand.size()
	discard_pile.append_array(hand)
	hand.clear()
	log_requested.emit("Discarded %d cards from hand." % count)
	_emit_state()


func resolve_loadout_pile() -> Array[Resource]:
	var resolved: Array[Resource] = []
	if loadout_pile.is_empty():
		log_requested.emit("No loadout cards to resolve.")
		return resolved

	for card in loadout_pile:
		if card == null:
			continue
		resolved.append(card)
		if _card_should_exhaust(card):
			exhaust_pile.append(card)
		else:
			discard_pile.append(card)
	var count := resolved.size()
	loadout_pile.clear()
	log_requested.emit("Resolved %d loadout card%s after arena combat." % [count, "" if count == 1 else "s"])
	_emit_state()
	return resolved


func get_counts() -> Dictionary:
	return {
		"draw": draw_pile.size(),
		"hand": hand.size(),
		"discard": discard_pile.size(),
		"exhaust": exhaust_pile.size(),
		"loadout": loadout_pile.size(),
		"committed": 1 if committed_card != null else 0
	}


func get_hand_snapshot() -> Array[Resource]:
	var snapshot: Array[Resource] = []
	for card in hand:
		if card != null:
			snapshot.append(card)
	return snapshot


func get_snapshot() -> Dictionary:
	return {
		"starting_card_paths": starting_card_paths.duplicate(),
		"shuffle_on_reset": shuffle_on_reset,
		"starting_deck_paths": _cards_to_paths(starting_deck),
		"draw_pile_paths": _cards_to_paths(draw_pile),
		"hand_paths": _cards_to_paths(hand),
		"discard_pile_paths": _cards_to_paths(discard_pile),
		"exhaust_pile_paths": _cards_to_paths(exhaust_pile),
		"loadout_pile_paths": _cards_to_paths(loadout_pile),
		"committed_card_path": _card_to_path(committed_card)
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return

	starting_card_paths = _string_array(snapshot.get("starting_card_paths", []))
	shuffle_on_reset = bool(snapshot.get("shuffle_on_reset", shuffle_on_reset))
	starting_deck = _load_cards_from_paths(snapshot.get("starting_deck_paths", starting_card_paths))
	draw_pile = _load_cards_from_paths(snapshot.get("draw_pile_paths", []))
	hand = _load_cards_from_paths(snapshot.get("hand_paths", []))
	discard_pile = _load_cards_from_paths(snapshot.get("discard_pile_paths", []))
	exhaust_pile = _load_cards_from_paths(snapshot.get("exhaust_pile_paths", []))
	loadout_pile = _load_cards_from_paths(snapshot.get("loadout_pile_paths", []))
	committed_card = _load_card_from_path(String(snapshot.get("committed_card_path", "")))
	log_requested.emit("Deck restored from arena return state.")
	_emit_state()


func get_hand_count() -> int:
	return hand.size()


func get_card_at(hand_index: int) -> Resource:
	if hand_index < 0 or hand_index >= hand.size():
		return null
	return hand[hand_index]


func get_committed_card() -> Resource:
	return committed_card


func has_committed_card() -> bool:
	return committed_card != null


func _reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return

	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
	log_requested.emit("Shuffled discard pile into draw pile.")


func _card_should_exhaust(card: Resource) -> bool:
	var tags: Array = card.get("tags")
	return tags.has(&"exhaust")


func _get_card_name(card: Resource) -> String:
	if card.has_method("get_display_name"):
		return String(card.call("get_display_name"))
	return String(card.get("display_name"))


func _cards_to_paths(cards: Array[Resource]) -> Array[String]:
	var paths: Array[String] = []
	for card in cards:
		var path := _card_to_path(card)
		if not path.is_empty():
			paths.append(path)
	return paths


func _card_to_path(card: Resource) -> String:
	if card == null:
		return ""
	return String(card.resource_path)


func _load_cards_from_paths(paths_value: Variant) -> Array[Resource]:
	var cards: Array[Resource] = []
	for path in paths_value:
		var card := _load_card_from_path(String(path))
		if card != null:
			cards.append(card)
	return cards


func _load_card_from_path(path: String) -> Resource:
	if path.is_empty():
		return null
	var card := load(path)
	if card == null:
		log_requested.emit("Failed to restore card resource: %s" % path)
	return card


func _string_array(values: Variant) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings


func _emit_state() -> void:
	hand_changed.emit(get_hand_snapshot())
	piles_changed.emit(get_counts())
	committed_card_changed.emit(committed_card)
