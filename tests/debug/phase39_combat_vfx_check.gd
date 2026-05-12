extends Node

var failed: bool = false


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	_verify_vfx_layer(combat_scene)
	if failed:
		return
	await _verify_card_hover_feedback()
	if failed:
		return
	await _verify_grid_focus_feedback()
	if failed:
		return

	print("PHASE39_COMBAT_VFX_CHECK: PASS")
	get_tree().quit(0)


func _verify_vfx_layer(combat_scene: Node) -> void:
	var vfx_layer: Control = combat_scene.find_child("CombatVFX", true, false)
	if vfx_layer == null:
		_fail("Expected CombatVFX overlay to be attached to TestCombat.")
		return

	for method_name in ["play_card_burst_on", "play_slash_between", "play_burst_at", "play_guard_pulse_at", "play_curse_smoke_on"]:
		if not vfx_layer.has_method(method_name):
			_fail("CombatVFX missing method %s." % method_name)
			return

	var previous_count := vfx_layer.get_child_count()
	vfx_layer.call("play_burst_at", Vector2(160, 140), Color(1.0, 0.30, 0.20), &"blood")
	vfx_layer.call("play_ring_at", Vector2(180, 160), Color(0.38, 0.78, 1.0), 28.0)
	if vfx_layer.get_child_count() <= previous_count:
		_fail("CombatVFX should spawn transient child nodes for procedural effects.")


func _verify_card_hover_feedback() -> void:
	var card_script: Script = load("res://scripts/ui/CardView.gd")
	var card_resource: Resource = load("res://resources/cards/quick_slash.tres")
	var card_view := Button.new()
	card_view.set_script(card_script)
	add_child(card_view)
	card_view.call("set_card", card_resource, 0)
	await get_tree().process_frame

	card_view.call("set_previewed", true)
	await get_tree().create_timer(0.20).timeout
	if card_view.scale.x < 1.04 or absf(card_view.rotation_degrees) < 0.5:
		_fail("CardView hover should lift/tilt the card.")
		return

	card_view.call("set_previewed", false)
	await get_tree().create_timer(0.20).timeout
	if card_view.scale.distance_to(Vector2.ONE) > 0.03 or absf(card_view.rotation_degrees) > 0.5:
		_fail("CardView hover should return to rest.")
	card_view.queue_free()


func _verify_grid_focus_feedback() -> void:
	var cell_script: Script = load("res://scripts/grid/GridCellView.gd")
	var cell_view := Button.new()
	cell_view.set_script(cell_script)
	add_child(cell_view)
	cell_view.call("configure", Vector2i(1, 1))
	await get_tree().process_frame

	cell_view.call("set_focus_target", true)
	await get_tree().process_frame
	if int(cell_view.get("z_index")) != 6:
		_fail("GridCellView focus should raise the active cell.")
		return

	cell_view.call("set_focus_target", false)
	await get_tree().process_frame
	if int(cell_view.get("z_index")) != 0:
		_fail("GridCellView focus should restore the cell z-index.")
	cell_view.queue_free()


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
