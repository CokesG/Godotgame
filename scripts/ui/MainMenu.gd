class_name MainMenu
extends Control

const CARD_SCENE := "res://scenes/combat/TestCombat.tscn"
const SHOOTER_SCENE := "res://scenes/fps/FPSPrototype.tscn"
const MAP_VIEWER_SCENE := "res://scenes/ui/TacticalMapViewer.tscn"
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")

const PHASE_CHECKS := [
	{"label": "FPS Smoke Check", "scene": "res://tests/debug/FPSPrototypeCheck.tscn"},
	{"label": "Arena Return Payout Check", "scene": "res://tests/debug/Phase69ArenaReturnCheck.tscn"},
	{"label": "Map Rules Check", "scene": "res://tests/debug/Phase61TacticalMapCheck.tscn"},
	{"label": "Card Gameplay Check", "scene": "res://tests/debug/Phase45GameplayMechanicsCheck.tscn"},
	{"label": "Responsive UI Check", "scene": "res://tests/debug/Phase44ResponsivenessGuidanceCheck.tscn"}
]

var status_label: Label
var dev_tools_panel: Control
var settings_panel: Control
var map_data: Dictionary = {}
var scene_preload_requests: Dictionary = {}


func _ready() -> void:
	map_data = TACTICAL_MAP_SCRIPT.get_default_map()
	_build_ui()
	_warm_common_scenes()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "MenuBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.026, 0.022, 0.020)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "MenuMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.name = "MenuLayout"
	layout.add_theme_constant_override("separation", 30)
	margin.add_child(layout)

	var nav := VBoxContainer.new()
	nav.name = "NavigationColumn"
	nav.custom_minimum_size = Vector2(420, 0)
	nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_theme_constant_override("separation", 14)
	layout.add_child(nav)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "DEAD MAN'S ANTE"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.35))
	nav.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Build kit. Fight FPS. Bank payout."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.88, 0.84))
	nav.add_child(subtitle)

	_add_divider(nav)
	var quick_arena_button := _make_action_button("ENTER ARENA\nQuick Fight", "QuickArenaButton", _open_quick_arena)
	quick_arena_button.custom_minimum_size = Vector2(0, 76)
	quick_arena_button.add_theme_font_size_override("font_size", 22)
	nav.add_child(quick_arena_button)

	var deal_in_button := _make_button("BUILD KIT\nCard Table", CARD_SCENE, "DealInButton")
	deal_in_button.custom_minimum_size = Vector2(0, 76)
	deal_in_button.add_theme_font_size_override("font_size", 22)
	nav.add_child(deal_in_button)
	nav.add_child(_make_action_button("Settings", "SettingsButton", _toggle_settings))
	nav.add_child(_make_action_button("Practice Lab", "DevToolsButton", _toggle_dev_tools))
	nav.add_child(_make_action_button("Quit", "QuitButton", _quit_game))

	settings_panel = _build_settings_panel()
	nav.add_child(settings_panel)
	dev_tools_panel = _build_dev_tools_panel()
	nav.add_child(dev_tools_panel)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)

	status_label = Label.new()
	status_label.name = "LaunchStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "Enter Arena jumps straight into the shooter. Build Kit opens card prep."
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.88, 0.64, 0.38))
	nav.add_child(status_label)

	var details := VBoxContainer.new()
	details.name = "DetailsColumn"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 16)
	layout.add_child(details)

	details.add_child(_build_identity_panel())
	details.add_child(_build_loop_panel())
	details.add_child(_build_progression_panel())


func _build_dev_tools_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "DevToolsPanel"
	panel.visible = false
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_menu_panel_style(panel, Color(0.050, 0.046, 0.044, 0.92), Color(0.42, 0.42, 0.46))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "DevToolsScroll"
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var dev := VBoxContainer.new()
	dev.name = "DevToolsList"
	dev.add_theme_constant_override("separation", 8)
	scroll.add_child(dev)
	_add_section_label(dev, "PRACTICE LAB")
	dev.add_child(_make_button("Card Prep With Sample Hand", CARD_SCENE, "CardPrepButton"))
	dev.add_child(_make_action_button("FPS With Slotted Weapon", "SlottedFPSButton", _open_fps_with_sample_loadout))
	dev.add_child(_make_action_button("Hold Pot Test", "HoldPotTestButton", _open_objective_fps.bind("hold_pot")))
	dev.add_child(_make_action_button("Extract Test", "ExtractTestButton", _open_objective_fps.bind("extract")))
	dev.add_child(_make_action_button("Duel Test", "DuelTestButton", _open_objective_fps.bind("duel")))
	dev.add_child(_make_action_button("Defend Test", "DefendTestButton", _open_objective_fps.bind("defend")))
	dev.add_child(_make_action_button("Boss Gate Test", "BossGateTestButton", _open_objective_fps.bind("boss_gate")))
	dev.add_child(_make_action_button("FPS Return Payout", "PayoutDemoButton", _open_payout_demo))
	dev.add_child(_make_action_button("FPS Defeat Return", "DefeatDemoButton", _open_defeat_demo))
	dev.add_child(_make_button("Shooter Arena Sandbox", SHOOTER_SCENE, "ShooterArenaButton"))
	dev.add_child(_make_button("Tactical Map Viewer", MAP_VIEWER_SCENE, "MapViewerButton"))
	_add_divider(dev)
	_add_section_label(dev, "PHASE CHECKS")
	for check in PHASE_CHECKS:
		dev.add_child(_make_button(String(check.get("label", "Check")), String(check.get("scene", "")), "PhaseCheckButton"))
	return panel


func _build_settings_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.visible = false
	_apply_menu_panel_style(panel, Color(0.046, 0.050, 0.048, 0.92), Color(0.48, 0.58, 0.55))
	var label := Label.new()
	label.name = "SettingsSummary"
	label.text = "Press Esc in the FPS arena to tune aim, reticle, sensitivity, and controls."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.84))
	panel.add_child(label)
	return panel


func _build_identity_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "GameIdentityPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_menu_panel_style(panel, Color(0.080, 0.054, 0.036, 0.92), Color(1.0, 0.63, 0.20))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_add_section_label(box, "CORE LOOP")
	var copy := RichTextLabel.new()
	copy.name = "IdentityCopy"
	copy.bbcode_enabled = true
	copy.fit_content = true
	copy.scroll_active = false
	copy.text = "[b]1 Build kit[/b]\nCards become your gun, powers, perk, and risk.\n\n[b]2 Enter FPS[/b]\nClear the arena objective.\n\n[b]3 Bank payout[/b]\nRewards upgrade the next loadout."
	copy.add_theme_font_size_override("normal_font_size", 18)
	copy.add_theme_color_override("default_color", Color(0.92, 0.88, 0.78))
	box.add_child(copy)
	return panel


func _build_loop_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "RunLoopPanel"
	_apply_menu_panel_style(panel, Color(0.045, 0.052, 0.055, 0.90), Color(0.44, 0.72, 0.76))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_add_section_label(box, "NEXT ACTION")
	var loop := Label.new()
	loop.name = "RunLoopSummary"
	loop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loop.text = "Enter Arena is fastest. Build Kit lets you tune the next FPS loadout."
	loop.add_theme_font_size_override("font_size", 17)
	loop.add_theme_color_override("font_color", Color(0.84, 0.90, 0.88))
	box.add_child(loop)
	return panel


func _build_progression_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "ProgressionPanel"
	_apply_menu_panel_style(panel, Color(0.052, 0.042, 0.058, 0.90), Color(0.70, 0.46, 0.82))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_add_section_label(box, "CARRYOVER")
	var progression := Label.new()
	progression.name = "ProgressionSummary"
	progression.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progression.text = "Payouts, Card XP, and wounds shape the next arena."
	progression.add_theme_font_size_override("font_size", 16)
	progression.add_theme_color_override("font_color", Color(0.88, 0.84, 0.92))
	box.add_child(progression)
	return panel


func _make_button(label: String, scene_path: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_go_to_scene.bind(scene_path))
	return button


func _make_action_button(label: String, node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button


func _toggle_dev_tools() -> void:
	if dev_tools_panel == null:
		return
	dev_tools_panel.visible = not dev_tools_panel.visible
	if dev_tools_panel.visible and settings_panel != null:
		settings_panel.visible = false
	if status_label != null:
		status_label.text = "Practice Lab open." if dev_tools_panel.visible else "Enter Arena jumps straight into the shooter."


func _toggle_settings() -> void:
	if settings_panel == null:
		return
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible and dev_tools_panel != null:
		dev_tools_panel.visible = false
	if status_label != null:
		status_label.text = "Settings note open." if settings_panel.visible else "Enter Arena jumps straight into the shooter."


func _quit_game() -> void:
	get_tree().quit()


func _add_section_label(parent: VBoxContainer, label_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	parent.add_child(label)


func _apply_menu_panel_style(panel: PanelContainer, bg_color: Color, border_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)


func _build_map_preview() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "CrossfireMapPreview"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for y in range(3):
		for x in range(3):
			var cell := Vector2i(x, y)
			grid.add_child(_build_map_cell(cell))
	return grid


func _build_map_cell(cell: Vector2i) -> PanelContainer:
	var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(map_data, cell)
	var panel := PanelContainer.new()
	panel.name = "MapCell_%s" % TACTICAL_MAP_SCRIPT.cell_key(cell)
	panel.custom_minimum_size = Vector2(160, 112)
	var style := StyleBoxFlat.new()
	style.bg_color = _get_feature_color(feature, "bg_color", Color(0.12, 0.14, 0.14))
	style.border_color = _get_feature_color(feature, "border_color", Color(0.42, 0.48, 0.48))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var short := Label.new()
	short.text = String(feature.get("short_label", ""))
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	short.add_theme_font_size_override("font_size", 26)
	short.add_theme_color_override("font_color", _get_feature_color(feature, "text_color", Color.WHITE))
	box.add_child(short)
	var label := Label.new()
	label.text = String(feature.get("label", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)
	return panel


func _get_feature_color(feature: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = feature.get(key, fallback)
	if typeof(value) == TYPE_COLOR:
		return value
	return fallback


func _go_to_scene(scene_path: String, preserve_bridge_state: bool = false) -> void:
	if scene_path.is_empty():
		return
	if not preserve_bridge_state:
		_clear_bridge_pending_state()
	call_deferred("_change_to_scene", scene_path, preserve_bridge_state)


func _change_to_scene(scene_path: String, preserve_bridge_state: bool = false) -> void:
	var packed_scene := _get_ready_preloaded_scene(scene_path)
	var error := get_tree().change_scene_to_packed(packed_scene) if packed_scene != null else get_tree().change_scene_to_file(scene_path)
	if error != OK:
		if preserve_bridge_state:
			_clear_bridge_pending_state()
		if status_label != null:
			status_label.text = "Could not open %s" % scene_path


func _open_quick_arena() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		bridge.call("set_payload", _build_sample_arena_payload(), CARD_SCENE)
	if status_label != null:
		status_label.text = "Loading arena..."
	_go_to_scene(SHOOTER_SCENE, true)


func _open_fps_with_sample_loadout() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		bridge.call("set_payload", _build_sample_arena_payload(), CARD_SCENE)
	_go_to_scene(SHOOTER_SCENE, true)


func _open_objective_fps(objective_mode: String) -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		var payload := _build_sample_arena_payload()
		payload["objective_mode"] = objective_mode
		payload["reads"] = _get_objective_read_payload(objective_mode)
		bridge.call("set_payload", payload, CARD_SCENE)
	_go_to_scene(SHOOTER_SCENE, true)


func _open_payout_demo() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_result"):
		bridge.call("set_result", {
			"source": "dev_hub",
			"map_name": "Crossfire Table",
			"outcome": "win",
			"cleared": true,
			"wave": 1,
			"kills": 4,
			"clear_time": 21.5,
			"shots_fired": 10,
			"shots_hit": 7,
			"hit_rate": 0.70,
			"critical_hits": 2,
			"damage_dealt": 186,
			"damage_taken": 14,
			"objective_score": 94,
			"wounds_taken": 0,
			"remaining_health": 27,
			"remaining_armor": 6,
			"loadout": {"weapon": "Ace Cutter Revolver", "abilities": 1, "armor": 6, "ammo": 22, "chips": 3},
			"selected_reward": {"label": "Damage Payout", "kind": "damage", "amount": 3, "chip_bonus": 2},
			"chips_awarded": 10,
			"cards_to_draw": 5
		})
	_go_to_scene(CARD_SCENE, true)


func _open_defeat_demo() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_result"):
		bridge.call("set_result", {
			"source": "dev_hub",
			"map_name": "Crossfire Table",
			"outcome": "defeat",
			"cleared": false,
			"wave": 1,
			"kills": 1,
			"clear_time": 34.0,
			"shots_fired": 18,
			"shots_hit": 7,
			"hit_rate": 0.39,
			"critical_hits": 1,
			"damage_dealt": 92,
			"damage_taken": 120,
			"objective_score": 18,
			"wounds_taken": 3,
			"remaining_health": 0,
			"remaining_armor": 0,
			"loadout": {"weapon": "Ante Carbine AR", "abilities": 2, "armor": 0, "ammo": 5, "chips": 1},
			"selected_reward": {"label": "No Payout", "kind": "none", "amount": 0, "chip_bonus": 0},
			"chips_awarded": 1,
			"cards_to_draw": 0
		})
	_go_to_scene(CARD_SCENE, true)


func _clear_bridge_pending_state() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("clear_pending"):
		bridge.call("clear_pending")


func _warm_common_scenes() -> void:
	_request_scene_preload(SHOOTER_SCENE)
	_request_scene_preload(CARD_SCENE)


func _request_scene_preload(scene_path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if scene_path.is_empty() or scene_preload_requests.has(scene_path):
		return
	var error := ResourceLoader.load_threaded_request(scene_path)
	if error == OK:
		scene_preload_requests[scene_path] = true


func _get_ready_preloaded_scene(scene_path: String) -> PackedScene:
	if not scene_preload_requests.has(scene_path):
		return null
	if ResourceLoader.load_threaded_get_status(scene_path) != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	return ResourceLoader.load_threaded_get(scene_path) as PackedScene


func _build_sample_arena_payload() -> Dictionary:
	return {
		"hero_class": "gambler_knight",
		"weapon_card": "quick_slash",
		"ability_cards": ["sidestep", "guard_up"],
		"passive_cards": [],
		"wager_cards": [],
		"objective_mode": "hold_pot",
		"loadout": [
			{"slot": "weapon", "id": "quick_slash", "name": "Quick Slash", "style": "attack", "combat_role": "weapon", "weapon": {"name": "Ace Cutter Revolver", "damage": 31, "magazine": 6, "fire_rate": 3.2, "range": "mid"}},
			{"slot": "ability_1", "id": "sidestep", "name": "Sidestep", "style": "move", "combat_role": "movement_ability", "ability": {"kind": "dash", "charges": 1, "cooldown": 6.0}},
			{"slot": "ability_2", "id": "guard_up", "name": "Guard Up", "style": "guard", "combat_role": "defense_ability", "ability": {"kind": "guard_shimmer", "armor": 4, "cooldown": 8.0}}
		],
		"economy": {"chips": 5, "armor": 6, "ammo": 30},
		"payout_bonuses": {"armor": 0, "ammo": 0, "weapon_damage": 3},
		"reads": {"target_enemy": &"skulker", "threat": "Knife Duelist rush likely"}
	}


func _get_objective_read_payload(objective_mode: String) -> Dictionary:
	match objective_mode:
		"extract":
			return {"target_enemy": &"skulker", "threat": "Rusher likely contests extract route"}
		"duel":
			return {"target_enemy": &"needle_eye", "threat": "Marked duel target on Long Rail"}
		"defend":
			return {"target_enemy": &"brute", "threat": "Shield Guard anchors the pot"}
		"boss_gate":
			return {"target_enemy": &"gate_champion", "threat": "Boss Gate target must fall"}
		_:
			return {"target_enemy": &"skulker", "threat": "Knife Duelist rush likely"}


func _add_divider(parent: VBoxContainer) -> void:
	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(0, 8)
	parent.add_child(divider)
