class_name CardView
extends Button

const DEAD_MANS_ANTE_SKIN_SCRIPT := preload("res://scripts/ui/DeadMansAnteSkin.gd")

signal card_pressed(hand_index: int)
signal card_hovered(hand_index: int)
signal card_unhovered(hand_index: int)

var card_resource: Resource
var hand_index: int = -1
var is_previewed: bool = false
var is_playable: bool = true
var disabled_reason: String = ""
var hover_tween: Tween
var feedback_tween: Tween
var compact_mode: bool = false


func _ready() -> void:
	_apply_compact_metrics()
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


func set_compact_mode(value: bool) -> void:
	if compact_mode == value:
		return
	compact_mode = value
	_apply_compact_metrics()
	_refresh()


func _on_pressed() -> void:
	card_pressed.emit(hand_index)


func set_previewed(value: bool) -> void:
	if is_previewed == value:
		return
	is_previewed = value
	_refresh()
	_animate_card_focus(is_previewed and is_playable)


func set_playability(value: bool, reason: String = "") -> void:
	is_playable = value
	disabled_reason = reason
	disabled = not is_playable
	_refresh()
	if not is_playable:
		_animate_card_focus(false)


func _on_mouse_entered() -> void:
	card_hovered.emit(hand_index)


func _on_mouse_exited() -> void:
	card_unhovered.emit(hand_index)


func _on_focus_entered() -> void:
	card_hovered.emit(hand_index)


func _on_focus_exited() -> void:
	card_unhovered.emit(hand_index)


func _refresh() -> void:
	_apply_compact_metrics()
	if card_resource == null:
		text = "Empty"
		icon = null
		return

	var card_name := _get_card_name()
	var cost := int(card_resource.get("cost"))
	var rules_text := _shorten_rules_text(String(card_resource.get("rules_text")))
	var type_label := _get_card_type_label()
	var target_label := _get_target_label()
	text = "%s\nCost %d | %s\nTarget: %s\n%s\n%s" % [
		card_name,
		cost,
		type_label,
		target_label,
		rules_text,
		_get_tag_line()
	]
	icon = _get_card_illustration_texture() if _should_load_runtime_art() else null
	expand_icon = icon != null
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	if is_playable:
		tooltip_text = "Click to play %s during Player Commit. Target: %s%s" % [
			card_name,
			target_label,
			_get_tag_tooltip()
		]
	else:
		tooltip_text = "Locked: %s | %s targets %s%s" % [
			disabled_reason,
			card_name,
			target_label,
			_get_tag_tooltip()
		]

	var card_color := _get_card_type_color()
	var style := DEAD_MANS_ANTE_SKIN_SCRIPT.make_card_style(is_previewed, card_color, not is_playable, is_playable)
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", DEAD_MANS_ANTE_SKIN_SCRIPT.make_card_style(true, Color(1.0, 0.86, 0.42), false, true))
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("disabled", DEAD_MANS_ANTE_SKIN_SCRIPT.make_card_style(false, card_color, true, false))
	add_theme_font_size_override("font_size", 12 if compact_mode else 14)
	add_theme_color_override("font_color", Color(1.0, 0.94, 0.74) if is_playable else Color(0.96, 0.91, 0.82))
	add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.78))
	add_theme_color_override("font_disabled_color", Color(0.62, 0.60, 0.56))
	modulate = Color.WHITE if is_playable else Color(1.0, 1.0, 1.0, 0.66)


func _apply_compact_metrics() -> void:
	custom_minimum_size = Vector2(150, 146) if compact_mode else Vector2(168, 188)


func play_feedback(color: Color) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()

	var base_modulate := Color.WHITE if is_playable else Color(1.0, 1.0, 1.0, 0.66)
	modulate = color
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "modulate", base_modulate, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_card_focus(active: bool) -> void:
	if hover_tween != null and hover_tween.is_valid():
		hover_tween.kill()

	pivot_offset = size * 0.5 if size != Vector2.ZERO else custom_minimum_size * 0.5
	z_index = 12 if active else 0
	var target_scale := Vector2(1.08, 1.08) if active else Vector2.ONE
	var target_rotation := -2.0 if active else 0.0
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", target_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "rotation_degrees", target_rotation, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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


func _get_tag_line() -> String:
	var tags_value = card_resource.get("tags")
	if typeof(tags_value) != TYPE_ARRAY:
		return "Tags: None"

	var labels: Array[String] = []
	for tag in tags_value:
		var label := String(tag).capitalize().replace("_", " ")
		if not label.is_empty():
			labels.append(label)
	if labels.is_empty():
		return "Tags: None"
	return "Tags: %s" % ", ".join(labels)


func _get_card_illustration_texture() -> Texture2D:
	if card_resource == null:
		return null
	if card_resource.has_method("get_illustration_texture"):
		return card_resource.call("get_illustration_texture")
	var legacy_value: Variant = card_resource.get("illustration_texture")
	if legacy_value is Texture2D:
		return legacy_value
	return null


func _should_load_runtime_art() -> bool:
	return DisplayServer.get_name() != "headless"


func _shorten_rules_text(rules_text: String) -> String:
	if rules_text.length() <= 58:
		return rules_text
	return "%s..." % rules_text.substr(0, 55)


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
