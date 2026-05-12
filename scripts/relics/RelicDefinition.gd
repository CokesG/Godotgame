class_name RelicDefinition
extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	BOSS
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var rules_text: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var icon_texture: Texture2D
@export var tags: Array[StringName] = []
@export var modifiers: Dictionary = {}
@export_multiline var design_note: String = ""


func get_display_name() -> String:
	if display_name.is_empty():
		return String(id)
	return display_name


func get_modifier(key: StringName, default_value = 0):
	return modifiers.get(key, default_value)


func get_debug_summary() -> String:
	return "%s | %s | %s" % [
		get_display_name(),
		Rarity.keys()[rarity].capitalize(),
		rules_text
	]
