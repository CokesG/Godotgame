class_name HandView
extends HBoxContainer

signal card_clicked(hand_index: int)

const CARD_VIEW_SCRIPT := preload("res://scripts/ui/CardView.gd")


func _ready() -> void:
	add_theme_constant_override("separation", 8)


func set_cards(cards: Array[Resource]) -> void:
	for child in get_children():
		child.queue_free()

	for index in range(cards.size()):
		var card_view := Button.new()
		card_view.set_script(CARD_VIEW_SCRIPT)
		card_view.call("set_card", cards[index], index)
		card_view.connect("card_pressed", _on_card_pressed)
		add_child(card_view)


func _on_card_pressed(hand_index: int) -> void:
	card_clicked.emit(hand_index)
