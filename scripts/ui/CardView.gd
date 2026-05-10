class_name CardView
extends Button

signal card_pressed(hand_index: int)

var card_resource: Resource
var hand_index: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(132, 176)
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	_refresh()


func set_card(card: Resource, index: int) -> void:
	card_resource = card
	hand_index = index
	_refresh()


func _on_pressed() -> void:
	card_pressed.emit(hand_index)


func _refresh() -> void:
	if card_resource == null:
		text = "Empty"
		return

	var card_name := _get_card_name()
	var cost := int(card_resource.get("cost"))
	var rules_text := String(card_resource.get("rules_text"))
	var type_label := _get_card_type_label()
	text = "%s\nCost %d\n%s\n\n%s" % [card_name, cost, type_label, rules_text]
	tooltip_text = "Click to play %s" % card_name

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.bg_color = Color(0.16, 0.14, 0.12)
	style.border_color = Color(0.72, 0.58, 0.38)
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
