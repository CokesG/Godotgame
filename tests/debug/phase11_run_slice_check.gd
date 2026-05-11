extends Node

const CARD_POOL := [
	"res://resources/cards/quick_slash.tres",
	"res://resources/cards/low_stab.tres",
	"res://resources/cards/guard_up.tres",
	"res://resources/cards/iron_vow.tres",
	"res://resources/cards/sidestep.tres",
	"res://resources/cards/hook_step.tres",
	"res://resources/cards/read_tell.tres",
	"res://resources/cards/false_opening.tres",
	"res://resources/cards/snare_card.tres",
	"res://resources/cards/blood_ritual.tres",
	"res://resources/cards/sure_cut.tres",
	"res://resources/cards/center_cut.tres",
	"res://resources/cards/house_edge.tres",
	"res://resources/cards/all_in_cut.tres",
	"res://resources/cards/bone_guard.tres",
	"res://resources/cards/black_shield.tres",
	"res://resources/cards/shadow_step.tres",
	"res://resources/cards/marked_card.tres",
	"res://resources/cards/tripwire.tres",
	"res://resources/cards/second_wind.tres"
]
const NORMAL_ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres",
	"res://resources/enemies/needle_eye.tres",
	"res://resources/enemies/hexmonger.tres"
]
const ELITE_PATH := "res://resources/enemies/grave_dealer.tres"
const BOSS_PATH := "res://resources/enemies/house_champion.tres"

var failed: bool = false


func _ready() -> void:
	_verify_card_pool()
	if failed:
		return
	_verify_enemy_balance()
	if failed:
		return
	_verify_resolver_effects()
	if failed:
		return
	_verify_run_progression()
	if failed:
		return

	print("PHASE11_RUN_SLICE_CHECK: PASS")
	get_tree().quit(0)


func _verify_card_pool() -> void:
	var ids: Dictionary = {}
	var type_counts: Dictionary = {}
	for path in CARD_POOL:
		var card: Resource = load(path)
		if card == null:
			_fail("Missing card resource: %s" % path)
			return

		var card_id: StringName = card.get("id")
		if ids.has(card_id):
			_fail("Duplicate card id: %s" % String(card_id))
			return
		ids[card_id] = true

		var cost := int(card.get("cost"))
		if cost < 0 or cost > 2:
			_fail("%s has out-of-slice cost %d." % [_get_resource_name(card), cost])
			return

		var card_type := int(card.get("card_type"))
		type_counts[card_type] = int(type_counts.get(card_type, 0)) + 1

	if ids.size() != 20:
		_fail("Expected 20 card resources, found %d." % ids.size())
		return

	if int(type_counts.get(0, 0)) < 6:
		_fail("Expected at least 6 attack cards for boss pacing.")
		return
	if int(type_counts.get(1, 0)) < 4:
		_fail("Expected at least 4 defense cards for survivability.")
		return
	if int(type_counts.get(2, 0)) < 3:
		_fail("Expected at least 3 movement cards for positional play.")
		return


func _verify_enemy_balance() -> void:
	for path in NORMAL_ENEMY_PATHS:
		_verify_enemy(path, 14, 24, 8, 5.5)
	_verify_enemy(ELITE_PATH, 30, 36, 8, 6.0)
	_verify_enemy(BOSS_PATH, 44, 50, 9, 6.0)


func _verify_enemy(path: String, min_hp: int, max_hp: int, max_single_damage: int, max_weighted_damage: float) -> void:
	var enemy: Resource = load(path)
	if enemy == null:
		_fail("Missing enemy resource: %s" % path)
		return

	var hp := int(enemy.get("max_hp"))
	if hp < min_hp or hp > max_hp:
		_fail("%s HP %d is outside expected range %d-%d." % [_get_resource_name(enemy), hp, min_hp, max_hp])
		return

	var intents: Array = enemy.get("intents")
	if intents.size() < 3:
		_fail("%s needs at least three intent options." % _get_resource_name(enemy))
		return

	var total_weight := 0.0
	var weighted_damage := 0.0
	for intent in intents:
		if intent == null:
			_fail("%s has a null intent." % _get_resource_name(enemy))
			return
		var weight := float(intent.get("weight"))
		if weight <= 0.0:
			_fail("%s has non-positive intent weight." % _get_resource_name(intent))
			return
		total_weight += weight
		var payload: Dictionary = intent.get("payload")
		var damage := int(payload.get("damage", 0))
		if damage > max_single_damage:
			_fail("%s hits too hard for this slice: %d." % [_get_resource_name(intent), damage])
			return
		weighted_damage += weight * damage

	if total_weight <= 0.0:
		_fail("%s has no weighted intent total." % _get_resource_name(enemy))
		return

	var expected_damage := weighted_damage / total_weight
	if expected_damage > max_weighted_damage:
		_fail("%s weighted damage %.2f exceeds %.2f." % [_get_resource_name(enemy), expected_damage, max_weighted_damage])
		return


func _verify_resolver_effects() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	add_child(resolver)
	resolver.call("reset_combat", [BOSS_PATH], 24)

	var sure_cut: Resource = load("res://resources/cards/sure_cut.tres")
	resolver.call("apply_card_with_context", sure_cut, {"target_enemy_id": &"house_champion"})
	var boss := _get_enemy_state(resolver, &"house_champion")
	if int(boss.get("hp", -1)) != 43:
		_fail("Sure Cut should deal 5 to the House Champion.")
		return

	var center_cut: Resource = load("res://resources/cards/center_cut.tres")
	resolver.call("apply_card_with_context", center_cut, {
		"target_enemy_id": &"house_champion",
		"player_lane": 1
	})
	boss = _get_enemy_state(resolver, &"house_champion")
	if int(boss.get("hp", -1)) != 37:
		_fail("Center Cut should deal 6 from center lane.")
		return

	var house_edge: Resource = load("res://resources/cards/house_edge.tres")
	resolver.call("apply_card_with_context", house_edge, {"target_enemy_id": &"house_champion"})
	var player: Dictionary = resolver.call("get_state").get("player", {})
	if int(player.get("guard", -1)) != 3:
		_fail("House Edge should add 3 Guard.")
		return


func _verify_run_progression() -> void:
	var run: Node = load("res://scripts/run/RunManager.gd").new()
	add_child(run)
	run.call("reset_run")

	var state: Dictionary = run.call("get_state")
	if int(state.get("deck_size", 0)) != 10:
		_fail("Run should start with a 10-card starter deck.")
		return
	if int(state.get("current_node_count", 0)) != 5:
		_fail("Run should have five encounters including elite and boss.")
		return

	for expected_index in range(3):
		run.call("mark_combat_victory", {"player": {"hp": 20}})
		state = run.call("get_state")
		if int(state.get("pending_card_rewards", []).size()) != 3:
			_fail("Normal combat %d should offer three card rewards." % expected_index)
			return
		run.call("claim_card_reward", 0)
		state = run.call("get_state")
		if int(state.get("current_node_index", -1)) != expected_index + 1:
			_fail("Expected run to advance to node %d." % (expected_index + 1))
			return

	run.call("mark_combat_victory", {"player": {"hp": 18}})
	state = run.call("get_state")
	if int(state.get("pending_card_rewards", []).size()) != 3:
		_fail("Elite should offer card rewards.")
		return
	if int(state.get("pending_relic_rewards", []).size()) != 2:
		_fail("Elite should offer relic rewards.")
		return

	run.call("claim_card_reward", 0)
	state = run.call("get_state")
	if not bool(state.get("waiting_for_reward", false)):
		_fail("Run should still wait for relic after elite card pick.")
		return

	run.call("claim_relic_reward", 0)
	state = run.call("get_state")
	if int(state.get("current_node_index", -1)) != 4:
		_fail("Expected boss node after elite rewards.")
		return
	if int(state.get("relic_names", []).size()) != 1:
		_fail("Expected one claimed relic before the boss.")
		return

	run.call("mark_combat_victory", {"player": {"hp": 12}})
	state = run.call("get_state")
	if String(state.get("run_outcome", "")) != "victory":
		_fail("Boss victory should complete the run.")
		return


func _get_enemy_state(resolver: Node, enemy_id: StringName) -> Dictionary:
	var state: Dictionary = resolver.call("get_state")
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and StringName(enemy.get("id", &"")) == enemy_id:
			return enemy
	return {}


func _get_resource_name(resource: Resource) -> String:
	if resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	return String(resource.get("display_name"))


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	get_tree().quit(1)
