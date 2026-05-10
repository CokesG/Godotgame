extends Control

const COMBAT_GRID_SCRIPT := preload("res://scripts/grid/CombatGrid.gd")
const BLUFF_SYSTEM_SCRIPT := preload("res://scripts/combat/BluffSystem.gd")
const COMBAT_RESOLVER_SCRIPT := preload("res://scripts/combat/CombatResolver.gd")
const COMBAT_SESSION_SCRIPT := preload("res://scripts/combat/CombatSession.gd")
const DECK_MANAGER_SCRIPT := preload("res://scripts/cards/DeckManager.gd")
const ENEMY_INTENT_SYSTEM_SCRIPT := preload("res://scripts/enemies/EnemyIntentSystem.gd")
const HAND_VIEW_SCRIPT := preload("res://scripts/ui/HandView.gd")
const STARTER_CARD_PATHS := [
	"res://resources/cards/quick_slash.tres",
	"res://resources/cards/low_stab.tres",
	"res://resources/cards/guard_up.tres",
	"res://resources/cards/iron_vow.tres",
	"res://resources/cards/sidestep.tres",
	"res://resources/cards/hook_step.tres",
	"res://resources/cards/read_tell.tres",
	"res://resources/cards/false_opening.tres",
	"res://resources/cards/snare_card.tres",
	"res://resources/cards/blood_ritual.tres"
]
const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]
const PHASE_ACTION_LABELS := {
	"START_TURN": "Start Draw",
	"DRAW": "Read Intents",
	"ENEMY_INTENT_PREVIEW": "Commit Cards",
	"PLAYER_COMMIT": "End Commit",
	"BLUFF_WAGER": "Reveal",
	"REVEAL": "Continue",
	"RESOLVE": "Cleanup",
	"CLEANUP": "Next Turn"
}
const PHASE_GUIDANCE := {
	"START_TURN": {
		"title": "Start Turn",
		"detail": "Energy refreshes. Continue to fill the hand."
	},
	"DRAW": {
		"title": "Draw",
		"detail": "The hand fills toward five cards automatically."
	},
	"ENEMY_INTENT_PREVIEW": {
		"title": "Read",
		"detail": "Compare enemy odds and tells before committing."
	},
	"PLAYER_COMMIT": {
		"title": "Commit",
		"detail": "Choose targets, click cards to play them, or commit the first card face-down."
	},
	"BLUFF_WAGER": {
		"title": "Bluff",
		"detail": "Set a call, raise if confident, or fold the committed card."
	},
	"REVEAL": {
		"title": "Reveal",
		"detail": "Enemy intent and committed cards resolve once this phase begins."
	},
	"RESOLVE": {
		"title": "Resolve",
		"detail": "Review HP, Guard, traps, and the combat log."
	},
	"CLEANUP": {
		"title": "Cleanup",
		"detail": "Leftover hand cards are discarded before the next turn."
	}
}
const RECIPE_STEPS := [
	{
		"id": "read_intents",
		"label": "Read one enemy intent preview"
	},
	{
		"id": "play_or_commit",
		"label": "Play a card or commit one face-down"
	},
	{
		"id": "bluff_choice",
		"label": "Set a call, raise, or fold"
	},
	{
		"id": "reveal_resolve",
		"label": "Resolve the reveal"
	},
	{
		"id": "cleanup",
		"label": "Clean up and start the next turn"
	}
]

@onready var turn_manager: Node = $TurnManager

var phase_label: Label
var turn_label: Label
var log_label: RichTextLabel
var combat_grid: Control
var bluff_system: Node
var combat_resolver: Node
var combat_session: Node
var deck_manager: Node
var enemy_intent_system: Node
var hand_view: HBoxContainer
var pile_counts_label: Label
var resource_state_label: Label
var phase_guidance_label: Label
var phase_detail_label: Label
var recipe_label: RichTextLabel
var combat_state_label: RichTextLabel
var bluff_state_label: RichTextLabel
var enemy_call_option: OptionButton
var intent_call_option: OptionButton
var lane_call_option: OptionButton
var target_enemy_option: OptionButton
var movement_cell_option: OptionButton
var intent_preview_label: RichTextLabel
var truth_title_label: Label
var debug_truth_label: RichTextLabel
var debug_controls: HBoxContainer
var next_phase_button: Button
var reset_button: Button
var toggle_debug_button: Button
var reset_grid_button: Button
var draw_button: Button
var discard_hand_button: Button
var reset_deck_button: Button
var roll_intents_button: Button
var reveal_intents_button: Button
var toggle_truth_button: Button
var commit_first_card_button: Button
var set_call_button: Button
var raise_button: Button
var fold_button: Button
var reset_bluff_button: Button
var debug_controls_visible: bool = false
var debug_truth_visible: bool = false
var current_intent_previews: Array[Dictionary] = []
var reveal_resolved_this_phase: bool = false
var recipe_progress: Dictionary = {}
var pending_card_context: Dictionary = {}
var committed_card_context: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_connect_turn_manager()
	log_label.clear()
	_reset_playable_combat()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.name = "RootMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Dead Man's Ante - Test Combat Harness"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Phase 10 makes enemy intent positional: lanes, traps, dodges, and called reads matter."
	subtitle.add_theme_font_size_override("font_size", 16)
	layout.add_child(subtitle)

	turn_label = Label.new()
	turn_label.text = "Turn: -"
	turn_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(turn_label)

	phase_label = Label.new()
	phase_label.text = "Phase: -"
	phase_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(phase_label)

	resource_state_label = Label.new()
	resource_state_label.text = "Energy: -"
	resource_state_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(resource_state_label)

	var guidance_panel := PanelContainer.new()
	guidance_panel.name = "TurnGuidance"
	guidance_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(guidance_panel)

	var guidance_layout := VBoxContainer.new()
	guidance_layout.name = "GuidanceLayout"
	guidance_layout.add_theme_constant_override("separation", 4)
	guidance_panel.add_child(guidance_layout)

	phase_guidance_label = Label.new()
	phase_guidance_label.name = "PhaseGuidance"
	phase_guidance_label.text = "Start Turn"
	phase_guidance_label.add_theme_font_size_override("font_size", 20)
	guidance_layout.add_child(phase_guidance_label)

	phase_detail_label = Label.new()
	phase_detail_label.name = "PhaseDetail"
	phase_detail_label.text = "Energy refreshes. Continue to fill the hand."
	phase_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance_layout.add_child(phase_detail_label)

	var recipe_panel := PanelContainer.new()
	recipe_panel.name = "RecipePanel"
	recipe_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(recipe_panel)

	recipe_label = RichTextLabel.new()
	recipe_label.name = "RecipeLabel"
	recipe_label.bbcode_enabled = false
	recipe_label.fit_content = true
	recipe_label.scroll_active = false
	recipe_label.custom_minimum_size = Vector2(0, 118)
	recipe_panel.add_child(recipe_label)

	var primary_controls := HBoxContainer.new()
	primary_controls.name = "PrimaryControls"
	primary_controls.add_theme_constant_override("separation", 8)
	layout.add_child(primary_controls)

	next_phase_button = Button.new()
	next_phase_button.name = "ContinueButton"
	next_phase_button.text = "Start Draw"
	next_phase_button.pressed.connect(_on_next_phase_pressed)
	primary_controls.add_child(next_phase_button)

	reset_button = Button.new()
	reset_button.name = "NewCombatButton"
	reset_button.text = "New Combat"
	reset_button.pressed.connect(_on_reset_pressed)
	primary_controls.add_child(reset_button)

	toggle_debug_button = Button.new()
	toggle_debug_button.name = "ToggleDebugButton"
	toggle_debug_button.text = "Show Debug"
	toggle_debug_button.pressed.connect(_on_toggle_debug_pressed)
	primary_controls.add_child(toggle_debug_button)

	debug_controls = HBoxContainer.new()
	debug_controls.name = "DebugControls"
	debug_controls.add_theme_constant_override("separation", 8)
	layout.add_child(debug_controls)

	reset_grid_button = Button.new()
	reset_grid_button.text = "Reset Grid"
	reset_grid_button.pressed.connect(_on_reset_grid_pressed)
	debug_controls.add_child(reset_grid_button)

	draw_button = Button.new()
	draw_button.text = "Draw 5"
	draw_button.pressed.connect(_on_draw_pressed)
	debug_controls.add_child(draw_button)

	discard_hand_button = Button.new()
	discard_hand_button.text = "Discard Hand"
	discard_hand_button.pressed.connect(_on_discard_hand_pressed)
	debug_controls.add_child(discard_hand_button)

	reset_deck_button = Button.new()
	reset_deck_button.text = "Reset Deck"
	reset_deck_button.pressed.connect(_on_reset_deck_pressed)
	debug_controls.add_child(reset_deck_button)

	roll_intents_button = Button.new()
	roll_intents_button.text = "Roll Intents"
	roll_intents_button.pressed.connect(_on_roll_intents_pressed)
	debug_controls.add_child(roll_intents_button)

	reveal_intents_button = Button.new()
	reveal_intents_button.text = "Reveal Intents"
	reveal_intents_button.pressed.connect(_on_reveal_intents_pressed)
	debug_controls.add_child(reveal_intents_button)

	toggle_truth_button = Button.new()
	toggle_truth_button.text = "Show Truth"
	toggle_truth_button.pressed.connect(_on_toggle_truth_pressed)
	debug_controls.add_child(toggle_truth_button)

	var body := HBoxContainer.new()
	body.name = "CombatBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	layout.add_child(body)

	combat_grid = Control.new()
	combat_grid.name = "CombatGrid"
	combat_grid.set_script(COMBAT_GRID_SCRIPT)
	body.add_child(combat_grid)

	var intent_column := VBoxContainer.new()
	intent_column.name = "IntentColumn"
	intent_column.custom_minimum_size = Vector2(340, 0)
	intent_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intent_column.add_theme_constant_override("separation", 8)
	body.add_child(intent_column)

	var intent_title := Label.new()
	intent_title.text = "Enemy Intent Preview"
	intent_title.add_theme_font_size_override("font_size", 18)
	intent_column.add_child(intent_title)

	intent_preview_label = RichTextLabel.new()
	intent_preview_label.name = "IntentPreview"
	intent_preview_label.bbcode_enabled = false
	intent_preview_label.fit_content = false
	intent_preview_label.custom_minimum_size = Vector2(320, 230)
	intent_preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intent_column.add_child(intent_preview_label)

	var target_title := Label.new()
	target_title.text = "Card Targets"
	target_title.add_theme_font_size_override("font_size", 18)
	intent_column.add_child(target_title)

	target_enemy_option = OptionButton.new()
	target_enemy_option.name = "TargetEnemyOption"
	intent_column.add_child(target_enemy_option)

	movement_cell_option = OptionButton.new()
	movement_cell_option.name = "MovementCellOption"
	intent_column.add_child(movement_cell_option)

	truth_title_label = Label.new()
	truth_title_label.name = "DebugTruthTitle"
	truth_title_label.text = "Debug Truth"
	truth_title_label.add_theme_font_size_override("font_size", 18)
	intent_column.add_child(truth_title_label)

	debug_truth_label = RichTextLabel.new()
	debug_truth_label.name = "DebugTruth"
	debug_truth_label.bbcode_enabled = false
	debug_truth_label.fit_content = false
	debug_truth_label.custom_minimum_size = Vector2(320, 170)
	debug_truth_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intent_column.add_child(debug_truth_label)

	var bluff_title := Label.new()
	bluff_title.text = "Commit / Bluff / Reveal"
	bluff_title.add_theme_font_size_override("font_size", 18)
	intent_column.add_child(bluff_title)

	bluff_state_label = RichTextLabel.new()
	bluff_state_label.name = "BluffState"
	bluff_state_label.bbcode_enabled = false
	bluff_state_label.fit_content = false
	bluff_state_label.custom_minimum_size = Vector2(320, 120)
	intent_column.add_child(bluff_state_label)

	enemy_call_option = OptionButton.new()
	enemy_call_option.item_selected.connect(_on_enemy_call_selected)
	intent_column.add_child(enemy_call_option)

	intent_call_option = OptionButton.new()
	intent_column.add_child(intent_call_option)

	lane_call_option = OptionButton.new()
	lane_call_option.add_item("Any Lane")
	lane_call_option.set_item_metadata(0, -1)
	for lane in range(3):
		lane_call_option.add_item("Lane %d" % lane)
		lane_call_option.set_item_metadata(lane + 1, lane)
	intent_column.add_child(lane_call_option)

	var bluff_buttons := HBoxContainer.new()
	bluff_buttons.name = "BluffButtons"
	bluff_buttons.add_theme_constant_override("separation", 6)
	intent_column.add_child(bluff_buttons)

	commit_first_card_button = Button.new()
	commit_first_card_button.text = "Commit First"
	commit_first_card_button.pressed.connect(_on_commit_first_card_pressed)
	bluff_buttons.add_child(commit_first_card_button)

	set_call_button = Button.new()
	set_call_button.text = "Set Call"
	set_call_button.pressed.connect(_on_set_call_pressed)
	bluff_buttons.add_child(set_call_button)

	raise_button = Button.new()
	raise_button.text = "Raise +1"
	raise_button.pressed.connect(_on_raise_pressed)
	bluff_buttons.add_child(raise_button)

	fold_button = Button.new()
	fold_button.text = "Fold"
	fold_button.pressed.connect(_on_fold_pressed)
	bluff_buttons.add_child(fold_button)

	reset_bluff_button = Button.new()
	reset_bluff_button.text = "Reset Bluff"
	reset_bluff_button.pressed.connect(_on_reset_bluff_pressed)
	intent_column.add_child(reset_bluff_button)

	var log_column := VBoxContainer.new()
	log_column.name = "LogColumn"
	log_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_column.add_theme_constant_override("separation", 8)
	body.add_child(log_column)

	var log_title := Label.new()
	log_title.text = "Combat Log"
	log_title.add_theme_font_size_override("font_size", 18)
	log_column.add_child(log_title)

	var state_title := Label.new()
	state_title.text = "Combat State"
	state_title.add_theme_font_size_override("font_size", 18)
	log_column.add_child(state_title)

	combat_state_label = RichTextLabel.new()
	combat_state_label.name = "CombatState"
	combat_state_label.bbcode_enabled = false
	combat_state_label.fit_content = false
	combat_state_label.custom_minimum_size = Vector2(0, 160)
	log_column.add_child(combat_state_label)

	log_label = RichTextLabel.new()
	log_label.name = "CombatLog"
	log_label.bbcode_enabled = false
	log_label.fit_content = false
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size = Vector2(0, 320)
	log_column.add_child(log_label)
	combat_grid.connect("log_requested", _on_log_requested)
	combat_grid.connect("unit_moved", _on_grid_unit_moved)

	var deck_panel := VBoxContainer.new()
	deck_panel.name = "DeckPanel"
	deck_panel.add_theme_constant_override("separation", 8)
	layout.add_child(deck_panel)

	pile_counts_label = Label.new()
	pile_counts_label.text = "Draw: 0 | Hand: 0 | Discard: 0 | Exhaust: 0"
	pile_counts_label.add_theme_font_size_override("font_size", 16)
	deck_panel.add_child(pile_counts_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.custom_minimum_size = Vector2(0, 196)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_panel.add_child(hand_scroll)

	hand_view = HBoxContainer.new()
	hand_view.name = "HandView"
	hand_view.set_script(HAND_VIEW_SCRIPT)
	hand_scroll.add_child(hand_view)

	deck_manager = Node.new()
	deck_manager.name = "DeckManager"
	deck_manager.set_script(DECK_MANAGER_SCRIPT)
	add_child(deck_manager)
	deck_manager.connect("log_requested", _on_log_requested)
	deck_manager.connect("hand_changed", _on_hand_changed)
	deck_manager.connect("piles_changed", _on_piles_changed)
	deck_manager.connect("card_played", _on_card_played)
	hand_view.connect("card_clicked", _on_card_clicked)

	enemy_intent_system = Node.new()
	enemy_intent_system.name = "EnemyIntentSystem"
	enemy_intent_system.set_script(ENEMY_INTENT_SYSTEM_SCRIPT)
	add_child(enemy_intent_system)
	enemy_intent_system.connect("log_requested", _on_log_requested)
	enemy_intent_system.connect("previews_changed", _on_intent_previews_changed)
	enemy_intent_system.connect("debug_truth_changed", _on_debug_truth_changed)
	enemy_intent_system.connect("intents_revealed", _on_intents_revealed)

	bluff_system = Node.new()
	bluff_system.name = "BluffSystem"
	bluff_system.set_script(BLUFF_SYSTEM_SCRIPT)
	add_child(bluff_system)
	bluff_system.connect("log_requested", _on_log_requested)
	bluff_system.connect("state_changed", _on_bluff_state_changed)

	combat_resolver = Node.new()
	combat_resolver.name = "CombatResolver"
	combat_resolver.set_script(COMBAT_RESOLVER_SCRIPT)
	add_child(combat_resolver)
	combat_resolver.connect("log_requested", _on_log_requested)
	combat_resolver.connect("state_changed", _on_combat_state_changed)
	combat_resolver.connect("combat_ended", _on_combat_ended)

	combat_session = Node.new()
	combat_session.name = "CombatSession"
	combat_session.set_script(COMBAT_SESSION_SCRIPT)
	add_child(combat_session)
	combat_session.connect("log_requested", _on_log_requested)
	combat_session.connect("state_changed", _on_session_state_changed)
	_update_debug_visibility()


func _connect_turn_manager() -> void:
	turn_manager.phase_changed.connect(_on_phase_changed)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.log_requested.connect(_on_log_requested)


func _on_phase_changed(new_phase: int) -> void:
	phase_label.text = "Phase: %s" % turn_manager.get_phase_display(new_phase)
	var phase_key: String = turn_manager.get_phase_key(new_phase)
	reveal_resolved_this_phase = false
	combat_session.call("enter_phase", phase_key, turn_manager.turn_number)

	if phase_key == "DRAW":
		_draw_to_hand_target()
	if phase_key == "ENEMY_INTENT_PREVIEW":
		enemy_intent_system.call("roll_intents")
		_mark_recipe_step("read_intents")
	elif phase_key == "REVEAL":
		_resolve_reveal()
	elif phase_key == "CLEANUP":
		_cleanup_turn()

	_refresh_action_controls()


func _on_turn_started(new_turn_number: int) -> void:
	turn_label.text = "Turn: %d" % new_turn_number


func _on_turn_ended(ended_turn_number: int) -> void:
	_append_log("Turn %d complete." % ended_turn_number)


func _on_log_requested(message: String) -> void:
	_append_log(message)


func _on_next_phase_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset to start a new loop.")
		return
	turn_manager.advance_phase()


func _on_reset_pressed() -> void:
	log_label.clear()
	_reset_playable_combat()


func _on_reset_grid_pressed() -> void:
	combat_grid.call("reset_grid")


func _on_draw_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset before drawing.")
		return
	deck_manager.call("draw_cards", 5)


func _on_discard_hand_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset before discarding.")
		return
	deck_manager.call("discard_hand")


func _on_reset_deck_pressed() -> void:
	_reset_deck_and_draw_opening_hand()


func _on_roll_intents_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset before rolling intents.")
		return
	enemy_intent_system.call("roll_intents")


func _on_reveal_intents_pressed() -> void:
	if not bool(combat_session.call("can_reveal")):
		_append_log("Reveal is only available during the Reveal phase.")
		return
	if reveal_resolved_this_phase:
		_append_log("Reveal already resolved for this phase.")
		return
	_resolve_reveal()


func _on_toggle_truth_pressed() -> void:
	debug_truth_visible = not debug_truth_visible
	_update_debug_visibility()


func _on_toggle_debug_pressed() -> void:
	debug_controls_visible = not debug_controls_visible
	_update_debug_visibility()


func _on_card_clicked(hand_index: int) -> void:
	if not bool(combat_session.call("can_play_cards")):
		_append_log("Cards can only be played during Player Commit.")
		return

	var card: Resource = deck_manager.call("get_card_at", hand_index)
	if card == null:
		_append_log("No card at hand index %d." % hand_index)
		return

	var cost := _get_card_cost(card)
	var card_name := _get_card_name(card)
	pending_card_context = _build_card_context(card)
	if not _validate_card_context(card, pending_card_context):
		pending_card_context.clear()
		return

	if not bool(combat_session.call("spend_energy", cost, card_name)):
		pending_card_context.clear()
		return

	if not bool(deck_manager.call("play_card_at", hand_index)):
		combat_session.call("refund_energy", cost, "%s failed to play" % card_name)
		pending_card_context.clear()
	else:
		_mark_recipe_step("play_or_commit")


func _on_card_played(card: Resource) -> void:
	if _is_movement_card(card):
		_resolve_movement_card(card, pending_card_context)
	else:
		combat_resolver.call("apply_card_with_context", card, pending_card_context)
	pending_card_context.clear()
	_refresh_targeting_options()


func _on_commit_first_card_pressed() -> void:
	if not bool(combat_session.call("can_play_cards")):
		_append_log("Cards can only be committed during Player Commit.")
		return

	if bool(deck_manager.call("has_committed_card")):
		_append_log("Resolve or fold the committed card before committing another.")
		return

	var card: Resource = deck_manager.call("get_card_at", 0)
	if card == null:
		_append_log("No first card in hand to commit.")
		return

	var cost := _get_card_cost(card)
	var card_name := _get_card_name(card)
	var context: Dictionary = _build_card_context(card)
	if not _validate_card_context(card, context):
		return

	if not bool(combat_session.call("spend_energy", cost, "Commit %s" % card_name)):
		return

	var committed: Resource = deck_manager.call("commit_card_at", 0)
	if committed != null:
		committed_card_context = context.duplicate()
		bluff_system.call("set_committed_card", committed)
		_mark_recipe_step("play_or_commit")
	else:
		combat_session.call("refund_energy", cost, "Commit failed")


func _on_set_call_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Calls can only be set during Bluff Wager.")
		return

	var enemy_metadata = _get_selected_metadata(enemy_call_option)
	var intent_metadata = _get_selected_metadata(intent_call_option)
	var lane_metadata = _get_selected_metadata(lane_call_option)

	if typeof(enemy_metadata) != TYPE_DICTIONARY or typeof(intent_metadata) != TYPE_DICTIONARY:
		_append_log("Choose an enemy and intent before setting a call.")
		return

	bluff_system.call("set_call",
		StringName(enemy_metadata.get("enemy_id", &"")),
		String(enemy_metadata.get("enemy_name", "Enemy")),
		StringName(intent_metadata.get("intent_id", &"")),
		String(intent_metadata.get("intent_name", "Intent")),
		int(lane_metadata)
	)
	_mark_recipe_step("bluff_choice")


func _on_raise_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Raise is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("raise_wager", 1)):
		_mark_recipe_step("bluff_choice")


func _on_fold_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Fold is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("fold")):
		deck_manager.call("fold_committed_card")
		committed_card_context.clear()
		_mark_recipe_step("bluff_choice")


func _on_reset_bluff_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset combat to reset bluff state.")
		return
	bluff_system.call("reset_bluff")


func _on_hand_changed(cards: Array[Resource]) -> void:
	hand_view.call("set_cards", cards)


func _on_piles_changed(counts: Dictionary) -> void:
	pile_counts_label.text = "Draw: %d | Hand: %d | Discard: %d | Exhaust: %d | Committed: %d" % [
		counts.get("draw", 0),
		counts.get("hand", 0),
		counts.get("discard", 0),
		counts.get("exhaust", 0),
		counts.get("committed", 0)
	]
	_refresh_action_controls()


func _reset_playable_combat() -> void:
	_reset_recipe_progress()
	pending_card_context.clear()
	committed_card_context.clear()
	combat_session.call("reset_session")
	combat_grid.call("reset_grid")
	_reset_combat_state()
	_reset_deck_and_draw_opening_hand()
	_reset_enemy_intents()
	bluff_system.call("reset_bluff")
	turn_manager.reset_combat()
	_refresh_action_controls()


func _reset_deck_and_draw_opening_hand() -> void:
	deck_manager.call("configure_deck", STARTER_CARD_PATHS)
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", 5)


func _reset_enemy_intents() -> void:
	enemy_intent_system.call("configure_enemies", ENEMY_PATHS)
	enemy_intent_system.call("roll_intents")


func _reset_combat_state() -> void:
	combat_resolver.call("reset_combat", ENEMY_PATHS)


func _draw_to_hand_target() -> void:
	var counts: Dictionary = deck_manager.call("get_counts")
	var hand_target: int = int(combat_session.get("hand_target"))
	var missing_cards: int = max(0, hand_target - int(counts.get("hand", 0)))
	if missing_cards == 0:
		_append_log("Draw phase: hand already at target.")
		return

	deck_manager.call("draw_cards", missing_cards)


func _cleanup_turn() -> void:
	if bool(deck_manager.call("has_committed_card")):
		_append_log("Cleanup found a committed card; resolving it into discard before ending turn.")
		deck_manager.call("resolve_committed_card")
		committed_card_context.clear()

	deck_manager.call("discard_hand")
	_mark_recipe_step("cleanup")
	_append_log("Cleanup complete. Advance to begin the next turn.")


func _on_intent_previews_changed(previews: Array[Dictionary]) -> void:
	current_intent_previews = previews.duplicate()
	intent_preview_label.clear()
	for preview in previews:
		intent_preview_label.append_text("%s\n" % preview.get("enemy_name", "Enemy"))
		var options: Array = preview.get("options", [])
		for option in options:
			intent_preview_label.append_text("  %d%% %s\n" % [
				option.get("percentage", 0),
				option.get("summary", "Unknown intent")
			])
		var tell := String(preview.get("tell", ""))
		if not tell.is_empty():
			intent_preview_label.append_text("  Tell: %s\n" % tell)
		intent_preview_label.append_text("\n")
	_refresh_enemy_call_options()


func _on_debug_truth_changed(truth: Array[Dictionary]) -> void:
	debug_truth_label.clear()
	for entry in truth:
		debug_truth_label.append_text("%s -> %s\n" % [
			entry.get("enemy_name", "Enemy"),
			entry.get("intent_name", "None")
		])
		debug_truth_label.append_text("  %s\n\n" % entry.get("hidden_text", "No hidden intent selected."))


func _on_intents_revealed(revealed: Array[Dictionary]) -> void:
	if revealed.is_empty():
		_append_log("Reveal: no enemy intents selected.")


func _on_bluff_state_changed(state: Dictionary) -> void:
	bluff_state_label.clear()
	bluff_state_label.append_text("Nerve: %d\n" % state.get("nerve", 0))
	bluff_state_label.append_text("Wager: %d\n" % state.get("current_wager", 0))
	bluff_state_label.append_text("Committed: %s\n" % state.get("committed_card_name", "None"))
	bluff_state_label.append_text("Call: %s\n" % state.get("call_summary", "No call set."))
	bluff_state_label.append_text("Last: %s" % state.get("last_result", "None"))


func _on_combat_state_changed(state: Dictionary) -> void:
	combat_state_label.clear()
	var player: Dictionary = state.get("player", {})
	combat_state_label.append_text("%s HP %d/%d | Guard %d\n" % [
		player.get("name", "Player"),
		player.get("hp", 0),
		player.get("max_hp", 0),
		player.get("guard", 0)
	])

	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		var alive_text := "alive" if bool(enemy.get("alive", false)) else "defeated"
		combat_state_label.append_text("%s HP %d/%d | Guard %d | %s\n" % [
			enemy.get("name", "Enemy"),
			enemy.get("hp", 0),
			enemy.get("max_hp", 0),
			enemy.get("guard", 0),
			alive_text
		])

	combat_state_label.append_text("Traps: %d%s | Outcome: %s" % [
		state.get("traps_armed", 0),
		_get_trap_cells_text(state.get("trap_cells", [])),
		state.get("outcome", "ongoing")
	])
	_refresh_targeting_options()
	_refresh_action_controls()


func _on_combat_ended(outcome: String) -> void:
	_append_log("Combat ended: %s." % outcome)
	combat_session.call("mark_combat_ended", outcome)
	_refresh_action_controls()


func _on_session_state_changed(state: Dictionary) -> void:
	resource_state_label.text = "Energy: %d/%d | Phase Gate: %s | Loop: %s" % [
		state.get("energy", 0),
		state.get("max_energy", 0),
		state.get("current_phase_key", "UNKNOWN"),
		state.get("outcome", "ongoing")
	]
	_refresh_action_controls()


func _on_grid_unit_moved(_unit_id: StringName, _from_cell: Vector2i, _to_cell: Vector2i) -> void:
	_refresh_targeting_options()


func _on_enemy_call_selected(_index: int) -> void:
	_refresh_intent_call_options()


func _resolve_reveal() -> void:
	if reveal_resolved_this_phase:
		return

	reveal_resolved_this_phase = true
	var revealed: Array = enemy_intent_system.call("reveal_intents")
	bluff_system.call("reveal", revealed)
	if bool(deck_manager.call("has_committed_card")):
		var resolved_card: Resource = deck_manager.call("resolve_committed_card")
		if resolved_card != null:
			if _is_movement_card(resolved_card):
				_resolve_movement_card(resolved_card, committed_card_context)
			else:
				combat_resolver.call("apply_card_with_context", resolved_card, committed_card_context)
			committed_card_context.clear()
	var bluff_state: Dictionary = bluff_system.call("get_state")
	combat_resolver.call("apply_revealed_intents_with_context", revealed, _build_reveal_context(bluff_state))
	_mark_recipe_step("reveal_resolve")
	_refresh_action_controls()


func _refresh_action_controls() -> void:
	if next_phase_button == null or combat_session == null:
		return

	var can_debug_adjust := bool(combat_session.call("can_debug_adjust"))
	var can_play := bool(combat_session.call("can_play_cards"))
	var can_bluff := bool(combat_session.call("can_bluff"))
	var can_reveal := bool(combat_session.call("can_reveal"))
	var has_committed := bool(deck_manager.call("has_committed_card")) if deck_manager != null else false
	var phase_key: String = String(combat_session.get("current_phase_key"))

	next_phase_button.disabled = not can_debug_adjust
	next_phase_button.text = "Combat Over" if not can_debug_adjust else String(PHASE_ACTION_LABELS.get(phase_key, "Continue"))
	reset_grid_button.disabled = not can_debug_adjust
	draw_button.disabled = not can_debug_adjust
	discard_hand_button.disabled = not can_debug_adjust
	reset_deck_button.disabled = not can_debug_adjust
	roll_intents_button.disabled = not can_debug_adjust
	reveal_intents_button.disabled = not can_reveal or reveal_resolved_this_phase

	commit_first_card_button.disabled = not can_play or has_committed
	set_call_button.disabled = not can_bluff
	raise_button.disabled = not can_bluff or not has_committed
	fold_button.disabled = not can_bluff or not has_committed
	reset_bluff_button.disabled = not can_debug_adjust
	_refresh_guidance()


func _refresh_targeting_options() -> void:
	if target_enemy_option == null or movement_cell_option == null or combat_resolver == null or combat_grid == null:
		return

	var selected_enemy_id: StringName = _get_selected_enemy_target_id()
	target_enemy_option.clear()
	var targets: Array = combat_resolver.call("get_alive_enemy_targets")
	for target in targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		target_enemy_option.add_item("%s HP %d/%d" % [
			target.get("name", "Enemy"),
			target.get("hp", 0),
			target.get("max_hp", 0)
		])
		target_enemy_option.set_item_metadata(target_enemy_option.item_count - 1, target)
		if StringName(target.get("id", &"")) == selected_enemy_id:
			target_enemy_option.select(target_enemy_option.item_count - 1)

	if target_enemy_option.item_count == 0:
		target_enemy_option.add_item("No living enemies")
		target_enemy_option.set_item_metadata(0, {})
	elif target_enemy_option.selected < 0:
		target_enemy_option.select(0)

	var selected_cell: Vector2i = _get_selected_move_cell()
	movement_cell_option.clear()
	var move_cells: Array = combat_grid.call("get_empty_adjacent_cells_for", &"player")
	for cell in move_cells:
		if typeof(cell) != TYPE_VECTOR2I:
			continue
		movement_cell_option.add_item("Move to %s" % combat_grid.call("format_cell", cell))
		movement_cell_option.set_item_metadata(movement_cell_option.item_count - 1, cell)
		if cell == selected_cell:
			movement_cell_option.select(movement_cell_option.item_count - 1)

	if movement_cell_option.item_count == 0:
		movement_cell_option.add_item("No legal move")
		movement_cell_option.set_item_metadata(0, Vector2i(-1, -1))
	elif movement_cell_option.selected < 0:
		movement_cell_option.select(0)


func _build_card_context(card: Resource) -> Dictionary:
	var target_enemy: Dictionary = _get_selected_enemy_target()
	var target_cell: Vector2i = _get_selected_move_cell()
	var target_enemy_id: StringName = StringName(target_enemy.get("id", &""))
	var target_enemy_name: String = String(target_enemy.get("name", "Enemy"))
	return {
		"target_enemy_id": target_enemy_id,
		"target_enemy_name": target_enemy_name,
		"target_cell": target_cell,
		"target_cell_label": combat_grid.call("format_cell", target_cell),
		"card_id": card.get("id")
	}


func _build_reveal_context(bluff_state: Dictionary) -> Dictionary:
	var player_context: Dictionary = combat_grid.call("get_player_context")
	var resolver_state: Dictionary = combat_resolver.call("get_state")
	return {
		"player_cell": player_context.get("cell", Vector2i(-1, -1)),
		"player_lane": int(player_context.get("lane", -1)),
		"unit_positions": combat_grid.call("get_unit_position_snapshot"),
		"active_trap_cells": resolver_state.get("trap_cells", []),
		"bluff_state": bluff_state
	}


func _validate_card_context(card: Resource, context: Dictionary) -> bool:
	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		if target_enemy_id.is_empty() or not bool(combat_resolver.call("has_living_enemy", target_enemy_id)):
			_append_log("%s needs a living enemy target." % _get_card_name(card))
			return false

	if _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		if not _is_valid_player_move_target(target_cell):
			_append_log("%s needs a legal adjacent move target." % _get_card_name(card))
			return false

	return true


func _resolve_movement_card(card: Resource, context: Dictionary) -> void:
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	if not _is_valid_player_move_target(target_cell):
		_append_log("%s fizzles because the move target is no longer legal." % _get_card_name(card))
		return

	if bool(combat_grid.call("move_unit", &"player", target_cell)):
		_append_log("%s moves the Gambler-Knight to %s." % [
			_get_card_name(card),
			combat_grid.call("format_cell", target_cell)
		])


func _is_valid_player_move_target(target_cell: Vector2i) -> bool:
	var valid_cells: Array = combat_grid.call("get_empty_adjacent_cells_for", &"player")
	return valid_cells.has(target_cell)


func _is_attack_or_read_card(card: Resource) -> bool:
	return int(card.get("target_type")) == 2


func _is_movement_card(card: Resource) -> bool:
	return int(card.get("card_type")) == 2


func _is_grid_cell_card(card: Resource) -> bool:
	return int(card.get("target_type")) == 3


func _get_selected_enemy_target() -> Dictionary:
	var metadata = _get_selected_metadata(target_enemy_option)
	if typeof(metadata) != TYPE_DICTIONARY:
		return {}
	return metadata


func _get_selected_enemy_target_id() -> StringName:
	var target: Dictionary = _get_selected_enemy_target()
	return StringName(target.get("id", &""))


func _get_selected_move_cell() -> Vector2i:
	var metadata = _get_selected_metadata(movement_cell_option)
	if typeof(metadata) == TYPE_VECTOR2I:
		return metadata
	return Vector2i(-1, -1)


func _refresh_guidance() -> void:
	if phase_guidance_label == null or recipe_label == null or combat_session == null:
		return

	var state: Dictionary = combat_session.call("get_state")
	var phase_key: String = String(state.get("current_phase_key", "START_TURN"))
	var guidance = PHASE_GUIDANCE.get(phase_key, PHASE_GUIDANCE.get("START_TURN", {}))

	if bool(state.get("combat_over", false)):
		phase_guidance_label.text = "Combat Complete"
		phase_detail_label.text = "Outcome: %s. Start a new combat when ready." % state.get("outcome", "unknown")
	else:
		phase_guidance_label.text = String(guidance.get("title", "Turn"))
		phase_detail_label.text = String(guidance.get("detail", "Continue the combat loop."))

	_refresh_recipe_label()


func _reset_recipe_progress() -> void:
	recipe_progress.clear()
	for step in RECIPE_STEPS:
		var step_id: String = String(step.get("id", ""))
		recipe_progress[step_id] = false
	_refresh_recipe_label()


func _mark_recipe_step(step_id: String) -> void:
	if recipe_progress.is_empty():
		_reset_recipe_progress()

	if not recipe_progress.has(step_id):
		return

	if bool(recipe_progress.get(step_id, false)):
		return

	recipe_progress[step_id] = true
	_refresh_recipe_label()


func _refresh_recipe_label() -> void:
	if recipe_label == null:
		return

	recipe_label.clear()
	recipe_label.append_text("Playable Combat Recipe\n")
	for step in RECIPE_STEPS:
		var step_id: String = String(step.get("id", ""))
		var step_label: String = String(step.get("label", "Step"))
		var done: bool = bool(recipe_progress.get(step_id, false))
		var marker := "x" if done else " "
		recipe_label.append_text("[%s] %s\n" % [marker, step_label])

	var next_step: String = _get_next_recipe_step_label()
	if next_step.is_empty():
		recipe_label.append_text("Next: repeat the loop with a cleaner read.")
	else:
		recipe_label.append_text("Next: %s" % next_step)


func _get_next_recipe_step_label() -> String:
	for step in RECIPE_STEPS:
		var step_id: String = String(step.get("id", ""))
		if not bool(recipe_progress.get(step_id, false)):
			return String(step.get("label", "Step"))
	return ""


func _update_debug_visibility() -> void:
	if debug_controls != null:
		debug_controls.visible = debug_controls_visible
	if toggle_debug_button != null:
		toggle_debug_button.text = "Hide Debug" if debug_controls_visible else "Show Debug"
	if toggle_truth_button != null:
		toggle_truth_button.text = "Hide Truth" if debug_truth_visible else "Show Truth"

	var truth_visible := debug_controls_visible and debug_truth_visible
	if truth_title_label != null:
		truth_title_label.visible = truth_visible
	if debug_truth_label != null:
		debug_truth_label.visible = truth_visible


func _refresh_enemy_call_options() -> void:
	enemy_call_option.clear()
	for preview in current_intent_previews:
		enemy_call_option.add_item(String(preview.get("enemy_name", "Enemy")))
		enemy_call_option.set_item_metadata(enemy_call_option.item_count - 1, preview)

	if enemy_call_option.item_count > 0:
		enemy_call_option.select(0)
	_refresh_intent_call_options()


func _refresh_intent_call_options() -> void:
	intent_call_option.clear()
	var preview = _get_selected_metadata(enemy_call_option)
	if typeof(preview) != TYPE_DICTIONARY:
		return

	var options: Array = preview.get("options", [])
	for option in options:
		intent_call_option.add_item("%d%% %s" % [
			option.get("percentage", 0),
			option.get("intent_name", "Intent")
		])
		intent_call_option.set_item_metadata(intent_call_option.item_count - 1, option)

	if intent_call_option.item_count > 0:
		intent_call_option.select(0)


func _get_selected_metadata(option_button: OptionButton):
	if option_button.item_count == 0 or option_button.selected < 0:
		return null
	return option_button.get_item_metadata(option_button.selected)


func _get_card_cost(card: Resource) -> int:
	if card == null:
		return 0
	return int(card.get("cost"))


func _get_card_name(card: Resource) -> String:
	if card == null:
		return "Unknown Card"
	if card.has_method("get_display_name"):
		return String(card.call("get_display_name"))
	return String(card.get("display_name"))


func _get_trap_cells_text(cells: Array) -> String:
	if cells.is_empty():
		return ""

	var labels: Array[String] = []
	for cell in cells:
		if typeof(cell) == TYPE_VECTOR2I:
			labels.append("(%d,%d)" % [cell.x, cell.y])

	if labels.is_empty():
		return ""

	return " at %s" % ", ".join(labels)


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
