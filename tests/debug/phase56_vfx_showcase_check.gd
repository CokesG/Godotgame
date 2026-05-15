extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/debug/VFXShowcase.tscn")
	if packed_scene == null:
		_fail("Could not load VFXShowcase scene.")
		return

	var showcase: Control = packed_scene.instantiate()
	add_child(showcase)
	await get_tree().process_frame

	if not showcase.has_method("play_showcase"):
		_fail("VFXShowcase should expose play_showcase.")
		return
	if int(showcase.call("get_showcase_effect_count")) < 10:
		_fail("VFXShowcase should cover the core generated VFX beats.")
		return

	var vfx_layer: Control = showcase.find_child("CombatVFX", true, false)
	if vfx_layer == null:
		_fail("VFXShowcase should create a CombatVFX layer.")
		return

	var asset_paths: Array = showcase.call("get_registered_asset_paths")
	for path in [
		"res://art/game/vfx/generated/vfx_slash_strip.png",
		"res://art/game/vfx/generated/vfx_guard_shield_strip.png",
		"res://art/game/vfx/generated/vfx_card_burn_strip.png",
		"res://audio/sfx/generated/sfx_card_flick.wav",
		"res://audio/sfx/generated/sfx_slash_hit.wav",
		"res://audio/sfx/generated/sfx_guard_shimmer.wav"
	]:
		if not asset_paths.has(path):
			_fail("VFXShowcase should register %s." % path)
			return

	var before_count := vfx_layer.get_child_count()
	showcase.call("play_showcase")
	await get_tree().process_frame
	if vfx_layer.get_child_count() <= before_count:
		_fail("play_showcase should spawn visible transient VFX children.")
		return

	showcase.queue_free()
	await get_tree().process_frame
	print("PHASE56_VFX_SHOWCASE_CHECK: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
