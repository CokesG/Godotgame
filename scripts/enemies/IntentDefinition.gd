class_name IntentDefinition
extends Resource

enum IntentType {
	ATTACK,
	GUARD,
	MOVE,
	FEINT,
	BUFF,
	DEBUFF,
	SUMMON,
	TRAP
}

enum TelegraphTier {
	LIKELY,
	POSSIBLE,
	RARE
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var public_text: String = ""
@export_multiline var hidden_text: String = ""
@export var intent_type: IntentType = IntentType.ATTACK
@export_range(0.0, 1.0, 0.01) var weight: float = 1.0
@export var telegraph_tier: TelegraphTier = TelegraphTier.POSSIBLE
@export var target_lane: int = -1
@export var target_cell: Vector2i = Vector2i(-1, -1)
@export_file("*.png") var icon_path: String = ""
@export var payload: Dictionary = {}
@export var tell_tags: Array[StringName] = []


func get_display_name() -> String:
	if display_name.is_empty():
		return String(id)
	return display_name


func get_public_summary() -> String:
	var tier: String = String(TelegraphTier.keys()[telegraph_tier]).capitalize()
	var text := public_text
	if text.is_empty():
		text = get_display_name()
	return "%s: %s" % [tier, text]


func get_icon_texture() -> Texture2D:
	if icon_path.is_empty():
		return null
	var texture := load(icon_path)
	if texture is Texture2D:
		return texture
	return null
