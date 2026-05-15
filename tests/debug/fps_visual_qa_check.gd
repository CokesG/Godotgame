extends Node

const DEBUG_WINDOW_SIZE := Vector2i(1280, 720)
const OUTPUT_DIR := "user://fps_visual_qa"
const FPS_SCENE := "res://scenes/fps/FPSPrototype.tscn"

var failed := false
var prototype: Node


func _ready() -> void:
	get_window().size = DEBUG_WINDOW_SIZE
	_prepare_output_dir()

	var packed_scene: PackedScene = load(FPS_SCENE)
	if packed_scene == null:
		_fail("Could not load FPSPrototype scene.")
		return

	prototype = packed_scene.instantiate()
	add_child(prototype)
	await _settle()
	prototype.call("apply_arena_bridge_payload", _build_visual_payload())
	await _settle()

	_assert_hud_layout("live")
	await _capture_and_assert("01_live_hud")
	if failed:
		return

	if DisplayServer.get_name() != "headless":
		prototype.call("_try_use_ability", 0)
		await _settle()
		await _capture_and_assert("02_dash_ability")
		if failed:
			return

	prototype.set("kills", 4)
	prototype.set("shots_fired", 18)
	prototype.set("shots_hit", 11)
	prototype.set("critical_hits", 2)
	prototype.set("damage_dealt", 180)
	prototype.set("damage_taken", 16)
	prototype.set("objective_completed", true)
	prototype.set("objective_score_bank", 92.0)
	prototype.call("_show_wave_rewards")
	await _settle()
	_assert_reward_report()
	await _capture_and_assert("03_reward_report")
	if failed:
		return

	print("FPS_VISUAL_QA_CHECK: PASS %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	get_tree().quit(0)


func _build_visual_payload() -> Dictionary:
	return {
		"hero_class": "hex_sharpshooter",
		"weapon_card": "quick_slash",
		"ability_cards": ["sidestep", "guard_up", "read_tell", "snare_card"],
		"objective_mode": "extract",
		"loadout": [
			{"slot": "weapon", "id": "quick_slash", "name": "Quick Slash", "weapon": {"name": "Ace Cutter Revolver", "damage": 31, "magazine": 6, "fire_rate": 3.2}},
			{"slot": "ability_1", "id": "sidestep", "name": "Sidestep", "ability": {"kind": "dash", "cooldown": 6.0}},
			{"slot": "ability_2", "id": "guard_up", "name": "Guard Up", "ability": {"kind": "guard_shimmer", "armor": 4, "cooldown": 8.0}},
			{"slot": "ability_3", "id": "read_tell", "name": "Read Tell", "ability": {"kind": "reveal_target", "duration": 3.5, "cooldown": 10.0}},
			{"slot": "ability_4", "id": "snare_card", "name": "Snare Card", "ability": {"kind": "snare_field", "duration": 4.0, "radius": 4.2, "cooldown": 12.0}}
		],
		"economy": {"chips": 7, "armor": 3, "ammo": 36},
		"card_upgrades": {"quick_slash": {"level": 1, "mutation": "Deadeye"}},
		"progression": {"card_xp_pool": 6, "wounds_total": 1, "wound_penalties": {"draw_penalty": 1, "armor_penalty": 2, "chip_tax": 1}},
		"reads": {"target_enemy": &"needle_eye", "threat": "Marked duel target on Long Rail"}
	}


func _assert_hud_layout(capture_name: String) -> void:
	var combat_hud := prototype.find_child("CombatStatusHud", true, false) as Control
	var card_hud := prototype.find_child("CardCombatHud", true, false) as Control
	var ability_row := prototype.find_child("CardHudAbilityRow", true, false)
	if combat_hud == null or card_hud == null or ability_row == null:
		_fail("Expected compact combat HUD, card HUD, and ability row for %s." % capture_name)
		return
	var screen_height := float(DEBUG_WINDOW_SIZE.y)
	var combat_ratio := combat_hud.get_global_rect().size.y / screen_height
	var card_ratio := card_hud.get_global_rect().size.y / screen_height
	if combat_ratio > 0.105:
		_fail("Top combat HUD uses too much vertical space in %s: %.3f." % [capture_name, combat_ratio])
	if card_ratio > 0.18:
		_fail("Bottom card HUD uses too much vertical space in %s: %.3f." % [capture_name, card_ratio])
	if ability_row.get_child_count() < 4:
		_fail("Ability HUD should expose four compact card-power slots.")


func _assert_reward_report() -> void:
	var reward_panel := prototype.find_child("RewardPanel", true, false) as Control
	var reward_summary := prototype.find_child("RewardSummaryLabel", true, false) as Label
	var reward_focus := prototype.find_child("RewardFocusLabel", true, false) as RichTextLabel
	var reward_button := prototype.find_child("RewardButton0", true, false) as Button
	var reward_labels := reward_panel.find_children("*", "RichTextLabel", true, false) if reward_panel != null else []
	var reward_label = reward_labels[0] if not reward_labels.is_empty() else null
	if reward_panel == null or not reward_panel.visible:
		_fail("Reward report should be visible after wave clear.")
	if reward_label == null:
		_fail("Reward report should expose summary text.")
	if reward_summary == null or not reward_summary.text.contains("1-3"):
		_fail("Reward report should explain payout mouse and keyboard controls.")
	if reward_focus == null or not reward_focus.text.contains("SELECTED"):
		_fail("Reward report should expose selected payout explanation copy.")
	if reward_button == null or not reward_button.text.contains("TAKE"):
		_fail("Reward buttons should read as clear payout cards.")


func _capture_and_assert(capture_name: String) -> void:
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
	if int(stats.get("lit_samples", 0)) < 18:
		_fail("Capture %s appears too dark or blank. Stats: %s" % [capture_name, stats])
	if float(stats.get("contrast", 0.0)) < 0.035:
		_fail("Capture %s has too little contrast. Stats: %s" % [capture_name, stats])


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


func _prepare_output_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("fps_visual_qa"):
		dir.make_dir_recursive("fps_visual_qa")


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error(message)
	get_tree().quit(1)
