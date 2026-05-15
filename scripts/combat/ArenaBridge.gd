extends Node

var pending_payload: Dictionary = {}
var last_payload: Dictionary = {}
var pending_result: Dictionary = {}
var last_result: Dictionary = {}
var return_scene_path := "res://scenes/combat/TestCombat.tscn"


func set_payload(payload: Dictionary, return_scene: String = "res://scenes/combat/TestCombat.tscn") -> void:
	pending_payload = payload.duplicate(true)
	last_payload = payload.duplicate(true)
	return_scene_path = return_scene


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


func set_result(result: Dictionary) -> void:
	pending_result = result.duplicate(true)
	last_result = result.duplicate(true)


func has_pending_result() -> bool:
	return not pending_result.is_empty()


func take_result() -> Dictionary:
	var result := pending_result.duplicate(true)
	pending_result.clear()
	return result


func peek_result() -> Dictionary:
	return pending_result.duplicate(true)


func get_last_result() -> Dictionary:
	return last_result.duplicate(true)


func get_return_scene_path() -> String:
	return return_scene_path
