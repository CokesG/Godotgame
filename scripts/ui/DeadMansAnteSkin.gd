extends RefCounted
class_name DeadMansAnteSkin

const TABLE_BACKDROP_PATH := "res://art/game/ui/skin/ui_table_backdrop.png"
const PANEL_FRAME_PATH := "res://art/game/ui/skin/ui_panel_velvet_frame.png"
const HEADER_PLAQUE_PATH := "res://art/game/ui/skin/ui_header_plaque.png"
const CUE_PLAQUE_PATH := "res://art/game/ui/skin/ui_cue_plaque.png"
const HAND_RAIL_PATH := "res://art/game/ui/skin/ui_hand_rail.png"
const CARD_FRAME_PATH := "res://art/game/ui/skin/ui_card_frame_common.png"
const BUTTON_NORMAL_PATH := "res://art/game/ui/skin/ui_button_brass_normal.png"
const BUTTON_HOVER_PATH := "res://art/game/ui/skin/ui_button_brass_hover.png"
const BUTTON_PRESSED_PATH := "res://art/game/ui/skin/ui_button_brass_pressed.png"
const BUTTON_DISABLED_PATH := "res://art/game/ui/skin/ui_button_brass_disabled.png"

const TEXT_PRIMARY := Color(0.96, 0.91, 0.82)
const TEXT_MUTED := Color(0.72, 0.70, 0.66)
const TEXT_GOLD := Color(1.0, 0.78, 0.32)
const PANEL_BG := Color(0.070, 0.052, 0.048, 0.94)
const PANEL_BORDER := Color(0.68, 0.50, 0.24)
const BUTTON_BG := Color(0.14, 0.095, 0.070, 0.96)
const BUTTON_ACTIVE_BG := Color(0.30, 0.21, 0.095, 0.98)
const BUTTON_BORDER := Color(0.58, 0.42, 0.20)
const BUTTON_ACTIVE_BORDER := Color(1.0, 0.78, 0.28)


static func apply_to(root: Control) -> void:
	if root == null:
		return

	var theme := Theme.new()
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.72))
	theme.set_font_size("font_size", "Label", 15)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_color("default_color", "RichTextLabel", TEXT_PRIMARY)
	theme.set_color("font_selected_color", "RichTextLabel", TEXT_GOLD)
	theme.set_font_size("normal_font_size", "RichTextLabel", 15)
	theme.set_stylebox("normal", "RichTextLabel", make_flat_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 0, 0))

	theme.set_stylebox("panel", "PanelContainer", make_panel_style(PANEL_BG, PANEL_BORDER))
	theme.set_stylebox("normal", "Button", make_button_style(false))
	theme.set_stylebox("hover", "Button", make_button_style(true))
	theme.set_stylebox("pressed", "Button", make_button_style(true, true))
	theme.set_stylebox("disabled", "Button", make_button_style(false, false, true))
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.76))
	theme.set_color("font_pressed_color", "Button", Color(0.12, 0.075, 0.03))
	theme.set_color("font_disabled_color", "Button", Color(0.48, 0.46, 0.42))
	theme.set_font_size("font_size", "Button", 15)
	theme.set_constant("h_separation", "Button", 6)

	theme.set_stylebox("normal", "OptionButton", make_button_style(false))
	theme.set_stylebox("hover", "OptionButton", make_button_style(true))
	theme.set_stylebox("pressed", "OptionButton", make_button_style(true, true))
	theme.set_stylebox("disabled", "OptionButton", make_button_style(false, false, true))
	theme.set_color("font_color", "OptionButton", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "OptionButton", Color(1.0, 0.94, 0.76))
	theme.set_color("font_disabled_color", "OptionButton", Color(0.48, 0.46, 0.42))

	root.theme = theme


static func apply_panel(panel: PanelContainer, bg_color: Color = PANEL_BG, border_color: Color = PANEL_BORDER, kind: String = "panel") -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", make_panel_style(bg_color, border_color, kind))


static func apply_button(button: Button, active: bool, hint: String = "") -> void:
	if button == null:
		return
	if not hint.is_empty():
		button.tooltip_text = hint
	button.add_theme_stylebox_override("normal", make_button_style(active))
	button.add_theme_stylebox_override("hover", make_button_style(true))
	button.add_theme_stylebox_override("pressed", make_button_style(active, true))
	button.add_theme_stylebox_override("disabled", make_button_style(false, false, true))
	button.add_theme_color_override("font_color", TEXT_PRIMARY if active else TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.76))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.46, 0.42))


static func apply_chip(button: Button, active: bool, color: Color, tooltip: String) -> void:
	if button == null:
		return
	button.tooltip_text = tooltip
	button.add_theme_stylebox_override("normal", make_chip_style(active, color))
	button.add_theme_stylebox_override("hover", make_chip_style(true, color))
	button.add_theme_stylebox_override("pressed", make_chip_style(active, color))
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82) if active else TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.84))


static func make_panel_style(bg_color: Color = PANEL_BG, border_color: Color = PANEL_BORDER, kind: String = "panel") -> StyleBox:
	var texture_path := PANEL_FRAME_PATH
	var texture_margin := 34
	var content_margin := 10
	if kind == "header":
		texture_path = HEADER_PLAQUE_PATH
		texture_margin = 42
		content_margin = 14
	elif kind == "cue":
		texture_path = CUE_PLAQUE_PATH
		texture_margin = 36
		content_margin = 12
	elif kind == "hand":
		texture_path = HAND_RAIL_PATH
		texture_margin = 46
		content_margin = 14

	return make_texture_style(texture_path, bg_color, border_color, texture_margin, content_margin, 6)


static func make_button_style(active: bool, pressed: bool = false, disabled: bool = false) -> StyleBox:
	var path := BUTTON_NORMAL_PATH
	var bg := BUTTON_BG
	var border := BUTTON_BORDER
	if disabled:
		path = BUTTON_DISABLED_PATH
		bg = Color(0.075, 0.075, 0.078, 0.92)
		border = Color(0.26, 0.26, 0.28)
	elif pressed:
		path = BUTTON_PRESSED_PATH
		bg = Color(0.42, 0.14, 0.105, 0.98)
		border = Color(0.92, 0.44, 0.24)
	elif active:
		path = BUTTON_HOVER_PATH
		bg = BUTTON_ACTIVE_BG
		border = BUTTON_ACTIVE_BORDER

	return make_texture_style(path, bg, border, 54, 12, 6)


static func make_chip_style(active: bool, color: Color) -> StyleBox:
	var bg := Color(0.16, 0.115, 0.075, 0.98).lerp(color, 0.16) if active else Color(0.075, 0.075, 0.082, 0.94)
	var border := color if active else Color(0.32, 0.31, 0.31)
	return make_flat_style(bg, border, 5, 2, 7)


static func make_card_style(previewed: bool, card_color: Color, disabled: bool = false) -> StyleBox:
	var bg := Color(0.20, 0.14, 0.10, 0.97) if previewed else Color(0.115, 0.095, 0.080, 0.96)
	var border := Color(1.0, 0.86, 0.36) if previewed else card_color
	if disabled:
		bg = Color(0.070, 0.066, 0.060, 0.92)
		border = Color(0.30, 0.30, 0.32)
	return make_texture_style(CARD_FRAME_PATH, bg, border, 40, 12, 6)


static func make_action_pip_style(color: Color) -> StyleBox:
	return make_flat_style(color, Color(1.0, 0.92, 0.68), 5, 1, 10)


static func make_flat_style(
	bg_color: Color,
	border_color: Color,
	radius: int = 6,
	border_width: int = 2,
	content_margin: int = 8
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


static func make_texture_style(
	path: String,
	bg_color: Color,
	border_color: Color,
	texture_margin: int = 32,
	content_margin: int = 8,
	radius: int = 6
) -> StyleBox:
	if _should_use_runtime_textures() and ResourceLoader.exists(path):
		var texture_resource := load(path)
		if texture_resource is Texture2D:
			var style := StyleBoxTexture.new()
			style.texture = texture_resource
			style.texture_margin_left = texture_margin
			style.texture_margin_top = texture_margin
			style.texture_margin_right = texture_margin
			style.texture_margin_bottom = texture_margin
			style.modulate_color = Color.WHITE.lerp(border_color, 0.10)
			style.content_margin_left = content_margin
			style.content_margin_top = content_margin
			style.content_margin_right = content_margin
			style.content_margin_bottom = content_margin
			return style

	return make_flat_style(bg_color, border_color, radius, 2, content_margin)


static func load_texture(path: String) -> Texture2D:
	if _should_use_runtime_textures() and ResourceLoader.exists(path):
		var texture_resource := load(path)
		if texture_resource is Texture2D:
			return texture_resource
	return null


static func _should_use_runtime_textures() -> bool:
	return DisplayServer.get_name() != "headless"
