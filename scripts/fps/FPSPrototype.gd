class_name FPSPrototype
extends Node3D

const FPS_PLAYER_SCRIPT := preload("res://scripts/fps/FPSPlayer.gd")
const FPS_DRONE_SCRIPT := preload("res://scripts/fps/FPSDrone.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")
const CARD_TABLE_SCENE := "res://scenes/combat/TestCombat.tscn"

const DEFAULT_BRIDGE_PAYLOAD := {
	"weapon_card": "",
	"hero_class": "gambler_knight",
	"ability_cards": [],
	"passive_cards": [],
	"wager_cards": [],
	"loadout": [],
	"economy": {"chips": 0, "armor": 0, "ammo": 24},
	"objective_mode": "hold_pot",
	"reward_mods": [],
	"card_upgrades": {},
	"progression": {"card_xp_pool": 0, "wounds_total": 0},
	"reads": {"target_enemy": &"", "threat": "intent hidden"}
}

const DEFAULT_OBJECTIVE_MODE := "hold_pot"
const OBJECTIVE_MODE_ROTATION := ["hold_pot", "extract", "duel", "defend", "boss_gate"]
const MIN_ENEMIES_PER_WAVE := 6
const MAX_ENEMIES_PER_WAVE := 11
const OBJECTIVE_MODE_DEFS := {
	"hold_pot": {
		"label": "Hold Pot",
		"short": "HOLD",
		"summary": "Stand near the Ante Pot to bank objective score.",
		"target_seconds": 8.0,
		"radius": 3.2,
		"color": Color(1.0, 0.78, 0.24)
	},
	"extract": {
		"label": "Extract",
		"short": "EXT",
		"summary": "Touch the Ante Pot, then reach the player-side exit alive.",
		"radius": 3.1,
		"exit_radius": 3.0,
		"time_limit": 18.0,
		"color": Color(0.34, 0.95, 1.0)
	},
	"duel": {
		"label": "Duel",
		"short": "DUEL",
		"summary": "Find and kill the marked enemy before the wave ends.",
		"target": "Needle Eye",
		"color": Color(1.0, 0.48, 0.24)
	},
	"defend": {
		"label": "Defend",
		"short": "DEF",
		"summary": "Keep enemies off the Ante Pot and preserve the table core.",
		"core_health": 100.0,
		"radius": 3.6,
		"color": Color(0.48, 0.78, 1.0)
	},
	"boss_gate": {
		"label": "Boss Gate",
		"short": "BOSS",
		"summary": "Break the Gate Champion while surviving Crossfire pressure.",
		"target": "Gate Champion",
		"color": Color(0.86, 0.42, 1.0)
	}
}

const HERO_CLASS_PROFILES := {
	"gambler_knight": {
		"name": "Gambler-Knight",
		"role": "Duelist",
		"passive": "Ante Guard",
		"summary": "+2 armor on entry. Card abilities cool down 8% faster.",
		"base_armor": 2,
		"cooldown_scalar": 0.92,
		"accent": Color(1.0, 0.76, 0.30)
	},
	"hex_sharpshooter": {
		"name": "Hex Sharpshooter",
		"role": "Controller",
		"passive": "Marked Shot",
		"summary": "Read and trap cards become the natural class focus.",
		"base_armor": 0,
		"cooldown_scalar": 0.96,
		"accent": Color(0.46, 0.86, 1.0)
	},
	"blood_wager": {
		"name": "Blood Wager",
		"role": "Berserker",
		"passive": "Redline",
		"summary": "Ritual and overclock cards become the natural class focus.",
		"base_armor": 0,
		"cooldown_scalar": 0.90,
		"accent": Color(1.0, 0.34, 0.24)
	}
}

const SETTINGS_PATH := "user://fps_settings.cfg"
const UI_REFRESH_INTERVAL := 0.08
const CROSSHAIR_DYNAMIC_REFRESH_INTERVAL := 0.05
const RUNTIME_VIEW_CHECK_INTERVAL := 0.45
const BOUNDS_RECOVERY_INTERVAL := 0.18
const MAX_TRANSIENT_EFFECTS := 72
const DEFAULT_AIM_SETTINGS := {
	"mouse_sensitivity": 0.00155,
	"gamepad_look_sensitivity": 2.4,
	"gamepad_deadzone": 0.18,
	"gamepad_response_curve": 1.55,
	"fov": 74.0,
	"sprint_fov_add": 5.0,
	"ads_fov": 56.0,
	"ads_sensitivity_scale": 0.62,
	"ads_toggle": false,
	"invert_y": false
}
const DEFAULT_CROSSHAIR_SETTINGS := {
	"color": Color(0.72, 0.96, 1.0, 0.92),
	"gap": 7.0,
	"length": 8.0,
	"thickness": 2.0,
	"dot_size": 2.0,
	"opacity": 0.92,
	"outline": true,
	"outline_opacity": 0.62,
	"dynamic_gap": true,
	"hit_marker_color": Color(1.0, 0.78, 0.24, 1.0)
}

var player: Node
var arena_root: Node3D
var tactical_map_root: Node3D
var enemies_root: Node3D
var effects_root: Node3D
var ui_layer: CanvasLayer
var hud_root: Control
var health_bar: ProgressBar
var ammo_label: Label
var reserve_label: Label
var reload_bar: ProgressBar
var reload_status_label: Label
var objective_label: Label
var objective_progress_bar: ProgressBar
var kill_label: Label
var status_label: Label
var loadout_label: Label
var ability_label: Label
var card_hud_panel: PanelContainer
var card_hud_weapon_label: Label
var card_hud_economy_label: Label
var card_hud_ability_row: HBoxContainer
var card_hud_summary_label: Label
var card_hud_layout_signature := ""
var telemetry_label: Label
var reward_backdrop: ColorRect
var reward_panel: PanelContainer
var reward_label: RichTextLabel
var reward_summary_label: Label
var reward_focus_label: RichTextLabel
var settings_panel: PanelContainer
var settings_backdrop: ColorRect
var settings_footer_label: Label
var crosshair: Control
var hit_marker: Control
var damage_flash: ColorRect
var restart_timer := 0.0
var kills := 0
var current_wave_kills := 0
var wave_index := 1
var wave_active := false
var settings_open := false
var run_started_msec := 0
var wave_started_msec := 0
var shots_fired := 0
var shots_hit := 0
var critical_hits := 0
var damage_dealt := 0
var damage_taken := 0
var waves_cleared := 0
var rewards_pending := false
var reward_return_in_progress := false
var active_reward_index := -1
var reward_options: Array[Dictionary] = []
var keybind_buttons: Dictionary = {}
var rebind_status_label: Label
var rebinding_action: StringName = &""
var rebinding_ignore_until_msec := 0
var settings_tabs: TabContainer
var spawn_position := Vector3(0.0, 1.4, 10.5)
var tactical_map: Dictionary = {}
var active_bridge_payload: Dictionary = DEFAULT_BRIDGE_PAYLOAD.duplicate(true)
var active_hero_class_id := "gambler_knight"
var active_hero_profile: Dictionary = HERO_CLASS_PROFILES["gambler_knight"].duplicate(true)
var active_abilities: Array[Dictionary] = []
var active_weapon_profile: Dictionary = {}
var ability_cooldowns: Array[float] = []
var ability_use_counts: Dictionary = {}
var aim_settings: Dictionary = DEFAULT_AIM_SETTINGS.duplicate(true)
var crosshair_settings: Dictionary = DEFAULT_CROSSHAIR_SETTINGS.duplicate(true)
var crosshair_signature := ""
var objective_mode := DEFAULT_OBJECTIVE_MODE
var objective_def: Dictionary = OBJECTIVE_MODE_DEFS[DEFAULT_OBJECTIVE_MODE].duplicate(true)
var arena_start_objective_mode := DEFAULT_OBJECTIVE_MODE
var objective_score_bank := 0.0
var objective_hold_time := 0.0
var objective_completed := false
var objective_failed := false
var objective_extract_collected := false
var objective_extract_timer := 0.0
var objective_core_health := 100.0
var objective_target_name := ""
var objective_target_defeated := false
var objective_contested_count := 0
var objective_events: Array[String] = []
var card_table_preload_requested := false
var ui_refresh_elapsed := 0.0
var crosshair_refresh_elapsed := 0.0
var runtime_view_check_elapsed := 0.0
var bounds_recovery_elapsed := 0.0
var current_wave_enemy_total := 0
var last_player_safe_position := spawn_position

var enemy_defs: Array[Dictionary] = [
	{
		"name": "Skulker",
		"position": Vector3(-7.5, 0.2, -8.5),
		"texture": "res://art/game/enemies/enemy_skulker.png",
		"color": Color(0.82, 0.18, 0.16),
		"archetype": "charger",
		"health": 68,
		"speed": 3.75,
		"attack_damage": 10,
		"attack_range": 1.62
	},
	{
		"name": "Brute",
		"position": Vector3(6.5, 0.2, -10.5),
		"texture": "res://art/game/enemies/enemy_brute.png",
		"color": Color(0.90, 0.56, 0.24),
		"archetype": "shield",
		"health": 118,
		"speed": 2.75,
		"attack_damage": 18,
		"attack_range": 1.95
	},
	{
		"name": "Needle Eye",
		"position": Vector3(0.0, 0.2, -14.0),
		"texture": "res://art/game/enemies/enemy_needle_eye.png",
		"color": Color(0.34, 0.78, 0.88),
		"archetype": "ranged",
		"health": 82,
		"speed": 3.55,
		"attack_damage": 13,
		"attack_range": 1.72,
		"ranged_attack_range": 11.5,
		"hold_distance": 7.0
	},
	{
		"name": "Hexmonger",
		"position": Vector3(10.0, 0.2, -2.0),
		"texture": "res://art/game/enemies/enemy_hexmonger.png",
		"color": Color(0.58, 0.32, 0.90),
		"archetype": "chaser",
		"health": 92,
		"speed": 3.20,
		"attack_damage": 14,
		"attack_range": 1.80
	}
]


func _ready() -> void:
	add_to_group("fps_game")
	tactical_map = TACTICAL_MAP_SCRIPT.get_default_map()
	_load_player_settings()
	_ensure_input_actions()
	_build_world()
	_build_arena()
	_build_player()
	_consume_pending_arena_bridge_payload()
	_request_card_table_preload()
	_build_ui()
	run_started_msec = Time.get_ticks_msec()
	_spawn_wave()
	_refresh_ui()


func _process(delta: float) -> void:
	_tick_ability_cooldowns(delta)
	_update_objective(delta)
	bounds_recovery_elapsed += delta
	if bounds_recovery_elapsed >= BOUNDS_RECOVERY_INTERVAL:
		bounds_recovery_elapsed = 0.0
		_recover_out_of_bounds_actors()
	runtime_view_check_elapsed += delta
	if runtime_view_check_elapsed >= RUNTIME_VIEW_CHECK_INTERVAL:
		runtime_view_check_elapsed = 0.0
		_ensure_runtime_view_is_rendering()
	if restart_timer > 0.0:
		restart_timer -= delta
		if restart_timer <= 0.0:
			_spawn_wave()
	_update_crosshair(false, delta)
	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= UI_REFRESH_INTERVAL:
		ui_refresh_elapsed = 0.0
		_refresh_ui()


func _input(event: InputEvent) -> void:
	if not rebinding_action.is_empty():
		if _capture_rebind_event(event):
			get_viewport().set_input_as_handled()
		return
	if rewards_pending:
		if _handle_reward_input(event):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fps_ability_1"):
		_try_use_ability(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fps_ability_2"):
		_try_use_ability(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fps_ability_3"):
		_try_use_ability(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fps_ability_4"):
		_try_use_ability(3)
		get_viewport().set_input_as_handled()


func is_gameplay_paused() -> bool:
	return settings_open or rewards_pending


func get_living_enemies() -> Array[Node]:
	var living: Array[Node] = []
	if enemies_root == null:
		return living
	for child in enemies_root.get_children():
		if child.has_method("take_damage") and bool(child.get("alive")):
			living.append(child)
	return living


func get_map_summary() -> Dictionary:
	return {
		"name": String(tactical_map.get("name", "Crossfire Table")),
		"summary": String(tactical_map.get("summary", "")),
		"rules": String(tactical_map.get("rules_summary", "")),
		"objective_mode": objective_mode,
		"objective": get_objective_state(),
		"regions": get_map_regions()
	}


func get_objective_modes() -> Array[String]:
	var modes: Array[String] = []
	for key in OBJECTIVE_MODE_DEFS.keys():
		modes.append(String(key))
	return modes


func get_objective_state() -> Dictionary:
	return {
		"mode": objective_mode,
		"label": String(objective_def.get("label", "Objective")),
		"summary": String(objective_def.get("summary", "")),
		"progress": _get_objective_progress_ratio(),
		"score": _calculate_objective_score(true, _get_current_clear_time()),
		"completed": objective_completed,
		"failed": objective_failed,
		"hold_time": objective_hold_time,
		"extract_collected": objective_extract_collected,
		"extract_timer": objective_extract_timer,
		"extract_time_limit": float(objective_def.get("time_limit", 0.0)),
		"core_health": int(roundf(objective_core_health)),
		"target": objective_target_name,
		"target_defeated": objective_target_defeated,
		"contested_count": objective_contested_count,
		"events": objective_events.duplicate()
	}


func get_map_regions() -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	for y in range(3):
		for x in range(3):
			var cell := Vector2i(x, y)
			var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(tactical_map, cell)
			if feature.is_empty():
				continue
			regions.append({
				"cell": cell,
				"name": String(feature.get("label", "")),
				"short_label": String(feature.get("short_label", "")),
				"type": String(feature.get("type", "")),
				"world_position": _map_cell_to_world(cell)
			})
	return regions


func apply_arena_bridge_payload(payload: Dictionary) -> void:
	active_bridge_payload = DEFAULT_BRIDGE_PAYLOAD.duplicate(true)
	active_bridge_payload.merge(payload.duplicate(true), true)
	active_abilities.clear()
	active_weapon_profile.clear()
	ability_use_counts.clear()
	_set_hero_class(String(active_bridge_payload.get("hero_class", "gambler_knight")))
	_set_objective_mode(String(active_bridge_payload.get("objective_mode", DEFAULT_OBJECTIVE_MODE)))
	arena_start_objective_mode = objective_mode

	var loadout: Array = active_bridge_payload.get("loadout", [])
	for entry in loadout:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = entry
		if slot.has("weapon") and active_weapon_profile.is_empty():
			active_weapon_profile = slot.get("weapon", {})
		if slot.has("ability"):
			active_abilities.append(slot)
	ability_cooldowns.clear()
	for _index in range(active_abilities.size()):
		ability_cooldowns.append(0.0)

	var economy: Dictionary = active_bridge_payload.get("economy", {})
	var total_ammo := int(economy.get("ammo", 24))
	var total_armor := int(economy.get("armor", 0)) + int(active_hero_profile.get("base_armor", 0))
	if player != null:
		if player.weapon != null and player.weapon.has_method("configure_from_bridge"):
			player.weapon.call("configure_from_bridge", active_weapon_profile, total_ammo)
		if player.has_method("apply_bridge_survivability"):
			player.call("apply_bridge_survivability", total_armor)
	_refresh_ui()


func get_active_loadout_summary() -> Dictionary:
	var economy: Dictionary = active_bridge_payload.get("economy", {})
	return {
		"hero": String(active_hero_profile.get("name", "Gambler-Knight")),
		"hero_role": String(active_hero_profile.get("role", "Duelist")),
		"hero_passive": String(active_hero_profile.get("passive", "Ante Guard")),
		"weapon": String(active_weapon_profile.get("name", "House Sidearm")),
		"abilities": active_abilities.size(),
		"ability_names": _get_ability_names(),
		"chips": int(economy.get("chips", 0)),
		"armor": int(economy.get("armor", 0)) + int(active_hero_profile.get("base_armor", 0)),
		"ammo": int(economy.get("ammo", 24)),
		"target_enemy": active_bridge_payload.get("reads", {}).get("target_enemy", &""),
		"objective_mode": objective_mode,
		"next_wave_objective": _get_wave_objective_mode(wave_index + 1),
		"objective_label": String(objective_def.get("label", "Objective")),
		"reward_mods": (active_bridge_payload.get("reward_mods", []) as Array).size(),
		"card_upgrades": (active_bridge_payload.get("card_upgrades", {}) as Dictionary).size(),
		"card_xp_pool": int((active_bridge_payload.get("progression", {}) as Dictionary).get("card_xp_pool", 0)),
		"wounds_total": int((active_bridge_payload.get("progression", {}) as Dictionary).get("wounds_total", 0)),
		"wound_penalties": ((active_bridge_payload.get("progression", {}) as Dictionary).get("wound_penalties", {}) as Dictionary).duplicate(true)
	}


func get_active_hero_profile() -> Dictionary:
	return active_hero_profile.duplicate(true)


func get_ability_state() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for index in range(active_abilities.size()):
		var entry: Dictionary = active_abilities[index]
		var ability: Dictionary = entry.get("ability", {})
		states.append({
			"index": index,
			"id": String(entry.get("id", "")),
			"kind": String(ability.get("kind", "")),
			"ready": _is_ability_ready(index),
			"cooldown": ability_cooldowns[index] if index < ability_cooldowns.size() else 0.0
		})
	return states


func _get_ability_names() -> Array[String]:
	var names: Array[String] = []
	for entry in active_abilities:
		var ability: Dictionary = entry.get("ability", {})
		names.append(_get_ability_display_name(String(entry.get("id", "")), String(ability.get("kind", ""))))
	return names


func _get_ability_display_name(card_id: String, kind: String) -> String:
	match card_id:
		"sidestep", "hook_step", "shadow_step":
			return "Dash"
		"guard_up", "iron_vow", "bone_guard", "black_shield":
			return "Shield"
		"read_tell", "marked_card":
			return "Read"
		"snare_card", "tripwire":
			return "Snare"
		"blood_ritual":
			return "Overclock"
		"false_opening":
			return "Bait"
	match kind:
		"dash":
			return "Dash"
		"guard_shimmer":
			return "Shield"
		"reveal_target":
			return "Read"
		"snare_field":
			return "Snare"
		"blood_overclock":
			return "Overclock"
		"bait_ping":
			return "Bait"
		_:
			return kind.capitalize()


func _tick_ability_cooldowns(delta: float) -> void:
	for index in range(ability_cooldowns.size()):
		ability_cooldowns[index] = maxf(0.0, float(ability_cooldowns[index]) - delta)


func _try_use_ability(index: int) -> bool:
	if is_gameplay_paused():
		return false
	if index < 0 or index >= active_abilities.size():
		return false
	if not _is_ability_ready(index):
		return false
	var entry: Dictionary = active_abilities[index]
	var ability: Dictionary = entry.get("ability", {})
	var kind := String(ability.get("kind", ""))
	var used := false
	match kind:
		"dash":
			used = _use_dash_ability(ability)
		"guard_shimmer":
			used = _use_guard_shimmer_ability(ability)
		"reveal_target":
			used = _use_read_reveal_ability(ability)
		"snare_field":
			used = _use_snare_field_ability(ability)
		"blood_overclock":
			used = _use_overclock_ability(ability)
		"bait_ping":
			used = _use_bait_ping_ability(ability)
	if used:
		ability_cooldowns[index] = float(ability.get("cooldown", 6.0)) * _get_hero_cooldown_scalar()
		var ability_id := String(entry.get("id", "ability_%d" % index))
		ability_use_counts[ability_id] = int(ability_use_counts.get(ability_id, 0)) + 1
		_show_status_flash("%s readying" % _get_ability_display_name(String(entry.get("id", "")), kind), Color(0.52, 1.0, 0.82))
		_pulse_card_hud_slot(index, Color(0.52, 1.0, 0.82))
		_refresh_ui()
	return used


func _is_ability_ready(index: int) -> bool:
	return index >= 0 and index < active_abilities.size() and (index >= ability_cooldowns.size() or float(ability_cooldowns[index]) <= 0.0)


func _set_hero_class(class_id: String) -> void:
	active_hero_class_id = class_id if HERO_CLASS_PROFILES.has(class_id) else "gambler_knight"
	active_hero_profile = (HERO_CLASS_PROFILES[active_hero_class_id] as Dictionary).duplicate(true)


func _get_hero_cooldown_scalar() -> float:
	return clampf(float(active_hero_profile.get("cooldown_scalar", 1.0)), 0.35, 2.0)


func _use_dash_ability(ability: Dictionary) -> bool:
	if player == null or not player.has_method("dash_forward"):
		return false
	player.call("dash_forward", float(ability.get("strength", 12.5)))
	_spawn_ability_ring(player.global_position, _blend_ability_class_color("dash", Color(0.34, 0.95, 1.0)), 1.6)
	if objective_mode == "extract" and objective_extract_collected and not objective_completed:
		_add_objective_score(4.0, "Dash rotated toward extract.")
	return true


func _use_guard_shimmer_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	if player.has_method("add_armor"):
		player.call("add_armor", int(ability.get("armor", 5)))
	_spawn_ability_ring(player.global_position, _blend_ability_class_color("guard_shimmer", Color(0.55, 0.78, 1.0)), 2.1)
	if objective_mode == "hold_pot" and _is_player_near(_get_objective_position(), 4.0):
		_add_objective_score(5.0, "Guarded the pot.")
	elif objective_mode == "defend":
		objective_core_health = minf(_get_objective_core_max_health(), objective_core_health + 10.0)
		_add_objective_score(5.0, "Reinforced the table core.")
	return true


func _use_read_reveal_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 3.5))
	for enemy in get_living_enemies():
		if enemy.has_method("reveal_for"):
			enemy.call("reveal_for", duration)
	_spawn_ability_ring(player.global_position + Vector3(0.0, 0.12, -2.0), _blend_ability_class_color("reveal_target", Color(0.22, 0.95, 1.0)), 3.0)
	if objective_mode == "duel" and not objective_target_defeated:
		_add_objective_score(8.0, "Read card exposed the duel target.")
	return true


func _use_snare_field_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 4.0))
	var radius := float(ability.get("radius", 4.2))
	var center: Vector3 = player.global_position + (-player.global_basis.z).normalized() * 5.4
	center.y = 0.05
	_spawn_ability_ring(center, _blend_ability_class_color("snare_field", Color(0.92, 0.48, 1.0)), radius)
	var snared := 0
	for enemy in get_living_enemies():
		if enemy.global_position.distance_to(center) <= radius and enemy.has_method("apply_snare"):
			enemy.call("apply_snare", duration)
			snared += 1
	if snared > 0 and (objective_mode == "hold_pot" or objective_mode == "defend"):
		_add_objective_score(float(snared * 4), "Trap locked a pressure lane.")
	return true


func _use_overclock_ability(ability: Dictionary) -> bool:
	if player == null or player.weapon == null or not player.weapon.has_method("apply_temporary_overclock"):
		return false
	player.weapon.call("apply_temporary_overclock", float(ability.get("duration", 4.0)), 0.78, 1.20)
	_spawn_ability_ring(player.global_position, _blend_ability_class_color("blood_overclock", Color(1.0, 0.58, 0.24)), 2.0)
	if objective_mode == "boss_gate":
		_add_objective_score(6.0, "Overclock pressured the Boss Gate.")
	return true


func _use_bait_ping_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 2.5))
	for enemy in get_living_enemies():
		if enemy.has_method("apply_bait"):
			enemy.call("apply_bait", duration)
	_spawn_ability_ring(player.global_position, _blend_ability_class_color("bait_ping", Color(1.0, 0.86, 0.35)), 3.4)
	if objective_mode == "hold_pot" or objective_mode == "defend":
		_add_objective_score(5.0, "Bait card delayed enemy pressure.")
	return true


func _set_objective_mode(mode: String) -> void:
	var safe_mode := mode if OBJECTIVE_MODE_DEFS.has(mode) else DEFAULT_OBJECTIVE_MODE
	objective_mode = safe_mode
	objective_def = (OBJECTIVE_MODE_DEFS[safe_mode] as Dictionary).duplicate(true)
	objective_score_bank = 0.0
	objective_hold_time = 0.0
	objective_completed = false
	objective_failed = false
	objective_extract_collected = false
	objective_extract_timer = 0.0
	objective_core_health = _get_objective_core_max_health()
	objective_target_name = String(objective_def.get("target", ""))
	objective_target_defeated = false
	objective_contested_count = 0
	objective_events.clear()
	_refresh_objective_mode_props()


func _get_wave_objective_mode(target_wave_index: int) -> String:
	var start_index := OBJECTIVE_MODE_ROTATION.find(arena_start_objective_mode)
	if start_index < 0:
		start_index = 0
	var offset := maxi(0, target_wave_index - 1)
	return String(OBJECTIVE_MODE_ROTATION[(start_index + offset) % OBJECTIVE_MODE_ROTATION.size()])


func _update_objective(delta: float) -> void:
	if player == null or not wave_active or rewards_pending:
		return
	if objective_failed:
		return
	match objective_mode:
		"hold_pot":
			_update_hold_pot_objective(delta)
		"extract":
			_update_extract_objective(delta)
		"defend":
			_update_defend_objective(delta)
		"duel", "boss_gate":
			if objective_target_defeated:
				objective_completed = true


func _update_hold_pot_objective(delta: float) -> void:
	if objective_completed:
		return
	objective_contested_count = _count_living_enemies_near(_get_objective_position(), float(objective_def.get("radius", 3.2)) + 0.85)
	if objective_contested_count > 0:
		objective_hold_time = maxf(0.0, objective_hold_time - delta * float(objective_contested_count) * 0.7)
		objective_score_bank = maxf(0.0, objective_score_bank - delta * float(objective_contested_count) * 1.2)
		_record_objective_event("Ante Pot contested.")
		return
	if _is_player_near(_get_objective_position(), float(objective_def.get("radius", 3.2))):
		objective_hold_time += delta
		objective_score_bank += delta * 4.5
		if objective_hold_time >= float(objective_def.get("target_seconds", 8.0)):
			objective_completed = true
			_add_objective_score(18.0, "Held the Ante Pot.")


func _update_extract_objective(delta: float) -> void:
	if not objective_extract_collected and _is_player_near(_get_objective_position(), float(objective_def.get("radius", 3.1))):
		objective_extract_collected = true
		_add_objective_score(28.0, "Collected the pot.")
		_show_status_flash("Pot taken: reach the extract lane", Color(0.34, 0.95, 1.0))
	if objective_extract_collected and not objective_completed:
		objective_extract_timer += delta
		var time_limit := float(objective_def.get("time_limit", 18.0))
		if objective_extract_timer >= time_limit:
			objective_failed = true
			_record_objective_event("Extract window closed.")
			_show_status_flash("Extract window closed", Color(1.0, 0.34, 0.22))
			return
	if objective_extract_collected and not objective_completed and _is_player_near(_get_extract_position(), float(objective_def.get("exit_radius", 3.0))):
		objective_completed = true
		_add_objective_score(32.0, "Extracted alive.")
		_show_status_flash("Extract secured", Color(0.34, 0.95, 1.0))


func _update_defend_objective(delta: float) -> void:
	var pressure := _count_living_enemies_near(_get_objective_position(), float(objective_def.get("radius", 3.6)))
	objective_contested_count = pressure
	if pressure > 0:
		objective_core_health = maxf(0.0, objective_core_health - delta * float(pressure) * 6.4)
		_record_objective_event("Core under pressure.")
		if objective_core_health <= 0.0:
			objective_failed = true
			_show_status_flash("Ante core broken", Color(1.0, 0.25, 0.18))
	elif wave_active:
		objective_score_bank += delta * 1.6


func _add_objective_score(amount: float, reason: String = "") -> void:
	objective_score_bank = minf(100.0, objective_score_bank + amount)
	_record_objective_event(reason)


func _record_objective_event(reason: String) -> void:
	if reason.is_empty() or objective_events.has(reason):
		return
	objective_events.append(reason)
	if objective_events.size() > 5:
		objective_events.pop_front()


func _count_living_enemies_near(position: Vector3, radius: float) -> int:
	if enemies_root == null:
		return 0
	var count := 0
	var target := position
	target.y = 0.0
	var radius_sq := radius * radius
	for enemy in enemies_root.get_children():
		if not enemy.has_method("take_damage") or not bool(enemy.get("alive")):
			continue
		var enemy_position: Vector3 = enemy.global_position
		enemy_position.y = 0.0
		if enemy_position.distance_squared_to(target) <= radius_sq:
			count += 1
	return count


func _recover_out_of_bounds_actors() -> void:
	var enemy_recovery_limit := 18.0
	if player != null and is_instance_valid(player):
		var player_position: Vector3 = player.global_position
		if player_position.y >= 0.55:
			last_player_safe_position = player_position
		if player_position.y < -6.0:
			player.global_position = last_player_safe_position
			player.set("velocity", Vector3.ZERO)
			_show_status_flash("Returned to arena bounds", Color(0.42, 0.96, 1.0))

	if enemies_root == null:
		return
	for enemy in enemies_root.get_children():
		if not enemy.has_method("take_damage") or not bool(enemy.get("alive")):
			continue
		var enemy_position: Vector3 = enemy.global_position
		if enemy_position.y >= -4.0 and absf(enemy_position.x) <= enemy_recovery_limit and absf(enemy_position.z) <= enemy_recovery_limit:
			continue
		enemy.global_position = Vector3(
			clampf(enemy_position.x, -14.4, 14.4),
			0.22,
			clampf(enemy_position.z, -14.4, 14.4)
		)
		enemy.set("velocity", Vector3.ZERO)


func _is_player_near(position: Vector3, radius: float) -> bool:
	if player == null:
		return false
	var player_position: Vector3 = player.global_position
	player_position.y = 0.0
	var target := position
	target.y = 0.0
	return player_position.distance_squared_to(target) <= radius * radius


func _get_objective_position() -> Vector3:
	return _map_cell_to_world(Vector2i(1, 1)) + Vector3(0.0, 0.08, 0.0)


func _get_extract_position() -> Vector3:
	return _map_cell_to_world(Vector2i(1, 2)) + Vector3(0.0, 0.08, 3.2)


func _get_objective_core_max_health() -> float:
	return float(objective_def.get("core_health", 100.0))


func _get_current_clear_time() -> float:
	return float(Time.get_ticks_msec() - wave_started_msec) / 1000.0 if wave_started_msec > 0 else 0.0


func _get_objective_progress_ratio() -> float:
	match objective_mode:
		"hold_pot":
			return clampf(objective_hold_time / maxf(0.1, float(objective_def.get("target_seconds", 8.0))), 0.0, 1.0)
		"extract":
			if objective_completed:
				return 1.0
			if objective_extract_collected:
				var time_limit := maxf(0.1, float(objective_def.get("time_limit", 18.0)))
				return clampf(0.52 + (1.0 - clampf(objective_extract_timer / time_limit, 0.0, 1.0)) * 0.18, 0.52, 0.70)
			return 0.0
		"defend":
			return clampf(objective_core_health / maxf(1.0, _get_objective_core_max_health()), 0.0, 1.0)
		"duel", "boss_gate":
			return 1.0 if objective_target_defeated else clampf(float(current_wave_kills) / maxf(1.0, float(maxi(1, current_wave_enemy_total))), 0.0, 0.88)
		_:
			return 0.0


func _get_objective_hud_text() -> String:
	var label := String(objective_def.get("label", "Objective"))
	var summary := String(objective_def.get("summary", ""))
	match objective_mode:
		"hold_pot":
			var contested := " contested x%d" % objective_contested_count if objective_contested_count > 0 else ""
			return "%s %.1fs/%.1fs%s | %s" % [label, objective_hold_time, float(objective_def.get("target_seconds", 8.0)), contested, summary]
		"extract":
			var step := "Reach extract" if objective_extract_collected else "Touch Ante Pot"
			var timer_text := " %.0fs" % maxf(0.0, float(objective_def.get("time_limit", 18.0)) - objective_extract_timer) if objective_extract_collected and not objective_completed else ""
			return "%s | %s%s | %s" % [label, step, timer_text, summary]
		"defend":
			var pressure_text := " pressure x%d" % objective_contested_count if objective_contested_count > 0 else ""
			return "%s core %d/%d%s | %s" % [label, int(roundf(objective_core_health)), int(roundf(_get_objective_core_max_health())), pressure_text, summary]
		"duel", "boss_gate":
			var target_state := "DOWN" if objective_target_defeated else objective_target_name
			return "%s target: %s | %s" % [label, target_state, summary]
		_:
			return "%s | %s" % [label, summary]


func _get_ability_hud_text() -> String:
	if active_abilities.is_empty():
		return "Abilities: none slotted"
	var labels: Array[String] = []
	for index in range(active_abilities.size()):
		var entry: Dictionary = active_abilities[index]
		var ability: Dictionary = entry.get("ability", {})
		var name := _get_ability_display_name(String(entry.get("id", "")), String(ability.get("kind", "")))
		var action := StringName("fps_ability_%d" % (index + 1))
		var key := _get_primary_action_binding_text(action)
		var cooldown := ability_cooldowns[index] if index < ability_cooldowns.size() else 0.0
		var state := "READY" if cooldown <= 0.0 else "%.1fs" % cooldown
		labels.append("%s:%s %s" % [key, name, state])
	return "Abilities | " + " | ".join(labels)


func _spawn_ability_ring(position: Vector3, color: Color, radius: float) -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(2)
	var ring := MeshInstance3D.new()
	ring.name = "AbilityRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.05
	ring.mesh = mesh
	ring.position = position
	ring.material_override = _make_marker_material(color, 0.95)
	effects_root.add_child(ring)
	var label := Label3D.new()
	label.name = "AbilityCastLabel"
	label.text = "CARD POWER"
	label.font_size = 34
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.outline_modulate = Color(0.02, 0.01, 0.01, 0.90)
	label.modulate = color
	label.position = position + Vector3(0.0, 0.72, 0.0)
	effects_root.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.35, 1.35, 1.35), 0.28).from(Vector3(0.3, 0.3, 0.3))
	tween.tween_property(ring, "transparency", 1.0, 0.42)
	tween.tween_property(label, "position", label.position + Vector3(0.0, 0.34, 0.0), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42).set_delay(0.10)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
		if is_instance_valid(label):
			label.queue_free()
	)


func _show_status_flash(text: String, color: Color) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_callback(func() -> void:
		if status_label != null:
			status_label.add_theme_color_override("font_color", Color.WHITE)
	)


func spawn_tracer(start_position: Vector3, end_position: Vector3, critical: bool = false) -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(1)
	var line := MeshInstance3D.new()
	line.name = "Tracer"
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start_position)
	mesh.surface_add_vertex(end_position)
	mesh.surface_end()
	line.mesh = mesh
	line.material_override = _make_tracer_material(Color(1.0, 0.82, 0.38) if critical else Color(0.44, 0.90, 1.0))
	effects_root.add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "transparency", 1.0, 0.085)
	tween.tween_callback(line.queue_free)


func spawn_impact(position: Vector3, normal: Vector3, critical: bool = false) -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(2)
	var spark := MeshInstance3D.new()
	spark.name = "Impact"
	var mesh := SphereMesh.new()
	mesh.radius = 0.07 if critical else 0.045
	mesh.height = 0.09 if critical else 0.06
	spark.mesh = mesh
	spark.material_override = _make_emissive_material(Color(1.0, 0.72, 0.20) if critical else Color(0.65, 0.95, 1.0), 1.9)
	effects_root.add_child(spark)
	spark.global_position = position + normal.normalized() * 0.03
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector3(2.2, 2.2, 2.2), 0.12).from(Vector3(0.35, 0.35, 0.35))
	tween.tween_property(spark, "transparency", 1.0, 0.14)
	tween.chain().tween_callback(spark.queue_free)
	_spawn_impact_decal(position, critical)


func _spawn_impact_decal(position: Vector3, critical: bool) -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(1)
	var decal := MeshInstance3D.new()
	decal.name = "ImpactDecal"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18 if critical else 0.11
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.01
	decal.mesh = mesh
	decal.material_override = _make_marker_material(Color(1.0, 0.48, 0.20) if critical else Color(0.50, 0.92, 1.0), 0.36)
	effects_root.add_child(decal)
	decal.global_position = Vector3(position.x, 0.018, position.z)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(decal, "scale", Vector3(1.8, 1.0, 1.8), 0.24).from(Vector3(0.35, 1.0, 0.35))
	tween.tween_property(decal, "transparency", 1.0, 1.05).set_delay(0.16)
	tween.chain().tween_callback(decal.queue_free)


func spawn_enemy_tell(position: Vector3, color: Color, radius: float, text: String = "DANGER") -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(2)
	var ring := MeshInstance3D.new()
	ring.name = "EnemyTellRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.055
	ring.mesh = mesh
	ring.material_override = _make_marker_material(color, 0.74)
	effects_root.add_child(ring)
	ring.global_position = position

	var label := Label3D.new()
	label.name = "EnemyTellLabel"
	label.text = text
	label.font_size = 26
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 5
	label.outline_modulate = Color(0.02, 0.01, 0.01, 0.90)
	label.modulate = color
	effects_root.add_child(label)
	label.global_position = position + Vector3(0.0, 1.18, 0.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.28, 1.28, 1.28), 0.34).from(Vector3(0.42, 0.42, 0.42))
	tween.tween_property(ring, "transparency", 1.0, 0.42).set_delay(0.10)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0.0, 0.34, 0.0), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42).set_delay(0.12)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
		if is_instance_valid(label):
			label.queue_free()
	)


func spawn_enemy_projectile(start_position: Vector3, end_position: Vector3, damage: int, source: Node = null) -> void:
	if effects_root == null:
		if player != null and player.has_method("take_damage"):
			player.call("take_damage", damage, start_position)
		return
	_reserve_effect_slots(2)
	var projectile := MeshInstance3D.new()
	projectile.name = "EnemyProjectile"
	var mesh := SphereMesh.new()
	mesh.radius = 0.085
	mesh.height = 0.16
	projectile.mesh = mesh
	projectile.material_override = _make_emissive_material(Color(1.0, 0.42, 0.24), 2.4)
	effects_root.add_child(projectile)
	projectile.global_position = start_position
	spawn_tracer(start_position, end_position, false)

	var travel_time := clampf(start_position.distance_to(end_position) / 26.0, 0.18, 0.46)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(projectile, "global_position", end_position, travel_time).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(projectile, "scale", Vector3(1.45, 1.45, 1.45), travel_time).from(Vector3(0.45, 0.45, 0.45))
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(projectile):
			projectile.queue_free()
		if player != null and is_instance_valid(player) and player.has_method("take_damage") and not is_gameplay_paused():
			player.call("take_damage", damage, start_position)
		spawn_impact(end_position, Vector3.UP, false)
	)


func spawn_combat_text(position: Vector3, text: String, critical: bool, defeated: bool) -> void:
	if effects_root == null:
		return
	_reserve_effect_slots(1)
	var label := Label3D.new()
	label.name = "CombatText"
	label.text = text
	label.font_size = 32 if critical else 24
	label.modulate = Color(1.0, 0.78, 0.25) if critical else Color(0.82, 0.96, 1.0)
	if defeated:
		label.modulate = Color(1.0, 0.30, 0.22)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.outline_modulate = Color(0.06, 0.03, 0.02, 0.88)
	effects_root.add_child(label)
	label.global_position = position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", position + Vector3(0.0, 0.65, 0.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.12)
	tween.chain().tween_callback(label.queue_free)
	_play_hit_marker(critical)


func on_enemy_defeated(_enemy: Node) -> void:
	kills += 1
	current_wave_kills += 1
	_handle_objective_enemy_defeated(_enemy)
	if get_living_enemies().is_empty():
		wave_active = false
		rewards_pending = true
		waves_cleared += 1
		if objective_mode == "defend" and not objective_failed:
			objective_completed = true
			_add_objective_score(24.0, "Defended the table core.")
		status_label.text = "WAVE CLEARED" if status_label != null else ""
		_show_wave_rewards()


func _handle_objective_enemy_defeated(enemy: Node) -> void:
	if enemy == null:
		return
	var defeated_name := String(enemy.get("display_name"))
	if defeated_name == objective_target_name and (objective_mode == "duel" or objective_mode == "boss_gate"):
		objective_target_defeated = true
		objective_completed = true
		_add_objective_score(42.0 if objective_mode == "duel" else 50.0, "%s defeated." % objective_target_name)
		_show_status_flash("%s complete" % String(objective_def.get("label", "Objective")), _get_objective_color())


func restart_encounter() -> void:
	for child in enemies_root.get_children():
		child.queue_free()
	kills = 0
	current_wave_kills = 0
	wave_index = 1
	waves_cleared = 0
	shots_fired = 0
	shots_hit = 0
	critical_hits = 0
	damage_dealt = 0
	damage_taken = 0
	rewards_pending = false
	reward_return_in_progress = false
	restart_timer = 0.0
	run_started_msec = Time.get_ticks_msec()
	_set_objective_mode(arena_start_objective_mode)
	if reward_panel != null:
		reward_panel.visible = false
	if player != null:
		player.reset_for_arena(spawn_position)
		last_player_safe_position = spawn_position
	_spawn_wave()


func _on_player_restart_requested() -> void:
	if player != null and bool(player.get("dead")):
		_retry_current_wave_after_defeat()
		return
	restart_encounter()


func _retry_current_wave_after_defeat() -> void:
	wave_active = false
	rewards_pending = false
	reward_return_in_progress = false
	restart_timer = 0.0
	if reward_backdrop != null:
		reward_backdrop.visible = false
	if reward_panel != null:
		reward_panel.visible = false
	var retry_mode := objective_mode
	if player != null:
		player.reset_for_arena(spawn_position)
		last_player_safe_position = spawn_position
	_set_objective_mode(retry_mode)
	_spawn_wave()
	_show_status_flash("Wave %d retry" % wave_index, Color(1.0, 0.48, 0.30))


func _ensure_runtime_view_is_rendering() -> void:
	if ui_layer != null:
		ui_layer.visible = true
	if hud_root != null:
		hud_root.visible = true
	if not rewards_pending:
		if reward_backdrop != null:
			reward_backdrop.visible = false
		if reward_panel != null:
			reward_panel.visible = false
	if settings_backdrop != null and not settings_open:
		settings_backdrop.visible = false
	if player == null or not is_instance_valid(player):
		return
	var player_camera: Camera3D = player.get("camera") as Camera3D
	if player_camera != null and not player_camera.current:
		player_camera.current = true


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.040, 0.045, 0.050)
	env.ambient_light_color = Color(0.34, 0.39, 0.42)
	env.ambient_light_energy = 0.82
	env.fog_enabled = true
	env.fog_density = 0.022
	env.fog_light_color = Color(0.22, 0.40, 0.42)
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.rotation_degrees = Vector3(-54.0, 32.0, 0.0)
	sun.light_color = Color(1.0, 0.78, 0.54)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.name = "TealFill"
	fill.position = Vector3(-8.0, 5.0, 8.0)
	fill.light_color = Color(0.26, 0.78, 1.0)
	fill.light_energy = 1.6
	fill.omni_range = 18.0
	add_child(fill)

	arena_root = Node3D.new()
	arena_root.name = "Arena"
	add_child(arena_root)
	tactical_map_root = Node3D.new()
	tactical_map_root.name = "TacticalMapMarkers"
	arena_root.add_child(tactical_map_root)
	enemies_root = Node3D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)
	effects_root = Node3D.new()
	effects_root.name = "Effects"
	add_child(effects_root)


func _build_arena() -> void:
	var floor_mat := _make_material(Color(0.10, 0.12, 0.13), 0.12, 0.78)
	var wall_mat := _make_material(Color(0.08, 0.10, 0.16), 0.02, 0.68)
	var cover_mat := _make_material(Color(0.36, 0.27, 0.18), 0.16, 0.58)
	var teal_mat := _make_emissive_material(Color(0.10, 0.76, 0.86), 0.82)
	var brass_mat := _make_material(Color(0.86, 0.57, 0.26), 0.34, 0.42)
	var lane_mat := _make_emissive_material(Color(0.08, 0.58, 0.68), 0.34)

	_add_box("Floor", Vector3(0.0, -0.20, 0.0), Vector3(32.0, 0.4, 32.0), floor_mat)
	_add_box("NorthWall", Vector3(0.0, 2.0, -16.0), Vector3(32.0, 4.4, 0.6), wall_mat)
	_add_box("SouthWall", Vector3(0.0, 2.0, 16.0), Vector3(32.0, 4.4, 0.6), wall_mat)
	_add_box("WestWall", Vector3(-16.0, 2.0, 0.0), Vector3(0.6, 4.4, 32.0), wall_mat)
	_add_box("EastWall", Vector3(16.0, 2.0, 0.0), Vector3(0.6, 4.4, 32.0), wall_mat)

	_add_box("CenterCoverA", Vector3(-2.6, 0.55, -3.8), Vector3(3.4, 1.1, 1.0), cover_mat)
	_add_box("CenterCoverB", Vector3(3.0, 0.55, -2.0), Vector3(1.0, 1.1, 4.4), cover_mat)
	_add_box("LeftPillar", Vector3(-8.0, 1.2, -1.0), Vector3(1.4, 2.4, 1.4), brass_mat)
	_add_box("RightPillar", Vector3(8.3, 1.2, 2.4), Vector3(1.4, 2.4, 1.4), brass_mat)
	_add_box("LowCoverLeft", Vector3(-7.0, 0.42, 6.0), Vector3(4.2, 0.84, 0.9), cover_mat)
	_add_box("LowCoverRight", Vector3(6.4, 0.42, 6.7), Vector3(3.2, 0.84, 0.9), cover_mat)
	_add_box("RaisedDeck", Vector3(0.0, 0.38, -10.6), Vector3(7.2, 0.76, 4.2), _make_material(Color(0.22, 0.26, 0.27), 0.18, 0.7))
	_add_box("RampLeft", Vector3(-4.75, 0.26, -8.8), Vector3(3.2, 0.42, 2.4), floor_mat, Vector3(deg_to_rad(-10.0), 0.0, 0.0))
	_add_box("RampRight", Vector3(4.75, 0.26, -8.8), Vector3(3.2, 0.42, 2.4), floor_mat, Vector3(deg_to_rad(-10.0), 0.0, 0.0))
	_add_box("CenterLaneLine", Vector3(0.0, 0.012, 0.0), Vector3(0.045, 0.025, 27.5), lane_mat, Vector3.ZERO, false)
	_add_box("LeftLaneLine", Vector3(-5.35, 0.012, 0.0), Vector3(0.035, 0.022, 23.5), lane_mat, Vector3.ZERO, false)
	_add_box("RightLaneLine", Vector3(5.35, 0.012, 0.0), Vector3(0.035, 0.022, 23.5), lane_mat, Vector3.ZERO, false)
	_add_box("CrossLaneLine", Vector3(0.0, 0.014, -5.2), Vector3(18.0, 0.022, 0.035), lane_mat, Vector3.ZERO, false)

	_build_spectacle_stage(lane_mat, brass_mat, teal_mat)
	_build_spawn_portals()
	_build_objective_props()
	_build_cover_silhouettes()

	for i in range(6):
		var x := -11.0 + float(i) * 4.4
		var lamp := _add_box("TableLight%d" % i, Vector3(x, 0.09, -14.2), Vector3(0.18, 0.18, 0.18), teal_mat, Vector3.ZERO, false)
		var light := OmniLight3D.new()
		light.name = "Light"
		light.light_color = Color(0.24, 0.86, 1.0)
		light.light_energy = 0.55
		light.omni_range = 4.6
		lamp.add_child(light)

	_build_tactical_map_markers()


func _build_spectacle_stage(lane_mat: Material, brass_mat: Material, teal_mat: Material) -> void:
	var stage := Node3D.new()
	stage.name = "ArenaSpectacleStage"
	arena_root.add_child(stage)

	var rail_positions := [
		Vector3(-12.8, 0.08, 0.0),
		Vector3(12.8, 0.08, 0.0),
		Vector3(0.0, 0.08, -12.8),
		Vector3(0.0, 0.08, 12.8)
	]
	var rail_sizes := [
		Vector3(0.12, 0.12, 25.0),
		Vector3(0.12, 0.12, 25.0),
		Vector3(25.0, 0.12, 0.12),
		Vector3(25.0, 0.12, 0.12)
	]
	for index in range(rail_positions.size()):
		var rail := _add_box("ArenaEnergyRail%d" % index, rail_positions[index], rail_sizes[index], lane_mat, Vector3.ZERO, false)
		arena_root.remove_child(rail)
		stage.add_child(rail)

	for index in range(4):
		var sign_x := -1.0 if index % 2 == 0 else 1.0
		var sign_z := -1.0 if index < 2 else 1.0
		var pillar := _add_box("BrassCornerPylon%d" % index, Vector3(sign_x * 12.8, 1.15, sign_z * 12.8), Vector3(0.62, 2.3, 0.62), brass_mat, Vector3.ZERO, false)
		arena_root.remove_child(pillar)
		stage.add_child(pillar)
		var light := OmniLight3D.new()
		light.name = "PylonLight"
		light.light_color = Color(0.95, 0.62, 0.22)
		light.light_energy = 1.4
		light.omni_range = 6.5
		pillar.add_child(light)

	var scoreboard := Label3D.new()
	scoreboard.name = "ArenaScoreboard"
	scoreboard.text = "ANTE ARENA // HOLD MID // CASH OUT ALIVE"
	scoreboard.font_size = 58
	scoreboard.modulate = Color(1.0, 0.78, 0.30)
	scoreboard.outline_size = 12
	scoreboard.outline_modulate = Color(0.02, 0.01, 0.01, 0.94)
	scoreboard.position = Vector3(0.0, 3.15, -15.58)
	stage.add_child(scoreboard)

	var crown := MeshInstance3D.new()
	crown.name = "ArenaCeilingSigil"
	var torus := TorusMesh.new()
	torus.inner_radius = 3.8
	torus.outer_radius = 3.92
	crown.mesh = torus
	crown.position = Vector3(0.0, 3.55, -4.0)
	crown.rotation_degrees.x = 90.0
	crown.material_override = teal_mat
	stage.add_child(crown)


func _build_spawn_portals() -> void:
	var portal_data := [
		{"name": "Left Spawn", "position": Vector3(-9.4, 0.06, -12.4), "color": Color(1.0, 0.34, 0.22)},
		{"name": "Mid Spawn", "position": Vector3(0.0, 0.06, -14.0), "color": Color(0.34, 0.86, 1.0)},
		{"name": "Right Spawn", "position": Vector3(9.4, 0.06, -12.4), "color": Color(0.78, 0.42, 1.0)}
	]
	for index in range(portal_data.size()):
		var data: Dictionary = portal_data[index]
		var portal := Node3D.new()
		portal.name = "EnemySpawnPortal%d" % index
		portal.position = data.get("position", Vector3.ZERO)
		arena_root.add_child(portal)

		var color: Color = data.get("color", Color.WHITE)
		var ring := MeshInstance3D.new()
		ring.name = "PortalRing"
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 1.12
		ring_mesh.outer_radius = 1.20
		ring.mesh = ring_mesh
		ring.material_override = _make_marker_material(color, 1.1)
		portal.add_child(ring)

		var haze := MeshInstance3D.new()
		haze.name = "PortalHaze"
		var haze_mesh := CylinderMesh.new()
		haze_mesh.top_radius = 1.05
		haze_mesh.bottom_radius = 1.05
		haze_mesh.height = 0.03
		haze.mesh = haze_mesh
		haze.position.y = 0.02
		haze.material_override = _make_marker_material(color, 0.44)
		portal.add_child(haze)

		var portal_light := OmniLight3D.new()
		portal_light.name = "PortalLight"
		portal_light.light_color = color
		portal_light.light_energy = 1.8
		portal_light.omni_range = 5.0
		portal.add_child(portal_light)

		var label := Label3D.new()
		label.name = "PortalLabel"
		label.text = String(data.get("name", "Spawn")).to_upper()
		label.font_size = 34
		label.modulate = color
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 8
		label.outline_modulate = Color(0.02, 0.01, 0.01, 0.92)
		label.position = Vector3(0.0, 1.25, 0.0)
		portal.add_child(label)


func _build_objective_props() -> void:
	var objective := Node3D.new()
	objective.name = "ObjectiveAntePot"
	objective.position = Vector3(0.0, 0.08, -2.2)
	arena_root.add_child(objective)

	var pot := MeshInstance3D.new()
	pot.name = "ChipPot"
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.85
	pot_mesh.bottom_radius = 0.72
	pot_mesh.height = 0.32
	pot.mesh = pot_mesh
	pot.material_override = _make_material(Color(0.74, 0.42, 0.18), 0.35, 0.38)
	pot.position.y = 0.16
	objective.add_child(pot)

	for index in range(12):
		var chip := MeshInstance3D.new()
		chip.name = "ScatteredChip%d" % index
		var chip_mesh := CylinderMesh.new()
		chip_mesh.top_radius = 0.16
		chip_mesh.bottom_radius = 0.16
		chip_mesh.height = 0.045
		chip.mesh = chip_mesh
		var angle := float(index) * TAU / 12.0
		var radius := 1.0 + float(index % 3) * 0.22
		chip.position = Vector3(cos(angle) * radius, 0.06, sin(angle) * radius)
		chip.rotation_degrees.y = float(index) * 21.0
		chip.material_override = _make_emissive_material(Color(1.0, 0.72, 0.26), 0.18)
		objective.add_child(chip)

	var label := Label3D.new()
	label.name = "ObjectiveLabel"
	label.text = "ANTE POT"
	label.font_size = 24
	label.pixel_size = 0.010
	label.modulate = Color(1.0, 0.80, 0.34)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 5
	label.outline_modulate = Color(0.02, 0.01, 0.01, 0.92)
	label.position = Vector3(0.0, 0.90, 0.0)
	objective.add_child(label)
	_refresh_objective_mode_props()


func _refresh_objective_mode_props() -> void:
	if arena_root == null:
		return
	var old_root := arena_root.get_node_or_null("ObjectiveModeProps")
	if old_root != null:
		arena_root.remove_child(old_root)
		old_root.queue_free()
	var mode_root := Node3D.new()
	mode_root.name = "ObjectiveModeProps"
	arena_root.add_child(mode_root)

	var color := _get_objective_color()
	_add_objective_mode_marker(mode_root, _get_objective_position(), float(objective_def.get("radius", 3.2)), String(objective_def.get("short", "OBJ")), color)
	match objective_mode:
		"hold_pot":
			_add_hold_pot_bank_prop(mode_root, color)
		"extract":
			_add_objective_mode_marker(mode_root, _get_extract_position(), float(objective_def.get("exit_radius", 3.0)), "EXTRACT", Color(0.34, 0.95, 1.0))
			_add_extract_gate_prop(mode_root, Color(0.34, 0.95, 1.0))
		"defend":
			_add_objective_core_prop(mode_root, color)
			_add_defend_barrier_props(mode_root, color)
		"duel":
			_add_objective_wall_note(mode_root, "DUEL TARGET: %s" % objective_target_name, color)
			_add_duel_mark_prop(mode_root, color)
		"boss_gate":
			_add_boss_gate_prop(mode_root, color)


func _add_objective_mode_marker(parent: Node3D, position: Vector3, radius: float, text: String, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = "%sMarker" % text.capitalize().replace(" ", "")
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.075
	marker.mesh = mesh
	marker.position = position + Vector3(0.0, 0.08, 0.0)
	marker.material_override = _make_marker_material(color, 0.92)
	parent.add_child(marker)

	var label := Label3D.new()
	label.name = "%sObjectiveLabel" % text.capitalize().replace(" ", "")
	label.text = text
	label.font_size = 18 if text.length() > 4 else 22
	label.pixel_size = 0.0075
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 5
	label.outline_modulate = Color(0.02, 0.01, 0.01, 0.92)
	label.position = position + Vector3(0.0, 0.88, 0.0)
	parent.add_child(label)


func _add_objective_core_prop(parent: Node3D, color: Color) -> void:
	var core := MeshInstance3D.new()
	core.name = "DefendCore"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.42
	mesh.height = 1.15
	core.mesh = mesh
	core.position = _get_objective_position() + Vector3(0.0, 0.62, 0.0)
	core.material_override = _make_emissive_material(color, 0.9)
	parent.add_child(core)


func _add_hold_pot_bank_prop(parent: Node3D, color: Color) -> void:
	for index in range(4):
		var angle := float(index) * TAU / 4.0 + PI * 0.25
		var post := _add_box(
			"HoldPotStake%d" % index,
			_get_objective_position() + Vector3(cos(angle) * 2.9, 0.64, sin(angle) * 2.9),
			Vector3(0.16, 1.20, 0.16),
			_make_marker_material(color, 0.62),
			Vector3.ZERO,
			false
		)
		arena_root.remove_child(post)
		parent.add_child(post)
	_add_objective_wall_note(parent, "HOLD CENTER: BANK THE POT", color)


func _add_extract_gate_prop(parent: Node3D, color: Color) -> void:
	var exit_pos := _get_extract_position()
	var left := _add_box("ExtractGateLeft", exit_pos + Vector3(-1.55, 1.05, 0.0), Vector3(0.22, 2.1, 0.20), _make_marker_material(color, 0.72), Vector3.ZERO, false)
	var right := _add_box("ExtractGateRight", exit_pos + Vector3(1.55, 1.05, 0.0), Vector3(0.22, 2.1, 0.20), _make_marker_material(color, 0.72), Vector3.ZERO, false)
	var top := _add_box("ExtractGateTop", exit_pos + Vector3(0.0, 2.08, 0.0), Vector3(3.4, 0.20, 0.20), _make_marker_material(color, 0.72), Vector3.ZERO, false)
	for node in [left, right, top]:
		arena_root.remove_child(node)
		parent.add_child(node)


func _add_defend_barrier_props(parent: Node3D, color: Color) -> void:
	for offset in [Vector3(-2.2, 0.58, -0.25), Vector3(2.2, 0.58, -0.25), Vector3(0.0, 0.58, 2.35)]:
		var barrier := _add_box("DefendBarrier", _get_objective_position() + offset, Vector3(1.65, 0.18, 0.76), _make_marker_material(color, 0.46), Vector3(0.0, 0.25 if offset.x < 0.0 else -0.25, 0.0), false)
		arena_root.remove_child(barrier)
		parent.add_child(barrier)


func _add_duel_mark_prop(parent: Node3D, color: Color) -> void:
	var mark_pos := Vector3(0.0, 0.10, -10.8)
	_add_objective_mode_marker(parent, mark_pos, 2.4, "MARK", color)
	var blade := _add_box("DuelMarkBlade", mark_pos + Vector3(0.0, 1.2, 0.0), Vector3(0.18, 2.3, 0.18), _make_marker_material(color, 0.74), Vector3(0.0, 0.0, deg_to_rad(35.0)), false)
	arena_root.remove_child(blade)
	parent.add_child(blade)


func _add_boss_gate_prop(parent: Node3D, color: Color) -> void:
	var gate := _add_box("BossGateArch", Vector3(0.0, 1.6, -13.6), Vector3(5.8, 3.2, 0.28), _make_marker_material(color, 0.72), Vector3.ZERO, false)
	arena_root.remove_child(gate)
	parent.add_child(gate)
	_add_objective_wall_note(parent, "BOSS GATE: BREAK THE CHAMPION", color)


func _add_objective_wall_note(parent: Node3D, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = "ObjectiveWallNote"
	label.text = text
	label.font_size = 44
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color(0.02, 0.01, 0.01, 0.94)
	label.position = Vector3(0.0, 2.38, -15.56)
	parent.add_child(label)


func _get_objective_color() -> Color:
	var color_value: Variant = objective_def.get("color", Color(1.0, 0.78, 0.24))
	if typeof(color_value) == TYPE_COLOR:
		return color_value
	return Color(1.0, 0.78, 0.24)


func _build_cover_silhouettes() -> void:
	var glass_mat := _make_marker_material(Color(0.22, 0.88, 1.0), 0.28)
	var warning_mat := _make_marker_material(Color(1.0, 0.48, 0.20), 0.38)
	var silhouettes := [
		{"name": "CoverSilhouetteCenterA", "position": Vector3(-2.6, 1.35, -3.8), "size": Vector3(3.7, 0.08, 1.18), "mat": glass_mat},
		{"name": "CoverSilhouetteCenterB", "position": Vector3(3.0, 1.35, -2.0), "size": Vector3(1.18, 0.08, 4.7), "mat": glass_mat},
		{"name": "CoverWarningLeft", "position": Vector3(-7.0, 1.02, 6.0), "size": Vector3(4.4, 0.07, 1.08), "mat": warning_mat},
		{"name": "CoverWarningRight", "position": Vector3(6.4, 1.02, 6.7), "size": Vector3(3.4, 0.07, 1.08), "mat": warning_mat}
	]
	for data in silhouettes:
		_add_box(String(data.get("name", "CoverSilhouette")), data.get("position", Vector3.ZERO), data.get("size", Vector3.ONE), data.get("mat", glass_mat), Vector3.ZERO, false)


func _build_tactical_map_markers() -> void:
	if tactical_map_root == null:
		return

	for child in tactical_map_root.get_children():
		child.queue_free()

	for region in get_map_regions():
		_add_tactical_region_marker(region)

	_add_map_wall_label("SMOKE LANE", Vector3(-8.8, 2.8, -15.62), Color(0.40, 0.95, 1.0))
	_add_map_wall_label("ANTE MID", Vector3(0.0, 2.9, -15.62), Color(1.0, 0.78, 0.24))
	_add_map_wall_label("LONG RAIL", Vector3(8.8, 2.8, -15.62), Color(1.0, 0.62, 0.24))


func _add_tactical_region_marker(region: Dictionary) -> void:
	var cell: Vector2i = region.get("cell", Vector2i.ZERO)
	var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(tactical_map, cell)
	var feature_type := String(region.get("type", ""))
	var color := _get_feature_color(feature, "border_color", Color(0.70, 0.90, 1.0))
	var position: Vector3 = region.get("world_position", _map_cell_to_world(cell))

	var marker := MeshInstance3D.new()
	marker.name = "MapRegion_%s_%s" % [String(region.get("short_label", "REG")), TACTICAL_MAP_SCRIPT.cell_key(cell)]
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 1.35 if feature_type == "objective" else 0.92
	marker_mesh.bottom_radius = marker_mesh.top_radius
	marker_mesh.height = 0.035
	marker.mesh = marker_mesh
	marker.position = position + Vector3(0.0, 0.035, 0.0)
	marker.material_override = _make_marker_material(color, 0.46)
	tactical_map_root.add_child(marker)

	if feature_type == "cover":
		_add_tactical_cover_flag(position, color)
	elif feature_type == "angle":
		_add_tactical_angle_line(position, color)
	elif feature_type == "objective":
		_add_tactical_objective_crown(position, color)

	_add_floor_label(String(region.get("short_label", "")), position + Vector3(0.0, 0.26, 0.0), color)


func _add_tactical_cover_flag(position: Vector3, color: Color) -> void:
	var flag := _add_box("MapCoverFlag", position + Vector3(0.0, 0.55, 0.0), Vector3(1.1, 0.10, 0.08), _make_marker_material(color, 0.55), Vector3.ZERO, false)
	flag.name = "MapCoverFlag"


func _add_tactical_angle_line(position: Vector3, color: Color) -> void:
	var line := _add_box("MapAngleLine", position + Vector3(0.0, 0.08, 0.0), Vector3(0.14, 0.035, 3.0), _make_marker_material(color, 0.72), Vector3(0.0, deg_to_rad(-24.0), 0.0), false)
	line.name = "MapAngleLine"


func _add_tactical_objective_crown(position: Vector3, color: Color) -> void:
	var crown := MeshInstance3D.new()
	crown.name = "MapObjectiveCrown"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.08
	crown.mesh = torus
	crown.position = position + Vector3(0.0, 0.12, 0.0)
	crown.material_override = _make_marker_material(color, 0.86)
	tactical_map_root.add_child(crown)


func _add_floor_label(text: String, position: Vector3, color: Color) -> void:
	if text.is_empty():
		return
	var label := Label3D.new()
	label.name = "MapFloorLabel"
	label.text = text
	label.font_size = 42
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color(0.02, 0.018, 0.012)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
	tactical_map_root.add_child(label)


func _add_map_wall_label(text: String, position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = "MapWallLabel"
	label.text = text
	label.font_size = 48
	label.modulate = color
	label.outline_size = 12
	label.outline_modulate = Color(0.02, 0.018, 0.012)
	label.position = position
	label.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	tactical_map_root.add_child(label)


func _build_player() -> void:
	player = FPS_PLAYER_SCRIPT.new()
	player.name = "FPSPlayer"
	player.game_mode = self
	player.position = spawn_position
	add_child(player)
	player.health_changed.connect(_on_player_health_changed)
	player.damage_taken.connect(_on_player_damage_taken)
	player.weapon_state_changed.connect(_on_weapon_state_changed)
	player.request_restart.connect(_on_player_restart_requested)
	if player.has_method("apply_aim_settings"):
		player.call("apply_aim_settings", aim_settings)
	if player.weapon != null:
		player.weapon.fired.connect(_on_weapon_fired)
		player.weapon.hit_confirmed.connect(_on_weapon_hit_confirmed)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "FPSHud"
	add_child(ui_layer)

	hud_root = Control.new()
	hud_root.name = "HudRoot"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud_root)

	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.95, 0.08, 0.04, 0.0)
	hud_root.add_child(damage_flash)

	var hud_accent := _get_class_accent_color()
	var combat_panel := PanelContainer.new()
	combat_panel.name = "CombatStatusHud"
	combat_panel.anchor_left = 0.028
	combat_panel.anchor_top = 0.026
	combat_panel.anchor_right = 0.972
	combat_panel.anchor_bottom = 0.106
	combat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_panel.add_theme_stylebox_override("panel", _make_hud_panel_style(Color(0.012, 0.018, 0.022, 0.72), Color(hud_accent.r, hud_accent.g, hud_accent.b, 0.68), 6, 2))
	hud_root.add_child(combat_panel)

	var combat_margin := MarginContainer.new()
	combat_margin.add_theme_constant_override("margin_left", 12)
	combat_margin.add_theme_constant_override("margin_top", 6)
	combat_margin.add_theme_constant_override("margin_right", 12)
	combat_margin.add_theme_constant_override("margin_bottom", 6)
	combat_panel.add_child(combat_margin)

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 14)
	combat_margin.add_child(top_bar)

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.max_value = 120.0
	health_bar.value = 120.0
	health_bar.custom_minimum_size = Vector2(170, 14)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _make_hud_panel_style(Color(0.04, 0.07, 0.075, 0.62), Color(0.10, 0.18, 0.20, 0.0), 4, 0))
	health_bar.add_theme_stylebox_override("fill", _make_hud_panel_style(Color(0.52, 0.92, 0.94, 0.76), Color(0.78, 1.0, 0.96, 0.16), 4, 0))
	top_bar.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "12"
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	ammo_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	ammo_label.add_theme_constant_override("shadow_offset_x", 1)
	ammo_label.add_theme_constant_override("shadow_offset_y", 1)
	top_bar.add_child(ammo_label)

	reserve_label = Label.new()
	reserve_label.name = "ReserveLabel"
	reserve_label.text = "72"
	reserve_label.add_theme_font_size_override("font_size", 14)
	reserve_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.92))
	top_bar.add_child(reserve_label)

	reload_bar = ProgressBar.new()
	reload_bar.name = "ReloadProgress"
	reload_bar.max_value = 1.0
	reload_bar.value = 0.0
	reload_bar.custom_minimum_size = Vector2(72, 8)
	reload_bar.show_percentage = false
	reload_bar.visible = false
	reload_bar.add_theme_stylebox_override("background", _make_hud_panel_style(Color(0.07, 0.06, 0.035, 0.80), Color(0.0, 0.0, 0.0, 0.0), 4, 0))
	reload_bar.add_theme_stylebox_override("fill", _make_hud_panel_style(Color(1.0, 0.68, 0.22, 0.92), Color(1.0, 0.88, 0.42, 0.22), 4, 0))
	top_bar.add_child(reload_bar)

	reload_status_label = Label.new()
	reload_status_label.name = "ReloadStatusLabel"
	reload_status_label.text = "RELOAD"
	reload_status_label.add_theme_font_size_override("font_size", 13)
	reload_status_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.35))
	reload_status_label.visible = false
	top_bar.add_child(reload_status_label)

	objective_progress_bar = ProgressBar.new()
	objective_progress_bar.name = "ObjectiveProgress"
	objective_progress_bar.max_value = 1.0
	objective_progress_bar.value = 0.0
	objective_progress_bar.custom_minimum_size = Vector2(94, 8)
	objective_progress_bar.show_percentage = false
	objective_progress_bar.add_theme_stylebox_override("background", _make_hud_panel_style(Color(0.06, 0.055, 0.04, 0.70), Color(0.10, 0.08, 0.04, 0.0), 4, 0))
	objective_progress_bar.add_theme_stylebox_override("fill", _make_hud_panel_style(Color(1.0, 0.73, 0.22, 0.86), Color(1.0, 0.88, 0.42, 0.18), 4, 0))
	top_bar.add_child(objective_progress_bar)

	kill_label = Label.new()
	kill_label.name = "KillLabel"
	kill_label.text = "0"
	kill_label.add_theme_font_size_override("font_size", 14)
	kill_label.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	top_bar.add_child(kill_label)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	top_bar.add_child(status_label)

	loadout_label = Label.new()
	loadout_label.name = "LoadoutLabel"
	loadout_label.anchor_left = 0.035
	loadout_label.anchor_top = 0.118
	loadout_label.anchor_right = 0.965
	loadout_label.anchor_bottom = 0.148
	loadout_label.add_theme_font_size_override("font_size", 12)
	loadout_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))
	loadout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_root.add_child(loadout_label)

	objective_label = Label.new()
	objective_label.name = "ObjectiveModeLabel"
	objective_label.anchor_left = 0.035
	objective_label.anchor_top = 0.148
	objective_label.anchor_right = 0.965
	objective_label.anchor_bottom = 0.178
	objective_label.add_theme_font_size_override("font_size", 11)
	objective_label.add_theme_color_override("font_color", _get_objective_color())
	hud_root.add_child(objective_label)

	ability_label = Label.new()
	ability_label.name = "AbilityLabel"
	ability_label.anchor_left = 0.035
	ability_label.anchor_top = 0.178
	ability_label.anchor_right = 0.965
	ability_label.anchor_bottom = 0.208
	ability_label.add_theme_font_size_override("font_size", 11)
	ability_label.add_theme_color_override("font_color", Color(0.74, 0.96, 1.0))
	hud_root.add_child(ability_label)

	_build_card_combat_hud(hud_root)

	telemetry_label = Label.new()
	telemetry_label.name = "TelemetryLabel"
	telemetry_label.anchor_left = 0.035
	telemetry_label.anchor_top = 0.795
	telemetry_label.anchor_right = 0.965
	telemetry_label.anchor_bottom = 0.825
	telemetry_label.add_theme_font_size_override("font_size", 11)
	telemetry_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.86, 0.88))
	telemetry_label.visible = false
	hud_root.add_child(telemetry_label)

	_build_crosshair(hud_root)
	_build_hit_marker(hud_root)
	_build_reward_panel(hud_root)
	_build_settings_panel(hud_root)


func _build_card_combat_hud(root: Control) -> void:
	card_hud_panel = PanelContainer.new()
	card_hud_panel.name = "CardCombatHud"
	card_hud_panel.anchor_left = 0.135
	card_hud_panel.anchor_top = 0.830
	card_hud_panel.anchor_right = 0.865
	card_hud_panel.anchor_bottom = 0.960
	card_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var class_color := _get_class_accent_color()
	card_hud_panel.add_theme_stylebox_override("panel", _make_hud_panel_style(Color(0.015, 0.014, 0.013, 0.72), Color(class_color.r, class_color.g, class_color.b, 0.64), 6, 2))
	root.add_child(card_hud_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	card_hud_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	margin.add_child(layout)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	layout.add_child(top_row)

	card_hud_weapon_label = Label.new()
	card_hud_weapon_label.name = "CardHudWeaponLabel"
	card_hud_weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_hud_weapon_label.add_theme_font_size_override("font_size", 11)
	card_hud_weapon_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.46))
	top_row.add_child(card_hud_weapon_label)

	card_hud_economy_label = Label.new()
	card_hud_economy_label.name = "CardHudEconomyLabel"
	card_hud_economy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card_hud_economy_label.add_theme_font_size_override("font_size", 11)
	card_hud_economy_label.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0))
	top_row.add_child(card_hud_economy_label)

	card_hud_ability_row = HBoxContainer.new()
	card_hud_ability_row.name = "CardHudAbilityRow"
	card_hud_ability_row.add_theme_constant_override("separation", 6)
	layout.add_child(card_hud_ability_row)

	card_hud_summary_label = Label.new()
	card_hud_summary_label.name = "CardHudSummaryLabel"
	card_hud_summary_label.add_theme_font_size_override("font_size", 9)
	card_hud_summary_label.add_theme_color_override("font_color", Color(0.70, 0.76, 0.82, 0.92))
	card_hud_summary_label.visible = true
	layout.add_child(card_hud_summary_label)


func _build_crosshair(root: Control) -> void:
	crosshair = Control.new()
	crosshair.name = "Crosshair"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	_update_crosshair()


func _build_hit_marker(root: Control) -> void:
	hit_marker = Control.new()
	hit_marker.name = "HitMarker"
	hit_marker.anchor_left = 0.5
	hit_marker.anchor_top = 0.5
	hit_marker.anchor_right = 0.5
	hit_marker.anchor_bottom = 0.5
	hit_marker.modulate.a = 0.0
	root.add_child(hit_marker)
	var a := _add_crosshair_rect(hit_marker, Vector2(-15.0, -15.0), Vector2(18.0, 2.0), Color(1.0, 0.78, 0.24))
	a.rotation = deg_to_rad(45.0)
	var b := _add_crosshair_rect(hit_marker, Vector2(1.0, -15.0), Vector2(18.0, 2.0), Color(1.0, 0.78, 0.24))
	b.rotation = deg_to_rad(135.0)
	var c := _add_crosshair_rect(hit_marker, Vector2(-15.0, 13.0), Vector2(18.0, 2.0), Color(1.0, 0.78, 0.24))
	c.rotation = deg_to_rad(-45.0)
	var d := _add_crosshair_rect(hit_marker, Vector2(1.0, 13.0), Vector2(18.0, 2.0), Color(1.0, 0.78, 0.24))
	d.rotation = deg_to_rad(-135.0)


func _add_crosshair_rect(parent: Control, position: Vector2, size: Vector2, color: Color = Color(0.86, 0.96, 1.0, 0.82)) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = position
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect


func toggle_settings_menu() -> void:
	_set_settings_open(not settings_open)


func _set_settings_open(open: bool) -> void:
	settings_open = open
	if settings_backdrop != null:
		settings_backdrop.visible = settings_open
	if settings_panel != null:
		settings_panel.visible = settings_open
	if player != null and player.has_method("set_gameplay_input_enabled"):
		player.call("set_gameplay_input_enabled", not settings_open and not rewards_pending)


func _build_settings_panel(root: Control) -> void:
	settings_backdrop = ColorRect.new()
	settings_backdrop.name = "FPSSettingsBackdrop"
	settings_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_backdrop.color = Color(0.012, 0.014, 0.018, 0.68)
	settings_backdrop.visible = false
	settings_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(settings_backdrop)

	settings_panel = PanelContainer.new()
	settings_panel.name = "FPSSettingsPanel"
	settings_panel.anchor_left = 0.13
	settings_panel.anchor_top = 0.07
	settings_panel.anchor_right = 0.87
	settings_panel.anchor_bottom = 0.93
	settings_panel.visible = false
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	settings_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Combat Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	var reset_controls_button := Button.new()
	reset_controls_button.text = "Reset Controls"
	reset_controls_button.pressed.connect(func() -> void:
		_reset_all_keybinds()
	)
	header.add_child(reset_controls_button)
	var reset_all_button := Button.new()
	reset_all_button.text = "Reset All"
	reset_all_button.pressed.connect(func() -> void:
		_reset_all_settings()
	)
	header.add_child(reset_all_button)
	var close_button := Button.new()
	close_button.text = "Back"
	close_button.pressed.connect(func() -> void:
		_set_settings_open(false)
	)
	header.add_child(close_button)

	settings_tabs = TabContainer.new()
	settings_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(settings_tabs)

	var aim_tab := _add_settings_tab(settings_tabs, "Aim")
	var reticle_tab := _add_settings_tab(settings_tabs, "Reticle")
	var controls_tab := _add_settings_tab(settings_tabs, "Controls")

	var aim_hint := Label.new()
	aim_hint.text = "Tune mouse feel before a duel. These changes apply instantly."
	aim_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aim_hint.add_theme_font_size_override("font_size", 13)
	aim_tab.add_child(aim_hint)
	_add_preset_row(aim_tab, "Aim Presets", [
		{"id": "default_fps", "label": "Default FPS"},
		{"id": "tactical", "label": "Tactical"},
		{"id": "controller", "label": "Controller"},
		{"id": "left_handed", "label": "Left-Handed"}
	])
	_add_setting_section(aim_tab, "Mouse")
	_add_slider_row(aim_tab, "Look Sensitivity", 0.00045, 0.0045, 0.00005, float(aim_settings.get("mouse_sensitivity", 0.00155)), func(value: float) -> void:
		aim_settings["mouse_sensitivity"] = value
		_apply_player_settings()
		_save_player_settings()
	)
	var ads_sensitivity_changed := func(value: float) -> void:
		aim_settings["ads_sensitivity_scale"] = value
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "ADS Sens Multiplier", 0.20, 1.0, 0.01, float(aim_settings.get("ads_sensitivity_scale", 0.62)), ads_sensitivity_changed, "x")
	_add_checkbox_row(aim_tab, "Toggle ADS", bool(aim_settings.get("ads_toggle", false)), func(enabled: bool) -> void:
		aim_settings["ads_toggle"] = enabled
		_apply_player_settings()
		_save_player_settings()
	)
	_add_checkbox_row(aim_tab, "Invert Y", bool(aim_settings.get("invert_y", false)), func(enabled: bool) -> void:
		aim_settings["invert_y"] = enabled
		_apply_player_settings()
		_save_player_settings()
	)
	_add_setting_section(aim_tab, "Controller Look")
	var gamepad_sens_changed := func(value: float) -> void:
		aim_settings["gamepad_look_sensitivity"] = value
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "Stick Sensitivity", 0.4, 6.0, 0.05, float(aim_settings.get("gamepad_look_sensitivity", 2.4)), gamepad_sens_changed)
	var deadzone_changed := func(value: float) -> void:
		aim_settings["gamepad_deadzone"] = value
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "Stick Deadzone", 0.04, 0.45, 0.01, float(aim_settings.get("gamepad_deadzone", 0.18)), deadzone_changed, "%")
	var curve_changed := func(value: float) -> void:
		aim_settings["gamepad_response_curve"] = value
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "Response Curve", 0.75, 3.0, 0.05, float(aim_settings.get("gamepad_response_curve", 1.55)), curve_changed)
	_add_setting_section(aim_tab, "Field of View")
	var hip_fov_changed := func(value: float) -> void:
		aim_settings["fov"] = value
		var ads_value := float(aim_settings.get("ads_fov", 56.0))
		if ads_value >= value:
			aim_settings["ads_fov"] = maxf(35.0, value - 4.0)
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "Hip-fire FOV", 65.0, 105.0, 1.0, float(aim_settings.get("fov", 74.0)), hip_fov_changed, "deg")
	var sprint_fov_changed := func(value: float) -> void:
		aim_settings["sprint_fov_add"] = value
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "Sprint FOV Boost", 0.0, 12.0, 1.0, float(aim_settings.get("sprint_fov_add", 5.0)), sprint_fov_changed, "deg")
	var ads_fov_changed := func(value: float) -> void:
		aim_settings["ads_fov"] = minf(value, float(aim_settings.get("fov", 74.0)) - 4.0)
		_apply_player_settings()
		_save_player_settings()
	_add_slider_row(aim_tab, "ADS FOV", 35.0, 90.0, 1.0, float(aim_settings.get("ads_fov", 56.0)), ads_fov_changed, "deg")

	var preview := Control.new()
	preview.name = "CrosshairPreview"
	preview.custom_minimum_size = Vector2(220, 120)
	reticle_tab.add_child(preview)
	var preview_crosshair := Control.new()
	preview_crosshair.name = "PreviewCrosshair"
	preview_crosshair.position = Vector2(110, 60)
	preview.add_child(preview_crosshair)

	_add_slider_row(reticle_tab, "Gap", 0.0, 24.0, 1.0, float(crosshair_settings.get("gap", 7.0)), func(value: float) -> void:
		crosshair_settings["gap"] = value
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	_add_slider_row(reticle_tab, "Length", 2.0, 22.0, 1.0, float(crosshair_settings.get("length", 8.0)), func(value: float) -> void:
		crosshair_settings["length"] = value
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	_add_slider_row(reticle_tab, "Thickness", 1.0, 8.0, 1.0, float(crosshair_settings.get("thickness", 2.0)), func(value: float) -> void:
		crosshair_settings["thickness"] = value
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	_add_slider_row(reticle_tab, "Dot", 0.0, 10.0, 1.0, float(crosshair_settings.get("dot_size", 2.0)), func(value: float) -> void:
		crosshair_settings["dot_size"] = value
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	_add_slider_row(reticle_tab, "Opacity", 0.15, 1.0, 0.05, float(crosshair_settings.get("opacity", 0.92)), func(value: float) -> void:
		crosshair_settings["opacity"] = value
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)

	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 10)
	reticle_tab.add_child(color_row)
	var color_label := Label.new()
	color_label.text = "Color"
	color_label.custom_minimum_size = Vector2(120, 0)
	color_row.add_child(color_label)
	var color_picker := ColorPickerButton.new()
	color_picker.color = _get_crosshair_color()
	color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_picker.color_changed.connect(func(color: Color) -> void:
		crosshair_settings["color"] = Color(color.r, color.g, color.b, float(crosshair_settings.get("opacity", 0.92)))
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	color_row.add_child(color_picker)

	_add_checkbox_row(reticle_tab, "Outline", bool(crosshair_settings.get("outline", true)), func(enabled: bool) -> void:
		crosshair_settings["outline"] = enabled
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)
	_add_checkbox_row(reticle_tab, "Dynamic gap", bool(crosshair_settings.get("dynamic_gap", true)), func(enabled: bool) -> void:
		crosshair_settings["dynamic_gap"] = enabled
		_update_crosshair()
		_rebuild_preview_crosshair(preview_crosshair)
		_save_player_settings()
	)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 8)
	reticle_tab.add_child(preset_row)
	for preset in [
		{"label": "Cyan", "color": Color(0.42, 0.95, 1.0, 0.95), "gap": 7.0, "length": 8.0},
		{"label": "Lime", "color": Color(0.60, 1.0, 0.24, 0.95), "gap": 5.0, "length": 7.0},
		{"label": "Magenta", "color": Color(1.0, 0.25, 0.78, 0.95), "gap": 8.0, "length": 9.0}
	]:
		var button := Button.new()
		button.text = String(preset.get("label", "Preset"))
		button.pressed.connect(func() -> void:
			crosshair_settings["color"] = preset.get("color", _get_crosshair_color())
			crosshair_settings["gap"] = preset.get("gap", crosshair_settings.get("gap", 7.0))
			crosshair_settings["length"] = preset.get("length", crosshair_settings.get("length", 8.0))
			color_picker.color = _get_crosshair_color()
			_update_crosshair()
			_rebuild_preview_crosshair(preview_crosshair)
			_save_player_settings()
		)
		preset_row.add_child(button)

	rebind_status_label = Label.new()
	rebind_status_label.text = "Pick Rebind, then press a key, mouse button, or controller button/trigger. Escape cancels and stays fixed for settings."
	rebind_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rebind_status_label.add_theme_font_size_override("font_size", 13)
	controls_tab.add_child(rebind_status_label)
	_add_preset_row(controls_tab, "Control Presets", [
		{"id": "default_fps", "label": "Default FPS"},
		{"id": "tactical", "label": "Tactical"},
		{"id": "controller", "label": "Controller"},
		{"id": "left_handed", "label": "Left-Handed"}
	])

	keybind_buttons.clear()
	_add_keybind_group(controls_tab, "Movement", "movement")
	_add_keybind_group(controls_tab, "Combat", "combat")
	_add_keybind_group(controls_tab, "Card Abilities", "ability")
	_add_keybind_group(controls_tab, "System", "system")
	_refresh_keybind_rows()

	_rebuild_preview_crosshair(preview_crosshair)

	settings_footer_label = Label.new()
	settings_footer_label.name = "SettingsFooter"
	settings_footer_label.text = "Esc / Back closes settings. Changes save instantly."
	settings_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_footer_label.add_theme_font_size_override("font_size", 12)
	settings_footer_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
	layout.add_child(settings_footer_label)


func _add_settings_tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	var tab := VBoxContainer.new()
	tab.add_theme_constant_override("separation", 10)
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(tab)
	return tab


func _build_reward_panel(root: Control) -> void:
	reward_backdrop = ColorRect.new()
	reward_backdrop.name = "RewardBackdrop"
	reward_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	reward_backdrop.color = Color(0.006, 0.009, 0.012, 0.62)
	reward_backdrop.visible = false
	reward_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(reward_backdrop)

	reward_panel = PanelContainer.new()
	reward_panel.name = "RewardPanel"
	reward_panel.anchor_left = 0.235
	reward_panel.anchor_top = 0.155
	reward_panel.anchor_right = 0.765
	reward_panel.anchor_bottom = 0.690
	reward_panel.visible = false
	reward_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_panel.add_theme_stylebox_override("panel", _make_hud_panel_style(Color(0.014, 0.018, 0.022, 0.94), Color(1.0, 0.66, 0.22, 0.86), 6, 2))
	root.add_child(reward_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	reward_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	reward_label = RichTextLabel.new()
	reward_label.bbcode_enabled = true
	reward_label.fit_content = true
	reward_label.scroll_active = false
	reward_label.custom_minimum_size = Vector2(560, 112)
	reward_label.add_theme_font_size_override("normal_font_size", 16)
	layout.add_child(reward_label)

	reward_summary_label = Label.new()
	reward_summary_label.name = "RewardSummaryLabel"
	reward_summary_label.text = "Pick one power-up to equip before the next wave."
	reward_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_summary_label.add_theme_font_size_override("font_size", 12)
	reward_summary_label.add_theme_color_override("font_color", Color(0.78, 0.90, 0.92, 0.94))
	layout.add_child(reward_summary_label)

	var row := HBoxContainer.new()
	row.name = "RewardButtonRow"
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(row)
	for i in range(3):
		var button := Button.new()
		button.name = "RewardButton%d" % i
		button.text = "Reward %d" % (i + 1)
		button.custom_minimum_size = Vector2(160, 92)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(Callable(self, "_select_reward").bind(i))
		button.focus_entered.connect(Callable(self, "_set_active_reward_index").bind(i))
		button.mouse_entered.connect(Callable(self, "_set_active_reward_index").bind(i))
		_style_reward_button(button, false)
		row.add_child(button)

	reward_focus_label = RichTextLabel.new()
	reward_focus_label.name = "RewardFocusLabel"
	reward_focus_label.bbcode_enabled = true
	reward_focus_label.fit_content = true
	reward_focus_label.scroll_active = false
	reward_focus_label.custom_minimum_size = Vector2(560, 56)
	reward_focus_label.add_theme_font_size_override("normal_font_size", 13)
	layout.add_child(reward_focus_label)


func _add_slider_row(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float, value: float, callback: Callable, value_suffix: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(160, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(new_value: float) -> void:
		callback.call(new_value)
	)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(74, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_setting_value(value, value_suffix)
	slider.value_changed.connect(func(new_value: float) -> void:
		value_label.text = _format_setting_value(new_value, value_suffix)
	)
	row.add_child(value_label)


func _add_checkbox_row(parent: VBoxContainer, label_text: String, enabled: bool, callback: Callable) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = enabled
	checkbox.toggled.connect(func(new_value: bool) -> void:
		callback.call(new_value)
	)
	parent.add_child(checkbox)


func _add_preset_row(parent: VBoxContainer, title_text: String, presets: Array[Dictionary]) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	parent.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for preset in presets:
		var button := Button.new()
		button.text = String(preset.get("label", "Preset"))
		var preset_id := String(preset.get("id", "default_fps"))
		button.pressed.connect(func() -> void:
			_apply_settings_preset(preset_id)
		)
		row.add_child(button)


func _add_setting_section(parent: VBoxContainer, title_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0))
	parent.add_child(title)


func _add_keybind_group(parent: VBoxContainer, title_text: String, group: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)
	for binding in _get_rebindable_actions():
		if String(binding.get("group", "")) == group:
			_add_keybind_row(parent, binding)


func _add_keybind_row(parent: VBoxContainer, binding: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := Label.new()
	label.text = String(binding.get("label", binding.get("action", "Action")))
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var current := Label.new()
	current.name = "CurrentBind_%s" % String(binding.get("action", "action"))
	current.text = _get_action_binding_text(StringName(binding.get("action", &"")))
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(current)
	var warning := Label.new()
	warning.name = "BindWarning_%s" % String(binding.get("action", "action"))
	warning.custom_minimum_size = Vector2(170, 0)
	warning.add_theme_font_size_override("font_size", 12)
	warning.add_theme_color_override("font_color", Color(1.0, 0.46, 0.28))
	row.add_child(warning)
	var button := Button.new()
	button.text = "Rebind"
	var action := StringName(binding.get("action", &""))
	button.pressed.connect(func() -> void:
		_start_rebinding(action)
	)
	row.add_child(button)
	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(func() -> void:
		_reset_action_binding(action)
	)
	row.add_child(reset_button)
	keybind_buttons[action] = {"button": button, "label": current, "warning": warning}


func _format_setting_value(value: float, suffix: String = "") -> String:
	if suffix == "deg":
		return "%d deg" % int(roundf(value))
	if suffix == "x":
		return "%.2fx" % value
	if suffix == "%":
		return "%d%%" % int(roundf(value * 100.0))
	if value < 0.01:
		return "%.4f" % value
	return "%.1f" % value


func _apply_settings_preset(preset_id: String) -> void:
	match preset_id:
		"tactical":
			aim_settings.merge({
				"mouse_sensitivity": 0.00115,
				"gamepad_look_sensitivity": 1.9,
				"gamepad_deadzone": 0.16,
				"gamepad_response_curve": 1.85,
				"fov": 80.0,
				"ads_fov": 52.0,
				"ads_sensitivity_scale": 0.48,
				"ads_toggle": false
			}, true)
			crosshair_settings.merge({"gap": 5.0, "length": 7.0, "thickness": 2.0, "dot_size": 1.0, "dynamic_gap": false}, true)
			_apply_default_keybinds()
		"controller":
			aim_settings.merge({
				"mouse_sensitivity": 0.00155,
				"gamepad_look_sensitivity": 3.0,
				"gamepad_deadzone": 0.20,
				"gamepad_response_curve": 1.35,
				"fov": 76.0,
				"ads_fov": 56.0,
				"ads_sensitivity_scale": 0.66,
				"ads_toggle": true
			}, true)
			crosshair_settings.merge({"gap": 8.0, "length": 9.0, "thickness": 3.0, "dot_size": 3.0, "dynamic_gap": true}, true)
			_apply_default_keybinds()
		"left_handed":
			aim_settings.merge({
				"mouse_sensitivity": 0.00155,
				"gamepad_look_sensitivity": 2.4,
				"gamepad_deadzone": 0.18,
				"gamepad_response_curve": 1.55,
				"fov": 74.0,
				"ads_fov": 56.0,
				"ads_sensitivity_scale": 0.62,
				"ads_toggle": false
			}, true)
			crosshair_settings.merge(DEFAULT_CROSSHAIR_SETTINGS.duplicate(true), true)
			_apply_left_handed_keybinds()
		_:
			_reset_all_settings()
			return
	_apply_player_settings()
	_update_crosshair()
	_refresh_keybind_rows()
	_save_player_settings()
	if rebind_status_label != null:
		rebind_status_label.text = "%s preset applied." % preset_id.capitalize()
	if settings_footer_label != null:
		settings_footer_label.text = "Preset applied. Changes save instantly."


func _reset_all_settings() -> void:
	aim_settings = DEFAULT_AIM_SETTINGS.duplicate(true)
	crosshair_settings = DEFAULT_CROSSHAIR_SETTINGS.duplicate(true)
	_apply_default_keybinds()
	_apply_player_settings()
	_update_crosshair()
	_refresh_keybind_rows()
	_save_player_settings()
	if rebind_status_label != null:
		rebind_status_label.text = "All aim, reticle, and controls reset to defaults."
	if settings_footer_label != null:
		settings_footer_label.text = "Defaults restored. Close and reopen to refresh slider positions."


func _apply_default_keybinds() -> void:
	for binding in _get_rebindable_actions():
		_apply_binding_events(StringName(binding.get("action", &"")), _get_default_input_events(binding))


func _apply_left_handed_keybinds() -> void:
	_apply_default_keybinds()
	_apply_encoded_binding(&"fps_move_forward", "key:%d|joy_button:%d" % [KEY_UP, JOY_BUTTON_DPAD_UP])
	_apply_encoded_binding(&"fps_move_back", "key:%d|joy_button:%d" % [KEY_DOWN, JOY_BUTTON_DPAD_DOWN])
	_apply_encoded_binding(&"fps_move_left", "key:%d|joy_button:%d" % [KEY_LEFT, JOY_BUTTON_DPAD_LEFT])
	_apply_encoded_binding(&"fps_move_right", "key:%d|joy_button:%d" % [KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT])
	_apply_encoded_binding(&"fps_reload", "key:%d|joy_button:%d" % [KEY_ENTER, JOY_BUTTON_X])
	_apply_encoded_binding(&"fps_ability_1", "key:%d|joy_button:%d" % [KEY_U, JOY_BUTTON_LEFT_SHOULDER])
	_apply_encoded_binding(&"fps_ability_2", "key:%d|joy_button:%d" % [KEY_I, JOY_BUTTON_RIGHT_SHOULDER])
	_apply_encoded_binding(&"fps_ability_3", "key:%d|joy_button:%d" % [KEY_O, JOY_BUTTON_Y])
	_apply_encoded_binding(&"fps_ability_4", "key:%d|joy_button:%d" % [KEY_P, JOY_BUTTON_B])


func _apply_binding_events(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for event in events:
		InputMap.action_add_event(action, event)


func _get_rebindable_actions() -> Array[Dictionary]:
	return [
		{"action": &"fps_move_forward", "label": "Move Forward", "group": "movement", "default_key": KEY_W, "default_joy_button": JOY_BUTTON_DPAD_UP},
		{"action": &"fps_move_back", "label": "Move Back", "group": "movement", "default_key": KEY_S, "default_joy_button": JOY_BUTTON_DPAD_DOWN},
		{"action": &"fps_move_left", "label": "Move Left", "group": "movement", "default_key": KEY_A, "default_joy_button": JOY_BUTTON_DPAD_LEFT},
		{"action": &"fps_move_right", "label": "Move Right", "group": "movement", "default_key": KEY_D, "default_joy_button": JOY_BUTTON_DPAD_RIGHT},
		{"action": &"fps_jump", "label": "Jump", "group": "movement", "default_key": KEY_SPACE, "default_joy_button": JOY_BUTTON_A},
		{"action": &"fps_sprint", "label": "Sprint", "group": "movement", "default_key": KEY_SHIFT, "default_joy_button": JOY_BUTTON_LEFT_STICK},
		{"action": &"fps_crouch", "label": "Crouch", "group": "movement", "default_key": KEY_CTRL, "default_joy_button": JOY_BUTTON_RIGHT_STICK},
		{"action": &"fps_reload", "label": "Reload", "group": "combat", "default_key": KEY_R, "default_joy_button": JOY_BUTTON_X},
		{"action": &"fps_fire", "label": "Fire", "group": "combat", "default_mouse": MOUSE_BUTTON_LEFT, "default_joy_axis": JOY_AXIS_TRIGGER_RIGHT, "default_joy_axis_value": 1.0},
		{"action": &"fps_ads", "label": "Aim Down Sights", "group": "combat", "default_mouse": MOUSE_BUTTON_RIGHT, "default_joy_axis": JOY_AXIS_TRIGGER_LEFT, "default_joy_axis_value": 1.0},
		{"action": &"fps_quick_restart", "label": "Restart Encounter", "group": "system", "default_key": KEY_F5, "default_joy_button": JOY_BUTTON_START},
		{"action": &"fps_ability_1", "label": "Ability 1", "group": "ability", "default_key": KEY_Q, "default_joy_button": JOY_BUTTON_LEFT_SHOULDER},
		{"action": &"fps_ability_2", "label": "Ability 2", "group": "ability", "default_key": KEY_E, "default_joy_button": JOY_BUTTON_RIGHT_SHOULDER},
		{"action": &"fps_ability_3", "label": "Ability 3", "group": "ability", "default_key": KEY_C, "default_joy_button": JOY_BUTTON_Y},
		{"action": &"fps_ability_4", "label": "Ability 4", "group": "ability", "default_key": KEY_V, "default_joy_button": JOY_BUTTON_B}
	]


func _start_rebinding(action: StringName) -> void:
	rebinding_action = action
	rebinding_ignore_until_msec = Time.get_ticks_msec() + 160
	if rebind_status_label != null:
		rebind_status_label.text = "Press a key or mouse button for %s. Press Escape to cancel." % _get_action_label(action)


func _capture_rebind_event(event: InputEvent) -> bool:
	if Time.get_ticks_msec() < rebinding_ignore_until_msec:
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		if key_event.keycode == KEY_ESCAPE:
			_finish_rebinding(false)
			return true
		var new_event := InputEventKey.new()
		new_event.physical_keycode = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		new_event.keycode = key_event.keycode
		_apply_rebind_event(rebinding_action, new_event)
		return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return false
		var new_mouse := InputEventMouseButton.new()
		new_mouse.button_index = mouse_event.button_index
		_apply_rebind_event(rebinding_action, new_mouse)
		return true
	if event is InputEventJoypadButton:
		var joy_button_event := event as InputEventJoypadButton
		if not joy_button_event.pressed:
			return false
		var new_joy_button := InputEventJoypadButton.new()
		new_joy_button.button_index = joy_button_event.button_index
		_apply_rebind_event(rebinding_action, new_joy_button)
		return true
	if event is InputEventJoypadMotion:
		var joy_motion_event := event as InputEventJoypadMotion
		if absf(joy_motion_event.axis_value) < 0.55:
			return false
		var new_joy_motion := InputEventJoypadMotion.new()
		new_joy_motion.axis = joy_motion_event.axis
		new_joy_motion.axis_value = 1.0 if joy_motion_event.axis_value > 0.0 else -1.0
		_apply_rebind_event(rebinding_action, new_joy_motion)
		return true
	return false


func _apply_rebind_event(action: StringName, event: InputEvent) -> void:
	if action.is_empty():
		return
	var conflict := _find_binding_conflict(event, action)
	if not conflict.is_empty():
		if rebind_status_label != null:
			rebind_status_label.text = "%s is already used by %s. Pick another input or press Escape." % [_get_input_event_label(event), _get_action_label(conflict)]
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save_player_settings()
	_finish_rebinding(true)


func _finish_rebinding(success: bool) -> void:
	var action := rebinding_action
	rebinding_action = &""
	rebinding_ignore_until_msec = 0
	_refresh_keybind_rows()
	if rebind_status_label != null:
		if success:
			rebind_status_label.text = "%s is now %s." % [_get_action_label(action), _get_action_binding_text(action)]
		else:
			rebind_status_label.text = "Rebind canceled."


func _refresh_keybind_rows() -> void:
	for action in keybind_buttons.keys():
		var row: Dictionary = keybind_buttons[action]
		var current: Label = row.get("label", null)
		if current != null:
			current.text = _get_action_binding_text(action)
			var conflict_text := _get_action_conflict_text(action)
			current.add_theme_color_override("font_color", Color(1.0, 0.48, 0.30) if not conflict_text.is_empty() else Color(0.88, 0.94, 1.0))
		var warning: Label = row.get("warning", null)
		if warning != null:
			warning.text = _get_action_conflict_text(action)


func _get_action_label(action: StringName) -> String:
	for binding in _get_rebindable_actions():
		if StringName(binding.get("action", &"")) == action:
			return String(binding.get("label", action))
	return String(action)


func _get_action_binding_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	var names: Array[String] = []
	for event in events:
		names.append(_get_input_event_label(event))
	return " / ".join(names)


func _get_primary_action_binding_text(action: StringName) -> String:
	var text := _get_action_binding_text(action)
	if text == "Unbound":
		return String(action)
	return text.split(" / ", false, 1)[0]


func _get_default_input_events(binding: Dictionary) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if binding.has("default_mouse"):
		var mouse := InputEventMouseButton.new()
		mouse.button_index = int(binding.get("default_mouse", MOUSE_BUTTON_LEFT))
		events.append(mouse)
	if binding.has("default_key"):
		var key := InputEventKey.new()
		key.physical_keycode = int(binding.get("default_key", KEY_NONE))
		key.keycode = int(binding.get("default_key", KEY_NONE))
		events.append(key)
	if binding.has("default_joy_button"):
		var joy_button := InputEventJoypadButton.new()
		joy_button.button_index = int(binding.get("default_joy_button", JOY_BUTTON_A))
		events.append(joy_button)
	if binding.has("default_joy_axis"):
		var joy_axis := InputEventJoypadMotion.new()
		joy_axis.axis = int(binding.get("default_joy_axis", JOY_AXIS_TRIGGER_RIGHT))
		joy_axis.axis_value = float(binding.get("default_joy_axis_value", 1.0))
		events.append(joy_axis)
	return events


func _encode_action_binding(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return ""
	var encoded: Array[String] = []
	for event in events:
		var event_text := _encode_input_event(event)
		if not event_text.is_empty():
			encoded.append(event_text)
	return "|".join(encoded)


func _encode_input_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		return "key:%d" % int(code)
	if event is InputEventMouseButton:
		return "mouse:%d" % int((event as InputEventMouseButton).button_index)
	if event is InputEventJoypadButton:
		return "joy_button:%d" % int((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var sign := 1 if motion.axis_value >= 0.0 else -1
		return "joy_axis:%d:%d" % [int(motion.axis), sign]
	return ""


func _apply_encoded_binding(action: StringName, encoded: String) -> void:
	var events: Array[InputEvent] = []
	for encoded_event in encoded.split("|", false):
		var event := _decode_input_event(encoded_event)
		if event != null:
			events.append(event)
	if events.is_empty():
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for event in events:
		InputMap.action_add_event(action, event)


func _decode_input_event(encoded: String) -> InputEvent:
	var parts := encoded.split(":", false)
	if parts.size() < 2:
		return null
	match parts[0]:
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(parts[1])
			key.keycode = int(parts[1])
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(parts[1])
			return mouse
		"joy_button":
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = int(parts[1])
			return joy_button
		"joy_axis":
			if parts.size() < 3:
				return null
			var joy_axis := InputEventJoypadMotion.new()
			joy_axis.axis = int(parts[1])
			joy_axis.axis_value = 1.0 if int(parts[2]) >= 0 else -1.0
			return joy_axis
		_:
			return null


func _reset_action_binding(action: StringName) -> void:
	for binding in _get_rebindable_actions():
		if StringName(binding.get("action", &"")) != action:
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for event in _get_default_input_events(binding):
			InputMap.action_add_event(action, event)
		_save_player_settings()
		_refresh_keybind_rows()
		if rebind_status_label != null:
			rebind_status_label.text = "%s reset to default." % _get_action_label(action)
		return


func _reset_all_keybinds() -> void:
	for binding in _get_rebindable_actions():
		_reset_action_binding(StringName(binding.get("action", &"")))
	_save_player_settings()
	_refresh_keybind_rows()
	if rebind_status_label != null:
		rebind_status_label.text = "Controls reset to keyboard, mouse, and gamepad defaults."


func _find_binding_conflict(event: InputEvent, except_action: StringName = &"") -> StringName:
	var signature := _get_input_event_signature(event)
	if signature.is_empty():
		return &""
	for binding in _get_rebindable_actions():
		var action := StringName(binding.get("action", &""))
		if action == except_action or not InputMap.has_action(action):
			continue
		for existing_event in InputMap.action_get_events(action):
			if _get_input_event_signature(existing_event) == signature:
				return action
	return &""


func _get_action_conflict_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var conflict := _find_binding_conflict(event, action)
		if not conflict.is_empty():
			return "Conflict: %s" % _get_action_label(conflict)
	return ""


func _get_input_event_signature(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		return "key:%d" % int(code)
	if event is InputEventMouseButton:
		return "mouse:%d" % int((event as InputEventMouseButton).button_index)
	if event is InputEventJoypadButton:
		return "joy_button:%d" % int((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var sign := 1 if motion.axis_value >= 0.0 else -1
		return "joy_axis:%d:%d" % [int(motion.axis), sign]
	return ""


func _get_input_event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			return "Mouse Left"
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			return "Mouse Right"
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			return "Mouse Middle"
		return "Mouse %d" % int(mouse_event.button_index)
	if event is InputEventJoypadButton:
		return _get_joypad_button_label(int((event as InputEventJoypadButton).button_index))
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return _get_joypad_axis_label(int(motion.axis), motion.axis_value)
	return event.as_text()


func _get_joypad_button_label(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "Pad A"
		JOY_BUTTON_B:
			return "Pad B"
		JOY_BUTTON_X:
			return "Pad X"
		JOY_BUTTON_Y:
			return "Pad Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_DPAD_UP:
			return "D-Pad Up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-Pad Down"
		JOY_BUTTON_DPAD_LEFT:
			return "D-Pad Left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-Pad Right"
		_:
			return "Pad Button %d" % button_index


func _get_joypad_axis_label(axis: int, value: float) -> String:
	if axis == JOY_AXIS_TRIGGER_LEFT:
		return "LT"
	if axis == JOY_AXIS_TRIGGER_RIGHT:
		return "RT"
	var direction := "+" if value >= 0.0 else "-"
	return "Axis %d%s" % [axis, direction]


func _update_crosshair(force: bool = true, delta: float = 0.0) -> void:
	if crosshair == null:
		return
	if not force:
		crosshair_refresh_elapsed += delta
		if crosshair_refresh_elapsed < CROSSHAIR_DYNAMIC_REFRESH_INTERVAL:
			return
	crosshair_refresh_elapsed = 0.0
	var signature := _get_crosshair_signature(true)
	if signature == crosshair_signature:
		return
	crosshair_signature = signature
	_rebuild_crosshair_on(crosshair, true)


func _rebuild_preview_crosshair(preview_crosshair: Control) -> void:
	_rebuild_crosshair_on(preview_crosshair, false)


func _rebuild_crosshair_on(target: Control, use_dynamic_gap: bool) -> void:
	_clear_children(target)
	var color := _get_crosshair_color()
	var gap := _get_crosshair_gap(use_dynamic_gap)
	var length := float(crosshair_settings.get("length", 8.0))
	var thickness := float(crosshair_settings.get("thickness", 2.0))
	var dot_size := float(crosshair_settings.get("dot_size", 2.0))
	var outline := bool(crosshair_settings.get("outline", true))
	var outline_color := Color(0.02, 0.018, 0.012, float(crosshair_settings.get("outline_opacity", 0.62)))

	_add_crosshair_pip(target, Vector2(-thickness * 0.5, -gap - length), Vector2(thickness, length), color, outline, outline_color)
	_add_crosshair_pip(target, Vector2(-thickness * 0.5, gap), Vector2(thickness, length), color, outline, outline_color)
	_add_crosshair_pip(target, Vector2(-gap - length, -thickness * 0.5), Vector2(length, thickness), color, outline, outline_color)
	_add_crosshair_pip(target, Vector2(gap, -thickness * 0.5), Vector2(length, thickness), color, outline, outline_color)
	if dot_size > 0.0:
		_add_crosshair_pip(target, Vector2(-dot_size * 0.5, -dot_size * 0.5), Vector2(dot_size, dot_size), color, outline, outline_color)


func _get_crosshair_gap(use_dynamic_gap: bool) -> float:
	var gap := float(crosshair_settings.get("gap", 7.0))
	if use_dynamic_gap and bool(crosshair_settings.get("dynamic_gap", true)) and player != null and player.has_method("get_horizontal_speed_ratio"):
		gap += float(player.call("get_horizontal_speed_ratio")) * 5.0
	return snappedf(gap, 0.25)


func _get_crosshair_signature(use_dynamic_gap: bool) -> String:
	var color := _get_crosshair_color()
	return "%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%s|%s" % [
		color.r,
		color.g,
		color.b,
		color.a,
		_get_crosshair_gap(use_dynamic_gap),
		float(crosshair_settings.get("length", 8.0)),
		float(crosshair_settings.get("thickness", 2.0)),
		float(crosshair_settings.get("dot_size", 2.0)),
		float(crosshair_settings.get("outline_opacity", 0.62)),
		str(bool(crosshair_settings.get("outline", true))),
		str(bool(crosshair_settings.get("dynamic_gap", true)))
	]


func _add_crosshair_pip(parent: Control, position: Vector2, size: Vector2, color: Color, outline: bool, outline_color: Color) -> void:
	if outline:
		_add_crosshair_rect(parent, position - Vector2.ONE, size + Vector2(2.0, 2.0), outline_color)
	_add_crosshair_rect(parent, position, size, color)


func _get_crosshair_color() -> Color:
	var color_value: Variant = crosshair_settings.get("color", Color(0.72, 0.96, 1.0, 0.92))
	var color := Color(0.72, 0.96, 1.0, 0.92)
	if typeof(color_value) == TYPE_COLOR:
		color = color_value
	color.a = float(crosshair_settings.get("opacity", color.a))
	return color


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _reserve_effect_slots(incoming_count: int = 1) -> void:
	if effects_root == null:
		return
	var target_count := maxi(0, MAX_TRANSIENT_EFFECTS - maxi(1, incoming_count))
	var trimmed := 0
	while effects_root.get_child_count() > target_count and trimmed < MAX_TRANSIENT_EFFECTS:
		var child := effects_root.get_child(0)
		if child == null:
			return
		effects_root.remove_child(child)
		child.queue_free()
		trimmed += 1


func _apply_player_settings() -> void:
	if player != null and player.has_method("apply_aim_settings"):
		player.call("apply_aim_settings", aim_settings)


func _load_player_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	aim_settings["mouse_sensitivity"] = float(config.get_value("aim", "mouse_sensitivity", aim_settings.get("mouse_sensitivity", 0.00155)))
	aim_settings["gamepad_look_sensitivity"] = float(config.get_value("aim", "gamepad_look_sensitivity", aim_settings.get("gamepad_look_sensitivity", 2.4)))
	aim_settings["gamepad_deadzone"] = float(config.get_value("aim", "gamepad_deadzone", aim_settings.get("gamepad_deadzone", 0.18)))
	aim_settings["gamepad_response_curve"] = float(config.get_value("aim", "gamepad_response_curve", aim_settings.get("gamepad_response_curve", 1.55)))
	aim_settings["fov"] = float(config.get_value("aim", "fov", aim_settings.get("fov", 74.0)))
	aim_settings["sprint_fov_add"] = float(config.get_value("aim", "sprint_fov_add", aim_settings.get("sprint_fov_add", 5.0)))
	aim_settings["ads_fov"] = float(config.get_value("aim", "ads_fov", aim_settings.get("ads_fov", 56.0)))
	aim_settings["ads_sensitivity_scale"] = float(config.get_value("aim", "ads_sensitivity_scale", aim_settings.get("ads_sensitivity_scale", 0.62)))
	aim_settings["ads_toggle"] = bool(config.get_value("aim", "ads_toggle", aim_settings.get("ads_toggle", false)))
	aim_settings["invert_y"] = bool(config.get_value("aim", "invert_y", aim_settings.get("invert_y", false)))
	crosshair_settings["gap"] = float(config.get_value("crosshair", "gap", crosshair_settings.get("gap", 7.0)))
	crosshair_settings["length"] = float(config.get_value("crosshair", "length", crosshair_settings.get("length", 8.0)))
	crosshair_settings["thickness"] = float(config.get_value("crosshair", "thickness", crosshair_settings.get("thickness", 2.0)))
	crosshair_settings["dot_size"] = float(config.get_value("crosshair", "dot_size", crosshair_settings.get("dot_size", 2.0)))
	crosshair_settings["opacity"] = float(config.get_value("crosshair", "opacity", crosshair_settings.get("opacity", 0.92)))
	crosshair_settings["outline"] = bool(config.get_value("crosshair", "outline", crosshair_settings.get("outline", true)))
	crosshair_settings["dynamic_gap"] = bool(config.get_value("crosshair", "dynamic_gap", crosshair_settings.get("dynamic_gap", true)))
	var color_value: Variant = config.get_value("crosshair", "color", crosshair_settings.get("color", Color(0.72, 0.96, 1.0, 0.92)))
	if typeof(color_value) == TYPE_COLOR:
		crosshair_settings["color"] = color_value
	for binding in _get_rebindable_actions():
		var action := StringName(binding.get("action", &""))
		var encoded := String(config.get_value("keybinds", String(action), ""))
		if not encoded.is_empty():
			_apply_encoded_binding(action, encoded)


func _save_player_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("aim", "mouse_sensitivity", aim_settings.get("mouse_sensitivity", 0.00155))
	config.set_value("aim", "gamepad_look_sensitivity", aim_settings.get("gamepad_look_sensitivity", 2.4))
	config.set_value("aim", "gamepad_deadzone", aim_settings.get("gamepad_deadzone", 0.18))
	config.set_value("aim", "gamepad_response_curve", aim_settings.get("gamepad_response_curve", 1.55))
	config.set_value("aim", "fov", aim_settings.get("fov", 74.0))
	config.set_value("aim", "sprint_fov_add", aim_settings.get("sprint_fov_add", 5.0))
	config.set_value("aim", "ads_fov", aim_settings.get("ads_fov", 56.0))
	config.set_value("aim", "ads_sensitivity_scale", aim_settings.get("ads_sensitivity_scale", 0.62))
	config.set_value("aim", "ads_toggle", aim_settings.get("ads_toggle", false))
	config.set_value("aim", "invert_y", aim_settings.get("invert_y", false))
	config.set_value("crosshair", "color", _get_crosshair_color())
	config.set_value("crosshair", "gap", crosshair_settings.get("gap", 7.0))
	config.set_value("crosshair", "length", crosshair_settings.get("length", 8.0))
	config.set_value("crosshair", "thickness", crosshair_settings.get("thickness", 2.0))
	config.set_value("crosshair", "dot_size", crosshair_settings.get("dot_size", 2.0))
	config.set_value("crosshair", "opacity", crosshair_settings.get("opacity", 0.92))
	config.set_value("crosshair", "outline", crosshair_settings.get("outline", true))
	config.set_value("crosshair", "dynamic_gap", crosshair_settings.get("dynamic_gap", true))
	for binding in _get_rebindable_actions():
		var action := StringName(binding.get("action", &""))
		config.set_value("keybinds", String(action), _encode_action_binding(action))
	config.save(SETTINGS_PATH)


func _spawn_wave() -> void:
	if enemies_root == null:
		return
	for child in enemies_root.get_children():
		child.queue_free()
	wave_active = true
	rewards_pending = false
	current_wave_kills = 0
	restart_timer = 0.0
	wave_started_msec = Time.get_ticks_msec()
	if status_label != null:
		status_label.text = ""
	var extra_health := (wave_index - 1) * 12
	var wave_defs := _get_objective_enemy_defs()
	current_wave_enemy_total = wave_defs.size()
	for data in wave_defs:
		var enemy := FPS_DRONE_SCRIPT.new()
		enemy.name = String(data.get("name", "Enemy")).replace(" ", "")
		var copy := data.duplicate(true)
		copy["health"] = int(copy.get("health", 70)) + extra_health
		enemy.configure(copy, player, self)
		enemies_root.add_child(enemy)
		enemy.global_position = copy.get("position", Vector3.ZERO)


func _get_objective_enemy_defs() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	for data in enemy_defs:
		var copy := (data as Dictionary).duplicate(true)
		copy["position"] = _get_map_spawn_for_enemy(copy)
		match objective_mode:
			"duel":
				if String(copy.get("name", "")) == objective_target_name:
					copy["health"] = int(copy.get("health", 70)) + 28
					copy["speed"] = float(copy.get("speed", 3.5)) + 0.35
					copy["attack_damage"] = int(copy.get("attack_damage", 12)) + 2
					copy["ranged_attack_range"] = float(copy.get("ranged_attack_range", 10.0)) + 1.5
					copy["hold_distance"] = float(copy.get("hold_distance", 6.5)) + 0.75
					copy["color"] = Color(1.0, 0.48, 0.24)
					copy["objective_target"] = true
			"defend":
				if String(copy.get("archetype", "")) == "charger":
					copy["speed"] = float(copy.get("speed", 3.5)) + 0.55
					copy["attack_damage"] = int(copy.get("attack_damage", 10)) + 2
				if String(copy.get("archetype", "")) == "shield":
					copy["position"] = _map_cell_to_world(Vector2i(1, 1)) + Vector3(0.8, 0.17, -2.1)
					copy["health"] = int(copy.get("health", 90)) + 24
			"extract":
				if String(copy.get("archetype", "")) == "charger":
					copy["position"] = _map_cell_to_world(Vector2i(0, 1)) + Vector3(-1.2, 0.17, 0.0)
					copy["speed"] = float(copy.get("speed", 3.5)) + 0.55
				if String(copy.get("archetype", "")) == "ranged":
					copy["position"] = _map_cell_to_world(Vector2i(1, 2)) + Vector3(3.4, 0.17, 1.6)
			"boss_gate":
				if String(copy.get("name", "")) == "Hexmonger":
					continue
		defs.append(copy)
	if objective_mode == "boss_gate":
		defs.append(_get_boss_gate_enemy_def())
	return _expand_wave_enemy_defs(defs)


func _get_wave_enemy_target_count() -> int:
	return clampi(MIN_ENEMIES_PER_WAVE + maxi(0, wave_index - 1), MIN_ENEMIES_PER_WAVE, MAX_ENEMIES_PER_WAVE)


func _expand_wave_enemy_defs(base_defs: Array[Dictionary]) -> Array[Dictionary]:
	var expanded: Array[Dictionary] = []
	for data in base_defs:
		expanded.append(data.duplicate(true))
	if expanded.is_empty():
		return expanded

	var templates: Array = []
	for data in expanded:
		if not bool(data.get("objective_target", false)):
			templates.append(data.duplicate(true))
	if templates.is_empty():
		for data in expanded:
			templates.append(data.duplicate(true))

	var target_count := _get_wave_enemy_target_count()
	var extra_index := 0
	while expanded.size() < target_count:
		var template: Dictionary = (templates[(extra_index + wave_index) % templates.size()] as Dictionary).duplicate(true)
		var base_name := String(template.get("name", "Enemy"))
		template["name"] = "%s Echo %d" % [base_name, extra_index + 1]
		template["objective_target"] = false
		template["position"] = _get_wave_spawn_position(expanded.size())
		template["speed"] = float(template.get("speed", 3.4)) + minf(0.55, float(maxi(0, wave_index - 1)) * 0.06)
		expanded.append(template)
		extra_index += 1
	return expanded


func _get_wave_spawn_position(spawn_number: int) -> Vector3:
	var cells := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2)
	]
	var offsets := [
		Vector3(-1.4, 0.17, -1.1),
		Vector3(1.1, 0.17, -0.7),
		Vector3(0.2, 0.17, 1.2),
		Vector3(-0.8, 0.17, 1.5),
		Vector3(1.5, 0.17, 0.8),
		Vector3(-1.1, 0.17, 0.3),
		Vector3(0.8, 0.17, -1.4),
		Vector3(1.7, 0.17, 1.4)
	]
	var cell: Vector2i = cells[(spawn_number + wave_index) % cells.size()]
	return _map_cell_to_world(cell) + offsets[(spawn_number * 2 + wave_index) % offsets.size()]


func _get_map_spawn_for_enemy(data: Dictionary) -> Vector3:
	match String(data.get("archetype", "chaser")):
		"ranged":
			return _map_cell_to_world(Vector2i(2, 0)) + Vector3(0.8, 0.17, -1.1)
		"charger":
			return _map_cell_to_world(Vector2i(0, 1)) + Vector3(-1.0, 0.17, -0.7)
		"shield":
			return _map_cell_to_world(Vector2i(2, 1)) + Vector3(0.4, 0.17, -0.5)
		_:
			return _map_cell_to_world(Vector2i(1, 0)) + Vector3(0.0, 0.17, -0.9)


func _get_boss_gate_enemy_def() -> Dictionary:
	return {
		"name": "Gate Champion",
		"position": _map_cell_to_world(Vector2i(1, 0)) + Vector3(0.0, 0.17, -1.5),
		"texture": "res://art/game/enemies/enemy_hexmonger.png",
		"color": Color(0.86, 0.42, 1.0),
		"archetype": "shield",
		"health": 238,
		"speed": 2.72,
		"attack_damage": 24,
		"attack_range": 2.05,
		"attack_cooldown": 0.92,
		"objective_target": true
	}


func _show_wave_rewards() -> void:
	reward_options = _build_reward_options()
	if reward_panel == null:
		return
	reward_return_in_progress = false
	active_reward_index = 0
	if reward_backdrop != null:
		reward_backdrop.visible = true
	reward_panel.visible = true
	reward_panel.move_to_front()
	if reward_label != null:
		var clear_time := float(Time.get_ticks_msec() - wave_started_msec) / 1000.0
		reward_label.text = "[center][font_size=22][b]WAVE %d CLEARED[/b][/font_size]\n[color=#ffd36a]%s %s[/color]  |  objective %d\n%s  |  %s\n[color=#8feeff]%.1fs[/color]  %d shots  %.0f%% hit rate  |  card powers %d[/center]" % [
			wave_index,
			String(objective_def.get("label", "Objective")),
			"complete" if objective_completed else ("failed" if objective_failed else "partial"),
			_calculate_objective_score(true, clear_time),
			String(active_hero_profile.get("name", "Gambler-Knight")),
			String(active_hero_profile.get("passive", "Ante Guard")),
			clear_time,
			shots_fired,
			_get_hit_rate() * 100.0,
			_get_total_ability_uses()
		]
	if reward_summary_label != null:
		var next_mode := _get_wave_objective_mode(wave_index + 1)
		var next_def: Dictionary = (OBJECTIVE_MODE_DEFS[next_mode] as Dictionary)
		reward_summary_label.text = "Choose one power-up. It applies now, then Wave %d starts: %s." % [
			wave_index + 1,
			String(next_def.get("label", "Objective"))
		]
	var buttons := reward_panel.find_children("RewardButton*", "Button", true, false)
	for i in range(buttons.size()):
		var button: Button = buttons[i] as Button
		if i < reward_options.size():
			var option: Dictionary = reward_options[i]
			button.text = _get_reward_button_text(i, option)
			button.tooltip_text = _get_reward_tooltip(option)
			button.disabled = false
			_style_reward_button(button, false, i == active_reward_index)
		else:
			button.disabled = true
			_style_reward_button(button, true, false)
	if player != null and player.has_method("set_gameplay_input_enabled"):
		player.call("set_gameplay_input_enabled", false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_reward_focus()
	_animate_reward_panel_open()
	_focus_reward_button(active_reward_index)


func _build_reward_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var objective_bonus := 2 if objective_completed else 0
	match objective_mode:
		"extract":
			options.append(_make_reward_option("Runner Edge", "damage", 2, 2 + objective_bonus, "Uncommon", ["extract", "duel"], "Dash-heavy clears turn into sharper opening weapon pressure."))
			options.append(_make_reward_option("Exit Plating", "armor", 8, 1 + objective_bonus, "Common", ["extract", "defend"], "Bank armor for risky grab-and-leave routes."))
			options.append(_make_reward_option("Sprint Ammo", "ammo", 24, 1 + objective_bonus, "Common", ["extract", "duel"], "Carry extra reserve ammo for longer rotations."))
		"duel":
			options.append(_make_reward_option("Marked Damage", "damage", 4, 2 + objective_bonus, "Rare" if objective_completed else "Uncommon", ["duel", "boss_gate"], "Marked kills become a bigger burst profile next round."))
			options.append(_make_reward_option("Read Cache", "ammo", 16, 1 + objective_bonus, "Common", ["duel", "extract"], "Intel clears leave enough ammo to play for another mark."))
			options.append(_make_reward_option("Duel Guard", "armor", 9, 1 + objective_bonus, "Common", ["duel", "defend"], "Survive the next committed fight with extra plating."))
		"defend":
			options.append(_make_reward_option("Fortified Guard", "armor", 14, 2 + objective_bonus, "Rare" if objective_completed else "Uncommon", ["defend", "hold_pot"], "Clean defenses become real armor for the next stand."))
			options.append(_make_reward_option("Reload Wall", "ammo", 18, 1 + objective_bonus, "Common", ["defend", "extract"], "A held lane leaves reload stock for longer fights."))
			options.append(_make_reward_option("Counter Damage", "damage", 3, 1 + objective_bonus, "Uncommon", ["defend", "duel"], "A stable hold converts into counter-pressure."))
		"boss_gate":
			options.append(_make_reward_option("Boss Tech", "damage", 5, 2 + objective_bonus, "Rare", ["boss_gate", "duel"], "Gate pressure becomes a major weapon-damage mod."))
			options.append(_make_reward_option("Gate Plating", "armor", 12, 1 + objective_bonus, "Uncommon", ["boss_gate", "defend"], "Boss survival becomes armor for the next gate or hold."))
			options.append(_make_reward_option("Ritual Ammo", "ammo", 20, 1 + objective_bonus, "Uncommon", ["boss_gate", "extract"], "Ritual clears leave reserve ammo for the next gamble."))
		_:
			options.append(_make_reward_option("Pot Anchor", "armor", 12, 2 + objective_bonus, "Uncommon", ["hold_pot", "defend"], "Holding center banks armor for the next stand."))
			options.append(_make_reward_option("Center Cut", "damage", 3, 1 + objective_bonus, "Uncommon", ["hold_pot", "duel"], "Owning center turns into stronger weapon pressure."))
			options.append(_make_reward_option("Table Ammo", "ammo", 18, 1 + objective_bonus, "Common", ["hold_pot", "extract"], "The table pays reserve ammo for another rotation."))
	return options


func _make_reward_option(label: String, kind: String, amount: int, chip_bonus: int, rarity: String, bias_modes: Array, summary: String) -> Dictionary:
	return {
		"label": label,
		"kind": kind,
		"amount": amount,
		"chip_bonus": chip_bonus,
		"rarity": rarity,
		"bias_modes": _string_array(bias_modes),
		"summary": summary,
		"mod_id": "%s_%s" % [kind, label.to_lower().replace(" ", "_").replace("-", "_")]
	}


func _select_reward(index: int) -> void:
	if reward_return_in_progress:
		return
	if index < 0 or index >= reward_options.size():
		_focus_reward_button(active_reward_index)
		return
	var reward: Dictionary = reward_options[index]
	active_reward_index = index
	reward_return_in_progress = true
	if reward_summary_label != null:
		reward_summary_label.text = "Equipping %s for Wave %d..." % [
			String(reward.get("label", "power-up")),
			wave_index + 1
		]
	var result := _build_arena_result(reward)
	rewards_pending = false
	if reward_backdrop != null:
		reward_backdrop.visible = false
	if reward_panel != null:
		reward_panel.visible = false
	call_deferred("_continue_after_wave_reward", reward, result)


func _continue_after_wave_reward(reward: Dictionary, result: Dictionary) -> void:
	_apply_in_arena_reward(reward, result)
	wave_index += 1
	_set_objective_mode(_get_wave_objective_mode(wave_index))
	rewards_pending = false
	reward_return_in_progress = false
	if player != null and player.has_method("set_gameplay_input_enabled"):
		player.call("set_gameplay_input_enabled", true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_spawn_wave()
	_show_status_flash("Wave %d: %s" % [wave_index, String(objective_def.get("label", "Objective"))], _get_objective_color())
	_refresh_ui()


func _apply_in_arena_reward(reward: Dictionary, result: Dictionary) -> void:
	if reward.is_empty():
		return
	var reward_mods: Array = active_bridge_payload.get("reward_mods", [])
	reward_mods.append(reward.duplicate(true))
	active_bridge_payload["reward_mods"] = reward_mods

	var economy: Dictionary = (active_bridge_payload.get("economy", {}) as Dictionary).duplicate(true)
	economy["chips"] = int(economy.get("chips", 0)) + int(result.get("chips_awarded", 0))
	var kind := String(reward.get("kind", "reward"))
	var amount := int(reward.get("amount", 0))
	match kind:
		"damage":
			var current_damage := int(active_weapon_profile.get("damage", 18))
			if player != null and player.weapon != null:
				current_damage = int(player.weapon.get("damage"))
			active_weapon_profile["damage"] = maxi(1, current_damage + amount)
		"armor":
			economy["armor"] = int(economy.get("armor", 0)) + amount
			if player != null and player.has_method("add_armor"):
				player.call("add_armor", amount)
		"ammo":
			economy["ammo"] = int(economy.get("ammo", 24)) + amount
			var current_magazine := int(active_weapon_profile.get("magazine", 30))
			if player != null and player.weapon != null:
				current_magazine = int(player.weapon.get("magazine_size"))
			active_weapon_profile["magazine"] = current_magazine + mini(6, maxi(1, int(roundf(float(amount) * 0.18))))
	active_bridge_payload["economy"] = economy

	var progression: Dictionary = (active_bridge_payload.get("progression", {}) as Dictionary).duplicate(true)
	var xp_gain := maxi(2, _get_wave_kills_for_scoring() + (2 if objective_completed else 0))
	progression["card_xp_pool"] = int(progression.get("card_xp_pool", 0)) + xp_gain
	active_bridge_payload["progression"] = progression

	for index in range(ability_cooldowns.size()):
		ability_cooldowns[index] = 0.0
	if player != null and player.weapon != null:
		if player.weapon.has_method("configure_from_bridge"):
			player.weapon.call("configure_from_bridge", active_weapon_profile, int(economy.get("ammo", 24)))
		elif player.weapon.has_method("force_ready"):
			player.weapon.call("force_ready")


func _handle_reward_input(event: InputEvent) -> bool:
	var navigation := _get_reward_navigation_delta(event)
	if navigation != 0:
		_move_reward_focus(navigation)
		return true
	var index := _get_reward_input_index(event)
	if index < 0:
		return false
	_select_reward(index)
	return true


func _get_reward_input_index(event: InputEvent) -> int:
	if not event is InputEventKey:
		return -1
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return -1
	var key := key_event.physical_keycode
	if key == KEY_NONE:
		key = key_event.keycode
	match key:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			return clampi(active_reward_index, 0, maxi(0, reward_options.size() - 1))
		_:
			return -1


func _get_reward_navigation_delta(event: InputEvent) -> int:
	if not event is InputEventKey:
		return 0
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return 0
	var key := key_event.physical_keycode
	if key == KEY_NONE:
		key = key_event.keycode
	match key:
		KEY_RIGHT, KEY_D, KEY_DOWN:
			return 1
		KEY_LEFT, KEY_A, KEY_UP:
			return -1
		_:
			return 0


func _move_reward_focus(direction: int) -> void:
	if reward_options.is_empty():
		return
	var next_index := wrapi(active_reward_index + direction, 0, reward_options.size())
	_set_active_reward_index(next_index)
	_focus_reward_button(next_index)


func _set_active_reward_index(index: int) -> void:
	active_reward_index = clampi(index, 0, maxi(0, reward_options.size() - 1))
	_refresh_reward_focus()


func _focus_reward_button(index: int) -> void:
	if reward_panel == null:
		return
	_set_active_reward_index(index)
	var button := reward_panel.get_node_or_null("MarginContainer/VBoxContainer/RewardButtonRow/RewardButton%d" % index) as Button
	if button != null and not button.disabled:
		button.grab_focus()


func _get_reward_button_text(index: int, option: Dictionary) -> String:
	var kind := _get_reward_kind_noun(String(option.get("kind", "reward")))
	var amount := int(option.get("amount", 0))
	var chips := int(option.get("chip_bonus", 0))
	return "%d  TAKE %s\n%s +%d %s\n+%d chips  |  %s" % [
		index + 1,
		String(option.get("label", "Reward")).to_upper(),
		String(option.get("rarity", "Common")).to_upper(),
		amount,
		kind,
		chips,
		_get_reward_kind_detail(String(option.get("kind", "reward")))
	]


func _get_reward_tooltip(option: Dictionary) -> String:
	return "%s\n%s\n%s\nBiases future prep toward: %s." % [
		String(option.get("label", "Reward")),
		_get_reward_focus_text(option),
		String(option.get("summary", "Equip now and keep the arena moving.")),
		", ".join(_string_array(option.get("bias_modes", [])))
	]


func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for entry in value:
			out.append(String(entry))
	return out


func _style_reward_button(button: Button, disabled: bool, active: bool = false) -> void:
	var reward_color := _get_reward_kind_color(_get_reward_kind_from_button(button))
	var active_border := Color(0.42, 0.96, 1.0, 0.92)
	var normal_bg := Color(0.055, 0.050, 0.044, 0.86) if not disabled else Color(0.03, 0.03, 0.03, 0.55)
	var normal_border := reward_color if not disabled else Color(0.24, 0.24, 0.24, 0.42)
	if active and not disabled:
		normal_bg = Color(0.105, 0.078, 0.045, 0.96)
		normal_border = active_border
	button.add_theme_stylebox_override("normal", _make_hud_panel_style(normal_bg, normal_border, 5, 1))
	button.add_theme_stylebox_override("hover", _make_hud_panel_style(Color(0.12, 0.090, 0.050, 0.94), Color(1.0, 0.78, 0.28, 0.92), 5, 2))
	button.add_theme_stylebox_override("focus", _make_hud_panel_style(Color(0.10, 0.086, 0.052, 0.40), Color(0.42, 0.96, 1.0, 0.86), 5, 2))
	button.add_theme_stylebox_override("pressed", _make_hud_panel_style(Color(0.18, 0.105, 0.040, 0.96), Color(1.0, 0.86, 0.32, 1.0), 5, 2))
	button.add_theme_stylebox_override("disabled", _make_hud_panel_style(Color(0.03, 0.03, 0.03, 0.48), Color(0.20, 0.20, 0.20, 0.35), 5, 1))
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72) if not disabled else Color(0.48, 0.48, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.84))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.98, 0.84))


func _refresh_reward_focus() -> void:
	if reward_panel == null:
		return
	var buttons := reward_panel.find_children("RewardButton*", "Button", true, false)
	for i in range(buttons.size()):
		var button: Button = buttons[i] as Button
		_style_reward_button(button, button.disabled, i == active_reward_index)
	if reward_focus_label == null:
		return
	if active_reward_index < 0 or active_reward_index >= reward_options.size():
		reward_focus_label.text = ""
		return
	var option: Dictionary = reward_options[active_reward_index]
	var color := _get_reward_kind_color(String(option.get("kind", "reward")))
	reward_focus_label.text = "[center][color=#%s][b]SELECTED: %s %s[/b][/color]\n%s\n%s[/center]" % [
		color.to_html(false),
		String(option.get("rarity", "Common")).to_upper(),
		String(option.get("label", "Reward")).to_upper(),
		_get_reward_focus_text(option),
		String(option.get("summary", ""))
	]


func _get_reward_focus_text(option: Dictionary) -> String:
	var kind := String(option.get("kind", "reward"))
	var amount := int(option.get("amount", 0))
	var chips := int(option.get("chip_bonus", 0))
	match kind:
		"damage":
			return "Weapon damage carries into the next wave. Great when your hand is trying to end fights fast. +%d damage, +%d chips." % [amount, chips]
		"armor":
			return "Adds survivability to the current loadout. Best for hold, defend, and close-range tests. +%d armor, +%d chips." % [amount, chips]
		"ammo":
			return "Adds breathing room for reload tests and longer waves. Best for Extract and sustained AR tuning. +%d ammo, +%d chips." % [amount, chips]
		_:
			return "Banks a flexible wave payout. +%d chips." % chips


func _get_reward_kind_noun(kind: String) -> String:
	match kind:
		"damage":
			return "DMG"
		"armor":
			return "ARMOR"
		"ammo":
			return "AMMO"
		_:
			return "PAYOUT"


func _get_reward_kind_detail(kind: String) -> String:
	match kind:
		"damage":
			return "lethal"
		"armor":
			return "sturdy"
		"ammo":
			return "tempo"
		_:
			return "flex"


func _get_reward_kind_color(kind: String) -> Color:
	match kind:
		"damage":
			return Color(1.0, 0.48, 0.24, 0.82)
		"armor":
			return Color(0.48, 0.78, 1.0, 0.82)
		"ammo":
			return Color(0.42, 0.96, 0.72, 0.82)
		_:
			return Color(1.0, 0.72, 0.28, 0.82)


func _get_reward_kind_from_button(button: Button) -> String:
	if button == null:
		return "reward"
	var index := int(button.name.replace("RewardButton", ""))
	if index >= 0 and index < reward_options.size():
		return String(reward_options[index].get("kind", "reward"))
	return "reward"


func _animate_reward_panel_open() -> void:
	if reward_panel == null:
		return
	reward_panel.modulate.a = 0.0
	reward_panel.scale = Vector2(0.975, 0.975)
	reward_panel.pivot_offset = reward_panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(reward_panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(reward_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if reward_backdrop != null:
		reward_backdrop.modulate.a = 0.0
		tween.tween_property(reward_backdrop, "modulate:a", 1.0, 0.14)


func get_arena_result_preview(reward_index: int = 0) -> Dictionary:
	var options := _build_reward_options()
	var safe_index := clampi(reward_index, 0, maxi(0, options.size() - 1))
	var reward: Dictionary = options[safe_index] if not options.is_empty() else {}
	return _build_arena_result(reward, true)


func _build_arena_result(reward: Dictionary, cleared: bool = true) -> Dictionary:
	var clear_time := float(Time.get_ticks_msec() - wave_started_msec) / 1000.0 if wave_started_msec > 0 else 0.0
	var remaining_health := int(player.get("health")) if player != null else 0
	var remaining_armor := int(player.get("armor")) if player != null else 0
	var objective_score := _calculate_objective_score(cleared, clear_time)
	var scored_kills := _get_wave_kills_for_scoring()
	return {
		"source": "fps_arena",
		"map_name": String(tactical_map.get("name", "Crossfire Table")),
		"objective_mode": objective_mode,
		"objective_label": String(objective_def.get("label", "Objective")),
		"objective_completed": objective_completed,
		"objective_failed": objective_failed,
		"objective_events": objective_events.duplicate(),
		"objective_extract_timer": objective_extract_timer,
		"objective_contested_count": objective_contested_count,
		"hero_class": active_hero_class_id,
		"hero": String(active_hero_profile.get("name", "Gambler-Knight")),
		"class_passive": String(active_hero_profile.get("passive", "Ante Guard")),
		"ability_uses": ability_use_counts.duplicate(true),
		"outcome": "win" if cleared else "defeat",
		"cleared": cleared,
		"wave": wave_index,
		"kills": scored_kills,
		"total_kills": kills,
		"clear_time": clear_time,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"hit_rate": _get_hit_rate(),
		"critical_hits": critical_hits,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"objective_score": objective_score,
		"wounds_taken": _calculate_wounds_taken(cleared, remaining_health),
		"remaining_health": remaining_health,
		"remaining_armor": remaining_armor,
		"loadout": get_active_loadout_summary(),
		"selected_reward": reward.duplicate(true),
		"chips_awarded": _calculate_arena_chips(reward, cleared, objective_score),
		"cards_to_draw": 5 if cleared else 0
	}


func _get_total_ability_uses() -> int:
	var total := 0
	for value in ability_use_counts.values():
		total += int(value)
	return total


func _calculate_arena_chips(reward: Dictionary, cleared: bool = true, objective_score: int = 0) -> int:
	var scored_kills := _get_wave_kills_for_scoring()
	if not cleared:
		return mini(2, max(0, scored_kills))
	var chips := 4 + scored_kills
	if _get_hit_rate() >= 0.50:
		chips += 2
	if damage_taken <= 20:
		chips += 1
	if objective_completed:
		chips += 2
	elif objective_failed:
		chips -= 1
	if objective_score >= 70:
		chips += 1
	if objective_score >= 90:
		chips += 1
	chips += int(reward.get("chip_bonus", 0))
	return maxi(1, chips)


func _calculate_objective_score(cleared: bool, clear_time: float) -> int:
	var scored_kills := _get_wave_kills_for_scoring()
	var objective_part := int(roundf(objective_score_bank))
	match objective_mode:
		"hold_pot":
			objective_part += int(roundf(_get_objective_progress_ratio() * 48.0))
		"extract":
			objective_part += 35 if objective_extract_collected else 0
			objective_part += 35 if objective_completed else 0
			if objective_completed:
				objective_part += int(roundf(maxf(0.0, float(objective_def.get("time_limit", 18.0)) - objective_extract_timer) * 0.8))
		"defend":
			objective_part += int(roundf(_get_objective_progress_ratio() * 54.0))
		"duel", "boss_gate":
			objective_part += 55 if objective_target_defeated else int(roundf(_get_objective_progress_ratio() * 22.0))
	if objective_failed:
		objective_part = maxi(0, objective_part - 24)
	if not cleared:
		return clampi(scored_kills * 10 + int(_get_hit_rate() * 18.0) + objective_part, 0, 65)
	var score := 32 + scored_kills * 4 + int(_get_hit_rate() * 16.0) + objective_part
	if clear_time > 0.0 and clear_time <= 30.0:
		score += 8
	if damage_taken <= 20:
		score += 6
	return clampi(score, 0, 100)


func _get_wave_kills_for_scoring() -> int:
	return current_wave_kills if current_wave_kills > 0 else kills


func _calculate_wounds_taken(cleared: bool, remaining_health: int) -> int:
	var wounds := int(floor(float(max(0, damage_taken)) / 35.0))
	if not cleared:
		wounds += 2
	if remaining_health <= 0:
		wounds += 1
	return wounds


func _return_to_card_table(result: Dictionary) -> void:
	var scene_path := CARD_TABLE_SCENE
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null:
		if bridge.has_method("set_result"):
			bridge.call("set_result", result)
		if bridge.has_method("get_return_scene_path"):
			scene_path = String(bridge.call("get_return_scene_path"))
	if scene_path.is_empty():
		scene_path = CARD_TABLE_SCENE
	var tree := get_tree()
	if tree != null:
		var packed_scene := _get_ready_card_table_scene(scene_path)
		var error := tree.change_scene_to_packed(packed_scene) if packed_scene != null else tree.change_scene_to_file(scene_path)
		if error != OK:
			reward_return_in_progress = false
			rewards_pending = true
			if reward_backdrop != null:
				reward_backdrop.visible = true
			if reward_panel != null:
				reward_panel.visible = true
			_show_status_flash("Return failed: %s" % scene_path, Color(1.0, 0.35, 0.22))
			_focus_reward_button(active_reward_index)


func _request_card_table_preload() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if card_table_preload_requested:
		return
	var error := ResourceLoader.load_threaded_request(CARD_TABLE_SCENE)
	if error == OK:
		card_table_preload_requested = true


func _get_ready_card_table_scene(scene_path: String) -> PackedScene:
	if scene_path != CARD_TABLE_SCENE or not card_table_preload_requested:
		return null
	if ResourceLoader.load_threaded_get_status(CARD_TABLE_SCENE) != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	return ResourceLoader.load_threaded_get(CARD_TABLE_SCENE) as PackedScene


func _on_weapon_fired(_from: Vector3, _to: Vector3) -> void:
	shots_fired += 1
	_pulse_crosshair_fire()


func _on_weapon_hit_confirmed(_position: Vector3, amount: int, critical: bool, _defeated: bool) -> void:
	shots_hit += 1
	damage_dealt += amount
	if critical:
		critical_hits += 1
	if _defeated:
		_show_status_flash("TARGET DOWN", Color(1.0, 0.68, 0.24))


func _get_hit_rate() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)


func _play_hit_marker(critical: bool) -> void:
	if hit_marker == null:
		return
	hit_marker.modulate = Color(1.0, 0.78, 0.24, 1.0) if critical else Color(0.72, 0.96, 1.0, 0.95)
	hit_marker.scale = Vector2(1.24, 1.24) if critical else Vector2(1.12, 1.12)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hit_marker, "modulate:a", 0.0, 0.16)
	tween.tween_property(hit_marker, "scale", Vector2.ONE, 0.14)


func _pulse_crosshair_fire() -> void:
	if crosshair == null:
		return
	crosshair.scale = Vector2(1.10, 1.10)
	var tween := create_tween()
	tween.tween_property(crosshair, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_player_health_changed(current: int, maximum: int) -> void:
	if health_bar != null:
		health_bar.max_value = maximum
		health_bar.value = current


func _on_player_damage_taken(amount: int) -> void:
	damage_taken += amount
	if damage_flash == null:
		return
	damage_flash.color = Color(0.95, 0.08, 0.04, 0.26)
	var tween := create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.28)


func _on_weapon_state_changed(_ammo: int, _reserve: int, _reloading: bool) -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	if player == null or player.weapon == null:
		return
	var ammo_state: Dictionary = player.weapon.call("get_ammo_state") as Dictionary
	var summary := get_active_loadout_summary()
	if ammo_label != null:
		ammo_label.text = str(ammo_state.get("ammo", 0))
	if reserve_label != null:
		var is_reloading := bool(ammo_state.get("reloading", false))
		var suffix := "..." if is_reloading else ("INF" if bool(ammo_state.get("infinite_ammo", false)) else str(ammo_state.get("reserve", 0)))
		reserve_label.text = suffix
		if reload_bar != null:
			reload_bar.visible = is_reloading
			reload_bar.value = float(ammo_state.get("reload_progress", 0.0))
		if reload_status_label != null:
			reload_status_label.visible = is_reloading
			reload_status_label.text = "RELOADING %d%%" % int(roundf(float(ammo_state.get("reload_progress", 0.0)) * 100.0))
	if kill_label != null:
		kill_label.text = "%d/%d" % [current_wave_kills, maxi(1, current_wave_enemy_total)]
	if status_label != null and wave_active:
		status_label.text = "WAVE %d" % wave_index
	if objective_label != null:
		objective_label.text = _get_objective_hud_text()
		objective_label.add_theme_color_override("font_color", _get_objective_color())
	if objective_progress_bar != null:
		objective_progress_bar.value = _get_objective_progress_ratio()
	if loadout_label != null:
		loadout_label.add_theme_color_override("font_color", _get_class_accent_color())
		loadout_label.text = "%s %s | %s | Armor %d | Chips %d | Upg %d W%d" % [
			summary.get("hero", "Gambler-Knight"),
			summary.get("hero_role", "Duelist"),
			summary.get("weapon", "House Sidearm"),
			summary.get("armor", 0),
			summary.get("chips", 0),
			summary.get("card_upgrades", 0),
			summary.get("wounds_total", 0)
		]
	if ability_label != null:
		ability_label.text = _get_ability_hud_text()
	_refresh_card_combat_hud(ammo_state, summary)
	if telemetry_label != null:
		var run_time := float(Time.get_ticks_msec() - run_started_msec) / 1000.0 if run_started_msec > 0 else 0.0
		telemetry_label.text = "Time %.1fs | Waves %d | Hits %.0f%% | Crits %d | Damage %d | Taken %d | Objective %d" % [
			run_time,
			waves_cleared,
			_get_hit_rate() * 100.0,
			critical_hits,
			damage_dealt,
			damage_taken,
			_calculate_objective_score(wave_active, _get_current_clear_time())
		]


func _refresh_card_combat_hud(ammo_state: Dictionary, summary: Dictionary = {}) -> void:
	if card_hud_panel == null:
		return
	if summary.is_empty():
		summary = get_active_loadout_summary()
	if card_hud_weapon_label != null:
		card_hud_weapon_label.text = "%s | %s" % [String(summary.get("hero_passive", "Ante Guard")).to_upper(), String(summary.get("weapon", "House Sidearm")).to_upper()]
	if card_hud_economy_label != null:
		var reserve_text := "INF" if bool(ammo_state.get("infinite_ammo", false)) else str(int(ammo_state.get("reserve", 0)))
		card_hud_economy_label.text = "$%d  ARM %d  AMMO %d/%s" % [
			int(summary.get("chips", 0)),
			int(summary.get("armor", 0)),
			int(ammo_state.get("ammo", 0)),
			reserve_text
		]
	if card_hud_ability_row != null:
		var signature := _get_card_hud_layout_signature()
		if signature != card_hud_layout_signature:
			card_hud_layout_signature = signature
			_rebuild_card_hud_ability_row()
		_update_card_hud_ability_row()
	if card_hud_summary_label != null:
		var target_text := String(summary.get("target_enemy", ""))
		var wound_text := " | wounds %d" % int(summary.get("wounds_total", 0)) if int(summary.get("wounds_total", 0)) > 0 else ""
		card_hud_summary_label.text = "CARD POWERS LIVE  |  %s%s" % [
			"read target %s" % target_text if not target_text.is_empty() else "slot cards before arena entry",
			wound_text
		]


func _rebuild_card_hud_ability_row() -> void:
	if card_hud_ability_row == null:
		return
	_clear_children(card_hud_ability_row)
	var max_slots := maxi(4, active_abilities.size())
	for index in range(max_slots):
		card_hud_ability_row.add_child(_build_ability_card_panel(index))


func _update_card_hud_ability_row() -> void:
	if card_hud_ability_row == null:
		return
	var max_slots := maxi(4, active_abilities.size())
	for index in range(max_slots):
		var panel := card_hud_ability_row.get_node_or_null("AbilityCardSlot%d" % (index + 1))
		if panel == null:
			continue
		var label := panel.find_child("AbilityText%d" % (index + 1), true, false)
		if label is Label:
			if index < active_abilities.size():
				(label as Label).text = _get_card_hud_ability_text(index)
				(label as Label).add_theme_color_override("font_color", Color(0.88, 0.98, 1.0) if _is_ability_ready(index) else Color(0.58, 0.66, 0.70))
			else:
				(label as Label).text = "%s EMPTY" % _get_primary_action_binding_text(StringName("fps_ability_%d" % (index + 1)))
		var cooldown := panel.find_child("AbilityCooldownBar%d" % (index + 1), true, false)
		if cooldown is ProgressBar:
			(cooldown as ProgressBar).value = _get_ability_cooldown_ratio(index)


func _get_card_hud_layout_signature() -> String:
	var parts: Array[String] = []
	for index in range(active_abilities.size()):
		var entry: Dictionary = active_abilities[index]
		var ability: Dictionary = entry.get("ability", {})
		parts.append("%s:%s:%s" % [
			String(entry.get("id", "")),
			String(entry.get("card_name", "")),
			String(ability.get("kind", ""))
		])
	return "|".join(parts)


func _build_ability_card_panel(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AbilityCardSlot%d" % (index + 1)
	panel.custom_minimum_size = Vector2(94, 34)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var active := index < active_abilities.size()
	var class_color := _get_class_accent_color()
	panel.add_theme_stylebox_override("panel", _make_hud_panel_style(
		Color(0.050, 0.060, 0.064, 0.70) if active else Color(0.025, 0.026, 0.026, 0.64),
		Color(class_color.r, class_color.g, class_color.b, 0.66) if active else Color(0.26, 0.28, 0.30, 0.46),
		5,
		1
	))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	margin.add_child(stack)

	var label := Label.new()
	label.name = "AbilityText%d" % (index + 1)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 9)
	if index < active_abilities.size():
		var entry: Dictionary = active_abilities[index]
		var ability: Dictionary = entry.get("ability", {})
		var kind := String(ability.get("kind", ""))
		var icon_frame := PanelContainer.new()
		icon_frame.name = "AbilityIconFrame%d" % (index + 1)
		icon_frame.custom_minimum_size = Vector2(0, 15)
		icon_frame.add_theme_stylebox_override("panel", _make_hud_panel_style(
			_get_ability_color(kind),
			Color(class_color.r, class_color.g, class_color.b, 0.86),
			4,
			1
		))
		stack.add_child(icon_frame)
		var icon := Label.new()
		icon.name = "AbilityIcon%d" % (index + 1)
		icon.text = "%s %s" % [_get_ability_glyph(kind), _get_ability_icon_label(kind)]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 9)
		icon.add_theme_color_override("font_color", Color(0.025, 0.020, 0.016))
		icon_frame.add_child(icon)
		label.text = _get_card_hud_ability_text(index)
		label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0) if _is_ability_ready(index) else Color(0.58, 0.66, 0.70))
		panel.tooltip_text = "Live card power from %s" % String(entry.get("card_name", "slotted card"))
	else:
		label.text = "%s EMPTY" % _get_primary_action_binding_text(StringName("fps_ability_%d" % (index + 1)))
		label.add_theme_color_override("font_color", Color(0.45, 0.49, 0.52))
		panel.tooltip_text = "Slot a card before Enter Arena to fill this combat power."
	stack.add_child(label)

	var cooldown := ProgressBar.new()
	cooldown.name = "AbilityCooldownBar%d" % (index + 1)
	cooldown.custom_minimum_size = Vector2(0, 6)
	cooldown.max_value = 1.0
	cooldown.value = _get_ability_cooldown_ratio(index)
	cooldown.show_percentage = false
	var cooldown_color := Color(0.36, 0.40, 0.42, 0.72)
	if active:
		var cooldown_entry: Dictionary = active_abilities[index]
		var cooldown_ability: Dictionary = cooldown_entry.get("ability", {})
		cooldown_color = _get_ability_color(String(cooldown_ability.get("kind", "")))
	cooldown.add_theme_stylebox_override("background", _make_hud_panel_style(Color(0.012, 0.014, 0.016, 0.74), Color(0.0, 0.0, 0.0, 0.0), 3, 0))
	cooldown.add_theme_stylebox_override("fill", _make_hud_panel_style(cooldown_color, Color(cooldown_color.r, cooldown_color.g, cooldown_color.b, 0.22), 3, 0))
	stack.add_child(cooldown)
	return panel


func _get_ability_icon_label(kind: String) -> String:
	match kind:
		"dash":
			return "DASH"
		"guard_shimmer":
			return "SHLD"
		"reveal_target":
			return "READ"
		"snare_field":
			return "TRAP"
		"blood_overclock":
			return "OVR"
		"bait_ping":
			return "BAIT"
		_:
			return "CARD"


func _get_ability_glyph(kind: String) -> String:
	match kind:
		"dash":
			return ">>"
		"guard_shimmer":
			return "[]"
		"reveal_target":
			return "?"
		"snare_field":
			return "X"
		"blood_overclock":
			return "!!"
		"bait_ping":
			return "B"
		_:
			return "*"


func _get_ability_color(kind: String) -> Color:
	match kind:
		"dash":
			return _blend_ability_class_color(kind, Color(0.32, 0.92, 1.0, 0.88))
		"guard_shimmer":
			return _blend_ability_class_color(kind, Color(0.58, 0.76, 1.0, 0.88))
		"reveal_target":
			return _blend_ability_class_color(kind, Color(0.28, 1.0, 0.82, 0.88))
		"snare_field":
			return _blend_ability_class_color(kind, Color(0.92, 0.52, 1.0, 0.88))
		"blood_overclock":
			return _blend_ability_class_color(kind, Color(1.0, 0.42, 0.24, 0.88))
		"bait_ping":
			return _blend_ability_class_color(kind, Color(1.0, 0.82, 0.30, 0.88))
		_:
			return _blend_ability_class_color(kind, Color(0.72, 0.78, 0.84, 0.88))


func _get_class_accent_color() -> Color:
	var accent_value: Variant = active_hero_profile.get("accent", Color(1.0, 0.76, 0.30))
	if typeof(accent_value) == TYPE_COLOR:
		return accent_value
	return Color(1.0, 0.76, 0.30)


func _blend_ability_class_color(kind: String, base_color: Color) -> Color:
	var accent := _get_class_accent_color()
	var amount := 0.26
	match active_hero_class_id:
		"hex_sharpshooter":
			amount = 0.34 if kind == "reveal_target" or kind == "snare_field" else 0.22
		"blood_wager":
			amount = 0.36 if kind == "blood_overclock" or kind == "guard_shimmer" else 0.24
		_:
			amount = 0.30 if kind == "dash" or kind == "guard_shimmer" else 0.20
	var color := base_color.lerp(accent, amount)
	color.a = base_color.a
	return color


func _get_ability_cooldown_ratio(index: int) -> float:
	if index < 0 or index >= active_abilities.size():
		return 0.0
	var entry: Dictionary = active_abilities[index]
	var ability: Dictionary = entry.get("ability", {})
	var max_cooldown := maxf(0.01, float(ability.get("cooldown", 6.0)) * _get_hero_cooldown_scalar())
	var remaining := ability_cooldowns[index] if index < ability_cooldowns.size() else 0.0
	return clampf(1.0 - float(remaining) / max_cooldown, 0.0, 1.0)


func _pulse_card_hud_slot(index: int, color: Color) -> void:
	if card_hud_ability_row == null:
		return
	var slot := card_hud_ability_row.get_node_or_null("AbilityCardSlot%d" % (index + 1))
	if slot == null:
		return
	slot.modulate = color
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
	tween.chain().tween_property(slot, "scale", Vector2.ONE, 0.16)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.22)


func _get_card_hud_ability_text(index: int) -> String:
	var entry: Dictionary = active_abilities[index]
	var ability: Dictionary = entry.get("ability", {})
	var key := _get_primary_action_binding_text(StringName("fps_ability_%d" % (index + 1)))
	var display := _get_ability_display_name(String(entry.get("id", "")), String(ability.get("kind", "")))
	var source := String(entry.get("card_name", entry.get("id", "Card")))
	var cooldown := ability_cooldowns[index] if index < ability_cooldowns.size() else 0.0
	var state := "READY" if cooldown <= 0.0 else "%.0fs" % cooldown
	return "%s %s\n%s" % [key, state, display if source == display else "%s / %s" % [display, source]]


func _consume_pending_arena_bridge_payload() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("has_pending_payload") and bool(bridge.call("has_pending_payload")):
		apply_arena_bridge_payload(bridge.call("take_payload"))
	else:
		apply_arena_bridge_payload(DEFAULT_BRIDGE_PAYLOAD)


func _ensure_input_actions() -> void:
	_ensure_key_action("fps_toggle_mouse", KEY_ESCAPE)
	for binding in _get_rebindable_actions():
		var action := StringName(binding.get("action", &""))
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for event in _get_default_input_events(binding):
				InputMap.action_add_event(action, event)


func _ensure_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _ensure_mouse_action(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


func _add_box(node_name: String, pos: Vector3, size: Vector3, material: Material, rot: Vector3 = Vector3.ZERO, collidable := true) -> Node3D:
	var root: Node3D
	if collidable:
		var body := StaticBody3D.new()
		body.name = node_name
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		root = body
	else:
		root = Node3D.new()
		root.name = node_name
	root.position = pos
	root.rotation = rot

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	arena_root.add_child(root)
	return root


func _map_cell_to_world(cell: Vector2i) -> Vector3:
	var x := (float(cell.x) - 1.0) * 7.4
	var z_values := [-10.8, -2.2, 6.4]
	var z := float(z_values[clampi(cell.y, 0, 2)])
	return Vector3(x, 0.03, z)


func _get_feature_color(feature: Dictionary, key: String, fallback: Color) -> Color:
	var color_value: Variant = feature.get(key, fallback)
	if typeof(color_value) == TYPE_COLOR:
		return color_value
	return fallback


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _make_marker_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.42)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.58
	return mat


func _make_hud_panel_style(bg_color: Color, border_color: Color, radius: int = 6, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


func _make_tracer_material(color: Color) -> StandardMaterial3D:
	var mat := _make_emissive_material(color, 1.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.72
	return mat
