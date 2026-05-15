class_name FPSPlayer
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int)
signal weapon_state_changed(ammo: int, reserve: int, reloading: bool)
signal request_restart

const FPS_WEAPON_SCRIPT := preload("res://scripts/fps/FPSWeapon.gd")

@export var max_health := 120
@export var walk_speed := 6.4
@export var sprint_speed := 9.2
@export var crouch_speed := 3.8
@export var acceleration := 18.0
@export var air_acceleration := 6.5
@export var ground_friction := 22.0
@export var jump_velocity := 5.4
@export var gravity := 17.5
@export var mouse_sensitivity := 0.00155
@export var base_fov := 74.0
@export var sprint_fov_add := 5.0
@export var standing_height := 1.82
@export var crouching_height := 1.16
@export var standing_eye_height := 1.61
@export var crouching_eye_height := 1.03
@export var coyote_time := 0.09
@export var jump_buffer_time := 0.11

var game_mode: Node
var health: int
var armor: int = 0
var head: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var body_shadow: MeshInstance3D
var weapon: Node
var pitch := 0.0
var current_height := 1.82
var target_height := 1.82
var current_eye_height := 1.61
var recoil_offset := Vector2.ZERO
var recoil_decay := 15.0
var fov_impulse := 0.0
var bob_time := 0.0
var bob_offset := Vector3.ZERO
var landing_kick := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := false
var dead := false
var mouse_captured := false
var last_spawn_position := Vector3.ZERO
var highest_horizontal_speed := 9.2
var input_enabled := true
var invert_y := false


func _ready() -> void:
	health = max_health
	last_spawn_position = global_position
	highest_horizontal_speed = sprint_speed
	current_height = standing_height
	target_height = standing_height
	current_eye_height = standing_eye_height
	_build_collision()
	_build_camera()
	_build_weapon()
	_capture_mouse()
	health_changed.emit(health, max_health)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fps_toggle_mouse"):
		if game_mode != null and game_mode.has_method("toggle_settings_menu"):
			game_mode.call("toggle_settings_menu")
		elif mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()
		get_viewport().set_input_as_handled()
		return

	if not input_enabled:
		return

	if event.is_action_pressed("fps_quick_restart"):
		request_restart.emit()
		get_viewport().set_input_as_handled()
		return

	if dead:
		return

	if event is InputEventMouseButton and event.is_action_pressed("fps_fire") and not mouse_captured:
		_capture_mouse()

	if event is InputEventMouseMotion:
		mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		if not mouse_captured:
			return
		var motion := event as InputEventMouseMotion
		_apply_mouse_look(motion.relative)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if dead or not input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_friction * delta)
		velocity.y -= gravity * delta
		move_and_slide()
		_update_camera(delta, Vector2.ZERO, false, false)
		return

	var input_vec := Input.get_vector("fps_move_left", "fps_move_right", "fps_move_forward", "fps_move_back")
	var wants_crouch := Input.is_action_pressed("fps_crouch")
	var wants_sprint := Input.is_action_pressed("fps_sprint") and input_vec.y < -0.2 and not wants_crouch
	var grounded := is_on_floor()

	if Input.is_action_just_pressed("fps_jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	if grounded:
		coyote_timer = coyote_time
		if not was_on_floor and velocity.y < -3.5:
			landing_kick = minf(0.08, absf(velocity.y) * 0.006)
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y -= gravity * delta

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not wants_crouch:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		grounded = false
		fov_impulse = maxf(fov_impulse, 1.2)

	var forward := -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_basis.x
	right.y = 0.0
	right = right.normalized()
	var wish_dir := (right * input_vec.x + forward * -input_vec.y)
	if wish_dir.length_squared() > 1.0:
		wish_dir = wish_dir.normalized()

	var speed := walk_speed
	if wants_crouch:
		speed = crouch_speed
	elif wants_sprint:
		speed = sprint_speed

	var target_velocity := wish_dir * speed
	var accel := acceleration if grounded else air_acceleration
	if wish_dir.is_zero_approx() and grounded:
		accel = ground_friction

	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta * speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta * speed)
	move_and_slide()

	_update_stance(delta, wants_crouch)
	_update_camera(delta, input_vec, wants_sprint, wants_crouch)
	was_on_floor = is_on_floor()


func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> void:
	if dead:
		return
	var remaining := amount
	if armor > 0:
		var absorbed := mini(armor, remaining)
		armor -= absorbed
		remaining -= absorbed
	health = maxi(0, health - remaining)
	var away := global_position - source_position
	away.y = 0.0
	if away.length_squared() > 0.01:
		velocity += away.normalized() * 2.8
	add_camera_impulse(Vector2(deg_to_rad(2.8), randf_range(-0.035, 0.035)), 0.08)
	damage_taken.emit(amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()


func reset_for_arena(spawn_position: Vector3) -> void:
	global_position = spawn_position
	last_spawn_position = spawn_position
	velocity = Vector3.ZERO
	health = max_health
	dead = false
	pitch = 0.0
	recoil_offset = Vector2.ZERO
	landing_kick = 0.0
	rotation = Vector3.ZERO
	if weapon != null:
		weapon.force_ready()
	health_changed.emit(health, max_health)
	_capture_mouse()


func apply_bridge_survivability(extra_armor: int) -> void:
	armor = maxi(0, extra_armor)
	health_changed.emit(health, max_health)


func add_armor(amount: int) -> void:
	armor = maxi(0, armor + amount)
	health_changed.emit(health, max_health)


func dash_forward(strength: float = 11.0) -> void:
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.01:
		forward = Vector3.FORWARD
	velocity += forward.normalized() * strength
	add_camera_impulse(Vector2(deg_to_rad(-1.2), randf_range(-0.015, 0.015)), 0.10)


func apply_aim_settings(settings: Dictionary) -> void:
	mouse_sensitivity = float(settings.get("mouse_sensitivity", mouse_sensitivity))
	base_fov = float(settings.get("fov", base_fov))
	sprint_fov_add = float(settings.get("sprint_fov_add", sprint_fov_add))
	invert_y = bool(settings.get("invert_y", invert_y))
	if camera != null:
		camera.fov = base_fov


func set_gameplay_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if enabled:
		_capture_mouse()
	else:
		_release_mouse()


func add_camera_impulse(amount: Vector2, fov_amount: float = 0.0) -> void:
	recoil_offset += amount
	recoil_offset.x = clampf(recoil_offset.x, deg_to_rad(-7.0), deg_to_rad(9.0))
	recoil_offset.y = clampf(recoil_offset.y, deg_to_rad(-4.0), deg_to_rad(4.0))
	fov_impulse = maxf(fov_impulse, fov_amount * 80.0)


func get_weapon_bob() -> Vector3:
	return bob_offset


func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_horizontal_speed_ratio() -> float:
	return clampf(get_horizontal_speed() / highest_horizontal_speed, 0.0, 1.0)


func _build_collision() -> void:
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = standing_height
	collision_shape.shape = capsule
	collision_shape.position.y = standing_height * 0.5
	add_child(collision_shape)

	body_shadow = MeshInstance3D.new()
	body_shadow.name = "BodyShadow"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.32
	mesh.height = standing_height
	body_shadow.mesh = mesh
	body_shadow.position.y = standing_height * 0.5
	body_shadow.visible = false
	add_child(body_shadow)


func _build_camera() -> void:
	head = Node3D.new()
	head.name = "Head"
	head.position.y = standing_eye_height
	add_child(head)

	camera = Camera3D.new()
	camera.name = "FPSCamera"
	camera.current = true
	camera.fov = 74.0
	camera.near = 0.025
	camera.far = 175.0
	head.add_child(camera)


func _build_weapon() -> void:
	weapon = FPS_WEAPON_SCRIPT.new()
	weapon.name = "Weapon"
	weapon.player = self
	weapon.camera = camera
	weapon.game_mode = game_mode
	camera.add_child(weapon)
	weapon.state_changed.connect(func(ammo: int, reserve: int, reloading: bool) -> void:
		weapon_state_changed.emit(ammo, reserve, reloading)
	)


func _update_stance(delta: float, wants_crouch: bool) -> void:
	target_height = crouching_height if wants_crouch else standing_height
	var target_eye := crouching_eye_height if wants_crouch else standing_eye_height
	current_height = move_toward(current_height, target_height, delta * 5.8)
	current_eye_height = move_toward(current_eye_height, target_eye, delta * 5.8)

	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule != null:
		capsule.height = current_height
	collision_shape.position.y = current_height * 0.5
	body_shadow.position.y = current_height * 0.5
	head.position.y = current_eye_height


func _update_camera(delta: float, input_vec: Vector2, wants_sprint: bool, wants_crouch: bool) -> void:
	var horizontal_speed := get_horizontal_speed()
	var grounded := is_on_floor()
	if grounded and horizontal_speed > 0.18:
		var bob_rate := 10.6
		var bob_amount := 0.026
		if wants_sprint:
			bob_rate = 13.8
			bob_amount = 0.041
		elif wants_crouch:
			bob_rate = 8.0
			bob_amount = 0.016
		bob_time += delta * bob_rate * clampf(horizontal_speed / walk_speed, 0.25, 1.4)
		bob_offset = Vector3(
			sin(bob_time * 0.5) * bob_amount * 0.45,
			absf(cos(bob_time)) * bob_amount,
			0.0
		)
	else:
		bob_offset = bob_offset.lerp(Vector3.ZERO, clampf(delta * 9.0, 0.0, 1.0))

	recoil_offset = recoil_offset.lerp(Vector2.ZERO, clampf(delta * recoil_decay, 0.0, 1.0))
	landing_kick = lerpf(landing_kick, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	fov_impulse = lerpf(fov_impulse, 0.0, clampf(delta * 6.0, 0.0, 1.0))

	head.rotation.x = pitch + recoil_offset.x + landing_kick
	head.rotation.z = -input_vec.x * 0.018 - recoil_offset.y * 0.35
	camera.rotation.y = recoil_offset.y

	var target_fov := base_fov
	if wants_sprint and horizontal_speed > walk_speed:
		target_fov = base_fov + sprint_fov_add
	target_fov += fov_impulse
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 8.0, 0.0, 1.0))


func _capture_mouse() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func _apply_mouse_look(relative_motion: Vector2) -> void:
	rotate_y(-relative_motion.x * mouse_sensitivity)
	var y_sign := 1.0 if invert_y else -1.0
	pitch = clampf(pitch + relative_motion.y * mouse_sensitivity * y_sign, deg_to_rad(-86.0), deg_to_rad(86.0))
	if weapon != null:
		weapon.add_sway(relative_motion)


func _die() -> void:
	dead = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func() -> void:
		request_restart.emit()
	)
