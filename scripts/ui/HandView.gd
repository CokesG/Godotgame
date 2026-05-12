class_name HandView
extends HBoxContainer

signal card_clicked(hand_index: int)
signal card_previewed(hand_index: int)
signal card_preview_cleared(hand_index: int)

const CARD_VIEW_SCRIPT := preload("res://scripts/ui/CardView.gd")

var compact_mode: bool = false


func _ready() -> void:
	_apply_compact_metrics()


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


func set_compact_mode(value: bool) -> void:
	if compact_mode == value:
		return
	compact_mode = value
	_apply_compact_metrics()
	for child in get_children():
		if child.has_method("set_compact_mode"):
			child.call("set_compact_mode", compact_mode)


func _apply_compact_metrics() -> void:
	add_theme_constant_override("separation", 6 if compact_mode else 8)


func set_previewed_index(hand_index: int) -> void:
	for index in range(get_child_count()):
		var child := get_child(index)
		if child.has_method("set_previewed"):
			child.call("set_previewed", index == hand_index)


func set_card_playability(entries: Array[Dictionary]) -> void:
	for index in range(get_child_count()):
		var child := get_child(index)
		if not child.has_method("set_playability"):
			continue
		var entry: Dictionary = {}
		if index < entries.size() and typeof(entries[index]) == TYPE_DICTIONARY:
			entry = entries[index]
		child.call("set_playability", bool(entry.get("playable", false)), String(entry.get("reason", "Card is locked.")))


func _on_card_pressed(hand_index: int) -> void:
	card_clicked.emit(hand_index)


func _on_card_hovered(hand_index: int) -> void:
	card_previewed.emit(hand_index)


func _on_card_unhovered(hand_index: int) -> void:
	card_preview_cleared.emit(hand_index)
