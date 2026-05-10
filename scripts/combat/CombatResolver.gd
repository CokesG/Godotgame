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
var traps_armed: int = 0
var outcome: String = "ongoing"


func reset_combat(enemy_paths: Array) -> void:
	player_state = {
		"id": PLAYER_ID,
		"name": "Gambler-Knight",
		"max_hp": player_max_hp,
		"hp": player_max_hp,
		"guard": 0
	}
	enemy_states.clear()
	enemy_order.clear()
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
		&"guard_up":
			_add_player_guard(5, card_name)
		&"iron_vow":
			_add_player_guard(8, card_name)
		&"sidestep":
			log_requested.emit("%s is a movement card. Grid movement remains player-click driven in this prototype." % card_name)
		&"hook_step":
			log_requested.emit("%s prepares a follow-up. Phase 6 logs setup but does not chain cards yet." % card_name)
		&"read_tell":
			log_requested.emit("%s sharpens the read on %s." % [card_name, _get_context_enemy_name(context)])
		&"false_opening":
			log_requested.emit("%s creates bait. Use Commit/Call/Raise to cash it in." % card_name)
		&"snare_card":
			traps_armed += 1
			log_requested.emit("%s arms a trap at %s. Traps armed: %d." % [
				card_name,
				String(context.get("target_cell_label", "the selected cell")),
				traps_armed
			])
		&"blood_ritual":
			log_requested.emit("%s feeds the wager engine. Nerve remains tracked by BluffSystem." % card_name)
		_:
			log_requested.emit("%s has no resolver effect yet." % card_name)

	_check_combat_end()
	_emit_state()


func apply_revealed_intents(revealed_intents: Array) -> void:
	if _is_finished():
		return

	for entry in revealed_intents:
		var enemy_id: StringName = StringName(entry.get("enemy_id", &""))
		if not _enemy_is_alive(enemy_id):
			continue

		var payload: Dictionary = entry.get("payload", {})
		var enemy_name := String(entry.get("enemy_name", "Enemy"))
		var intent_name := String(entry.get("intent_name", "Intent"))

		if payload.has("damage"):
			_damage_player(int(payload.get("damage", 0)), "%s's %s" % [enemy_name, intent_name])
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
