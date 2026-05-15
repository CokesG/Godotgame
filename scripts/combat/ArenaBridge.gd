extends Node

var pending_payload: Dictionary = {}
var last_payload: Dictionary = {}


func set_payload(payload: Dictionary) -> void:
	pending_payload = payload.duplicate(true)
	last_payload = payload.duplicate(true)


func has_pending_payload() -> bool:
	return not pending_payload.is_empty()


func take_payload() -> Dictionary:
	var payload := pending_payload.duplicate(true)
	pending_payload.clear()
	return payload


func peek_payload() -> Dictionary:
	return pending_payload.duplicate(true)


func get_last_payload() -> Dictionary:
	return last_payload.duplicate(true)
