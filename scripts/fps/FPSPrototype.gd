class_name FPSPrototype
extends Node3D

const FPS_PLAYER_SCRIPT := preload("res://scripts/fps/FPSPlayer.gd")
const FPS_DRONE_SCRIPT := preload("res://scripts/fps/FPSDrone.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")

const DEFAULT_BRIDGE_PAYLOAD := {
	"weapon_card": "",
	"ability_cards": [],
	"passive_cards": [],
	"wager_cards": [],
	"loadout": [],
	"economy": {"chips": 0, "armor": 0, "ammo": 24},
	"reads": {"target_enemy": &"", "threat": "intent hidden"}
}

var player: Node
var arena_root: Node3D
var tactical_map_root: Node3D
var enemies_root: Node3D
var effects_root: Node3D
var ui_layer: CanvasLayer
var health_bar: ProgressBar
var ammo_label: Label
var reserve_label: Label
var kill_label: Label
var status_label: Label
var loadout_label: Label
var hit_marker: Control
var damage_flash: ColorRect
var restart_timer := 0.0
var kills := 0
var wave_index := 1
var wave_active := false
var spawn_position := Vector3(0.0, 1.4, 10.5)
var tactical_map: Dictionary = {}
var active_bridge_payload: Dictionary = DEFAULT_BRIDGE_PAYLOAD.duplicate(true)
var active_abilities: Array[Dictionary] = []
var active_weapon_profile: Dictionary = {}

var enemy_defs: Array[Dictionary] = [
	{
		"name": "Skulker",
		"position": Vector3(-7.5, 0.2, -8.5),
		"texture": "res://art/game/enemies/enemy_skulker.png",
		"color": Color(0.82, 0.18, 0.16),
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
		"health": 82,
		"speed": 3.55,
		"attack_damage": 13,
		"attack_range": 1.72
	},
	{
		"name": "Hexmonger",
		"position": Vector3(10.0, 0.2, -2.0),
		"texture": "res://art/game/enemies/enemy_hexmonger.png",
		"color": Color(0.58, 0.32, 0.90),
		"health": 92,
		"speed": 3.20,
		"attack_damage": 14,
		"attack_range": 1.80
	}
]


func _ready() -> void:
	add_to_group("fps_game")
	tactical_map = TACTICAL_MAP_SCRIPT.get_default_map()
	_ensure_input_actions()
	_build_world()
	_build_arena()
	_build_player()
	_consume_pending_arena_bridge_payload()
	_build_ui()
	_spawn_wave()
	_refresh_ui()


func _process(delta: float) -> void:
	if restart_timer > 0.0:
		restart_timer -= delta
		if restart_timer <= 0.0:
			_spawn_wave()
	_refresh_ui()


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
		"chips": int(economy.get("chips", 0)),
		"armor": int(economy.get("armor", 0)),
		"ammo": int(economy.get("ammo", 24)),
		"target_enemy": active_bridge_payload.get("reads", {}).get("target_enemy", &"")
	}


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
		restart_timer = 1.15
		wave_index += 1
		status_label.text = "WAVE CLEARED" if status_label != null else ""


func restart_encounter() -> void:
	for child in enemies_root.get_children():
		child.queue_free()
	kills = 0
	wave_index = 1
	restart_timer = 0.0
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


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "FPSHud"
	add_child(ui_layer)

	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)

	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.95, 0.08, 0.04, 0.0)
	root.add_child(damage_flash)

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.035
	top_bar.anchor_top = 0.035
	top_bar.anchor_right = 0.965
	top_bar.anchor_bottom = 0.13
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 14)
	root.add_child(top_bar)

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
	root.add_child(loadout_label)

	_build_crosshair(root)
	_build_hit_marker(root)


func _build_crosshair(root: Control) -> void:
	var cross := Control.new()
	cross.name = "Crosshair"
	cross.anchor_left = 0.5
	cross.anchor_top = 0.5
	cross.anchor_right = 0.5
	cross.anchor_bottom = 0.5
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cross)
	_add_crosshair_rect(cross, Vector2(-1.0, -15.0), Vector2(2.0, 8.0))
	_add_crosshair_rect(cross, Vector2(-1.0, 7.0), Vector2(2.0, 8.0))
	_add_crosshair_rect(cross, Vector2(-15.0, -1.0), Vector2(8.0, 2.0))
	_add_crosshair_rect(cross, Vector2(7.0, -1.0), Vector2(8.0, 2.0))


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


func _spawn_wave() -> void:
	if enemies_root == null:
		return
	for child in enemies_root.get_children():
		child.queue_free()
	wave_active = true
	restart_timer = 0.0
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


func _on_player_damage_taken(_amount: int) -> void:
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


func _consume_pending_arena_bridge_payload() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("has_pending_payload") and bool(bridge.call("has_pending_payload")):
		apply_arena_bridge_payload(bridge.call("take_payload"))
	else:
		apply_arena_bridge_payload(DEFAULT_BRIDGE_PAYLOAD)


func _ensure_input_actions() -> void:
	_ensure_key_action("fps_move_forward", KEY_W)
	_ensure_key_action("fps_move_back", KEY_S)
	_ensure_key_action("fps_move_left", KEY_A)
	_ensure_key_action("fps_move_right", KEY_D)
	_ensure_key_action("fps_jump", KEY_SPACE)
	_ensure_key_action("fps_sprint", KEY_SHIFT)
	_ensure_key_action("fps_crouch", KEY_CTRL)
	_ensure_key_action("fps_reload", KEY_R)
	_ensure_key_action("fps_toggle_mouse", KEY_ESCAPE)
	_ensure_key_action("fps_quick_restart", KEY_F5)
	_ensure_mouse_action("fps_fire", MOUSE_BUTTON_LEFT)


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
