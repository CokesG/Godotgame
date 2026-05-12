class_name CardView
extends Button

signal card_pressed(hand_index: int)
signal card_hovered(hand_index: int)
signal card_unhovered(hand_index: int)

var card_resource: Resource
var hand_index: int = -1
var is_previewed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(156, 176)
	focus_mode = Control.FOCUS_NONE
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_refresh()


func set_card(card: Resource, index: int) -> void:
	card_resource = card
	hand_index = index
	_refresh()


func _on_pressed() -> void:
	card_pressed.emit(hand_index)


func set_previewed(value: bool) -> void:
	is_previewed = value
	_refresh()


func _on_mouse_entered() -> void:
	card_hovered.emit(hand_index)


func _on_mouse_exited() -> void:
	card_unhovered.emit(hand_index)


func _on_focus_entered() -> void:
	card_hovered.emit(hand_index)


func _on_focus_exited() -> void:
	card_unhovered.emit(hand_index)


func _refresh() -> void:
	if card_resource == null:
		text = "Empty"
		return

	var card_name := _get_card_name()
	var cost := int(card_resource.get("cost"))
	var rules_text := String(card_resource.get("rules_text"))
	var type_label := _get_card_type_label()
	var target_label := _get_target_label()
	text = "%s\nCost %d | %s\nTarget: %s\n%s" % [card_name, cost, type_label, target_label, rules_text]
	tooltip_text = "Click to play %s during Player Commit. Target: %s%s" % [
		card_name,
		target_label,
		_get_tag_tooltip()
	]

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.bg_color = Color(0.22, 0.18, 0.12) if is_previewed else Color(0.16, 0.14, 0.12)
	style.border_color = Color(1.0, 0.88, 0.48) if is_previewed else _get_card_type_color()
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_font_size_override("font_size", 13)


func _get_card_name() -> String:
	if card_resource.has_method("get_display_name"):
		return String(card_resource.call("get_display_name"))
	return String(card_resource.get("display_name"))


func _get_card_type_label() -> String:
	var card_type := int(card_resource.get("card_type"))
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


func _get_target_label() -> String:
	var target_type := int(card_resource.get("target_type"))
	var labels := [
		"None",
		"Self",
		"Enemy",
		"Grid Cell",
		"Lane",
		"Any Unit"
	]
	if target_type >= 0 and target_type < labels.size():
		return labels[target_type]
	return "Unknown"


func _get_tag_tooltip() -> String:
	var tags_value = card_resource.get("tags")
	if typeof(tags_value) != TYPE_ARRAY:
		return ""

	var labels: Array[String] = []
	for tag in tags_value:
		labels.append(String(tag).capitalize())
	if labels.is_empty():
		return ""
	return " | Tags: %s" % ", ".join(labels)


func _get_card_type_color() -> Color:
	match int(card_resource.get("card_type")):
		0:
			return Color(0.92, 0.42, 0.34)
		1:
			return Color(0.36, 0.74, 0.58)
		2:
			return Color(0.38, 0.68, 0.92)
		3:
			return Color(0.88, 0.72, 0.32)
		4:
			return Color(0.72, 0.56, 0.92)
		5:
			return Color(0.78, 0.46, 0.72)
		6:
			return Color(0.88, 0.52, 0.40)
		_:
			return Color(0.72, 0.58, 0.38)
