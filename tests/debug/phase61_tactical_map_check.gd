extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]

var failed: bool = false


func _ready() -> void:
	_verify_map_definition()
	if failed:
		return
	_verify_resolver_map_rules()
	if failed:
		return
	await _verify_combat_scene_map_surface()
	if failed:
		return

	print("PHASE61_TACTICAL_MAP_CHECK: PASS")
	get_tree().quit(0)


func _verify_map_definition() -> void:
	var map_script: GDScript = load("res://scripts/grid/TacticalMapDefinition.gd")
	var map_data: Dictionary = map_script.get_default_map()
	if String(map_data.get("name", "")) != "Crossfire Table":
		_fail("Default tactical map should be Crossfire Table.")
		return
	var center: Dictionary = map_script.get_cell_feature(map_data, Vector2i(1, 1))
	if String(center.get("short_label", "")) != "POT":
		_fail("Center cell should be the Ante Pot objective.")
		return
	if int(center.get("card_damage_bonus", 0)) != 1:
		_fail("Center Pot should add +1 card damage.")
		return
	var cover: Dictionary = map_script.get_cell_feature(map_data, Vector2i(0, 2))
	if int(cover.get("incoming_damage_mitigation", 0)) != 2:
		_fail("Back Cover should reduce incoming lane damage by 2.")


func _verify_resolver_map_rules() -> void:
	var map_script: GDScript = load("res://scripts/grid/TacticalMapDefinition.gd")
	var map_data: Dictionary = map_script.get_default_map()
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	add_child(resolver)

	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker",
		"map_context": map_script.build_context(map_data, Vector2i(1, 1))
	})
	var skulker_hp := _get_enemy_hp(resolver, &"skulker")
	if skulker_hp != 9:
		_fail("Center Pot should make Quick Slash deal 5 total damage; got Skulker HP %d." % skulker_hp)
		return

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 0,
		"payload": {"damage": 8}
	}], {
		"player_lane": 0,
		"map_context": map_script.build_context(map_data, Vector2i(0, 2))
	})
	var player_hp := int(resolver.call("get_state").get("player", {}).get("hp", -1))
	if player_hp != 24:
		_fail("Back Cover should reduce an 8 damage lane hit to 6; got player HP %d." % player_hp)


func _verify_combat_scene_map_surface() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await _settle()

	var start_button: Button = combat_scene.find_child("StartRunButton", true, false)
	var combat_grid: Node = combat_scene.find_child("CombatGrid", true, false)
	if start_button == null or combat_grid == null:
		_fail("Expected StartRunButton and CombatGrid.")
		return

	start_button.emit_signal("pressed")
	await _settle()

	var context: Dictionary = combat_grid.call("get_map_context")
	if String(context.get("map_name", "")) != "Crossfire Table":
		_fail("CombatGrid should expose Crossfire Table map context.")
		return

	var cells: GridContainer = combat_grid.find_child("Cells", true, false)
	if cells == null or cells.get_child_count() < 5:
		_fail("CombatGrid should create map cells.")
		return
	var center_cell: Button = cells.get_child(4) as Button
	if center_cell == null or not String(center_cell.get("text")).contains("POT"):
		_fail("Center grid cell should visibly mark the Ante Pot objective.")
		return

	var arena: Control = combat_scene.find_child("Arena3DView", true, false)
	if arena == null or not arena.has_method("configure_map"):
		_fail("Arena3DView should accept tactical map data.")


func _get_enemy_hp(resolver: Node, enemy_id: StringName) -> int:
	var state: Dictionary = resolver.call("get_state")
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		if StringName(enemy_data.get("id", &"")) == enemy_id:
			return int(enemy_data.get("hp", -1))
	return -1


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
