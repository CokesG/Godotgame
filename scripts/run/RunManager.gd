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
		"encounter_intro": "A cramped first table where a Skulker tests your lanes while a Shieldbearer tries to drag the tempo down.",
		"table_modifier": {
			"id": "house_rules",
			"name": "House Rules",
			"summary": "Opening table starts you with 2 Guard so the first read is forgiving.",
			"modifiers": {"starting_guard": 2}
		},
		"reward_stakes": "Movement, defense, and read cards are favored so the starter deck gains a cleaner table plan.",
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
		"encounter_intro": "The Brute forces raw damage checks while Needle-Eye punishes lazy lane choices from the back rail.",
		"table_modifier": {
			"id": "high_ante",
			"name": "High Ante",
			"summary": "You get +1 max Energy at this table, but the enemy pair is built to cash in fast.",
			"modifiers": {"max_energy_bonus": 1}
		},
		"reward_stakes": "Attack, Guard, and movement rewards are weighted because this table asks for faster pressure.",
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
		"encounter_intro": "Hexmonger muddles your calls while Shieldbearer keeps the curse alive behind a wall of Guard.",
		"table_modifier": {
			"id": "hexed_felt",
			"name": "Hexed Felt",
			"summary": "Start with -1 Nerve. Reads, traps, and ritual cards matter more here.",
			"modifiers": {"starting_nerve_bonus": -1}
		},
		"reward_stakes": "Ritual, trap, and read rewards are favored to answer the curse instead of simply racing it.",
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
		"encounter_intro": "The Grave Dealer hides the real threat behind Skulker pressure and pays out a relic if you survive.",
		"table_modifier": {
			"id": "marked_deal",
			"name": "Marked Deal",
			"summary": "Start with +1 Nerve. Correct calls can swing the elite before the relic offer.",
			"modifiers": {"starting_nerve_bonus": 1}
		},
		"reward_stakes": "Bluff, attack, and Nerve rewards are favored, and this elite also offers a relic.",
		"reward_tags": [&"bluff", &"attack", &"nerve"]
	},
	{
		"id": "house_champion",
		"name": "Boss: House Champion",
		"kind": "boss",
		"enemy_paths": [
			"res://resources/enemies/house_champion.tres"
		],
		"encounter_intro": "The House Champion is the final single-opponent read: fewer bodies, bigger punishment, no post-fight reward.",
		"table_modifier": {
			"id": "final_hand",
			"name": "Final Hand",
			"summary": "Draw +1 card and start with 3 Guard. This is the last table.",
			"modifiers": {"hand_target_bonus": 1, "starting_guard": 3}
		},
		"reward_stakes": "The payout is the run result. Win here to clear the prototype path.",
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


func get_current_enemy_names() -> Array[String]:
	return _get_enemy_names_from_paths(get_current_enemy_paths())


func get_next_node_name_after_reward() -> String:
	var next_index := current_node_index + 1
	if next_index < 0 or next_index >= RUN_NODES.size():
		return "run results"
	var node: Dictionary = RUN_NODES[next_index]
	return String(node.get("name", "Next Table"))


func get_current_encounter_intro() -> String:
	var node: Dictionary = get_current_node()
	return String(node.get("encounter_intro", "Read the enemies before the table opens."))


func get_current_table_modifier() -> Dictionary:
	var node: Dictionary = get_current_node()
	var modifier_value: Variant = node.get("table_modifier", {})
	if typeof(modifier_value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(modifier_value).duplicate(true)


func get_table_modifiers() -> Dictionary:
	var table_modifier: Dictionary = get_current_table_modifier()
	var modifiers_value: Variant = table_modifier.get("modifiers", {})
	if typeof(modifiers_value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(modifiers_value).duplicate(true)


func get_current_reward_stakes() -> String:
	var node: Dictionary = get_current_node()
	return String(node.get("reward_stakes", "Clear the table to improve the run."))


func get_current_reward_tag_names() -> Array[String]:
	var node: Dictionary = get_current_node()
	return _format_reward_tags(node.get("reward_tags", []))


func get_run_path() -> Array[Dictionary]:
	var path: Array[Dictionary] = []
	for index in range(RUN_NODES.size()):
		var node: Dictionary = RUN_NODES[index]
		var status: String = _get_run_path_status(index)
		var modifier: Dictionary = _get_node_table_modifier(node)
		path.append({
			"index": index,
			"table_number": index + 1,
			"name": String(node.get("name", "Table")),
			"kind": String(node.get("kind", "combat")),
			"enemy_names": _get_enemy_names_from_paths(node.get("enemy_paths", [])),
			"enemy_cards": _get_enemy_cards_from_paths(node.get("enemy_paths", [])),
			"encounter_intro": String(node.get("encounter_intro", "Read the table before combat starts.")),
			"table_modifier_name": String(modifier.get("name", "House Rules")),
			"table_modifier_summary": String(modifier.get("summary", "No special rule is active.")),
			"reward_stakes": String(node.get("reward_stakes", "Clear the table to improve the run.")),
			"reward_tag_names": _format_reward_tags(node.get("reward_tags", [])),
			"status": status,
			"status_label": _get_run_path_status_label(status)
		})
	return path


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
	var rank := 1

	for path in rewards:
		var card: Resource = load(path)
		if card == null:
			continue
		var details: Dictionary = simulator.call("score_card_reward_details", path, reward_tags, deck_profile, "balanced")
		var impact: Dictionary = _build_card_reward_impact(path, deck_profile, simulator)
		var reasons: Array = details.get("reasons", [])
		report.append({
			"path": path,
			"name": _get_resource_name(card),
			"rank": rank,
			"recommendation_label": "Recommended" if rank == 1 else "Option %d" % rank,
			"score": details.get("score", 0.0),
			"text": String(card.get("rules_text")),
			"explanation": details.get("explanation", "Solid reward option."),
			"reasons": reasons,
			"top_reasons": _get_top_reward_reasons(reasons),
			"impact": impact,
			"impact_summary": impact.get("summary", "Deck impact unavailable.")
		})
		rank += 1

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
		"encounter_intro": get_current_encounter_intro(),
		"table_modifier": get_current_table_modifier(),
		"table_modifiers": get_table_modifiers(),
		"run_path": get_run_path(),
		"reward_stakes": get_current_reward_stakes(),
		"reward_tag_names": get_current_reward_tag_names(),
		"player_hp": player_current_hp,
		"player_max_hp": PLAYER_MAX_HP,
		"deck_size": deck_paths.size(),
		"relic_names": _get_relic_names(),
		"pending_card_rewards": _describe_card_rewards(pending_card_reward_paths),
		"pending_relic_rewards": _describe_paths(pending_relic_reward_paths),
		"balance_snapshot": get_balance_snapshot(),
		"run_results": get_run_results(),
		"last_completed_node_name": last_completed_node_name,
		"next_node_name_after_reward": get_next_node_name_after_reward(),
		"current_enemy_names": get_current_enemy_names(),
		"current_enemy_cards": _get_enemy_cards_from_paths(get_current_enemy_paths()),
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


func _get_run_path_status(index: int) -> String:
	if run_outcome == "victory":
		return "cleared"
	if run_outcome == "defeat":
		if index < current_node_index:
			return "cleared"
		if index == current_node_index:
			return "lost"
		return "upcoming"
	if is_waiting_for_reward():
		if index < current_node_index:
			return "cleared"
		if index == current_node_index:
			return "reward"
		if index == current_node_index + 1:
			return "next"
		return "upcoming"
	if index < current_node_index:
		return "cleared"
	if index == current_node_index:
		return "current"
	return "upcoming"


func _get_run_path_status_label(status: String) -> String:
	match status:
		"cleared":
			return "CLEARED"
		"current":
			return "CURRENT"
		"reward":
			return "REWARD"
		"next":
			return "NEXT"
		"lost":
			return "LOST"
		_:
			return "UPCOMING"


func _get_node_table_modifier(node: Dictionary) -> Dictionary:
	var modifier_value: Variant = node.get("table_modifier", {})
	if typeof(modifier_value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(modifier_value)


func _get_enemy_names_from_paths(enemy_paths_value: Variant) -> Array[String]:
	var names: Array[String] = []
	if typeof(enemy_paths_value) != TYPE_ARRAY:
		return names

	for path_value in enemy_paths_value:
		var enemy: Resource = load(String(path_value))
		if enemy != null:
			names.append(_get_resource_name(enemy))
	return names


func _get_enemy_cards_from_paths(enemy_paths_value: Variant) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	if typeof(enemy_paths_value) != TYPE_ARRAY:
		return cards

	for path_value in enemy_paths_value:
		var enemy: Resource = load(String(path_value))
		if enemy == null:
			continue

		var behavior_tags_value: Variant = enemy.get("behavior_tags")
		var behavior_tags: Array = behavior_tags_value if typeof(behavior_tags_value) == TYPE_ARRAY else []
		cards.append({
			"name": _get_resource_name(enemy),
			"role": _get_enemy_role_label(int(enemy.get("role"))),
			"max_hp": int(enemy.get("max_hp")),
			"aggression": int(round(float(enemy.get("aggression")) * 100.0)),
			"bluff_chance": int(round(float(enemy.get("bluff_chance")) * 100.0)),
			"behavior_tags": _format_reward_tags(behavior_tags),
			"intent_names": _get_intent_names(enemy),
			"tell": String(enemy.get("tell_description")),
			"counterplay": String(enemy.get("counterplay_note")),
			"visual_identity": String(enemy.get("visual_identity"))
		})
	return cards


func _get_enemy_role_label(role_index: int) -> String:
	var roles := [
		"Basic Attacker",
		"Shield",
		"Trickster",
		"Summoner",
		"Sniper",
		"Brute",
		"Gambler",
		"Mimic",
		"Hex Caster",
		"Trap Setter",
		"Elite",
		"Boss"
	]
	if role_index < 0 or role_index >= roles.size():
		return "Enemy"
	return roles[role_index]


func _get_intent_names(enemy: Resource) -> Array[String]:
	var names: Array[String] = []
	var intents_value: Variant = enemy.get("intents")
	if typeof(intents_value) != TYPE_ARRAY:
		return names

	for intent in intents_value:
		if intent != null:
			names.append(_get_resource_name(intent))
	return names


func _resource_has_any_tag(resource: Resource, tags_to_match: Array) -> bool:
	var resource_tags: Array = resource.get("tags")
	for tag in tags_to_match:
		if resource_tags.has(StringName(tag)):
			return true
	return false


func _format_reward_tags(tags: Array) -> Array[String]:
	var labels: Array[String] = []
	for tag in tags:
		var label: String = String(tag).capitalize().replace("_", " ")
		if not label.is_empty():
			labels.append(label)
	return labels


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
				"rank": descriptions.size() + 1,
				"recommendation_label": "Option",
				"score": 0.0,
				"explanation": "Solid reward option.",
				"reasons": [],
				"top_reasons": [],
				"impact": {},
				"impact_summary": "Deck impact unavailable."
			})
	return descriptions


func _build_card_reward_impact(card_path: String, before_profile: Dictionary, simulator: RefCounted) -> Dictionary:
	var after_deck_paths: Array[String] = deck_paths.duplicate()
	after_deck_paths.append(card_path)
	var after_profile: Dictionary = simulator.call("build_deck_profile", after_deck_paths, get_relic_modifiers())
	var added_label: String = _get_added_card_role_label(card_path)
	var damage_delta: float = snappedf(float(after_profile.get("projected_damage_per_turn", 0.0)) - float(before_profile.get("projected_damage_per_turn", 0.0)), 0.01)
	var guard_delta: float = snappedf(float(after_profile.get("projected_guard_per_turn", 0.0)) - float(before_profile.get("projected_guard_per_turn", 0.0)), 0.01)
	var control_delta: float = snappedf(float(after_profile.get("control_score", 0.0)) - float(before_profile.get("control_score", 0.0)), 0.01)
	var power_delta: float = snappedf(float(after_profile.get("deck_power", 0.0)) - float(before_profile.get("deck_power", 0.0)), 0.01)

	return {
		"before_size": int(before_profile.get("deck_size", deck_paths.size())),
		"after_size": int(after_profile.get("deck_size", after_deck_paths.size())),
		"added_role": added_label,
		"damage_delta": damage_delta,
		"guard_delta": guard_delta,
		"control_delta": control_delta,
		"power_delta": power_delta,
		"summary": "Deck %d -> %d | Adds %s | Damage %s/turn | Guard %s/turn | Control %s" % [
			int(before_profile.get("deck_size", deck_paths.size())),
			int(after_profile.get("deck_size", after_deck_paths.size())),
			added_label,
			_format_signed_float(damage_delta),
			_format_signed_float(guard_delta),
			_format_signed_float(control_delta)
		]
	}


func _get_added_card_role_label(card_path: String) -> String:
	var card: Resource = load(card_path)
	if card == null:
		return "Card"

	match int(card.get("card_type")):
		0:
			return "Attack"
		1:
			return "Guard"
		2:
			return "Movement"
		3:
			return "Bluff"
		4:
			return "Read"
		5:
			return "Trap"
		6:
			return "Ritual"
		_:
			return "Card"


func _get_top_reward_reasons(reasons: Array) -> Array[String]:
	var top_reasons: Array[String] = []
	for reason in reasons:
		if top_reasons.size() >= 3:
			break
		top_reasons.append(String(reason))
	return top_reasons


func _format_signed_float(value: float) -> String:
	if value > 0.0:
		return "+%.2f" % value
	return "%.2f" % value


func _get_resource_name(resource: Resource) -> String:
	if resource == null:
		return "Unknown"
	if resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	return String(resource.get("display_name"))


func _emit_state() -> void:
	state_changed.emit(get_state())
