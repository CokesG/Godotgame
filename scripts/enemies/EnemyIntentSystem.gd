class_name EnemyIntentSystem
extends Node

signal log_requested(message: String)
signal previews_changed(previews: Array[Dictionary])
signal debug_truth_changed(truth: Array[Dictionary])
signal intents_revealed(revealed: Array[Dictionary])

@export var enemy_paths: Array[String] = []
@export var debug_truth_visible: bool = true

var enemies: Array[Resource] = []
var selected_intents: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func configure_enemies(paths: Array) -> void:
	enemy_paths.clear()
	for path in paths:
		enemy_paths.append(String(path))
	load_enemies()


func set_seed(seed: int) -> void:
	rng.seed = seed


func load_enemies() -> void:
	enemies.clear()
	selected_intents.clear()

	for path in enemy_paths:
		var enemy := load(path)
		if enemy == null:
			log_requested.emit("Failed to load enemy resource: %s" % path)
			continue
		enemies.append(enemy)

	log_requested.emit("Loaded %d enemies for intent preview." % enemies.size())
	_emit_previews()
	_emit_truth()


func roll_intents() -> void:
	selected_intents.clear()

	for enemy in enemies:
		var intent := _choose_weighted_intent(enemy)
		if intent == null:
			log_requested.emit("%s has no valid intents." % _get_enemy_name(enemy))
			continue
		selected_intents[_get_enemy_id(enemy)] = intent
		log_requested.emit("%s commits an unseen intent." % _get_enemy_name(enemy))

	_emit_previews()
	_emit_truth()


func reveal_intents() -> Array[Dictionary]:
	var revealed: Array[Dictionary] = []

	for enemy in enemies:
		var enemy_id := _get_enemy_id(enemy)
		var intent: Resource = selected_intents.get(enemy_id)
		if intent == null:
			continue

		var entry := _make_intent_entry(enemy, intent)
		revealed.append(entry)
		log_requested.emit("Reveal: %s -> %s" % [
			entry.get("enemy_name", "Enemy"),
			entry.get("hidden_text", entry.get("intent_name", "Unknown"))
		])

	intents_revealed.emit(revealed)
	return revealed


func clear_intents() -> void:
	selected_intents.clear()
	_emit_truth()
	log_requested.emit("Hidden intents cleared.")


func get_public_previews() -> Array[Dictionary]:
	var previews: Array[Dictionary] = []

	for enemy in enemies:
		var preview := {
			"enemy_id": _get_enemy_id(enemy),
			"enemy_name": _get_enemy_name(enemy),
			"tell": String(enemy.get("tell_description")),
			"options": _get_public_options(enemy)
		}
		previews.append(preview)

	return previews


func get_debug_truth() -> Array[Dictionary]:
	var truth: Array[Dictionary] = []

	for enemy in enemies:
		var enemy_id := _get_enemy_id(enemy)
		var intent: Resource = selected_intents.get(enemy_id)
		if intent == null:
			truth.append({
				"enemy_id": enemy_id,
				"enemy_name": _get_enemy_name(enemy),
				"intent_name": "None",
				"hidden_text": "No hidden intent selected."
			})
		else:
			truth.append(_make_intent_entry(enemy, intent))

	return truth


func _choose_weighted_intent(enemy: Resource) -> Resource:
	var intents: Array = enemy.get("intents")
	if intents.is_empty():
		return null

	var total_weight := 0.0
	for intent in intents:
		if intent == null:
			continue
		total_weight += _get_nonnegative_weight(intent)

	if total_weight <= 0.0:
		return intents[0]

	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0

	for intent in intents:
		if intent == null:
			continue
		cursor += _get_nonnegative_weight(intent)
		if roll <= cursor:
			return intent

	return intents.back()


func _get_public_options(enemy: Resource) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var intents: Array = enemy.get("intents")
	var total_weight := 0.0

	for intent in intents:
		if intent != null:
			total_weight += _get_nonnegative_weight(intent)

	for intent in intents:
		if intent == null:
			continue
		var weight := _get_nonnegative_weight(intent)
		var percentage: int = 0
		if total_weight > 0.0:
			percentage = int(round((weight / total_weight) * 100.0))

		var target_lane: int = int(intent.get("target_lane"))
		var intent_type: int = int(intent.get("intent_type"))
		options.append({
			"intent_id": _get_intent_id(intent),
			"intent_name": _get_intent_name(intent),
			"summary": "%s [%s]" % [_get_public_summary(intent), _get_lane_text(target_lane, intent_type)],
			"icon_texture": intent.get("icon_texture"),
			"weight": weight,
			"percentage": percentage,
			"tier": _get_tier_name(intent),
			"target_lane": target_lane,
			"intent_type": intent_type,
			"lane_text": _get_lane_text(target_lane, intent_type)
		})

	return options


func _make_intent_entry(enemy: Resource, intent: Resource) -> Dictionary:
	return {
		"enemy_id": _get_enemy_id(enemy),
		"enemy_name": _get_enemy_name(enemy),
		"intent_id": _get_intent_id(intent),
		"intent_name": _get_intent_name(intent),
		"public_text": String(intent.get("public_text")),
		"hidden_text": _get_hidden_text(intent),
		"icon_texture": intent.get("icon_texture"),
		"tier": _get_tier_name(intent),
		"target_lane": int(intent.get("target_lane")),
		"intent_type": int(intent.get("intent_type")),
		"payload": intent.get("payload")
	}


func _emit_previews() -> void:
	previews_changed.emit(get_public_previews())


func _emit_truth() -> void:
	debug_truth_changed.emit(get_debug_truth())


func _get_enemy_id(enemy: Resource) -> StringName:
	return enemy.get("id")


func _get_enemy_name(enemy: Resource) -> String:
	if enemy.has_method("get_display_name"):
		return String(enemy.call("get_display_name"))
	return String(enemy.get("display_name"))


func _get_intent_id(intent: Resource) -> StringName:
	return intent.get("id")


func _get_intent_name(intent: Resource) -> String:
	if intent.has_method("get_display_name"):
		return String(intent.call("get_display_name"))
	return String(intent.get("display_name"))


func _get_public_summary(intent: Resource) -> String:
	if intent.has_method("get_public_summary"):
		return String(intent.call("get_public_summary"))
	return String(intent.get("public_text"))


func _get_hidden_text(intent: Resource) -> String:
	var hidden_text := String(intent.get("hidden_text"))
	if hidden_text.is_empty():
		return _get_intent_name(intent)
	return hidden_text


func _get_tier_name(intent: Resource) -> String:
	var tier_index := int(intent.get("telegraph_tier"))
	var tiers := ["Likely", "Possible", "Rare"]
	if tier_index >= 0 and tier_index < tiers.size():
		return tiers[tier_index]
	return "Possible"


func _get_nonnegative_weight(intent: Resource) -> float:
	var weight := float(intent.get("weight"))
	if weight < 0.0:
		return 0.0
	return weight


func _get_lane_text(target_lane: int, intent_type: int) -> String:
	if target_lane >= 0:
		return "Lane: %s" % _get_lane_name(target_lane)

	if intent_type == IntentDefinition.IntentType.ATTACK:
		return "Tracks you"

	return "No attack"


func _get_lane_name(lane: int) -> String:
	match lane:
		0:
			return "Left"
		1:
			return "Center"
		2:
			return "Right"
		_:
			return "Unknown"
