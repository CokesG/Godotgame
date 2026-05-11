class_name RunManager
extends Node

signal log_requested(message: String)
signal state_changed(state: Dictionary)

const BALANCE_SIMULATOR_SCRIPT := preload("res://scripts/run/RunBalanceSimulator.gd")
const PLAYER_MAX_HP := 30
const VICTORY_HEAL := 3
const STARTER_DECK_PATHS := [
	"res://resources/cards/quick_slash.tres",
	"res://resources/cards/low_stab.tres",
	"res://resources/cards/guard_up.tres",
	"res://resources/cards/iron_vow.tres",
	"res://resources/cards/sidestep.tres",
	"res://resources/cards/hook_step.tres",
	"res://resources/cards/read_tell.tres",
	"res://resources/cards/false_opening.tres",
	"res://resources/cards/snare_card.tres",
	"res://resources/cards/blood_ritual.tres"
]
const CARD_REWARD_POOL := [
	"res://resources/cards/sure_cut.tres",
	"res://resources/cards/center_cut.tres",
	"res://resources/cards/house_edge.tres",
	"res://resources/cards/all_in_cut.tres",
	"res://resources/cards/bone_guard.tres",
	"res://resources/cards/black_shield.tres",
	"res://resources/cards/shadow_step.tres",
	"res://resources/cards/marked_card.tres",
	"res://resources/cards/tripwire.tres",
	"res://resources/cards/second_wind.tres",
	"res://resources/cards/hook_step.tres",
	"res://resources/cards/read_tell.tres",
	"res://resources/cards/false_opening.tres",
	"res://resources/cards/snare_card.tres",
	"res://resources/cards/blood_ritual.tres",
	"res://resources/cards/iron_vow.tres"
]
const RELIC_POOL := [
	"res://resources/relics/cracked_lens.tres",
	"res://resources/relics/loaded_dice.tres",
	"res://resources/relics/bone_chips.tres",
	"res://resources/relics/marked_deck.tres",
	"res://resources/relics/scarlet_ante.tres"
]
const RUN_NODES := [
	{
		"id": "opening_table",
		"name": "Opening Table",
		"kind": "combat",
		"enemy_paths": [
			"res://resources/enemies/skulker.tres",
			"res://resources/enemies/shieldbearer.tres"
		],
		"reward_tags": [&"movement", &"defense", &"read"]
	},
	{
		"id": "raised_stakes",
		"name": "Raised Stakes",
		"kind": "combat",
		"enemy_paths": [
			"res://resources/enemies/brute.tres",
			"res://resources/enemies/needle_eye.tres"
		],
		"reward_tags": [&"attack", &"guard", &"movement"]
	},
	{
		"id": "cursed_pair",
		"name": "Cursed Pair",
		"kind": "combat",
		"enemy_paths": [
			"res://resources/enemies/hexmonger.tres",
			"res://resources/enemies/shieldbearer.tres"
		],
		"reward_tags": [&"ritual", &"trap", &"read"]
	},
	{
		"id": "grave_dealer",
		"name": "Elite: Grave Dealer",
		"kind": "elite",
		"enemy_paths": [
			"res://resources/enemies/grave_dealer.tres",
			"res://resources/enemies/skulker.tres"
		],
		"reward_tags": [&"bluff", &"attack", &"nerve"]
	},
	{
		"id": "house_champion",
		"name": "Boss: House Champion",
		"kind": "boss",
		"enemy_paths": [
			"res://resources/enemies/house_champion.tres"
		],
		"reward_tags": []
	}
]

var current_node_index: int = 0
var player_current_hp: int = PLAYER_MAX_HP
var deck_paths: Array[String] = []
var relic_paths: Array[String] = []
var pending_card_reward_paths: Array[String] = []
var pending_relic_reward_paths: Array[String] = []
var run_outcome: String = "running"
var last_completed_node_name: String = ""
var combats_won: int = 0
var cards_claimed: int = 0
var relics_claimed: int = 0
var damage_taken_total: int = 0
var lowest_blood: int = PLAYER_MAX_HP


func reset_run() -> void:
	current_node_index = 0
	player_current_hp = PLAYER_MAX_HP
	deck_paths.clear()
	for path in STARTER_DECK_PATHS:
		deck_paths.append(String(path))
	relic_paths.clear()
	pending_card_reward_paths.clear()
	pending_relic_reward_paths.clear()
	run_outcome = "running"
	last_completed_node_name = ""
	combats_won = 0
	cards_claimed = 0
	relics_claimed = 0
	damage_taken_total = 0
	lowest_blood = PLAYER_MAX_HP
	log_requested.emit("Run reset: Gambler-Knight antes into a five-fight prototype path.")
	_emit_state()


func get_current_node() -> Dictionary:
	if current_node_index < 0 or current_node_index >= RUN_NODES.size():
		return {}
	return RUN_NODES[current_node_index].duplicate(true)


func get_current_enemy_paths() -> Array[String]:
	var node := get_current_node()
	var paths: Array[String] = []
	for path in node.get("enemy_paths", []):
		paths.append(String(path))
	return paths


func get_deck_paths() -> Array[String]:
	return deck_paths.duplicate()


func get_player_hp() -> int:
	return player_current_hp


func get_current_enemy_spawns() -> Array[Dictionary]:
	var paths := get_current_enemy_paths()
	var cells := _get_spawn_cells(paths.size())
	var spawns: Array[Dictionary] = []
	for index in range(paths.size()):
		var enemy: Resource = load(paths[index])
		if enemy == null:
			continue
		spawns.append({
			"id": StringName(enemy.get("id")),
			"cell": cells[index],
			"label": _get_resource_name(enemy)
		})
	return spawns


func mark_combat_victory(combat_state: Dictionary) -> void:
	if run_outcome != "running":
		return

	var node := get_current_node()
	last_completed_node_name = String(node.get("name", "Encounter"))
	var player: Dictionary = combat_state.get("player", {})
	var ending_hp := int(player.get("hp", player_current_hp))
	damage_taken_total += max(0, player_current_hp - ending_hp)
	lowest_blood = min(lowest_blood, ending_hp)
	combats_won += 1
	player_current_hp = clampi(ending_hp + VICTORY_HEAL, 1, PLAYER_MAX_HP)

	if String(node.get("kind", "")) == "boss":
		run_outcome = "victory"
		pending_card_reward_paths.clear()
		pending_relic_reward_paths.clear()
		log_requested.emit("Run victory: the House Champion folds.")
		_emit_state()
		return

	pending_card_reward_paths = _build_card_rewards(node)
	if String(node.get("kind", "")) == "elite":
		pending_relic_reward_paths = _build_relic_rewards()

	log_requested.emit("%s cleared. Blood recovers to %d/%d. Choose rewards." % [
		last_completed_node_name,
		player_current_hp,
		PLAYER_MAX_HP
	])
	_emit_state()


func mark_combat_defeat() -> void:
	run_outcome = "defeat"
	damage_taken_total += player_current_hp
	lowest_blood = 0
	player_current_hp = 0
	pending_card_reward_paths.clear()
	pending_relic_reward_paths.clear()
	log_requested.emit("Run defeat: the House takes the table.")
	_emit_state()


func claim_card_reward(index: int) -> String:
	if index < 0 or index >= pending_card_reward_paths.size():
		log_requested.emit("No card reward at slot %d." % index)
		return ""

	var card_path := pending_card_reward_paths[index]
	deck_paths.append(card_path)
	cards_claimed += 1
	pending_card_reward_paths.clear()
	var card: Resource = load(card_path)
	log_requested.emit("Added %s to the run deck." % _get_resource_name(card))
	_advance_if_rewards_clear()
	_emit_state()
	return card_path


func claim_relic_reward(index: int) -> String:
	if index < 0 or index >= pending_relic_reward_paths.size():
		log_requested.emit("No relic reward at slot %d." % index)
		return ""

	var relic_path := pending_relic_reward_paths[index]
	relic_paths.append(relic_path)
	relics_claimed += 1
	pending_relic_reward_paths.clear()
	var relic: Resource = load(relic_path)
	log_requested.emit("Claimed relic: %s." % _get_resource_name(relic))
	_advance_if_rewards_clear()
	_emit_state()
	return relic_path


func skip_rewards() -> void:
	if pending_card_reward_paths.is_empty() and pending_relic_reward_paths.is_empty():
		log_requested.emit("No pending rewards to skip.")
	else:
		log_requested.emit("Skipped pending rewards.")
	pending_card_reward_paths.clear()
	pending_relic_reward_paths.clear()
	_advance_if_rewards_clear()
	_emit_state()


func is_waiting_for_reward() -> bool:
	return not pending_card_reward_paths.is_empty() or not pending_relic_reward_paths.is_empty()


func can_start_current_node() -> bool:
	return run_outcome == "running" and not is_waiting_for_reward() and current_node_index < RUN_NODES.size()


func get_relic_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	for path in relic_paths:
		var relic: Resource = load(path)
		if relic == null:
			continue
		var relic_modifiers: Dictionary = relic.get("modifiers")
		for key in relic_modifiers.keys():
			modifiers[key] = modifiers.get(key, 0) + relic_modifiers[key]
	return modifiers


func get_balance_snapshot() -> Dictionary:
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	var node := get_current_node()
	var evaluation: Dictionary = simulator.call("evaluate_encounter", deck_paths, get_current_enemy_paths(), get_relic_modifiers(), player_current_hp)
	var fast_run: Dictionary = simulator.call("simulate_fast_run", RUN_NODES, deck_paths, get_relic_modifiers(), player_current_hp)
	var playtest_batch: Dictionary = simulator.call("simulate_playtest_batch", RUN_NODES, deck_paths, RELIC_POOL, get_relic_modifiers(), player_current_hp, 5)
	return {
		"current_node_name": String(node.get("name", "Complete")),
		"current_node_kind": String(node.get("kind", "")),
		"evaluation": evaluation,
		"fast_run": fast_run,
		"playtest_batch": playtest_batch,
		"reward_tuning": get_reward_tuning_report()
	}


func get_reward_tuning_report() -> Array[Dictionary]:
	var report: Array[Dictionary] = []
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	var deck_profile: Dictionary = simulator.call("build_deck_profile", deck_paths, get_relic_modifiers())
	var node := get_current_node()
	var reward_tags: Array = node.get("reward_tags", [])
	var rewards: Array[String] = pending_card_reward_paths if not pending_card_reward_paths.is_empty() else _build_card_rewards(node)

	for path in rewards:
		var card: Resource = load(path)
		if card == null:
			continue
		var details: Dictionary = simulator.call("score_card_reward_details", path, reward_tags, deck_profile, "balanced")
		report.append({
			"path": path,
			"name": _get_resource_name(card),
			"score": details.get("score", 0.0),
			"text": String(card.get("rules_text")),
			"explanation": details.get("explanation", "Solid reward option."),
			"reasons": details.get("reasons", [])
		})

	return report


func get_run_results() -> Dictionary:
	var title := "Run In Progress"
	if run_outcome == "victory":
		title = "Prototype Path Cleared"
	elif run_outcome == "defeat":
		title = "Run Lost"

	var grade := "Table Stakes"
	if run_outcome == "victory":
		if player_current_hp >= 20:
			grade = "Clean Read"
		elif player_current_hp >= 10:
			grade = "Hard-Fought Win"
		else:
			grade = "Barely Standing"
	elif run_outcome == "defeat":
		grade = "House Win"

	return {
		"title": title,
		"grade": grade,
		"outcome": run_outcome,
		"combats_won": combats_won,
		"total_combats": RUN_NODES.size(),
		"blood": player_current_hp,
		"max_blood": PLAYER_MAX_HP,
		"lowest_blood": lowest_blood,
		"damage_taken_total": damage_taken_total,
		"deck_size": deck_paths.size(),
		"cards_claimed": cards_claimed,
		"relics_claimed": relics_claimed,
		"relic_names": _get_relic_names(),
		"last_completed_node_name": last_completed_node_name
	}


func get_playtest_batch() -> Dictionary:
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	return simulator.call("simulate_playtest_batch", RUN_NODES, deck_paths, RELIC_POOL, get_relic_modifiers(), player_current_hp, 5)


func get_run_export_data() -> Dictionary:
	return {
		"version": 1,
		"run_results": get_run_results(),
		"balance_snapshot": get_balance_snapshot(),
		"playtest_batch": get_playtest_batch(),
		"deck": _describe_paths(deck_paths),
		"relics": _get_relic_names(),
		"current_node": get_current_node(),
		"pending_card_rewards": get_reward_tuning_report()
	}


func export_run_summary() -> String:
	var path := "user://dead_mans_ante_run_summary_%d.json" % Time.get_unix_time_from_system()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		log_requested.emit("Could not export run summary.")
		return ""

	file.store_string(JSON.stringify(get_run_export_data(), "\t"))
	file.close()
	var global_path := ProjectSettings.globalize_path(path)
	log_requested.emit("Run summary exported: %s" % global_path)
	return global_path


func get_state() -> Dictionary:
	var node := get_current_node()
	return {
		"current_node_index": current_node_index,
		"current_node_count": RUN_NODES.size(),
		"current_node": node,
		"current_node_name": String(node.get("name", "Complete")),
		"current_node_kind": String(node.get("kind", "")),
		"player_hp": player_current_hp,
		"player_max_hp": PLAYER_MAX_HP,
		"deck_size": deck_paths.size(),
		"relic_names": _get_relic_names(),
		"pending_card_rewards": _describe_card_rewards(pending_card_reward_paths),
		"pending_relic_rewards": _describe_paths(pending_relic_reward_paths),
		"balance_snapshot": get_balance_snapshot(),
		"run_results": get_run_results(),
		"combats_won": combats_won,
		"damage_taken_total": damage_taken_total,
		"waiting_for_reward": is_waiting_for_reward(),
		"run_outcome": run_outcome,
		"can_start_current_node": can_start_current_node()
	}


func _build_card_rewards(node: Dictionary) -> Array[String]:
	var reward_tags: Array = node.get("reward_tags", [])
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	var deck_profile: Dictionary = simulator.call("build_deck_profile", deck_paths, get_relic_modifiers())
	var scored_candidates: Array[Dictionary] = []
	for path in CARD_REWARD_POOL:
		if deck_paths.has(path):
			continue
		var card: Resource = load(path)
		if card == null:
			continue
		var details: Dictionary = simulator.call("score_card_reward_details", path, reward_tags, deck_profile, "balanced")
		var score: float = float(details.get("score", 0.0))
		if _resource_has_any_tag(card, reward_tags):
			score += 1.0
		scored_candidates.append({
			"path": path,
			"score": score,
			"name": _get_resource_name(card)
		})

	scored_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score := float(left.get("score", 0.0))
		var right_score := float(right.get("score", 0.0))
		if left_score == right_score:
			return String(left.get("name", "")) < String(right.get("name", ""))
		return left_score > right_score
	)

	var chosen: Array[String] = []
	for candidate in scored_candidates:
		if chosen.size() >= 3:
			break
		chosen.append(String(candidate.get("path", "")))

	return chosen


func _build_relic_rewards() -> Array[String]:
	var chosen: Array[String] = []
	for path in RELIC_POOL:
		if chosen.size() >= 2:
			break
		if not relic_paths.has(path):
			chosen.append(path)
	return chosen


func _advance_if_rewards_clear() -> void:
	if run_outcome != "running" or is_waiting_for_reward():
		return

	current_node_index += 1
	if current_node_index >= RUN_NODES.size():
		run_outcome = "victory"
		log_requested.emit("Run complete.")
	else:
		log_requested.emit("Next node: %s." % String(get_current_node().get("name", "Encounter")))


func _resource_has_any_tag(resource: Resource, tags_to_match: Array) -> bool:
	var resource_tags: Array = resource.get("tags")
	for tag in tags_to_match:
		if resource_tags.has(StringName(tag)):
			return true
	return false


func _get_spawn_cells(count: int) -> Array[Vector2i]:
	match count:
		1:
			return [Vector2i(1, 0)]
		2:
			return [Vector2i(0, 0), Vector2i(2, 0)]
		_:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]


func _get_relic_names() -> Array[String]:
	var names: Array[String] = []
	for path in relic_paths:
		var relic: Resource = load(path)
		if relic != null:
			names.append(_get_resource_name(relic))
	return names


func _describe_paths(paths: Array[String]) -> Array[Dictionary]:
	var descriptions: Array[Dictionary] = []
	for path in paths:
		var resource: Resource = load(path)
		if resource == null:
			continue
		descriptions.append({
			"path": path,
			"name": _get_resource_name(resource),
			"text": String(resource.get("rules_text"))
		})
	return descriptions


func _describe_card_rewards(paths: Array[String]) -> Array[Dictionary]:
	if paths.is_empty():
		return []

	var report := get_reward_tuning_report()
	var descriptions: Array[Dictionary] = []
	for path in paths:
		var found := false
		for entry in report:
			if String(entry.get("path", "")) == path:
				descriptions.append(entry)
				found = true
				break
		if found:
			continue

		var resource: Resource = load(path)
		if resource != null:
			descriptions.append({
				"path": path,
				"name": _get_resource_name(resource),
				"text": String(resource.get("rules_text")),
				"score": 0.0,
				"explanation": "Solid reward option.",
				"reasons": []
			})
	return descriptions


func _get_resource_name(resource: Resource) -> String:
	if resource == null:
		return "Unknown"
	if resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	return String(resource.get("display_name"))


func _emit_state() -> void:
	state_changed.emit(get_state())
