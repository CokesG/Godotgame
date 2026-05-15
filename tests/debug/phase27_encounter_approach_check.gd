extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	_verify_run_path_enemy_card_data()
	if failed:
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	_verify_opening_approach(combat_scene)
	if failed:
		return
	await _verify_next_table_approach(combat_scene)
	if failed:
		return
	await _verify_approach_to_combat_transition(combat_scene)
	if failed:
		return

	print("PHASE27_ENCOUNTER_APPROACH_CHECK: PASS")
	get_tree().quit(0)


func _verify_run_path_enemy_card_data() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	var state: Dictionary = run.call("get_state")
	var path_entries: Array = state.get("run_path", [])
	if path_entries.is_empty() or typeof(path_entries[0]) != TYPE_DICTIONARY:
		_fail("Run path should expose table entries.")
		return

	var first_entry: Dictionary = Dictionary(path_entries[0])
	var enemy_cards: Array = first_entry.get("enemy_cards", [])
	if enemy_cards.size() < 2 or typeof(enemy_cards[0]) != TYPE_DICTIONARY:
		_fail("Run path should expose enemy-card data for approach previews.")
		return

	var first_enemy: Dictionary = Dictionary(enemy_cards[0])
	if not first_enemy.has("max_hp") or not first_enemy.has("tell") or not first_enemy.has("counterplay"):
		_fail("Enemy-card data should include HP, tell, and counterplay.")
		return
	if int(first_enemy.get("max_hp", 0)) <= 0 or String(first_enemy.get("role", "")).is_empty():
		_fail("Enemy-card data should include usable HP and role labels.")


func _verify_opening_approach(combat_scene: Node) -> void:
	var approach_panel: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if approach_panel == null or detail == null or start_button == null:
		_fail("Expected complete encounter approach panel.")
		return
	if bool(approach_panel.get("visible")):
		_fail("Opening approach details should stay hidden on the focused first screen.")
		return
	if not _get_text(detail).contains("Deal In") or not bool(start_button.get("visible")):
		_fail("Opening screen should point at the single Deal In action.")
		return


func _verify_next_table_approach(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if start_button == null or run_manager == null:
		_fail("Expected StartRunButton and RunManager.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await get_tree().process_frame

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or bool(card_reward.get("disabled")):
		_fail("Expected selectable card reward before next-table approach.")
		return
	card_reward.emit_signal("pressed")
	await get_tree().process_frame

	var title: Node = combat_scene.find_child("ApproachTitle", true, false)
	var enemy_cards: Node = combat_scene.find_child("ApproachEnemyCards", true, false)
	var rule: Node = combat_scene.find_child("ApproachTableRule", true, false)
	var detail: Node = combat_scene.find_child("RunShellDetail", true, false)
	if title == null or enemy_cards == null or rule == null or detail == null:
		_fail("Expected next-table approach labels.")
		return

	if not _get_text(title).contains("Approach Table 2/5: Raised Stakes"):
		_fail("Next-table approach title should name Raised Stakes.")
		return
	var enemy_text: String = _get_text(enemy_cards)
	if not enemy_text.contains("[Enemy Card] Brute") or not enemy_text.contains("[Enemy Card] Needle-Eye"):
		_fail("Next-table approach should show Brute and Needle-Eye enemy cards.")
		return
	if not enemy_text.contains("Aggro") or not enemy_text.contains("Bluff"):
		_fail("Enemy cards should surface pressure and bluff stats.")
		return
	if not _get_text(rule).contains("Table Rule Card: High Ante") or not _get_text(rule).contains("+1 max Energy"):
		_fail("Next-table approach should frame High Ante before combat.")
		return
	if not _get_text(detail).contains("Approach: review enemy cards"):
		_fail("Next-table shell detail should point the player toward the approach preview.")


func _verify_approach_to_combat_transition(combat_scene: Node) -> void:
	var next_encounter: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter == null or bool(next_encounter.get("disabled")):
		_fail("Expected enabled NextEncounterButton.")
		return

	next_encounter.emit_signal("pressed")
	await get_tree().process_frame

	var approach_panel: Node = combat_scene.find_child("EncounterApproachPanel", true, false)
	var feedback: Node = combat_scene.find_child("CombatFeedback", true, false)
	var title: Node = combat_scene.find_child("RunShellTitle", true, false)
	if approach_panel == null or feedback == null or title == null:
		_fail("Expected approach panel, feedback feed, and shell title after transition.")
		return

	if bool(approach_panel.get("visible")):
		_fail("Approach panel should hide once combat is live.")
		return
	if _get_text(title) != "Current Table":
		_fail("Approach transition should enter the live current-table shell.")
		return
	if not _get_text(feedback).contains("Approach: Raised Stakes dealt into combat"):
		_fail("Transition feedback should call out the approach-to-combat beat.")


func _get_text(node: Node) -> String:
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
