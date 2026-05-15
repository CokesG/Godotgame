class_name RunManager
extends Node

signal log_requested(message: String)
signal state_changed(state: Dictionary)

const BALANCE_SIMULATOR_SCRIPT := preload("res://scripts/run/RunBalanceSimulator.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")
const PLAYER_MAX_HP := 30
const VICTORY_HEAL := 3
const RUN_SUMMARY_PREFIX := "dead_mans_ante_run_summary_"
const RUN_SUMMARY_SUFFIX := ".json"
const RUN_HISTORY_CSV_PREFIX := "dead_mans_ante_run_history_comparison_"
const RUN_HISTORY_CSV_SUFFIX := ".csv"
const RUN_SUMMARY_ARCHIVE_DIR := "run_summary_archive"
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
const CLASS_STARTER_DECKS := {
	"gambler_knight": STARTER_DECK_PATHS,
	"hex_sharpshooter": [
		"res://resources/cards/quick_slash.tres",
		"res://resources/cards/sure_cut.tres",
		"res://resources/cards/read_tell.tres",
		"res://resources/cards/marked_card.tres",
		"res://resources/cards/snare_card.tres",
		"res://resources/cards/tripwire.tres",
		"res://resources/cards/sidestep.tres",
		"res://resources/cards/shadow_step.tres",
		"res://resources/cards/false_opening.tres",
		"res://resources/cards/guard_up.tres"
	],
	"blood_wager": [
		"res://resources/cards/quick_slash.tres",
		"res://resources/cards/all_in_cut.tres",
		"res://resources/cards/blood_ritual.tres",
		"res://resources/cards/second_wind.tres",
		"res://resources/cards/iron_vow.tres",
		"res://resources/cards/black_shield.tres",
		"res://resources/cards/house_edge.tres",
		"res://resources/cards/false_opening.tres",
		"res://resources/cards/hook_step.tres",
		"res://resources/cards/low_stab.tres"
	]
}
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
var current_hero_class_id := "gambler_knight"
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
var reward_history: Array[Dictionary] = []
var last_reward_decision: Dictionary = {}


func reset_run(hero_class_id: String = "gambler_knight") -> void:
	current_node_index = 0
	current_hero_class_id = hero_class_id if CLASS_STARTER_DECKS.has(hero_class_id) else "gambler_knight"
	player_current_hp = PLAYER_MAX_HP
	deck_paths.clear()
	for path in get_class_starter_deck_paths(current_hero_class_id):
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
	reward_history.clear()
	last_reward_decision.clear()
	log_requested.emit("Run reset: %s antes into a five-fight prototype path." % current_hero_class_id.replace("_", " ").capitalize())
	_emit_state()


func get_class_starter_deck_paths(hero_class_id: String = "") -> Array[String]:
	var safe_id := current_hero_class_id if hero_class_id.is_empty() else hero_class_id
	var raw_paths: Array = CLASS_STARTER_DECKS.get(safe_id, STARTER_DECK_PATHS)
	var paths: Array[String] = []
	for path in raw_paths:
		paths.append(String(path))
	return paths


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


func get_current_tactical_map() -> Dictionary:
	var node: Dictionary = get_current_node()
	var map_id := String(node.get("tactical_map_id", TACTICAL_MAP_SCRIPT.MAP_CROSSFIRE_TABLE))
	var tactical_map: Dictionary = TACTICAL_MAP_SCRIPT.get_map(map_id)
	tactical_map["encounter_name"] = String(node.get("name", "Table"))
	tactical_map["encounter_note"] = String(node.get("encounter_intro", "Read the table before combat starts."))
	return tactical_map


func get_run_path() -> Array[Dictionary]:
	var path: Array[Dictionary] = []
	for index in range(RUN_NODES.size()):
		var node: Dictionary = RUN_NODES[index]
		var status: String = _get_run_path_status(index)
		var modifier: Dictionary = _get_node_table_modifier(node)
		var tactical_map: Dictionary = TACTICAL_MAP_SCRIPT.get_map(String(node.get("tactical_map_id", TACTICAL_MAP_SCRIPT.MAP_CROSSFIRE_TABLE)))
		path.append({
			"index": index,
			"table_number": index + 1,
			"name": String(node.get("name", "Table")),
			"kind": String(node.get("kind", "combat")),
			"tactical_map_name": String(tactical_map.get("name", "Crossfire Table")),
			"tactical_map_summary": String(tactical_map.get("summary", "")),
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
	var history_entry := _build_card_reward_history_entry(card_path, index)
	deck_paths.append(card_path)
	cards_claimed += 1
	pending_card_reward_paths.clear()
	var card: Resource = load(card_path)
	_record_reward_history(history_entry)
	log_requested.emit("Added %s to the run deck." % _get_resource_name(card))
	_advance_if_rewards_clear()
	_emit_state()
	return card_path


func claim_relic_reward(index: int) -> String:
	if index < 0 or index >= pending_relic_reward_paths.size():
		log_requested.emit("No relic reward at slot %d." % index)
		return ""

	var relic_path := pending_relic_reward_paths[index]
	var history_entry := _build_relic_reward_history_entry(relic_path, index)
	relic_paths.append(relic_path)
	relics_claimed += 1
	pending_relic_reward_paths.clear()
	var relic: Resource = load(relic_path)
	_record_reward_history(history_entry)
	log_requested.emit("Claimed relic: %s." % _get_resource_name(relic))
	_advance_if_rewards_clear()
	_emit_state()
	return relic_path


func skip_rewards() -> void:
	if pending_card_reward_paths.is_empty() and pending_relic_reward_paths.is_empty():
		log_requested.emit("No pending rewards to skip.")
	else:
		_record_reward_history(_build_skip_reward_history_entry())
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


func get_export_comparison_summary() -> Dictionary:
	var results := get_run_results()
	var outcome: String = String(results.get("outcome", run_outcome))
	var grade: String = String(results.get("grade", "Table Stakes"))
	var cleared_tables: int = int(results.get("combats_won", combats_won))
	var total_tables: int = int(results.get("total_combats", RUN_NODES.size()))
	var blood: int = int(results.get("blood", player_current_hp))
	var max_blood: int = int(results.get("max_blood", PLAYER_MAX_HP))
	var lowest: int = int(results.get("lowest_blood", lowest_blood))
	var damage: int = int(results.get("damage_taken_total", damage_taken_total))
	var deck_size: int = int(results.get("deck_size", deck_paths.size()))
	var cards_added: int = int(results.get("cards_claimed", cards_claimed))
	var relics_added: int = int(results.get("relics_claimed", relics_claimed))
	var current_node := get_current_node()
	var current_table: String = String(current_node.get("name", "Complete"))
	var final_table: String = last_completed_node_name if not last_completed_node_name.is_empty() else current_table
	var result_key := _build_export_result_key(outcome, cleared_tables, total_tables, blood, lowest, damage, deck_size)

	return {
		"result_key": result_key,
		"summary_line": "%s | %s | Tables %d/%d | Blood %d/%d | Low %d | Damage %d | Deck %d | Rewards +%d cards/+%d relics" % [
			outcome.capitalize(),
			grade,
			cleared_tables,
			total_tables,
			blood,
			max_blood,
			lowest,
			damage,
			deck_size,
			cards_added,
			relics_added
		],
		"compare_columns": {
			"outcome": outcome,
			"grade": grade,
			"cleared_tables": cleared_tables,
			"total_tables": total_tables,
			"blood": blood,
			"max_blood": max_blood,
			"lowest_blood": lowest,
			"damage_taken_total": damage,
			"deck_size": deck_size,
			"cards_claimed": cards_added,
			"relics_claimed": relics_added
		},
		"final_table": final_table,
		"current_table": current_table,
		"deck_names": _get_deck_card_names(),
		"relic_names": _get_relic_names()
	}


func get_export_route_summary() -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for entry in get_run_path():
		summary.append({
			"table_number": int(entry.get("table_number", 0)),
			"name": String(entry.get("name", "Table")),
			"kind": String(entry.get("kind", "combat")),
			"tactical_map_name": String(entry.get("tactical_map_name", "Crossfire Table")),
			"status": String(entry.get("status", "upcoming")),
			"status_label": String(entry.get("status_label", "UPCOMING")),
			"enemy_names": entry.get("enemy_names", []),
			"table_modifier_name": String(entry.get("table_modifier_name", "House Rules")),
			"reward_stakes": String(entry.get("reward_stakes", "Clear the table to improve the run."))
		})
	return summary


func get_run_history_comparison(limit: int = 6) -> Dictionary:
	var rows := get_recent_run_history(limit)
	var headline := "No exported run summaries found yet."
	var has_outcome_shift := false
	if not rows.is_empty():
		var latest: Dictionary = rows[0]
		headline = "Latest %s | %s" % [
			latest.get("result_key", "unkeyed_run"),
			latest.get("summary_line", "summary unavailable")
		]
		for row in rows:
			if bool(row.get("outcome_shift", false)):
				has_outcome_shift = true
				break

	return {
		"count": rows.size(),
		"rows": rows,
		"headline": headline,
		"has_outcome_shift": has_outcome_shift
	}


func get_run_inspection_report(history_limit: int = 5) -> Dictionary:
	var history_rows := get_recent_run_history(history_limit)
	var deck_report := _build_deck_inspection_report()
	var relic_report := _build_relic_inspection_report()
	var reward_rows := reward_history.duplicate(true)
	var pending_rewards := get_reward_tuning_report()
	var results := get_run_results()

	return {
		"title": "Run/Deck Inspector",
		"current_table": String(get_current_node().get("name", "Complete")),
		"run_outcome": run_outcome,
		"blood": player_current_hp,
		"max_blood": PLAYER_MAX_HP,
		"deck": deck_report,
		"relics": relic_report,
		"recent_rewards": reward_rows,
		"last_reward_decision": last_reward_decision.duplicate(true),
		"pending_rewards": pending_rewards,
		"history_rows": history_rows,
		"run_results": results,
		"summary": "Deck %d | Relics %d | Rewards logged %d | History rows %d" % [
			int(deck_report.get("size", deck_paths.size())),
			int(relic_report.get("count", relic_paths.size())),
			reward_rows.size(),
			history_rows.size()
		]
	}


func get_recent_run_history(limit: int = 6) -> Array[Dictionary]:
	var records := _collect_run_history_records()
	var rows: Array[Dictionary] = []
	var bounded_limit: int = max(1, limit)
	for index in range(min(bounded_limit, records.size())):
		rows.append(records[index].duplicate(true))
	_apply_history_deltas(rows)
	return rows


func export_run_history_csv(limit: int = 20) -> String:
	var rows := get_recent_run_history(limit)
	if rows.is_empty():
		log_requested.emit("No run history summaries available for CSV export.")
		return ""

	var path := "user://%s%d_%d%s" % [
		RUN_HISTORY_CSV_PREFIX,
		Time.get_unix_time_from_system(),
		Time.get_ticks_msec(),
		RUN_HISTORY_CSV_SUFFIX
	]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		log_requested.emit("Could not export run history CSV.")
		return ""

	var columns := _get_run_history_csv_columns()
	file.store_line(_build_csv_line(columns))
	for row in rows:
		var values: Array[String] = []
		for column in columns:
			values.append(str(row.get(column, "")))
		file.store_line(_build_csv_line(values))
	file.close()

	var global_path := ProjectSettings.globalize_path(path)
	log_requested.emit("Run history CSV exported: %s" % global_path)
	return global_path


func archive_old_run_summaries(keep_count: int = 8) -> Dictionary:
	var records := _collect_run_history_records()
	var bounded_keep: int = max(0, keep_count)
	var archived_files: Array[String] = []
	var errors: Array[String] = []
	var dir := DirAccess.open("user://")
	if dir == null:
		return {
			"kept_count": 0,
			"archived_count": 0,
			"archived_files": archived_files,
			"errors": ["Could not open user data directory."],
			"archive_dir": "user://%s" % RUN_SUMMARY_ARCHIVE_DIR
		}

	if not dir.dir_exists(RUN_SUMMARY_ARCHIVE_DIR):
		var make_error := dir.make_dir(RUN_SUMMARY_ARCHIVE_DIR)
		if make_error != OK:
			return {
				"kept_count": min(bounded_keep, records.size()),
				"archived_count": 0,
				"archived_files": archived_files,
				"errors": ["Could not create archive directory: %s." % error_string(make_error)],
				"archive_dir": "user://%s" % RUN_SUMMARY_ARCHIVE_DIR
			}

	for index in range(bounded_keep, records.size()):
		var record: Dictionary = records[index]
		var file_name := String(record.get("file_name", ""))
		if file_name.is_empty():
			continue
		var target_name := _get_archive_target_name(file_name)
		var rename_error := dir.rename(file_name, "%s/%s" % [RUN_SUMMARY_ARCHIVE_DIR, target_name])
		if rename_error == OK:
			archived_files.append(target_name)
		else:
			errors.append("%s: %s" % [file_name, error_string(rename_error)])

	return {
		"kept_count": min(bounded_keep, records.size()),
		"archived_count": archived_files.size(),
		"archived_files": archived_files,
		"errors": errors,
		"archive_dir": "user://%s" % RUN_SUMMARY_ARCHIVE_DIR
	}


func get_playtest_batch() -> Dictionary:
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	return simulator.call("simulate_playtest_batch", RUN_NODES, deck_paths, RELIC_POOL, get_relic_modifiers(), player_current_hp, 5)


func get_run_export_data() -> Dictionary:
	return {
		"version": 1,
		"export_version": 2,
		"exported_at_unix": Time.get_unix_time_from_system(),
		"run_results": get_run_results(),
		"comparison_summary": get_export_comparison_summary(),
		"route_summary": get_export_route_summary(),
		"balance_snapshot": get_balance_snapshot(),
		"playtest_batch": get_playtest_batch(),
		"deck": _describe_paths(deck_paths),
		"relics": _get_relic_names(),
		"current_node": get_current_node(),
		"pending_card_rewards": get_reward_tuning_report()
	}


func export_run_summary() -> String:
	var path := "user://dead_mans_ante_run_summary_%d_%d.json" % [
		Time.get_unix_time_from_system(),
		Time.get_ticks_msec()
	]
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
		"tactical_map": get_current_tactical_map(),
		"run_path": get_run_path(),
		"reward_stakes": get_current_reward_stakes(),
		"reward_tag_names": get_current_reward_tag_names(),
		"hero_class": current_hero_class_id,
		"player_hp": player_current_hp,
		"player_max_hp": PLAYER_MAX_HP,
		"deck_size": deck_paths.size(),
		"relic_names": _get_relic_names(),
		"pending_card_rewards": _describe_card_rewards(pending_card_reward_paths),
		"pending_relic_rewards": _describe_paths(pending_relic_reward_paths),
		"reward_history": reward_history.duplicate(true),
		"last_reward_decision": last_reward_decision.duplicate(true),
		"balance_snapshot": get_balance_snapshot(),
		"run_results": get_run_results(),
		"comparison_summary": get_export_comparison_summary(),
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


func get_snapshot() -> Dictionary:
	return {
		"current_node_index": current_node_index,
		"hero_class": current_hero_class_id,
		"player_current_hp": player_current_hp,
		"deck_paths": deck_paths.duplicate(),
		"relic_paths": relic_paths.duplicate(),
		"pending_card_reward_paths": pending_card_reward_paths.duplicate(),
		"pending_relic_reward_paths": pending_relic_reward_paths.duplicate(),
		"run_outcome": run_outcome,
		"last_completed_node_name": last_completed_node_name,
		"combats_won": combats_won,
		"cards_claimed": cards_claimed,
		"relics_claimed": relics_claimed,
		"damage_taken_total": damage_taken_total,
		"lowest_blood": lowest_blood,
		"reward_history": reward_history.duplicate(true),
		"last_reward_decision": last_reward_decision.duplicate(true)
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return

	current_node_index = clampi(int(snapshot.get("current_node_index", current_node_index)), 0, RUN_NODES.size() - 1)
	current_hero_class_id = String(snapshot.get("hero_class", current_hero_class_id))
	if not CLASS_STARTER_DECKS.has(current_hero_class_id):
		current_hero_class_id = "gambler_knight"
	player_current_hp = clampi(int(snapshot.get("player_current_hp", player_current_hp)), 0, PLAYER_MAX_HP)
	deck_paths = _string_array(snapshot.get("deck_paths", deck_paths))
	relic_paths = _string_array(snapshot.get("relic_paths", relic_paths))
	pending_card_reward_paths = _string_array(snapshot.get("pending_card_reward_paths", pending_card_reward_paths))
	pending_relic_reward_paths = _string_array(snapshot.get("pending_relic_reward_paths", pending_relic_reward_paths))
	run_outcome = String(snapshot.get("run_outcome", run_outcome))
	last_completed_node_name = String(snapshot.get("last_completed_node_name", last_completed_node_name))
	combats_won = int(snapshot.get("combats_won", combats_won))
	cards_claimed = int(snapshot.get("cards_claimed", cards_claimed))
	relics_claimed = int(snapshot.get("relics_claimed", relics_claimed))
	damage_taken_total = int(snapshot.get("damage_taken_total", damage_taken_total))
	lowest_blood = clampi(int(snapshot.get("lowest_blood", lowest_blood)), 0, PLAYER_MAX_HP)
	reward_history = _dictionary_array(snapshot.get("reward_history", reward_history))
	last_reward_decision = Dictionary(snapshot.get("last_reward_decision", last_reward_decision)).duplicate(true)
	log_requested.emit("Run restored from arena return state.")
	_emit_state()


func apply_arena_defeat(result: Dictionary) -> void:
	if run_outcome != "running":
		return

	run_outcome = "defeat"
	damage_taken_total += max(0, int(result.get("damage_taken", 0)))
	lowest_blood = 0
	player_current_hp = 0
	pending_card_reward_paths.clear()
	pending_relic_reward_paths.clear()
	last_completed_node_name = String(get_current_node().get("name", "Arena"))
	log_requested.emit("Arena defeat: the House takes the table.")
	_emit_state()


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


func _record_reward_history(entry: Dictionary) -> void:
	if entry.is_empty():
		return

	_finalize_reward_history_entry(entry)
	last_reward_decision = entry.duplicate(true)
	reward_history.push_front(entry)
	while reward_history.size() > 12:
		reward_history.pop_back()


func _build_card_reward_history_entry(card_path: String, index: int) -> Dictionary:
	var card: Resource = load(card_path)
	if card == null:
		return {}

	var reward_entry := _get_reward_tuning_entry_for_path(card_path)
	var impact_text := String(reward_entry.get("impact_summary", "Deck impact unavailable."))
	return {
		"kind": "Card",
		"name": _get_resource_name(card),
		"path": card_path,
		"choice": index + 1,
		"table": last_completed_node_name,
		"before_deck_size": deck_paths.size(),
		"before_deck_snapshot": _build_deck_snapshot_summary(deck_paths),
		"before_relic_count": relic_paths.size(),
		"summary": "Card reward #%d from %s: %s" % [
			index + 1,
			last_completed_node_name,
			_get_resource_name(card)
		],
		"reason": String(reward_entry.get("explanation", "Added to fill a run need.")),
		"impact": impact_text,
		"deck_change": impact_text
	}


func _build_relic_reward_history_entry(relic_path: String, index: int) -> Dictionary:
	var relic: Resource = load(relic_path)
	if relic == null:
		return {}

	return {
		"kind": "Relic",
		"name": _get_resource_name(relic),
		"path": relic_path,
		"choice": index + 1,
		"table": last_completed_node_name,
		"before_deck_size": deck_paths.size(),
		"before_deck_snapshot": _build_deck_snapshot_summary(deck_paths),
		"before_relic_count": relic_paths.size(),
		"summary": "Relic reward #%d from %s: %s" % [
			index + 1,
			last_completed_node_name,
			_get_resource_name(relic)
		],
		"reason": String(relic.get("rules_text")),
		"impact": _format_relic_modifiers(relic.get("modifiers")),
		"deck_change": "Deck size stayed at %d while relic count changes." % deck_paths.size()
	}


func _build_skip_reward_history_entry() -> Dictionary:
	var skipped_names: Array[String] = []
	for path in pending_card_reward_paths:
		var card: Resource = load(path)
		if card != null:
			skipped_names.append(_get_resource_name(card))
	for path in pending_relic_reward_paths:
		var relic: Resource = load(path)
		if relic != null:
			skipped_names.append(_get_resource_name(relic))

	return {
		"kind": "Skip",
		"name": "Skipped Rewards",
		"path": "",
		"choice": 0,
		"table": last_completed_node_name,
		"before_deck_size": deck_paths.size(),
		"before_deck_snapshot": _build_deck_snapshot_summary(deck_paths),
		"before_relic_count": relic_paths.size(),
		"summary": "Skipped rewards from %s." % last_completed_node_name,
		"reason": "Kept the deck lean instead of adding %s." % _join_or_none(skipped_names),
		"impact": "Deck size stayed at %d." % deck_paths.size(),
		"deck_change": "Deck %d -> %d | No card added." % [deck_paths.size(), deck_paths.size()]
	}


func _finalize_reward_history_entry(entry: Dictionary) -> void:
	if not entry.has("before_deck_size"):
		entry["before_deck_size"] = deck_paths.size()
	if not entry.has("before_deck_snapshot"):
		entry["before_deck_snapshot"] = _build_deck_snapshot_summary(deck_paths)
	if not entry.has("before_relic_count"):
		entry["before_relic_count"] = relic_paths.size()

	var before_deck_size := int(entry.get("before_deck_size", deck_paths.size()))
	var before_relic_count := int(entry.get("before_relic_count", relic_paths.size()))
	entry["after_deck_size"] = deck_paths.size()
	entry["after_deck_snapshot"] = _build_deck_snapshot_summary(deck_paths)
	entry["after_relic_count"] = relic_paths.size()

	match String(entry.get("kind", "")):
		"Relic":
			entry["deck_change"] = "Deck %d -> %d | Relics %d -> %d" % [
				before_deck_size,
				deck_paths.size(),
				before_relic_count,
				relic_paths.size()
			]
		"Skip":
			entry["deck_change"] = "Deck %d -> %d | No card added." % [
				before_deck_size,
				deck_paths.size()
			]
		_:
			if String(entry.get("deck_change", "")).is_empty():
				entry["deck_change"] = "Deck %d -> %d" % [before_deck_size, deck_paths.size()]

	entry["decision_summary"] = "%s\nBefore: %s\nAfter: %s" % [
		String(entry.get("deck_change", "Deck change unavailable.")),
		String(entry.get("before_deck_snapshot", "")),
		String(entry.get("after_deck_snapshot", ""))
	]


func _build_deck_snapshot_summary(paths: Array[String]) -> String:
	var type_counts: Dictionary = {}
	var tag_counts: Dictionary = {}
	var total_cost := 0
	var card_count := 0

	for path in paths:
		var card: Resource = load(path)
		if card == null:
			continue

		card_count += 1
		total_cost += int(card.get("cost"))
		var type_label := _get_card_type_label(int(card.get("card_type")))
		type_counts[type_label] = int(type_counts.get(type_label, 0)) + 1
		for tag in _format_reward_tags(card.get("tags")):
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1

	var average_cost: float = 0.0 if card_count == 0 else snappedf(float(total_cost) / float(card_count), 0.01)
	return "%d cards | Avg cost %.2f | Types %s | Tags %s" % [
		paths.size(),
		average_cost,
		_format_counts(type_counts),
		_format_counts(tag_counts)
	]


func _get_reward_tuning_entry_for_path(card_path: String) -> Dictionary:
	for entry in get_reward_tuning_report():
		if String(entry.get("path", "")) == card_path:
			return entry
	return {}


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


func _get_deck_card_names() -> Array[String]:
	var names: Array[String] = []
	for path in deck_paths:
		var card: Resource = load(path)
		if card != null:
			names.append(_get_resource_name(card))
	return names


func _build_export_result_key(outcome: String, cleared: int, total: int, blood: int, lowest: int, damage: int, deck_size: int) -> String:
	var safe_outcome := outcome.to_lower().replace(" ", "_")
	return "%s_%dof%d_hp%d_low%d_dmg%d_deck%d" % [
		safe_outcome,
		cleared,
		total,
		blood,
		lowest,
		damage,
		deck_size
	]


func _is_run_summary_file(file_name: String) -> bool:
	return file_name.begins_with(RUN_SUMMARY_PREFIX) and file_name.ends_with(RUN_SUMMARY_SUFFIX)


func _collect_run_history_records() -> Array[Dictionary]:
	var dir := DirAccess.open("user://")
	if dir == null:
		return []

	var records: Array[Dictionary] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and _is_run_summary_file(file_name):
			var path := "user://%s" % file_name
			var row := _read_run_history_row(file_name, path)
			if not row.is_empty():
				records.append(row)
		file_name = dir.get_next()
	dir.list_dir_end()

	records.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_time := int(left.get("sort_time", 0))
		var right_time := int(right.get("sort_time", 0))
		if left_time == right_time:
			return String(left.get("file_name", "")) > String(right.get("file_name", ""))
		return left_time > right_time
	)
	return records


func _get_archive_target_name(file_name: String) -> String:
	var target_name := file_name
	if not FileAccess.file_exists("user://%s/%s" % [RUN_SUMMARY_ARCHIVE_DIR, target_name]):
		return target_name

	var stem_length: int = max(0, file_name.length() - RUN_SUMMARY_SUFFIX.length())
	var stem := file_name.substr(0, stem_length)
	return "%s_archive_%d%s" % [
		stem,
		Time.get_ticks_msec(),
		RUN_SUMMARY_SUFFIX
	]


func _build_deck_inspection_report() -> Dictionary:
	var simulator = BALANCE_SIMULATOR_SCRIPT.new()
	var profile: Dictionary = simulator.call("build_deck_profile", deck_paths, get_relic_modifiers())
	var cards: Array[Dictionary] = []
	var type_counts: Dictionary = {}
	var tag_counts: Dictionary = {}
	var total_cost := 0

	for path in deck_paths:
		var card: Resource = load(path)
		if card == null:
			continue

		var type_label := _get_card_type_label(int(card.get("card_type")))
		var tags := _format_reward_tags(card.get("tags"))
		type_counts[type_label] = int(type_counts.get(type_label, 0)) + 1
		for tag in tags:
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
		total_cost += int(card.get("cost"))
		cards.append({
			"name": _get_resource_name(card),
			"path": path,
			"type": type_label,
			"cost": int(card.get("cost")),
			"tags": tags,
			"text": String(card.get("rules_text"))
		})

	var average_cost: float = 0.0 if cards.is_empty() else snappedf(float(total_cost) / float(cards.size()), 0.01)
	return {
		"size": deck_paths.size(),
		"average_cost": average_cost,
		"type_counts": type_counts,
		"type_summary": _format_counts(type_counts),
		"tag_counts": tag_counts,
		"tag_summary": _format_counts(tag_counts),
		"profile": profile,
		"gap_summary": _build_deck_gap_summary(profile),
		"cards": cards
	}


func _build_relic_inspection_report() -> Dictionary:
	var rows: Array[Dictionary] = []
	for path in relic_paths:
		var relic: Resource = load(path)
		if relic == null:
			continue

		rows.append({
			"name": _get_resource_name(relic),
			"path": path,
			"text": String(relic.get("rules_text")),
			"tags": _format_reward_tags(relic.get("tags")),
			"modifiers": relic.get("modifiers"),
			"modifier_summary": _format_relic_modifiers(relic.get("modifiers"))
		})

	return {
		"count": rows.size(),
		"names": _get_relic_names(),
		"summary": "No relics claimed yet." if rows.is_empty() else _join_or_none(_get_relic_names()),
		"rows": rows
	}


func _build_deck_gap_summary(profile: Dictionary) -> String:
	var gaps: Array[String] = []
	if int(profile.get("attack_cards", 0)) < 4:
		gaps.append("needs more attacks")
	if int(profile.get("defense_cards", 0)) < 2:
		gaps.append("needs more Guard")
	if int(profile.get("movement_cards", 0)) < 2:
		gaps.append("needs movement")
	if int(profile.get("read_cards", 0)) < 1:
		gaps.append("needs reads")
	if int(profile.get("trap_cards", 0)) < 1:
		gaps.append("could use trap control")
	if gaps.is_empty():
		return "Core deck lanes are covered."
	return ", ".join(gaps).capitalize()


func _read_run_history_row(file_name: String, path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var data: Dictionary = Dictionary(parsed)
	var comparison := _get_dictionary_value(data.get("comparison_summary", {}))
	var columns := _get_dictionary_value(comparison.get("compare_columns", {}))
	var results := _get_dictionary_value(data.get("run_results", {}))
	if columns.is_empty():
		columns = _build_compare_columns_from_results(results)

	var route_summary: Array = []
	var route_value: Variant = data.get("route_summary", [])
	if typeof(route_value) == TYPE_ARRAY:
		route_summary = Array(route_value)

	var exported_at: int = int(data.get("exported_at_unix", FileAccess.get_modified_time(path)))
	var result_key: String = String(comparison.get("result_key", _build_export_result_key(
		String(columns.get("outcome", results.get("outcome", "unknown"))),
		int(columns.get("cleared_tables", results.get("combats_won", 0))),
		int(columns.get("total_tables", results.get("total_combats", RUN_NODES.size()))),
		int(columns.get("blood", results.get("blood", 0))),
		int(columns.get("lowest_blood", results.get("lowest_blood", 0))),
		int(columns.get("damage_taken_total", results.get("damage_taken_total", 0))),
		int(columns.get("deck_size", results.get("deck_size", 0)))
	)))
	var summary_line: String = String(comparison.get("summary_line", _build_history_summary_line(columns)))

	return {
		"file_name": file_name,
		"path": path,
		"global_path": ProjectSettings.globalize_path(path),
		"modified_time": int(FileAccess.get_modified_time(path)),
		"exported_at_unix": exported_at,
		"sort_time": max(exported_at, int(FileAccess.get_modified_time(path))),
		"result_key": result_key,
		"summary_line": summary_line,
		"outcome": String(columns.get("outcome", results.get("outcome", "unknown"))),
		"grade": String(columns.get("grade", results.get("grade", "Table Stakes"))),
		"cleared_tables": int(columns.get("cleared_tables", results.get("combats_won", 0))),
		"total_tables": int(columns.get("total_tables", results.get("total_combats", RUN_NODES.size()))),
		"blood": int(columns.get("blood", results.get("blood", 0))),
		"max_blood": int(columns.get("max_blood", results.get("max_blood", PLAYER_MAX_HP))),
		"lowest_blood": int(columns.get("lowest_blood", results.get("lowest_blood", 0))),
		"damage_taken_total": int(columns.get("damage_taken_total", results.get("damage_taken_total", 0))),
		"deck_size": int(columns.get("deck_size", results.get("deck_size", 0))),
		"cards_claimed": int(columns.get("cards_claimed", results.get("cards_claimed", 0))),
		"relics_claimed": int(columns.get("relics_claimed", results.get("relics_claimed", 0))),
		"route_text": _get_history_route_text(route_summary),
		"delta_label": "",
		"outcome_shift": false
	}


func _apply_history_deltas(rows: Array[Dictionary]) -> void:
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		if index + 1 >= rows.size():
			row["delta_label"] = "First loaded export in this comparison window."
			row["outcome_shift"] = false
		else:
			var previous: Dictionary = rows[index + 1]
			row["delta_label"] = _build_history_delta_label(row, previous)
			row["outcome_shift"] = String(row.get("outcome", "")) != String(previous.get("outcome", ""))
		rows[index] = row


func _build_history_delta_label(current: Dictionary, previous: Dictionary) -> String:
	var parts := PackedStringArray()
	var current_outcome := String(current.get("outcome", "unknown"))
	var previous_outcome := String(previous.get("outcome", "unknown"))
	if current_outcome != previous_outcome:
		parts.append("Outcome shift %s -> %s" % [previous_outcome, current_outcome])
	parts.append("Clears %s" % _format_signed_int(int(current.get("cleared_tables", 0)) - int(previous.get("cleared_tables", 0))))
	parts.append("Blood %s" % _format_signed_int(int(current.get("blood", 0)) - int(previous.get("blood", 0))))
	parts.append("Low %s" % _format_signed_int(int(current.get("lowest_blood", 0)) - int(previous.get("lowest_blood", 0))))
	parts.append("Damage %s" % _format_signed_int(int(current.get("damage_taken_total", 0)) - int(previous.get("damage_taken_total", 0))))
	parts.append("Deck %s" % _format_signed_int(int(current.get("deck_size", 0)) - int(previous.get("deck_size", 0))))
	return " | ".join(parts)


func _build_compare_columns_from_results(results: Dictionary) -> Dictionary:
	return {
		"outcome": String(results.get("outcome", "unknown")),
		"grade": String(results.get("grade", "Table Stakes")),
		"cleared_tables": int(results.get("combats_won", 0)),
		"total_tables": int(results.get("total_combats", RUN_NODES.size())),
		"blood": int(results.get("blood", 0)),
		"max_blood": int(results.get("max_blood", PLAYER_MAX_HP)),
		"lowest_blood": int(results.get("lowest_blood", 0)),
		"damage_taken_total": int(results.get("damage_taken_total", 0)),
		"deck_size": int(results.get("deck_size", 0)),
		"cards_claimed": int(results.get("cards_claimed", 0)),
		"relics_claimed": int(results.get("relics_claimed", 0))
	}


func _build_history_summary_line(columns: Dictionary) -> String:
	return "%s | %s | Tables %d/%d | Blood %d/%d | Low %d | Damage %d | Deck %d" % [
		String(columns.get("outcome", "Unknown")).capitalize(),
		columns.get("grade", "Table Stakes"),
		columns.get("cleared_tables", 0),
		columns.get("total_tables", RUN_NODES.size()),
		columns.get("blood", 0),
		columns.get("max_blood", PLAYER_MAX_HP),
		columns.get("lowest_blood", 0),
		columns.get("damage_taken_total", 0),
		columns.get("deck_size", 0)
	]


func _get_history_route_text(route_summary: Array) -> String:
	if route_summary.is_empty():
		return "route unavailable"

	var entries := PackedStringArray()
	for entry_value in route_summary:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_value)
		entries.append("%d:%s" % [
			int(entry.get("table_number", 0)),
			String(entry.get("status_label", "UPCOMING"))
		])
	if entries.is_empty():
		return "route unavailable"
	return " -> ".join(entries)


func _get_dictionary_value(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value)
	return {}


func _get_card_type_label(card_type: int) -> String:
	var labels := [
		"Attack",
		"Defense",
		"Movement",
		"Bluff",
		"Read",
		"Trap",
		"Ritual"
	]
	if card_type >= 0 and card_type < labels.size():
		return labels[card_type]
	return "Card"


func _format_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "None"

	var parts := PackedStringArray()
	var keys := counts.keys()
	keys.sort()
	for key in keys:
		parts.append("%s %d" % [String(key), int(counts[key])])
	return " | ".join(parts)


func _format_relic_modifiers(modifiers_value: Variant) -> String:
	if typeof(modifiers_value) != TYPE_DICTIONARY:
		return "No modifiers"

	var modifiers: Dictionary = Dictionary(modifiers_value)
	if modifiers.is_empty():
		return "No modifiers"

	var parts := PackedStringArray()
	var keys := modifiers.keys()
	keys.sort()
	for key in keys:
		parts.append("%s %s" % [String(key), _format_signed_int(int(modifiers[key]))])
	return " | ".join(parts)


func _join_or_none(values: Array[String]) -> String:
	if values.is_empty():
		return "None"
	return ", ".join(values)


func _get_run_history_csv_columns() -> Array[String]:
	return [
		"file_name",
		"result_key",
		"outcome",
		"grade",
		"cleared_tables",
		"total_tables",
		"blood",
		"max_blood",
		"lowest_blood",
		"damage_taken_total",
		"deck_size",
		"cards_claimed",
		"relics_claimed",
		"delta_label",
		"route_text"
	]


func _build_csv_line(values: Array[String]) -> String:
	var escaped_values := PackedStringArray()
	for value in values:
		escaped_values.append(_csv_escape(value))
	return ",".join(escaped_values)


func _csv_escape(value: String) -> String:
	var text := value.replace("\"", "\"\"")
	if text.contains(",") or text.contains("\"") or text.contains("\n") or text.contains("\r"):
		return "\"%s\"" % text
	return text


func _format_signed_int(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return "%d" % value


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


func _string_array(values: Variant) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings


func _dictionary_array(values: Variant) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			dictionaries.append(Dictionary(value).duplicate(true))
	return dictionaries


func _get_resource_name(resource: Resource) -> String:
	if resource == null:
		return "Unknown"
	if resource.has_method("get_display_name"):
		return String(resource.call("get_display_name"))
	return String(resource.get("display_name"))


func _emit_state() -> void:
	state_changed.emit(get_state())
