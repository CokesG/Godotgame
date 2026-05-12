extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var victory_scene: Node = packed_scene.instantiate()
	add_child(victory_scene)
	await get_tree().process_frame

	await _verify_boss_victory_finale(victory_scene)
	if failed:
		return

	var defeat_scene: Node = packed_scene.instantiate()
	add_child(defeat_scene)
	await get_tree().process_frame

	await _verify_defeat_finale(defeat_scene)
	if failed:
		return

	print("PHASE29_RUN_FINALE_CHECK: PASS")
	get_tree().quit(0)


func _verify_boss_victory_finale(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for boss finale.")
		return

	for _index in range(4):
		run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
		await get_tree().process_frame
		run_manager.call("skip_rewards")
		await get_tree().process_frame

	var boss_state: Dictionary = run_manager.call("get_state")
	if String(boss_state.get("current_node_name", "")) != "Boss: House Champion":
		_fail("Expected to reach the boss table before victory finale.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 18}})
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var finale_panel: Node = combat_scene.find_child("RunFinalePanel", true, false)
	var finale: Node = combat_scene.find_child("RunFinale", true, false)
	var ceremony: Node = combat_scene.find_child("RunCeremony", true, false)
	if title == null or detail == null or finale_panel == null or finale == null or ceremony == null:
		_fail("Expected complete victory finale UI.")
		return

	if _get_text(title) != "Prototype Path Cleared":
		_fail("Boss victory should use the run results title.")
		return
	if not _get_text(detail).contains("Finale ready: Prototype Path Cleared"):
		_fail("Results detail should present the finale as the active state.")
		return
	if not bool(finale_panel.get("visible")):
		_fail("RunFinalePanel should be visible after boss victory.")
		return

	var finale_text: String = _get_text(finale)
	if not finale_text.contains("Boss Victory Finale") or not finale_text.contains("House Champion folded"):
		_fail("Victory finale should explicitly celebrate the boss result.")
		return
	if not finale_text.contains("Tables: 5/5") or not finale_text.contains("Next: Export Summary"):
		_fail("Victory finale should summarize run completion and next actions.")
		return

	var ceremony_text: String = _get_text(ceremony)
	if not ceremony_text.contains("[DONE] Boss Victory") or not ceremony_text.contains("[ACTIVE] Results"):
		_fail("Victory ceremony should mark boss victory and active results.")
		return
	if not ceremony_text.contains("Boss Victory Finale: Boss: House Champion folded"):
		_fail("Victory ceremony should preserve the boss finale event.")
		return

	_verify_results_actions(combat_scene)


func _verify_defeat_finale(combat_scene: Node) -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for defeat finale.")
		return

	run_manager.call("mark_combat_defeat")
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	var finale_panel: Node = combat_scene.find_child("RunFinalePanel", true, false)
	var finale: Node = combat_scene.find_child("RunFinale", true, false)
	var ceremony: Node = combat_scene.find_child("RunCeremony", true, false)
	if title == null or finale_panel == null or finale == null or ceremony == null:
		_fail("Expected complete defeat finale UI.")
		return

	if _get_text(title) != "Run Lost":
		_fail("Defeat should use the run lost results title.")
		return
	if not bool(finale_panel.get("visible")):
		_fail("RunFinalePanel should be visible after defeat.")
		return

	var finale_text: String = _get_text(finale)
	if not finale_text.contains("Defeat Finale") or not finale_text.contains("The House takes Opening Table"):
		_fail("Defeat finale should explicitly name the fallen table.")
		return
	if not finale_text.contains("Tables Cleared: 0/5") or not finale_text.contains("Next: Export Summary"):
		_fail("Defeat finale should summarize loss progress and next actions.")
		return

	var ceremony_text: String = _get_text(ceremony)
	if not ceremony_text.contains("[DONE] Defeat") or not ceremony_text.contains("[ACTIVE] Results"):
		_fail("Defeat ceremony should mark defeat and active results.")
		return
	if not ceremony_text.contains("Defeat Finale: the House stopped the run at Opening Table"):
		_fail("Defeat ceremony should preserve the defeat finale event.")
		return

	_verify_results_actions(combat_scene)


func _verify_results_actions(combat_scene: Node) -> void:
	var new_run: Button = combat_scene.find_child("ShellNewRunButton", true, false)
	var export: Button = combat_scene.find_child("ShellExportButton", true, false)
	if new_run == null or export == null:
		_fail("Expected finale action buttons.")
		return
	if not bool(new_run.get("visible")) or not bool(export.get("visible")):
		_fail("Finale should show New Run and Export Summary actions.")
		return
	if bool(new_run.get("disabled")) or bool(export.get("disabled")):
		_fail("Finale actions should be enabled.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
