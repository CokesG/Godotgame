class_name FPSWeapon
extends Node3D

signal state_changed(ammo: int, reserve: int, reloading: bool)
signal fired(from: Vector3, to: Vector3)
signal hit_confirmed(position: Vector3, damage: int, critical: bool, defeated: bool)

@export var weapon_name := "Ante Carbine AR"
@export var damage := 18
@export var critical_damage := 34
@export var magazine_size := 30
@export var reserve_ammo := 90
@export var fire_interval := 0.092
@export var reload_time := 1.58
@export var range := 110.0
@export var base_spread_degrees := 0.20
@export var moving_spread_degrees := 0.58
@export var sustained_spread_degrees := 0.88
@export var recoil_recovery := 12.0
@export var viewmodel_recovery := 14.0

var player: Node
var camera: Camera3D
var game_mode: Node
var ammo: int
var reserve: int
var reloading := false
var reload_timer := 0.0
var fire_timer := 0.0
var shot_index := 0
var time_since_last_shot := 999.0
var sway_offset := Vector2.ZERO
var viewmodel_root: Node3D
var muzzle: Marker3D
var shell_eject: Marker3D
var magazine: MeshInstance3D
var base_position := Vector3(0.46, -0.42, -0.88)
var ads_position := Vector3(0.0, -0.19, -0.74)
var magazine_base_position := Vector3.ZERO
var recoil_position := Vector3.ZERO
var recoil_rotation := Vector3.ZERO
var ads_blend := 0.0
var rng := RandomNumberGenerator.new()
var overclock_timer := 0.0
var overclock_interval_scalar := 1.0
var overclock_damage_scalar := 1.0

var recoil_pattern: Array[Vector2] = [
	Vector2(0.00, 0.22),
	Vector2(0.03, 0.29),
	Vector2(-0.04, 0.35),
	Vector2(0.07, 0.41),
	Vector2(0.12, 0.43),
	Vector2(0.17, 0.39),
	Vector2(0.20, 0.35),
	Vector2(0.14, 0.32),
	Vector2(0.06, 0.30),
	Vector2(-0.04, 0.31),
	Vector2(-0.13, 0.33),
	Vector2(-0.20, 0.34),
	Vector2(-0.24, 0.31),
	Vector2(-0.17, 0.29),
	Vector2(-0.06, 0.28),
	Vector2(0.05, 0.29),
	Vector2(0.15, 0.30),
	Vector2(0.23, 0.30),
	Vector2(0.18, 0.28),
	Vector2(0.07, 0.27),
	Vector2(-0.06, 0.27),
	Vector2(-0.18, 0.29),
	Vector2(-0.25, 0.30),
	Vector2(-0.18, 0.28),
	Vector2(-0.06, 0.27),
	Vector2(0.08, 0.27),
	Vector2(0.18, 0.28),
	Vector2(0.12, 0.26),
	Vector2(0.02, 0.25),
	Vector2(-0.08, 0.25)
]


func _ready() -> void:
	rng.randomize()
	ammo = magazine_size
	reserve = reserve_ammo
	if camera == null:
		camera = get_parent() as Camera3D
	_build_viewmodel()
	state_changed.emit(ammo, reserve, reloading)


func _process(delta: float) -> void:
	fire_timer = maxf(0.0, fire_timer - delta)
	time_since_last_shot += delta
	if overclock_timer > 0.0:
		overclock_timer = maxf(0.0, overclock_timer - delta)
		if overclock_timer <= 0.0:
			overclock_interval_scalar = 1.0
			overclock_damage_scalar = 1.0
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	if game_mode != null and game_mode.has_method("is_gameplay_paused") and bool(game_mode.call("is_gameplay_paused")):
		_recover_viewmodel(delta)
		return

	if Input.is_action_pressed("fps_fire"):
		try_fire()
	if Input.is_action_just_pressed("fps_reload"):
		try_reload()

	_recover_viewmodel(delta)


func try_fire() -> bool:
	if camera == null or player == null:
		return false
	if reloading:
		return false
	if fire_timer > 0.0:
		return false
	if ammo <= 0:
		try_reload()
		_play_dry_punch()
		return false

	ammo -= 1
	fire_timer = fire_interval * overclock_interval_scalar
	if time_since_last_shot > 0.35:
		shot_index = 0
	time_since_last_shot = 0.0

	var from := camera.global_position
	var direction := _get_shot_direction()
	var to := from + direction * range
	var hit := _raycast(from, to)
	var end_point := to
	var critical := false
	var defeated := false
	var dealt_damage := 0

	if not hit.is_empty():
		end_point = hit.get("position", to)
		var collider: Object = hit.get("collider", null)
		critical = _is_critical_hit(collider, end_point)
		dealt_damage = int(round(float(critical_damage if critical else damage) * overclock_damage_scalar))
		if collider != null and collider.has_method("take_damage"):
			var result: Dictionary = collider.call("take_damage", dealt_damage, end_point, direction * 6.5, critical)
			defeated = bool(result.get("defeated", false))
			hit_confirmed.emit(end_point, dealt_damage, critical, defeated)
		if game_mode != null and game_mode.has_method("spawn_impact"):
			game_mode.call("spawn_impact", end_point, hit.get("normal", Vector3.UP), critical)
	else:
		dealt_damage = 0

	if game_mode != null and game_mode.has_method("spawn_tracer"):
		game_mode.call("spawn_tracer", muzzle.global_position if muzzle != null else from, end_point, critical)
	if game_mode != null and dealt_damage > 0 and game_mode.has_method("spawn_combat_text"):
		game_mode.call("spawn_combat_text", end_point + Vector3(0.0, 0.35, 0.0), str(dealt_damage), critical, defeated)

	_apply_recoil(critical)
	shot_index += 1
	state_changed.emit(ammo, reserve, reloading)
	fired.emit(from, end_point)
	return true


func try_reload() -> bool:
	if reloading or ammo >= magazine_size or reserve <= 0:
		return false
	reloading = true
	reload_timer = reload_time
	recoil_position += Vector3(-0.03, -0.08, 0.08)
	recoil_rotation += Vector3(deg_to_rad(-8.0), deg_to_rad(-4.0), deg_to_rad(12.0))
	state_changed.emit(ammo, reserve, reloading)
	return true


func force_ready() -> void:
	fire_timer = 0.0
	reload_timer = 0.0
	reloading = false
	ammo = magazine_size
	reserve = reserve_ammo
	state_changed.emit(ammo, reserve, reloading)


func configure_from_bridge(weapon_profile: Dictionary, total_ammo: int = -1) -> void:
	if not weapon_profile.is_empty():
		weapon_name = String(weapon_profile.get("name", weapon_name))
		damage = int(weapon_profile.get("damage", damage))
		critical_damage = maxi(damage + 10, int(round(float(damage) * 1.85)))
		magazine_size = maxi(1, int(weapon_profile.get("magazine", magazine_size)))
		var fire_rate := float(weapon_profile.get("fire_rate", 0.0))
		if fire_rate > 0.0:
			fire_interval = 1.0 / fire_rate
	if total_ammo >= 0:
		reserve_ammo = maxi(0, total_ammo - magazine_size)
	force_ready()


func apply_temporary_overclock(duration: float, interval_scalar: float, damage_scalar: float) -> void:
	overclock_timer = maxf(overclock_timer, duration)
	overclock_interval_scalar = clampf(interval_scalar, 0.45, 1.0)
	overclock_damage_scalar = clampf(damage_scalar, 1.0, 2.0)


func add_sway(delta_pixels: Vector2) -> void:
	sway_offset += delta_pixels * 0.0018
	sway_offset = sway_offset.clamp(Vector2(-0.08, -0.08), Vector2(0.08, 0.08))


func get_ammo_state() -> Dictionary:
	return {
		"weapon_name": weapon_name,
		"ammo": ammo,
		"reserve": reserve,
		"magazine_size": magazine_size,
		"reloading": reloading,
		"reload_progress": 1.0 - clampf(reload_timer / reload_time, 0.0, 1.0) if reloading else 1.0
	}


func _finish_reload() -> void:
	var needed := magazine_size - ammo
	var loaded := mini(needed, reserve)
	ammo += loaded
	reserve -= loaded
	reloading = false
	shot_index = 0
	state_changed.emit(ammo, reserve, reloading)


func _get_shot_direction() -> Vector3:
	var forward := -camera.global_basis.z
	var right := camera.global_basis.x
	var up := camera.global_basis.y
	var speed_ratio := 0.0
	if player != null and player.has_method("get_horizontal_speed_ratio"):
		speed_ratio = float(player.call("get_horizontal_speed_ratio"))
	var ads_spread_multiplier := 1.0
	if player != null and player.has_method("get_ads_spread_multiplier"):
		ads_spread_multiplier = float(player.call("get_ads_spread_multiplier"))

	var pattern := _get_recoil_pattern_value()
	var sustained := clampf(float(shot_index) / 7.0, 0.0, 1.0)
	var spread := base_spread_degrees
	spread += moving_spread_degrees * speed_ratio
	spread += sustained_spread_degrees * sustained
	spread *= ads_spread_multiplier
	var random_offset := Vector2(
		rng.randf_range(-spread, spread),
		rng.randf_range(-spread, spread)
	)
	var pattern_offset := pattern * Vector2(0.20, 0.10) * ads_spread_multiplier
	var total := (random_offset + pattern_offset) * deg_to_rad(1.0)
	return (forward + right * tan(total.x) + up * tan(total.y)).normalized()


func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if player != null and player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


func _is_critical_hit(collider: Object, point: Vector3) -> bool:
	if collider != null and collider.has_method("is_critical_hit"):
		return bool(collider.call("is_critical_hit", point))
	return false


func _get_recoil_pattern_value() -> Vector2:
	if recoil_pattern.is_empty():
		return Vector2.ZERO
	return recoil_pattern[mini(shot_index, recoil_pattern.size() - 1)]


func _get_ads_recoil_scalar() -> float:
	if player != null and player.has_method("is_ads_active") and bool(player.call("is_ads_active")):
		return 0.68
	return 1.0


func _apply_recoil(critical: bool) -> void:
	var pattern := _get_recoil_pattern_value()
	var recoil_scalar := _get_ads_recoil_scalar()
	var yaw := deg_to_rad((pattern.x + rng.randf_range(-0.025, 0.025)) * recoil_scalar)
	var pitch := deg_to_rad(pattern.y * recoil_scalar)
	if critical:
		pitch *= 0.82
	if player != null and player.has_method("apply_weapon_recoil"):
		player.call("apply_weapon_recoil", Vector2(pitch, yaw), 0.012)
	elif player != null and player.has_method("add_camera_impulse"):
		player.call("add_camera_impulse", Vector2(pitch, yaw), 0.018)

	var visual_scalar := lerpf(1.0, 0.48, ads_blend)
	recoil_position += Vector3(rng.randf_range(-0.010, 0.010), 0.010, 0.075) * visual_scalar
	recoil_rotation += Vector3(deg_to_rad(2.6), yaw * 1.8, deg_to_rad(rng.randf_range(-1.8, 1.8))) * visual_scalar
	if muzzle != null:
		_spawn_muzzle_flash()


func _play_dry_punch() -> void:
	recoil_position += Vector3(0.0, -0.01, 0.025)
	recoil_rotation += Vector3(deg_to_rad(1.2), 0.0, 0.0)


func _recover_viewmodel(delta: float) -> void:
	recoil_position = recoil_position.lerp(Vector3.ZERO, clampf(delta * viewmodel_recovery, 0.0, 1.0))
	recoil_rotation = recoil_rotation.lerp(Vector3.ZERO, clampf(delta * viewmodel_recovery, 0.0, 1.0))
	sway_offset = sway_offset.lerp(Vector2.ZERO, clampf(delta * 8.5, 0.0, 1.0))
	var target_ads_blend := 0.0
	if player != null and player.has_method("is_ads_active") and bool(player.call("is_ads_active")):
		target_ads_blend = 1.0
	ads_blend = lerpf(ads_blend, target_ads_blend, clampf(delta * 14.0, 0.0, 1.0))

	var bob := Vector3.ZERO
	if player != null and player.has_method("get_weapon_bob"):
		bob = player.call("get_weapon_bob")
	if viewmodel_root != null:
		var target_base := base_position.lerp(ads_position, ads_blend)
		var sway_scale := lerpf(1.0, 0.24, ads_blend)
		var visual_recoil_scale := lerpf(1.0, 0.55, ads_blend)
		var reload_progress := _get_reload_progress()
		var reload_curve := sin(reload_progress * PI)
		var reload_offset := Vector3(0.08, -0.11, 0.07) * reload_curve
		var reload_rotation := Vector3(deg_to_rad(-10.0), deg_to_rad(5.0), deg_to_rad(-8.0)) * reload_curve
		viewmodel_root.position = target_base + recoil_position * visual_recoil_scale + bob * sway_scale + Vector3(-sway_offset.x, sway_offset.y, 0.0) * sway_scale + reload_offset
		viewmodel_root.rotation = recoil_rotation * visual_recoil_scale + Vector3(sway_offset.y * 0.7, sway_offset.x * 1.1, -sway_offset.x * 0.35) * sway_scale + reload_rotation
	if magazine != null:
		var progress := _get_reload_progress()
		var mag_drop := sin(progress * PI)
		magazine.position = magazine_base_position + Vector3(0.0, -0.18 * mag_drop, 0.05 * mag_drop)
		magazine.rotation.x = deg_to_rad(-16.0 * mag_drop)


func _get_reload_progress() -> float:
	if not reloading or reload_time <= 0.0:
		return 0.0
	return 1.0 - clampf(reload_timer / reload_time, 0.0, 1.0)


func _spawn_muzzle_flash() -> void:
	var flash := MeshInstance3D.new()
	flash.name = "MuzzleFlash"
	var mesh := SphereMesh.new()
	mesh.radius = 0.065
	mesh.height = 0.12
	flash.mesh = mesh
	flash.material_override = _make_emissive_material(Color(1.0, 0.72, 0.30), 2.8, true)
	muzzle.add_child(flash)
	var light := OmniLight3D.new()
	light.name = "MuzzleLight"
	light.light_color = Color(1.0, 0.58, 0.25)
	light.light_energy = 1.6
	light.omni_range = 2.3
	muzzle.add_child(light)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(2.2, 2.2, 2.2), 0.045).from(Vector3(0.4, 0.4, 0.4))
	tween.tween_property(light, "light_energy", 0.0, 0.055)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
		if is_instance_valid(light):
			light.queue_free()
	)


func _build_viewmodel() -> void:
	viewmodel_root = Node3D.new()
	viewmodel_root.name = "ViewmodelRoot"
	add_child(viewmodel_root)

	var brass := _make_viewmodel_material(Color(0.96, 0.66, 0.28), 0.75, 0.22)
	var iron := _make_viewmodel_material(Color(0.16, 0.18, 0.19), 0.35, 0.42)
	var bone := _make_viewmodel_material(Color(0.88, 0.80, 0.64), 0.18, 0.68)
	var grip := _make_viewmodel_material(Color(0.29, 0.12, 0.08), 0.05, 0.72)

	_add_box(viewmodel_root, "Receiver", Vector3(0.0, 0.0, 0.0), Vector3(0.24, 0.14, 0.28), iron)
	_add_box(viewmodel_root, "TopRail", Vector3(0.0, 0.082, -0.045), Vector3(0.22, 0.034, 0.30), brass)
	_add_box(viewmodel_root, "Barrel", Vector3(0.0, 0.012, -0.33), Vector3(0.078, 0.078, 0.44), iron)
	_add_box(viewmodel_root, "MuzzleBlock", Vector3(0.0, 0.012, -0.59), Vector3(0.12, 0.10, 0.065), brass)
	_add_box(viewmodel_root, "RearSightLeft", Vector3(-0.052, 0.142, 0.075), Vector3(0.025, 0.080, 0.026), iron)
	_add_box(viewmodel_root, "RearSightRight", Vector3(0.052, 0.142, 0.075), Vector3(0.025, 0.080, 0.026), iron)
	_add_box(viewmodel_root, "FrontSightPost", Vector3(0.0, 0.150, -0.535), Vector3(0.020, 0.095, 0.020), iron)
	_add_box(viewmodel_root, "FrontSightBase", Vector3(0.0, 0.098, -0.535), Vector3(0.106, 0.030, 0.040), brass)
	magazine = _add_box(viewmodel_root, "Magazine", Vector3(0.0, -0.150, -0.010), Vector3(0.125, 0.230, 0.115), iron, Vector3(deg_to_rad(-3.0), 0.0, 0.0))
	magazine_base_position = magazine.position
	_add_box(viewmodel_root, "Grip", Vector3(0.075, -0.17, 0.08), Vector3(0.095, 0.24, 0.105), grip, Vector3(0.0, 0.0, deg_to_rad(-10.0)))
	_add_box(viewmodel_root, "Guard", Vector3(-0.09, -0.064, 0.035), Vector3(0.055, 0.095, 0.09), bone)
	_add_box(viewmodel_root, "Hand", Vector3(0.19, -0.16, -0.12), Vector3(0.14, 0.095, 0.18), bone)

	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0.0, 0.012, -0.67)
	viewmodel_root.add_child(muzzle)

	shell_eject = Marker3D.new()
	shell_eject.name = "ShellEject"
	shell_eject.position = Vector3(-0.18, 0.08, -0.08)
	viewmodel_root.add_child(shell_eject)


func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	instance.mesh = mesh
	instance.scale = size
	instance.position = pos
	instance.rotation = rot
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _make_viewmodel_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.use_z_clip_scale = true
	mat.z_clip_scale = 0.35
	return mat


func _make_emissive_material(color: Color, energy: float, transparent := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.82
	return mat
