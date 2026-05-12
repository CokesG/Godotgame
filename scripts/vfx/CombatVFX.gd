class_name CombatVFX
extends Control

const DEFAULT_PARTICLE_COUNT := 12


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func play_card_burst_on(target: CanvasItem, color: Color) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	play_ring_at(center, color, 40.0)
	play_burst_at(center, color, &"card")


func play_burst_on(target: CanvasItem, color: Color, style: StringName = &"spark") -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	play_burst_at(center, color, style)


func play_burst_at(global_position: Vector2, color: Color, style: StringName = &"spark") -> void:
	var center := _to_layer_position(global_position)
	var count := DEFAULT_PARTICLE_COUNT
	if style == &"smoke":
		count = 16
	elif style == &"chip":
		count = 10
	elif style == &"ash":
		count = 18

	for index in range(count):
		_spawn_particle(center, color, style, index, count)


func play_ring_at(global_position: Vector2, color: Color, radius: float = 48.0) -> void:
	var center := _to_layer_position(global_position)
	var ring := Panel.new()
	ring.name = "VFXRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 91
	ring.size = Vector2(radius * 2.0, radius * 2.0)
	ring.position = center - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5
	ring.modulate = Color(1.0, 1.0, 1.0, 0.78)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.05)
	style.border_color = Color(color.r, color.g, color.b, 0.76)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	var corner_radius := int(radius)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	ring.add_theme_stylebox_override("panel", style)
	add_child(ring)

	ring.scale = Vector2(0.42, 0.42)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.24, 1.24), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func play_slash_between(start_global: Vector2, end_global: Vector2, color: Color) -> void:
	var start := _to_layer_position(start_global)
	var end := _to_layer_position(end_global)
	if start.distance_to(end) < 8.0:
		play_burst_at(end_global, color, &"blood")
		return

	var slash := Line2D.new()
	slash.name = "VFXSlash"
	slash.z_index = 94
	slash.width = 9.0
	slash.default_color = Color(color.r, color.g, color.b, 0.94)
	slash.points = PackedVector2Array([start, end])
	add_child(slash)

	var highlight := Line2D.new()
	highlight.name = "VFXSlashHighlight"
	highlight.z_index = 95
	highlight.width = 3.0
	highlight.default_color = Color(1.0, 0.86, 0.60, 0.82)
	highlight.points = PackedVector2Array([start, end])
	add_child(highlight)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "width", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(slash, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(highlight, "width", 0.5, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(highlight, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(slash):
			slash.queue_free()
		if is_instance_valid(highlight):
			highlight.queue_free()
	)


func play_guard_pulse_at(global_position: Vector2, color: Color) -> void:
	play_ring_at(global_position, color, 54.0)
	play_ring_at(global_position, Color(0.75, 0.92, 1.0), 34.0)
	play_burst_at(global_position, color, &"guard")


func play_chip_burst_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	play_burst_at(center, Color(1.0, 0.76, 0.34), &"chip")
	play_ring_at(center, Color(0.95, 0.70, 0.26), 34.0)


func play_curse_smoke_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	play_burst_at(center, Color(0.42, 0.22, 0.68), &"smoke")
	play_ring_at(center, Color(0.55, 0.30, 0.78), 44.0)


func play_intent_flicker_on(target: CanvasItem, color: Color) -> void:
	var center := _target_center(target)
	if center != Vector2.ZERO:
		play_ring_at(center, color, 38.0)

	if target == null or not target.is_inside_tree():
		return

	target.modulate = color
	var tween := target.create_tween()
	tween.tween_property(target, "modulate", Color.WHITE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", color, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _spawn_particle(center: Vector2, color: Color, style: StringName, index: int, count: int) -> void:
	var particle := ColorRect.new()
	particle.name = "VFXParticle"
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle.z_index = 93
	particle.color = _particle_color(color, style, index)
	particle.size = _particle_size(style, index)
	particle.position = center - particle.size * 0.5
	particle.pivot_offset = particle.size * 0.5
	particle.rotation = TAU * float(index) / max(1.0, float(count))
	add_child(particle)

	var angle: float = TAU * float(index) / max(1.0, float(count))
	var distance: float = _particle_distance(style, index)
	var direction: Vector2 = Vector2.RIGHT.rotated(angle)
	if style == &"smoke":
		direction = Vector2(0.0, -1.0).rotated(-0.75 + 1.5 * float(index) / max(1.0, float(count - 1)))
	elif style == &"ash":
		direction = Vector2(0.0, -1.0).rotated(-1.0 + 2.0 * float(index) / max(1.0, float(count - 1)))

	var target_position := particle.position + direction * distance
	var tween := particle.create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position", target_position, _particle_duration(style)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "rotation", particle.rotation + 0.9, _particle_duration(style)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "scale", _particle_end_scale(style), _particle_duration(style)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "modulate:a", 0.0, _particle_duration(style)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(particle):
			particle.queue_free()
	)


func _particle_color(color: Color, style: StringName, index: int) -> Color:
	match style:
		&"blood":
			return Color(0.92, 0.08 + 0.03 * float(index % 3), 0.07, 0.95)
		&"guard":
			return Color(0.46, 0.84, 1.0, 0.82)
		&"chip":
			return Color(1.0, 0.70 + 0.08 * float(index % 2), 0.30, 0.94)
		&"smoke":
			return Color(0.20, 0.11, 0.30 + 0.05 * float(index % 3), 0.50)
		&"ash":
			return Color(0.82, 0.78, 0.66, 0.78)
		&"move":
			return Color(0.42, 1.0, 0.62, 0.82)
		_:
			return Color(color.r, color.g, color.b, 0.88)


func _particle_size(style: StringName, index: int) -> Vector2:
	match style:
		&"blood":
			return Vector2(5 + index % 4, 10 + index % 5)
		&"chip":
			return Vector2(10, 5)
		&"smoke":
			return Vector2(14 + index % 6, 14 + index % 6)
		&"ash":
			return Vector2(4 + index % 3, 8 + index % 4)
		&"guard":
			return Vector2(6, 6)
		_:
			return Vector2(6 + index % 3, 6 + index % 3)


func _particle_distance(style: StringName, index: int) -> float:
	match style:
		&"smoke":
			return 38.0 + 4.0 * float(index % 5)
		&"ash":
			return 48.0 + 5.0 * float(index % 5)
		&"chip":
			return 52.0 + 3.0 * float(index % 4)
		&"guard":
			return 36.0 + 3.0 * float(index % 4)
		_:
			return 44.0 + 5.0 * float(index % 5)


func _particle_duration(style: StringName) -> float:
	match style:
		&"smoke":
			return 0.72
		&"ash":
			return 0.64
		&"chip":
			return 0.38
		_:
			return 0.34


func _particle_end_scale(style: StringName) -> Vector2:
	if style == &"smoke":
		return Vector2(1.75, 1.75)
	if style == &"chip":
		return Vector2(0.75, 0.75)
	return Vector2(0.25, 0.25)


func _target_center(target: CanvasItem) -> Vector2:
	if target == null or not target.is_inside_tree():
		return Vector2.ZERO
	if target is Control:
		var control: Control = target
		return control.get_global_rect().get_center()
	return target.get_global_transform_with_canvas().origin


func _to_layer_position(global_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_position
