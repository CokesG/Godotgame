extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func _ready() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	var grid: Node = load("res://scripts/grid/CombatGrid.gd").new()
	add_child(resolver)
	add_child(grid)

	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"shieldbearer",
		"target_enemy_name": "Shieldbearer"
	})

	var shieldbearer: Dictionary = _get_enemy_state(resolver, &"shieldbearer")
	if int(shieldbearer.get("hp", -1)) != int(shieldbearer.get("max_hp", 0)) - 4:
		_fail("Targeted Quick Slash should damage Shieldbearer, not the first enemy.")
		return

	var brute: Dictionary = _get_enemy_state(resolver, &"brute")
	if int(brute.get("hp", -1)) != int(brute.get("max_hp", 0)):
		_fail("Brute should remain undamaged after targeting Shieldbearer.")
		return

	grid.call("reset_grid")
	if grid.call("get_unit_position", &"skulker") != Vector2i(0, 0):
		_fail("Expected Skulker on the grid at (0,0).")
		return
	if grid.call("get_unit_position", &"brute") != Vector2i(1, 0):
		_fail("Expected Brute on the grid at (1,0).")
		return
	if grid.call("get_unit_position", &"shieldbearer") != Vector2i(2, 0):
		_fail("Expected Shieldbearer on the grid at (2,0).")
		return

	var valid_moves: Array = grid.call("get_empty_adjacent_cells_for", &"player")
	if not valid_moves.has(Vector2i(0, 2)) or not valid_moves.has(Vector2i(2, 2)) or not valid_moves.has(Vector2i(1, 1)):
		_fail("Expected all three opening adjacent movement targets.")
		return

	if not bool(grid.call("move_unit", &"player", Vector2i(0, 2))):
		_fail("Expected targeted movement to move the player to (0,2).")
		return

	if grid.call("get_unit_position", &"player") != Vector2i(0, 2):
		_fail("Player grid position did not update after targeted movement.")
		return

	print("TARGETED_CARD_ACTION_CHECK: PASS")
	get_tree().quit(0)


func _get_enemy_state(resolver: Node, enemy_id: StringName) -> Dictionary:
	var state: Dictionary = resolver.call("get_state")
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and StringName(enemy.get("id", &"")) == enemy_id:
			return enemy
	return {}


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
