extends Node

const DEFAULT_RETURN_SCENE := "res://scenes/combat/TestCombat.tscn"

var pending_payload: Dictionary = {}
var last_payload: Dictionary = {}
var pending_result: Dictionary = {}
var last_result: Dictionary = {}
var pending_return_state: Dictionary = {}
var last_return_state: Dictionary = {}
var return_scene_path := DEFAULT_RETURN_SCENE


func set_payload(payload: Dictionary, return_scene: String = DEFAULT_RETURN_SCENE, return_state: Dictionary = {}) -> void:
	pending_payload = payload.duplicate(true)
	last_payload = payload.duplicate(true)
	pending_result.clear()
	return_scene_path = return_scene if not return_scene.is_empty() else DEFAULT_RETURN_SCENE
	if return_state.is_empty():
		pending_return_state.clear()
	else:
		set_return_state(return_state)


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


func set_return_state(return_state: Dictionary) -> void:
	pending_return_state = return_state.duplicate(true)
	last_return_state = return_state.duplicate(true)


func has_pending_return_state() -> bool:
	return not pending_return_state.is_empty()


func take_return_state() -> Dictionary:
	var return_state := pending_return_state.duplicate(true)
	pending_return_state.clear()
	return return_state


func peek_return_state() -> Dictionary:
	return pending_return_state.duplicate(true)


func get_last_return_state() -> Dictionary:
	return last_return_state.duplicate(true)


func set_result(result: Dictionary, return_state: Dictionary = {}) -> void:
	pending_result = result.duplicate(true)
	last_result = result.duplicate(true)
	pending_payload.clear()
	if not return_state.is_empty():
		set_return_state(return_state)
	elif String(result.get("source", "")) != "fps_arena":
		pending_return_state.clear()


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


func clear_pending() -> void:
	pending_payload.clear()
	pending_result.clear()
	pending_return_state.clear()
	return_scene_path = DEFAULT_RETURN_SCENE
