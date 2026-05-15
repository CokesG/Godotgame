class_name FPSDrone
extends CharacterBody3D

signal damaged(amount: int, health: int, critical: bool)
signal defeated

@export var display_name := "Skulker"
@export var max_health := 70
@export var move_speed := 3.6
@export var acceleration := 9.0
@export var attack_range := 1.75
@export var attack_damage := 12
@export var attack_cooldown := 1.05
@export var texture_path := "res://art/game/enemies/enemy_skulker.png"
@export var accent_color := Color(0.86, 0.24, 0.18)

var player: Node3D
var game_mode: Node
var health: int
var alive := true
var attack_timer := 0.4
var stagger_timer := 0.0
var knockback := Vector3.ZERO
var gravity := 17.0
var body_mesh: MeshInstance3D
var sprite: Sprite3D
var health_bar_root: Node3D
var health_bar_fill: MeshInstance3D
var rng := RandomNumberGenerator.new()


func configure(data: Dictionary, target_player: Node3D, owner_game_mode: Node) -> void:
	display_name = String(data.get("name", display_name))
	max_health = int(data.get("health", max_health))
	move_speed = float(data.get("speed", move_speed))
	attack_range = float(data.get("attack_range", attack_range))
	attack_damage = int(data.get("attack_damage", attack_damage))
	attack_cooldown = float(data.get("attack_cooldown", attack_cooldown))
	texture_path = String(data.get("texture", texture_path))
	accent_color = data.get("color", accent_color)
	player = target_player
	game_mode = owner_game_mode


func _ready() -> void:
	rng.randomize()
	add_to_group("fps_enemies")
	health = max_health
	_build_body()
	_update_health_bar()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if player == null or not is_instance_valid(player):
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var desired := Vector3.ZERO
	if distance > 0.05:
		var direction := to_player.normalized()
		look_at(global_position + direction, Vector3.UP)
		if distance > attack_range and stagger_timer <= 0.0:
			var strafe := global_basis.x * sin(Time.get_ticks_msec() * 0.0015 + float(get_instance_id() % 17)) * 0.32
			desired = (direction + strafe).normalized() * move_speed
		elif distance <= attack_range:
			_try_attack()

	if stagger_timer > 0.0:
		desired *= 0.25
	velocity.x = move_toward(velocity.x, desired.x + knockback.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z + knockback.z, acceleration * delta)
	knockback = knockback.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))
	move_and_slide()
	_update_sprite_facing()


func take_damage(amount: int, hit_position: Vector3, impulse: Vector3, critical: bool = false) -> Dictionary:
	if not alive:
		return {"defeated": true}
	health = maxi(0, health - amount)
	stagger_timer = 0.12 if not critical else 0.22
	knockback += Vector3(impulse.x, 0.0, impulse.z).limit_length(3.4 if critical else 2.1)
	_flash_body(critical)
	_update_health_bar()
	damaged.emit(amount, health, critical)
	if health <= 0:
		_die()
	return {"defeated": not alive, "health": health}


func is_critical_hit(point: Vector3) -> bool:
	return point.y > global_position.y + 1.18


func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if player != null and player.has_method("take_damage"):
		player.call("take_damage", attack_damage, global_position)
	_pulse_attack()


func _die() -> void:
	alive = false
	remove_from_group("fps_enemies")
	defeated.emit()
	if game_mode != null and game_mode.has_method("on_enemy_defeated"):
		game_mode.call("on_enemy_defeated", self)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.08, 0.08, 0.08), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees:z", 64.0, 0.34)
	tween.chain().tween_callback(queue_free)


func _build_body() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "DroneCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.43
	capsule.height = 1.72
	collision.shape = capsule
	collision.position.y = 0.86
	add_child(collision)

	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.40
	mesh.height = 1.68
	body_mesh.mesh = mesh
	body_mesh.position.y = 0.86
	body_mesh.material_override = _make_body_material(accent_color)
	add_child(body_mesh)

	sprite = Sprite3D.new()
	sprite.name = "Portrait"
	sprite.position = Vector3(0.0, 1.34, -0.045)
	sprite.pixel_size = 0.00082
	sprite.modulate.a = 0.88
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = false
	var tex := load(texture_path)
	if tex is Texture2D:
		sprite.texture = tex
	add_child(sprite)

	health_bar_root = Node3D.new()
	health_bar_root.name = "HealthBar"
	health_bar_root.position = Vector3(0.0, 2.12, 0.0)
	add_child(health_bar_root)
	var back := _health_bar_piece("Back", Color(0.10, 0.08, 0.07), Vector3(0.82, 0.055, 0.018))
	health_bar_root.add_child(back)
	health_bar_fill = _health_bar_piece("Fill", Color(0.95, 0.22, 0.14), Vector3(0.78, 0.06, 0.02))
	health_bar_fill.position.z = -0.003
	health_bar_root.add_child(health_bar_fill)


func _health_bar_piece(node_name: String, color: Color, size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	instance.mesh = mesh
	instance.scale = size
	instance.material_override = _make_unshaded_material(color)
	return instance


func _update_health_bar() -> void:
	if health_bar_fill == null:
		return
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_bar_fill.scale.x = 0.78 * ratio
	health_bar_fill.position.x = -0.39 + health_bar_fill.scale.x * 0.5


func _update_sprite_facing() -> void:
	if health_bar_root != null and player != null:
		health_bar_root.look_at(player.global_position + Vector3.UP, Vector3.UP)


func _flash_body(critical: bool) -> void:
	if body_mesh == null:
		return
	var original := body_mesh.material_override
	body_mesh.material_override = _make_body_material(Color(1.0, 0.86, 0.38) if critical else Color(1.0, 0.38, 0.25))
	var tween := create_tween()
	tween.tween_interval(0.055)
	tween.tween_callback(func() -> void:
		if is_instance_valid(body_mesh):
			body_mesh.material_override = original
	)


func _pulse_attack() -> void:
	if body_mesh == null:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body_mesh, "scale", Vector3(1.18, 1.08, 1.18), 0.08)
	tween.chain().tween_property(body_mesh, "scale", Vector3.ONE, 0.12)


func _make_body_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.62
	mat.metallic = 0.08
	mat.emission_enabled = true
	mat.emission = color.darkened(0.55)
	mat.emission_energy_multiplier = 0.22
	return mat


func _make_unshaded_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
