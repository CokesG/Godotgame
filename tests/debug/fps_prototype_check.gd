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

	var player: Node = prototype.find_child("FPSPlayer", true, false)
	var enemies_root: Node = prototype.find_child("Enemies", true, false)
	var hud: Node = prototype.find_child("FPSHud", true, false)
	if player == null or enemies_root == null or hud == null:
		_fail("Expected player, enemies root, and HUD in FPSPrototype.")
		return
	var reload_bar: Node = prototype.find_child("ReloadProgress", true, false)
	var reload_status: Node = prototype.find_child("ReloadStatusLabel", true, false)
	if reload_bar == null or reload_status == null:
		_fail("FPS HUD should expose reload progress state.")
		return
	if prototype.find_child("CombatStatusHud", true, false) == null:
		_fail("FPS HUD should frame combat state in a readable status panel.")
		return

	if not prototype.has_method("get_living_enemies"):
		_fail("FPSPrototype should expose get_living_enemies.")
		return
	if not prototype.has_method("get_map_summary"):
		_fail("FPSPrototype should expose tactical map summary.")
		return
	var map_summary: Dictionary = prototype.call("get_map_summary")
	if String(map_summary.get("name", "")) != "Crossfire Table":
		_fail("FPSPrototype should use the Crossfire Table tactical map.")
		return
	var map_markers: Node = prototype.find_child("TacticalMapMarkers", true, false)
	if map_markers == null or map_markers.get_child_count() < 9:
		_fail("FPSPrototype should render tactical map markers for all 3x3 regions.")
		return
	if prototype.find_child("ArenaSpectacleStage", true, false) == null:
		_fail("FPS arena should include authored spectacle staging.")
		return
	if prototype.find_child("EnemySpawnPortal0", true, false) == null:
		_fail("FPS arena should expose readable enemy spawn portals.")
		return
	if prototype.find_child("ObjectiveAntePot", true, false) == null:
		_fail("FPS arena should include an objective prop.")
		return
	var living: Array = prototype.call("get_living_enemies")
	if living.size() < 4:
		_fail("FPSPrototype should spawn the first enemy wave.")
		return
	var enemy_status: Node = (living[0] as Node).find_child("StatusLabel", true, false)
	if enemy_status == null:
		_fail("FPS enemies should expose readable status/tell labels.")
		return

	var weapon: Node = player.get("weapon")
	if weapon == null or not weapon.has_method("try_fire") or not weapon.has_method("try_reload"):
		_fail("FPSPlayer should build an FPSWeapon with fire/reload controls.")
		return

	var enemy: Node = living[0]
	if not enemy.has_method("take_damage"):
		_fail("FPS enemies should accept weapon damage.")
		return
	var before := int(enemy.get("health"))
	enemy.call("take_damage", 25, enemy.global_position + Vector3.UP, Vector3.ZERO, true)
	await _settle()
	var after := int(enemy.get("health"))
	if after >= before:
		_fail("FPS enemy damage should reduce health.")
		return

	print("FPS_PROTOTYPE_CHECK: PASS")
	get_tree().quit(0)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error(message)
	get_tree().quit(1)
