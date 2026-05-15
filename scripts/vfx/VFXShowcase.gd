class_name VFXShowcase
extends Control

const COMBAT_VFX_SCRIPT := preload("res://scripts/vfx/CombatVFX.gd")

var vfx_layer: Control
var title_label: Label
var loop_timer: Timer
var dummy_cards: Array[PanelContainer] = []
var dummy_targets: Array[PanelContainer] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_stage()
	play_showcase()
	loop_timer = Timer.new()
	loop_timer.name = "ShowcaseLoopTimer"
	loop_timer.wait_time = 2.4
	loop_timer.autostart = true
	loop_timer.timeout.connect(play_showcase)
	add_child(loop_timer)


func play_showcase() -> void:
	if vfx_layer == null:
		return

	var card_a := _center_of(dummy_cards[0])
	var card_b := _center_of(dummy_cards[1])
	var target_a := _center_of(dummy_targets[0])
	var target_b := _center_of(dummy_targets[1])
	var center := get_global_rect().get_center()

	vfx_layer.call("play_card_fly_between", card_a, target_a, Color(0.92, 0.20, 0.14), "Slash", false)
	vfx_layer.call("play_slash_between", card_a, target_a, Color(1.0, 0.22, 0.14))
	vfx_layer.call("play_burst_at", target_a, Color(1.0, 0.24, 0.14), &"blood")

	vfx_layer.call("play_card_fly_between", card_b, target_b, Color(0.45, 0.84, 1.0), "Guard", false)
	vfx_layer.call("play_guard_pulse_at", target_b, Color(0.45, 0.84, 1.0))

	vfx_layer.call("play_chip_burst_on", dummy_cards[2])
	vfx_layer.call("play_curse_smoke_on", dummy_targets[2])
	vfx_layer.call("play_ritual_glow_on", dummy_cards[3])
	vfx_layer.call("play_card_burn_on", dummy_cards[4])

	vfx_layer.call("play_burst_at", center + Vector2(-80, 70), Color(0.82, 0.78, 0.66), &"ash")
	vfx_layer.call("play_link_between_targets", dummy_targets[0], target_b, Color(1.0, 0.78, 0.30))
	vfx_layer.call("play_card_preview_arc", card_b, target_a, Color(0.78, 0.50, 1.0))


func get_showcase_effect_count() -> int:
	return 10


func get_registered_asset_paths() -> Array[String]:
	if vfx_layer == null or not vfx_layer.has_method("get_polish_asset_paths"):
		return []
	return vfx_layer.call("get_polish_asset_paths")


func _build_stage() -> void:
	var background := ColorRect.new()
	background.name = "ShowcaseBackground"
	background.color = Color(0.035, 0.026, 0.024)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	title_label = Label.new()
	title_label.name = "ShowcaseTitle"
	title_label.text = "Dead Man's Ante VFX Table"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.custom_minimum_size = Vector2(0, 58)
	add_child(title_label)

	var rail := HBoxContainer.new()
	rail.name = "ShowcaseCardRail"
	rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rail.offset_left = 80
	rail.offset_right = -80
	rail.offset_top = -150
	rail.offset_bottom = -22
	rail.add_theme_constant_override("separation", 18)
	add_child(rail)

	for index in range(5):
		var card := _make_dummy_panel("Card%d" % index, "CARD", Color(0.18, 0.08, 0.055), Color(0.96, 0.68, 0.24), Vector2(112, 126))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rail.add_child(card)
		dummy_cards.append(card)

	var target_row := HBoxContainer.new()
	target_row.name = "ShowcaseTargetRow"
	target_row.set_anchors_preset(Control.PRESET_CENTER)
	target_row.offset_left = -330
	target_row.offset_right = 330
	target_row.offset_top = -84
	target_row.offset_bottom = 74
	target_row.add_theme_constant_override("separation", 48)
	add_child(target_row)

	for index in range(3):
		var target := _make_dummy_panel("Target%d" % index, "TARGET", Color(0.16, 0.06, 0.05), Color(0.88, 0.22, 0.16), Vector2(180, 126))
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_row.add_child(target)
		dummy_targets.append(target)

	vfx_layer = COMBAT_VFX_SCRIPT.new()
	vfx_layer.name = "CombatVFX"
	add_child(vfx_layer)
	vfx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_dummy_panel(node_name: String, label_text: String, fill: Color, border: Color, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.72))
	panel.add_child(label)
	return panel


func _center_of(item: CanvasItem) -> Vector2:
	if item == null:
		return Vector2.ZERO
	return item.get_global_rect().get_center()
