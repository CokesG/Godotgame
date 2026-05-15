class_name FPSPrototype
extends Node3D

const FPS_PLAYER_SCRIPT := preload("res://scripts/fps/FPSPlayer.gd")
const FPS_DRONE_SCRIPT := preload("res://scripts/fps/FPSDrone.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")
const CARD_TABLE_SCENE := "res://scenes/combat/TestCombat.tscn"

const DEFAULT_BRIDGE_PAYLOAD := {
	"weapon_card": "",
	"ability_cards": [],
	"passive_cards": [],
	"wager_cards": [],
	"loadout": [],
	"economy": {"chips": 0, "armor": 0, "ammo": 24},
	"reads": {"target_enemy": &"", "threat": "intent hidden"}
}

const SETTINGS_PATH := "user://fps_settings.cfg"
const DEFAULT_AIM_SETTINGS := {
	"mouse_sensitivity": 0.00155,
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
var kill_label: Label
var status_label: Label
var loadout_label: Label
var ability_label: Label
var telemetry_label: Label
var reward_panel: PanelContainer
var reward_label: RichTextLabel
var settings_panel: PanelContainer
var crosshair: Control
var hit_marker: Control
var damage_flash: ColorRect
var restart_timer := 0.0
var kills := 0
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
var active_abilities: Array[Dictionary] = []
var active_weapon_profile: Dictionary = {}
var ability_cooldowns: Array[float] = []
var aim_settings: Dictionary = DEFAULT_AIM_SETTINGS.duplicate(true)
var crosshair_settings: Dictionary = DEFAULT_CROSSHAIR_SETTINGS.duplicate(true)
var crosshair_signature := ""

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
	_build_ui()
	run_started_msec = Time.get_ticks_msec()
	_spawn_wave()
	_refresh_ui()


func _process(delta: float) -> void:
	_tick_ability_cooldowns(delta)
	if restart_timer > 0.0:
		restart_timer -= delta
		if restart_timer <= 0.0:
			_spawn_wave()
	_update_crosshair()
	_refresh_ui()


func _input(event: InputEvent) -> void:
	if not rebinding_action.is_empty():
		if _capture_rebind_event(event):
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
		"regions": get_map_regions()
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
	if player != null:
		if player.weapon != null and player.weapon.has_method("configure_from_bridge"):
			player.weapon.call("configure_from_bridge", active_weapon_profile, total_ammo)
		if player.has_method("apply_bridge_survivability"):
			player.call("apply_bridge_survivability", int(economy.get("armor", 0)))
	_refresh_ui()


func get_active_loadout_summary() -> Dictionary:
	var economy: Dictionary = active_bridge_payload.get("economy", {})
	return {
		"weapon": String(active_weapon_profile.get("name", "House Sidearm")),
		"abilities": active_abilities.size(),
		"ability_names": _get_ability_names(),
		"chips": int(economy.get("chips", 0)),
		"armor": int(economy.get("armor", 0)),
		"ammo": int(economy.get("ammo", 24)),
		"target_enemy": active_bridge_payload.get("reads", {}).get("target_enemy", &"")
	}


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
		ability_cooldowns[index] = float(ability.get("cooldown", 6.0))
		_show_status_flash("%s readying" % _get_ability_display_name(String(entry.get("id", "")), kind), Color(0.52, 1.0, 0.82))
		_refresh_ui()
	return used


func _is_ability_ready(index: int) -> bool:
	return index >= 0 and index < active_abilities.size() and (index >= ability_cooldowns.size() or float(ability_cooldowns[index]) <= 0.0)


func _use_dash_ability(ability: Dictionary) -> bool:
	if player == null or not player.has_method("dash_forward"):
		return false
	player.call("dash_forward", float(ability.get("strength", 12.5)))
	_spawn_ability_ring(player.global_position, Color(0.34, 0.95, 1.0), 1.6)
	return true


func _use_guard_shimmer_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	if player.has_method("add_armor"):
		player.call("add_armor", int(ability.get("armor", 5)))
	_spawn_ability_ring(player.global_position, Color(0.55, 0.78, 1.0), 2.1)
	return true


func _use_read_reveal_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 3.5))
	for enemy in get_living_enemies():
		if enemy.has_method("reveal_for"):
			enemy.call("reveal_for", duration)
	_spawn_ability_ring(player.global_position + Vector3(0.0, 0.12, -2.0), Color(0.22, 0.95, 1.0), 3.0)
	return true


func _use_snare_field_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 4.0))
	var radius := float(ability.get("radius", 4.2))
	var center: Vector3 = player.global_position + (-player.global_basis.z).normalized() * 5.4
	center.y = 0.05
	_spawn_ability_ring(center, Color(0.92, 0.48, 1.0), radius)
	for enemy in get_living_enemies():
		if enemy.global_position.distance_to(center) <= radius and enemy.has_method("apply_snare"):
			enemy.call("apply_snare", duration)
	return true


func _use_overclock_ability(ability: Dictionary) -> bool:
	if player == null or player.weapon == null or not player.weapon.has_method("apply_temporary_overclock"):
		return false
	player.weapon.call("apply_temporary_overclock", float(ability.get("duration", 4.0)), 0.78, 1.20)
	_spawn_ability_ring(player.global_position, Color(1.0, 0.58, 0.24), 2.0)
	return true


func _use_bait_ping_ability(ability: Dictionary) -> bool:
	if player == null:
		return false
	var duration := float(ability.get("duration", 2.5))
	for enemy in get_living_enemies():
		if enemy.has_method("apply_bait"):
			enemy.call("apply_bait", duration)
	_spawn_ability_ring(player.global_position, Color(1.0, 0.86, 0.35), 3.4)
	return true


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
	var ring := MeshInstance3D.new()
	ring.name = "AbilityRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.05
	ring.mesh = mesh
	ring.position = position
	ring.material_override = _make_marker_material(color, 0.95)
	effects_root.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.35, 1.35, 1.35), 0.28).from(Vector3(0.3, 0.3, 0.3))
	tween.tween_property(ring, "transparency", 1.0, 0.42)
	tween.chain().tween_callback(ring.queue_free)


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


func spawn_combat_text(position: Vector3, text: String, critical: bool, defeated: bool) -> void:
	if effects_root == null:
		return
	var label := Label3D.new()
	label.name = "CombatText"
	label.text = text
	label.font_size = 44 if critical else 34
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
	if get_living_enemies().is_empty():
		wave_active = false
		rewards_pending = true
		waves_cleared += 1
		status_label.text = "WAVE CLEARED" if status_label != null else ""
		_show_wave_rewards()


func restart_encounter() -> void:
	for child in enemies_root.get_children():
		child.queue_free()
	kills = 0
	wave_index = 1
	waves_cleared = 0
	shots_fired = 0
	shots_hit = 0
	critical_hits = 0
	damage_dealt = 0
	damage_taken = 0
	rewards_pending = false
	restart_timer = 0.0
	run_started_msec = Time.get_ticks_msec()
	if reward_panel != null:
		reward_panel.visible = false
	if player != null:
		player.reset_for_arena(spawn_position)
	_spawn_wave()


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
	var floor_mat := _make_material(Color(0.15, 0.19, 0.18), 0.08, 0.86)
	var wall_mat := _make_material(Color(0.12, 0.15, 0.22), 0.0, 0.72)
	var cover_mat := _make_material(Color(0.40, 0.29, 0.18), 0.12, 0.66)
	var teal_mat := _make_emissive_material(Color(0.10, 0.76, 0.86), 0.62)
	var brass_mat := _make_material(Color(0.86, 0.57, 0.26), 0.3, 0.48)
	var lane_mat := _make_emissive_material(Color(0.08, 0.52, 0.56), 0.20)

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
	player.request_restart.connect(restart_encounter)
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

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.035
	top_bar.anchor_top = 0.035
	top_bar.anchor_right = 0.965
	top_bar.anchor_bottom = 0.13
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 14)
	hud_root.add_child(top_bar)

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.max_value = 120.0
	health_bar.value = 120.0
	health_bar.custom_minimum_size = Vector2(250, 22)
	health_bar.show_percentage = false
	top_bar.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "12"
	ammo_label.add_theme_font_size_override("font_size", 30)
	top_bar.add_child(ammo_label)

	reserve_label = Label.new()
	reserve_label.name = "ReserveLabel"
	reserve_label.text = "72"
	reserve_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(reserve_label)

	kill_label = Label.new()
	kill_label.name = "KillLabel"
	kill_label.text = "0"
	kill_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(kill_label)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(status_label)

	loadout_label = Label.new()
	loadout_label.name = "LoadoutLabel"
	loadout_label.anchor_left = 0.035
	loadout_label.anchor_top = 0.135
	loadout_label.anchor_right = 0.965
	loadout_label.anchor_bottom = 0.19
	loadout_label.add_theme_font_size_override("font_size", 15)
	loadout_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))
	loadout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_root.add_child(loadout_label)

	ability_label = Label.new()
	ability_label.name = "AbilityLabel"
	ability_label.anchor_left = 0.035
	ability_label.anchor_top = 0.19
	ability_label.anchor_right = 0.965
	ability_label.anchor_bottom = 0.25
	ability_label.add_theme_font_size_override("font_size", 14)
	ability_label.add_theme_color_override("font_color", Color(0.74, 0.96, 1.0))
	hud_root.add_child(ability_label)

	telemetry_label = Label.new()
	telemetry_label.name = "TelemetryLabel"
	telemetry_label.anchor_left = 0.035
	telemetry_label.anchor_top = 0.90
	telemetry_label.anchor_right = 0.965
	telemetry_label.anchor_bottom = 0.96
	telemetry_label.add_theme_font_size_override("font_size", 13)
	telemetry_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.86, 0.88))
	hud_root.add_child(telemetry_label)

	_build_crosshair(hud_root)
	_build_hit_marker(hud_root)
	_build_reward_panel(hud_root)
	_build_settings_panel(hud_root)


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
	if settings_panel != null:
		settings_panel.visible = settings_open
	if player != null and player.has_method("set_gameplay_input_enabled"):
		player.call("set_gameplay_input_enabled", not settings_open and not rewards_pending)


func _build_settings_panel(root: Control) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "FPSSettingsPanel"
	settings_panel.anchor_left = 0.18
	settings_panel.anchor_top = 0.08
	settings_panel.anchor_right = 0.82
	settings_panel.anchor_bottom = 0.92
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
	var close_button := Button.new()
	close_button.text = "Close"
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

	keybind_buttons.clear()
	_add_keybind_group(controls_tab, "Movement", "movement")
	_add_keybind_group(controls_tab, "Combat", "combat")
	_add_keybind_group(controls_tab, "Card Abilities", "ability")
	_add_keybind_group(controls_tab, "System", "system")
	_refresh_keybind_rows()

	_rebuild_preview_crosshair(preview_crosshair)


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
	reward_panel = PanelContainer.new()
	reward_panel.name = "RewardPanel"
	reward_panel.anchor_left = 0.30
	reward_panel.anchor_top = 0.26
	reward_panel.anchor_right = 0.70
	reward_panel.anchor_bottom = 0.58
	reward_panel.visible = false
	reward_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(reward_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	reward_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	reward_label = RichTextLabel.new()
	reward_label.bbcode_enabled = true
	reward_label.fit_content = true
	reward_label.custom_minimum_size = Vector2(360, 120)
	layout.add_child(reward_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	layout.add_child(row)
	for i in range(3):
		var button := Button.new()
		button.name = "RewardButton%d" % i
		button.text = "Reward %d" % (i + 1)
		var index := i
		button.pressed.connect(func() -> void:
			_select_reward(index)
		)
		row.add_child(button)


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


func _update_crosshair() -> void:
	if crosshair == null:
		return
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


func _apply_player_settings() -> void:
	if player != null and player.has_method("apply_aim_settings"):
		player.call("apply_aim_settings", aim_settings)


func _load_player_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	aim_settings["mouse_sensitivity"] = float(config.get_value("aim", "mouse_sensitivity", aim_settings.get("mouse_sensitivity", 0.00155)))
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
	restart_timer = 0.0
	wave_started_msec = Time.get_ticks_msec()
	status_label.text = "" if status_label != null else ""
	var extra_health := (wave_index - 1) * 12
	for data in enemy_defs:
		var enemy := FPS_DRONE_SCRIPT.new()
		enemy.name = String(data.get("name", "Enemy")).replace(" ", "")
		var copy := data.duplicate(true)
		copy["health"] = int(copy.get("health", 70)) + extra_health
		enemy.configure(copy, player, self)
		enemies_root.add_child(enemy)
		enemy.global_position = data.get("position", Vector3.ZERO)


func _show_wave_rewards() -> void:
	reward_options = _build_reward_options()
	if reward_panel == null:
		return
	reward_panel.visible = true
	if reward_label != null:
		var clear_time := float(Time.get_ticks_msec() - wave_started_msec) / 1000.0
		reward_label.text = "[center][b]Wave %d Cleared[/b]\n%.1fs  %d shots  %.0f%% hit rate\nChoose a payout to return to the table.[/center]" % [
			wave_index,
			clear_time,
			shots_fired,
			_get_hit_rate() * 100.0
		]
	var buttons := reward_panel.find_children("RewardButton*", "Button", true, false)
	for i in range(buttons.size()):
		var button: Button = buttons[i] as Button
		if i < reward_options.size():
			var option: Dictionary = reward_options[i]
			button.text = String(option.get("label", "Reward"))
			button.disabled = false
		else:
			button.disabled = true
	if player != null and player.has_method("set_gameplay_input_enabled"):
		player.call("set_gameplay_input_enabled", false)


func _build_reward_options() -> Array[Dictionary]:
	return [
		{"label": "Damage Payout", "kind": "damage", "amount": 3, "chip_bonus": 2},
		{"label": "Armor Payout", "kind": "armor", "amount": 10, "chip_bonus": 1},
		{"label": "Ammo Payout", "kind": "ammo", "amount": 18, "chip_bonus": 1}
	]


func _select_reward(index: int) -> void:
	if index < 0 or index >= reward_options.size():
		return
	var reward: Dictionary = reward_options[index]
	active_reward_index = index
	var result := _build_arena_result(reward)
	rewards_pending = false
	if reward_panel != null:
		reward_panel.visible = false
	_return_to_card_table(result)


func get_arena_result_preview(reward_index: int = 0) -> Dictionary:
	var options := _build_reward_options()
	var safe_index := clampi(reward_index, 0, maxi(0, options.size() - 1))
	var reward: Dictionary = options[safe_index] if not options.is_empty() else {}
	return _build_arena_result(reward)


func _build_arena_result(reward: Dictionary) -> Dictionary:
	var clear_time := float(Time.get_ticks_msec() - wave_started_msec) / 1000.0 if wave_started_msec > 0 else 0.0
	var remaining_health := int(player.get("health")) if player != null else 0
	var remaining_armor := int(player.get("armor")) if player != null else 0
	return {
		"source": "fps_arena",
		"map_name": String(tactical_map.get("name", "Crossfire Table")),
		"cleared": true,
		"wave": wave_index,
		"kills": kills,
		"clear_time": clear_time,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"hit_rate": _get_hit_rate(),
		"critical_hits": critical_hits,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"remaining_health": remaining_health,
		"remaining_armor": remaining_armor,
		"loadout": get_active_loadout_summary(),
		"selected_reward": reward.duplicate(true),
		"chips_awarded": _calculate_arena_chips(reward),
		"cards_to_draw": 5
	}


func _calculate_arena_chips(reward: Dictionary) -> int:
	var chips := 4 + kills
	if _get_hit_rate() >= 0.50:
		chips += 2
	if damage_taken <= 20:
		chips += 1
	chips += int(reward.get("chip_bonus", 0))
	return maxi(1, chips)


func _return_to_card_table(result: Dictionary) -> void:
	var scene_path := CARD_TABLE_SCENE
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null:
		if bridge.has_method("set_result"):
			bridge.call("set_result", result)
		if bridge.has_method("get_return_scene_path"):
			scene_path = String(bridge.call("get_return_scene_path"))
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(scene_path)


func _on_weapon_fired(_from: Vector3, _to: Vector3) -> void:
	shots_fired += 1


func _on_weapon_hit_confirmed(_position: Vector3, amount: int, critical: bool, _defeated: bool) -> void:
	shots_hit += 1
	damage_dealt += amount
	if critical:
		critical_hits += 1


func _get_hit_rate() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)


func _play_hit_marker(critical: bool) -> void:
	if hit_marker == null:
		return
	hit_marker.modulate = Color(1.0, 0.78, 0.24, 1.0) if critical else Color(0.72, 0.96, 1.0, 0.95)
	var tween := create_tween()
	tween.tween_property(hit_marker, "modulate:a", 0.0, 0.16)


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
	if ammo_label != null:
		ammo_label.text = str(ammo_state.get("ammo", 0))
	if reserve_label != null:
		var suffix := "..." if bool(ammo_state.get("reloading", false)) else str(ammo_state.get("reserve", 0))
		reserve_label.text = suffix
	if kill_label != null:
		kill_label.text = "%d/%d" % [kills, enemy_defs.size()]
	if status_label != null and wave_active:
		status_label.text = "WAVE %d" % wave_index
	if loadout_label != null:
		var summary := get_active_loadout_summary()
		loadout_label.text = "%s | Ammo %d | Armor %d | Abilities %d | Chips %d" % [
			summary.get("weapon", "House Sidearm"),
			summary.get("ammo", 0),
			summary.get("armor", 0),
			summary.get("abilities", 0),
			summary.get("chips", 0)
		]
	if ability_label != null:
		ability_label.text = _get_ability_hud_text()
	if telemetry_label != null:
		var run_time := float(Time.get_ticks_msec() - run_started_msec) / 1000.0 if run_started_msec > 0 else 0.0
		telemetry_label.text = "Time %.1fs | Waves %d | Hits %.0f%% | Crits %d | Damage %d | Taken %d" % [
			run_time,
			waves_cleared,
			_get_hit_rate() * 100.0,
			critical_hits,
			damage_dealt,
			damage_taken
		]


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
