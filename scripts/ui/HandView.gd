class_name HandView
extends HBoxContainer

signal card_clicked(hand_index: int)
signal card_previewed(hand_index: int)
signal card_preview_cleared(hand_index: int)

const CARD_VIEW_SCRIPT := preload("res://scripts/ui/CardView.gd")

var compact_mode: bool = false


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_compact_metrics()
	_apply_hand_pose.call_deferred()


func set_cards(cards: Array[Resource]) -> void:
	for child in get_children():
		child.queue_free()

	for index in range(cards.size()):
		var card_view := Button.new()
		card_view.set_script(CARD_VIEW_SCRIPT)
		card_view.call("set_card", cards[index], index)
		if card_view.has_method("set_compact_mode"):
			card_view.call("set_compact_mode", compact_mode)
		card_view.connect("card_pressed", _on_card_pressed)
		card_view.connect("card_hovered", _on_card_hovered)
		card_view.connect("card_unhovered", _on_card_unhovered)
		add_child(card_view)
	_apply_hand_pose.call_deferred()


func set_compact_mode(value: bool) -> void:
	if compact_mode == value:
		return
	compact_mode = value
	_apply_compact_metrics()
	for child in get_children():
		if child.has_method("set_compact_mode"):
			child.call("set_compact_mode", compact_mode)
	_apply_hand_pose.call_deferred()


func _apply_compact_metrics() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", -28 if compact_mode else 10)


func _apply_hand_pose() -> void:
	var count := get_child_count()
	if count <= 0:
		return

	var estimated_width := 0.0
	for child in get_children():
		if child is Control:
			estimated_width += (child as Control).custom_minimum_size.x
	if count > 1:
		estimated_width += float(count - 1) * float(get_theme_constant("separation"))
	var parent_control := get_parent() as Control
	if parent_control != null and parent_control.size.x > 1.0:
		custom_minimum_size.x = max(parent_control.size.x, estimated_width)

	var center := float(count - 1) * 0.5
	for index in range(count):
		var child := get_child(index)
		if not (child is Control):
			continue
		var control := child as Control
		var distance_from_center := float(index) - center
		if compact_mode:
			control.rotation_degrees = clamp(distance_from_center * 5.0, -12.0, 12.0)
			control.position.y = 10.0 + abs(distance_from_center) * 7.0
			control.z_index = index + 4
		else:
			control.rotation_degrees = clamp(distance_from_center * 2.0, -5.0, 5.0)
			control.position.y = abs(distance_from_center) * 4.0
			control.z_index = 0


func set_previewed_index(hand_index: int) -> void:
	for index in range(get_child_count()):
		var child := get_child(index)
		if child.has_method("set_previewed"):
			child.call("set_previewed", index == hand_index)
	_apply_hand_pose.call_deferred()


func set_card_playability(entries: Array[Dictionary]) -> void:
	for index in range(get_child_count()):
		var child := get_child(index)
		if not child.has_method("set_playability"):
			continue
		var entry: Dictionary = {}
		if index < entries.size() and typeof(entries[index]) == TYPE_DICTIONARY:
			entry = entries[index]
		child.call("set_playability", bool(entry.get("playable", false)), String(entry.get("reason", "Card is locked.")))


func set_card_recommendations(entries: Array[Dictionary]) -> void:
	for index in range(get_child_count()):
		var child := get_child(index)
		if not child.has_method("set_loadout_recommendation"):
			continue
		var entry: Dictionary = {}
		if index < entries.size() and typeof(entries[index]) == TYPE_DICTIONARY:
			entry = entries[index]
		child.call("set_loadout_recommendation", String(entry.get("badge", "")), String(entry.get("reason", "")))


func _on_card_pressed(hand_index: int) -> void:
	card_clicked.emit(hand_index)


func _on_card_hovered(hand_index: int) -> void:
	card_previewed.emit(hand_index)


func _on_card_unhovered(hand_index: int) -> void:
	card_preview_cleared.emit(hand_index)
