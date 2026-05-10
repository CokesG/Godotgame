class_name EnemyDefinition
extends Resource

enum EnemyRole {
	BASIC_ATTACKER,
	SHIELD,
	TRICKSTER,
	SUMMONER,
	SNIPER,
	BRUTE,
	GAMBLER,
	MIMIC,
	HEX_CASTER,
	TRAP_SETTER,
	ELITE,
	BOSS
}

@export var id: StringName
@export var display_name: String = ""
@export var role: EnemyRole = EnemyRole.BASIC_ATTACKER
@export var max_hp: int = 10
@export_range(0.0, 1.0, 0.01) var bluff_chance: float = 0.0
@export_range(0.0, 1.0, 0.01) var aggression: float = 0.5
@export var behavior_tags: Array[StringName] = []
@export var intents: Array[Resource] = []
@export_multiline var tell_description: String = ""
@export_multiline var counterplay_note: String = ""
@export_multiline var visual_identity: String = ""
@export var reward_tags: Array[StringName] = []


func get_display_name() -> String:
	if display_name.is_empty():
		return String(id)
	return display_name


func has_intents() -> bool:
	return not intents.is_empty()


func get_debug_summary() -> String:
	return "%s | hp %d | %s | intents %d" % [
		get_display_name(),
		max_hp,
		EnemyRole.keys()[role].capitalize(),
		intents.size()
	]
