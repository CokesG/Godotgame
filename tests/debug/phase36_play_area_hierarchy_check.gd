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

	_verify_table_surface(combat_scene)
	if failed:
		return
	await _verify_live_opponent_and_target_hierarchy(combat_scene)
	if failed:
		return
	await _verify_hand_card_readability(combat_scene)
	if failed:
		return

	print("PHASE36_PLAY_AREA_HIERARCHY_CHECK: PASS")
	get_tree().quit(0)


func _verify_table_surface(combat_scene: Node) -> void:
	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	var table_row: Node = combat_scene.find_child("TableRow", true, false)
	var table_board_panel: Node = combat_scene.find_child("TableBoardPanel", true, false)
	var opponent_panel: Node = combat_scene.find_child("OpponentCardsPanel", true, false)
	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var combat_grid: Control = combat_scene.find_child("CombatGrid", true, false)
	var table_title: Node = combat_scene.find_child("TableTitle", true, false)
	if combat_body == null or table_row == null or table_board_panel == null or opponent_panel == null:
		_fail("Expected table row, board panel, and opponent panel in the play area.")
		return
	if deck_panel == null or combat_grid == null or table_title == null:
		_fail("Expected deck panel, combat grid, and table title.")
		return

	if table_row.get_parent() != combat_body or deck_panel.get_parent() != combat_body:
		_fail("Table row and hand/deck strip should both live inside CombatBody.")
		return
	if table_board_panel.get_parent() != table_row or opponent_panel.get_parent() != table_row:
		_fail("Board and opponent panels should be peers in the table row.")
		return
	if combat_grid.get_parent() != table_board_panel:
		_fail("CombatGrid should be framed by the table board panel.")
		return
	if _get_text(table_title) != "The Table":
		_fail("Grid title should read like a game table, not a debug grid.")
		return
	if combat_grid.custom_minimum_size.x < 400:
		_fail("CombatGrid should reserve a larger table footprint.")
		return

	var cells: Node = combat_scene.find_child("Cells", true, false)
	if cells == null or cells.get_child_count() == 0:
		_fail("Expected grid cells.")
		return
	var first_cell: Control = cells.get_child(0)
	if first_cell.custom_minimum_size.x < 116 or first_cell.custom_minimum_size.y < 116:
		_fail("Grid cells should be larger for the table pass.")


func _verify_live_opponent_and_target_hierarchy(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var opponent_panel: Node = combat_scene.find_child("OpponentCardsPanel", true, false)
	var target_panel: Node = combat_scene.find_child("TargetControlsPanel", true, false)
	var target_enemy: OptionButton = combat_scene.find_child("TargetEnemyOption", true, false)
	var move_target: OptionButton = combat_scene.find_child("MovementCellOption", true, false)
	var enemy_status: Node = combat_scene.find_child("EnemyStatus", true, false)
	var intent_icons: Node = combat_scene.find_child("IntentIconStrip", true, false)
	var threat_summary: Node = combat_scene.find_child("ThreatSummary", true, false)
	var intent_preview: Node = combat_scene.find_child("IntentPreview", true, false)
	if start_button == null or continue_button == null:
		_fail("Expected start and smart action buttons.")
		return
	if opponent_panel == null or target_panel == null or target_enemy == null or move_target == null:
		_fail("Expected opponent and target control panels.")
		return
	if enemy_status == null or intent_icons == null or threat_summary == null or intent_preview == null:
		_fail("Expected opponent readout labels.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	if not bool(opponent_panel.get("visible")) or not bool(target_panel.get("visible")):
		_fail("Opponent and target panels should be visible in live combat.")
		return
	if not _get_text(enemy_status).contains("Opponent Cards") or not _get_text(enemy_status).contains("[Enemy Card]"):
		_fail("Enemy status should read as opponent cards.")
		return
	if not _get_text(enemy_status).contains("Threat:"):
		_fail("Enemy cards should keep threat readable.")
		return
	if not _get_text(intent_icons).contains("Intent Icons | Opponent Cards"):
		_fail("Intent strip should frame intents as opponent-card information.")
		return
	if not _get_text(threat_summary).contains("Table Read"):
		_fail("Threat summary should read as table-read guidance.")
		return
	if not _get_text(intent_preview).contains("Intent Cards"):
		_fail("Detailed intent preview should use intent-card framing.")
		return

	if not target_enemy.tooltip_text.contains("Cards") or not move_target.tooltip_text.contains("Movement"):
		_fail("Target controls should explain what card families use them.")
		return
	if target_enemy.item_count <= 0 or not target_enemy.get_item_text(0).contains("Target:"):
		_fail("Enemy target dropdown should use explicit target language.")
		return
	if move_target.item_count <= 0 or not move_target.get_item_text(0).contains("Move:"):
		_fail("Move dropdown should use explicit move language.")
		return

	continue_button.emit_signal("pressed")
	await get_tree().process_frame
	var card_hint: Node = combat_scene.find_child("CardActionHint", true, false)
	if card_hint == null or not _get_text(card_hint).contains("Cards are playable now"):
		_fail("Card affordance should still explain live card play.")


func _verify_hand_card_readability(combat_scene: Node) -> void:
	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if hand_view == null or hand_view.get_child_count() == 0:
		_fail("Expected visible hand cards.")
		return

	var first_card: Control = hand_view.get_child(0)
	if first_card.custom_minimum_size.x < 168 or first_card.custom_minimum_size.y < 188:
		_fail("Cards should reserve the larger readable card footprint.")
		return

	var card_text := _get_text(first_card)
	if not card_text.contains("Cost") or not card_text.contains("Target:") or not card_text.contains("Tags:"):
		_fail("Card text should show cost, target, and tags for readable hand decisions.")
		return

	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var combat_body: Node = combat_scene.find_child("CombatBody", true, false)
	if deck_panel == null or combat_body == null or deck_panel.get_parent() != combat_body:
		_fail("Hand/deck panel should be inside the combat body hierarchy.")


func _get_text(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_parsed_text"):
		return String(node.call("get_parsed_text"))
	return String(node.get("text"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
