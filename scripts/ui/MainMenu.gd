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
var map_data: Dictionary = {}


func _ready() -> void:
	map_data = TACTICAL_MAP_SCRIPT.get_default_map()
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "MenuBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.035, 0.030, 0.026)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "MenuMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.name = "MenuLayout"
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)

	var nav_scroll := ScrollContainer.new()
	nav_scroll.name = "NavigationScroll"
	nav_scroll.custom_minimum_size = Vector2(380, 0)
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(nav_scroll)

	var nav := VBoxContainer.new()
	nav.name = "NavigationColumn"
	nav.custom_minimum_size = Vector2(360, 0)
	nav.add_theme_constant_override("separation", 12)
	nav_scroll.add_child(nav)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "DEAD MAN'S ANTE"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.35))
	nav.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "DEV HUB"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.66, 0.90, 0.92))
	nav.add_child(subtitle)

	_add_divider(nav)
	nav.add_child(_make_button("Full Game Experience", CARD_SCENE, "FullGameButton"))
	nav.add_child(_make_button("Card Prep With Sample Hand", CARD_SCENE, "CardPrepButton"))
	nav.add_child(_make_action_button("FPS With Slotted Weapon", "SlottedFPSButton", _open_fps_with_sample_loadout))
	nav.add_child(_make_action_button("Hold Pot Test", "HoldPotTestButton", _open_objective_fps.bind("hold_pot")))
	nav.add_child(_make_action_button("Extract Test", "ExtractTestButton", _open_objective_fps.bind("extract")))
	nav.add_child(_make_action_button("Duel Test", "DuelTestButton", _open_objective_fps.bind("duel")))
	nav.add_child(_make_action_button("Defend Test", "DefendTestButton", _open_objective_fps.bind("defend")))
	nav.add_child(_make_action_button("Boss Gate Test", "BossGateTestButton", _open_objective_fps.bind("boss_gate")))
	nav.add_child(_make_action_button("FPS Return Payout", "PayoutDemoButton", _open_payout_demo))
	nav.add_child(_make_action_button("FPS Defeat Return", "DefeatDemoButton", _open_defeat_demo))
	nav.add_child(_make_button("Shooter Arena Sandbox", SHOOTER_SCENE, "ShooterArenaButton"))
	nav.add_child(_make_button("Tactical Map Viewer", MAP_VIEWER_SCENE, "MapViewerButton"))

	_add_divider(nav)
	var checks_title := Label.new()
	checks_title.text = "PHASE CHECKS"
	checks_title.add_theme_font_size_override("font_size", 15)
	checks_title.add_theme_color_override("font_color", Color(0.72, 0.74, 0.70))
	nav.add_child(checks_title)
	for check in PHASE_CHECKS:
		nav.add_child(_make_button(String(check.get("label", "Check")), String(check.get("scene", "")), "PhaseCheckButton"))

	status_label = Label.new()
	status_label.name = "LaunchStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.88, 0.64, 0.38))
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(status_label)

	var details := VBoxContainer.new()
	details.name = "DetailsColumn"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 16)
	layout.add_child(details)

	var map_title := Label.new()
	map_title.name = "MapTitle"
	map_title.text = String(map_data.get("name", "Crossfire Table"))
	map_title.add_theme_font_size_override("font_size", 25)
	map_title.add_theme_color_override("font_color", Color(0.94, 0.96, 0.88))
	details.add_child(map_title)

	var map_summary := RichTextLabel.new()
	map_summary.name = "MapSummary"
	map_summary.bbcode_enabled = false
	map_summary.fit_content = true
	map_summary.text = "%s\n%s" % [
		String(map_data.get("summary", "")),
		String(map_data.get("rules_summary", ""))
	]
	map_summary.add_theme_color_override("default_color", Color(0.78, 0.82, 0.80))
	details.add_child(map_summary)

	details.add_child(_build_map_preview())

	var lanes := Label.new()
	lanes.name = "ModeSummary"
	lanes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lanes.text = "Full Game starts the card run. Card Prep opens the table. The FPS objective tests seed Hold, Extract, Duel, Defend, or Boss Gate modes without replaying the whole loop. FPS Return Payout and FPS Defeat Return jump straight to arena handoff outcomes. Tactical Map Viewer opens the shared Crossfire Table data."
	lanes.add_theme_color_override("font_color", Color(0.72, 0.80, 0.78))
	details.add_child(lanes)


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


func _go_to_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK and status_label != null:
		status_label.text = "Could not open %s" % scene_path


func _open_fps_with_sample_loadout() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		bridge.call("set_payload", _build_sample_arena_payload(), CARD_SCENE)
	_go_to_scene(SHOOTER_SCENE)


func _open_objective_fps(objective_mode: String) -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		var payload := _build_sample_arena_payload()
		payload["objective_mode"] = objective_mode
		payload["reads"] = _get_objective_read_payload(objective_mode)
		bridge.call("set_payload", payload, CARD_SCENE)
	_go_to_scene(SHOOTER_SCENE)


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
	_go_to_scene(CARD_SCENE)


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
	_go_to_scene(CARD_SCENE)


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
