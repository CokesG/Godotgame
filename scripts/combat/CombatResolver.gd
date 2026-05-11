class_name CombatResolver
extends Node

signal log_requested(message: String)
signal state_changed(state: Dictionary)
signal combat_ended(outcome: String)

const PLAYER_ID := &"player"

@export var player_max_hp: int = 30

var player_state: Dictionary = {}
var enemy_states: Dictionary = {}
var enemy_order: Array[StringName] = []
var trap_cells: Array[Vector2i] = []
var traps_armed: int = 0
var outcome: String = "ongoing"


func reset_combat(enemy_paths: Array, player_hp: int = -1) -> void:
	var starting_hp := player_max_hp
	if player_hp > 0:
		starting_hp = clampi(player_hp, 1, player_max_hp)

	player_state = {
		"id": PLAYER_ID,
		"name": "Gambler-Knight",
		"max_hp": player_max_hp,
		"hp": starting_hp,
		"guard": 0
	}
	enemy_states.clear()
	enemy_order.clear()
	trap_cells.clear()
	traps_armed = 0
	outcome = "ongoing"

	for path in enemy_paths:
		var enemy: Resource = load(String(path))
		if enemy == null:
			log_requested.emit("Resolver could not load enemy: %s" % String(path))
			continue

		var enemy_id: StringName = enemy.get("id")
		enemy_order.append(enemy_id)
		enemy_states[enemy_id] = {
			"id": enemy_id,
			"name": _get_resource_name(enemy),
			"max_hp": int(enemy.get("max_hp")),
			"hp": int(enemy.get("max_hp")),
			"guard": 0,
			"alive": true
		}

	log_requested.emit("Combat resolver reset with %d enemies." % enemy_order.size())
	_emit_state()


func apply_card(card: Resource) -> void:
	apply_card_with_context(card, {})


func apply_card_with_context(card: Resource, context: Dictionary = {}) -> void:
	if _is_finished():
		log_requested.emit("Combat is already over.")
		return

	var card_id: StringName = card.get("id")
	var card_name := _get_resource_name(card)

	match card_id:
		&"quick_slash":
			_damage_targeted_enemy(4, card_name, context)
		&"low_stab":
			_damage_targeted_enemy(2, card_name, context)
		&"sure_cut":
			_damage_targeted_enemy(6, card_name, context)
		&"center_cut":
			var center_damage := 7 if int(context.get("player_lane", -1)) == 1 else 4
			_damage_targeted_enemy(center_damage, card_name, context)
		&"house_edge":
			_damage_targeted_enemy(4, card_name, context)
			_add_player_guard(3, card_name)
		&"all_in_cut":
			_damage_targeted_enemy(8, card_name, context)
		&"guard_up":
			_add_player_guard(5, card_name)
		&"iron_vow":
			_add_player_guard(8, card_name)
		&"bone_guard":
			_add_player_guard(5, card_name)
		&"black_shield":
			_add_player_guard(11, card_name)
		&"sidestep":
			log_requested.emit("%s is a movement card. Grid movement remains player-click driven in this prototype." % card_name)
		&"hook_step":
			log_requested.emit("%s prepares a follow-up. Phase 6 logs setup but does not chain cards yet." % card_name)
		&"shadow_step":
			_add_player_guard(2, card_name)
		&"read_tell":
			log_requested.emit("%s sharpens the read on %s." % [card_name, _get_context_enemy_name(context)])
		&"marked_card":
			_damage_targeted_enemy(2, card_name, context)
			log_requested.emit("%s marks the enemy for a cleaner call." % card_name)
		&"false_opening":
			log_requested.emit("%s creates bait. Use Commit/Call/Raise to cash it in." % card_name)
		&"snare_card":
			_arm_trap(card_name, context)
		&"tripwire":
			_arm_trap(card_name, context)
		&"blood_ritual":
			log_requested.emit("%s feeds the wager engine. Nerve remains tracked by BluffSystem." % card_name)
		&"second_wind":
			_add_player_guard(5, card_name)
		_:
			log_requested.emit("%s has no resolver effect yet." % card_name)

	_check_combat_end()
	_emit_state()


func apply_revealed_intents(revealed_intents: Array) -> void:
	apply_revealed_intents_with_context(revealed_intents, {})


func apply_revealed_intents_with_context(revealed_intents: Array, context: Dictionary = {}) -> void:
	if _is_finished():
		return

	for entry in revealed_intents:
		var enemy_id: StringName = StringName(entry.get("enemy_id", &""))
		if not _enemy_is_alive(enemy_id):
			continue

		var payload: Dictionary = entry.get("payload", {})
		var enemy_name := String(entry.get("enemy_name", "Enemy"))
		var intent_name := String(entry.get("intent_name", "Intent"))
		var target_lane: int = int(entry.get("target_lane", -1))

		_trigger_trap_for_intent(enemy_id, enemy_name, intent_name, target_lane)
		if not _enemy_is_alive(enemy_id):
			_check_combat_end()
			_emit_state()
			continue

		if payload.has("damage"):
			_resolve_positional_damage(enemy_id, enemy_name, StringName(entry.get("intent_id", &"")), intent_name, int(payload.get("damage", 0)), target_lane, context)
		elif payload.has("guard"):
			_add_enemy_guard(enemy_id, int(payload.get("guard", 0)), "%s's %s" % [enemy_name, intent_name])
		elif payload.has("rage"):
			log_requested.emit("%s gains Rage. Future scaling is not implemented yet." % enemy_name)
		elif payload.has("feint"):
			log_requested.emit("%s feints. Commit/Call resolution handled the mind game." % enemy_name)
		elif payload.has("move"):
			log_requested.emit("%s repositions. Enemy movement will become grid-driven later." % enemy_name)
		elif payload.has("suspicion"):
			log_requested.emit("%s raises Suspicion. Suspicion is reserved for a later pass." % enemy_name)
		else:
			log_requested.emit("%s resolves %s with no Phase 6 payload." % [enemy_name, intent_name])

		_check_combat_end()
		_emit_state()


func get_state() -> Dictionary:
	return {
		"player": player_state.duplicate(),
		"enemies": _get_enemy_list(),
		"traps_armed": traps_armed,
		"trap_cells": trap_cells.duplicate(),
		"outcome": outcome
	}


func get_alive_enemy_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for enemy_id in enemy_order:
		if _enemy_is_alive(enemy_id):
			var enemy: Dictionary = enemy_states[enemy_id]
			targets.append({
				"id": enemy_id,
				"name": enemy.get("name", "Enemy"),
				"hp": enemy.get("hp", 0),
				"max_hp": enemy.get("max_hp", 0),
				"guard": enemy.get("guard", 0)
			})
	return targets


func has_living_enemy(enemy_id: StringName) -> bool:
	return _enemy_is_alive(enemy_id)


func add_player_guard(amount: int, source: String = "Relic") -> void:
	if _is_finished():
		return
	_add_player_guard(max(0, amount), source)
	_emit_state()


func _damage_first_alive_enemy(amount: int, source: String) -> void:
	var enemy_id := _get_first_alive_enemy_id()
	if enemy_id.is_empty():
		log_requested.emit("%s has no living enemy target." % source)
		return

	_damage_enemy(enemy_id, amount, source)


func _damage_targeted_enemy(amount: int, source: String, context: Dictionary) -> void:
	var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
	if target_enemy_id.is_empty() or not _enemy_is_alive(target_enemy_id):
		if not target_enemy_id.is_empty():
			log_requested.emit("%s cannot target %s, falling back to the first living enemy." % [
				source,
				String(context.get("target_enemy_name", target_enemy_id))
			])
		_damage_first_alive_enemy(amount, source)
		return

	_damage_enemy(target_enemy_id, amount, source)


func _damage_enemy(enemy_id: StringName, amount: int, source: String) -> void:
	var enemy: Dictionary = enemy_states[enemy_id]
	var guard: int = int(enemy.get("guard", 0))
	var damage_after_guard: int = max(0, amount - guard)
	enemy["guard"] = max(0, guard - amount)
	enemy["hp"] = max(0, int(enemy.get("hp", 0)) - damage_after_guard)

	log_requested.emit("%s deals %d to %s (%d blocked)." % [
		source,
		damage_after_guard,
		enemy.get("name", "Enemy"),
		amount - damage_after_guard
	])

	if int(enemy.get("hp", 0)) <= 0:
		enemy["alive"] = false
		log_requested.emit("%s is defeated." % enemy.get("name", "Enemy"))

	enemy_states[enemy_id] = enemy


func _arm_trap(source: String, context: Dictionary) -> void:
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	if target_cell.x < 0:
		trap_cells.append(target_cell)
		_sync_trap_count()
		log_requested.emit("%s arms a loose trap. Traps armed: %d." % [source, traps_armed])
		return

	trap_cells.append(target_cell)
	_sync_trap_count()
	log_requested.emit("%s arms a trap at %s. Traps armed: %d." % [
		source,
		String(context.get("target_cell_label", "(%d,%d)" % [target_cell.x, target_cell.y])),
		traps_armed
	])


func _trigger_trap_for_intent(enemy_id: StringName, enemy_name: String, intent_name: String, target_lane: int) -> void:
	if target_lane < 0:
		return

	var trap_index: int = _get_trap_index_for_lane(target_lane)
	if trap_index < 0:
		return

	var trap_cell: Vector2i = trap_cells[trap_index]
	trap_cells.remove_at(trap_index)
	_sync_trap_count()
	log_requested.emit("Snare trap at %s catches %s's %s in lane %s." % [
		"(%d,%d)" % [trap_cell.x, trap_cell.y],
		enemy_name,
		intent_name,
		_get_lane_label(target_lane)
	])
	_damage_enemy(enemy_id, 3, "Snare trap")


func _get_trap_index_for_lane(target_lane: int) -> int:
	for index in range(trap_cells.size()):
		if trap_cells[index].x == target_lane:
			return index
	return -1


func _sync_trap_count() -> void:
	traps_armed = trap_cells.size()


func _resolve_positional_damage(enemy_id: StringName, enemy_name: String, intent_id: StringName, intent_name: String, amount: int, target_lane: int, context: Dictionary) -> void:
	if amount <= 0:
		log_requested.emit("%s's %s deals no damage." % [enemy_name, intent_name])
		return

	if _lane_attack_misses(target_lane, context):
		log_requested.emit("%s's %s misses lane %s: player is in lane %s." % [
			enemy_name,
			intent_name,
			_get_lane_label(target_lane),
			_get_lane_label(_get_player_lane(context))
		])
		return

	var mitigated_amount: int = amount
	var call_mitigation: int = _get_call_mitigation(enemy_id, intent_id, context)
	if call_mitigation > 0:
		mitigated_amount = max(0, amount - call_mitigation)
		log_requested.emit("Called read reduces incoming damage by %d." % min(amount, call_mitigation))

	if target_lane >= 0:
		log_requested.emit("%s's %s hits lane %s for %d damage." % [
			enemy_name,
			intent_name,
			_get_lane_label(target_lane),
			mitigated_amount
		])
	else:
		log_requested.emit("%s's %s tracks the player for %d damage." % [
			enemy_name,
			intent_name,
			mitigated_amount
		])

	_damage_player(mitigated_amount, "%s's %s" % [enemy_name, intent_name])


func _lane_attack_misses(target_lane: int, context: Dictionary) -> bool:
	if target_lane < 0:
		return false
	if not context.has("player_lane"):
		return false
	return _get_player_lane(context) != target_lane


func _get_player_lane(context: Dictionary) -> int:
	return int(context.get("player_lane", -1))


func _get_call_mitigation(enemy_id: StringName, intent_id: StringName, context: Dictionary) -> int:
	var bluff_state: Dictionary = context.get("bluff_state", {})
	if not bool(bluff_state.get("last_call_correct", context.get("last_call_correct", false))):
		return 0
	if StringName(bluff_state.get("last_called_enemy_id", context.get("last_called_enemy_id", &""))) != enemy_id:
		return 0
	if StringName(bluff_state.get("last_called_intent_id", context.get("last_called_intent_id", &""))) != intent_id:
		return 0
	return 2 + int(bluff_state.get("last_resolved_wager", context.get("last_resolved_wager", 0)))


func _get_lane_label(lane: int) -> String:
	match lane:
		0:
			return "Left"
		1:
			return "Center"
		2:
			return "Right"
		_:
			return "Tracking"


func _damage_player(amount: int, source: String) -> void:
	var guard: int = int(player_state.get("guard", 0))
	var damage_after_guard: int = max(0, amount - guard)
	player_state["guard"] = max(0, guard - amount)
	player_state["hp"] = max(0, int(player_state.get("hp", 0)) - damage_after_guard)

	log_requested.emit("%s deals %d to the Gambler-Knight (%d blocked)." % [
		source,
		damage_after_guard,
		amount - damage_after_guard
	])

	if int(player_state.get("hp", 0)) <= 0:
		outcome = "defeat"
		combat_ended.emit(outcome)
		log_requested.emit("Defeat: the Gambler-Knight falls.")


func _add_player_guard(amount: int, source: String) -> void:
	player_state["guard"] = int(player_state.get("guard", 0)) + amount
	log_requested.emit("%s grants %d Guard." % [source, amount])


func _add_enemy_guard(enemy_id: StringName, amount: int, source: String) -> void:
	var enemy: Dictionary = enemy_states[enemy_id]
	enemy["guard"] = int(enemy.get("guard", 0)) + amount
	enemy_states[enemy_id] = enemy
	log_requested.emit("%s grants %d Guard to %s." % [source, amount, enemy.get("name", "Enemy")])


func _check_combat_end() -> void:
	if outcome != "ongoing":
		return

	if _get_first_alive_enemy_id().is_empty():
		outcome = "victory"
		combat_ended.emit(outcome)
		log_requested.emit("Victory: all enemies are defeated.")


func _get_first_alive_enemy_id() -> StringName:
	for enemy_id in enemy_order:
		if _enemy_is_alive(enemy_id):
			return enemy_id
	return &""


func _enemy_is_alive(enemy_id: StringName) -> bool:
	if not enemy_states.has(enemy_id):
		return false
	return bool(enemy_states[enemy_id].get("alive", false))


func _get_enemy_list() -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	for enemy_id in enemy_order:
		enemies.append(enemy_states[enemy_id].duplicate())
	return enemies


func _get_resource_name(resource: Resource) -> String:
	if resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	return String(resource.get("display_name"))


func _get_context_enemy_name(context: Dictionary) -> String:
	var target_enemy_name: String = String(context.get("target_enemy_name", "the selected enemy"))
	if target_enemy_name.is_empty():
		return "the selected enemy"
	return target_enemy_name


func _is_finished() -> bool:
	return outcome != "ongoing"


func _emit_state() -> void:
	state_changed.emit(get_state())
