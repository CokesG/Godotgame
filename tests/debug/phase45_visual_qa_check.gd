extends Node

const DEBUG_WINDOW_SIZE := Vector2i(1152, 648)
const OUTPUT_DIR := "user://phase45_visual_qa"
const TEST_COMBAT_SCENE := "res://scenes/combat/TestCombat.tscn"

var failed: bool = false
var combat_scene: Control


func _ready() -> void:
	get_window().size = DEBUG_WINDOW_SIZE
	_prepare_output_dir()

	var packed_scene: PackedScene = load(TEST_COMBAT_SCENE)
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	combat_scene = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()

	await _capture_and_assert("01_opening")
	if failed:
		return

	_press_button("StartRunButton")
	await _settle()
	await _capture_and_assert("02_live_combat")
	if failed:
		return

	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager for reward capture.")
		return
	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await _settle()
	await _capture_and_assert("03_reward")
	if failed:
		return

	_press_button("CardReward0")
	await _settle()
	await _capture_and_assert("04_next_table")
	if failed:
		return

	run_manager.set("current_node_index", 4)
	run_manager.set("run_outcome", "running")
	run_manager.set("pending_card_reward_paths", [])
	run_manager.set("pending_relic_reward_paths", [])
	run_manager.call("mark_combat_victory", {"player": {"hp": 18}})
	await _settle()
	await _capture_and_assert("05_finale")
	if failed:
		return

	print("PHASE45_VISUAL_QA_CHECK: PASS %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	get_tree().quit(0)


func _prepare_output_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("phase45_visual_qa"):
		dir.make_dir_recursive("phase45_visual_qa")


func _press_button(button_name: String) -> void:
	var button: Button = combat_scene.find_child(button_name, true, false)
	if button == null:
		_fail("Expected button %s." % button_name)
		return
	if bool(button.get("disabled")):
		_fail("Button %s should be enabled for visual QA flow." % button_name)
		return
	button.emit_signal("pressed")


func _capture_and_assert(capture_name: String) -> void:
	_assert_expected_surface(capture_name)
	if failed:
		return
	if DisplayServer.get_name() == "headless":
		return

	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		_fail("Capture %s produced no viewport texture." % capture_name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		_fail("Capture %s produced no image." % capture_name)
		return

	image.convert(Image.FORMAT_RGBA8)
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture_name]
	var save_error := image.save_png(output_path)
	if save_error != OK:
		_fail("Capture %s could not be saved: %s." % [capture_name, error_string(save_error)])
		return

	var stats := _measure_image(image)
	if int(stats.get("lit_samples", 0)) < 12:
		_fail("Capture %s appears blank or black. Stats: %s" % [capture_name, stats])
		return
	if float(stats.get("contrast", 0.0)) < 0.02:
		_fail("Capture %s has too little contrast for visual QA. Stats: %s" % [capture_name, stats])


func _assert_expected_surface(capture_name: String) -> void:
	match capture_name:
		"01_opening":
			_assert_visible_button("StartRunButton", true)
			_assert_visible_control("CombatBody", false)
		"02_live_combat":
			_assert_visible_button("ContinueButton", true)
			_assert_visible_control("CombatBody", true)
			_assert_child_count("EnemyTargetCards", 1)
			_assert_child_count("HandView", 1)
		"03_reward":
			_assert_visible_button("CardReward0", true)
			_assert_visible_control("RunPanel", true)
		"04_next_table":
			_assert_visible_button("NextEncounterButton", true)
			_assert_visible_control("EncounterApproachPanel", true)
		"05_finale":
			_assert_visible_control("RunFinalePanel", true)
			_assert_visible_button("ShellExportButton", true)


func _assert_visible_button(node_name: String, expected_visible: bool) -> void:
	var button: Button = combat_scene.find_child(node_name, true, false)
	if button == null:
		_fail("Expected button %s." % node_name)
		return
	if bool(button.get("visible")) != expected_visible:
		_fail("Button %s visible expected %s." % [node_name, expected_visible])
		return
	if expected_visible and bool(button.get("disabled")):
		_fail("Button %s should be enabled." % node_name)


func _assert_visible_control(node_name: String, expected_visible: bool) -> void:
	var control: Control = combat_scene.find_child(node_name, true, false)
	if control == null:
		_fail("Expected control %s." % node_name)
		return
	if bool(control.get("visible")) != expected_visible:
		_fail("Control %s visible expected %s." % [node_name, expected_visible])


func _assert_child_count(node_name: String, minimum_count: int) -> void:
	var node: Node = combat_scene.find_child(node_name, true, false)
	if node == null:
		_fail("Expected node %s." % node_name)
		return
	if node.get_child_count() < minimum_count:
		_fail("Node %s should have at least %d children." % [node_name, minimum_count])


func _measure_image(image: Image) -> Dictionary:
	var sample_columns := 16
	var sample_rows := 9
	var lit_samples := 0
	var min_luma := 1.0
	var max_luma := 0.0
	for y_index in range(sample_rows):
		for x_index in range(sample_columns):
			var x := int(float(x_index + 0.5) * float(image.get_width()) / float(sample_columns))
			var y := int(float(y_index + 0.5) * float(image.get_height()) / float(sample_rows))
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			min_luma = min(min_luma, luma)
			max_luma = max(max_luma, luma)
			if color.a > 0.1 and luma > 0.025:
				lit_samples += 1
	return {
		"lit_samples": lit_samples,
		"contrast": max_luma - min_luma,
		"width": image.get_width(),
		"height": image.get_height()
	}


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
