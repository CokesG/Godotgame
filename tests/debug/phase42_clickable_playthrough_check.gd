extends Node

const DEBUG_WINDOW_SIZE := Vector2i(1152, 648)
const PASS_MARKER_FILENAME := "phase42_clickable_playthrough_pass.txt"

var failed: bool = false
var combat_scene: Node


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("PHASE42_CLICKABLE_PLAYTHROUGH_CHECK: SKIP headless real mouse-input test requires a rendered window")
		get_tree().quit(0)
		return

	get_window().size = DEBUG_WINDOW_SIZE

	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	combat_scene = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()

	await _verify_opening_screen_is_clean_and_clickable()
	if failed:
		return
	await _verify_first_combat_click_path()
	if failed:
		return
	await _verify_reward_and_next_table_click_path()
	if failed:
		return

	var marker_path := _write_pass_marker()
	print("PHASE42_CLICKABLE_PLAYTHROUGH_CHECK: PASS %s" % marker_path)
	await _settle()
	get_tree().quit(0)


func _verify_opening_screen_is_clean_and_clickable() -> void:
	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var body: Control = combat_scene.find_child("CombatBody", true, false)
	var toggle_debug: Button = combat_scene.find_child("ToggleDebugButton", true, false)
	if start_button == null or body == null or toggle_debug == null:
		_fail("Expected opening button, combat body, and debug toggle.")
		return

	if not bool(start_button.get("visible")) or bool(start_button.get("disabled")):
		_fail("Open Opening Table must be visible and enabled on the opening screen.")
		return
	if bool(body.get("visible")):
		_fail("Opening screen should not show the board/opponent debug surface before the table opens.")
		return
	if bool(toggle_debug.get("visible")):
		_fail("Opening screen should not spend space on the debug toggle.")
		return
	if not _control_fits_debug_window(start_button):
		_fail("Open Opening Table is clipped at the debug-window size.")
		return


func _verify_first_combat_click_path() -> void:
	await _click_button("StartRunButton")
	if _get_phase_key() != "PLAYER_COMMIT":
		_fail("Mouse click on Open Opening Table should deal into Player Commit.")
		return

	var continue_button: Button = combat_scene.find_child("ContinueButton", true, false)
	var target_cards: Control = combat_scene.find_child("EnemyTargetCards", true, false)
	var hand_view: HBoxContainer = combat_scene.find_child("HandView", true, false)
	var body: Control = combat_scene.find_child("CombatBody", true, false)
	if continue_button == null or target_cards == null or hand_view == null or body == null:
		_fail("Expected continue button, target cards, hand, and combat body after opening.")
		return

	if not bool(body.get("visible")):
		_fail("Combat body should appear after opening the table.")
		return
	if not bool(continue_button.get("visible")) or bool(continue_button.get("disabled")):
		_fail("Resolve Turn must be visible and enabled after opening.")
		return
	if not bool(target_cards.get("visible")) or target_cards.get_child_count() <= 0:
		_fail("Clickable enemy target cards should be visible after opening.")
		return
	if hand_view.get_child_count() <= 0:
		_fail("Playable hand should be visible after opening.")
		return
	if not _control_fits_debug_window(continue_button) or not _control_fits_debug_window(hand_view):
		var grid: Control = combat_scene.find_child("CombatGrid", true, false)
		var table_row: Control = combat_scene.find_child("TableRow", true, false)
		var deck: Control = combat_scene.find_child("DeckPanel", true, false)
		_fail("Live combat controls or hand are clipped at the debug-window size. Continue %s | Grid %s | Row %s | Deck %s | Hand %s | Viewport %s" % [
			continue_button.get_global_rect(),
			grid.get_global_rect() if grid != null else Rect2(),
			table_row.get_global_rect() if table_row != null else Rect2(),
			deck.get_global_rect() if deck != null else Rect2(),
			hand_view.get_global_rect(),
			get_viewport().get_visible_rect().size
		])
		return

	var target_card: Button = target_cards.get_child(0)
	if not target_card.has_meta("enemy_id"):
		_fail("Clicked target card should carry enemy metadata.")
		return
	await _click_control(target_card)

	var playable_card := _get_first_playable_hand_card(hand_view)
	if playable_card == null:
		_fail("Expected at least one enabled hand card after selecting a target.")
		return
	await _click_control(playable_card)
	await _click_button("ContinueButton")
	if _get_phase_key() == "PLAYER_COMMIT":
		_fail("Mouse click on Resolve Turn should advance out of Player Commit.")


func _verify_reward_and_next_table_click_path() -> void:
	var run_manager: Node = combat_scene.find_child("RunManager", true, false)
	if run_manager == null:
		_fail("Expected RunManager.")
		return

	run_manager.call("mark_combat_victory", {"player": {"hp": 24}})
	await _settle()

	var card_reward: Button = combat_scene.find_child("CardReward0", true, false)
	if card_reward == null or not bool(card_reward.get("visible")) or bool(card_reward.get("disabled")):
		_fail("Reward card should be visible, enabled, and clickable after victory.")
		return
	if not _control_fits_debug_window(card_reward):
		var shell: Control = combat_scene.find_child("RunShellPanel", true, false)
		var cue: Control = combat_scene.find_child("ActionCuePanel", true, false)
		var controls: Control = combat_scene.find_child("PrimaryControls", true, false)
		_fail("Reward card is clipped at the debug-window size. Reward %s | RunPanel %s | Shell %s visible=%s | Cue %s visible=%s | Controls %s visible=%s | Viewport %s" % [
			card_reward.get_global_rect(),
			(combat_scene.find_child("RunPanel", true, false) as Control).get_global_rect(),
			shell.get_global_rect() if shell != null else Rect2(),
			bool(shell.get("visible")) if shell != null else false,
			cue.get_global_rect() if cue != null else Rect2(),
			bool(cue.get("visible")) if cue != null else false,
			controls.get_global_rect() if controls != null else Rect2(),
			bool(controls.get("visible")) if controls != null else false,
			get_viewport().get_visible_rect().size
		])
		return

	await _click_control(card_reward)
	var next_button: Button = combat_scene.find_child("NextEncounterButton", true, false)
	if next_button == null or not bool(next_button.get("visible")) or bool(next_button.get("disabled")):
		_fail("Open Next Table should be visible and enabled after taking a reward.")
		return
	if not _control_fits_debug_window(next_button):
		_fail("Open Next Table is clipped at the debug-window size.")
		return

	await _click_control(next_button)
	if _get_phase_key() != "PLAYER_COMMIT":
		_fail("Mouse click on Open Next Table should deal the next combat into Player Commit.")


func _click_button(node_name: String) -> void:
	var button: Button = combat_scene.find_child(node_name, true, false)
	if button == null:
		_fail("Missing button: %s" % node_name)
		return
	await _click_control(button)


func _click_control(control: Control) -> void:
	if control == null:
		_fail("Missing click target.")
		return
	if not bool(control.get("visible")):
		_fail("Click target is hidden: %s" % control.name)
		return
	if control is BaseButton and bool((control as BaseButton).get("disabled")):
		_fail("Click target is disabled: %s" % control.name)
		return

	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	get_viewport().push_input(motion, true)
	await get_tree().process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center
	press.global_position = center
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(press, true)
	await get_tree().process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = center
	release.global_position = center
	release.pressed = false
	release.button_mask = 0
	get_viewport().push_input(release, true)
	await _settle()


func _get_first_playable_hand_card(hand_view: HBoxContainer) -> Button:
	for child in hand_view.get_children():
		if child is Button and not bool(child.get("disabled")) and bool(child.get("visible")):
			return child as Button
	return null


func _control_fits_debug_window(control: Control) -> bool:
	if control == null or not control.is_inside_tree():
		return false
	var rect := control.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	var bounds := Vector2(min(viewport_size.x, float(DEBUG_WINDOW_SIZE.x)), min(viewport_size.y, float(DEBUG_WINDOW_SIZE.y)))
	return rect.position.x >= -1.0 \
		and rect.position.y >= -1.0 \
		and rect.end.x <= bounds.x + 1.0 \
		and rect.end.y <= bounds.y + 1.0


func _get_phase_key() -> String:
	var session: Node = combat_scene.find_child("CombatSession", true, false)
	if session == null:
		return ""
	return String(session.get("current_phase_key"))


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.08).timeout


func _write_pass_marker() -> String:
	var output_dir := OS.get_environment("TEMP").path_join("CodexGameDebugFlow").replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var marker_path := output_dir.path_join(PASS_MARKER_FILENAME)
	var marker := FileAccess.open(marker_path, FileAccess.WRITE)
	if marker != null:
		marker.store_string("PHASE42_CLICKABLE_PLAYTHROUGH_CHECK: PASS\n")
	return marker_path


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
