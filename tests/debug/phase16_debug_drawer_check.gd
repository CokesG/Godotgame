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

	_verify_default_player_view(combat_scene)
	if failed:
		return
	_verify_debug_drawer_toggle(combat_scene)
	if failed:
		return

	print("PHASE16_DEBUG_DRAWER_CHECK: PASS")
	get_tree().quit(0)


func _verify_default_player_view(combat_scene: Node) -> void:
	for node_name in ["DebugDrawer", "DebugControls", "RecipePanel", "RunState", "BalanceReport", "PlaytestReport"]:
		var node: Node = combat_scene.find_child(node_name, true, false)
		if node == null:
			_fail("Expected %s." % node_name)
			return
		if bool(node.get("visible")):
			_fail("%s should start hidden in the player-facing view." % node_name)
			return

	var run_shell: Node = combat_scene.find_child("RunShellPanel", true, false)
	if run_shell == null or not bool(run_shell.get("visible")):
		_fail("RunShellPanel should stay visible in the player-facing view.")
		return

	var threat_summary: Node = combat_scene.find_child("ThreatSummary", true, false)
	if threat_summary == null or not bool(threat_summary.get("visible")):
		_fail("ThreatSummary should stay visible in the player-facing view.")
		return


func _verify_debug_drawer_toggle(combat_scene: Node) -> void:
	var toggle: Button = combat_scene.find_child("ToggleDebugButton", true, false)
	if toggle == null:
		_fail("Expected ToggleDebugButton.")
		return

	toggle.emit_signal("pressed")
	for node_name in ["DebugDrawer", "DebugControls", "RecipePanel", "RunState", "BalanceReport", "PlaytestReport"]:
		var node: Node = combat_scene.find_child(node_name, true, false)
		if node == null:
			_fail("Expected %s after debug toggle." % node_name)
			return
		if not bool(node.get("visible")):
			_fail("%s should be visible after opening debug drawer." % node_name)
			return

	var debug_summary: Node = combat_scene.find_child("DebugSummary", true, false)
	if debug_summary == null:
		_fail("Expected DebugSummary.")
		return
	var summary_text := _get_text(debug_summary)
	if not summary_text.contains("Flow") or not summary_text.contains("Playtest"):
		_fail("DebugSummary should include flow and playtest diagnostics.")
		return

	toggle.emit_signal("pressed")
	var drawer: Node = combat_scene.find_child("DebugDrawer", true, false)
	if drawer == null or bool(drawer.get("visible")):
		_fail("DebugDrawer should hide after closing debug.")
		return


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
