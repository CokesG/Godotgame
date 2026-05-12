extends Node

const DEBUG_WINDOW_SIZE := Vector2i(1152, 648)

var combat_scene: Node
var output_dir: String


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screenshot capture requires a rendered window.")
		get_tree().quit(1)
		return

	get_window().size = DEBUG_WINDOW_SIZE
	output_dir = OS.get_environment("TEMP").path_join("CodexGameDebugFlow").replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(output_dir)

	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		push_error("Could not load TestCombat scene.")
		get_tree().quit(1)
		return

	combat_scene = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()
	await _capture("01_opening.png")

	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	start_button.emit_signal("pressed")
	await _settle()
	await _capture("02_live_combat.png")

	var hand_view: Node = combat_scene.find_child("HandView", true, false)
	var first_card: Button = hand_view.get_child(0)
	first_card.emit_signal("pressed")
	await _settle()
	await _capture("03_card_feedback.png")

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await _settle()
	await _capture("04_reward.png")

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	card_reward.emit_signal("pressed")
	await _settle()
	await _capture("05_next_table.png")

	print("PHASE42_SCREENSHOT_CAPTURE: %s" % output_dir)
	get_tree().quit(0)


func _capture(filename: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(output_dir.path_join(filename))


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.08).timeout
