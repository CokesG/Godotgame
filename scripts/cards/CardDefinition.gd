class_name CardDefinition
extends Resource

enum CardType {
	ATTACK,
	DEFENSE,
	MOVEMENT,
	BLUFF,
	READ,
	TRAP,
	RITUAL
}

enum Rarity {
	STARTER,
	COMMON,
	UNCOMMON,
	RARE,
	BOSS
}

enum TargetType {
	NONE,
	SELF,
	ENEMY,
	GRID_CELL,
	LANE,
	ANY_UNIT
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var rules_text: String = ""
@export var cost: int = 0
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.STARTER
@export var target_type: TargetType = TargetType.ENEMY
@export_file("*.png") var illustration_path: String = ""
@export var tags: Array[StringName] = []
@export var effects: Array[Dictionary] = []
@export var upgrade_id: StringName
@export_multiline var design_note: String = ""


func get_display_name() -> String:
	if display_name.is_empty():
		return String(id)
	return display_name


func get_debug_summary() -> String:
	return "%s | cost %d | %s" % [
		get_display_name(),
		cost,
		CardType.keys()[card_type].capitalize()
	]


func get_illustration_texture() -> Texture2D:
	if illustration_path.is_empty():
		return null
	var texture := load(illustration_path)
	if texture is Texture2D:
		return texture
	return null
