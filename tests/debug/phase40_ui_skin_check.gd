extends Node

var failed: bool = false


func _ready() -> void:
	_verify_skin_assets()
	if failed:
		return

	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	_verify_skinned_layout(combat_scene)
	if failed:
		return
	await _verify_skinned_live_cards(combat_scene)
	if failed:
		return

	print("PHASE40_UI_SKIN_CHECK: PASS")
	get_tree().quit(0)


func _verify_skin_assets() -> void:
	var skin_script := load("res://scripts/ui/DeadMansAnteSkin.gd")
	if skin_script == null:
		_fail("Expected DeadMansAnteSkin.gd.")
		return

	for path in [
		"res://art/game/ui/skin/ui_table_backdrop.png",
		"res://art/game/ui/skin/ui_header_plaque.png",
		"res://art/game/ui/skin/ui_cue_plaque.png",
		"res://art/game/ui/skin/ui_panel_velvet_frame.png",
		"res://art/game/ui/skin/ui_hand_rail.png",
		"res://art/game/ui/skin/ui_card_frame_common.png",
		"res://art/game/ui/skin/ui_button_brass_normal.png",
		"res://art/game/ui/skin/ui_button_brass_hover.png",
		"res://art/game/ui/skin/ui_button_brass_pressed.png",
		"res://art/game/ui/skin/ui_button_brass_disabled.png"
	]:
		if not FileAccess.file_exists(path):
			_fail("Missing UI skin asset: %s" % path)
			return


func _verify_skinned_layout(combat_scene: Node) -> void:
	var backdrop: Node = combat_scene.find_child("TableBackdropFallback", true, false)
	var title_plate: Node = combat_scene.find_child("TitlePlaque", true, false)
	var title: Node = combat_scene.find_child("ScreenTitle", true, false)
	var deck_panel: Node = combat_scene.find_child("DeckPanel", true, false)
	var action_cue_panel: Node = combat_scene.find_child("ActionCuePanel", true, false)
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if backdrop == null or title_plate == null or title == null:
		_fail("Expected skinned backdrop and title plaque.")
		return
	if deck_panel == null or action_cue_panel == null or start_button == null:
		_fail("Expected skinned deck, action cue, and primary button.")
		return
	if not title_plate is PanelContainer:
		_fail("TitlePlaque should be a skinnable PanelContainer.")
		return
	if not deck_panel is PanelContainer:
		_fail("DeckPanel should be a skinnable hand rail PanelContainer.")
		return
	if String(title.get("text")) != "Dead Man's Ante":
		_fail("ScreenTitle should use the branded title plaque wording.")
		return
	if (action_cue_panel as Control).get_theme_stylebox("panel") == null:
		_fail("ActionCuePanel should have a styled panel frame.")
		return
	if start_button.get_theme_stylebox("normal") == null:
		_fail("StartRunButton should have a skinned button state.")
		return


func _verify_skinned_live_cards(combat_scene: Node) -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	if start_button == null:
		_fail("Expected StartRunButton.")
		return

	start_button.emit_signal("pressed")
	await get_tree().process_frame

	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	if hand_view == null or hand_view.get_child_count() == 0:
		_fail("Expected live hand cards after opening the table.")
		return

	var first_card := hand_view.get_child(0)
	if not first_card is Button:
		_fail("Expected hand card buttons.")
		return
	if (first_card as Button).get_theme_stylebox("normal") == null:
		_fail("CardView should have a skinned card frame style.")
		return


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
