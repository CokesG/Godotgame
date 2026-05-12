extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	_verify_default_controls(combat_scene)
	if failed:
		return
	await _verify_smart_turn_setup(combat_scene)
	if failed:
		return
	await _verify_resolve_and_next_turn_flow(combat_scene)
	if failed:
		return
	_verify_debug_reset_access(combat_scene)
	if failed:
		return

	print("PHASE20_LOOP_QUALITY_CHECK: PASS")
	get_tree().quit(0)


func _verify_default_controls(combat_scene: Node) -> void:
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return
	if not bool(continue_button.get("disabled")):
		_fail("ContinueButton should stay blocked by the start shell.")
		return

	var new_run_button: Button = combat_scene.find_child("NewCombatButton", true, false)
	if new_run_button == null:
		_fail("Expected NewCombatButton.")
		return
	if bool(new_run_button.get("visible")):
		_fail("NewCombatButton should not sit in the default play path.")
		return


func _verify_smart_turn_setup(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if start_button == null or continue_button == null:
		_fail("Expected start and continue buttons.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if bool(continue_button.get("disabled")):
		_fail("ContinueButton should unlock after Start Run.")
		return
	if String(continue_button.get("text")) != "Begin Turn":
		_fail("ContinueButton should become the smart Begin Turn control.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Begin Turn should auto draw, read intent, and land on Player Commit.")
		return
	if String(continue_button.get("text")) != "Resolve Turn":
		_fail("ContinueButton should become Resolve Turn during planning.")


func _verify_resolve_and_next_turn_flow(combat_scene: Node) -> void:
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "RESOLVE":
		_fail("Resolve Turn should auto-run bluff/reveal and land on Resolve.")
		return
	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	if feedback == null or not _get_text(feedback).contains("Reveal:"):
		_fail("Resolve Turn should surface reveal feedback.")
		return
	if String(continue_button.get("text")) != "Next Turn":
		_fail("ContinueButton should become Next Turn during review.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame

	if _get_phase_key(combat_scene) != "PLAYER_COMMIT":
		_fail("Next Turn should cleanup, draw, read intent, and land on Player Commit.")
		return
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null or int(session.get("turn_number")) < 2:
		_fail("Next Turn should advance the turn number.")


func _verify_debug_reset_access(combat_scene: Node) -> void:
	var toggle: Button = combat_scene.find_child("ToggleDebugButton", true, false)
	var debug_controls: Node = combat_scene.find_child("DebugControls", true, false)
	var new_run_button: Button = combat_scene.find_child("NewCombatButton", true, false)
	if toggle == null or debug_controls == null or new_run_button == null:
		_fail("Expected debug toggle, debug controls, and reset button.")
		return

	toggle.emit_signal("pressed")
	if not bool(debug_controls.get("visible")):
		_fail("DebugControls should open from the debug toggle.")
		return
	if not bool(new_run_button.get("visible")):
		_fail("NewCombatButton should remain available once debug is open.")


func _get_phase_key(combat_scene: Node) -> String:
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		return ""
	return String(session.get("current_phase_key"))


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
