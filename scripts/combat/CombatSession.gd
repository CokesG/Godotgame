class_name CombatSession
extends Node

signal log_requested(message: String)
signal state_changed(state: Dictionary)

@export var max_energy: int = 3
@export var hand_target: int = 5

var energy: int = 3
var current_phase_key: String = "START_TURN"
var turn_number: int = 1
var combat_over: bool = false
var outcome: String = "ongoing"


func reset_session() -> void:
	energy = max_energy
	current_phase_key = "START_TURN"
	turn_number = 1
	combat_over = false
	outcome = "ongoing"
	log_requested.emit("Combat session reset. Energy: %d/%d." % [energy, max_energy])
	_emit_state()


func enter_phase(phase_key: String, new_turn_number: int) -> void:
	current_phase_key = phase_key
	turn_number = new_turn_number

	if current_phase_key == "START_TURN" and not combat_over:
		energy = max_energy
		log_requested.emit("Energy refilled to %d." % max_energy)

	_emit_state()


func can_play_cards() -> bool:
	return not combat_over and current_phase_key == "PLAYER_COMMIT"


func can_bluff() -> bool:
	return not combat_over and current_phase_key == "BLUFF_WAGER"


func can_reveal() -> bool:
	return not combat_over and current_phase_key == "REVEAL"


func can_debug_adjust() -> bool:
	return not combat_over


func can_spend_energy(cost: int) -> bool:
	return not combat_over and energy >= max(0, cost)


func spend_energy(cost: int, source: String = "Action") -> bool:
	var clean_cost: int = max(0, cost)
	if combat_over:
		log_requested.emit("Cannot spend Energy after combat ends.")
		return false

	if energy < clean_cost:
		log_requested.emit("%s needs %d Energy, but only %d remains." % [source, clean_cost, energy])
		return false

	energy -= clean_cost
	log_requested.emit("%s spent %d Energy. Energy: %d/%d." % [source, clean_cost, energy, max_energy])
	_emit_state()
	return true


func refund_energy(amount: int, source: String = "Refund") -> void:
	var clean_amount: int = max(0, amount)
	if clean_amount == 0:
		return

	energy = min(max_energy, energy + clean_amount)
	log_requested.emit("%s restored %d Energy. Energy: %d/%d." % [source, clean_amount, energy, max_energy])
	_emit_state()


func mark_combat_ended(new_outcome: String) -> void:
	combat_over = true
	outcome = new_outcome
	log_requested.emit("Combat session locked after %s." % outcome)
	_emit_state()


func get_state() -> Dictionary:
	return {
		"energy": energy,
		"max_energy": max_energy,
		"hand_target": hand_target,
		"current_phase_key": current_phase_key,
		"turn_number": turn_number,
		"combat_over": combat_over,
		"outcome": outcome
	}


func _emit_state() -> void:
	state_changed.emit(get_state())
