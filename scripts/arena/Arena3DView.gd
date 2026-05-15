class_name Arena3DView
extends SubViewportContainer

const PLAYER_ID := &"player"
const GRID_SPACING := 1.55
const UNIT_Y := 0.28
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")

var viewport: SubViewport
var world_root: Node3D
var map_root: Node3D
var units_root: Node3D
var effects_root: Node3D
var camera: Camera3D
var table_mesh: MeshInstance3D
var focus_marker: MeshInstance3D
var focus_marker_tween: Tween
var focus_unit_id: StringName = &""
var units: Dictionary = {}
var headless_mode: bool = false
var map_data: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if map_data.is_empty():
		map_data = TACTICAL_MAP_SCRIPT.get_default_map()
	headless_mode = DisplayServer.get_name() == "headless"
	if headless_mode:
		visible = false
		return

	_build_viewport()
	_build_world()
	_start_table_idle()


func configure_map(new_map_data: Dictionary) -> void:
	map_data = new_map_data.duplicate(true) if not new_map_data.is_empty() else TACTICAL_MAP_SCRIPT.get_default_map()
	if headless_mode or map_root == null:
		return
	_rebuild_map_features()


func reset_units(position_snapshot: Dictionary, combat_state: Dictionary = {}) -> void:
	if headless_mode:
		return

	for unit_id in units.keys():
		var unit_data: Dictionary = units[unit_id]
		var root: Node3D = unit_data.get("root", null)
		if root != null and is_instance_valid(root):
			root.queue_free()
	units.clear()

	sync_units(position_snapshot)
	sync_combat_state(combat_state)


func sync_units(position_snapshot: Dictionary) -> void:
	if headless_mode:
		return

	var seen := {}
	for unit_key in position_snapshot.keys():
		var unit_id := StringName(unit_key)
		var entry: Dictionary = position_snapshot[unit_key]
		var cell: Vector2i = entry.get("cell", Vector2i(-1, -1))
		if cell.x < 0:
			continue
		var label := String(entry.get("label", String(unit_id)))
		seen[unit_id] = true
		_ensure_unit(unit_id, label, cell)
		var unit_data: Dictionary = units[unit_id]
		var root: Node3D = unit_data.get("root", null)
		if root != null:
			root.position = _cell_to_world(cell)
			unit_data["cell"] = cell
			units[unit_id] = unit_data

	for existing_id in units.keys():
		if seen.has(existing_id):
			continue
		var existing_data: Dictionary = units[existing_id]
		var existing_root: Node3D = existing_data.get("root", null)
		if existing_root != null and is_instance_valid(existing_root):
			existing_root.queue_free()
		units.erase(existing_id)


func sync_combat_state(combat_state: Dictionary) -> void:
	if headless_mode or combat_state.is_empty():
		return

	_apply_actor_state(combat_state.get("player", {}))
	for enemy in combat_state.get("enemies", []):
		if typeof(enemy) == TYPE_DICTIONARY:
			_apply_actor_state(enemy)


func play_card_beat(style: StringName, source_id: StringName, target_id: StringName, target_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if headless_mode:
		return

	var target_position := _get_unit_or_cell_position(target_id, target_cell)
	match style:
		&"attack":
			_spawn_target_beam(target_position, Color(1.0, 0.28, 0.18))
			_play_lunge(source_id, target_position)
			_spawn_burst(target_position, Color(1.0, 0.24, 0.16), &"slash")
			_shake_unit(target_id, Color(1.0, 0.32, 0.24))
			_pulse_camera(0.04)
		&"guard":
			var source_position := _get_unit_or_cell_position(source_id, Vector2i(-1, -1))
			_spawn_guard_ring(source_position)
			_shake_unit(source_id, Color(0.45, 0.86, 1.0))
		&"move":
			_spawn_burst(target_position, Color(0.36, 1.0, 0.54), &"spark")
		&"read":
			_spawn_burst(target_position, Color(0.78, 0.50, 1.0), &"spark")
			_pulse_camera(0.02)
		&"trap":
			_spawn_burst(target_position, Color(0.55, 0.28, 0.76), &"smoke")
		&"ritual", &"bluff":
			_spawn_burst(_get_unit_or_cell_position(source_id, Vector2i(-1, -1)), Color(1.0, 0.68, 0.24), &"chip")
		_:
			_spawn_burst(target_position, Color(1.0, 0.78, 0.30), &"spark")


func play_move(unit_id: StringName, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if headless_mode:
		return

	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		_ensure_unit(unit_id, String(unit_id), from_cell)
		unit_data = units.get(unit_id, {})
	var root: Node3D = unit_data.get("root", null)
	if root == null:
		return

	var destination := _cell_to_world(to_cell)
	_spawn_burst(_cell_to_world(from_cell), Color(0.42, 1.0, 0.62), &"spark")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "position", destination, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3(1.12, 1.12, 1.12), 0.12).from(Vector3.ONE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "rotation_degrees:y", root.rotation_degrees.y + 12.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(root, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(root):
			root.rotation_degrees.y = 0.0
			_spawn_burst(destination, Color(0.36, 1.0, 0.54), &"spark")
	)
	unit_data["cell"] = to_cell
	units[unit_id] = unit_data


func play_damage(unit_id: StringName, amount: int = 0) -> void:
	if headless_mode:
		return
	var position := _get_unit_or_cell_position(unit_id, Vector2i(-1, -1))
	_spawn_burst(position, Color(1.0, 0.22, 0.14), &"slash")
	_shake_unit(unit_id, Color(1.0, 0.30, 0.22))
	if amount > 0:
		_spawn_number(position + Vector3(0.0, 0.7, 0.0), "-%d" % amount, Color(1.0, 0.30, 0.20))
	_pulse_camera(0.035)


func play_guard(unit_id: StringName, amount: int = 0) -> void:
	if headless_mode:
		return
	var position := _get_unit_or_cell_position(unit_id, Vector2i(-1, -1))
	_spawn_guard_ring(position)
	if amount > 0:
		_spawn_number(position + Vector3(0.0, 0.7, 0.0), "+%dG" % amount, Color(0.55, 0.88, 1.0))


func play_defeat(unit_id: StringName) -> void:
	if headless_mode:
		return
	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		return
	var root: Node3D = unit_data.get("root", null)
	if root == null:
		return
	_spawn_burst(root.global_position, Color(0.78, 0.70, 0.58), &"smoke")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector3(0.05, 0.05, 0.05), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(root, "rotation_degrees:z", 72.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(root, "position:y", 0.02, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func focus_unit(unit_id: StringName) -> void:
	if headless_mode:
		return
	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		return
	var root: Node3D = unit_data.get("root", null)
	if root == null:
		return
	focus_unit_id = unit_id
	_move_focus_marker(root.global_position)
	_play_focus_breathe(unit_id)
	_spawn_guard_ring(root.global_position, Color(1.0, 0.78, 0.26))
	_spawn_target_beam(root.global_position, Color(1.0, 0.72, 0.24))


func preview_card_intent(style: StringName, source_id: StringName, target_id: StringName, target_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if headless_mode:
		return
	var target_position := _get_unit_or_cell_position(target_id, target_cell)
	if target_id != &"" and units.has(target_id):
		focus_unit(target_id)
	else:
		_move_focus_marker(target_position)
	match style:
		&"attack":
			_spawn_target_beam(target_position, Color(1.0, 0.30, 0.20))
		&"guard":
			_spawn_guard_ring(_get_unit_or_cell_position(source_id, Vector2i(-1, -1)), Color(0.52, 0.86, 1.0))
		&"move":
			_spawn_guard_ring(target_position, Color(0.36, 1.0, 0.54))
		&"read":
			_spawn_target_beam(target_position, Color(0.78, 0.50, 1.0))
		_:
			_spawn_guard_ring(target_position, Color(1.0, 0.78, 0.30))


func _build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.name = "ArenaViewport"
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(960, 540)
	add_child(viewport)


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "ArenaWorld"
	viewport.add_child(world_root)

	var environment := WorldEnvironment.new()
	environment.name = "ArenaEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.018, 0.016)
	env.ambient_light_color = Color(0.36, 0.24, 0.18)
	env.ambient_light_energy = 0.72
	env.fog_enabled = true
	env.fog_density = 0.045
	env.fog_light_color = Color(0.42, 0.24, 0.18)
	environment.environment = env
	world_root.add_child(environment)

	camera = Camera3D.new()
	camera.name = "ArenaCamera"
	camera.fov = 34.0
	camera.look_at_from_position(Vector3(0.0, 4.25, 5.9), Vector3(0.0, 0.12, 0.0), Vector3.UP)
	camera.current = true
	world_root.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.name = "CandleKeyLight"
	key_light.rotation_degrees = Vector3(-52.0, 32.0, 0.0)
	key_light.light_energy = 1.45
	key_light.light_color = Color(1.0, 0.70, 0.42)
	world_root.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "BloodFillLight"
	fill_light.position = Vector3(-2.2, 1.4, 1.5)
	fill_light.light_color = Color(0.72, 0.18, 0.14)
	fill_light.light_energy = 1.8
	fill_light.omni_range = 6.0
	world_root.add_child(fill_light)

	var target_light := SpotLight3D.new()
	target_light.name = "TargetSpotlight"
	target_light.position = Vector3(0.0, 4.2, 0.2)
	target_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	target_light.light_color = Color(1.0, 0.62, 0.24)
	target_light.light_energy = 2.1
	target_light.spot_range = 7.0
	target_light.spot_angle = 42.0
	world_root.add_child(target_light)

	units_root = Node3D.new()
	units_root.name = "ArenaUnits"
	world_root.add_child(units_root)
	map_root = Node3D.new()
	map_root.name = "TacticalMap"
	world_root.add_child(map_root)
	effects_root = Node3D.new()
	effects_root.name = "ArenaEffects"
	world_root.add_child(effects_root)
	_build_table()


func _build_table() -> void:
	_build_arena_room()

	table_mesh = MeshInstance3D.new()
	table_mesh.name = "CursedTable"
	var table_box := BoxMesh.new()
	table_box.size = Vector3(6.4, 0.16, 4.8)
	table_mesh.mesh = table_box
	table_mesh.material_override = _make_material(Color(0.13, 0.055, 0.035), Color(0.28, 0.12, 0.06), 0.18)
	table_mesh.position = Vector3(0.0, -0.12, 0.0)
	world_root.add_child(table_mesh)

	var border_mesh := BoxMesh.new()
	border_mesh.size = Vector3(6.8, 0.12, 5.2)
	var border := MeshInstance3D.new()
	border.name = "BrassTableRim"
	border.mesh = border_mesh
	border.material_override = _make_material(Color(0.56, 0.36, 0.12), Color(0.9, 0.54, 0.18), 0.25)
	border.position = Vector3(0.0, -0.19, 0.0)
	world_root.add_child(border)
	world_root.move_child(border, table_mesh.get_index())

	for y in range(3):
		for x in range(3):
			var cell := MeshInstance3D.new()
			cell.name = "ArenaCell_%d_%d" % [x, y]
			var plane := PlaneMesh.new()
			plane.size = Vector2(1.32, 1.02)
			cell.mesh = plane
			cell.position = _cell_to_world(Vector2i(x, y)) + Vector3(0.0, -0.015, 0.0)
			cell.material_override = _make_material(Color(0.16, 0.12, 0.08, 0.46), Color(0.95, 0.58, 0.18), 0.18, true)
			world_root.add_child(cell)

	for lane in range(3):
		var lane_strip := MeshInstance3D.new()
		lane_strip.name = "FeltLane_%d" % lane
		var lane_mesh := PlaneMesh.new()
		lane_mesh.size = Vector2(1.48, 4.05)
		lane_strip.mesh = lane_mesh
		lane_strip.position = _cell_to_world(Vector2i(lane, 1)) + Vector3(0.0, -0.025, 0.0)
		var lane_color := Color(0.12, 0.18, 0.12, 0.24) if lane != 1 else Color(0.20, 0.15, 0.08, 0.28)
		lane_strip.material_override = _make_material(lane_color, Color(0.72, 0.46, 0.18), 0.05, true)
		world_root.add_child(lane_strip)

	_rebuild_map_features()
	_build_table_dressing()
	_build_focus_marker()


func _rebuild_map_features() -> void:
	if map_root == null:
		return
	for child in map_root.get_children():
		child.queue_free()

	for y in range(3):
		for x in range(3):
			var cell := Vector2i(x, y)
			var feature := TACTICAL_MAP_SCRIPT.get_cell_feature(map_data, cell)
			if feature.is_empty():
				continue
			_build_map_feature_marker(cell, feature)


func _build_map_feature_marker(cell: Vector2i, feature: Dictionary) -> void:
	var feature_type := String(feature.get("type", ""))
	var base_position := _cell_to_world(cell)
	var color := _get_feature_color(feature, "border_color", Color(1.0, 0.72, 0.24))
	var fill := _get_feature_color(feature, "color", Color(color.r, color.g, color.b, 0.24))

	var floor_marker := MeshInstance3D.new()
	floor_marker.name = "Map_%s_%d_%d" % [feature_type, cell.x, cell.y]
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(1.10, 0.78)
	floor_marker.mesh = floor_mesh
	floor_marker.position = base_position + Vector3(0.0, -0.006, 0.0)
	floor_marker.material_override = _make_material(fill, color, 0.16, true)
	map_root.add_child(floor_marker)

	match feature_type:
		"cover":
			_add_cover_piece(base_position, color, cell)
		"objective":
			_add_objective_piece(base_position, color)
		"angle":
			_add_angle_piece(base_position, color)
		"flank":
			_add_flank_piece(base_position, color)
		"choke":
			_add_choke_piece(base_position, color)
		_:
			_add_floor_pip(base_position, color)


func _add_cover_piece(position: Vector3, color: Color, cell: Vector2i) -> void:
	var cover := MeshInstance3D.new()
	cover.name = "MapCover"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.84, 0.24, 0.13)
	cover.mesh = mesh
	var z_offset := -0.42 if cell.y <= 1 else 0.42
	cover.position = position + Vector3(0.0, 0.13, z_offset)
	cover.material_override = _make_material(Color(color.r * 0.42, color.g * 0.42, color.b * 0.42, 0.82), color, 0.32, true)
	map_root.add_child(cover)


func _add_objective_piece(position: Vector3, color: Color) -> void:
	var pot := MeshInstance3D.new()
	pot.name = "MapCenterPot"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.38
	pot.mesh = torus
	pot.position = position + Vector3(0.0, 0.075, 0.0)
	pot.material_override = _make_material(Color(color.r, color.g, color.b, 0.58), color, 0.75, true)
	map_root.add_child(pot)


func _add_angle_piece(position: Vector3, color: Color) -> void:
	var sightline := MeshInstance3D.new()
	sightline.name = "MapSightline"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.10, 0.035, 1.02)
	sightline.mesh = mesh
	sightline.position = position + Vector3(0.0, 0.055, 0.0)
	sightline.rotation_degrees.y = -24.0
	sightline.material_override = _make_material(Color(color.r, color.g, color.b, 0.46), color, 0.62, true)
	map_root.add_child(sightline)


func _add_flank_piece(position: Vector3, color: Color) -> void:
	var flank := MeshInstance3D.new()
	flank.name = "MapFlankArrow"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.035, 0.10)
	flank.mesh = mesh
	flank.position = position + Vector3(0.0, 0.052, 0.0)
	flank.rotation_degrees.y = 34.0
	flank.material_override = _make_material(Color(color.r, color.g, color.b, 0.42), color, 0.55, true)
	map_root.add_child(flank)


func _add_choke_piece(position: Vector3, color: Color) -> void:
	for offset in [-0.22, 0.22]:
		var post := MeshInstance3D.new()
		post.name = "MapChokePost"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.035
		mesh.bottom_radius = 0.045
		mesh.height = 0.20
		post.mesh = mesh
		post.position = position + Vector3(offset, 0.12, 0.0)
		post.material_override = _make_material(Color(color.r * 0.62, color.g * 0.62, color.b * 0.62), color, 0.34)
		map_root.add_child(post)


func _add_floor_pip(position: Vector3, color: Color) -> void:
	var pip := MeshInstance3D.new()
	pip.name = "MapPip"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.10
	mesh.bottom_radius = 0.10
	mesh.height = 0.035
	pip.mesh = mesh
	pip.position = position + Vector3(0.0, 0.045, 0.0)
	pip.material_override = _make_material(Color(color.r, color.g, color.b, 0.48), color, 0.45, true)
	map_root.add_child(pip)


func _build_arena_room() -> void:
	var back_wall := MeshInstance3D.new()
	back_wall.name = "VelvetBackWall"
	var wall_mesh := PlaneMesh.new()
	wall_mesh.size = Vector2(8.4, 3.2)
	back_wall.mesh = wall_mesh
	back_wall.position = Vector3(0.0, 1.28, -2.72)
	back_wall.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	back_wall.material_override = _make_material(Color(0.105, 0.018, 0.028), Color(0.58, 0.12, 0.08), 0.22)
	world_root.add_child(back_wall)

	for index in range(7):
		var pillar := MeshInstance3D.new()
		pillar.name = "BrassBackPillar"
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.08, 2.8, 0.06)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(-3.6 + float(index) * 1.2, 1.16, -2.66)
		pillar.material_override = _make_material(Color(0.46, 0.28, 0.10), Color(0.95, 0.58, 0.20), 0.36)
		world_root.add_child(pillar)

	for side in [-1, 1]:
		var rail := MeshInstance3D.new()
		rail.name = "ArenaSideRail"
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.12, 0.28, 5.2)
		rail.mesh = rail_mesh
		rail.position = Vector3(float(side) * 3.56, 0.18, 0.0)
		rail.material_override = _make_material(Color(0.42, 0.22, 0.08), Color(0.86, 0.46, 0.16), 0.30)
		world_root.add_child(rail)

	var house_sig := MeshInstance3D.new()
	house_sig.name = "HouseSigilGlow"
	var sigil_mesh := TorusMesh.new()
	sigil_mesh.inner_radius = 0.46
	sigil_mesh.outer_radius = 0.50
	house_sig.mesh = sigil_mesh
	house_sig.position = Vector3(0.0, 1.42, -2.61)
	house_sig.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	house_sig.material_override = _make_material(Color(1.0, 0.42, 0.12, 0.40), Color(1.0, 0.42, 0.12), 0.92, true)
	world_root.add_child(house_sig)


func _build_table_dressing() -> void:
	var chip_colors := [
		Color(0.72, 0.08, 0.08),
		Color(0.92, 0.72, 0.22),
		Color(0.18, 0.25, 0.38)
	]
	for index in range(18):
		var chip := MeshInstance3D.new()
		chip.name = "TableChip"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.07
		cylinder.bottom_radius = 0.07
		cylinder.height = 0.024
		chip.mesh = cylinder
		var x := -2.85 + float(index % 6) * 0.18
		var z := -2.05 + float(index / 6) * 0.16
		if index >= 9:
			x = 2.35 + float(index % 5) * 0.15
			z = 1.72 + float(index / 5) * 0.14
		chip.position = Vector3(x, 0.02 + float(index % 3) * 0.012, z)
		chip.material_override = _make_material(chip_colors[index % chip_colors.size()], Color(1.0, 0.62, 0.20), 0.12)
		world_root.add_child(chip)

	for index in range(4):
		var candle := MeshInstance3D.new()
		candle.name = "CandleGlow"
		var candle_mesh := CylinderMesh.new()
		candle_mesh.top_radius = 0.045
		candle_mesh.bottom_radius = 0.055
		candle_mesh.height = 0.22
		candle.mesh = candle_mesh
		candle.position = Vector3(-3.0 + float(index % 2) * 6.0, 0.09, -2.08 + float(index / 2) * 4.15)
		candle.material_override = _make_material(Color(0.82, 0.70, 0.48), Color(1.0, 0.62, 0.24), 0.22)
		world_root.add_child(candle)

		var light := OmniLight3D.new()
		light.name = "CandleLight"
		light.position = candle.position + Vector3(0.0, 0.28, 0.0)
		light.light_color = Color(1.0, 0.58, 0.22)
		light.light_energy = 0.72
		light.omni_range = 1.7
		world_root.add_child(light)


func _build_focus_marker() -> void:
	focus_marker = MeshInstance3D.new()
	focus_marker.name = "AttackTargetSpotlight"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.46
	torus.outer_radius = 0.52
	focus_marker.mesh = torus
	focus_marker.material_override = _make_material(Color(1.0, 0.70, 0.20, 0.74), Color(1.0, 0.62, 0.16), 0.85, true)
	focus_marker.position = Vector3(0.0, 0.12, 0.0)
	focus_marker.visible = false
	effects_root.add_child(focus_marker)


func _ensure_unit(unit_id: StringName, label: String, cell: Vector2i) -> void:
	if units.has(unit_id):
		return

	var root := Node3D.new()
	root.name = "ArenaUnit_%s" % String(unit_id)
	root.position = _cell_to_world(cell)
	units_root.add_child(root)

	var mesh := MeshInstance3D.new()
	mesh.name = "Body"
	mesh.mesh = _make_unit_mesh(unit_id)
	mesh.material_override = _get_unit_material(unit_id)
	mesh.position = Vector3(0.0, UNIT_Y, 0.0)
	root.add_child(mesh)

	var nameplate := Label3D.new()
	nameplate.name = "Nameplate"
	nameplate.text = _short_label(unit_id, label)
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.font_size = 36
	nameplate.modulate = Color(1.0, 0.90, 0.68)
	nameplate.outline_size = 12
	nameplate.position = Vector3(0.0, 0.92, 0.0)
	nameplate.visible = false
	root.add_child(nameplate)

	var hp_bar := MeshInstance3D.new()
	hp_bar.name = "HealthBar"
	var hp_box := BoxMesh.new()
	hp_box.size = Vector3(0.58, 0.045, 0.045)
	hp_bar.mesh = hp_box
	hp_bar.material_override = _make_material(Color(0.82, 0.12, 0.10), Color(0.9, 0.10, 0.08), 0.35)
	hp_bar.position = Vector3(0.0, 0.78, 0.0)
	root.add_child(hp_bar)

	var guard_bar := MeshInstance3D.new()
	guard_bar.name = "GuardBar"
	var guard_box := BoxMesh.new()
	guard_box.size = Vector3(0.46, 0.035, 0.035)
	guard_bar.mesh = guard_box
	guard_bar.material_override = _make_material(Color(0.28, 0.68, 1.0), Color(0.45, 0.85, 1.0), 0.45)
	guard_bar.position = Vector3(0.0, 0.69, 0.0)
	guard_bar.visible = false
	root.add_child(guard_bar)

	units[unit_id] = {
		"root": root,
		"mesh": mesh,
		"hp_bar": hp_bar,
		"guard_bar": guard_bar,
		"cell": cell,
		"max_hp": 1
	}
	_play_unit_entrance(root, unit_id)


func _apply_actor_state(actor: Dictionary) -> void:
	if actor.is_empty():
		return
	var unit_id := StringName(actor.get("id", &""))
	if unit_id.is_empty() or not units.has(unit_id):
		return

	var unit_data: Dictionary = units[unit_id]
	var max_hp: int = max(1, int(actor.get("max_hp", unit_data.get("max_hp", 1))))
	var hp: int = clampi(int(actor.get("hp", max_hp)), 0, max_hp)
	var guard: int = max(0, int(actor.get("guard", 0)))
	unit_data["max_hp"] = max_hp

	var hp_bar: MeshInstance3D = unit_data.get("hp_bar", null)
	if hp_bar != null:
		hp_bar.scale.x = max(0.04, float(hp) / float(max_hp))
		hp_bar.visible = hp > 0
	var guard_bar: MeshInstance3D = unit_data.get("guard_bar", null)
	if guard_bar != null:
		guard_bar.visible = guard > 0
		guard_bar.scale.x = clampf(float(guard) / 12.0, 0.16, 1.25)

	var mesh: MeshInstance3D = unit_data.get("mesh", null)
	if mesh != null:
		mesh.transparency = 0.0 if bool(actor.get("alive", true)) or unit_id == PLAYER_ID else 0.65
	units[unit_id] = unit_data


func _play_lunge(unit_id: StringName, target_position: Vector3) -> void:
	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		return
	var root: Node3D = unit_data.get("root", null)
	if root == null:
		return
	var origin := root.position
	var direction := (target_position - origin)
	if direction.length() > 0.01:
		direction = direction.normalized()
	var lunge_position := origin + direction * 0.24
	var tween := create_tween()
	tween.tween_property(root, "position", lunge_position, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "position", origin, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _shake_unit(unit_id: StringName, color: Color) -> void:
	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		return
	var mesh: MeshInstance3D = unit_data.get("mesh", null)
	var root: Node3D = unit_data.get("root", null)
	if mesh == null or root == null:
		return
	var original_x := root.position.x
	var original_material: Material = mesh.material_override
	mesh.material_override = _make_material(color, color, 0.45)
	var tween := create_tween()
	tween.tween_property(root, "position:x", original_x + 0.08, 0.04)
	tween.tween_property(root, "position:x", original_x - 0.08, 0.04)
	tween.tween_property(root, "position:x", original_x, 0.06)
	tween.tween_callback(func() -> void:
		if is_instance_valid(mesh):
			mesh.material_override = original_material
	)


func _spawn_guard_ring(position: Vector3, color: Color = Color(0.45, 0.82, 1.0)) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "ArenaGuardRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = 0.39
	ring.mesh = torus
	ring.material_override = _make_material(Color(color.r, color.g, color.b, 0.62), color, 0.65, true)
	ring.position = position + Vector3(0.0, 0.28, 0.0)
	effects_root.add_child(ring)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.55, 1.55, 1.55), 0.34).from(Vector3(0.45, 0.45, 0.45)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "transparency", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func _move_focus_marker(position: Vector3) -> void:
	if focus_marker == null:
		return
	focus_marker.visible = true
	focus_marker.position = Vector3(position.x, 0.11, position.z)
	if focus_marker_tween != null and focus_marker_tween.is_valid():
		focus_marker_tween.kill()
	focus_marker_tween = create_tween()
	focus_marker_tween.set_loops()
	focus_marker_tween.set_parallel(true)
	focus_marker_tween.tween_property(focus_marker, "scale", Vector3(1.22, 1.22, 1.22), 0.46).from(Vector3(0.78, 0.78, 0.78)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	focus_marker_tween.tween_property(focus_marker, "rotation_degrees:y", 360.0, 1.2).from(0.0).set_trans(Tween.TRANS_LINEAR)


func _play_focus_breathe(unit_id: StringName) -> void:
	var unit_data: Dictionary = units.get(unit_id, {})
	if unit_data.is_empty():
		return
	var root: Node3D = unit_data.get("root", null)
	if root == null:
		return
	var tween := create_tween()
	tween.tween_property(root, "scale", Vector3(1.09, 1.09, 1.09), 0.13).from(Vector3.ONE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _spawn_target_beam(position: Vector3, color: Color) -> void:
	var beam := MeshInstance3D.new()
	beam.name = "TargetBeam"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.035
	cylinder.bottom_radius = 0.11
	cylinder.height = 1.24
	beam.mesh = cylinder
	beam.material_override = _make_material(Color(color.r, color.g, color.b, 0.34), color, 0.95, true)
	beam.position = position + Vector3(0.0, 0.78, 0.0)
	effects_root.add_child(beam)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(beam, "scale", Vector3(1.45, 0.55, 1.45), 0.34).from(Vector3(0.45, 0.18, 0.45)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(beam, "transparency", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)


func _play_unit_entrance(root: Node3D, unit_id: StringName) -> void:
	var destination := root.position
	root.position = destination + Vector3(0.0, 0.0, 0.42 if unit_id == PLAYER_ID else -0.42)
	root.scale = Vector3(0.78, 0.78, 0.78)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "position", destination, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_burst(position: Vector3, color: Color, style: StringName) -> void:
	var count := 16
	if style == &"smoke":
		count = 20
	elif style == &"chip":
		count = 12
	for index in range(count):
		var bit := MeshInstance3D.new()
		bit.name = "ArenaParticle"
		var mesh := SphereMesh.new()
		mesh.radius = 0.035 if style != &"chip" else 0.05
		mesh.height = 0.07 if style != &"chip" else 0.025
		bit.mesh = mesh
		bit.material_override = _make_material(color, color, 0.45, true)
		bit.position = position + Vector3(0.0, 0.36, 0.0)
		effects_root.add_child(bit)

		var angle := TAU * float(index) / float(count)
		var outward := Vector3(cos(angle), 0.42 if style != &"smoke" else 0.78, sin(angle))
		var distance := 0.48 if style != &"smoke" else 0.72
		if style == &"slash":
			outward.z *= 0.22
			distance = 0.68
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(bit, "position", bit.position + outward.normalized() * distance, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bit, "scale", Vector3(0.05, 0.05, 0.05), 0.36).from(Vector3.ONE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(bit, "transparency", 1.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(func() -> void:
			if is_instance_valid(bit):
				bit.queue_free()
		)


func _spawn_number(position: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = "ArenaFloatingNumber"
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.modulate = color
	label.outline_size = 12
	label.position = position
	effects_root.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y + 0.45, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func _pulse_camera(amount: float) -> void:
	if camera == null:
		return
	var base_position := camera.position
	var tween := create_tween()
	tween.tween_property(camera, "position", base_position + Vector3(0.0, amount, -amount * 2.0), 0.06)
	tween.tween_property(camera, "position", base_position, 0.16)


func _start_table_idle() -> void:
	if table_mesh == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(table_mesh, "position:y", -0.09, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(table_mesh, "position:y", -0.13, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _get_unit_or_cell_position(unit_id: StringName, cell: Vector2i) -> Vector3:
	if not unit_id.is_empty() and units.has(unit_id):
		var unit_data: Dictionary = units[unit_id]
		var root: Node3D = unit_data.get("root", null)
		if root != null:
			return root.global_position
	if cell.x >= 0:
		return _cell_to_world(cell)
	return Vector3.ZERO


func _cell_to_world(cell: Vector2i) -> Vector3:
	var x := (float(cell.x) - 1.0) * GRID_SPACING
	var z := (float(cell.y) - 1.0) * GRID_SPACING * 1.20
	return Vector3(x, 0.04, z)


func _short_label(unit_id: StringName, fallback: String) -> String:
	if unit_id == PLAYER_ID:
		return "YOU"
	if fallback.length() <= 3:
		return fallback
	var parts := fallback.split(" ", false)
	if parts.size() > 1:
		var initials := ""
		for part in parts:
			initials += part.substr(0, 1)
		return initials.to_upper()
	return fallback.substr(0, 2).to_upper()


func _make_unit_mesh(unit_id: StringName) -> Mesh:
	if unit_id == PLAYER_ID:
		var player_capsule := CapsuleMesh.new()
		player_capsule.radius = 0.24
		player_capsule.height = 0.82
		return player_capsule
	var unit_key := String(unit_id)
	if unit_key == "shieldbearer":
		var shield_box := BoxMesh.new()
		shield_box.size = Vector3(0.48, 0.74, 0.22)
		return shield_box
	if unit_key == "brute":
		var brute_capsule := CapsuleMesh.new()
		brute_capsule.radius = 0.30
		brute_capsule.height = 0.92
		return brute_capsule
	if unit_key == "needle_eye":
		var sniper_box := BoxMesh.new()
		sniper_box.size = Vector3(0.24, 0.84, 0.24)
		return sniper_box
	if unit_key == "skulker":
		var duelist_capsule := CapsuleMesh.new()
		duelist_capsule.radius = 0.18
		duelist_capsule.height = 0.76
		return duelist_capsule
	var enemy_capsule := CapsuleMesh.new()
	enemy_capsule.radius = 0.22
	enemy_capsule.height = 0.78
	return enemy_capsule


func _get_unit_material(unit_id: StringName) -> StandardMaterial3D:
	if unit_id == PLAYER_ID:
		return _make_material(Color(0.12, 0.34, 0.82), Color(0.38, 0.68, 1.0), 0.35)
	match String(unit_id):
		"shieldbearer":
			return _make_material(Color(0.48, 0.12, 0.12), Color(1.0, 0.44, 0.32), 0.28)
		"skulker":
			return _make_material(Color(0.36, 0.09, 0.06), Color(0.92, 0.28, 0.20), 0.22)
		"brute":
			return _make_material(Color(0.42, 0.12, 0.08), Color(1.0, 0.22, 0.14), 0.25)
		_:
			return _make_material(Color(0.38, 0.10, 0.08), Color(0.9, 0.22, 0.18), 0.24)


func _get_feature_color(feature: Dictionary, key: String, fallback: Color) -> Color:
	var color_value: Variant = feature.get(key, fallback)
	if typeof(color_value) == TYPE_COLOR:
		return color_value
	return fallback


func _make_material(albedo: Color, emission: Color = Color.BLACK, emission_energy: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.72
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	return material
