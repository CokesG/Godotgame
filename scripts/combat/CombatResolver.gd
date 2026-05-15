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
		"guard": 0,
		"suspicion": 0,
		"bait_lane": -1
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
			"rage": 0,
			"last_move_cell": Vector2i(-1, -1),
			"alive": true,
			"sprite_path": String(enemy.get("sprite_path"))
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
			_apply_card_damage(4, card_name, context)
		&"low_stab":
			_apply_card_damage(2, card_name, context)
		&"sure_cut":
			_apply_card_damage(6, card_name, context)
		&"center_cut":
			var center_damage := 7 if int(context.get("player_lane", -1)) == 1 else 4
			_apply_card_damage(center_damage, card_name, context)
		&"house_edge":
			_apply_card_damage(4, card_name, context)
			_apply_card_guard(3, card_name, context)
		&"all_in_cut":
			_apply_card_damage(8, card_name, context)
		&"guard_up":
			_apply_card_guard(5, card_name, context)
		&"iron_vow":
			_apply_card_guard(8, card_name, context)
		&"bone_guard":
			_apply_card_guard(5, card_name, context)
		&"black_shield":
			_apply_card_guard(11, card_name, context)
		&"sidestep":
			log_requested.emit("%s is a movement card. Grid movement remains player-click driven in this prototype." % card_name)
		&"hook_step":
			log_requested.emit("%s hooks the footwork. Move it first, then the follow-up strike can cash in." % card_name)
		&"shadow_step":
			_apply_card_guard(2, card_name, context)
		&"read_tell":
			log_requested.emit("%s sharpens the read on %s." % [card_name, _get_context_enemy_name(context)])
		&"marked_card":
			_apply_card_damage(2, card_name, context)
			log_requested.emit("%s marks the enemy for a cleaner call." % card_name)
		&"false_opening":
			_set_player_bait_lane(int(context.get("player_lane", -1)), card_name)
		&"snare_card":
			_arm_trap(card_name, context)
		&"tripwire":
			_arm_trap(card_name, context)
		&"blood_ritual":
			log_requested.emit("%s feeds the wager engine and steadies the table read." % card_name)
		&"second_wind":
			_apply_card_guard(5, card_name, context)
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

		var effective_target_lane := _get_effective_target_lane(target_lane)
		_trigger_trap_for_intent(enemy_id, enemy_name, intent_name, effective_target_lane)
		if not _enemy_is_alive(enemy_id):
			_check_combat_end()
			_emit_state()
			continue

		if payload.has("damage"):
			_resolve_positional_damage(enemy_id, enemy_name, StringName(entry.get("intent_id", &"")), intent_name, int(payload.get("damage", 0)), target_lane, effective_target_lane, context)
		elif payload.has("guard"):
			_add_enemy_guard(enemy_id, int(payload.get("guard", 0)), "%s's %s" % [enemy_name, intent_name])
		elif payload.has("rage"):
			_add_enemy_rage(enemy_id, int(payload.get("rage", 0)), "%s's %s" % [enemy_name, intent_name])
		elif payload.has("feint"):
			log_requested.emit("%s feints. Commit/Call resolution handled the mind game." % enemy_name)
		elif payload.has("move"):
			_record_enemy_reposition(enemy_id, enemy_name, payload, context)
		elif payload.has("suspicion"):
			_add_player_suspicion(int(payload.get("suspicion", 0)), "%s's %s" % [enemy_name, intent_name])
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
				"guard": enemy.get("guard", 0),
				"rage": enemy.get("rage", 0),
				"sprite_path": String(enemy.get("sprite_path", ""))
			})
	return targets


func apply_follow_up_damage(amount: int, source: String, context: Dictionary = {}) -> void:
	if _is_finished():
		return
	_apply_card_damage(max(0, amount), source, context)
	_check_combat_end()
	_emit_state()


func has_living_enemy(enemy_id: StringName) -> bool:
	return _enemy_is_alive(enemy_id)


func add_player_guard(amount: int, source: String = "Relic") -> void:
	if _is_finished():
		return
	_add_player_guard(max(0, amount), source)
	_emit_state()


func _apply_card_damage(amount: int, source: String, context: Dictionary) -> void:
	var upgrade_bonus := maxi(0, int(context.get("upgrade_damage_bonus", 0)))
	var scaled_amount := _scale_card_amount(amount + upgrade_bonus, source, context)
	scaled_amount = _apply_player_map_bonus(scaled_amount, "card_damage_bonus", "damage", source, context)
	if scaled_amount <= 0:
		return
	if upgrade_bonus > 0:
		log_requested.emit("%s armory upgrade adds +%d damage." % [source, upgrade_bonus])
	_damage_targeted_enemy(scaled_amount, source, context)


func _apply_card_guard(amount: int, source: String, context: Dictionary) -> void:
	var upgrade_bonus := maxi(0, int(context.get("upgrade_guard_bonus", 0)))
	var scaled_amount := _scale_card_amount(amount + upgrade_bonus, source, context)
	scaled_amount = _apply_player_map_bonus(scaled_amount, "guard_bonus", "Guard", source, context)
	if scaled_amount <= 0:
		return
	if upgrade_bonus > 0:
		log_requested.emit("%s armory upgrade adds +%d Guard." % [source, upgrade_bonus])
	_add_player_guard(scaled_amount, source)


func _scale_card_amount(amount: int, source: String, context: Dictionary) -> int:
	if amount <= 0:
		return 0
	if not context.has("action_beat_result"):
		return amount

	var result: String = String(context.get("action_beat_result", "hit"))
	var multiplier: float = float(context.get("action_multiplier", 1.0))
	if result == "miss" or multiplier <= 0.0:
		log_requested.emit("%s misses the action beat. No card effect." % source)
		return 0

	var scaled: int = max(1, int(round(float(amount) * multiplier)))
	if scaled != amount:
		log_requested.emit("%s action beat %s scales %d -> %d." % [
			source,
			String(context.get("action_beat_label", result)).to_lower(),
			amount,
			scaled
		])
	return scaled


func _apply_player_map_bonus(amount: int, key: String, label: String, source: String, context: Dictionary) -> int:
	if amount <= 0:
		return amount
	var feature := _get_player_map_feature(context)
	var bonus: int = int(feature.get(key, 0))
	if bonus <= 0:
		return amount
	var feature_label := String(feature.get("label", "map position"))
	log_requested.emit("%s uses %s for +%d %s." % [source, feature_label, bonus, label])
	return amount + bonus


func _get_player_map_feature(context: Dictionary) -> Dictionary:
	var map_context_value: Variant = context.get("map_context", {})
	if typeof(map_context_value) != TYPE_DICTIONARY:
		return {}
	var map_context: Dictionary = Dictionary(map_context_value)
	var feature_value: Variant = map_context.get("player_feature", {})
	if typeof(feature_value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(feature_value)


func _get_player_map_mitigation(context: Dictionary) -> int:
	var feature := _get_player_map_feature(context)
	return max(0, int(feature.get("incoming_damage_mitigation", 0)))


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


func _set_player_bait_lane(lane: int, source: String) -> void:
	if lane < 0:
		log_requested.emit("%s creates bait, but no player lane was readable." % source)
		return

	player_state["bait_lane"] = lane
	log_requested.emit("%s baits the next lane attack toward %s." % [
		source,
		_get_lane_label(lane)
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


func _get_effective_target_lane(target_lane: int) -> int:
	if target_lane < 0:
		return target_lane
	var bait_lane: int = int(player_state.get("bait_lane", -1))
	if bait_lane >= 0:
		return bait_lane
	return target_lane


func _sync_trap_count() -> void:
	traps_armed = trap_cells.size()


func _resolve_positional_damage(enemy_id: StringName, enemy_name: String, intent_id: StringName, intent_name: String, amount: int, original_target_lane: int, target_lane: int, context: Dictionary) -> void:
	if amount <= 0:
		log_requested.emit("%s's %s deals no damage." % [enemy_name, intent_name])
		return

	if target_lane != original_target_lane:
		log_requested.emit("False Opening pulls %s's %s from %s toward %s." % [
			enemy_name,
			intent_name,
			_get_lane_label(original_target_lane),
			_get_lane_label(target_lane)
		])
		player_state["bait_lane"] = -1

	if _lane_attack_misses(target_lane, context):
		log_requested.emit("%s's %s misses lane %s: player is in lane %s." % [
			enemy_name,
			intent_name,
			_get_lane_label(target_lane),
			_get_lane_label(_get_player_lane(context))
		])
		return

	var rage_bonus: int = _consume_enemy_rage(enemy_id)
	var charged_amount: int = amount + rage_bonus
	if rage_bonus > 0:
		log_requested.emit("%s cashes in Rage for +%d damage." % [enemy_name, rage_bonus])

	var mitigated_amount: int = charged_amount
	var call_mitigation: int = _get_call_mitigation(enemy_id, intent_id, context)
	if call_mitigation > 0:
		mitigated_amount = max(0, charged_amount - call_mitigation)
		log_requested.emit("Called read reduces incoming damage by %d." % min(charged_amount, call_mitigation))

	var map_mitigation := _get_player_map_mitigation(context)
	if map_mitigation > 0 and mitigated_amount > 0:
		var blocked_by_map: int = min(map_mitigation, mitigated_amount)
		mitigated_amount = max(0, mitigated_amount - map_mitigation)
		var feature := _get_player_map_feature(context)
		log_requested.emit("%s cover reduces incoming damage by %d." % [
			String(feature.get("label", "Arena")),
			blocked_by_map
		])

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
	var mitigation := 2 + int(bluff_state.get("last_resolved_wager", context.get("last_resolved_wager", 0)))
	var suspicion: int = int(player_state.get("suspicion", 0))
	if suspicion > 0 and mitigation > 0:
		var suspicion_tax: int = min(suspicion, mitigation)
		mitigation -= suspicion_tax
		player_state["suspicion"] = max(0, suspicion - suspicion_tax)
		log_requested.emit("Suspicion cuts call mitigation by %d." % suspicion_tax)
	return mitigation


func _add_enemy_rage(enemy_id: StringName, amount: int, source: String) -> void:
	if amount <= 0 or not enemy_states.has(enemy_id):
		return
	var enemy: Dictionary = enemy_states[enemy_id]
	enemy["rage"] = int(enemy.get("rage", 0)) + amount
	enemy_states[enemy_id] = enemy
	log_requested.emit("%s adds %d Rage to %s." % [
		source,
		amount,
		enemy.get("name", "Enemy")
	])


func _consume_enemy_rage(enemy_id: StringName) -> int:
	if not enemy_states.has(enemy_id):
		return 0
	var enemy: Dictionary = enemy_states[enemy_id]
	var rage: int = int(enemy.get("rage", 0))
	if rage <= 0:
		return 0
	enemy["rage"] = 0
	enemy_states[enemy_id] = enemy
	return rage * 2


func _add_player_suspicion(amount: int, source: String) -> void:
	if amount <= 0:
		return
	player_state["suspicion"] = int(player_state.get("suspicion", 0)) + amount
	log_requested.emit("%s raises Suspicion to %d." % [
		source,
		int(player_state.get("suspicion", 0))
	])


func _record_enemy_reposition(enemy_id: StringName, enemy_name: String, payload: Dictionary, context: Dictionary) -> void:
	var move_steps: int = max(1, int(payload.get("move", 1)))
	var next_cell := _get_reposition_cell(enemy_id, context)
	if enemy_states.has(enemy_id):
		var enemy: Dictionary = enemy_states[enemy_id]
		enemy["last_move_cell"] = next_cell
		enemy_states[enemy_id] = enemy
	if next_cell.x >= 0:
		log_requested.emit("%s repositions %d step to (%d,%d)." % [
			enemy_name,
			move_steps,
			next_cell.x,
			next_cell.y
		])
	else:
		log_requested.emit("%s repositions, but no open cell was available in the resolver snapshot." % enemy_name)


func _get_reposition_cell(enemy_id: StringName, context: Dictionary) -> Vector2i:
	var unit_positions: Dictionary = context.get("unit_positions", {})
	if not unit_positions.has(enemy_id):
		return Vector2i(-1, -1)

	var origin := _get_position_cell(unit_positions[enemy_id])
	if origin.x < 0:
		return Vector2i(-1, -1)
	var occupied := {}
	for value in unit_positions.values():
		var occupied_cell := _get_position_cell(value)
		if occupied_cell.x >= 0:
			occupied[occupied_cell] = true

	var offsets := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	for offset: Vector2i in offsets:
		var candidate: Vector2i = origin + offset
		if candidate.x < 0 or candidate.x > 2 or candidate.y < 0 or candidate.y > 2:
			continue
		if occupied.has(candidate):
			continue
		return candidate
	return Vector2i(-1, -1)


func _get_position_cell(value: Variant) -> Vector2i:
	if typeof(value) == TYPE_VECTOR2I:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var data: Dictionary = value
		var cell: Variant = data.get("cell", Vector2i(-1, -1))
		if typeof(cell) == TYPE_VECTOR2I:
			return cell
	return Vector2i(-1, -1)


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
	if not Engine.is_editor_hint() and resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	var display_name := String(resource.get("display_name"))
	if not display_name.is_empty():
		return display_name
	return String(resource.get("id"))


func _get_context_enemy_name(context: Dictionary) -> String:
	var target_enemy_name: String = String(context.get("target_enemy_name", "the selected enemy"))
	if target_enemy_name.is_empty():
		return "the selected enemy"
	return target_enemy_name


func _is_finished() -> bool:
	return outcome != "ongoing"


func _emit_state() -> void:
	state_changed.emit(get_state())
