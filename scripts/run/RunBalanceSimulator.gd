class_name RunBalanceSimulator
extends RefCounted

const CARD_DAMAGE := {
	&"quick_slash": 4.0,
	&"low_stab": 2.0,
	&"sure_cut": 5.0,
	&"center_cut": 5.0,
	&"house_edge": 3.0,
	&"all_in_cut": 7.0,
	&"marked_card": 2.0
}
const CARD_GUARD := {
	&"guard_up": 5.0,
	&"iron_vow": 8.0,
	&"house_edge": 3.0,
	&"bone_guard": 4.0,
	&"black_shield": 11.0,
	&"shadow_step": 2.0,
	&"second_wind": 4.0
}
const CARD_NERVE := {
	&"blood_ritual": 2.0,
	&"marked_card": 1.0,
	&"second_wind": 1.0
}


func build_deck_profile(card_paths: Array, relic_modifiers: Dictionary = {}) -> Dictionary:
	var profile := {
		"deck_size": card_paths.size(),
		"attack_cards": 0,
		"defense_cards": 0,
		"movement_cards": 0,
		"read_cards": 0,
		"trap_cards": 0,
		"ritual_cards": 0,
		"zero_cost_cards": 0,
		"average_cost": 0.0,
		"damage_per_cycle": 0.0,
		"guard_per_cycle": 0.0,
		"nerve_per_cycle": 0.0,
		"projected_damage_per_turn": 0.0,
		"projected_guard_per_turn": 0.0,
		"control_score": 0.0,
		"consistency_score": 0.0,
		"deck_power": 0.0
	}

	if card_paths.is_empty():
		return profile

	var total_cost := 0.0
	for path in card_paths:
		var card: Resource = load(String(path))
		if card == null:
			continue

		var card_id: StringName = card.get("id")
		var card_type := int(card.get("card_type"))
		var cost := int(card.get("cost"))
		total_cost += float(cost)

		match card_type:
			0:
				profile["attack_cards"] += 1
			1:
				profile["defense_cards"] += 1
			2:
				profile["movement_cards"] += 1
			4:
				profile["read_cards"] += 1
			5:
				profile["trap_cards"] += 1
			6:
				profile["ritual_cards"] += 1

		if cost == 0:
			profile["zero_cost_cards"] += 1

		profile["damage_per_cycle"] += float(CARD_DAMAGE.get(card_id, 0.0))
		profile["guard_per_cycle"] += float(CARD_GUARD.get(card_id, 0.0))
		profile["nerve_per_cycle"] += float(CARD_NERVE.get(card_id, 0.0))

	var deck_size: float = max(1.0, float(card_paths.size()))
	var hand_target: float = 5.0 + float(relic_modifiers.get("hand_target_bonus", 0))
	var max_energy: float = 3.0 + float(relic_modifiers.get("max_energy_bonus", 0))
	var average_cost: float = total_cost / deck_size
	var cost_pressure: float = clampf(max_energy / max(1.0, hand_target * max(0.65, average_cost)), 0.55, 1.25)

	profile["average_cost"] = snappedf(average_cost, 0.01)
	profile["projected_damage_per_turn"] = snappedf(float(profile["damage_per_cycle"]) / deck_size * hand_target * cost_pressure, 0.01)
	profile["projected_guard_per_turn"] = snappedf(float(profile["guard_per_cycle"]) / deck_size * hand_target * cost_pressure, 0.01)
	profile["control_score"] = snappedf(float(profile["movement_cards"]) * 0.9 + float(profile["trap_cards"]) * 0.8 + float(profile["read_cards"]) * 0.7 + float(profile["nerve_per_cycle"]) * 0.35, 0.01)
	profile["consistency_score"] = snappedf(float(profile["zero_cost_cards"]) * 0.5 + max(0.0, 2.0 - average_cost) + min(3.0, max_energy - 2.0), 0.01)
	profile["deck_power"] = snappedf(float(profile["projected_damage_per_turn"]) + float(profile["projected_guard_per_turn"]) * 0.55 + float(profile["control_score"]) * 0.45 + float(profile["consistency_score"]) * 0.35, 0.01)
	return profile


func build_encounter_profile(enemy_paths: Array) -> Dictionary:
	var total_hp := 0
	var expected_damage_per_turn := 0.0
	var max_single_hit := 0
	var intent_options := 0

	for path in enemy_paths:
		var enemy: Resource = load(String(path))
		if enemy == null:
			continue

		total_hp += int(enemy.get("max_hp"))
		var intents: Array = enemy.get("intents")
		intent_options += intents.size()
		var total_weight := 0.0
		var weighted_damage := 0.0

		for intent in intents:
			if intent == null:
				continue
			var weight: float = max(0.0, float(intent.get("weight")))
			var payload: Dictionary = intent.get("payload")
			var damage := int(payload.get("damage", 0))
			total_weight += weight
			weighted_damage += weight * float(damage)
			max_single_hit = max(max_single_hit, damage)

		if total_weight > 0.0:
			expected_damage_per_turn += weighted_damage / total_weight

	return {
		"enemy_count": enemy_paths.size(),
		"total_hp": total_hp,
		"expected_damage_per_turn": snappedf(expected_damage_per_turn, 0.01),
		"max_single_hit": max_single_hit,
		"intent_options": intent_options
	}


func evaluate_encounter(card_paths: Array, enemy_paths: Array, relic_modifiers: Dictionary = {}, starting_hp: int = 30) -> Dictionary:
	var deck_profile: Dictionary = build_deck_profile(card_paths, relic_modifiers)
	var encounter_profile: Dictionary = build_encounter_profile(enemy_paths)
	var damage_per_turn: float = max(1.0, float(deck_profile.get("projected_damage_per_turn", 0.0)))
	var projected_turns: int = ceili(float(encounter_profile.get("total_hp", 0)) / damage_per_turn)
	var control_mitigation: float = min(float(deck_profile.get("control_score", 0.0)) * 0.35, float(encounter_profile.get("expected_damage_per_turn", 0.0)) * 0.45)
	var guard_per_turn: float = float(deck_profile.get("projected_guard_per_turn", 0.0))
	var expected_taken: float = max(0.0, float(projected_turns) * (float(encounter_profile.get("expected_damage_per_turn", 0.0)) - guard_per_turn * 0.62 - control_mitigation))
	var starting_guard: float = float(relic_modifiers.get("starting_guard", 0))
	var survival_margin: float = float(starting_hp) + starting_guard - expected_taken
	var rating: String = _get_rating(survival_margin, projected_turns)

	return {
		"deck": deck_profile,
		"encounter": encounter_profile,
		"projected_turns": projected_turns,
		"expected_damage_taken": snappedf(expected_taken, 0.01),
		"survival_margin": snappedf(survival_margin, 0.01),
		"rating": rating,
		"recommendation": _get_recommendation(deck_profile, encounter_profile, rating)
	}


func score_card_reward(card_path: String, reward_tags: Array, deck_profile: Dictionary) -> float:
	var card: Resource = load(card_path)
	if card == null:
		return -999.0

	var score := 0.0
	var card_type := int(card.get("card_type"))
	var cost := int(card.get("cost"))
	var tags: Array = card.get("tags")
	for tag in reward_tags:
		if tags.has(StringName(tag)):
			score += 4.0

	match card_type:
		0:
			if int(deck_profile.get("attack_cards", 0)) < 5:
				score += 3.0
			score += 1.0
		1:
			if int(deck_profile.get("defense_cards", 0)) < 4:
				score += 3.0
		2:
			if int(deck_profile.get("movement_cards", 0)) < 3:
				score += 2.5
		4:
			if int(deck_profile.get("read_cards", 0)) < 2:
				score += 2.0
		5:
			if int(deck_profile.get("trap_cards", 0)) < 2:
				score += 2.0
		6:
			if int(deck_profile.get("ritual_cards", 0)) < 2:
				score += 1.5

	var card_id: StringName = card.get("id")
	score += float(CARD_DAMAGE.get(card_id, 0.0)) * 0.45
	score += float(CARD_GUARD.get(card_id, 0.0)) * 0.25
	score += float(CARD_NERVE.get(card_id, 0.0)) * 0.55
	score += max(0.0, 2.0 - float(cost)) * 0.35
	return snappedf(score, 0.01)


func simulate_fast_run(nodes: Array, starting_deck: Array, relic_modifiers: Dictionary = {}, starting_hp: int = 30) -> Dictionary:
	var deck_paths := _string_array(starting_deck)
	var hp := starting_hp
	var clears := 0
	var total_expected_damage := 0.0
	var worst_margin := 999.0
	var danger_nodes: Array[String] = []

	for node in nodes:
		if typeof(node) != TYPE_DICTIONARY:
			continue
		var enemy_paths := _string_array(node.get("enemy_paths", []))
		var evaluation: Dictionary = evaluate_encounter(deck_paths, enemy_paths, relic_modifiers, hp)
		var margin: float = float(evaluation.get("survival_margin", 0.0))
		worst_margin = min(worst_margin, margin)
		total_expected_damage += float(evaluation.get("expected_damage_taken", 0.0))
		if margin <= 0.0:
			danger_nodes.append(String(node.get("name", "Encounter")))
			return {
				"predicted_outcome": "defeat",
				"predicted_clears": clears,
				"total_nodes": nodes.size(),
				"ending_hp": max(0, floori(hp + float(relic_modifiers.get("starting_guard", 0)) - float(evaluation.get("expected_damage_taken", 0.0)))),
				"total_expected_damage": snappedf(total_expected_damage, 0.01),
				"worst_margin": snappedf(worst_margin, 0.01),
				"danger_nodes": danger_nodes
			}

		clears += 1
		hp = clampi(floori(hp - float(evaluation.get("expected_damage_taken", 0.0)) + 3.0), 1, starting_hp)
		deck_paths.append(_pick_default_reward(deck_paths, node.get("reward_tags", [])))

	return {
		"predicted_outcome": "victory",
		"predicted_clears": clears,
		"total_nodes": nodes.size(),
		"ending_hp": hp,
		"total_expected_damage": snappedf(total_expected_damage, 0.01),
		"worst_margin": snappedf(worst_margin, 0.01),
		"danger_nodes": danger_nodes
	}


func _pick_default_reward(deck_paths: Array[String], reward_tags: Array) -> String:
	var candidates := [
		"res://resources/cards/sure_cut.tres",
		"res://resources/cards/house_edge.tres",
		"res://resources/cards/bone_guard.tres",
		"res://resources/cards/shadow_step.tres",
		"res://resources/cards/marked_card.tres",
		"res://resources/cards/tripwire.tres"
	]
	var profile: Dictionary = build_deck_profile(deck_paths)
	var best_path: String = String(candidates[0])
	var best_score := -999.0
	for path in candidates:
		if deck_paths.has(path):
			continue
		var score: float = score_card_reward(path, reward_tags, profile)
		if score > best_score:
			best_score = score
			best_path = path
	return best_path


func _get_rating(survival_margin: float, projected_turns: int) -> String:
	if survival_margin >= 12.0 and projected_turns <= 5:
		return "favorable"
	if survival_margin >= 4.0:
		return "close"
	return "danger"


func _get_recommendation(deck_profile: Dictionary, encounter_profile: Dictionary, rating: String) -> String:
	if rating == "danger":
		if float(deck_profile.get("projected_guard_per_turn", 0.0)) < float(encounter_profile.get("expected_damage_per_turn", 0.0)) * 0.4:
			return "Add Guard or movement before this fight."
		return "Add damage; the encounter lasts too many turns."
	if int(deck_profile.get("movement_cards", 0)) < 2:
		return "Movement density is low for positional reads."
	if int(deck_profile.get("read_cards", 0)) + int(deck_profile.get("trap_cards", 0)) < 3:
		return "Add read/trap tools to support the hook."
	return "Run profile is in a playable band."


func _string_array(values: Array) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings
