extends Node

var failed := false


func _ready() -> void:
	await _run_check()


func _run_check() -> void:
	var packed_scene: PackedScene = load("res://scenes/fps/FPSPrototype.tscn")
	if packed_scene == null:
		_fail("Could not load FPSPrototype scene.")
		return

	var prototype := packed_scene.instantiate()
	add_child(prototype)
	await _settle()
	if not _assert_runtime_visible(prototype, "initial arena"):
		return

	for cycle in range(3):
		await _clear_current_wave(prototype)
		if not bool(prototype.get("rewards_pending")):
			_fail("Wave %d should open reward selection." % int(prototype.get("wave_index")))
			return
		var reward_panel := prototype.find_child("RewardPanel", true, false) as Control
		if reward_panel == null or not reward_panel.visible:
			_fail("Wave %d reward panel should be visible." % int(prototype.get("wave_index")))
			return
		prototype.call("_select_reward", 0)
		await _settle()
		if not _assert_runtime_visible(prototype, "continued wave %d" % int(prototype.get("wave_index"))):
			return
		if bool(prototype.get("rewards_pending")):
			_fail("Reward state should close after continuing to the next wave.")
			return
		if int(prototype.get("wave_index")) != cycle + 2:
			_fail("Reward selection should advance to the next wave.")
			return
		var living: Array = prototype.call("get_living_enemies")
		if living.is_empty():
			_fail("Continued wave should spawn enemies.")
			return

	var player := prototype.find_child("FPSPlayer", true, false)
	if player == null or not player.has_method("take_damage"):
		_fail("FPS wave-loop check needs a damageable player.")
		return
	player.global_position = Vector3(18.6, 1.4, 0.0)
	prototype.call("_recover_out_of_bounds_actors")
	await _settle()
	if player.global_position.distance_to(Vector3(18.6, 1.4, 0.0)) > 0.25:
		_fail("Horizontal arena edge movement should not reset the player to start.")
		return

	var last_safe_position: Vector3 = player.global_position
	player.global_position = Vector3(last_safe_position.x, -8.0, last_safe_position.z)
	prototype.call("_recover_out_of_bounds_actors")
	await _settle()
	if player.global_position.distance_to(last_safe_position) > 0.25:
		_fail("Falling through the world should restore the last safe position, not the start point.")
		return

	player.call("take_damage", 9999, player.global_position + Vector3.FORWARD)
	await get_tree().create_timer(1.25).timeout
	await _settle()
	if bool(player.get("dead")):
		_fail("Player defeat should retry the current wave in-place, not leave the arena blank.")
		return
	if not _assert_runtime_visible(prototype, "post-defeat retry"):
		return

	print("FPS_WAVE_LOOP_CHECK: PASS")
	get_tree().quit(0)


func _clear_current_wave(prototype: Node) -> void:
	var living: Array = prototype.call("get_living_enemies")
	for enemy in living:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage"):
			enemy.call("take_damage", 9999, enemy.global_position + Vector3.UP, Vector3.ZERO, true)
		await get_tree().process_frame
	await _settle()


func _assert_runtime_visible(prototype: Node, context: String) -> bool:
	if prototype == null or not is_instance_valid(prototype) or not prototype.is_inside_tree():
		_fail("%s should keep FPSPrototype in the tree." % context)
		return false
	var player := prototype.find_child("FPSPlayer", true, false)
	if player == null:
		_fail("%s should keep the FPS player alive in the scene tree." % context)
		return false
	var camera := player.get("camera") as Camera3D
	if camera == null or not camera.current:
		_fail("%s should keep a current FPS camera." % context)
		return false
	var hud := prototype.find_child("FPSHud", true, false) as CanvasLayer
	if hud == null or not hud.visible:
		_fail("%s should keep the FPS HUD visible." % context)
		return false
	var backdrop := prototype.find_child("RewardBackdrop", true, false) as Control
	var panel := prototype.find_child("RewardPanel", true, false) as Control
	if not bool(prototype.get("rewards_pending")):
		if backdrop != null and backdrop.visible:
			_fail("%s should not leave the reward backdrop covering the arena." % context)
			return false
		if panel != null and panel.visible:
			_fail("%s should not leave the reward panel open after continuation." % context)
			return false
	return true


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.12).timeout


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error(message)
	get_tree().quit(1)
