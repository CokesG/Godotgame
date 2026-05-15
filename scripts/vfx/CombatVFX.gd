class_name CombatVFX
extends Control

const DEFAULT_PARTICLE_COUNT := 12
const POLISH_ASSET_PATHS := [
	"res://art/game/vfx/vfx_particle_atlas.svg",
	"res://art/game/vfx/vfx_slash_strip.svg",
	"res://art/game/vfx/vfx_ritual_circle.svg",
	"res://art/game/vfx/vfx_card_burn_mask.svg",
	"res://art/game/vfx/generated/vfx_slash_strip.png",
	"res://art/game/vfx/generated/vfx_smoke_strip.png",
	"res://art/game/vfx/generated/vfx_chip_scatter_strip.png",
	"res://art/game/vfx/generated/vfx_ritual_glow_strip.png",
	"res://art/game/vfx/generated/vfx_guard_shield_strip.png",
	"res://art/game/vfx/generated/vfx_blood_hit_strip.png",
	"res://art/game/vfx/generated/vfx_death_ash_strip.png",
	"res://art/game/vfx/generated/vfx_card_burn_strip.png"
]

const SFX_ASSET_PATHS := [
	"res://audio/sfx/generated/sfx_card_flick.wav",
	"res://audio/sfx/generated/sfx_chip_clack.wav",
	"res://audio/sfx/generated/sfx_slash_hit.wav",
	"res://audio/sfx/generated/sfx_guard_shimmer.wav",
	"res://audio/sfx/generated/sfx_smoke_whoosh.wav",
	"res://audio/sfx/generated/sfx_ritual_hum.wav",
	"res://audio/sfx/generated/sfx_card_burn.wav",
	"res://audio/sfx/generated/sfx_ash_fall.wav"
]

const SPRITE_STRIPS := {
	&"slash": {
		"path": "res://art/game/vfx/generated/vfx_slash_strip.png",
		"frames": 6,
		"frame_size": Vector2i(192, 96),
		"duration": 0.20
	},
	&"smoke": {
		"path": "res://art/game/vfx/generated/vfx_smoke_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.52
	},
	&"chip": {
		"path": "res://art/game/vfx/generated/vfx_chip_scatter_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.38
	},
	&"ritual": {
		"path": "res://art/game/vfx/generated/vfx_ritual_glow_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.50
	},
	&"guard_shield": {
		"path": "res://art/game/vfx/generated/vfx_guard_shield_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.30
	},
	&"blood_hit": {
		"path": "res://art/game/vfx/generated/vfx_blood_hit_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.26
	},
	&"death_ash": {
		"path": "res://art/game/vfx/generated/vfx_death_ash_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.58
	},
	&"card_burn": {
		"path": "res://art/game/vfx/generated/vfx_card_burn_strip.png",
		"frames": 6,
		"frame_size": Vector2i(128, 128),
		"duration": 0.42
	}
}

const SFX := {
	&"card": "res://audio/sfx/generated/sfx_card_flick.wav",
	&"chip": "res://audio/sfx/generated/sfx_chip_clack.wav",
	&"slash": "res://audio/sfx/generated/sfx_slash_hit.wav",
	&"guard": "res://audio/sfx/generated/sfx_guard_shimmer.wav",
	&"smoke": "res://audio/sfx/generated/sfx_smoke_whoosh.wav",
	&"ritual": "res://audio/sfx/generated/sfx_ritual_hum.wav",
	&"burn": "res://audio/sfx/generated/sfx_card_burn.wav",
	&"ash": "res://audio/sfx/generated/sfx_ash_fall.wav"
}

var sprite_strip_textures: Dictionary = {}
var sfx_streams: Dictionary = {}
var audio_players: Array[AudioStreamPlayer] = []
var next_audio_player_index: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_sprite_strips()
	_load_sfx()
	_build_audio_pool()


func get_polish_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in POLISH_ASSET_PATHS:
		paths.append(String(path))
	for path in SFX_ASSET_PATHS:
		paths.append(String(path))
	return paths


func get_sfx_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in SFX_ASSET_PATHS:
		paths.append(String(path))
	return paths


func _load_sprite_strips() -> void:
	sprite_strip_textures.clear()
	for key in SPRITE_STRIPS.keys():
		var metadata: Dictionary = SPRITE_STRIPS[key]
		var resource_path := String(metadata.get("path", ""))
		var image := Image.new()
		var image_error := image.load(ProjectSettings.globalize_path(resource_path))
		if image_error == OK:
			sprite_strip_textures[key] = ImageTexture.create_from_image(image)


func _load_sfx() -> void:
	sfx_streams.clear()
	for key in SFX.keys():
		var stream := _load_wav_stream(String(SFX[key]))
		if stream != null:
			sfx_streams[key] = stream


func _build_audio_pool() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "VFXSFXPlayer%d" % index
		player.volume_db = -8.0
		add_child(player)
		audio_players.append(player)


func play_card_burst_on(target: CanvasItem, color: Color) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_sfx(&"card", -4.0, randf_range(0.96, 1.04))
	play_ring_at(center, color, 40.0)
	play_burst_at(center, color, &"card")


func play_card_fly_between(start_global: Vector2, end_global: Vector2, color: Color, label: String = "", face_down: bool = false) -> void:
	var start := _to_layer_position(start_global)
	var end := _to_layer_position(end_global)
	if start == Vector2.ZERO or end == Vector2.ZERO:
		return
	_play_sfx(&"card", -7.0, 0.98 if face_down else 1.04)

	var control := end - start
	control.y -= max(86.0, abs(end.x - start.x) * 0.18)
	control.x += clampf((end.x - start.x) * 0.18, -80.0, 80.0)
	_play_card_arc_trail(start, control, end, color)

	var card := PanelContainer.new()
	card.name = "VFXCardFly"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = 98
	card.size = Vector2(88, 118)
	card.position = start - card.size * 0.5
	card.pivot_offset = card.size * 0.5
	card.modulate = Color(1.0, 1.0, 1.0, 0.92)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.055, 0.045, 0.96) if face_down else Color(0.19, 0.11, 0.075, 0.95).lerp(color, 0.12)
	style.border_color = Color(0.95, 0.70, 0.26, 0.95) if face_down else color.lerp(Color(1.0, 0.86, 0.40), 0.45)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.name = "VFXCardFlyLabel"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	title.text = "FACE DOWN" if face_down else label
	if title.text.length() > 28:
		title.text = "%s..." % title.text.substr(0, 25)
	card.add_child(title)
	add_child(card)

	var travel_time := 0.32
	var tween := card.create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(progress: float) -> void:
		if not is_instance_valid(card):
			return
		var point := _quadratic_bezier(start, control, end, progress)
		card.position = point - card.size * 0.5
		card.rotation_degrees = lerpf(-9.0 if face_down else -5.0, -3.0 if face_down else 9.0, progress)
	, 0.0, 1.0, travel_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(0.82, 0.82), travel_time).from(Vector2(1.14, 1.14)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 0.0, 0.16).set_delay(0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(card):
			card.queue_free()
	)


func play_card_preview_arc(start_global: Vector2, end_global: Vector2, color: Color) -> void:
	var start := _to_layer_position(start_global)
	var end := _to_layer_position(end_global)
	if start == Vector2.ZERO or end == Vector2.ZERO:
		return
	var control := end - start
	control.y -= max(64.0, abs(end.x - start.x) * 0.12)
	control.x += clampf((end.x - start.x) * 0.12, -56.0, 56.0)
	_play_card_arc_trail(start, control, end, Color(color.r, color.g, color.b, 0.62), 0.30, true)


func play_burst_on(target: CanvasItem, color: Color, style: StringName = &"spark") -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	play_burst_at(center, color, style)


func play_burst_at(global_position: Vector2, color: Color, style: StringName = &"spark") -> void:
	var center := _to_layer_position(global_position)
	match style:
		&"blood":
			_play_sfx(&"slash", -4.0, randf_range(0.94, 1.06))
			_play_sprite_strip_at_layer(center, &"blood_hit", Vector2(112, 112), 0.0, Color.WHITE, 98)
		&"ash":
			_play_sfx(&"ash", -6.0, randf_range(0.92, 1.04))
			_play_sprite_strip_at_layer(center, &"death_ash", Vector2(126, 126), 0.0, Color.WHITE, 98)
		&"guard":
			_play_sfx(&"guard", -6.0, randf_range(0.98, 1.08))
			_play_sprite_strip_at_layer(center, &"guard_shield", Vector2(112, 112), 0.0, Color.WHITE, 98)

	var count := DEFAULT_PARTICLE_COUNT
	if style == &"blood":
		count = 20
	elif style == &"guard":
		count = 16
	elif style == &"card":
		count = 16
	elif style == &"smoke":
		count = 16
	elif style == &"chip":
		count = 14
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
	_play_sfx(&"slash", -3.0, randf_range(0.96, 1.04))

	var midpoint := start.lerp(end, 0.5)
	var angle := (end - start).angle()
	var slash_size := Vector2(clampf(start.distance_to(end) * 0.72, 96.0, 240.0), 86.0)
	_play_sprite_strip_at_layer(midpoint, &"slash", slash_size, angle, Color(1.0, 1.0, 1.0, 0.96), 99)

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
	_play_sfx(&"guard", -4.0, randf_range(0.96, 1.05))
	_play_sprite_strip_at_global(global_position, &"guard_shield", Vector2(124, 124), 0.0, Color.WHITE, 98)
	play_ring_at(global_position, color, 54.0)
	play_ring_at(global_position, Color(0.75, 0.92, 1.0), 34.0)
	play_burst_at(global_position, color, &"guard")


func play_target_lock_on(target: CanvasItem, color: Color) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_target_lock_at(center, color)


func play_target_lock_at(global_position: Vector2, color: Color) -> void:
	_play_target_lock_at(global_position, color)


func play_reward_shimmer_on(target: CanvasItem) -> void:
	var rect := _target_rect(target)
	if rect == Rect2():
		return

	play_chip_burst_on(target)
	var start := _to_layer_position(rect.position)
	var end := _to_layer_position(rect.end)
	var shimmer := ColorRect.new()
	shimmer.name = "VFXRewardShimmer"
	shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shimmer.z_index = 97
	shimmer.color = Color(1.0, 0.86, 0.36, 0.82)
	shimmer.size = Vector2(max(36.0, (end.x - start.x) * 0.22), 4.0)
	shimmer.position = Vector2(start.x - shimmer.size.x, lerpf(start.y, end.y, 0.52))
	add_child(shimmer)

	var tween := shimmer.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shimmer, "position:x", end.x + shimmer.size.x * 0.35, 0.46).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(shimmer, "modulate:a", 0.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(shimmer):
			shimmer.queue_free()
	)


func play_button_sheen_on(target: CanvasItem, color: Color = Color(1.0, 0.78, 0.32)) -> void:
	var rect := _target_rect(target)
	if rect == Rect2():
		return

	play_ring_at(rect.get_center(), color, max(24.0, min(rect.size.x, rect.size.y) * 0.42))
	var start := _to_layer_position(rect.position)
	var end := _to_layer_position(rect.end)
	var sheen := ColorRect.new()
	sheen.name = "VFXButtonSheen"
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.z_index = 96
	sheen.color = Color(color.r, color.g, color.b, 0.74)
	sheen.size = Vector2(max(24.0, (end.x - start.x) * 0.22), 5.0)
	sheen.position = Vector2(start.x, lerpf(start.y, end.y, 0.18))
	add_child(sheen)

	var tween := sheen.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sheen, "position:x", end.x - sheen.size.x, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sheen, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(sheen):
			sheen.queue_free()
	)


func play_link_between_targets(start_target: CanvasItem, end_global: Vector2, color: Color) -> void:
	var start := _target_center(start_target)
	if start == Vector2.ZERO or end_global == Vector2.ZERO:
		return
	var start_layer := _to_layer_position(start)
	var end_layer := _to_layer_position(end_global)
	var line := Line2D.new()
	line.name = "VFXTargetLink"
	line.z_index = 96
	line.width = 4.0
	line.default_color = Color(color.r, color.g, color.b, 0.62)
	line.points = PackedVector2Array([start_layer, end_layer])
	add_child(line)

	var pulse := ColorRect.new()
	pulse.name = "VFXTargetLinkPulse"
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.z_index = 97
	pulse.color = Color(1.0, 0.88, 0.48, 0.9)
	pulse.size = Vector2(10, 10)
	pulse.pivot_offset = pulse.size * 0.5
	add_child(pulse)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(progress: float) -> void:
		if is_instance_valid(pulse):
			pulse.position = start_layer.lerp(end_layer, progress) - pulse.size * 0.5
	, 0.0, 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.12).set_delay(0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
		if is_instance_valid(pulse):
			pulse.queue_free()
	)


func play_click_beacon_on(target: CanvasItem, color: Color = Color(1.0, 0.78, 0.32), label: String = "CLICK") -> void:
	var rect := _target_rect(target)
	if rect == Rect2():
		return

	var center := rect.get_center()
	var radius: float = clamp(max(rect.size.x, rect.size.y) * 0.56, 36.0, 112.0)
	play_ring_at(center, color, radius)
	play_ring_at(center, Color(1.0, 0.92, 0.58), radius * 0.72)

	var start := _to_layer_position(rect.position)
	var end := _to_layer_position(rect.end)
	var badge := PanelContainer.new()
	badge.name = "VFXClickBeacon"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 99
	badge.modulate = Color(1.0, 1.0, 1.0, 0.96)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.88)
	style.border_color = Color(1.0, 0.94, 0.62, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_top = 4
	style.content_margin_right = 10
	style.content_margin_bottom = 4
	badge.add_theme_stylebox_override("panel", style)

	var label_node := Label.new()
	label_node.name = "VFXClickBeaconLabel"
	label_node.text = label.to_upper()
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.add_theme_font_size_override("font_size", 14)
	label_node.add_theme_color_override("font_color", Color(0.08, 0.045, 0.025))
	badge.add_child(label_node)
	add_child(badge)

	var badge_size := Vector2(max(76.0, float(label.length()) * 9.0 + 28.0), 30.0)
	badge.size = badge_size
	badge.position = Vector2(
		clampf(start.x + (end.x - start.x - badge_size.x) * 0.5, 8.0, max(8.0, size.x - badge_size.x - 8.0)),
		max(8.0, start.y - badge_size.y - 8.0)
	)
	badge.pivot_offset = badge_size * 0.5

	var tween := badge.create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2(1.08, 1.08), 0.18).from(Vector2(0.92, 0.92)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "position:y", badge.position.y - 8.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate:a", 0.0, 0.24).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(badge):
			badge.queue_free()
	)


func play_chip_burst_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_sfx(&"chip", -3.0, randf_range(0.94, 1.08))
	_play_sprite_strip_at_global(center, &"chip", Vector2(116, 116), 0.0, Color.WHITE, 98)
	play_burst_at(center, Color(1.0, 0.76, 0.34), &"chip")
	play_ring_at(center, Color(0.95, 0.70, 0.26), 34.0)


func play_curse_smoke_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_sfx(&"smoke", -5.0, randf_range(0.94, 1.02))
	_play_sprite_strip_at_global(center, &"smoke", Vector2(132, 132), -0.08, Color.WHITE, 98)
	play_burst_at(center, Color(0.42, 0.22, 0.68), &"smoke")
	play_ring_at(center, Color(0.55, 0.30, 0.78), 44.0)


func play_ritual_glow_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_sfx(&"ritual", -6.0, randf_range(0.96, 1.02))
	_play_sprite_strip_at_global(center, &"ritual", Vector2(138, 138), 0.0, Color.WHITE, 98)
	play_ring_at(center, Color(0.95, 0.28, 0.16), 48.0)


func play_card_burn_on(target: CanvasItem) -> void:
	var center := _target_center(target)
	if center == Vector2.ZERO:
		return
	_play_sfx(&"burn", -4.0, randf_range(0.96, 1.04))
	_play_sprite_strip_at_global(center, &"card_burn", Vector2(122, 122), 0.0, Color.WHITE, 99)
	play_burst_at(center, Color(1.0, 0.42, 0.18), &"ash")


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


func _play_target_lock_at(global_position: Vector2, color: Color) -> void:
	var center := _to_layer_position(global_position)
	var lock := Panel.new()
	lock.name = "VFXTargetLock"
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.z_index = 97
	lock.size = Vector2(74, 74)
	lock.position = center - lock.size * 0.5
	lock.pivot_offset = lock.size * 0.5
	lock.modulate = Color(1.0, 1.0, 1.0, 0.88)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.03)
	style.border_color = Color(color.r, color.g, color.b, 0.92)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	lock.add_theme_stylebox_override("panel", style)
	add_child(lock)

	var tween := lock.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lock, "scale", Vector2(0.64, 0.64), 0.22).from(Vector2(1.18, 1.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lock, "rotation_degrees", 10.0, 0.22).from(-8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(lock, "modulate:a", 0.0, 0.28).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(lock):
			lock.queue_free()
	)


func _play_card_arc_trail(start: Vector2, control: Vector2, end: Vector2, color: Color, duration: float = 0.36, subtle: bool = false) -> void:
	var trail := Line2D.new()
	trail.name = "VFXCardArcTrail"
	trail.z_index = 92
	trail.width = 5.0 if not subtle else 3.0
	trail.default_color = Color(color.r, color.g, color.b, 0.72 if not subtle else 0.38)
	var points := PackedVector2Array()
	for index in range(15):
		var progress := float(index) / 14.0
		points.append(_quadratic_bezier(start, control, end, progress))
	trail.points = points
	add_child(trail)

	var tween := trail.create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "width", 0.6, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(trail, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(trail):
			trail.queue_free()
	)


func _quadratic_bezier(start: Vector2, control: Vector2, end: Vector2, progress: float) -> Vector2:
	var inverse := 1.0 - progress
	return inverse * inverse * start + 2.0 * inverse * progress * control + progress * progress * end


func _play_sprite_strip_at_global(global_position: Vector2, strip_key: StringName, draw_size: Vector2, rotation: float = 0.0, modulate_color: Color = Color.WHITE, z: int = 98) -> void:
	_play_sprite_strip_at_layer(_to_layer_position(global_position), strip_key, draw_size, rotation, modulate_color, z)


func _play_sprite_strip_at_layer(layer_position: Vector2, strip_key: StringName, draw_size: Vector2, rotation: float = 0.0, modulate_color: Color = Color.WHITE, z: int = 98) -> void:
	if not sprite_strip_textures.has(strip_key):
		return
	var metadata: Dictionary = SPRITE_STRIPS.get(strip_key, {})
	var texture: Texture2D = sprite_strip_textures[strip_key]
	var frame_size: Vector2i = metadata.get("frame_size", Vector2i(128, 128))
	var frame_count: int = int(metadata.get("frames", 1))
	var duration: float = float(metadata.get("duration", 0.4))
	if texture == null or frame_count <= 0:
		return

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2.ZERO, Vector2(frame_size))

	var sprite := TextureRect.new()
	sprite.name = "VFXSpriteStrip"
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = z
	sprite.texture = atlas
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = draw_size
	sprite.position = layer_position - draw_size * 0.5
	sprite.pivot_offset = draw_size * 0.5
	sprite.rotation = rotation
	sprite.modulate = modulate_color
	add_child(sprite)

	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(progress: float) -> void:
		if not is_instance_valid(sprite):
			return
		var frame_index := clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
		atlas.region = Rect2(Vector2(float(frame_index * frame_size.x), 0.0), Vector2(frame_size))
	, 0.0, 0.999, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(sprite, "scale", Vector2(1.08, 1.08), duration).from(Vector2(0.88, 0.88)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.34).set_delay(duration * 0.66).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.queue_free()
	)


func _play_sfx(sfx_key: StringName, volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if audio_players.is_empty() or not sfx_streams.has(sfx_key):
		return
	var player := audio_players[next_audio_player_index % audio_players.size()]
	next_audio_player_index += 1
	player.stop()
	player.stream = sfx_streams[sfx_key]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _load_wav_stream(resource_path: String) -> AudioStreamWAV:
	var file_path := ProjectSettings.globalize_path(resource_path)
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44:
		return null

	var channel_count := _read_u16_le(bytes, 22)
	var sample_rate := _read_u32_le(bytes, 24)
	var bits_per_sample := _read_u16_le(bytes, 34)
	var data_offset := -1
	var data_size := 0
	var offset := 12
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := _read_u32_le(bytes, offset + 4)
		if chunk_id == "data":
			data_offset = offset + 8
			data_size = chunk_size
			break
		offset += 8 + chunk_size + int(chunk_size % 2)
	if data_offset < 0 or data_size <= 0:
		return null

	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.stereo = channel_count == 2
	stream.format = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 else AudioStreamWAV.FORMAT_8_BITS
	stream.data = bytes.slice(data_offset, min(bytes.size(), data_offset + data_size))
	return stream


func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 1 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 3 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)


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


func _target_rect(target: CanvasItem) -> Rect2:
	if target == null or not target.is_inside_tree():
		return Rect2()
	if target is Control:
		var control: Control = target
		return control.get_global_rect()
	var origin := target.get_global_transform_with_canvas().origin
	return Rect2(origin, Vector2(1, 1))


func _to_layer_position(global_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_position
