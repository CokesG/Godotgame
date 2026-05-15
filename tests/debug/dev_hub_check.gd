extends Node

var failed := false


func _ready() -> void:
	await _verify_menu_scene()
	if failed:
		return
	await _verify_map_viewer_scene()
	if failed:
		return
	print("DEV_HUB_CHECK: PASS")
	get_tree().quit(0)


func _verify_menu_scene() -> void:
	var packed_scene: PackedScene = load("res://scenes/ui/MainMenu.tscn")
	if packed_scene == null:
		_fail("Could not load MainMenu scene.")
		return
	var menu := packed_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	if menu.find_child("FullGameButton", true, false) == null:
		_fail("Main menu should expose Full Game Experience.")
	if menu.find_child("CardPrepButton", true, false) == null:
		_fail("Main menu should expose Card Prep With Sample Hand.")
	if menu.find_child("SlottedFPSButton", true, false) == null:
		_fail("Main menu should expose FPS With Slotted Weapon.")
	if menu.find_child("PayoutDemoButton", true, false) == null:
		_fail("Main menu should expose FPS Return Payout.")
	if menu.find_child("ShooterArenaButton", true, false) == null:
		_fail("Main menu should expose Shooter Arena.")
	if menu.find_child("MapViewerButton", true, false) == null:
		_fail("Main menu should expose Tactical Map Viewer.")
	if menu.find_child("CrossfireMapPreview", true, false) == null:
		_fail("Main menu should show the Crossfire map preview.")
	var phase_buttons := menu.find_children("*", "Button", true, false)
	var has_payout_check := false
	for button in phase_buttons:
		if String((button as Button).text).contains("Arena Return Payout"):
			has_payout_check = true
	if not has_payout_check:
		_fail("Main menu should expose the arena return payout check.")
	menu.queue_free()


func _verify_map_viewer_scene() -> void:
	var packed_scene: PackedScene = load("res://scenes/ui/TacticalMapViewer.tscn")
	if packed_scene == null:
		_fail("Could not load TacticalMapViewer scene.")
		return
	var viewer := packed_scene.instantiate()
	add_child(viewer)
	await get_tree().process_frame
	var grid := viewer.find_child("TacticalMapGrid", true, false)
	if grid == null:
		_fail("Map viewer should expose TacticalMapGrid.")
		return
	if grid.get_child_count() != 9:
		_fail("Map viewer should render all nine tactical cells.")
	var detail := viewer.find_child("MapDetail", true, false)
	if detail == null:
		_fail("Map viewer should expose map detail text.")
	viewer.queue_free()


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
