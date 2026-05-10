class_name TurnManager
extends Node

signal phase_changed(new_phase: Phase)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal log_requested(message: String)

enum Phase {
	START_TURN,
	DRAW,
	ENEMY_INTENT_PREVIEW,
	PLAYER_COMMIT,
	BLUFF_WAGER,
	REVEAL,
	RESOLVE,
	CLEANUP
}

@export var auto_start: bool = true

var current_phase: Phase = Phase.START_TURN
var turn_number: int = 0


func _ready() -> void:
	if auto_start:
		reset_combat()


func reset_combat() -> void:
	turn_number = 1
	current_phase = Phase.START_TURN
	log_requested.emit("Combat reset.")
	turn_started.emit(turn_number)
	log_requested.emit("Turn %d started." % turn_number)
	_emit_phase_changed()


func advance_phase() -> void:
	if current_phase == Phase.CLEANUP:
		turn_ended.emit(turn_number)
		log_requested.emit("Turn %d ended." % turn_number)
		turn_number += 1
		current_phase = Phase.START_TURN
		turn_started.emit(turn_number)
		log_requested.emit("Turn %d started." % turn_number)
	else:
		current_phase = Phase.values()[current_phase + 1]

	_emit_phase_changed()


func get_current_phase_display() -> String:
	return get_phase_display(current_phase)


func get_phase_display(phase: Phase) -> String:
	match phase:
		Phase.START_TURN:
			return "Start Turn"
		Phase.DRAW:
			return "Draw"
		Phase.ENEMY_INTENT_PREVIEW:
			return "Enemy Intent Preview"
		Phase.PLAYER_COMMIT:
			return "Player Commit"
		Phase.BLUFF_WAGER:
			return "Bluff Wager"
		Phase.REVEAL:
			return "Reveal"
		Phase.RESOLVE:
			return "Resolve"
		Phase.CLEANUP:
			return "Cleanup"
		_:
			return "Unknown"


func get_phase_key(phase: Phase) -> String:
	return Phase.keys()[phase]


func _emit_phase_changed() -> void:
	phase_changed.emit(current_phase)
	log_requested.emit("Phase: %s" % get_current_phase_display())
