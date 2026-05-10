class_name BluffSystem
extends Node

signal log_requested(message: String)
signal state_changed(state: Dictionary)

@export var starting_nerve: int = 3

var nerve: int = 3
var current_wager: int = 0
var committed_card: Resource
var called_enemy_id: StringName = &""
var called_enemy_name: String = ""
var called_intent_id: StringName = &""
var called_intent_name: String = ""
var called_lane: int = -1
var last_result: String = ""


func _ready() -> void:
	reset_bluff()


func reset_bluff() -> void:
	nerve = starting_nerve
	current_wager = 0
	committed_card = null
	clear_call(false)
	last_result = "No call resolved yet."
	log_requested.emit("Bluff state reset. Nerve: %d." % nerve)
	_emit_state()


func set_committed_card(card: Resource) -> void:
	committed_card = card
	current_wager = 0
	last_result = "Committed %s face-down." % _get_card_name(card)
	log_requested.emit(last_result)
	_emit_state()


func clear_committed_card() -> void:
	committed_card = null
	current_wager = 0
	_emit_state()


func set_call(enemy_id: StringName, enemy_name: String, intent_id: StringName, intent_name: String, lane: int) -> void:
	called_enemy_id = enemy_id
	called_enemy_name = enemy_name
	called_intent_id = intent_id
	called_intent_name = intent_name
	called_lane = lane
	log_requested.emit("Call set: %s will use %s%s." % [
		called_enemy_name,
		called_intent_name,
		_get_lane_suffix(called_lane)
	])
	_emit_state()


func clear_call(emit_log: bool = true) -> void:
	called_enemy_id = &""
	called_enemy_name = ""
	called_intent_id = &""
	called_intent_name = ""
	called_lane = -1
	if emit_log:
		log_requested.emit("Call cleared.")
	_emit_state()


func raise_wager(amount: int = 1) -> bool:
	if committed_card == null:
		log_requested.emit("Commit a card before raising.")
		return false

	if amount <= 0:
		log_requested.emit("Raise amount must be positive.")
		return false

	if nerve < amount:
		log_requested.emit("Not enough Nerve to raise by %d." % amount)
		return false

	nerve -= amount
	current_wager += amount
	log_requested.emit("Raised by %d Nerve. Current wager: %d. Nerve left: %d." % [amount, current_wager, nerve])
	_emit_state()
	return true


func fold() -> bool:
	if committed_card == null:
		log_requested.emit("No committed card to fold.")
		return false

	var penalty := 1 if nerve > 0 else 0
	nerve -= penalty
	last_result = "Folded %s. Lost %d Nerve and avoided reveal risk." % [_get_card_name(committed_card), penalty]
	log_requested.emit(last_result)
	committed_card = null
	current_wager = 0
	clear_call(false)
	_emit_state()
	return true


func reveal(revealed_intents: Array) -> Dictionary:
	if committed_card == null:
		last_result = "Reveal resolved without a committed card."
		log_requested.emit(last_result)
		_emit_state()
		return get_state()

	if called_enemy_id.is_empty() or called_intent_id.is_empty():
		last_result = "Reveal exposed %s without a call. No payoff." % _get_card_name(committed_card)
		log_requested.emit(last_result)
		committed_card = null
		current_wager = 0
		_emit_state()
		return get_state()

	var matched_entry := _find_revealed_entry(revealed_intents, called_enemy_id)
	if matched_entry.is_empty():
		last_result = "Reveal could not find %s. Wager lost." % called_enemy_name
		log_requested.emit(last_result)
		committed_card = null
		current_wager = 0
		_emit_state()
		return get_state()

	var correct := _call_matches(matched_entry)
	if correct:
		var payout := 1 + current_wager * 2
		nerve += payout
		last_result = "CALL CORRECT: %s revealed %s%s. %s pays out %d Nerve." % [
			called_enemy_name,
			matched_entry.get("intent_name", "Unknown"),
			_get_lane_suffix(int(matched_entry.get("target_lane", -1))),
			_get_card_name(committed_card),
			payout
		]
	else:
		last_result = "CALL MISSED: %s revealed %s%s. %s fizzles and the wager is lost." % [
			called_enemy_name,
			matched_entry.get("intent_name", "Unknown"),
			_get_lane_suffix(int(matched_entry.get("target_lane", -1))),
			_get_card_name(committed_card)
		]

	log_requested.emit(last_result)
	committed_card = null
	current_wager = 0
	clear_call(false)
	_emit_state()
	return get_state()


func get_state() -> Dictionary:
	return {
		"nerve": nerve,
		"current_wager": current_wager,
		"committed_card_name": _get_card_name(committed_card) if committed_card != null else "None",
		"has_committed_card": committed_card != null,
		"called_enemy_id": called_enemy_id,
		"called_enemy_name": called_enemy_name if not called_enemy_name.is_empty() else "None",
		"called_intent_id": called_intent_id,
		"called_intent_name": called_intent_name if not called_intent_name.is_empty() else "None",
		"called_lane": called_lane,
		"call_summary": _get_call_summary(),
		"last_result": last_result
	}


func _find_revealed_entry(revealed_intents: Array, enemy_id: StringName) -> Dictionary:
	for entry in revealed_intents:
		if StringName(entry.get("enemy_id", &"")) == enemy_id:
			return entry
	return {}


func _call_matches(revealed_entry: Dictionary) -> bool:
	if StringName(revealed_entry.get("intent_id", &"")) != called_intent_id:
		return false

	if called_lane >= 0 and int(revealed_entry.get("target_lane", -1)) != called_lane:
		return false

	return true


func _get_card_name(card: Resource) -> String:
	if card == null:
		return "None"
	if card.has_method("get_display_name"):
		return String(card.call("get_display_name"))
	return String(card.get("display_name"))


func _get_call_summary() -> String:
	if called_enemy_id.is_empty() or called_intent_id.is_empty():
		return "No call set."
	return "%s -> %s%s" % [called_enemy_name, called_intent_name, _get_lane_suffix(called_lane)]


func _get_lane_suffix(lane: int) -> String:
	if lane < 0:
		return ""
	return " in lane %d" % lane


func _emit_state() -> void:
	state_changed.emit(get_state())
