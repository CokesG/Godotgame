extends Control

const COMBAT_GRID_SCRIPT := preload("res://scripts/grid/CombatGrid.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/grid/TacticalMapDefinition.gd")
const BLUFF_SYSTEM_SCRIPT := preload("res://scripts/combat/BluffSystem.gd")
const COMBAT_RESOLVER_SCRIPT := preload("res://scripts/combat/CombatResolver.gd")
const COMBAT_SESSION_SCRIPT := preload("res://scripts/combat/CombatSession.gd")
const COMBAT_VFX_SCRIPT := preload("res://scripts/vfx/CombatVFX.gd")
const ARENA_3D_VIEW_SCRIPT := preload("res://scripts/arena/Arena3DView.gd")
const ACTION_BEAT_RESOLVER_SCRIPT := preload("res://scripts/combat/ActionBeatResolver.gd")
const DECK_MANAGER_SCRIPT := preload("res://scripts/cards/DeckManager.gd")
const ENEMY_INTENT_SYSTEM_SCRIPT := preload("res://scripts/enemies/EnemyIntentSystem.gd")
const HAND_VIEW_SCRIPT := preload("res://scripts/ui/HandView.gd")
const DEAD_MANS_ANTE_SKIN_SCRIPT := preload("res://scripts/ui/DeadMansAnteSkin.gd")
const RUN_MANAGER_SCRIPT := preload("res://scripts/run/RunManager.gd")
const TEST_COMBAT_COPY_SCRIPT := preload("res://scripts/combat/TestCombatCopy.gd")
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
const INTENT_TYPE_ATTACK := 0
const RUN_FLOW_START := "start"
const RUN_FLOW_COMBAT := "combat"
const RUN_FLOW_REWARD := "reward"
const RUN_FLOW_NEXT_ENCOUNTER := "next_encounter"
const RUN_FLOW_RESULTS := "results"
const FEEDBACK_DAMAGE_COLOR := Color(1.0, 0.36, 0.28)
const FEEDBACK_GUARD_COLOR := Color(0.38, 0.78, 1.0)
const FEEDBACK_CARD_COLOR := Color(1.0, 0.78, 0.36)
const FEEDBACK_PHASE_COLOR := Color(0.72, 0.90, 1.0)
const FEEDBACK_REVEAL_COLOR := Color(0.90, 0.68, 1.0)
const FEEDBACK_MOVE_COLOR := Color(0.52, 1.0, 0.62)
const PHASE_ACTION_LABELS := TEST_COMBAT_COPY_SCRIPT.PHASE_ACTION_LABELS
const PHASE_GUIDANCE := TEST_COMBAT_COPY_SCRIPT.PHASE_GUIDANCE
const RECIPE_STEPS := TEST_COMBAT_COPY_SCRIPT.RECIPE_STEPS
const RUN_INSPECTOR_FILTERS := TEST_COMBAT_COPY_SCRIPT.RUN_INSPECTOR_FILTERS
const HERO_CLASS_OPTIONS := [
	{
		"id": "gambler_knight",
		"label": "Gambler-Knight",
		"role": "Duelist",
		"summary": "+2 armor, card powers cool down faster.",
		"deck_focus": "Balanced opener: cut, guard, move, read, trap.",
		"arena_line": "FPS kit: armored duelist with flexible card powers.",
		"art": "res://art/game/classes/hero_gambler_knight_keyart.png",
		"accent": Color(1.0, 0.74, 0.30)
	},
	{
		"id": "hex_sharpshooter",
		"label": "Hex Sharpshooter",
		"role": "Controller",
		"summary": "Read and trap cards become your natural kit.",
		"deck_focus": "Control opener: reveals, snares, marks, repositions.",
		"arena_line": "FPS kit: outline reads, trap fields, marked shots.",
		"art": "res://art/game/classes/hero_hex_sharpshooter_keyart.png",
		"accent": Color(0.82, 0.50, 1.0)
	},
	{
		"id": "blood_wager",
		"label": "Blood Wager",
		"role": "Berserker",
		"summary": "Ritual and overclock cards become your natural kit.",
		"deck_focus": "Risk opener: blood fuel, burst damage, hard guard.",
		"arena_line": "FPS kit: sacrifice economy for violent tempo.",
		"art": "res://art/game/classes/hero_blood_wager_keyart.png",
		"accent": Color(1.0, 0.28, 0.22)
	}
]

@onready var turn_manager: Node = $TurnManager

var phase_label: Label
var turn_label: Label
var log_label: RichTextLabel
var combat_grid: Control
var combat_vfx: Control
var arena_view: Control
var battlefield_focus_label: Label
var battlefield_callout_label: Label
var action_beat_panel: PanelContainer
var action_beat_label: Label
var action_beat_progress: ProgressBar
var action_beat_button: Button
var action_target_ring: PanelContainer
var action_aim_reticle: PanelContainer
var bluff_system: Node
var combat_resolver: Node
var combat_session: Node
var run_manager: Node
var deck_manager: Node
var enemy_intent_system: Node
var hand_view: HBoxContainer
var pile_counts_label: Label
var resource_state_label: Label
var shooter_economy_label: Label
var objective_plan_label: Label
var reward_mods_label: Label
var reward_artifact_row: HBoxContainer
var reward_artifact_detail_label: RichTextLabel
var armory_plan_label: Label
var start_hero_class_option: OptionButton
var start_hero_class_summary_label: Label
var start_hero_class_art: TextureRect
var start_hero_class_loadout_label: Label
var start_hero_class_card_buttons: Array[Button] = []
var hero_class_option: OptionButton
var hero_class_summary_label: Label
var arena_payout_panel: PanelContainer
var arena_payout_label: RichTextLabel
var arena_payout_continue_button: Button
var loadout_slot_row: HBoxContainer
var loadout_slot_buttons: Dictionary = {}
var hand_action_button_row: HBoxContainer
var slot_selected_button: Button
var burn_selected_button: Button
var hold_selected_button: Button
var upgrade_selected_button: Button
var mutate_selected_button: Button
var recommend_loadout_button: Button
var bridge_payload_button: Button
var enter_arena_button: Button
var run_header_label: RichTextLabel
var run_path_label: RichTextLabel
var run_path_buttons_row: HBoxContainer
var run_path_preview_label: RichTextLabel
var run_shell_panel: PanelContainer
var run_shell_title_label: Label
var run_shell_detail_label: RichTextLabel
var run_continuity_label: RichTextLabel
var run_ceremony_panel: PanelContainer
var run_ceremony_label: RichTextLabel
var encounter_preview_label: RichTextLabel
var encounter_approach_panel: PanelContainer
var approach_title_label: Label
var approach_enemy_cards_label: RichTextLabel
var approach_rule_label: RichTextLabel
var approach_stakes_label: RichTextLabel
var run_finale_panel: PanelContainer
var run_finale_label: RichTextLabel
var start_run_button: Button
var next_encounter_button: Button
var shell_new_run_button: Button
var shell_export_button: Button
var shell_inspect_run_button: Button
var shell_view_history_button: Button
var shell_export_history_csv_button: Button
var shell_archive_history_button: Button
var action_cue_panel: PanelContainer
var action_cue_title_label: Label
var action_cue_detail_label: Label
var action_cue_pip_label: Label
var opening_click_prompt_label: Label
var combat_action_badge_label: Label
var opening_step_row: HBoxContainer
var opening_step_buttons: Array[Button] = []
var turn_status_label: RichTextLabel
var feedback_banner_label: Label
var combat_feedback_label: RichTextLabel
var action_prompt_label: Label
var first_play_path_label: RichTextLabel
var first_play_coach_panel: PanelContainer
var first_play_coach_label: Label
var live_state_chip_row: HBoxContainer
var phase_state_chip: Button
var energy_state_chip: Button
var target_state_chip: Button
var move_state_chip: Button
var threat_state_chip: Button
var rule_state_chip: Button
var first_play_step_row: HBoxContainer
var first_play_step_buttons: Array[Button] = []
var phase_guidance_label: Label
var phase_detail_label: Label
var table_rule_status_label: RichTextLabel
var recipe_panel: PanelContainer
var recipe_label: RichTextLabel
var run_state_label: RichTextLabel
var balance_report_label: RichTextLabel
var run_results_label: RichTextLabel
var run_export_readback_label: RichTextLabel
var run_history_label: RichTextLabel
var run_panel_container: PanelContainer
var run_inspector_panel: PanelContainer
var run_inspector_filter_row: HBoxContainer
var run_inspector_label: RichTextLabel
var playtest_report_label: RichTextLabel
var reward_prompt_label: RichTextLabel
var reward_impact_label: RichTextLabel
var run_path_buttons: Array[Button] = []
var card_reward_buttons: Array[Button] = []
var relic_reward_buttons: Array[Button] = []
var skip_rewards_button: Button
var combat_state_label: RichTextLabel
var combat_log_column: VBoxContainer
var bluff_state_label: RichTextLabel
var enemy_call_option: OptionButton
var intent_call_option: OptionButton
var lane_call_option: OptionButton
var target_enemy_option: OptionButton
var movement_cell_option: OptionButton
var enemy_target_cards_row: HBoxContainer
var opponent_title_label: Label
var enemy_target_card_buttons: Array[Button] = []
var enemy_status_label: RichTextLabel
var intent_icon_strip_label: RichTextLabel
var threat_summary_label: RichTextLabel
var intent_preview_label: RichTextLabel
var truth_title_label: Label
var debug_truth_label: RichTextLabel
var debug_drawer_panel: PanelContainer
var debug_summary_label: RichTextLabel
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
var run_playtests_button: Button
var export_summary_button: Button
var commit_first_card_button: Button
var set_call_button: Button
var raise_button: Button
var fold_button: Button
var reset_bluff_button: Button
var card_action_hint_label: RichTextLabel
var card_target_preview_label: RichTextLabel
var hand_action_status_label: Label
var debug_controls_visible: bool = false
var debug_truth_visible: bool = false
var current_intent_previews: Array[Dictionary] = []
var reveal_resolved_this_phase: bool = false
var run_flow_state: String = RUN_FLOW_START
var recipe_progress: Dictionary = {}
var pending_card_context: Dictionary = {}
var committed_card_context: Dictionary = {}
var shooter_chips: int = 7
var arena_carryover_armor: int = 0
var arena_carryover_ammo: int = 0
var arena_weapon_damage_bonus: int = 0
var held_hand_indices: Dictionary = {}
var loadout_slots: Dictionary = {}
var selected_hero_class_id := "gambler_knight"
var selected_hand_index: int = -1
var arena_bridge_payload: Dictionary = {}
var arena_round_armed := false
var pending_arena_result: Dictionary = {}
var pending_arena_effect_lines: Array[String] = []
var arena_payout_pending := false
var active_reward_mods: Array = []
var card_upgrade_mods: Dictionary = {}
var arena_card_xp_pool: int = 0
var arena_wounds_total: int = 0
var selected_reward_artifact_index: int = 0
var feedback_history: Array[String] = []
var run_ceremony_history: Array[String] = []
var table_rule_effect_history: Array[String] = []
var last_combat_feedback_state: Dictionary = {}
var previewed_hand_index: int = -1
var selected_run_path_index: int = -1
var last_run_path_current_index: int = -1
var last_run_path_transition_text: String = ""
var last_results_ceremony_outcome: String = ""
var last_export_path: String = ""
var last_export_readback: Dictionary = {}
var last_run_history_report: Dictionary = {}
var last_run_history_rows: Array[Dictionary] = []
var last_history_csv_path: String = ""
var last_history_archive_report: Dictionary = {}
var run_history_requested: bool = false
var last_run_inspection_report: Dictionary = {}
var run_inspector_requested: bool = false
var run_inspector_card_filter: String = "all"
var run_inspector_filter_buttons: Array[Button] = []
var last_action_cue_key: String = ""
var last_reward_shimmer_key: String = ""
var first_play_coach_steps: Dictionary = {}
var first_play_coach_complete: bool = false
var active_action_beat: Dictionary = {}
var active_action_card: Resource
var active_action_context: Dictionary = {}
var active_action_target_position: Vector2 = Vector2.ZERO
var opening_idle_tween: Tween
var guide_beacon_timer: Timer
var guided_click_target: CanvasItem
var guided_click_label: String = ""
var guided_click_color: Color = Color(1.0, 0.78, 0.32)
var last_action_guide_key: String = ""


func _ready() -> void:
	_build_ui()
	_build_vfx_layer()
	_connect_turn_manager()
	log_label.clear()
	_reset_run_slice()
	_consume_pending_arena_result()


func _process(_delta: float) -> void:
	if active_action_beat.is_empty() or action_beat_panel == null or not action_beat_panel.visible:
		return

	var aim_position: Vector2 = get_viewport().get_mouse_position()
	_position_action_marker(action_aim_reticle, aim_position, Vector2(30, 30))
	var distance: float = aim_position.distance_to(active_action_target_position)
	var ratio: float = clampf(1.0 - (distance / 170.0), 0.0, 1.0)
	if action_beat_progress != null:
		action_beat_progress.value = ratio * 100.0
	_update_action_beat_copy(distance)


func _input(event: InputEvent) -> void:
	if active_action_beat.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_complete_action_beat()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
			_complete_action_beat()
			get_viewport().set_input_as_handled()


func _build_vfx_layer() -> void:
	combat_vfx = COMBAT_VFX_SCRIPT.new()
	combat_vfx.name = "CombatVFX"
	combat_vfx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combat_vfx)
	combat_vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	guide_beacon_timer = Timer.new()
	guide_beacon_timer.name = "GuideBeaconTimer"
	guide_beacon_timer.wait_time = 0.74
	guide_beacon_timer.autostart = true
	guide_beacon_timer.timeout.connect(_on_guide_beacon_timeout)
	add_child(guide_beacon_timer)


func _add_table_backdrop() -> void:
	var fallback := ColorRect.new()
	fallback.name = "TableBackdropFallback"
	fallback.color = Color(0.028, 0.024, 0.022)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var texture := DEAD_MANS_ANTE_SKIN_SCRIPT.load_texture(DEAD_MANS_ANTE_SKIN_SCRIPT.TABLE_BACKDROP_PATH)
	if texture == null:
		return

	var backdrop := TextureRect.new()
	backdrop.name = "TableBackdrop"
	backdrop.texture = texture
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DEAD_MANS_ANTE_SKIN_SCRIPT.apply_to(self)
	_add_table_backdrop()

	var margin := MarginContainer.new()
	margin.name = "RootMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var title_plate := PanelContainer.new()
	title_plate.name = "TitlePlaque"
	title_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_plate.custom_minimum_size = Vector2(0, 62)
	layout.add_child(title_plate)

	var title := Label.new()
	title.name = "ScreenTitle"
	title.text = "Dead Man's Ante"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title_plate.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "ScreenSubtitle"
	subtitle.text = "Five cursed tables. One clean read."
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 16)
	layout.add_child(subtitle)

	run_header_label = RichTextLabel.new()
	run_header_label.name = "RunHeader"
	run_header_label.bbcode_enabled = false
	run_header_label.fit_content = true
	run_header_label.scroll_active = false
	run_header_label.custom_minimum_size = Vector2(0, 64)
	layout.add_child(run_header_label)

	var run_path_panel := PanelContainer.new()
	run_path_panel.name = "RunPathPanel"
	run_path_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(run_path_panel)

	var run_path_layout := VBoxContainer.new()
	run_path_layout.name = "RunPathLayout"
	run_path_layout.add_theme_constant_override("separation", 6)
	run_path_panel.add_child(run_path_layout)

	run_path_label = RichTextLabel.new()
	run_path_label.name = "RunPath"
	run_path_label.bbcode_enabled = false
	run_path_label.fit_content = true
	run_path_label.scroll_active = false
	run_path_label.custom_minimum_size = Vector2(0, 52)
	run_path_layout.add_child(run_path_label)

	run_path_buttons_row = HBoxContainer.new()
	run_path_buttons_row.name = "RunPathButtons"
	run_path_buttons_row.add_theme_constant_override("separation", 6)
	run_path_layout.add_child(run_path_buttons_row)

	for index in range(5):
		var path_button := Button.new()
		path_button.name = "RunPathTable%d" % index
		path_button.text = "Table %d" % (index + 1)
		path_button.custom_minimum_size = Vector2(0, 76)
		path_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		path_button.clip_text = true
		path_button.pressed.connect(_on_run_path_table_pressed.bind(index))
		path_button.mouse_entered.connect(_on_run_path_table_hovered.bind(index))
		run_path_buttons.append(path_button)
		run_path_buttons_row.add_child(path_button)

	run_path_preview_label = RichTextLabel.new()
	run_path_preview_label.name = "RunPathPreview"
	run_path_preview_label.bbcode_enabled = false
	run_path_preview_label.fit_content = true
	run_path_preview_label.scroll_active = false
	run_path_preview_label.custom_minimum_size = Vector2(0, 86)
	run_path_layout.add_child(run_path_preview_label)

	run_shell_panel = PanelContainer.new()
	run_shell_panel.name = "RunShellPanel"
	run_shell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(run_shell_panel)

	var run_shell_layout := VBoxContainer.new()
	run_shell_layout.name = "RunShellLayout"
	run_shell_layout.add_theme_constant_override("separation", 6)
	run_shell_panel.add_child(run_shell_layout)

	run_shell_title_label = Label.new()
	run_shell_title_label.name = "RunShellTitle"
	run_shell_title_label.text = "Run Start"
	run_shell_title_label.add_theme_font_size_override("font_size", 20)
	run_shell_layout.add_child(run_shell_title_label)

	run_shell_detail_label = RichTextLabel.new()
	run_shell_detail_label.name = "RunShellDetail"
	run_shell_detail_label.bbcode_enabled = false
	run_shell_detail_label.fit_content = true
	run_shell_detail_label.scroll_active = false
	run_shell_detail_label.custom_minimum_size = Vector2(0, 56)
	run_shell_layout.add_child(run_shell_detail_label)

	_build_start_hero_class_selector(run_shell_layout)

	opening_click_prompt_label = Label.new()
	opening_click_prompt_label.name = "OpeningClickPrompt"
	opening_click_prompt_label.text = "CHOOSE A FIGHTER, THEN DEAL IN"
	opening_click_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_click_prompt_label.add_theme_font_size_override("font_size", 15)
	opening_click_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	run_shell_layout.add_child(opening_click_prompt_label)

	opening_step_row = HBoxContainer.new()
	opening_step_row.name = "OpeningStepRow"
	opening_step_row.add_theme_constant_override("separation", 8)
	run_shell_layout.add_child(opening_step_row)

	var opening_steps := [
		{"label": "1 DEAL IN\nDraw 5", "tooltip": "Start the first table and draw your opening hand."},
		{"label": "2 TARGET\nClick enemy", "tooltip": "Combat starts with a visible enemy target."},
		{"label": "3 CARD\nPlay glow", "tooltip": "Glowing hand cards are playable."},
		{"label": "4 RESOLVE\nEnemy acts", "tooltip": "Resolve Turn lets the table answer."}
	]
	for index in range(opening_steps.size()):
		var step_button := Button.new()
		step_button.name = "OpeningStep%d" % index
		step_button.text = String(opening_steps[index].get("label", "STEP"))
		step_button.tooltip_text = String(opening_steps[index].get("tooltip", ""))
		step_button.focus_mode = Control.FOCUS_NONE
		step_button.clip_text = true
		step_button.custom_minimum_size = Vector2(0, 46)
		step_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_button.pressed.connect(_on_opening_step_pressed.bind(index))
		opening_step_buttons.append(step_button)
		opening_step_row.add_child(step_button)

	run_continuity_label = RichTextLabel.new()
	run_continuity_label.name = "RunContinuity"
	run_continuity_label.bbcode_enabled = false
	run_continuity_label.fit_content = true
	run_continuity_label.scroll_active = false
	run_continuity_label.custom_minimum_size = Vector2(0, 48)
	run_shell_layout.add_child(run_continuity_label)

	run_ceremony_panel = PanelContainer.new()
	run_ceremony_panel.name = "RunCeremonyPanel"
	run_ceremony_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_shell_layout.add_child(run_ceremony_panel)

	run_ceremony_label = RichTextLabel.new()
	run_ceremony_label.name = "RunCeremony"
	run_ceremony_label.bbcode_enabled = false
	run_ceremony_label.fit_content = true
	run_ceremony_label.scroll_active = false
	run_ceremony_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_ceremony_label.custom_minimum_size = Vector2(0, 96)
	run_ceremony_panel.add_child(run_ceremony_label)

	encounter_preview_label = RichTextLabel.new()
	encounter_preview_label.name = "EncounterPreview"
	encounter_preview_label.bbcode_enabled = false
	encounter_preview_label.fit_content = true
	encounter_preview_label.scroll_active = false
	encounter_preview_label.custom_minimum_size = Vector2(0, 86)
	run_shell_layout.add_child(encounter_preview_label)

	encounter_approach_panel = PanelContainer.new()
	encounter_approach_panel.name = "EncounterApproachPanel"
	encounter_approach_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_shell_layout.add_child(encounter_approach_panel)

	var approach_layout := VBoxContainer.new()
	approach_layout.name = "EncounterApproachLayout"
	approach_layout.add_theme_constant_override("separation", 6)
	encounter_approach_panel.add_child(approach_layout)

	approach_title_label = Label.new()
	approach_title_label.name = "ApproachTitle"
	approach_title_label.text = "Approach Table"
	approach_title_label.add_theme_font_size_override("font_size", 18)
	approach_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	approach_layout.add_child(approach_title_label)

	approach_enemy_cards_label = RichTextLabel.new()
	approach_enemy_cards_label.name = "ApproachEnemyCards"
	approach_enemy_cards_label.bbcode_enabled = false
	approach_enemy_cards_label.fit_content = true
	approach_enemy_cards_label.scroll_active = false
	approach_enemy_cards_label.custom_minimum_size = Vector2(0, 118)
	approach_layout.add_child(approach_enemy_cards_label)

	approach_rule_label = RichTextLabel.new()
	approach_rule_label.name = "ApproachTableRule"
	approach_rule_label.bbcode_enabled = false
	approach_rule_label.fit_content = true
	approach_rule_label.scroll_active = false
	approach_rule_label.custom_minimum_size = Vector2(0, 64)
	approach_layout.add_child(approach_rule_label)

	approach_stakes_label = RichTextLabel.new()
	approach_stakes_label.name = "ApproachStakes"
	approach_stakes_label.bbcode_enabled = false
	approach_stakes_label.fit_content = true
	approach_stakes_label.scroll_active = false
	approach_stakes_label.custom_minimum_size = Vector2(0, 58)
	approach_layout.add_child(approach_stakes_label)

	run_finale_panel = PanelContainer.new()
	run_finale_panel.name = "RunFinalePanel"
	run_finale_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_shell_layout.add_child(run_finale_panel)

	run_finale_label = RichTextLabel.new()
	run_finale_label.name = "RunFinale"
	run_finale_label.bbcode_enabled = false
	run_finale_label.fit_content = true
	run_finale_label.scroll_active = false
	run_finale_label.custom_minimum_size = Vector2(0, 136)
	run_finale_panel.add_child(run_finale_label)

	var run_shell_actions := HBoxContainer.new()
	run_shell_actions.name = "RunShellActions"
	run_shell_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	run_shell_actions.add_theme_constant_override("separation", 8)
	run_shell_layout.add_child(run_shell_actions)

	start_run_button = Button.new()
	start_run_button.name = "StartRunButton"
	start_run_button.text = "DEAL IN\nDraw Class Hand"
	start_run_button.custom_minimum_size = Vector2(300, 58)
	start_run_button.add_theme_font_size_override("font_size", 20)
	start_run_button.tooltip_text = "Deal into the first fight with the selected fighter deck."
	start_run_button.pressed.connect(_on_start_run_pressed)
	run_shell_actions.add_child(start_run_button)

	next_encounter_button = Button.new()
	next_encounter_button.name = "NextEncounterButton"
	next_encounter_button.text = "Open Next Table"
	next_encounter_button.custom_minimum_size = Vector2(180, 40)
	next_encounter_button.pressed.connect(_on_next_encounter_pressed)
	run_shell_actions.add_child(next_encounter_button)

	shell_new_run_button = Button.new()
	shell_new_run_button.name = "ShellNewRunButton"
	shell_new_run_button.text = "New Run"
	shell_new_run_button.pressed.connect(_on_reset_pressed)
	run_shell_actions.add_child(shell_new_run_button)

	shell_export_button = Button.new()
	shell_export_button.name = "ShellExportButton"
	shell_export_button.text = "Export Summary"
	shell_export_button.pressed.connect(_on_export_summary_pressed)
	run_shell_actions.add_child(shell_export_button)

	shell_inspect_run_button = Button.new()
	shell_inspect_run_button.name = "ShellInspectRunButton"
	shell_inspect_run_button.text = "Inspect Run"
	shell_inspect_run_button.pressed.connect(_on_inspect_run_pressed)
	run_shell_actions.add_child(shell_inspect_run_button)

	shell_view_history_button = Button.new()
	shell_view_history_button.name = "ShellViewHistoryButton"
	shell_view_history_button.text = "View History"
	shell_view_history_button.pressed.connect(_on_view_history_pressed)
	run_shell_actions.add_child(shell_view_history_button)

	shell_export_history_csv_button = Button.new()
	shell_export_history_csv_button.name = "ShellExportHistoryCsvButton"
	shell_export_history_csv_button.text = "Export History CSV"
	shell_export_history_csv_button.pressed.connect(_on_export_history_csv_pressed)
	run_shell_actions.add_child(shell_export_history_csv_button)

	shell_archive_history_button = Button.new()
	shell_archive_history_button.name = "ShellArchiveHistoryButton"
	shell_archive_history_button.text = "Archive Old Summaries"
	shell_archive_history_button.pressed.connect(_on_archive_history_pressed)
	run_shell_actions.add_child(shell_archive_history_button)
	run_shell_layout.move_child(run_shell_actions, 4)

	action_cue_panel = PanelContainer.new()
	action_cue_panel.name = "ActionCuePanel"
	action_cue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_cue_panel.custom_minimum_size = Vector2(0, 72)
	layout.add_child(action_cue_panel)

	var action_cue_layout := HBoxContainer.new()
	action_cue_layout.name = "ActionCueLayout"
	action_cue_layout.add_theme_constant_override("separation", 10)
	action_cue_panel.add_child(action_cue_layout)

	var action_cue_copy := VBoxContainer.new()
	action_cue_copy.name = "ActionCueCopy"
	action_cue_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_cue_copy.add_theme_constant_override("separation", 2)
	action_cue_layout.add_child(action_cue_copy)

	action_cue_title_label = Label.new()
	action_cue_title_label.name = "ActionCueTitle"
	action_cue_title_label.text = "DEAL IN"
	action_cue_title_label.add_theme_font_size_override("font_size", 22)
	action_cue_copy.add_child(action_cue_title_label)

	action_cue_detail_label = Label.new()
	action_cue_detail_label.name = "ActionCueDetail"
	action_cue_detail_label.text = "Deal In to start the hand."
	action_cue_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_cue_detail_label.add_theme_font_size_override("font_size", 14)
	action_cue_copy.add_child(action_cue_detail_label)

	action_cue_pip_label = Label.new()
	action_cue_pip_label.name = "ActionCuePip"
	action_cue_pip_label.text = "OPEN"
	action_cue_pip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_cue_pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_cue_pip_label.custom_minimum_size = Vector2(104, 46)
	action_cue_layout.add_child(action_cue_pip_label)

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

	var turn_status_panel := PanelContainer.new()
	turn_status_panel.name = "TurnStatusPanel"
	turn_status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(turn_status_panel)

	turn_status_label = RichTextLabel.new()
	turn_status_label.name = "TurnStatus"
	turn_status_label.bbcode_enabled = false
	turn_status_label.fit_content = true
	turn_status_label.scroll_active = false
	turn_status_label.custom_minimum_size = Vector2(0, 70)
	turn_status_panel.add_child(turn_status_label)

	var table_rule_panel := PanelContainer.new()
	table_rule_panel.name = "TableRulePanel"
	table_rule_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(table_rule_panel)

	table_rule_status_label = RichTextLabel.new()
	table_rule_status_label.name = "TableRuleStatus"
	table_rule_status_label.bbcode_enabled = false
	table_rule_status_label.fit_content = true
	table_rule_status_label.scroll_active = false
	table_rule_status_label.custom_minimum_size = Vector2(0, 76)
	table_rule_panel.add_child(table_rule_status_label)

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

	live_state_chip_row = HBoxContainer.new()
	live_state_chip_row.name = "LiveStateChips"
	live_state_chip_row.add_theme_constant_override("separation", 6)
	guidance_layout.add_child(live_state_chip_row)

	phase_state_chip = _create_compact_chip("PhaseStateChip", "PHASE START")
	energy_state_chip = _create_compact_chip("EnergyStateChip", "ENERGY 0/0")
	target_state_chip = _create_compact_chip("TargetStateChip", "TARGET --")
	move_state_chip = _create_compact_chip("MoveStateChip", "MOVE --")
	threat_state_chip = _create_compact_chip("ThreatStateChip", "THREAT ?")
	rule_state_chip = _create_compact_chip("RuleStateChip", "RULE --")
	for chip in [phase_state_chip, energy_state_chip, target_state_chip, move_state_chip, threat_state_chip, rule_state_chip]:
		live_state_chip_row.add_child(chip)

	action_prompt_label = Label.new()
	action_prompt_label.name = "ActionPrompt"
	action_prompt_label.text = "Next: start the run."
	action_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_prompt_label.add_theme_font_size_override("font_size", 16)
	guidance_layout.add_child(action_prompt_label)

	first_play_path_label = RichTextLabel.new()
	first_play_path_label.name = "FirstPlayPath"
	first_play_path_label.bbcode_enabled = false
	first_play_path_label.fit_content = true
	first_play_path_label.scroll_active = false
	first_play_path_label.custom_minimum_size = Vector2(0, 48)
	guidance_layout.add_child(first_play_path_label)

	first_play_coach_panel = PanelContainer.new()
	first_play_coach_panel.name = "FirstPlayCoachPanel"
	first_play_coach_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guidance_layout.add_child(first_play_coach_panel)

	first_play_coach_label = Label.new()
	first_play_coach_label.name = "FirstPlayCoach"
	first_play_coach_label.text = "Coach: OPEN -> TARGET -> CARD -> RESOLVE"
	first_play_coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	first_play_coach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	first_play_coach_label.custom_minimum_size = Vector2(0, 30)
	first_play_coach_label.add_theme_font_size_override("font_size", 15)
	first_play_coach_panel.add_child(first_play_coach_label)

	first_play_step_row = HBoxContainer.new()
	first_play_step_row.name = "FirstPlayStepButtons"
	first_play_step_row.add_theme_constant_override("separation", 6)
	guidance_layout.add_child(first_play_step_row)

	for step in [
		{"name": "FirstPlayStepOpen", "text": "1 Open"},
		{"name": "FirstPlayStepTarget", "text": "2 Target"},
		{"name": "FirstPlayStepCard", "text": "3 Card"},
		{"name": "FirstPlayStepResolve", "text": "4 Resolve"}
	]:
		var step_button := _create_compact_chip(String(step.get("name", "FirstPlayStep")), String(step.get("text", "Step")))
		first_play_step_buttons.append(step_button)
		first_play_step_row.add_child(step_button)

	var feedback_panel := PanelContainer.new()
	feedback_panel.name = "CombatFeedbackPanel"
	feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(feedback_panel)

	var feedback_layout := VBoxContainer.new()
	feedback_layout.name = "CombatFeedbackLayout"
	feedback_layout.add_theme_constant_override("separation", 4)
	feedback_panel.add_child(feedback_layout)

	feedback_banner_label = Label.new()
	feedback_banner_label.name = "FeedbackBanner"
	feedback_banner_label.text = "Ready"
	feedback_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_banner_label.custom_minimum_size = Vector2(0, 34)
	feedback_banner_label.add_theme_font_size_override("font_size", 20)
	feedback_layout.add_child(feedback_banner_label)

	combat_feedback_label = RichTextLabel.new()
	combat_feedback_label.name = "CombatFeedback"
	combat_feedback_label.bbcode_enabled = false
	combat_feedback_label.fit_content = true
	combat_feedback_label.scroll_active = false
	combat_feedback_label.custom_minimum_size = Vector2(0, 72)
	feedback_layout.add_child(combat_feedback_label)

	recipe_panel = PanelContainer.new()
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

	var run_panel := PanelContainer.new()
	run_panel.name = "RunPanel"
	run_panel.visible = false
	run_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(run_panel)
	run_panel_container = run_panel

	var run_layout := VBoxContainer.new()
	run_layout.name = "RunLayout"
	run_layout.add_theme_constant_override("separation", 6)
	run_panel.add_child(run_layout)

	run_state_label = RichTextLabel.new()
	run_state_label.name = "RunState"
	run_state_label.bbcode_enabled = false
	run_state_label.fit_content = true
	run_state_label.scroll_active = false
	run_state_label.custom_minimum_size = Vector2(0, 86)
	run_layout.add_child(run_state_label)

	balance_report_label = RichTextLabel.new()
	balance_report_label.name = "BalanceReport"
	balance_report_label.bbcode_enabled = false
	balance_report_label.fit_content = true
	balance_report_label.scroll_active = false
	balance_report_label.custom_minimum_size = Vector2(0, 78)
	run_layout.add_child(balance_report_label)

	run_results_label = RichTextLabel.new()
	run_results_label.name = "RunResults"
	run_results_label.bbcode_enabled = false
	run_results_label.fit_content = true
	run_results_label.scroll_active = false
	run_results_label.visible = false
	run_results_label.custom_minimum_size = Vector2(0, 74)
	run_layout.add_child(run_results_label)

	run_export_readback_label = RichTextLabel.new()
	run_export_readback_label.name = "RunExportReadback"
	run_export_readback_label.bbcode_enabled = false
	run_export_readback_label.fit_content = true
	run_export_readback_label.scroll_active = false
	run_export_readback_label.visible = false
	run_export_readback_label.custom_minimum_size = Vector2(0, 92)
	run_layout.add_child(run_export_readback_label)

	run_history_label = RichTextLabel.new()
	run_history_label.name = "RunHistoryComparison"
	run_history_label.bbcode_enabled = false
	run_history_label.fit_content = true
	run_history_label.scroll_active = false
	run_history_label.visible = false
	run_history_label.custom_minimum_size = Vector2(0, 148)
	run_layout.add_child(run_history_label)

	run_inspector_filter_row = HBoxContainer.new()
	run_inspector_filter_row.name = "RunInspectorFilters"
	run_inspector_filter_row.visible = false
	run_inspector_filter_row.add_theme_constant_override("separation", 6)
	run_layout.add_child(run_inspector_filter_row)

	for filter in RUN_INSPECTOR_FILTERS:
		var filter_button := Button.new()
		var filter_id := String(filter.get("id", "all"))
		filter_button.name = "RunInspectorFilter%s" % filter_id.capitalize()
		filter_button.text = String(filter.get("label", filter_id.capitalize()))
		filter_button.custom_minimum_size = Vector2(76, 32)
		filter_button.pressed.connect(_on_run_inspector_filter_pressed.bind(filter_id))
		run_inspector_filter_buttons.append(filter_button)
		run_inspector_filter_row.add_child(filter_button)

	run_inspector_panel = PanelContainer.new()
	run_inspector_panel.name = "RunInspectorPanel"
	run_inspector_panel.visible = false
	run_inspector_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_layout.add_child(run_inspector_panel)

	run_inspector_label = RichTextLabel.new()
	run_inspector_label.name = "RunInspector"
	run_inspector_label.bbcode_enabled = false
	run_inspector_label.fit_content = true
	run_inspector_label.scroll_active = false
	run_inspector_label.custom_minimum_size = Vector2(0, 220)
	run_inspector_panel.add_child(run_inspector_label)

	playtest_report_label = RichTextLabel.new()
	playtest_report_label.name = "PlaytestReport"
	playtest_report_label.bbcode_enabled = false
	playtest_report_label.fit_content = true
	playtest_report_label.scroll_active = false
	playtest_report_label.custom_minimum_size = Vector2(0, 72)
	run_layout.add_child(playtest_report_label)

	reward_prompt_label = RichTextLabel.new()
	reward_prompt_label.name = "RewardPrompt"
	reward_prompt_label.bbcode_enabled = false
	reward_prompt_label.fit_content = true
	reward_prompt_label.scroll_active = false
	reward_prompt_label.visible = false
	reward_prompt_label.custom_minimum_size = Vector2(0, 60)
	run_layout.add_child(reward_prompt_label)

	reward_impact_label = RichTextLabel.new()
	reward_impact_label.name = "RewardImpact"
	reward_impact_label.bbcode_enabled = false
	reward_impact_label.fit_content = true
	reward_impact_label.scroll_active = false
	reward_impact_label.visible = false
	reward_impact_label.custom_minimum_size = Vector2(0, 84)
	run_layout.add_child(reward_impact_label)

	var card_rewards_row := HBoxContainer.new()
	card_rewards_row.name = "CardRewards"
	card_rewards_row.add_theme_constant_override("separation", 6)
	run_layout.add_child(card_rewards_row)

	for index in range(3):
		var reward_button := Button.new()
		reward_button.name = "CardReward%d" % index
		reward_button.text = "Card Reward"
		reward_button.disabled = true
		reward_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward_button.custom_minimum_size = Vector2(0, 96)
		reward_button.clip_text = true
		reward_button.pressed.connect(_on_card_reward_pressed.bind(index))
		card_reward_buttons.append(reward_button)
		card_rewards_row.add_child(reward_button)

	var relic_rewards_row := HBoxContainer.new()
	relic_rewards_row.name = "RelicRewards"
	relic_rewards_row.add_theme_constant_override("separation", 6)
	run_layout.add_child(relic_rewards_row)

	for index in range(2):
		var relic_button := Button.new()
		relic_button.name = "RelicReward%d" % index
		relic_button.text = "Relic Reward"
		relic_button.disabled = true
		relic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		relic_button.custom_minimum_size = Vector2(0, 76)
		relic_button.pressed.connect(_on_relic_reward_pressed.bind(index))
		relic_reward_buttons.append(relic_button)
		relic_rewards_row.add_child(relic_button)

	skip_rewards_button = Button.new()
	skip_rewards_button.name = "SkipRewardsButton"
	skip_rewards_button.text = "Skip Rewards"
	skip_rewards_button.disabled = true
	skip_rewards_button.pressed.connect(_on_skip_rewards_pressed)
	run_layout.add_child(skip_rewards_button)
	var reward_prompt_index := reward_prompt_label.get_index()
	run_layout.move_child(card_rewards_row, reward_prompt_index + 1)
	run_layout.move_child(relic_rewards_row, reward_prompt_index + 2)
	run_layout.move_child(skip_rewards_button, reward_prompt_index + 3)
	run_layout.move_child(reward_impact_label, reward_prompt_index + 4)

	var primary_controls := HBoxContainer.new()
	primary_controls.name = "PrimaryControls"
	primary_controls.add_theme_constant_override("separation", 8)
	layout.add_child(primary_controls)

	next_phase_button = Button.new()
	next_phase_button.name = "ContinueButton"
	next_phase_button.text = "Start Draw"
	next_phase_button.pressed.connect(_on_next_phase_pressed)
	primary_controls.add_child(next_phase_button)

	combat_action_badge_label = Label.new()
	combat_action_badge_label.name = "NextActionBadge"
	combat_action_badge_label.text = "NEXT: CLICK"
	combat_action_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combat_action_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_action_badge_label.custom_minimum_size = Vector2(0, 46)
	combat_action_badge_label.add_theme_font_size_override("font_size", 18)
	combat_action_badge_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	primary_controls.add_child(combat_action_badge_label)

	reset_button = Button.new()
	reset_button.name = "NewCombatButton"
	reset_button.text = "New Run"
	reset_button.pressed.connect(_on_reset_pressed)
	primary_controls.add_child(reset_button)

	toggle_debug_button = Button.new()
	toggle_debug_button.name = "ToggleDebugButton"
	toggle_debug_button.text = "Show Debug"
	toggle_debug_button.pressed.connect(_on_toggle_debug_pressed)
	primary_controls.add_child(toggle_debug_button)

	debug_drawer_panel = PanelContainer.new()
	debug_drawer_panel.name = "DebugDrawer"
	debug_drawer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(debug_drawer_panel)

	var debug_drawer_layout := VBoxContainer.new()
	debug_drawer_layout.name = "DebugDrawerLayout"
	debug_drawer_layout.add_theme_constant_override("separation", 6)
	debug_drawer_panel.add_child(debug_drawer_layout)

	var debug_drawer_title := Label.new()
	debug_drawer_title.name = "DebugDrawerTitle"
	debug_drawer_title.text = "Debug Drawer"
	debug_drawer_title.add_theme_font_size_override("font_size", 18)
	debug_drawer_layout.add_child(debug_drawer_title)

	debug_summary_label = RichTextLabel.new()
	debug_summary_label.name = "DebugSummary"
	debug_summary_label.bbcode_enabled = false
	debug_summary_label.fit_content = true
	debug_summary_label.scroll_active = false
	debug_summary_label.custom_minimum_size = Vector2(0, 68)
	debug_drawer_layout.add_child(debug_summary_label)

	debug_controls = HBoxContainer.new()
	debug_controls.name = "DebugControls"
	debug_controls.add_theme_constant_override("separation", 8)
	debug_drawer_layout.add_child(debug_controls)

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

	run_playtests_button = Button.new()
	run_playtests_button.name = "RunPlaytestsButton"
	run_playtests_button.text = "Run 5 Sims"
	run_playtests_button.pressed.connect(_on_run_playtests_pressed)
	debug_controls.add_child(run_playtests_button)

	export_summary_button = Button.new()
	export_summary_button.name = "ExportSummaryButton"
	export_summary_button.text = "Export Summary"
	export_summary_button.pressed.connect(_on_export_summary_pressed)
	debug_controls.add_child(export_summary_button)

	var body := VBoxContainer.new()
	body.name = "CombatBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	layout.add_child(body)

	battlefield_focus_label = Label.new()
	battlefield_focus_label.name = "BattlefieldFocus"
	battlefield_focus_label.text = "BATTLEFIELD"
	battlefield_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battlefield_focus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battlefield_focus_label.custom_minimum_size = Vector2(0, 38)
	battlefield_focus_label.add_theme_font_size_override("font_size", 20)
	battlefield_focus_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	body.add_child(battlefield_focus_label)

	arena_payout_panel = PanelContainer.new()
	arena_payout_panel.name = "ArenaPayoutPanel"
	arena_payout_panel.visible = false
	arena_payout_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_payout_panel.custom_minimum_size = Vector2(0, 318)
	body.add_child(arena_payout_panel)

	var arena_payout_layout := VBoxContainer.new()
	arena_payout_layout.name = "ArenaPayoutLayout"
	arena_payout_layout.add_theme_constant_override("separation", 10)
	arena_payout_panel.add_child(arena_payout_layout)

	arena_payout_label = RichTextLabel.new()
	arena_payout_label.name = "ArenaPayoutLabel"
	arena_payout_label.bbcode_enabled = true
	arena_payout_label.fit_content = true
	arena_payout_label.scroll_active = false
	arena_payout_label.custom_minimum_size = Vector2(0, 190)
	arena_payout_label.add_theme_font_size_override("normal_font_size", 17)
	arena_payout_layout.add_child(arena_payout_label)

	arena_payout_continue_button = Button.new()
	arena_payout_continue_button.name = "ArenaPayoutContinueButton"
	arena_payout_continue_button.text = "Collect Payout"
	arena_payout_continue_button.custom_minimum_size = Vector2(0, 58)
	arena_payout_continue_button.pressed.connect(_on_arena_payout_continue_pressed)
	arena_payout_layout.add_child(arena_payout_continue_button)

	var table_row := HBoxContainer.new()
	table_row.name = "TableRow"
	table_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_row.add_theme_constant_override("separation", 12)
	body.add_child(table_row)

	var table_board_panel := PanelContainer.new()
	table_board_panel.name = "TableBoardPanel"
	table_board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_board_panel.size_flags_stretch_ratio = 2.45
	table_row.add_child(table_board_panel)

	var table_stage := Control.new()
	table_stage.name = "TableStage"
	table_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_board_panel.add_child(table_stage)

	arena_view = ARENA_3D_VIEW_SCRIPT.new()
	arena_view.name = "Arena3DView"
	arena_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena_view.modulate = Color.WHITE
	table_stage.add_child(arena_view)
	arena_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	combat_grid = Control.new()
	combat_grid.name = "CombatGrid"
	combat_grid.set_script(COMBAT_GRID_SCRIPT)
	table_stage.add_child(combat_grid)
	combat_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	battlefield_callout_label = Label.new()
	battlefield_callout_label.name = "BattlefieldCallout"
	battlefield_callout_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_callout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battlefield_callout_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battlefield_callout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battlefield_callout_label.custom_minimum_size = Vector2(0, 58)
	battlefield_callout_label.add_theme_font_size_override("font_size", 18)
	battlefield_callout_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.56))
	battlefield_callout_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	battlefield_callout_label.add_theme_constant_override("shadow_offset_x", 2)
	battlefield_callout_label.add_theme_constant_override("shadow_offset_y", 2)
	battlefield_callout_label.z_index = 35
	table_stage.add_child(battlefield_callout_label)
	battlefield_callout_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	battlefield_callout_label.offset_left = 16
	battlefield_callout_label.offset_top = 12
	battlefield_callout_label.offset_right = -16
	battlefield_callout_label.offset_bottom = 64

	action_beat_panel = PanelContainer.new()
	action_beat_panel.name = "ActionBeatPanel"
	action_beat_panel.visible = false
	action_beat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_beat_panel.z_index = 60
	table_stage.add_child(action_beat_panel)
	action_beat_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_beat_panel.offset_left = 190
	action_beat_panel.offset_top = -126
	action_beat_panel.offset_right = -190
	action_beat_panel.offset_bottom = -14
	_style_play_panel(action_beat_panel, Color(0.08, 0.035, 0.028, 0.94), Color(1.0, 0.62, 0.20), "cue")

	var beat_layout := VBoxContainer.new()
	beat_layout.name = "ActionBeatLayout"
	beat_layout.add_theme_constant_override("separation", 8)
	action_beat_panel.add_child(beat_layout)

	action_beat_label = Label.new()
	action_beat_label.name = "ActionBeatLabel"
	action_beat_label.text = "ACTION BEAT"
	action_beat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_beat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_beat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_beat_label.add_theme_font_size_override("font_size", 19)
	action_beat_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58))
	beat_layout.add_child(action_beat_label)

	action_beat_progress = ProgressBar.new()
	action_beat_progress.name = "ActionAimAccuracy"
	action_beat_progress.min_value = 0.0
	action_beat_progress.max_value = 100.0
	action_beat_progress.value = 0.0
	action_beat_progress.show_percentage = false
	action_beat_progress.custom_minimum_size = Vector2(0, 18)
	beat_layout.add_child(action_beat_progress)

	action_beat_button = Button.new()
	action_beat_button.name = "ActionBeatButton"
	action_beat_button.text = "AIM ON TARGET - CLICK ARENA OR PRESS SPACE"
	action_beat_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_beat_button.focus_mode = Control.FOCUS_NONE
	action_beat_button.custom_minimum_size = Vector2(0, 38)
	action_beat_button.add_theme_font_size_override("font_size", 18)
	action_beat_button.pressed.connect(_on_action_beat_pressed)
	beat_layout.add_child(action_beat_button)

	action_target_ring = _make_action_marker("ActionTargetRing", Color(1.0, 0.24, 0.16), 4)
	table_stage.add_child(action_target_ring)
	action_target_ring.visible = false

	action_aim_reticle = _make_action_marker("ActionAimReticle", Color(0.42, 0.86, 1.0), 2)
	table_stage.add_child(action_aim_reticle)
	action_aim_reticle.visible = false

	var opponent_panel := PanelContainer.new()
	opponent_panel.name = "OpponentCardsPanel"
	opponent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opponent_panel.size_flags_stretch_ratio = 0.54
	table_row.add_child(opponent_panel)

	var intent_column := VBoxContainer.new()
	intent_column.name = "IntentColumn"
	intent_column.custom_minimum_size = Vector2(300, 0)
	intent_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intent_column.add_theme_constant_override("separation", 6)
	opponent_panel.add_child(intent_column)

	opponent_title_label = Label.new()
	opponent_title_label.name = "OpponentTargetTitle"
	opponent_title_label.text = "Enemy Fighters"
	opponent_title_label.add_theme_font_size_override("font_size", 18)
	opponent_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_column.add_child(opponent_title_label)

	enemy_target_cards_row = HBoxContainer.new()
	enemy_target_cards_row.name = "EnemyTargetCards"
	enemy_target_cards_row.add_theme_constant_override("separation", 6)
	intent_column.add_child(enemy_target_cards_row)

	enemy_status_label = RichTextLabel.new()
	enemy_status_label.name = "EnemyStatus"
	enemy_status_label.bbcode_enabled = false
	enemy_status_label.fit_content = true
	enemy_status_label.scroll_active = false
	enemy_status_label.custom_minimum_size = Vector2(320, 112)
	intent_column.add_child(enemy_status_label)

	intent_icon_strip_label = RichTextLabel.new()
	intent_icon_strip_label.name = "IntentIconStrip"
	intent_icon_strip_label.bbcode_enabled = false
	intent_icon_strip_label.fit_content = true
	intent_icon_strip_label.scroll_active = false
	intent_icon_strip_label.custom_minimum_size = Vector2(320, 72)
	intent_column.add_child(intent_icon_strip_label)

	threat_summary_label = RichTextLabel.new()
	threat_summary_label.name = "ThreatSummary"
	threat_summary_label.bbcode_enabled = false
	threat_summary_label.fit_content = true
	threat_summary_label.scroll_active = false
	threat_summary_label.custom_minimum_size = Vector2(320, 76)
	intent_column.add_child(threat_summary_label)

	var target_controls_panel := PanelContainer.new()
	target_controls_panel.name = "TargetControlsPanel"
	target_controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_column.add_child(target_controls_panel)

	var target_controls_layout := VBoxContainer.new()
	target_controls_layout.name = "TargetControlsLayout"
	target_controls_layout.add_theme_constant_override("separation", 4)
	target_controls_panel.add_child(target_controls_layout)

	var target_title := Label.new()
	target_title.text = "Advanced Target Controls"
	target_title.add_theme_font_size_override("font_size", 16)
	target_controls_layout.add_child(target_title)

	var target_options_row := HBoxContainer.new()
	target_options_row.name = "TargetOptionsRow"
	target_options_row.add_theme_constant_override("separation", 6)
	target_controls_layout.add_child(target_options_row)

	var enemy_target_box := VBoxContainer.new()
	enemy_target_box.name = "EnemyTargetBox"
	enemy_target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_options_row.add_child(enemy_target_box)

	var enemy_target_label := Label.new()
	enemy_target_label.text = "Enemy"
	enemy_target_box.add_child(enemy_target_label)

	target_enemy_option = OptionButton.new()
	target_enemy_option.name = "TargetEnemyOption"
	target_enemy_option.tooltip_text = "Cards that hit or read enemies use this target."
	target_enemy_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_enemy_option.item_selected.connect(_on_target_enemy_selected)
	enemy_target_box.add_child(target_enemy_option)

	var move_target_box := VBoxContainer.new()
	move_target_box.name = "MoveTargetBox"
	move_target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_options_row.add_child(move_target_box)

	var move_target_label := Label.new()
	move_target_label.text = "Move"
	move_target_box.add_child(move_target_label)

	movement_cell_option = OptionButton.new()
	movement_cell_option.name = "MovementCellOption"
	movement_cell_option.tooltip_text = "Movement and trap cards use this table cell."
	movement_cell_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	movement_cell_option.item_selected.connect(_on_movement_cell_selected)
	move_target_box.add_child(movement_cell_option)

	intent_preview_label = RichTextLabel.new()
	intent_preview_label.name = "IntentPreview"
	intent_preview_label.bbcode_enabled = false
	intent_preview_label.fit_content = false
	intent_preview_label.custom_minimum_size = Vector2(320, 230)
	intent_preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intent_column.add_child(intent_preview_label)

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
	bluff_title.name = "BluffTitle"
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
	table_row.add_child(log_column)
	combat_log_column = log_column

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
	combat_grid.connect("cell_selected", _on_grid_cell_selected)

	var deck_panel := PanelContainer.new()
	deck_panel.name = "DeckPanel"
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(deck_panel)

	var deck_layout := VBoxContainer.new()
	deck_layout.name = "DeckLayout"
	deck_layout.add_theme_constant_override("separation", 8)
	deck_panel.add_child(deck_layout)

	pile_counts_label = Label.new()
	pile_counts_label.text = "Draw: 0 | Hand: 0 | Discard: 0 | Exhaust: 0"
	pile_counts_label.add_theme_font_size_override("font_size", 16)
	deck_layout.add_child(pile_counts_label)

	hand_action_status_label = Label.new()
	hand_action_status_label.name = "HandActionStatus"
	hand_action_status_label.text = "Cards locked until the table opens."
	hand_action_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_action_status_label.custom_minimum_size = Vector2(0, 28)
	hand_action_status_label.add_theme_font_size_override("font_size", 15)
	hand_action_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.68))
	hand_action_status_label.add_theme_constant_override("shadow_offset_x", 1)
	hand_action_status_label.add_theme_constant_override("shadow_offset_y", 1)
	deck_layout.add_child(hand_action_status_label)

	shooter_economy_label = Label.new()
	shooter_economy_label.name = "ShooterEconomyStrip"
	shooter_economy_label.text = "CHIPS 7 | ARMOR 0 | AMMO 18 | LOADOUT EMPTY"
	shooter_economy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shooter_economy_label.add_theme_font_size_override("font_size", 15)
	shooter_economy_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	deck_layout.add_child(shooter_economy_label)

	objective_plan_label = Label.new()
	objective_plan_label.name = "ObjectivePlanLabel"
	objective_plan_label.text = "NEXT FPS OBJECTIVE: Hold Pot"
	objective_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_plan_label.custom_minimum_size = Vector2(0, 44)
	objective_plan_label.add_theme_font_size_override("font_size", 14)
	objective_plan_label.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))
	objective_plan_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.70))
	objective_plan_label.add_theme_constant_override("shadow_offset_x", 1)
	objective_plan_label.add_theme_constant_override("shadow_offset_y", 1)
	deck_layout.add_child(objective_plan_label)

	reward_mods_label = Label.new()
	reward_mods_label.name = "RewardModsLabel"
	reward_mods_label.text = "ACTIVE MODS: none"
	reward_mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_mods_label.custom_minimum_size = Vector2(0, 34)
	reward_mods_label.add_theme_font_size_override("font_size", 13)
	reward_mods_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	deck_layout.add_child(reward_mods_label)

	_build_reward_artifact_panel(deck_layout)
	_build_hero_class_selector(deck_layout)

	loadout_slot_row = HBoxContainer.new()
	loadout_slot_row.name = "LoadoutSlotRow"
	loadout_slot_row.add_theme_constant_override("separation", 6)
	deck_layout.add_child(loadout_slot_row)
	for slot_id in ["weapon", "ability_1", "ability_2", "passive", "wager"]:
		var slot_button := Button.new()
		slot_button.name = "LoadoutSlot_%s" % slot_id
		slot_button.text = "%s\nEMPTY" % _get_loadout_slot_label(slot_id)
		slot_button.focus_mode = Control.FOCUS_NONE
		slot_button.clip_text = true
		slot_button.custom_minimum_size = Vector2(132, 48)
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.pressed.connect(_on_loadout_slot_pressed.bind(slot_id))
		loadout_slot_buttons[slot_id] = slot_button
		loadout_slot_row.add_child(slot_button)

	armory_plan_label = Label.new()
	armory_plan_label.name = "ArmoryPlanLabel"
	armory_plan_label.text = "ARMORY: draw a hand, then build a kit."
	armory_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	armory_plan_label.custom_minimum_size = Vector2(0, 64)
	armory_plan_label.add_theme_font_size_override("font_size", 13)
	armory_plan_label.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
	deck_layout.add_child(armory_plan_label)

	hand_action_button_row = HBoxContainer.new()
	hand_action_button_row.name = "HandCardActionRow"
	hand_action_button_row.add_theme_constant_override("separation", 6)
	deck_layout.add_child(hand_action_button_row)

	slot_selected_button = Button.new()
	slot_selected_button.name = "SlotSelectedCardButton"
	slot_selected_button.text = "Slot Selected"
	slot_selected_button.pressed.connect(_on_slot_selected_card_pressed)
	hand_action_button_row.add_child(slot_selected_button)

	burn_selected_button = Button.new()
	burn_selected_button.name = "BurnSelectedCardButton"
	burn_selected_button.text = "Burn +2 Chips"
	burn_selected_button.pressed.connect(_on_burn_selected_card_pressed)
	hand_action_button_row.add_child(burn_selected_button)

	hold_selected_button = Button.new()
	hold_selected_button.name = "HoldSelectedCardButton"
	hold_selected_button.text = "Hold"
	hold_selected_button.pressed.connect(_on_hold_selected_card_pressed)
	hand_action_button_row.add_child(hold_selected_button)

	upgrade_selected_button = Button.new()
	upgrade_selected_button.name = "UpgradeSelectedCardButton"
	upgrade_selected_button.text = "Upgrade"
	upgrade_selected_button.pressed.connect(_on_upgrade_selected_card_pressed)
	hand_action_button_row.add_child(upgrade_selected_button)

	mutate_selected_button = Button.new()
	mutate_selected_button.name = "MutateSelectedCardButton"
	mutate_selected_button.text = "Mutate"
	mutate_selected_button.pressed.connect(_on_mutate_selected_card_pressed)
	hand_action_button_row.add_child(mutate_selected_button)

	recommend_loadout_button = Button.new()
	recommend_loadout_button.name = "RecommendLoadoutButton"
	recommend_loadout_button.text = "Recommend Loadout"
	recommend_loadout_button.pressed.connect(_on_recommend_loadout_pressed)
	hand_action_button_row.add_child(recommend_loadout_button)

	bridge_payload_button = Button.new()
	bridge_payload_button.name = "CombatBridgePayloadButton"
	bridge_payload_button.text = "Preview Payload"
	bridge_payload_button.pressed.connect(_on_bridge_payload_pressed)
	hand_action_button_row.add_child(bridge_payload_button)

	enter_arena_button = Button.new()
	enter_arena_button.name = "EnterArenaButton"
	enter_arena_button.text = "Enter Arena"
	enter_arena_button.pressed.connect(_on_enter_arena_pressed)
	hand_action_button_row.add_child(enter_arena_button)

	card_action_hint_label = RichTextLabel.new()
	card_action_hint_label.name = "CardActionHint"
	card_action_hint_label.bbcode_enabled = false
	card_action_hint_label.fit_content = true
	card_action_hint_label.scroll_active = false
	card_action_hint_label.custom_minimum_size = Vector2(0, 64)
	deck_layout.add_child(card_action_hint_label)

	card_target_preview_label = RichTextLabel.new()
	card_target_preview_label.name = "CardTargetPreview"
	card_target_preview_label.bbcode_enabled = false
	card_target_preview_label.fit_content = true
	card_target_preview_label.scroll_active = false
	card_target_preview_label.custom_minimum_size = Vector2(0, 100)
	deck_layout.add_child(card_target_preview_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.custom_minimum_size = Vector2(0, 154)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_layout.add_child(hand_scroll)

	hand_view = HBoxContainer.new()
	hand_view.name = "HandView"
	hand_view.set_script(HAND_VIEW_SCRIPT)
	hand_scroll.add_child(hand_view)
	_apply_phase35_default_layout(
		layout,
		title,
		subtitle,
		run_path_panel,
		run_shell_panel,
		turn_label,
		phase_label,
		resource_state_label,
		turn_status_panel,
		table_rule_panel,
		guidance_panel,
		feedback_panel,
		recipe_panel,
		run_panel,
		action_cue_panel,
		primary_controls,
		debug_drawer_panel,
		body,
		deck_panel,
		log_column
	)

	deck_manager = Node.new()
	deck_manager.name = "DeckManager"
	deck_manager.set_script(DECK_MANAGER_SCRIPT)
	add_child(deck_manager)
	deck_manager.connect("log_requested", _on_log_requested)
	deck_manager.connect("hand_changed", _on_hand_changed)
	deck_manager.connect("piles_changed", _on_piles_changed)
	deck_manager.connect("card_played", _on_card_played)
	hand_view.connect("card_clicked", _on_card_clicked)
	hand_view.connect("card_previewed", _on_card_previewed)
	hand_view.connect("card_preview_cleared", _on_card_preview_cleared)

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

	run_manager = Node.new()
	run_manager.name = "RunManager"
	run_manager.set_script(RUN_MANAGER_SCRIPT)
	add_child(run_manager)
	run_manager.connect("log_requested", _on_log_requested)
	run_manager.connect("state_changed", _on_run_state_changed)
	_update_debug_visibility()


func _build_hero_class_selector(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "HeroClassSelector"
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = "CLASS"
	label.custom_minimum_size = Vector2(48, 0)
	label.add_theme_color_override("font_color", Color(0.70, 0.88, 0.90))
	row.add_child(label)

	hero_class_option = OptionButton.new()
	hero_class_option.name = "HeroClassOption"
	hero_class_option.custom_minimum_size = Vector2(190, 34)
	_populate_hero_class_option(hero_class_option)
	hero_class_option.item_selected.connect(_on_hero_class_selected)
	row.add_child(hero_class_option)

	hero_class_summary_label = Label.new()
	hero_class_summary_label.name = "HeroClassSummary"
	hero_class_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_class_summary_label.add_theme_font_size_override("font_size", 12)
	hero_class_summary_label.add_theme_color_override("font_color", Color(0.74, 0.92, 0.96))
	row.add_child(hero_class_summary_label)
	_refresh_hero_class_selector()


func _build_start_hero_class_selector(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "StartHeroClassPanel"
	_style_play_panel(panel, Color(0.030, 0.022, 0.025, 0.88), Color(0.96, 0.66, 0.24, 0.72), "cue")
	parent.add_child(panel)

	var layout := VBoxContainer.new()
	layout.name = "StartHeroClassLayout"
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var label := Label.new()
	label.text = "CHOOSE YOUR FIGHTER"
	label.custom_minimum_size = Vector2(188, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38))
	layout.add_child(label)

	start_hero_class_summary_label = Label.new()
	start_hero_class_summary_label.name = "StartHeroClassSummary"
	start_hero_class_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_hero_class_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_hero_class_summary_label.add_theme_font_size_override("font_size", 12)
	start_hero_class_summary_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0))
	layout.add_child(start_hero_class_summary_label)

	var spotlight := HBoxContainer.new()
	spotlight.name = "StartHeroClassSpotlight"
	spotlight.add_theme_constant_override("separation", 10)
	layout.add_child(spotlight)

	start_hero_class_art = TextureRect.new()
	start_hero_class_art.name = "StartHeroClassArt"
	start_hero_class_art.custom_minimum_size = Vector2(360, 104)
	start_hero_class_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	start_hero_class_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	spotlight.add_child(start_hero_class_art)

	start_hero_class_loadout_label = Label.new()
	start_hero_class_loadout_label.name = "StartHeroClassLoadout"
	start_hero_class_loadout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_hero_class_loadout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_hero_class_loadout_label.add_theme_font_size_override("font_size", 14)
	start_hero_class_loadout_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72))
	spotlight.add_child(start_hero_class_loadout_label)

	var card_row := HBoxContainer.new()
	card_row.name = "StartHeroClassCards"
	card_row.add_theme_constant_override("separation", 8)
	layout.add_child(card_row)

	start_hero_class_card_buttons.clear()
	for index in range(HERO_CLASS_OPTIONS.size()):
		var entry: Dictionary = HERO_CLASS_OPTIONS[index]
		var button := _build_start_hero_class_card(entry, index)
		start_hero_class_card_buttons.append(button)
		card_row.add_child(button)

	start_hero_class_option = OptionButton.new()
	start_hero_class_option.name = "StartHeroClassOption"
	start_hero_class_option.visible = false
	_populate_hero_class_option(start_hero_class_option)
	start_hero_class_option.item_selected.connect(_on_start_hero_class_selected)
	layout.add_child(start_hero_class_option)
	_refresh_hero_class_selector()


func _build_start_hero_class_card(entry: Dictionary, index: int) -> Button:
	var class_id := String(entry.get("id", "gambler_knight"))
	var button := Button.new()
	button.name = "StartHeroClassCard%d" % index
	button.text = "%s\n%s\n%s" % [
		String(entry.get("label", "Fighter")),
		String(entry.get("role", "Role")).to_upper(),
		String(entry.get("deck_focus", "Opening deck ready."))
	]
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.custom_minimum_size = Vector2(0, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("hero_class_id", class_id)
	button.tooltip_text = "%s: %s" % [String(entry.get("label", "Fighter")), String(entry.get("summary", ""))]
	button.pressed.connect(Callable(self, "_on_start_hero_class_card_pressed").bind(class_id))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 12)
	_style_start_hero_class_button(button, entry, class_id == selected_hero_class_id)
	return button


func _set_descendant_mouse_filter(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_descendant_mouse_filter(child, filter)


func _populate_hero_class_option(option: OptionButton) -> void:
	option.clear()
	for index in range(HERO_CLASS_OPTIONS.size()):
		var entry: Dictionary = HERO_CLASS_OPTIONS[index]
		option.add_item("%s - %s" % [String(entry.get("label", "Class")), String(entry.get("role", "Role"))], index)
		option.set_item_metadata(index, String(entry.get("id", "gambler_knight")))


func _on_hero_class_selected(index: int) -> void:
	_select_hero_class_from_option(hero_class_option, index)


func _on_start_hero_class_selected(index: int) -> void:
	_select_hero_class_from_option(start_hero_class_option, index)


func _on_start_hero_class_card_pressed(class_id: String) -> void:
	_select_hero_class_id(class_id)


func _select_hero_class_from_option(option: OptionButton, index: int) -> void:
	if option == null:
		return
	var metadata: Variant = option.get_item_metadata(index)
	_select_hero_class_id(String(metadata) if metadata != null else "gambler_knight")


func _select_hero_class_id(class_id: String) -> void:
	selected_hero_class_id = class_id
	if run_flow_state == RUN_FLOW_START and run_manager != null:
		run_manager.call("reset_run", selected_hero_class_id)
		_reset_playable_combat()
		_push_feedback("Class deck ready: %s." % _get_selected_hero_class_label(), FEEDBACK_CARD_COLOR, start_hero_class_summary_label)
	_refresh_hero_class_selector()
	_refresh_loadout_ui()


func _refresh_hero_class_selector() -> void:
	if hero_class_option != null:
		for index in range(hero_class_option.item_count):
			if String(hero_class_option.get_item_metadata(index)) == selected_hero_class_id:
				hero_class_option.select(index)
				break
	if start_hero_class_option != null:
		for index in range(start_hero_class_option.item_count):
			if String(start_hero_class_option.get_item_metadata(index)) == selected_hero_class_id:
				start_hero_class_option.select(index)
				break
	if hero_class_summary_label != null:
		hero_class_summary_label.text = _get_selected_hero_class_summary()
	if start_hero_class_summary_label != null:
		start_hero_class_summary_label.text = _get_selected_hero_class_summary()
	var selected_entry := _get_hero_class_entry(selected_hero_class_id)
	if start_hero_class_art != null:
		start_hero_class_art.texture = DEAD_MANS_ANTE_SKIN_SCRIPT.load_texture(String(selected_entry.get("art", "")))
	if start_hero_class_loadout_label != null:
		start_hero_class_loadout_label.text = "%s\n%s\n%s" % [
			String(selected_entry.get("label", "Fighter")),
			String(selected_entry.get("deck_focus", "Opening deck ready.")),
			String(selected_entry.get("arena_line", "FPS kit ready."))
		]
	for button in start_hero_class_card_buttons:
		var class_id := String(button.get_meta("hero_class_id", "gambler_knight"))
		_style_start_hero_class_button(button, _get_hero_class_entry(class_id), class_id == selected_hero_class_id)


func _build_reward_artifact_panel(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "ArenaRewardArtifacts"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_play_panel(panel, Color(0.064, 0.050, 0.033, 0.84), Color(1.0, 0.60, 0.24, 0.72), "cue")
	parent.add_child(panel)

	var layout := VBoxContainer.new()
	layout.name = "ArenaRewardArtifactLayout"
	layout.add_theme_constant_override("separation", 5)
	panel.add_child(layout)

	var title := Label.new()
	title.name = "ArenaRewardArtifactsTitle"
	title.text = "ARENA ARTIFACTS"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	layout.add_child(title)

	reward_artifact_row = HBoxContainer.new()
	reward_artifact_row.name = "RewardArtifactRow"
	reward_artifact_row.add_theme_constant_override("separation", 6)
	layout.add_child(reward_artifact_row)

	reward_artifact_detail_label = RichTextLabel.new()
	reward_artifact_detail_label.name = "RewardArtifactDetail"
	reward_artifact_detail_label.bbcode_enabled = true
	reward_artifact_detail_label.fit_content = true
	reward_artifact_detail_label.scroll_active = false
	reward_artifact_detail_label.custom_minimum_size = Vector2(0, 64)
	reward_artifact_detail_label.add_theme_font_size_override("normal_font_size", 12)
	reward_artifact_detail_label.add_theme_color_override("default_color", Color(0.90, 0.92, 0.93))
	layout.add_child(reward_artifact_detail_label)
	_refresh_reward_artifact_cards()


func _style_start_hero_class_button(button: Button, entry: Dictionary, active: bool) -> void:
	if button == null:
		return
	var color: Color = entry.get("accent", FEEDBACK_CARD_COLOR)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r * 0.18, color.g * 0.15, color.b * 0.12, 0.58 if active else 0.36)
	normal.border_color = Color(color.r, color.g, color.b, 0.96 if active else 0.46)
	normal.set_border_width_all(3 if active else 1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 8
	normal.content_margin_top = 8
	normal.content_margin_right = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(color.r * 0.24, color.g * 0.20, color.b * 0.16, 0.70)
	hover.border_color = Color(color.r, color.g, color.b, 1.0)
	hover.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.modulate = Color.WHITE if active else Color(0.84, 0.86, 0.88, 0.84)
	button.tooltip_text = "%s: %s" % [String(entry.get("label", "Fighter")), String(entry.get("summary", ""))]


func _get_hero_class_entry(class_id: String) -> Dictionary:
	for entry in HERO_CLASS_OPTIONS:
		if String(entry.get("id", "")) == class_id:
			return entry
	return HERO_CLASS_OPTIONS[0]


func _get_hero_class_accent(class_id: String) -> Color:
	var entry := _get_hero_class_entry(class_id)
	return Color(entry.get("accent", FEEDBACK_CARD_COLOR))


func _get_selected_hero_class_summary() -> String:
	for entry in HERO_CLASS_OPTIONS:
		if String(entry.get("id", "")) == selected_hero_class_id:
			return "%s: %s %s" % [
				String(entry.get("role", "Role")),
				String(entry.get("summary", "")),
				String(entry.get("arena_line", "FPS kit ready."))
			]
	return "Duelist: +2 armor, card powers cool down faster."


func _get_selected_hero_class_label() -> String:
	for entry in HERO_CLASS_OPTIONS:
		if String(entry.get("id", "")) == selected_hero_class_id:
			return String(entry.get("label", "Gambler-Knight"))
	return "Gambler-Knight"


func _apply_phase35_default_layout(
	layout: VBoxContainer,
	title: Label,
	subtitle: Label,
	run_path_panel: Control,
	run_shell_panel: Control,
	turn_label: Control,
	phase_label: Control,
	resource_state_label: Control,
	turn_status_panel: Control,
	table_rule_panel: Control,
	guidance_panel: Control,
	feedback_panel: Control,
	recipe_panel: Control,
	run_panel: Control,
	action_cue_panel: Control,
	primary_controls: Control,
	debug_drawer_panel: Control,
	body: Control,
	deck_panel: Control,
	log_column: Control
) -> void:
	layout.add_theme_constant_override("separation", 6)
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
	subtitle.visible = false
	var title_parent := title.get_parent()
	if title_parent is PanelContainer:
		_style_play_panel(title_parent as PanelContainer, Color(0.075, 0.044, 0.050, 0.95), Color(0.88, 0.62, 0.24), "header")
	run_header_label.add_theme_stylebox_override(
		"normal",
		DEAD_MANS_ANTE_SKIN_SCRIPT.make_panel_style(Color(0.052, 0.040, 0.040, 0.92), Color(0.70, 0.50, 0.24), "header")
	)
	var table_board_panel: Node = body.find_child("TableBoardPanel", true, false)
	if table_board_panel is PanelContainer:
		_style_play_panel(table_board_panel as PanelContainer, Color(0.12, 0.105, 0.085), Color(0.72, 0.56, 0.26))
	var opponent_panel: Node = body.find_child("OpponentCardsPanel", true, false)
	if opponent_panel is PanelContainer:
		_style_play_panel(opponent_panel as PanelContainer, Color(0.10, 0.095, 0.105), Color(0.46, 0.48, 0.56))
	var target_controls_panel: Node = body.find_child("TargetControlsPanel", true, false)
	if target_controls_panel is PanelContainer:
		_style_play_panel(target_controls_panel as PanelContainer, Color(0.13, 0.115, 0.09), Color(0.68, 0.55, 0.28))
	if run_shell_panel is PanelContainer:
		_style_play_panel(run_shell_panel as PanelContainer, Color(0.105, 0.085, 0.072), Color(0.64, 0.45, 0.22))
	if guidance_panel is PanelContainer:
		_style_play_panel(guidance_panel as PanelContainer, Color(0.085, 0.088, 0.095), Color(0.38, 0.50, 0.62))
	if feedback_panel is PanelContainer:
		_style_play_panel(feedback_panel as PanelContainer, Color(0.095, 0.080, 0.072), Color(0.56, 0.40, 0.22))
	if run_path_panel is PanelContainer:
		_style_play_panel(run_path_panel as PanelContainer, Color(0.075, 0.078, 0.082), Color(0.34, 0.34, 0.38))
	if turn_status_panel is PanelContainer:
		_style_play_panel(turn_status_panel as PanelContainer, Color(0.070, 0.060, 0.055), Color(0.52, 0.42, 0.26))
	if table_rule_panel is PanelContainer:
		_style_play_panel(table_rule_panel as PanelContainer, Color(0.060, 0.058, 0.066), Color(0.44, 0.34, 0.58))
	if recipe_panel is PanelContainer:
		_style_play_panel(recipe_panel as PanelContainer, Color(0.058, 0.052, 0.048), Color(0.46, 0.36, 0.24))
	if run_panel is PanelContainer:
		_style_play_panel(run_panel as PanelContainer, Color(0.065, 0.052, 0.048), Color(0.58, 0.40, 0.20))
	if debug_drawer_panel is PanelContainer:
		_style_play_panel(debug_drawer_panel as PanelContainer, Color(0.052, 0.052, 0.056), Color(0.32, 0.32, 0.35))
	if action_cue_panel is PanelContainer:
		_style_play_panel(action_cue_panel as PanelContainer, Color(0.062, 0.046, 0.040), Color(0.82, 0.56, 0.22), "cue")
	if first_play_coach_panel is PanelContainer:
		_style_play_panel(first_play_coach_panel as PanelContainer, Color(0.070, 0.052, 0.036), Color(0.92, 0.64, 0.24), "cue")
	if deck_panel is PanelContainer:
		_style_play_panel(deck_panel as PanelContainer, Color(0.070, 0.050, 0.038), Color(0.78, 0.54, 0.24), "hand")
	if arena_payout_panel != null:
		_style_play_panel(arena_payout_panel, Color(0.090, 0.064, 0.040, 0.96), FEEDBACK_CARD_COLOR, "cue")
	if run_ceremony_panel != null:
		_style_play_panel(run_ceremony_panel, Color(0.070, 0.052, 0.046), Color(0.68, 0.48, 0.22))
	if encounter_approach_panel != null:
		_style_play_panel(encounter_approach_panel, Color(0.060, 0.055, 0.058), Color(0.58, 0.44, 0.24))
	if run_finale_panel != null:
		_style_play_panel(run_finale_panel, Color(0.070, 0.052, 0.052), Color(0.76, 0.52, 0.22))
	if run_inspector_panel != null:
		_style_play_panel(run_inspector_panel, Color(0.052, 0.050, 0.052), Color(0.42, 0.36, 0.30))

	run_header_label.custom_minimum_size = Vector2(0, 42)
	run_path_label.custom_minimum_size = Vector2(0, 42)
	run_path_preview_label.custom_minimum_size = Vector2(0, 64)
	run_shell_detail_label.custom_minimum_size = Vector2(0, 42)
	run_continuity_label.custom_minimum_size = Vector2(0, 32)
	encounter_preview_label.custom_minimum_size = Vector2(0, 64)
	run_ceremony_label.custom_minimum_size = Vector2(0, 72)

	body.custom_minimum_size = Vector2(0, 0)
	var table_row: Node = body.find_child("TableRow", true, false)
	if table_row is Control:
		(table_row as Control).custom_minimum_size = Vector2(0, 430)
		(table_row as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	combat_grid.custom_minimum_size = Vector2(760, 430)
	enemy_status_label.custom_minimum_size = Vector2(320, 92)
	intent_icon_strip_label.custom_minimum_size = Vector2(360, 58)
	threat_summary_label.custom_minimum_size = Vector2(360, 58)
	intent_preview_label.custom_minimum_size = Vector2(360, 104)
	bluff_state_label.custom_minimum_size = Vector2(360, 64)
	live_state_chip_row.custom_minimum_size = Vector2(0, 34)
	first_play_path_label.custom_minimum_size = Vector2(0, 50)
	first_play_step_row.custom_minimum_size = Vector2(0, 34)
	card_action_hint_label.custom_minimum_size = Vector2(0, 48)
	card_target_preview_label.custom_minimum_size = Vector2(0, 74)
	action_cue_panel.custom_minimum_size = Vector2(0, 72)
	if first_play_coach_panel != null:
		first_play_coach_panel.custom_minimum_size = Vector2(0, 38)
	if hand_action_status_label != null:
		hand_action_status_label.custom_minimum_size = Vector2(0, 28)

	var hand_scroll: Node = deck_panel.find_child("HandScroll", true, false)
	if hand_scroll is Control:
		(hand_scroll as Control).custom_minimum_size = Vector2(0, 154)

	if deck_panel.get_parent() != body:
		var previous_parent := deck_panel.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(deck_panel)
		body.add_child(deck_panel)

	next_phase_button.custom_minimum_size = Vector2(220, 44)
	next_phase_button.add_theme_font_size_override("font_size", 18)
	toggle_debug_button.custom_minimum_size = Vector2(112, 36)

	turn_label.visible = false
	phase_label.visible = false
	resource_state_label.visible = false
	log_column.visible = false

	layout.move_child(run_header_label, 1)
	layout.move_child(run_shell_panel, 2)
	layout.move_child(action_cue_panel, 3)
	layout.move_child(primary_controls, 4)
	layout.move_child(body, 5)
	layout.move_child(run_path_panel, 6)
	layout.move_child(guidance_panel, 7)
	layout.move_child(turn_status_panel, 8)
	layout.move_child(table_rule_panel, 9)
	layout.move_child(feedback_panel, 10)
	layout.move_child(run_panel, 11)
	layout.move_child(debug_drawer_panel, 12)
	layout.move_child(recipe_panel, 13)


func _style_play_panel(panel: PanelContainer, bg_color: Color, border_color: Color, kind: String = "panel") -> void:
	if panel == null:
		return

	DEAD_MANS_ANTE_SKIN_SCRIPT.apply_panel(panel, bg_color, border_color, kind)


func _make_action_marker(marker_name: String, color: Color, border_width: int) -> PanelContainer:
	var marker := PanelContainer.new()
	marker.name = marker_name
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 58
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.10)
	style.border_color = color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	marker.add_theme_stylebox_override("panel", style)
	return marker


func _create_compact_chip(chip_name: String, label: String) -> Button:
	var chip := Button.new()
	chip.name = chip_name
	chip.text = label
	chip.focus_mode = Control.FOCUS_NONE
	chip.clip_text = true
	chip.custom_minimum_size = Vector2(96, 30)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_compact_button(chip, false, Color(0.56, 0.56, 0.58), "Compact state.")
	return chip


func _style_compact_button(button: Button, active: bool, color: Color, tooltip: String) -> void:
	if button == null:
		return

	button.tooltip_text = tooltip
	button.add_theme_font_size_override("font_size", 13 if active else 12)
	DEAD_MANS_ANTE_SKIN_SCRIPT.apply_chip(button, active, color, tooltip)


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
	_show_phase_feedback(phase_key)

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
	if run_flow_state == RUN_FLOW_START:
		_on_start_run_pressed()
		return
	if arena_payout_pending:
		_on_arena_payout_continue_pressed()
		return
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		_on_next_encounter_pressed()
		return
	if run_flow_state == RUN_FLOW_REWARD:
		_append_log("Choose or skip rewards before the next table.")
		return
	if run_flow_state == RUN_FLOW_RESULTS:
		_append_log("Run is complete. Start a new run to play again.")
		return
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset to start a new loop.")
		return
	if String(combat_session.get("current_phase_key")) == "PLAYER_COMMIT":
		_record_first_play_step("resolve")
		_play_resolve_anticipation()
	_advance_play_loop()


func _advance_play_loop() -> void:
	var phase_key: String = String(combat_session.get("current_phase_key"))
	match phase_key:
		"START_TURN", "DRAW", "ENEMY_INTENT_PREVIEW":
			_advance_to_phase("PLAYER_COMMIT", 4)
		"PLAYER_COMMIT":
			if bool(deck_manager.call("has_committed_card")):
				_advance_to_phase("BLUFF_WAGER", 2)
			else:
				_advance_to_phase("RESOLVE", 4)
		"BLUFF_WAGER", "REVEAL":
			_advance_to_phase("RESOLVE", 3)
		"RESOLVE", "CLEANUP":
			_advance_to_phase("PLAYER_COMMIT", 6)
		_:
			turn_manager.advance_phase()


func _play_resolve_anticipation() -> void:
	var target := _get_selected_enemy_target()
	var target_id := StringName(target.get("id", &"")) if not target.is_empty() else _get_selected_enemy_target_id()
	var target_name := String(target.get("name", "enemy fighter")) if not target.is_empty() else "enemy fighter"
	var target_center := _get_unit_vfx_position(target_id)
	if battlefield_callout_label != null:
		battlefield_callout_label.text = "Resolve: cards hit, enemies answer, Blood and Guard update."
		_pulse_canvas_item(battlefield_callout_label, FEEDBACK_REVEAL_COLOR)
	if battlefield_focus_label != null:
		_pulse_canvas_item(battlefield_focus_label, FEEDBACK_REVEAL_COLOR)
	if combat_vfx != null and target_center != Vector2.ZERO:
		if combat_vfx.has_method("play_target_lock_at"):
			combat_vfx.call("play_target_lock_at", target_center, FEEDBACK_REVEAL_COLOR)
		if combat_vfx.has_method("play_ring_at"):
			combat_vfx.call("play_ring_at", target_center, FEEDBACK_CARD_COLOR, 54.0)
	if arena_view != null and arena_view.has_method("focus_unit") and not target_id.is_empty():
		arena_view.call("focus_unit", target_id)
	_push_feedback("Resolving against %s. Watch the battlefield, not the old debug log." % target_name, FEEDBACK_REVEAL_COLOR, battlefield_focus_label)


func _advance_to_phase(target_phase: String, max_steps: int) -> void:
	for _index in range(max_steps):
		var current_phase: String = String(combat_session.get("current_phase_key"))
		if current_phase == target_phase:
			return
		if bool(combat_session.get("combat_over")) and target_phase != "RESOLVE":
			return
		turn_manager.advance_phase()


func _on_reset_pressed() -> void:
	log_label.clear()
	_reset_run_slice()


func _on_start_run_pressed() -> void:
	if run_flow_state != RUN_FLOW_START:
		return
	var run_state: Dictionary = run_manager.call("get_state")
	if String(run_state.get("hero_class", selected_hero_class_id)) != selected_hero_class_id:
		run_manager.call("reset_run", selected_hero_class_id)
		_reset_playable_combat()
	_set_run_flow_state(RUN_FLOW_COMBAT)
	_advance_to_phase("PLAYER_COMMIT", 4)
	_sync_hand_card_interaction()
	_record_first_play_step("open")
	_append_log("Opening Table dealt: pick a target and play a card.")
	_push_feedback("Opening Table dealt: pick a target and play a card.", FEEDBACK_PHASE_COLOR, run_path_label)
	_refresh_action_controls()


func _on_next_encounter_pressed() -> void:
	if run_manager == null:
		return

	var state: Dictionary = run_manager.call("get_state")
	if String(state.get("run_outcome", "running")) != "running":
		_refresh_action_controls()
		return
	if bool(state.get("waiting_for_reward", false)) or not bool(state.get("can_start_current_node", false)):
		_append_log("Resolve rewards before dealing the next table.")
		_refresh_action_controls()
		return

	var node_name: String = String(state.get("current_node_name", "Next Table"))
	var table_number: int = min(int(state.get("current_node_index", 0)) + 1, int(state.get("current_node_count", 0)))
	var table_count: int = int(state.get("current_node_count", 0))
	_set_run_flow_state(RUN_FLOW_COMBAT)
	_append_log("%s is live." % node_name)
	_append_log("Approach complete: %s dealt from the run map into combat." % node_name)
	_record_run_ceremony("Approach: %s dealt into combat. The ceremony hands back to turn play." % node_name, FEEDBACK_PHASE_COLOR, run_shell_panel)
	_reset_playable_combat()
	_advance_to_phase("PLAYER_COMMIT", 4)
	_push_feedback("Run map: moving to Table %d/%d - %s." % [
		table_number,
		table_count,
		node_name
	], FEEDBACK_PHASE_COLOR, run_path_label)
	_push_feedback("Approach: %s dealt into combat. Read the table, pick a target, then play." % node_name, FEEDBACK_PHASE_COLOR, run_shell_panel)
	_surface_latest_table_rule_effect()


func _on_reset_grid_pressed() -> void:
	_apply_current_tactical_map()
	combat_grid.call("reset_grid", run_manager.call("get_current_enemy_spawns"))
	_sync_arena_units()


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
	selected_hand_index = hand_index
	_refresh_loadout_ui()
	if not bool(combat_session.call("can_play_cards")):
		_append_log("Cards can only be played during Player Commit.")
		_push_feedback("Locked: %s" % _get_global_card_lock_reason(combat_session.call("get_state")), FEEDBACK_PHASE_COLOR, card_action_hint_label)
		return

	var card: Resource = deck_manager.call("get_card_at", hand_index)
	if card == null:
		_append_log("No card at hand index %d." % hand_index)
		return

	var source_card_view := _get_hand_card_view(hand_index)
	if source_card_view != null and source_card_view.has_method("play_feedback"):
		source_card_view.call("play_feedback", FEEDBACK_CARD_COLOR)

	var cost := _get_card_cost(card)
	var card_name := _get_card_name(card)
	pending_card_context = _build_card_context(card)
	if not _validate_card_context(card, pending_card_context):
		pending_card_context.clear()
		return

	if not bool(combat_session.call("spend_energy", cost, card_name)):
		_push_feedback("Blocked: %s needs %d Energy." % [card_name, cost], FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		pending_card_context.clear()
		return

	var play_context := pending_card_context.duplicate()
	if not bool(deck_manager.call("play_card_at", hand_index)):
		combat_session.call("refund_energy", cost, "%s failed to play" % card_name)
		pending_card_context.clear()
	else:
		_play_card_commit_vfx(card, play_context, source_card_view, false)
		_mark_recipe_step("play_or_commit")


func _on_card_played(card: Resource) -> void:
	_push_feedback("Card: %s played." % _get_card_name(card), FEEDBACK_CARD_COLOR, card_action_hint_label)
	_record_first_play_step("card")
	if _should_start_action_duel(card):
		_start_action_duel(card, pending_card_context.duplicate())
		return

	_apply_played_card_effect(card, pending_card_context)
	pending_card_context.clear()
	_refresh_targeting_options()


func _on_slot_selected_card_pressed() -> void:
	_slot_selected_card()


func _on_burn_selected_card_pressed() -> void:
	_burn_selected_card()


func _on_hold_selected_card_pressed() -> void:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before changing the next hand.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return
	if selected_hand_index < 0:
		_push_feedback("Hover or click a card first, then Hold.", FEEDBACK_PHASE_COLOR, hand_action_status_label)
		return
	held_hand_indices[selected_hand_index] = true
	_push_feedback("Held card %d for later. Hold is a planning promise until the combat bridge owns persistence." % (selected_hand_index + 1), FEEDBACK_PHASE_COLOR, hand_action_status_label)
	_refresh_loadout_ui()


func _on_upgrade_selected_card_pressed() -> void:
	_upgrade_selected_card(false)


func _on_mutate_selected_card_pressed() -> void:
	_upgrade_selected_card(true)


func _on_recommend_loadout_pressed() -> void:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before changing the next hand.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return
	if deck_manager == null:
		_push_feedback("Deck is not ready for loadout recommendations.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		return
	var target_mode := _get_recommended_objective_for_current_hand()
	var slotted_lines: Array[String] = []
	for slot_id in _get_recommended_slot_order_for_objective(target_mode):
		if loadout_slots.has(slot_id):
			continue
		var hand_index := _find_recommended_hand_index_for_slot(slot_id, target_mode)
		if hand_index < 0:
			continue
		var result := _slot_hand_card_at(hand_index, slot_id)
		if not bool(result.get("ok", false)):
			continue
		var slotted_card: Resource = result.get("card", null)
		slotted_lines.append("%s -> %s" % [
			_get_card_name(slotted_card),
			_get_loadout_slot_label(String(result.get("slot_id", slot_id)))
		])
		if _get_slotted_card_count() >= 3 and target_mode != "boss_gate":
			break
	if slotted_lines.is_empty():
		_push_feedback("No affordable hand card fits the %s recommendation. Burn a card or draw before auto-slotting." % _get_objective_label(target_mode), FEEDBACK_DAMAGE_COLOR, shooter_economy_label)
	else:
		_push_feedback("Recommended %s loadout: %s." % [_get_objective_label(target_mode), _join_string_array(slotted_lines, ", ")], FEEDBACK_MOVE_COLOR, shooter_economy_label)
	_refresh_loadout_ui()


func _on_bridge_payload_pressed() -> void:
	var payload := _build_combat_bridge_payload()
	_append_log("Combat bridge payload: %s" % JSON.stringify(payload))
	_push_feedback("Bridge payload ready: %d chips, %d slotted card%s." % [
		shooter_chips,
		_get_slotted_card_count(),
		"" if _get_slotted_card_count() == 1 else "s"
	], FEEDBACK_CARD_COLOR, shooter_economy_label)


func _on_enter_arena_pressed() -> void:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before entering another fight.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return
	var payload := _build_combat_bridge_payload()
	if _get_slotted_card_count() <= 0:
		_push_feedback("Slot at least one card before entering the arena.", FEEDBACK_DAMAGE_COLOR, shooter_economy_label)
		return
	arena_bridge_payload = payload
	arena_round_armed = true
	var weapon_label := String(payload.get("weapon_card", ""))
	if weapon_label.is_empty():
		weapon_label = "sidearm"
	var ability_cards: Array = payload.get("ability_cards", [])
	var ability_count := ability_cards.size()
	var economy: Dictionary = payload.get("economy", {})
	_append_log("ENTER ARENA: %s" % JSON.stringify(payload))
	_push_feedback("Arena armed: %s, %d ability card%s, %d armor, %d ammo." % [
		weapon_label,
		ability_count,
		"" if ability_count == 1 else "s",
		int(economy.get("armor", 0)),
		int(economy.get("ammo", 0))
	], FEEDBACK_MOVE_COLOR, shooter_economy_label)
	if battlefield_callout_label != null:
		battlefield_callout_label.text = "ARENA LIVE: your slotted cards are now shooter kit. Fight, spend, survive, then collect payout."
		_pulse_canvas_item(battlefield_callout_label, FEEDBACK_MOVE_COLOR)
	if arena_view != null and arena_view.has_method("focus_unit"):
		arena_view.call("focus_unit", &"player")
	_refresh_loadout_ui()
	var spent_bonuses := _get_arena_bonus_snapshot()
	_clear_arena_bonuses()
	var return_state := _build_arena_return_state()
	return_state["spent_arena_bonuses"] = spent_bonuses
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge != null and bridge.has_method("set_payload"):
		bridge.call("set_payload", payload, "res://scenes/combat/TestCombat.tscn", return_state)
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://scenes/fps/FPSPrototype.tscn")


func _consume_pending_arena_result() -> void:
	var bridge := get_node_or_null("/root/ArenaBridge")
	if bridge == null:
		return
	if not bridge.has_method("has_pending_result") or not bool(bridge.call("has_pending_result")):
		return
	if not bridge.has_method("take_result"):
		return
	var result: Dictionary = bridge.call("take_result")
	if bridge.has_method("has_pending_return_state") and bool(bridge.call("has_pending_return_state")) and bridge.has_method("take_return_state"):
		var return_state: Dictionary = bridge.call("take_return_state")
		_restore_arena_return_state(return_state)
	_apply_arena_result(result)


func _apply_arena_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	var cleared := bool(result.get("cleared", String(result.get("outcome", "win")) != "defeat"))
	pending_arena_result = result.duplicate(true)
	pending_arena_effect_lines = _apply_arena_payout_effects(result) if cleared else ["Run lost: FPS defeat ended this table."]
	arena_payout_pending = true
	shooter_chips += int(result.get("chips_awarded", 0))
	loadout_slots.clear()
	held_hand_indices.clear()
	arena_bridge_payload.clear()
	arena_round_armed = false
	selected_hand_index = -1
	if deck_manager != null:
		if bool(deck_manager.call("has_committed_card")):
			deck_manager.call("resolve_committed_card")
		deck_manager.call("discard_hand")
		if deck_manager.has_method("resolve_loadout_pile"):
			deck_manager.call("resolve_loadout_pile")
		if cleared:
			var base_draw := int(result.get("cards_to_draw", combat_session.get("hand_target")))
			var next_draw := _get_next_hand_draw_count_after_wounds(base_draw)
			pending_arena_result["cards_drawn_after_wounds"] = next_draw
			pending_arena_result["wound_draw_penalty"] = _get_wound_draw_penalty()
			deck_manager.call("draw_cards", maxi(0, next_draw))
	if not cleared and run_manager != null and run_manager.has_method("apply_arena_defeat"):
		run_manager.call("apply_arena_defeat", result)
	_set_run_flow_state(RUN_FLOW_COMBAT)
	_append_log("ARENA PAYOUT: %s" % JSON.stringify(result))
	_refresh_arena_payout_panel()
	_refresh_loadout_ui()
	_refresh_action_controls()
	if battlefield_callout_label != null:
		battlefield_callout_label.text = "ARENA PAYOUT: collect the reward, then build the next hand into another loadout."
		_pulse_canvas_item(battlefield_callout_label, FEEDBACK_CARD_COLOR)


func _refresh_arena_payout_panel() -> void:
	if arena_payout_panel == null:
		return
	arena_payout_panel.visible = arena_payout_pending and run_flow_state == RUN_FLOW_COMBAT
	if arena_payout_label != null:
		arena_payout_label.text = _get_arena_payout_text(pending_arena_result)
	if arena_payout_continue_button != null:
		arena_payout_continue_button.disabled = not arena_payout_pending
		arena_payout_continue_button.text = "VIEW RUN RESULTS" if _arena_result_ends_run() else "COLLECT PAYOUT - BUILD NEXT HAND"
		_style_compact_button(arena_payout_continue_button, arena_payout_pending, FEEDBACK_CARD_COLOR, "Collect the FPS arena payout and unlock the next prep hand.")


func _get_arena_payout_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var cleared := bool(result.get("cleared", String(result.get("outcome", "win")) != "defeat"))
	var reward: Dictionary = result.get("selected_reward", {})
	var reward_label := String(reward.get("label", "Arena Payout")) if cleared else "Arena Lost"
	var reward_amount := int(reward.get("amount", 0))
	var reward_kind := String(reward.get("kind", "reward")).capitalize()
	var reward_line := "%s +%d" % [reward_kind, reward_amount] if reward_amount > 0 else reward_kind
	var hit_rate := float(result.get("hit_rate", 0.0)) * 100.0
	var clear_time := float(result.get("clear_time", 0.0))
	var chips := int(result.get("chips_awarded", 0))
	var cards_to_draw := int(result.get("cards_drawn_after_wounds", result.get("cards_to_draw", combat_session.get("hand_target"))))
	var draw_penalty := int(result.get("wound_draw_penalty", 0))
	var headline := "[b]%s[/b]" % reward_label
	var draw_text := "Draw %d next-hand cards%s" % [cards_to_draw, " (-%d wound)" % draw_penalty if draw_penalty > 0 else ""]
	var economy_line := "+%d Chips | %s | %s" % [chips, reward_line, draw_text] if cleared else "Defeat | %d kills | %d damage taken" % [int(result.get("kills", 0)), int(result.get("damage_taken", 0))]
	var effects_line := "Effects: %s" % _join_string_array(pending_arena_effect_lines, " | ") if not pending_arena_effect_lines.is_empty() else "Effects: none"
	var progression_line := "Progression: +%d Card XP | Wounds %d total | Active mods %d" % [
		_calculate_arena_card_xp(result),
		arena_wounds_total,
		active_reward_mods.size()
	]
	var objective_line := "%s %s: %d" % [
		String(result.get("objective_label", "Objective")),
		"complete" if bool(result.get("objective_completed", false)) else ("failed" if bool(result.get("objective_failed", false)) else "partial"),
		int(result.get("objective_score", 0))
	]
	var class_line := "Class: %s | Passive: %s | Ability uses: %d" % [
		String(result.get("hero", "Gambler-Knight")),
		String(result.get("class_passive", "Ante Guard")),
		_count_ability_uses(result.get("ability_uses", {}))
	]
	var next_line := "Next: collect this payout, then slot/burn/upgrade the new hand for the next FPS arena."
	return "[center][font_size=26][b]ARENA PAYOUT READY[/b][/font_size]\n%s[/center]\n\n[b]%s[/b]\n%s\n%s\n%s\n%s\n%s Wave %d: %d kills, %.0f%% hit rate, %.1fs, %s." % [
		next_line,
		headline,
		economy_line,
		effects_line,
		progression_line,
		class_line,
		String(result.get("map_name", "Arena")),
		int(result.get("wave", 1)),
		int(result.get("kills", 0)),
		hit_rate,
		clear_time,
		objective_line
	]


func _count_ability_uses(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var uses: Dictionary = value
	var total := 0
	for count in uses.values():
		total += int(count)
	return total


func _on_arena_payout_continue_pressed() -> void:
	if not arena_payout_pending:
		return
	var ends_run := _arena_result_ends_run()
	arena_payout_pending = false
	pending_arena_result.clear()
	pending_arena_effect_lines.clear()
	_refresh_arena_payout_panel()
	_refresh_loadout_ui()
	_refresh_action_controls()
	if ends_run:
		_set_run_flow_state(RUN_FLOW_RESULTS)
		_push_feedback("Arena defeat recorded. Review the run results.", FEEDBACK_DAMAGE_COLOR, run_finale_panel)
	else:
		_push_feedback("Payout collected. Build this hand into the next arena loadout.", FEEDBACK_CARD_COLOR, shooter_economy_label)


func _arena_result_ends_run() -> bool:
	if pending_arena_result.is_empty():
		return false
	if not bool(pending_arena_result.get("cleared", String(pending_arena_result.get("outcome", "win")) != "defeat")):
		return true
	if run_manager != null:
		var state: Dictionary = run_manager.call("get_state")
		return String(state.get("run_outcome", "running")) != "running"
	return false


func _apply_arena_payout_effects(result: Dictionary) -> Array[String]:
	var effects: Array[String] = []
	var reward: Dictionary = result.get("selected_reward", {})
	var kind := String(reward.get("kind", "chips"))
	var amount := int(reward.get("amount", 0))
	match kind:
		"damage":
			arena_weapon_damage_bonus += amount
			effects.append("Next arena weapon +%d damage" % amount)
		"armor":
			arena_carryover_armor += amount
			effects.append("+%d armor carried into next arena" % amount)
		"ammo":
			arena_carryover_ammo += amount
			effects.append("+%d ammo reserve carried into next arena" % amount)
		_:
			effects.append("Chip payout banked")
	var mod := _record_arena_reward_mod(result)
	if not mod.is_empty():
		effects.append("Mod acquired: %s %s" % [String(mod.get("rarity", "Common")), String(mod.get("label", "Arena Mod"))])
	var card_xp := _calculate_arena_card_xp(result)
	arena_card_xp_pool += card_xp
	if card_xp > 0:
		effects.append("+%d Card XP banked" % card_xp)
	var wounds := int(result.get("wounds_taken", 0))
	if wounds > 0:
		arena_wounds_total += wounds
		effects.append("+%d Wound%s recorded" % [wounds, "" if wounds == 1 else "s"])
	if arena_wounds_total > 0:
		var chip_tax := _get_wound_chip_tax()
		if chip_tax > 0:
			shooter_chips = maxi(0, shooter_chips - chip_tax)
		effects.append("%s" % _get_wound_burden_text())
	var objective_score := int(result.get("objective_score", 0))
	if bool(result.get("objective_completed", false)):
		shooter_chips += 1
		effects.append("%s objective +1 Chip" % String(result.get("objective_label", "Arena")))
	if objective_score >= 90:
		shooter_chips += 2
		effects.append("Objective bonus +2 Chips")
	return effects


func _record_arena_reward_mod(result: Dictionary) -> Dictionary:
	var mod := _build_arena_reward_mod(result)
	if mod.is_empty():
		return {}
	active_reward_mods.push_front(mod)
	while active_reward_mods.size() > 8:
		active_reward_mods.pop_back()
	if run_manager != null and run_manager.has_method("record_arena_reward_mod"):
		run_manager.call("record_arena_reward_mod", mod)
	return mod


func _build_arena_reward_mod(result: Dictionary) -> Dictionary:
	var reward: Dictionary = result.get("selected_reward", {})
	if reward.is_empty():
		return {}
	var label := String(reward.get("label", "Arena Mod"))
	var kind := String(reward.get("kind", "chips"))
	var amount := int(reward.get("amount", 0))
	var objective_mode := String(result.get("objective_mode", "hold_pot"))
	var objective_score := int(result.get("objective_score", 0))
	var rarity := String(reward.get("rarity", _get_arena_reward_mod_rarity(objective_score, bool(result.get("objective_completed", false)))))
	return {
		"id": String(reward.get("mod_id", _make_reward_mod_id(label, kind))),
		"kind": kind,
		"label": label,
		"amount": amount,
		"rarity": rarity,
		"objective_mode": objective_mode,
		"objective_label": String(result.get("objective_label", _get_objective_label(objective_mode))),
		"bias_modes": _string_array_from_variant(reward.get("bias_modes", _get_reward_mod_bias_modes(kind, objective_mode))),
		"summary": String(reward.get("summary", _get_reward_mod_summary(label, kind, amount))),
		"card_xp": _calculate_arena_card_xp(result),
		"wounds": int(result.get("wounds_taken", 0)),
		"source": "fps_arena"
	}


func _get_arena_reward_mod_rarity(objective_score: int, completed: bool) -> String:
	if completed and objective_score >= 95:
		return "Rare"
	if completed and objective_score >= 80:
		return "Uncommon"
	return "Common"


func _make_reward_mod_id(label: String, kind: String) -> String:
	return "%s_%s" % [kind, label.to_lower().replace(" ", "_").replace("-", "_")]


func _get_reward_mod_summary(label: String, kind: String, amount: int) -> String:
	match kind:
		"damage":
			return "%s adds +%d weapon pressure to the next build and favors duel/boss plans." % [label, amount]
		"armor":
			return "%s adds +%d armor value and favors hold/defend plans." % [label, amount]
		"ammo":
			return "%s adds +%d reserve ammo and favors extract/duel plans." % [label, amount]
		_:
			return "%s banks economy for the next hand." % label


func _get_reward_mod_bias_modes(kind: String, objective_mode: String) -> Array[String]:
	match kind:
		"damage":
			return ["duel", "boss_gate", objective_mode]
		"armor":
			return ["defend", "hold_pot", objective_mode]
		"ammo":
			return ["extract", "duel", objective_mode]
		_:
			return [objective_mode]


func _calculate_arena_card_xp(result: Dictionary) -> int:
	if result.is_empty() or not bool(result.get("cleared", String(result.get("outcome", "win")) != "defeat")):
		return 0
	var xp := 2 + int(result.get("kills", 0))
	if bool(result.get("objective_completed", false)):
		xp += 2
	if int(result.get("objective_score", 0)) >= 90:
		xp += 2
	xp += mini(3, _count_ability_uses(result.get("ability_uses", {})))
	return xp


func _string_array_from_variant(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for entry in value:
			var text := String(entry)
			if not text.is_empty() and not out.has(text):
				out.append(text)
	return out


func _dictionary_array_from_variant(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(value) == TYPE_ARRAY:
		for entry in value:
			if typeof(entry) == TYPE_DICTIONARY:
				out.append((entry as Dictionary).duplicate(true))
	return out


func _build_arena_return_state() -> Dictionary:
	return {
		"schema": 1,
		"run_flow_state": run_flow_state,
		"run_manager": run_manager.call("get_snapshot") if run_manager != null and run_manager.has_method("get_snapshot") else {},
		"deck_manager": deck_manager.call("get_snapshot") if deck_manager != null and deck_manager.has_method("get_snapshot") else {},
		"shooter_chips": shooter_chips,
		"arena_carryover_armor": arena_carryover_armor,
		"arena_carryover_ammo": arena_carryover_ammo,
		"arena_weapon_damage_bonus": arena_weapon_damage_bonus,
		"active_reward_mods": active_reward_mods.duplicate(true),
		"card_upgrade_mods": card_upgrade_mods.duplicate(true),
		"arena_card_xp_pool": arena_card_xp_pool,
		"arena_wounds_total": arena_wounds_total,
		"held_hand_indices": held_hand_indices.duplicate(true),
		"selected_hand_index": selected_hand_index,
		"arena_bridge_payload": arena_bridge_payload.duplicate(true),
		"arena_round_armed": arena_round_armed,
		"selected_hero_class_id": selected_hero_class_id,
		"loadout_slot_paths": _serialize_loadout_slots()
	}


func _restore_arena_return_state(return_state: Dictionary) -> void:
	if return_state.is_empty():
		return
	if run_manager != null and run_manager.has_method("restore_snapshot"):
		var run_snapshot: Dictionary = return_state.get("run_manager", {})
		run_manager.call("restore_snapshot", run_snapshot)
	if deck_manager != null and deck_manager.has_method("restore_snapshot"):
		var deck_snapshot: Dictionary = return_state.get("deck_manager", {})
		deck_manager.call("restore_snapshot", deck_snapshot)
	shooter_chips = int(return_state.get("shooter_chips", shooter_chips))
	arena_carryover_armor = int(return_state.get("arena_carryover_armor", arena_carryover_armor))
	arena_carryover_ammo = int(return_state.get("arena_carryover_ammo", arena_carryover_ammo))
	arena_weapon_damage_bonus = int(return_state.get("arena_weapon_damage_bonus", arena_weapon_damage_bonus))
	active_reward_mods = _dictionary_array_from_variant(return_state.get("active_reward_mods", active_reward_mods))
	card_upgrade_mods = _dictionary_from_variant(return_state.get("card_upgrade_mods", card_upgrade_mods))
	arena_card_xp_pool = int(return_state.get("arena_card_xp_pool", arena_card_xp_pool))
	arena_wounds_total = int(return_state.get("arena_wounds_total", arena_wounds_total))
	held_hand_indices = Dictionary(return_state.get("held_hand_indices", {})).duplicate(true)
	selected_hand_index = int(return_state.get("selected_hand_index", selected_hand_index))
	arena_bridge_payload = Dictionary(return_state.get("arena_bridge_payload", {})).duplicate(true)
	arena_round_armed = bool(return_state.get("arena_round_armed", arena_round_armed))
	selected_hero_class_id = String(return_state.get("selected_hero_class_id", selected_hero_class_id))
	loadout_slots = _deserialize_loadout_slots(return_state.get("loadout_slot_paths", {}))
	_apply_current_tactical_map()
	if combat_grid != null and run_manager != null:
		combat_grid.call("reset_grid", run_manager.call("get_current_enemy_spawns"))
	_reset_combat_state()
	_reset_enemy_intents()
	_refresh_loadout_ui()
	_refresh_hero_class_selector()
	_refresh_action_controls()


func _serialize_loadout_slots() -> Dictionary:
	var serialized := {}
	for slot_id in loadout_slots.keys():
		var card: Resource = loadout_slots[slot_id]
		if card != null and not String(card.resource_path).is_empty():
			serialized[String(slot_id)] = String(card.resource_path)
	return serialized


func _deserialize_loadout_slots(serialized: Variant) -> Dictionary:
	var restored := {}
	if typeof(serialized) != TYPE_DICTIONARY:
		return restored
	var paths: Dictionary = serialized
	for slot_id in paths.keys():
		var card := load(String(paths[slot_id]))
		if card is Resource:
			restored[String(slot_id)] = card
	return restored


func _get_arena_bonus_snapshot() -> Dictionary:
	return {
		"armor": arena_carryover_armor,
		"ammo": arena_carryover_ammo,
		"weapon_damage": arena_weapon_damage_bonus,
		"reward_mods": active_reward_mods.duplicate(true),
		"card_upgrade_mods": card_upgrade_mods.duplicate(true),
		"card_xp_pool": arena_card_xp_pool,
		"wounds_total": arena_wounds_total
	}


func _clear_arena_bonuses() -> void:
	arena_carryover_armor = 0
	arena_carryover_ammo = 0
	arena_weapon_damage_bonus = 0


func _upgrade_selected_card(mutate: bool = false) -> bool:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before changing the next hand.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return false
	if selected_hand_index < 0:
		_push_feedback("Select a hand card first, then upgrade it with Card XP.", FEEDBACK_PHASE_COLOR, hand_action_status_label)
		return false
	if deck_manager == null:
		_push_feedback("Deck is not ready for armory work.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		return false
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		selected_hand_index = -1
		_push_feedback("Selected card is no longer in hand.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		_refresh_loadout_ui()
		return false
	var result := _apply_card_upgrade_purchase(card, mutate)
	if not bool(result.get("ok", false)):
		var card_name := _get_card_name(card)
		match String(result.get("code", "")):
			"xp":
				_push_feedback("Need %d Card XP to %s %s; you have %d." % [
					int(result.get("cost", 0)),
					"mutate" if mutate else "upgrade",
					card_name,
					arena_card_xp_pool
				], FEEDBACK_DAMAGE_COLOR, reward_mods_label)
			"max":
				_push_feedback("%s is already at upgrade cap." % card_name, FEEDBACK_CARD_COLOR, hand_action_status_label)
			"mutated":
				_push_feedback("%s already has a mutation." % card_name, FEEDBACK_CARD_COLOR, hand_action_status_label)
			_:
				_push_feedback(String(result.get("reason", "Could not upgrade that card.")), FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		_refresh_loadout_ui()
		return false
	var summary := String(result.get("summary", _get_card_upgrade_summary(card)))
	_push_feedback("%s upgraded: %s." % [_get_card_name(card), summary], FEEDBACK_CARD_COLOR, hand_action_status_label)
	_refresh_loadout_ui()
	return true


func _apply_card_upgrade_purchase(card: Resource, mutate: bool = false) -> Dictionary:
	if card == null:
		return {"ok": false, "code": "card", "reason": "No card selected."}
	var card_id := _get_card_upgrade_key(card)
	if card_id.is_empty():
		return {"ok": false, "code": "card", "reason": "Card has no upgrade key."}
	var upgrade := _get_card_upgrade(card)
	var cost := _get_card_mutation_cost(card) if mutate else _get_card_upgrade_cost(card)
	if arena_card_xp_pool < cost:
		return {"ok": false, "code": "xp", "cost": cost}
	if mutate:
		if not String(upgrade.get("mutation", "")).is_empty():
			return {"ok": false, "code": "mutated"}
		upgrade["mutation"] = _get_card_mutation_for_card(card)
	else:
		var current_level := int(upgrade.get("level", 0))
		if current_level >= 3:
			return {"ok": false, "code": "max"}
		upgrade["level"] = current_level + 1
	arena_card_xp_pool -= cost
	upgrade["id"] = card_id
	upgrade["spent_xp"] = int(upgrade.get("spent_xp", 0)) + cost
	upgrade["source"] = "armory"
	card_upgrade_mods[card_id] = upgrade
	var payload := _get_card_upgrade_payload(card)
	return {
		"ok": true,
		"cost": cost,
		"upgrade": payload.duplicate(true),
		"summary": _format_card_upgrade_summary(payload)
	}


func _get_card_upgrade(card: Resource) -> Dictionary:
	var card_id := _get_card_upgrade_key(card)
	if card_id.is_empty():
		return {}
	var existing: Variant = card_upgrade_mods.get(card_id, {})
	if typeof(existing) == TYPE_DICTIONARY:
		var upgrade: Dictionary = existing
		return upgrade.duplicate(true)
	return {}


func _get_card_upgrade_key(card: Resource) -> String:
	if card == null:
		return ""
	var card_id := String(card.get("id"))
	if not card_id.is_empty():
		return card_id
	return String(card.resource_path)


func _get_card_upgrade_level(card: Resource) -> int:
	return clampi(int(_get_card_upgrade(card).get("level", 0)), 0, 3)


func _get_card_upgrade_mutation(card: Resource) -> String:
	return String(_get_card_upgrade(card).get("mutation", ""))


func _get_card_upgrade_cost(card: Resource) -> int:
	var level := _get_card_upgrade_level(card)
	return 4 + level * 3


func _get_card_mutation_cost(card: Resource) -> int:
	return 7 + _get_card_upgrade_level(card) * 2


func _get_card_mutation_for_card(card: Resource) -> String:
	match _get_card_vfx_style(card):
		&"attack":
			return "Deadeye"
		&"guard":
			return "Bulwark"
		&"move":
			return "Fleet"
		&"read":
			return "Marked"
		&"trap":
			return "Snare"
		&"ritual", &"bluff":
			return "Wager"
	var latest_kind := ""
	if not active_reward_mods.is_empty() and typeof(active_reward_mods[0]) == TYPE_DICTIONARY:
		latest_kind = String((active_reward_mods[0] as Dictionary).get("kind", ""))
	match latest_kind:
		"damage":
			return "Deadeye"
		"armor":
			return "Bulwark"
		"ammo":
			return "Fleet"
	return "Lucky"


func _get_card_upgrade_damage_bonus(card: Resource) -> int:
	var level := _get_card_upgrade_level(card)
	var mutation := _get_card_upgrade_mutation(card)
	var bonus := 0
	match _get_card_vfx_style(card):
		&"attack", &"read", &"trap", &"ritual":
			bonus += level
	if mutation == "Deadeye":
		bonus += 2
	elif mutation == "Marked" or mutation == "Wager":
		bonus += 1
	return bonus


func _get_card_upgrade_guard_bonus(card: Resource) -> int:
	var level := _get_card_upgrade_level(card)
	var mutation := _get_card_upgrade_mutation(card)
	var bonus := 0
	match _get_card_vfx_style(card):
		&"guard":
			bonus += level * 2
		&"move":
			bonus += level
	if mutation == "Bulwark":
		bonus += 3
	elif mutation == "Fleet":
		bonus += 1
	return bonus


func _get_card_upgrade_slot_discount(card: Resource) -> int:
	var mutation := _get_card_upgrade_mutation(card)
	if mutation == "Fleet":
		return 1
	return 1 if _get_card_upgrade_level(card) >= 3 else 0


func _get_card_upgrade_cooldown_discount(card: Resource) -> float:
	var discount := float(_get_card_upgrade_level(card)) * 0.45
	match _get_card_upgrade_mutation(card):
		"Fleet":
			discount += 1.0
		"Marked", "Snare":
			discount += 0.65
		"Bulwark":
			discount += 0.4
	return discount


func _get_card_upgrade_duration_bonus(card: Resource) -> float:
	var bonus := float(_get_card_upgrade_level(card)) * 0.55
	match _get_card_upgrade_mutation(card):
		"Marked", "Snare", "Wager":
			bonus += 1.0
	return bonus


func _get_card_upgrade_context(card: Resource) -> Dictionary:
	return {
		"upgrade_level": _get_card_upgrade_level(card),
		"upgrade_mutation": _get_card_upgrade_mutation(card),
		"upgrade_damage_bonus": _get_card_upgrade_damage_bonus(card),
		"upgrade_guard_bonus": _get_card_upgrade_guard_bonus(card)
	}


func _get_card_upgrade_payload(card: Resource) -> Dictionary:
	var upgrade := _get_card_upgrade(card)
	if upgrade.is_empty():
		return {}
	upgrade["level"] = _get_card_upgrade_level(card)
	upgrade["mutation"] = _get_card_upgrade_mutation(card)
	upgrade["damage_bonus"] = _get_card_upgrade_damage_bonus(card)
	upgrade["guard_bonus"] = _get_card_upgrade_guard_bonus(card)
	upgrade["slot_discount"] = _get_card_upgrade_slot_discount(card)
	upgrade["cooldown_discount"] = _get_card_upgrade_cooldown_discount(card)
	upgrade["duration_bonus"] = _get_card_upgrade_duration_bonus(card)
	upgrade["summary"] = _format_card_upgrade_summary(upgrade)
	return upgrade


func _get_card_upgrade_summary(card: Resource) -> String:
	var upgrade := _get_card_upgrade_payload(card)
	if upgrade.is_empty():
		return "L0 | upgrade %d XP | mutate %d XP" % [_get_card_upgrade_cost(card), _get_card_mutation_cost(card)]
	return _format_card_upgrade_summary(upgrade)


func _format_card_upgrade_summary(upgrade: Dictionary) -> String:
	var level := int(upgrade.get("level", 0))
	var mutation := String(upgrade.get("mutation", ""))
	var parts: Array[String] = ["L%d" % level]
	if not mutation.is_empty():
		parts.append(mutation)
	var damage := int(upgrade.get("damage_bonus", 0))
	var guard := int(upgrade.get("guard_bonus", 0))
	var discount := int(upgrade.get("slot_discount", 0))
	if damage > 0:
		parts.append("+%d dmg" % damage)
	if guard > 0:
		parts.append("+%d guard" % guard)
	if discount > 0:
		parts.append("-%d slot" % discount)
	return _join_string_array(parts, " ")


func _get_selected_card_upgrade_prompt() -> String:
	if selected_hand_index < 0 or deck_manager == null:
		return ""
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		return ""
	var summary := _get_card_upgrade_summary(card)
	var mutation := _get_card_upgrade_mutation(card)
	var mutate_text := "mutate %dXP" % _get_card_mutation_cost(card) if mutation.is_empty() else "mutated"
	var upgrade_text := "upgrade cap" if _get_card_upgrade_level(card) >= 3 else "upgrade %dXP" % _get_card_upgrade_cost(card)
	return "Selected %s: %s | %s | %s" % [_get_card_name(card), summary, upgrade_text, mutate_text]


func _selected_card_can_buy_upgrade(mutate: bool) -> bool:
	if selected_hand_index < 0 or deck_manager == null:
		return false
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		return false
	if mutate and not _get_card_upgrade_mutation(card).is_empty():
		return false
	if not mutate and _get_card_upgrade_level(card) >= 3:
		return false
	var cost := _get_card_mutation_cost(card) if mutate else _get_card_upgrade_cost(card)
	return arena_card_xp_pool >= cost


func _get_upgrade_button_tooltip(mutate: bool) -> String:
	if arena_payout_pending:
		return "Collect the arena payout first."
	if selected_hand_index < 0 or deck_manager == null:
		return "Select a hand card first."
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		return "Selected card is no longer in hand."
	if mutate and not _get_card_upgrade_mutation(card).is_empty():
		return "%s already has %s." % [_get_card_name(card), _get_card_upgrade_mutation(card)]
	if not mutate and _get_card_upgrade_level(card) >= 3:
		return "%s is at upgrade cap." % _get_card_name(card)
	var cost := _get_card_mutation_cost(card) if mutate else _get_card_upgrade_cost(card)
	var verb := "Mutate" if mutate else "Upgrade"
	return "%s %s for %d Card XP. Current: %s" % [verb, _get_card_name(card), cost, _get_card_upgrade_summary(card)]


func _get_wound_chip_tax() -> int:
	return mini(3, maxi(0, arena_wounds_total))


func _get_wound_draw_penalty() -> int:
	return mini(2, int(floor(float(arena_wounds_total + 1) / 2.0)))


func _get_wound_armor_penalty() -> int:
	return mini(8, maxi(0, arena_wounds_total * 2))


func _get_next_hand_draw_count_after_wounds(base_draw: int) -> int:
	return maxi(0, base_draw - _get_wound_draw_penalty())


func _get_wound_penalty_payload() -> Dictionary:
	return {
		"chip_tax": _get_wound_chip_tax(),
		"draw_penalty": _get_wound_draw_penalty(),
		"armor_penalty": _get_wound_armor_penalty()
	}


func _get_wound_burden_text() -> String:
	if arena_wounds_total <= 0:
		return ""
	return "Wound burden: -%d Chips on payout, -%d draw, -%d armor" % [
		_get_wound_chip_tax(),
		_get_wound_draw_penalty(),
		_get_wound_armor_penalty()
	]


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = value
		return dict.duplicate(true)
	return {}


func _join_string_array(values: Array[String], separator: String) -> String:
	var packed := PackedStringArray()
	for value in values:
		packed.append(value)
	return separator.join(packed)


func _on_loadout_slot_pressed(slot_id: String) -> void:
	if loadout_slots.has(slot_id):
		var card: Resource = loadout_slots[slot_id]
		_push_feedback("%s slot: %s." % [_get_loadout_slot_label(slot_id), _get_card_name(card)], FEEDBACK_CARD_COLOR, loadout_slot_buttons.get(slot_id, null))
		return
	_slot_selected_card(slot_id)


func _slot_selected_card(forced_slot: String = "") -> bool:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before changing the next hand.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return false
	if selected_hand_index < 0:
		_push_feedback("Hover or click a card first, then Slot.", FEEDBACK_PHASE_COLOR, hand_action_status_label)
		return false
	var result := _slot_hand_card_at(selected_hand_index, forced_slot)
	if not bool(result.get("ok", false)):
		match String(result.get("code", "")):
			"missing":
				_push_feedback("Selected card is no longer in hand.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
				selected_hand_index = -1
			"chips":
				_push_feedback("Need %d Chips to slot %s; you have %d." % [
					int(result.get("cost", 0)),
					String(result.get("card_name", "that card")),
					shooter_chips
				], FEEDBACK_DAMAGE_COLOR, shooter_economy_label)
			"slot_failed":
				_push_feedback("Could not slot that card; it may have moved already.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
				selected_hand_index = -1
			_:
				_push_feedback(String(result.get("reason", "Could not slot that card.")), FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		_refresh_loadout_ui()
		return false
	var slotted_card: Resource = result.get("card", null)
	var slot_id := String(result.get("slot_id", forced_slot))
	var slot_cost := int(result.get("cost", 0))
	_push_feedback("Slotted %s into %s for %d Chips." % [_get_card_name(slotted_card), _get_loadout_slot_label(slot_id), slot_cost], FEEDBACK_CARD_COLOR, loadout_slot_buttons.get(slot_id, null))
	_refresh_loadout_ui()
	return true


func _slot_hand_card_at(hand_index: int, forced_slot: String = "") -> Dictionary:
	if arena_payout_pending:
		return {"ok": false, "code": "payout", "reason": "Collect the arena payout before changing the next hand."}
	if deck_manager == null:
		return {"ok": false, "code": "deck", "reason": "Deck is not ready."}
	if hand_index < 0:
		return {"ok": false, "code": "index", "reason": "No hand card is selected."}
	var card: Resource = deck_manager.call("get_card_at", hand_index)
	if card == null:
		return {"ok": false, "code": "missing", "reason": "Selected card is no longer in hand."}
	var slot_id := forced_slot if not forced_slot.is_empty() else _get_recommended_loadout_slot(card)
	var slot_cost := _get_loadout_slot_cost(card, slot_id)
	if shooter_chips < slot_cost:
		return {
			"ok": false,
			"code": "chips",
			"reason": "Not enough Chips.",
			"card_name": _get_card_name(card),
			"cost": slot_cost
		}
	var slotted_card: Resource = deck_manager.call("slot_card_at", hand_index)
	if slotted_card == null:
		return {"ok": false, "code": "slot_failed", "reason": "Could not slot that card."}
	shooter_chips -= slot_cost
	loadout_slots[slot_id] = slotted_card
	held_hand_indices.erase(hand_index)
	arena_round_armed = false
	arena_bridge_payload.clear()
	selected_hand_index = min(hand_index, int(deck_manager.call("get_hand_count")) - 1)
	return {
		"ok": true,
		"card": slotted_card,
		"slot_id": slot_id,
		"cost": slot_cost
	}


func _burn_selected_card() -> bool:
	if arena_payout_pending:
		_push_feedback("Collect the arena payout before burning next-hand cards.", FEEDBACK_CARD_COLOR, arena_payout_continue_button)
		return false
	if selected_hand_index < 0:
		_push_feedback("Hover or click a card first, then Burn.", FEEDBACK_PHASE_COLOR, hand_action_status_label)
		return false
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index) if deck_manager != null else null
	if card == null:
		_push_feedback("Selected card is no longer in hand.", FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
		selected_hand_index = -1
		return false
	var burned: Resource = deck_manager.call("burn_card_at", selected_hand_index)
	if burned == null:
		return false
	shooter_chips += _get_card_burn_value(card)
	held_hand_indices.clear()
	selected_hand_index = min(selected_hand_index, int(deck_manager.call("get_hand_count")) - 1)
	_push_feedback("Burned %s for +%d Chips." % [_get_card_name(card), _get_card_burn_value(card)], FEEDBACK_CARD_COLOR, shooter_economy_label)
	_refresh_loadout_ui()
	return true


func _should_start_action_duel(card: Resource) -> bool:
	if card == null:
		return false
	var style: StringName = _get_card_vfx_style(card)
	return style == &"attack" or style == &"guard" or style == &"move" or style == &"read"


func _start_action_duel(card: Resource, context: Dictionary) -> void:
	var style: StringName = _get_card_vfx_style(card)
	var target_position: Vector2 = _get_card_vfx_target_position(card, context, battlefield_callout_label)
	if target_position == Vector2.ZERO:
		target_position = _get_canvas_item_global_center(battlefield_callout_label)
	active_action_card = card
	active_action_context = context
	active_action_target_position = target_position
	active_action_beat = ACTION_BEAT_RESOLVER_SCRIPT.make_beat(style, &"player", StringName(context.get("target_enemy_id", &"")), _get_card_name(card))
	if action_beat_panel != null:
		action_beat_panel.visible = true
	if action_target_ring != null:
		action_target_ring.visible = true
		_position_action_marker(action_target_ring, target_position, Vector2(104, 104))
	if action_aim_reticle != null:
		action_aim_reticle.visible = true
		_position_action_marker(action_aim_reticle, get_viewport().get_mouse_position(), Vector2(30, 30))
	if action_beat_progress != null:
		action_beat_progress.value = 0.0
	_update_action_beat_copy(999.0)
	_push_feedback("%s opens a live arena action: aim on the target, then strike." % _get_card_name(card), FEEDBACK_CARD_COLOR, battlefield_callout_label)
	if combat_vfx != null and combat_vfx.has_method("play_ring_at"):
		combat_vfx.call("play_ring_at", target_position, FEEDBACK_DAMAGE_COLOR if style == &"attack" else FEEDBACK_CARD_COLOR, 58.0)


func _on_action_beat_pressed() -> void:
	_complete_action_beat()


func _complete_action_beat() -> void:
	if active_action_beat.is_empty() or active_action_card == null:
		return
	var aim_position: Vector2 = get_viewport().get_mouse_position()
	var distance: float = aim_position.distance_to(active_action_target_position)
	var style: StringName = StringName(active_action_beat.get("style", &"attack"))
	var result: Dictionary = ACTION_BEAT_RESOLVER_SCRIPT.resolve_aim(style, distance, 42.0, 96.0, 164.0)
	active_action_context["action_beat_result"] = String(result.get("result", "hit"))
	active_action_context["action_multiplier"] = float(result.get("multiplier", 1.0))
	active_action_context["action_beat_label"] = String(result.get("label", "HIT"))
	_push_feedback(String(result.get("message", "Arena action resolved.")), _get_action_result_color(String(result.get("result", "hit"))), battlefield_callout_label)
	if combat_vfx != null and combat_vfx.has_method("play_burst_at"):
		combat_vfx.call("play_burst_at", active_action_target_position, _get_action_result_color(String(result.get("result", "hit"))), &"blood" if style == &"attack" else &"chip")
	_apply_played_card_effect(active_action_card, active_action_context)
	_clear_action_duel()
	pending_card_context.clear()
	_refresh_targeting_options()


func _apply_played_card_effect(card: Resource, context: Dictionary) -> void:
	if _is_movement_card(card):
		if String(context.get("action_beat_result", "hit")) == "miss":
			_push_feedback("%s misses the dodge line. No movement." % _get_card_name(card), FEEDBACK_DAMAGE_COLOR, battlefield_callout_label)
			return
		if bool(_resolve_movement_card(card, context)):
			_apply_card_side_effects(card, context)
	else:
		combat_resolver.call("apply_card_with_context", card, context)
		_apply_card_side_effects(card, context)


func _clear_action_duel() -> void:
	active_action_beat.clear()
	active_action_context.clear()
	active_action_card = null
	active_action_target_position = Vector2.ZERO
	if action_beat_panel != null:
		action_beat_panel.visible = false
	if action_target_ring != null:
		action_target_ring.visible = false
	if action_aim_reticle != null:
		action_aim_reticle.visible = false


func _position_action_marker(marker: Control, global_center: Vector2, marker_size: Vector2) -> void:
	if marker == null or not marker.is_inside_tree():
		return
	var parent_item: CanvasItem = marker.get_parent() as CanvasItem
	if parent_item == null:
		return
	var local_center: Vector2 = parent_item.get_global_transform_with_canvas().affine_inverse() * global_center
	marker.size = marker_size
	marker.position = local_center - marker_size * 0.5
	marker.pivot_offset = marker_size * 0.5


func _update_action_beat_copy(distance: float) -> void:
	if action_beat_label == null or active_action_beat.is_empty():
		return
	var label := "MISS"
	if distance <= 42.0:
		label = "CENTERED"
	elif distance <= 96.0:
		label = "ON TARGET"
	elif distance <= 164.0:
		label = "EDGE"
	action_beat_label.text = "%s\nAim on the target, then strike. %s" % [
		String(active_action_beat.get("card_name", "Action")).to_upper(),
		label
	]


func _get_action_result_color(result: String) -> Color:
	match result:
		"perfect":
			return Color(1.0, 0.88, 0.34)
		"hit":
			return FEEDBACK_DAMAGE_COLOR
		"graze":
			return FEEDBACK_CARD_COLOR
		_:
			return Color(0.55, 0.58, 0.64)


func _get_loadout_slot_label(slot_id: String) -> String:
	match slot_id:
		"weapon":
			return "Weapon"
		"ability_1":
			return "Ability 1"
		"ability_2":
			return "Ability 2"
		"passive":
			return "Passive"
		"wager":
			return "Wager"
		_:
			return slot_id.capitalize()


func _get_recommended_loadout_slot(card: Resource) -> String:
	match _get_card_vfx_style(card):
		&"attack":
			if not loadout_slots.has("weapon"):
				return "weapon"
			return _get_first_empty_loadout_slot("passive")
		&"move", &"guard", &"read", &"trap":
			if not loadout_slots.has("ability_1"):
				return "ability_1"
			if not loadout_slots.has("ability_2"):
				return "ability_2"
			return _get_first_empty_loadout_slot("passive")
		&"ritual", &"bluff":
			if not loadout_slots.has("wager"):
				return "wager"
			return _get_first_empty_loadout_slot("passive")
		_:
			return _get_first_empty_loadout_slot("passive")


func _get_first_empty_loadout_slot(fallback: String) -> String:
	for slot_id in ["weapon", "ability_1", "ability_2", "passive", "wager"]:
		if not loadout_slots.has(slot_id):
			return slot_id
	return fallback


func _get_loadout_slot_cost(card: Resource, slot_id: String) -> int:
	var base_cost: int = maxi(1, _get_card_cost(card))
	base_cost = maxi(1, base_cost - _get_card_upgrade_slot_discount(card))
	if slot_id == "passive":
		return max(1, base_cost + 1)
	if slot_id == "wager":
		return base_cost
	return base_cost


func _get_card_burn_value(card: Resource) -> int:
	return max(1, 1 + int(_get_card_cost(card) / 2))


func _get_slotted_card_count() -> int:
	var count := 0
	for value in loadout_slots.values():
		if value is Resource:
			count += 1
	return count


func _refresh_loadout_ui() -> void:
	var preview_objective_mode := _get_preview_objective_mode()
	if shooter_economy_label != null:
		var arena_state := "PAYOUT READY" if arena_payout_pending else ("ARENA READY" if arena_round_armed else "PREP")
		shooter_economy_label.text = "CHIPS %d | ARMOR %d | AMMO %d | SLOTTED %d/5 | CLASS %s | %s | SELECTED %s" % [
			shooter_chips,
			_get_bridge_armor_value(),
			_get_bridge_ammo_value(),
			_get_slotted_card_count(),
			selected_hero_class_id.replace("_", " ").to_upper(),
			arena_state,
			_get_selected_card_label()
		]
	if objective_plan_label != null:
		objective_plan_label.text = "NEXT FPS OBJECTIVE: %s\n%s%s" % [
			_get_objective_label(preview_objective_mode),
			_get_objective_plan_text(preview_objective_mode),
			_get_payout_bias_text()
		]
		objective_plan_label.tooltip_text = "The card table sends objective_mode=%s through the ArenaBridge payload." % preview_objective_mode
	if reward_mods_label != null:
		reward_mods_label.text = _get_reward_mods_label_text()
	_refresh_reward_artifact_cards()
	if armory_plan_label != null:
		armory_plan_label.text = _get_armory_plan_text(preview_objective_mode)
	_refresh_hero_class_selector()
	for slot_id in loadout_slot_buttons.keys():
		var button: Button = loadout_slot_buttons[slot_id]
		if loadout_slots.has(slot_id):
			var card: Resource = loadout_slots[slot_id]
			button.text = "%s\n%s" % [_get_loadout_slot_label(slot_id).to_upper(), _get_card_name(card)]
			button.tooltip_text = "%s is slotted for the combat bridge. Click another selected card action to replace it." % _get_card_name(card)
			_style_compact_button(button, true, FEEDBACK_CARD_COLOR, button.tooltip_text)
		else:
			button.text = "%s\nEMPTY" % _get_loadout_slot_label(slot_id).to_upper()
			button.tooltip_text = "Select a card, then click this slot or Slot Selected."
			_style_compact_button(button, false, Color(0.50, 0.46, 0.38), button.tooltip_text)
	if slot_selected_button != null:
		slot_selected_button.disabled = arena_payout_pending or selected_hand_index < 0
	if burn_selected_button != null:
		burn_selected_button.disabled = arena_payout_pending or selected_hand_index < 0
	if hold_selected_button != null:
		hold_selected_button.disabled = arena_payout_pending or selected_hand_index < 0
	if upgrade_selected_button != null:
		var can_upgrade := _selected_card_can_buy_upgrade(false)
		upgrade_selected_button.disabled = arena_payout_pending or not can_upgrade
		_style_compact_button(upgrade_selected_button, can_upgrade, FEEDBACK_CARD_COLOR, _get_upgrade_button_tooltip(false))
	if mutate_selected_button != null:
		var can_mutate := _selected_card_can_buy_upgrade(true)
		mutate_selected_button.disabled = arena_payout_pending or not can_mutate
		_style_compact_button(mutate_selected_button, can_mutate, FEEDBACK_REVEAL_COLOR, _get_upgrade_button_tooltip(true))
	if recommend_loadout_button != null:
		var hand_count := int(deck_manager.call("get_hand_count")) if deck_manager != null else 0
		recommend_loadout_button.disabled = arena_payout_pending or hand_count <= 0 or _get_slotted_card_count() >= 5
		var recommend_tooltip := "Auto-slot an affordable kit for %s from the current hand." % _get_objective_label(preview_objective_mode)
		if arena_payout_pending:
			recommend_tooltip = "Collect the arena payout first."
		elif hand_count <= 0:
			recommend_tooltip = "Draw cards before recommending a loadout."
		_style_compact_button(recommend_loadout_button, not recommend_loadout_button.disabled, FEEDBACK_MOVE_COLOR, recommend_tooltip)
	if enter_arena_button != null:
		enter_arena_button.disabled = arena_payout_pending or _get_slotted_card_count() <= 0
		enter_arena_button.tooltip_text = "Collect the arena payout first." if arena_payout_pending else "Slot at least one card, then enter the shooter arena with that loadout."
		_style_compact_button(enter_arena_button, arena_round_armed or _get_slotted_card_count() > 0, FEEDBACK_MOVE_COLOR, enter_arena_button.tooltip_text)
	_refresh_hand_loadout_recommendations(preview_objective_mode)
	_refresh_selected_card_loadout_reason(preview_objective_mode)
	_refresh_arena_payout_panel()


func _get_selected_card_label() -> String:
	if selected_hand_index < 0 or deck_manager == null:
		return "NONE"
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		return "NONE"
	return _get_card_name(card)


func _get_bridge_armor_value() -> int:
	var armor := arena_carryover_armor
	for card in loadout_slots.values():
		if not (card is Resource):
			continue
		var style := _get_card_vfx_style(card)
		if style == &"guard":
			armor += 2 + _get_card_cost(card) + _get_card_upgrade_guard_bonus(card)
	return maxi(0, armor - _get_wound_armor_penalty())


func _get_bridge_ammo_value() -> int:
	var ammo := 12 + arena_carryover_ammo
	for card in loadout_slots.values():
		if not (card is Resource):
			continue
		if _get_card_vfx_style(card) == &"attack":
			ammo += 6 + _get_card_cost(card) * 2
	return ammo


func _build_combat_bridge_payload() -> Dictionary:
	var ability_cards: Array[String] = []
	var passive_cards: Array[String] = []
	var wager_cards: Array[String] = []
	var loadout: Array[Dictionary] = []
	for slot_id in loadout_slots.keys():
		var card: Resource = loadout_slots[slot_id]
		if card == null:
			continue
		var card_id := String(card.get("id"))
		loadout.append(_get_shooter_card_payload(card, String(slot_id)))
		match String(slot_id):
			"ability_1", "ability_2":
				ability_cards.append(card_id)
			"passive":
				passive_cards.append(card_id)
			"wager":
				wager_cards.append(card_id)
	var economy := {
		"chips": shooter_chips,
		"armor": _get_bridge_armor_value(),
		"ammo": _get_bridge_ammo_value()
	}
	return {
		"weapon_card": String(loadout_slots.get("weapon", null).get("id")) if loadout_slots.get("weapon", null) is Resource else "",
		"hero_class": selected_hero_class_id,
		"ability_cards": ability_cards,
		"passive_cards": passive_cards,
		"wager_cards": wager_cards,
		"loadout": loadout,
		"economy": economy,
		"objective_mode": _get_loadout_objective_mode(),
		"payout_bonuses": _get_arena_bonus_snapshot(),
		"reward_mods": active_reward_mods.duplicate(true),
		"card_upgrades": card_upgrade_mods.duplicate(true),
		"progression": {
			"card_xp_pool": arena_card_xp_pool,
			"wounds_total": arena_wounds_total,
			"wound_penalties": _get_wound_penalty_payload()
		},
		"reads": {
			"target_enemy": _get_selected_enemy_target_id(),
			"threat": _get_enemy_intent_line(_get_selected_enemy_target_id())
		}
	}


func _get_loadout_objective_mode() -> String:
	var has_move := false
	var has_guard := false
	var has_read := false
	var has_ritual := false
	for card in loadout_slots.values():
		if not (card is Resource):
			continue
		match _get_card_vfx_style(card):
			&"move":
				has_move = true
			&"guard":
				has_guard = true
			&"read", &"trap":
				has_read = true
			&"ritual":
				has_ritual = true
	if has_ritual:
		return "boss_gate"
	if has_read:
		return "duel"
	if has_move:
		return "extract"
	if has_guard:
		return "defend"
	return "hold_pot"


func _get_preview_objective_mode() -> String:
	if _get_slotted_card_count() > 0:
		return _get_loadout_objective_mode()
	if selected_hand_index >= 0 and deck_manager != null:
		var selected_card: Resource = deck_manager.call("get_card_at", selected_hand_index)
		if selected_card != null:
			return _get_objective_mode_for_card(selected_card)
	return _get_recommended_objective_for_current_hand()


func _get_recommended_objective_for_current_hand() -> String:
	if _get_slotted_card_count() > 0:
		return _get_loadout_objective_mode()
	var scores := {
		"hold_pot": _get_payout_objective_bias_score("hold_pot"),
		"extract": _get_payout_objective_bias_score("extract"),
		"duel": _get_payout_objective_bias_score("duel"),
		"defend": _get_payout_objective_bias_score("defend"),
		"boss_gate": _get_payout_objective_bias_score("boss_gate")
	}
	if deck_manager != null:
		var hand_count := int(deck_manager.call("get_hand_count"))
		for index in range(hand_count):
			var card: Resource = deck_manager.call("get_card_at", index)
			if card == null:
				continue
			var card_mode := _get_objective_mode_for_card(card)
			scores[card_mode] = int(scores.get(card_mode, 0)) + _get_card_objective_weight(card)
			if _get_card_vfx_style(card) == &"attack":
				scores["hold_pot"] = int(scores.get("hold_pot", 0)) + 2
	var best_mode := "hold_pot"
	var best_score := -999
	for mode in ["boss_gate", "duel", "extract", "defend", "hold_pot"]:
		var score := int(scores.get(mode, 0))
		if score > best_score:
			best_mode = mode
			best_score = score
	return best_mode


func _get_card_objective_weight(card: Resource) -> int:
	match _get_card_vfx_style(card):
		&"ritual":
			return 8
		&"read", &"trap":
			return 6
		&"move":
			return 6
		&"guard":
			return 5
		&"attack":
			return 3
		&"bluff":
			return 2
		_:
			return 1


func _get_payout_objective_bias_score(mode: String) -> int:
	var score: int = 0
	if arena_weapon_damage_bonus > 0 and (mode == "duel" or mode == "boss_gate"):
		score += 2
	if arena_carryover_armor > 0 and (mode == "defend" or mode == "hold_pot"):
		score += 2
	if arena_carryover_ammo > 0 and (mode == "extract" or mode == "duel"):
		score += 1
	for mod in active_reward_mods:
		var bias_modes: Array[String] = _string_array_from_variant(mod.get("bias_modes", []))
		if bias_modes.has(mode):
			score += 2 if String(mod.get("rarity", "Common")) == "Rare" else 1
	return score


func _get_objective_mode_for_card(card: Resource) -> String:
	match _get_card_vfx_style(card):
		&"move":
			return "extract"
		&"guard":
			return "defend"
		&"read", &"trap":
			return "duel"
		&"ritual":
			return "boss_gate"
		_:
			return "hold_pot"


func _get_objective_label(mode: String) -> String:
	match mode:
		"extract":
			return "Extract"
		"duel":
			return "Duel"
		"defend":
			return "Defend"
		"boss_gate":
			return "Boss Gate"
		_:
			return "Hold Pot"


func _get_objective_plan_text(mode: String) -> String:
	match mode:
		"extract":
			return "Plan: slot movement, take the pot, then rotate to the exit before the wave collapses."
		"duel":
			return "Plan: bring weapon damage plus read/trap control to delete the marked target fast."
		"defend":
			return "Plan: bring guard and control cards, hold the marked lane, and cash a stable payout."
		"boss_gate":
			return "Plan: bring a weapon plus ritual/wager tech; burn the gate target before it overwhelms you."
		_:
			return "Plan: bring a reliable weapon and anchoring tools, then control the center pot."


func _get_payout_bias_text() -> String:
	var lines: Array[String] = []
	if arena_weapon_damage_bonus > 0:
		lines.append("+%d weapon damage favors Duel or Boss Gate" % arena_weapon_damage_bonus)
	if arena_carryover_armor > 0:
		lines.append("+%d armor favors Hold Pot or Defend" % arena_carryover_armor)
	if arena_carryover_ammo > 0:
		lines.append("+%d ammo favors Extract or Duel" % arena_carryover_ammo)
	var mod_bias := _get_reward_mod_bias_summary()
	if not mod_bias.is_empty():
		lines.append(mod_bias)
	if lines.is_empty():
		return ""
	return "\nPAYOUT BIAS: %s" % _join_string_array(lines, " | ")


func _get_reward_mod_bias_summary() -> String:
	if active_reward_mods.is_empty():
		return ""
	var names: Array[String] = []
	for index in range(mini(3, active_reward_mods.size())):
		var mod: Dictionary = active_reward_mods[index]
		names.append("%s %s" % [String(mod.get("rarity", "Common")), String(mod.get("label", "Arena Mod"))])
	return "mods bias: %s" % _join_string_array(names, ", ")


func _get_reward_mods_label_text() -> String:
	if active_reward_mods.is_empty() and card_upgrade_mods.is_empty() and arena_card_xp_pool <= 0 and arena_wounds_total <= 0:
		return "ACTIVE MODS: none yet | Card XP 0 | Upgrades 0 | Wounds 0"
	var mod_names: Array[String] = []
	for index in range(mini(3, active_reward_mods.size())):
		var mod: Dictionary = active_reward_mods[index]
		mod_names.append("%s %s" % [String(mod.get("rarity", "Common")).to_upper(), String(mod.get("label", "Arena Mod"))])
	var mod_text := "none" if mod_names.is_empty() else _join_string_array(mod_names, " | ")
	var wound_text := _get_wound_burden_text()
	var suffix := " | %s" % wound_text if not wound_text.is_empty() else ""
	return "ACTIVE MODS: %s | Card XP %d | Upgrades %d | Wounds %d%s" % [
		mod_text,
		arena_card_xp_pool,
		card_upgrade_mods.size(),
		arena_wounds_total,
		suffix
	]


func _refresh_reward_artifact_cards() -> void:
	if reward_artifact_row == null or reward_artifact_detail_label == null:
		return
	for child in reward_artifact_row.get_children():
		child.queue_free()
	var artifacts := _get_reward_artifact_snapshots()
	if artifacts.is_empty():
		selected_reward_artifact_index = 0
		var empty_card := Button.new()
		empty_card.name = "RewardArtifactEmpty"
		empty_card.text = "NO ARTIFACTS\nCLEAR ARENA"
		empty_card.disabled = true
		empty_card.focus_mode = Control.FOCUS_NONE
		empty_card.custom_minimum_size = Vector2(128, 58)
		empty_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward_artifact_row.add_child(empty_card)
		_style_reward_artifact_button(empty_card, Color(0.48, 0.48, 0.50), Color(0.32, 0.30, 0.26), false)
		reward_artifact_detail_label.text = "Arena reward mods become inspectable artifacts here after FPS payouts. Spend Card XP below to upgrade or mutate hand cards."
		return
	selected_reward_artifact_index = clampi(selected_reward_artifact_index, 0, artifacts.size() - 1)
	for index in range(artifacts.size()):
		var artifact: Dictionary = artifacts[index]
		var card_button := Button.new()
		card_button.name = "RewardArtifactCard%d" % index
		card_button.text = "%s\n%s\n%s" % [
			String(artifact.get("icon", "MOD")),
			_truncate_reward_artifact_label(String(artifact.get("label", "Arena Mod")), 16).to_upper(),
			String(artifact.get("rarity", "Common")).to_upper()
		]
		card_button.focus_mode = Control.FOCUS_NONE
		card_button.clip_text = true
		card_button.custom_minimum_size = Vector2(124, 66)
		card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_button.set_meta("artifact_index", index)
		card_button.pressed.connect(_on_reward_artifact_pressed.bind(index))
		var bias_modes: Array[String] = artifact.get("bias_modes", [])
		card_button.tooltip_text = "%s %s: %s Bias: %s" % [
			String(artifact.get("rarity", "Common")),
			String(artifact.get("label", "Arena Mod")),
			String(artifact.get("summary", "")),
			_join_string_array(bias_modes, ", ") if not bias_modes.is_empty() else "none"
		]
		reward_artifact_row.add_child(card_button)
		_style_reward_artifact_button(
			card_button,
			artifact.get("frame_color", Color(0.70, 0.70, 0.72)),
			artifact.get("kind_color", FEEDBACK_CARD_COLOR),
			index == selected_reward_artifact_index
		)
	reward_artifact_detail_label.text = _get_reward_artifact_detail_text(selected_reward_artifact_index)


func _get_reward_artifact_snapshots() -> Array[Dictionary]:
	var artifacts: Array[Dictionary] = []
	for index in range(active_reward_mods.size()):
		var mod: Dictionary = active_reward_mods[index]
		var kind := String(mod.get("kind", "chips"))
		var rarity := String(mod.get("rarity", "Common"))
		artifacts.append({
			"id": String(mod.get("id", "artifact_%d" % index)),
			"index": index,
			"label": String(mod.get("label", "Arena Mod")),
			"kind": kind,
			"amount": int(mod.get("amount", 0)),
			"rarity": rarity,
			"icon": _get_reward_artifact_icon(kind),
			"frame_color": _get_reward_artifact_frame_color(rarity),
			"kind_color": _get_reward_artifact_kind_color(kind),
			"objective_label": String(mod.get("objective_label", _get_objective_label(String(mod.get("objective_mode", "hold_pot"))))),
			"bias_modes": _string_array_from_variant(mod.get("bias_modes", [])),
			"summary": String(mod.get("summary", _get_reward_mod_summary(String(mod.get("label", "Arena Mod")), kind, int(mod.get("amount", 0))))),
			"card_xp": int(mod.get("card_xp", 0)),
			"wounds": int(mod.get("wounds", 0)),
			"source": String(mod.get("source", "fps_arena"))
		})
	return artifacts


func _get_reward_artifact_detail_text(index: int) -> String:
	var artifacts := _get_reward_artifact_snapshots()
	if artifacts.is_empty():
		return "No arena artifacts yet."
	index = clampi(index, 0, artifacts.size() - 1)
	var artifact: Dictionary = artifacts[index]
	var bias_modes: Array[String] = artifact.get("bias_modes", [])
	var bias_text := _join_string_array(bias_modes, ", ") if not bias_modes.is_empty() else "none"
	return "[b]%s %s[/b]  %s\n%s\nBias: %s | Card XP earned: %d | Wounds carried: %d" % [
		String(artifact.get("rarity", "Common")).to_upper(),
		_safe_bbcode_text(String(artifact.get("label", "Arena Mod"))),
		String(artifact.get("icon", "MOD")),
		_safe_bbcode_text(String(artifact.get("summary", ""))),
		_safe_bbcode_text(bias_text.to_upper()),
		int(artifact.get("card_xp", 0)),
		int(artifact.get("wounds", 0))
	]


func _on_reward_artifact_pressed(index: int) -> void:
	selected_reward_artifact_index = index
	_refresh_reward_artifact_cards()
	var artifacts := _get_reward_artifact_snapshots()
	if not artifacts.is_empty():
		var artifact: Dictionary = artifacts[clampi(index, 0, artifacts.size() - 1)]
		_push_feedback("Inspected %s artifact: %s." % [String(artifact.get("rarity", "Common")), String(artifact.get("label", "Arena Mod"))], artifact.get("frame_color", FEEDBACK_CARD_COLOR), reward_artifact_row)


func _style_reward_artifact_button(button: Button, frame_color: Color, kind_color: Color, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(kind_color.r * 0.16, kind_color.g * 0.14, kind_color.b * 0.12, 0.62 if active else 0.38)
	normal.border_color = Color(frame_color.r, frame_color.g, frame_color.b, 1.0 if active else 0.62)
	normal.set_border_width_all(3 if active else 2)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 8
	normal.content_margin_top = 7
	normal.content_margin_right = 8
	normal.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(kind_color.r * 0.24, kind_color.g * 0.20, kind_color.b * 0.16, 0.78)
	hover.border_color = frame_color
	hover.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90))
	button.add_theme_font_size_override("font_size", 12)


func _get_reward_artifact_icon(kind: String) -> String:
	match kind:
		"damage":
			return "DMG"
		"armor":
			return "ARM"
		"ammo":
			return "AMM"
		_:
			return "MOD"


func _get_reward_artifact_frame_color(rarity: String) -> Color:
	match rarity.to_lower():
		"rare":
			return Color(1.0, 0.72, 0.18)
		"uncommon":
			return Color(0.36, 0.92, 0.72)
		_:
			return Color(0.72, 0.76, 0.80)


func _get_reward_artifact_kind_color(kind: String) -> Color:
	match kind:
		"damage":
			return FEEDBACK_DAMAGE_COLOR
		"armor":
			return FEEDBACK_GUARD_COLOR
		"ammo":
			return FEEDBACK_MOVE_COLOR
		_:
			return FEEDBACK_CARD_COLOR


func _truncate_reward_artifact_label(label: String, max_len: int) -> String:
	if label.length() <= max_len:
		return label
	return "%s." % label.substr(0, maxi(1, max_len - 1))


func _safe_bbcode_text(text: String) -> String:
	return text.replace("[", "(").replace("]", ")")


func _get_armory_plan_text(target_mode: String) -> String:
	if deck_manager == null:
		return "ARMORY: deck not ready."
	var selected_upgrade := _get_selected_card_upgrade_prompt()
	if _get_slotted_card_count() > 0:
		var slotted_text := "ARMORY: %s | %s | %s" % [
			_get_current_loadout_summary_text(),
			_get_loadout_strength_text(target_mode),
			_get_objective_label(target_mode)
		]
		return "%s | %s" % [slotted_text, selected_upgrade] if not selected_upgrade.is_empty() else slotted_text
	var preview := _build_recommended_loadout_preview(target_mode)
	var entries: Array[String] = preview.get("entries", [])
	if entries.is_empty():
		var empty_text := "ARMORY: no affordable recommendation yet. Burn a low-fit card for Chips or manual-slot your best card."
		return "%s | %s" % [empty_text, selected_upgrade] if not selected_upgrade.is_empty() else empty_text
	var recommend_text := "ARMORY RECOMMENDS: %s | Cost %d/%d Chips | %s" % [
		_join_string_array(entries, ", "),
		int(preview.get("cost", 0)),
		shooter_chips,
		_get_loadout_strength_text(target_mode)
	]
	return "%s | %s" % [recommend_text, selected_upgrade] if not selected_upgrade.is_empty() else recommend_text


func _build_recommended_loadout_preview(target_mode: String) -> Dictionary:
	var used_indices: Dictionary = {}
	var entries: Array[String] = []
	var remaining_chips := shooter_chips
	var total_cost := 0
	for slot_id in _get_recommended_slot_order_for_objective(target_mode):
		var hand_index := _find_recommended_hand_index_for_slot_with_budget(slot_id, target_mode, remaining_chips, used_indices)
		if hand_index < 0:
			continue
		var card: Resource = deck_manager.call("get_card_at", hand_index)
		if card == null:
			continue
		var cost := _get_loadout_slot_cost(card, slot_id)
		remaining_chips -= cost
		total_cost += cost
		used_indices[hand_index] = true
		entries.append("%s -> %s (%dc)" % [_get_card_name(card), _get_loadout_slot_label(slot_id), cost])
		if entries.size() >= 3 and target_mode != "boss_gate":
			break
	return {"entries": entries, "cost": total_cost}


func _find_recommended_hand_index_for_slot_with_budget(slot_id: String, target_mode: String, budget: int, used_indices: Dictionary) -> int:
	var best_index := -1
	var best_score := -9999
	var hand_count := int(deck_manager.call("get_hand_count")) if deck_manager != null else 0
	for index in range(hand_count):
		if used_indices.has(index):
			continue
		var card: Resource = deck_manager.call("get_card_at", index)
		if card == null:
			continue
		if _get_loadout_slot_cost(card, slot_id) > budget:
			continue
		var score := _get_card_loadout_recommendation_score(card, target_mode, slot_id)
		if score > best_score:
			best_score = score
			best_index = index
	return best_index if best_score > -9000 else -1


func _get_current_loadout_summary_text() -> String:
	var entries: Array[String] = []
	for slot_id in ["weapon", "ability_1", "ability_2", "passive", "wager"]:
		if not loadout_slots.has(slot_id):
			continue
		var card: Resource = loadout_slots[slot_id]
		if card == null:
			continue
		entries.append("%s %s" % [_get_loadout_slot_label(slot_id), _get_card_name(card)])
	if entries.is_empty():
		return "empty kit"
	return _join_string_array(entries, ", ")


func _get_loadout_strength_text(target_mode: String) -> String:
	match target_mode:
		"extract":
			return "Extract wants movement plus enough ammo to leave clean."
		"duel":
			return "Duel wants read/trap control and weapon damage."
		"defend":
			return "Defend wants armor, trap control, and a stable weapon."
		"boss_gate":
			return "Boss Gate wants weapon burst and ritual/wager pressure."
		_:
			return "Hold Pot wants a balanced weapon plus sustain."


func _refresh_hand_loadout_recommendations(target_mode: String) -> void:
	if hand_view == null or deck_manager == null:
		return
	if not hand_view.has_method("set_card_recommendations"):
		return
	var entries: Array[Dictionary] = []
	for index in range(hand_view.get_child_count()):
		var card: Resource = deck_manager.call("get_card_at", index)
		entries.append(_get_card_objective_recommendation(card, target_mode))
	hand_view.call("set_card_recommendations", entries)


func _refresh_selected_card_loadout_reason(target_mode: String) -> void:
	if hand_action_status_label == null or deck_manager == null:
		return
	if run_flow_state != RUN_FLOW_COMBAT or arena_payout_pending or selected_hand_index < 0:
		return
	var card: Resource = deck_manager.call("get_card_at", selected_hand_index)
	if card == null:
		return
	var recommendation := _get_card_objective_recommendation(card, target_mode)
	var badge := String(recommendation.get("badge", "LOADOUT"))
	var reason := String(recommendation.get("reason", "Fits the next arena kit."))
	hand_action_status_label.text = "LOADOUT: %s - %s. %s" % [_get_card_name(card), badge, reason]
	hand_action_status_label.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))


func _get_card_objective_recommendation(card: Resource, target_mode: String = "") -> Dictionary:
	if card == null:
		return {"badge": "", "reason": "", "mode": "hold_pot", "score": 0}
	var style := _get_card_vfx_style(card)
	var natural_mode := _get_objective_mode_for_card(card)
	var badge := "LOADOUT FLEX"
	var reason := "Can fill a passive or backup slot if the kit needs one more card."
	match style:
		&"attack":
			badge = "WEAPON CORE"
			reason = "Turns into your arena gun, so it keeps every objective lethal."
			if target_mode == "duel" or target_mode == "boss_gate":
				badge = "DAMAGE CORE"
		&"move":
			badge = "GOOD FOR EXTRACT"
			reason = "Movement helps grab the pot and reach the exit before the timer closes."
		&"guard":
			badge = "GOOD FOR DEFEND"
			reason = "Guard becomes armor, buying time on hold and defend objectives."
		&"read":
			badge = "GOOD FOR DUEL"
			reason = "Read tools expose priority targets and make duel objectives safer."
		&"trap":
			badge = "CHOKE CONTROL"
			reason = "Trap control slows threats and pins duel or defend lanes."
		&"ritual":
			badge = "BOSS TECH"
			reason = "Ritual wagers overclock boss-gate fights for a sharper payout."
		&"bluff":
			badge = "WAGER TOOL"
			reason = "Bluff cards are best as wager/passive economy instead of primary damage."
	if natural_mode == target_mode and style != &"attack":
		badge = "PICK FOR %s" % _get_objective_label(target_mode).to_upper()
	return {
		"badge": badge,
		"reason": reason,
		"mode": natural_mode,
		"score": _get_card_loadout_recommendation_score(card, target_mode, _get_recommended_loadout_slot(card))
	}


func _get_recommended_slot_order_for_objective(mode: String) -> Array[String]:
	match mode:
		"extract":
			return ["weapon", "ability_1", "ability_2", "passive", "wager"]
		"duel":
			return ["weapon", "ability_1", "ability_2", "passive", "wager"]
		"defend":
			return ["weapon", "ability_1", "ability_2", "passive", "wager"]
		"boss_gate":
			return ["weapon", "wager", "ability_1", "ability_2", "passive"]
		_:
			return ["weapon", "ability_1", "ability_2", "passive", "wager"]


func _find_recommended_hand_index_for_slot(slot_id: String, target_mode: String) -> int:
	if deck_manager == null:
		return -1
	var best_index := -1
	var best_score := -9999
	var hand_count := int(deck_manager.call("get_hand_count"))
	for index in range(hand_count):
		var card: Resource = deck_manager.call("get_card_at", index)
		if card == null:
			continue
		var slot_cost := _get_loadout_slot_cost(card, slot_id)
		if slot_cost > shooter_chips:
			continue
		var score: int = _get_card_loadout_recommendation_score(card, target_mode, slot_id)
		if score > best_score:
			best_score = score
			best_index = index
	return best_index if best_score > -9000 else -1


func _get_card_loadout_recommendation_score(card: Resource, target_mode: String, slot_id: String) -> int:
	if card == null or not _card_fits_recommended_slot(card, slot_id):
		return -9999
	var style := _get_card_vfx_style(card)
	var score: int = 10 + maxi(0, 4 - _get_card_cost(card))
	score += _get_card_upgrade_level(card) * 5
	if not _get_card_upgrade_mutation(card).is_empty():
		score += 8
	if _get_objective_mode_for_card(card) == target_mode:
		score += 30
	match slot_id:
		"weapon":
			if style == &"attack":
				score += 35
		"ability_1", "ability_2":
			score += 20
		"wager":
			score += 24 if style == &"ritual" else 12
		"passive":
			score += 6
	match target_mode:
		"extract":
			if style == &"move":
				score += 20
			elif style == &"attack":
				score += 8
		"duel":
			if style == &"read" or style == &"trap":
				score += 20
			elif style == &"attack":
				score += 14
		"defend":
			if style == &"guard" or style == &"trap":
				score += 20
			elif style == &"attack":
				score += 8
		"boss_gate":
			if style == &"ritual":
				score += 24
			elif style == &"attack":
				score += 18
		_:
			if style == &"attack" or style == &"guard" or style == &"trap":
				score += 12
	return score


func _card_fits_recommended_slot(card: Resource, slot_id: String) -> bool:
	var style := _get_card_vfx_style(card)
	match slot_id:
		"weapon":
			return style == &"attack"
		"ability_1", "ability_2":
			return style == &"move" or style == &"guard" or style == &"read" or style == &"trap"
		"wager":
			return style == &"ritual" or style == &"bluff"
		"passive":
			return true
		_:
			return true


func _get_shooter_card_payload(card: Resource, slot_id: String) -> Dictionary:
	var style := _get_card_vfx_style(card)
	var card_id := String(card.get("id"))
	var cooldown_discount := _get_card_upgrade_cooldown_discount(card)
	var duration_bonus := _get_card_upgrade_duration_bonus(card)
	var upgrade_guard := _get_card_upgrade_guard_bonus(card)
	var upgrade_damage := _get_card_upgrade_damage_bonus(card)
	var payload := {
		"slot": slot_id,
		"id": card_id,
		"name": _get_card_name(card),
		"style": String(style),
		"cost": _get_card_cost(card),
		"input": "instant"
	}
	var upgrade_payload := _get_card_upgrade_payload(card)
	if not upgrade_payload.is_empty():
		payload["upgrade"] = upgrade_payload
	match style:
		&"attack":
			payload["combat_role"] = "weapon"
			payload["weapon"] = _get_weapon_profile_for_card(card_id, card)
		&"guard":
			payload["combat_role"] = "defense_ability"
			payload["ability"] = {"kind": "guard_shimmer", "armor": 2 + _get_card_cost(card) + upgrade_guard, "cooldown": maxf(3.0, 8.0 - cooldown_discount)}
		&"move":
			payload["combat_role"] = "movement_ability"
			payload["ability"] = {"kind": "dash", "charges": 2 if _get_card_upgrade_mutation(card) == "Fleet" else 1, "strength": 12.5 + float(_get_card_upgrade_level(card)) * 1.5, "cooldown": maxf(2.5, 6.0 - cooldown_discount)}
		&"read":
			payload["combat_role"] = "intel_ability"
			payload["ability"] = {"kind": "reveal_target", "duration": 3.5 + duration_bonus, "cooldown": maxf(4.0, 10.0 - cooldown_discount)}
		&"trap":
			payload["combat_role"] = "area_control"
			payload["ability"] = {"kind": "snare_field", "duration": 4.0 + duration_bonus, "radius": 4.2 + float(_get_card_upgrade_level(card)) * 0.22 + (0.75 if _get_card_upgrade_mutation(card) == "Snare" else 0.0), "cooldown": maxf(4.5, 12.0 - cooldown_discount)}
		&"ritual":
			payload["combat_role"] = "wager"
			payload["ability"] = {"kind": "blood_overclock", "risk": maxi(1, 2 - int(_get_card_upgrade_level(card) / 2)), "reward": 4 + upgrade_damage, "duration": 4.0 + duration_bonus, "cooldown": maxf(5.0, 11.0 - cooldown_discount)}
		&"bluff":
			payload["combat_role"] = "debuff"
			payload["ability"] = {"kind": "bait_ping", "duration": 2.5 + duration_bonus, "cooldown": maxf(3.5, 9.0 - cooldown_discount)}
		_:
			payload["combat_role"] = "passive"
			payload["ability"] = {"kind": "minor_stat_boost", "damage_bonus": upgrade_damage, "guard_bonus": upgrade_guard}
	return payload


func _get_weapon_profile_for_card(card_id: String, card: Resource = null) -> Dictionary:
	var profile: Dictionary
	match card_id:
		"quick_slash":
			profile = {"name": "Ace Cutter Revolver", "damage": 28, "magazine": 6, "fire_rate": 3.2, "range": "mid"}
		"low_stab":
			profile = {"name": "Low Stab Sidearm", "damage": 18, "magazine": 12, "fire_rate": 5.8, "range": "close"}
		"all_in_cut":
			profile = {"name": "All-In Rail Pistol", "damage": 44, "magazine": 3, "fire_rate": 1.4, "range": "long"}
		"center_cut":
			profile = {"name": "Center Cut Carbine", "damage": 24, "magazine": 18, "fire_rate": 6.0, "range": "mid"}
		_:
			profile = {"name": "House Sidearm", "damage": 20, "magazine": 10, "fire_rate": 4.0, "range": "mid"}
	if arena_weapon_damage_bonus > 0:
		profile["damage"] = int(profile.get("damage", 0)) + arena_weapon_damage_bonus
		profile["payout_bonus_damage"] = arena_weapon_damage_bonus
	if card != null:
		var upgrade_damage := _get_card_upgrade_damage_bonus(card)
		if upgrade_damage > 0:
			profile["damage"] = int(profile.get("damage", 0)) + upgrade_damage
			profile["upgrade_damage_bonus"] = upgrade_damage
			profile["upgrade"] = _get_card_upgrade_payload(card)
	return profile


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
	context["committed"] = true
	if not _validate_card_context(card, context):
		return

	if not bool(combat_session.call("spend_energy", cost, "Commit %s" % card_name)):
		return

	var source_card_view := _get_hand_card_view(0)
	var committed: Resource = deck_manager.call("commit_card_at", 0)
	if committed != null:
		committed_card_context = context.duplicate()
		bluff_system.call("set_committed_card", committed)
		_mark_recipe_step("play_or_commit")
		_record_first_play_step("card")
		_push_feedback("Committed: %s face-down." % _get_card_name(committed), FEEDBACK_CARD_COLOR, bluff_state_label)
		_play_card_commit_vfx(committed, context, source_card_view, true)
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
	_push_feedback("Call set: %s on %s." % [
		intent_metadata.get("intent_name", "Intent"),
		enemy_metadata.get("enemy_name", "Enemy")
	], FEEDBACK_REVEAL_COLOR, bluff_state_label)
	_play_intent_flicker_vfx(intent_preview_label, FEEDBACK_REVEAL_COLOR)


func _on_raise_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Raise is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("raise_wager", 1)):
		_mark_recipe_step("bluff_choice")
		_push_feedback("Raise: wager increased.", FEEDBACK_REVEAL_COLOR, bluff_state_label)
		_play_chip_vfx(bluff_state_label)


func _on_fold_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Fold is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("fold")):
		deck_manager.call("fold_committed_card")
		committed_card_context.clear()
		_mark_recipe_step("bluff_choice")
		_push_feedback("Fold: committed card moved to discard.", FEEDBACK_REVEAL_COLOR, bluff_state_label)
		_play_smoke_vfx(bluff_state_label)


func _on_reset_bluff_pressed() -> void:
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset combat to reset bluff state.")
		return
	bluff_system.call("reset_bluff")


func _on_hand_changed(cards: Array[Resource]) -> void:
	hand_view.call("set_cards", cards)
	previewed_hand_index = -1
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_sync_hand_card_interaction()


func _on_piles_changed(counts: Dictionary) -> void:
	pile_counts_label.text = "Draw: %d | Hand: %d | Discard: %d | Exhaust: %d | Committed: %d" % [
		counts.get("draw", 0),
		counts.get("hand", 0),
		counts.get("discard", 0),
		counts.get("exhaust", 0),
		counts.get("committed", 0)
	]
	_refresh_action_controls()


func _reset_run_slice() -> void:
	_set_run_flow_state(RUN_FLOW_START)
	_reset_first_play_coach()
	pending_arena_result.clear()
	pending_arena_effect_lines.clear()
	arena_payout_pending = false
	active_reward_mods.clear()
	card_upgrade_mods.clear()
	arena_card_xp_pool = 0
	arena_wounds_total = 0
	_clear_arena_bonuses()
	run_ceremony_history.clear()
	selected_run_path_index = -1
	last_run_path_current_index = -1
	last_run_path_transition_text = ""
	last_results_ceremony_outcome = ""
	last_export_path = ""
	last_export_readback.clear()
	last_run_history_report.clear()
	last_run_history_rows.clear()
	last_history_csv_path = ""
	last_history_archive_report.clear()
	run_history_requested = false
	last_run_inspection_report.clear()
	run_inspector_requested = false
	run_inspector_card_filter = "all"
	run_manager.call("reset_run", selected_hero_class_id)
	_reset_playable_combat()


func _reset_playable_combat() -> void:
	_reset_recipe_progress()
	_reset_feedback_state()
	pending_card_context.clear()
	committed_card_context.clear()
	shooter_chips = 7
	_clear_arena_bonuses()
	active_reward_mods.clear()
	card_upgrade_mods.clear()
	arena_card_xp_pool = 0
	arena_wounds_total = 0
	loadout_slots.clear()
	held_hand_indices.clear()
	arena_bridge_payload.clear()
	arena_round_armed = false
	selected_hand_index = -1
	_apply_relic_modifiers()
	combat_session.call("reset_session")
	_apply_current_tactical_map()
	combat_grid.call("reset_grid", run_manager.call("get_current_enemy_spawns"))
	_reset_combat_state()
	_reset_deck_and_draw_opening_hand()
	_reset_enemy_intents()
	bluff_system.call("reset_bluff")
	_apply_starting_relic_effects()
	turn_manager.reset_combat()
	_surface_latest_table_rule_effect()
	if run_flow_state != RUN_FLOW_START:
		_set_run_flow_state(RUN_FLOW_COMBAT)
	_refresh_action_controls()
	_refresh_loadout_ui()


func _reset_deck_and_draw_opening_hand() -> void:
	deck_manager.call("configure_deck", run_manager.call("get_deck_paths"))
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", int(combat_session.get("hand_target")))


func _reset_enemy_intents() -> void:
	enemy_intent_system.call("configure_enemies", run_manager.call("get_current_enemy_paths"))
	enemy_intent_system.call("roll_intents")


func _reset_combat_state() -> void:
	combat_resolver.call("reset_combat", run_manager.call("get_current_enemy_paths"), int(run_manager.call("get_player_hp")))


func _apply_current_tactical_map() -> void:
	var tactical_map := _get_current_tactical_map()
	if combat_grid != null and combat_grid.has_method("configure_map"):
		combat_grid.call("configure_map", tactical_map)
	if arena_view != null and arena_view.has_method("configure_map"):
		arena_view.call("configure_map", tactical_map)


func _get_current_tactical_map() -> Dictionary:
	if run_manager != null and run_manager.has_method("get_current_tactical_map"):
		return run_manager.call("get_current_tactical_map")
	return TACTICAL_MAP_SCRIPT.get_default_map()


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
	if intent_icon_strip_label != null:
		intent_icon_strip_label.clear()
		intent_icon_strip_label.append_text(_build_intent_icon_strip(previews))
	if threat_summary_label != null:
		threat_summary_label.clear()
		threat_summary_label.append_text(_build_threat_summary(previews))

	intent_preview_label.clear()
	intent_preview_label.append_text("Intent Cards\n")
	for preview in previews:
		var options: Array = preview.get("options", [])
		var top_option: Dictionary = _get_top_intent_option(options)
		intent_preview_label.append_text("[Read] %s | Top: %s %d%%\n" % [
			preview.get("enemy_name", "Enemy"),
			_get_threat_level(top_option),
			top_option.get("percentage", 0)
		])
		for option in options:
			if typeof(option) != TYPE_DICTIONARY:
				continue
			var option_data: Dictionary = option
			var marker := ">" if StringName(option_data.get("intent_id", &"")) == StringName(top_option.get("intent_id", &"")) else " "
			intent_preview_label.append_text("%s %s %s %d%% %s\n" % [
				marker,
				_get_intent_icon_marker(option_data),
				_get_threat_level(option_data),
				option_data.get("percentage", 0),
				option_data.get("summary", "Unknown intent")
			])
		var tell := String(preview.get("tell", ""))
		if not tell.is_empty():
			intent_preview_label.append_text("  Tell: %s\n" % tell)
		intent_preview_label.append_text("\n")
	_refresh_enemy_call_options()
	if combat_resolver != null:
		_refresh_enemy_status(combat_resolver.call("get_state"))


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
		_push_feedback("Reveal: no enemy intents selected.", FEEDBACK_REVEAL_COLOR, intent_preview_label)
		return

	var reveal_names: Array[String] = []
	for entry in revealed:
		reveal_names.append("%s: %s" % [
			entry.get("enemy_name", "Enemy"),
			entry.get("intent_name", "Intent")
		])
	_push_feedback("Reveal: %s." % " | ".join(reveal_names), FEEDBACK_REVEAL_COLOR, intent_preview_label)
	_play_intent_flicker_vfx(intent_preview_label, FEEDBACK_REVEAL_COLOR)


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
	_emit_combat_delta_feedback(state)
	_sync_arena_combat_state(state)
	_refresh_enemy_status(state)
	_refresh_targeting_options()
	_refresh_action_controls()


func _on_combat_ended(outcome: String) -> void:
	_append_log("Combat ended: %s." % outcome)
	combat_session.call("mark_combat_ended", outcome)
	if outcome == "victory":
		var pre_victory_state: Dictionary = run_manager.call("get_state") if run_manager != null else {}
		var cleared_table_name: String = String(pre_victory_state.get("current_node_name", "Table"))
		run_manager.call("mark_combat_victory", combat_resolver.call("get_state"))
		var post_victory_state: Dictionary = run_manager.call("get_state")
		if String(post_victory_state.get("run_outcome", "running")) == "victory":
			_ensure_results_ceremony(post_victory_state)
		else:
			_record_run_ceremony("Victory: %s cleared. Reward choice opens the route forward." % cleared_table_name, FEEDBACK_PHASE_COLOR, run_shell_panel)
	else:
		run_manager.call("mark_combat_defeat")
		_ensure_results_ceremony(run_manager.call("get_state"))
	_refresh_action_controls()


func _on_session_state_changed(state: Dictionary) -> void:
	resource_state_label.text = "Energy: %d/%d | Phase Gate: %s | Loop: %s" % [
		state.get("energy", 0),
		state.get("max_energy", 0),
		state.get("current_phase_key", "UNKNOWN"),
		state.get("outcome", "ongoing")
	]
	_refresh_action_controls()


func _on_target_enemy_selected(_index: int) -> void:
	_sync_target_focus()
	var target: Dictionary = _get_selected_enemy_target()
	if not target.is_empty():
		_record_first_play_step("target")
		_flash_grid_unit(StringName(target.get("id", &"")), FEEDBACK_CARD_COLOR)
		_push_feedback("Target selected: %s for attack/read cards." % target.get("name", "Enemy"), FEEDBACK_CARD_COLOR, target_enemy_option)
		_refresh_enemy_target_cards(combat_resolver.call("get_state") if combat_resolver != null else {})
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_refresh_compact_play_state(run_manager.call("get_state") if run_manager != null else {})


func _on_movement_cell_selected(_index: int) -> void:
	_sync_target_focus()
	var target_cell: Vector2i = _get_selected_move_cell()
	if target_cell != Vector2i(-1, -1) and combat_grid != null:
		_record_first_play_step("target")
		combat_grid.call("flash_cell", target_cell, FEEDBACK_MOVE_COLOR)
		_push_feedback("Move selected: %s for movement/trap cards." % combat_grid.call("format_cell", target_cell), FEEDBACK_MOVE_COLOR, movement_cell_option)
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_refresh_compact_play_state(run_manager.call("get_state") if run_manager != null else {})


func _on_card_previewed(hand_index: int) -> void:
	previewed_hand_index = hand_index
	selected_hand_index = hand_index
	if hand_view != null and hand_view.has_method("set_previewed_index"):
		hand_view.call("set_previewed_index", hand_index)
	_refresh_card_target_preview()
	_sync_target_focus()
	_refresh_loadout_ui()


func _on_card_preview_cleared(hand_index: int) -> void:
	if previewed_hand_index != hand_index:
		return
	previewed_hand_index = -1
	if hand_view != null and hand_view.has_method("set_previewed_index"):
		hand_view.call("set_previewed_index", -1)
	_refresh_card_target_preview()


func _on_run_state_changed(state: Dictionary) -> void:
	_sync_run_flow_from_state(state)
	_refresh_action_controls()


func _on_run_path_table_pressed(index: int) -> void:
	if run_flow_state == RUN_FLOW_START:
		if index == 0:
			_on_start_run_pressed()
		else:
			_push_feedback("Deal In first; later tables unlock after the first fight.", FEEDBACK_PHASE_COLOR, run_path_buttons[index] if index >= 0 and index < run_path_buttons.size() else run_path_label)
		return
	selected_run_path_index = index
	if run_manager == null:
		return

	var state: Dictionary = run_manager.call("get_state")
	var path_entries: Array = state.get("run_path", [])
	if index >= 0 and index < path_entries.size() and typeof(path_entries[index]) == TYPE_DICTIONARY:
		var entry: Dictionary = Dictionary(path_entries[index])
		_push_feedback("Run map: inspecting Table %d - %s." % [
			entry.get("table_number", index + 1),
			entry.get("name", "Table")
		], FEEDBACK_PHASE_COLOR, run_path_buttons[index])
	_refresh_run_path(state)


func _on_run_path_table_hovered(index: int) -> void:
	if run_flow_state == RUN_FLOW_START:
		if index >= 0 and index < run_path_buttons.size():
			_flash_canvas_item(run_path_buttons[index], FEEDBACK_CARD_COLOR if index == 0 else FEEDBACK_PHASE_COLOR, 0.12)
		return
	selected_run_path_index = index
	if run_manager == null:
		return
	_refresh_run_path(run_manager.call("get_state"))


func _on_opening_step_pressed(index: int) -> void:
	if run_flow_state != RUN_FLOW_START:
		return
	if index == 0:
		_on_start_run_pressed()
		return
	var target: Node = opening_step_buttons[index] if index >= 0 and index < opening_step_buttons.size() else run_shell_panel
	_push_feedback("Deal In first. That step lights up once combat starts.", FEEDBACK_PHASE_COLOR, target)


func _on_card_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_card_reward", index))
	if not claimed_path.is_empty():
		_record_run_ceremony("Reward: card added to the deck. The map marker can advance when rewards are clear.", FEEDBACK_CARD_COLOR, reward_prompt_label)
		_refresh_run_inspector_label(false)
		_show_next_encounter_if_ready()


func _on_relic_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_relic_reward", index))
	if not claimed_path.is_empty():
		_record_run_ceremony("Reward: relic claimed. The route is ready to continue when rewards are clear.", FEEDBACK_CARD_COLOR, reward_prompt_label)
		_refresh_run_inspector_label(false)
		_show_next_encounter_if_ready()


func _on_skip_rewards_pressed() -> void:
	run_manager.call("skip_rewards")
	_record_run_ceremony("Reward: skipped to keep the deck lean. The route marker advances.", FEEDBACK_CARD_COLOR, reward_prompt_label)
	_refresh_run_inspector_label(false)
	_show_next_encounter_if_ready()


func _on_run_playtests_pressed() -> void:
	var batch: Dictionary = run_manager.call("get_playtest_batch")
	_refresh_playtest_report(batch)
	_append_log("Playtest sims: %s" % batch.get("summary", "No summary."))


func _on_inspect_run_pressed() -> void:
	run_inspector_requested = true
	_refresh_run_inspector_label(true)
	_append_log("Run inspector loaded.")
	_push_feedback("Inspector: deck, relics, rewards, and history refreshed.", FEEDBACK_REVEAL_COLOR, run_inspector_panel)
	_refresh_action_controls()


func _on_run_inspector_filter_pressed(filter_id: String) -> void:
	run_inspector_card_filter = filter_id
	run_inspector_requested = true
	_refresh_run_inspector_label(true)
	_push_feedback("Inspector filter: %s cards." % filter_id.capitalize(), FEEDBACK_REVEAL_COLOR, run_inspector_panel)


func _on_view_history_pressed() -> void:
	run_history_requested = true
	_refresh_run_history_label(true)
	_append_log("Run history loaded: %d summaries." % last_run_history_rows.size())
	_push_feedback("History: loaded %d exported summaries." % last_run_history_rows.size(), FEEDBACK_REVEAL_COLOR, run_history_label)
	_refresh_action_controls()


func _on_export_summary_pressed() -> void:
	var path: String = String(run_manager.call("export_run_summary"))
	if path.is_empty():
		_append_log("Run summary export failed.")
		last_export_path = ""
		last_export_readback = {"ok": false, "error": "export returned no path"}
		_refresh_export_readback_label()
		_refresh_run_history_label(false)
		return

	last_export_path = path
	last_export_readback = _read_export_summary(path)
	if bool(last_export_readback.get("ok", false)):
		var summary_line: String = String(last_export_readback.get("summary_line", "Summary ready."))
		_append_log("Run summary exported and read back: %s." % summary_line)
		_record_run_ceremony("Export: summary read back for comparison.", FEEDBACK_PHASE_COLOR, run_results_label)
	else:
		_append_log("Run summary exported to %s, but readback failed: %s." % [
			path,
			last_export_readback.get("error", "unknown error")
		])
	_refresh_export_readback_label()
	_refresh_run_history_label(true)


func _on_export_history_csv_pressed() -> void:
	if run_manager == null:
		return

	run_history_requested = true
	last_history_csv_path = String(run_manager.call("export_run_history_csv", 20))
	if last_history_csv_path.is_empty():
		_append_log("Run history CSV export failed: no summaries available.")
	else:
		_append_log("Run history CSV exported to %s." % last_history_csv_path)
		_push_feedback("History: CSV comparison exported.", FEEDBACK_REVEAL_COLOR, run_history_label)
	_refresh_run_history_label(true)
	_refresh_action_controls()


func _on_archive_history_pressed() -> void:
	if run_manager == null:
		return

	run_history_requested = true
	last_history_archive_report = run_manager.call("archive_old_run_summaries", 8)
	var archived_count := int(last_history_archive_report.get("archived_count", 0))
	var kept_count := int(last_history_archive_report.get("kept_count", 0))
	_append_log("Run history archive: kept %d recent summaries, archived %d older summaries." % [
		kept_count,
		archived_count
	])
	_push_feedback("History: archived %d older summaries." % archived_count, FEEDBACK_REVEAL_COLOR, run_history_label)
	_refresh_run_history_label(true)
	_refresh_action_controls()


func _read_export_summary(path: String) -> Dictionary:
	if path.is_empty():
		return {"ok": false, "error": "missing export path", "path": path}
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "file does not exist", "path": path}

	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {"ok": false, "error": "file is empty", "path": path}

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "invalid JSON", "path": path}

	var data: Dictionary = Dictionary(parsed)
	var comparison: Dictionary = {}
	var comparison_value: Variant = data.get("comparison_summary", {})
	if typeof(comparison_value) == TYPE_DICTIONARY:
		comparison = Dictionary(comparison_value)

	var results: Dictionary = {}
	var results_value: Variant = data.get("run_results", {})
	if typeof(results_value) == TYPE_DICTIONARY:
		results = Dictionary(results_value)

	var route_summary: Array = []
	var route_value: Variant = data.get("route_summary", [])
	if typeof(route_value) == TYPE_ARRAY:
		route_summary = Array(route_value)

	return {
		"ok": true,
		"path": path,
		"result_key": String(comparison.get("result_key", "unkeyed_run")),
		"summary_line": String(comparison.get("summary_line", "Summary unavailable.")),
		"comparison_summary": comparison,
		"run_results": results,
		"route_summary": route_summary
	}


func _refresh_export_readback_label() -> void:
	if run_export_readback_label == null:
		return

	run_export_readback_label.clear()
	if last_export_path.is_empty() and last_export_readback.is_empty():
		run_export_readback_label.visible = false
		run_export_readback_label.modulate = Color.WHITE
		_sync_run_panel_visibility()
		return

	run_export_readback_label.visible = true
	if not bool(last_export_readback.get("ok", false)):
		run_export_readback_label.modulate = FEEDBACK_DAMAGE_COLOR
		run_export_readback_label.append_text("Export Readback\nFailed: %s\nFile: %s" % [
			last_export_readback.get("error", "unknown error"),
			last_export_path
		])
		return

	run_export_readback_label.modulate = FEEDBACK_PHASE_COLOR
	var route_summary: Array = last_export_readback.get("route_summary", [])
	run_export_readback_label.append_text("Export Readback\n")
	run_export_readback_label.append_text("Compare: %s\n" % last_export_readback.get("summary_line", "Summary unavailable."))
	run_export_readback_label.append_text("Key: %s\n" % last_export_readback.get("result_key", "unkeyed_run"))
	run_export_readback_label.append_text("Route: %s\n" % _get_export_route_readback_text(route_summary))
	run_export_readback_label.append_text("File: %s" % last_export_path.get_file())
	_sync_run_panel_visibility()


func _refresh_run_history_label(force_show: bool = false) -> void:
	if run_history_label == null:
		return

	if force_show:
		run_history_requested = true
	run_history_label.clear()
	if run_manager == null:
		run_history_label.visible = false
		_sync_run_panel_visibility()
		return
	if not force_show and not run_history_requested and last_run_history_rows.is_empty():
		run_history_label.visible = false
		run_history_label.modulate = Color.WHITE
		_sync_run_panel_visibility()
		return

	last_run_history_report = run_manager.call("get_run_history_comparison", 6)
	last_run_history_rows.clear()
	var rows_value: Variant = last_run_history_report.get("rows", [])
	if typeof(rows_value) == TYPE_ARRAY:
		for row_value in Array(rows_value):
			if typeof(row_value) == TYPE_DICTIONARY:
				last_run_history_rows.append(Dictionary(row_value))

	if last_run_history_rows.is_empty():
		run_history_label.visible = force_show
		run_history_label.modulate = Color.WHITE
		if force_show:
			run_history_label.append_text("Run History Comparison\nNo exported summaries found yet.")
		return

	run_history_label.visible = true
	run_history_label.modulate = FEEDBACK_REVEAL_COLOR if bool(last_run_history_report.get("has_outcome_shift", false)) else FEEDBACK_PHASE_COLOR
	run_history_label.append_text("Run History Comparison\n")
	run_history_label.append_text("Rows loaded: %d recent exports | %s\n" % [
		last_run_history_rows.size(),
		last_run_history_report.get("headline", "History ready.")
	])
	run_history_label.append_text("Management: View History refreshes rows; Export History CSV writes a tuning table; Archive Old keeps the 8 newest JSON summaries.\n")
	if not last_history_csv_path.is_empty():
		run_history_label.append_text("CSV: %s\n" % last_history_csv_path.get_file())
	if not last_history_archive_report.is_empty():
		var archive_errors: Array = last_history_archive_report.get("errors", [])
		var archive_error_text := " | errors %d" % archive_errors.size() if not archive_errors.is_empty() else ""
		run_history_label.append_text("Archive: kept %d | archived %d%s\n" % [
			last_history_archive_report.get("kept_count", 0),
			last_history_archive_report.get("archived_count", 0),
			archive_error_text
		])

	var limit: int = min(5, last_run_history_rows.size())
	for index in range(limit):
		var row: Dictionary = last_run_history_rows[index]
		var marker := "!!" if bool(row.get("outcome_shift", false)) else "--"
		run_history_label.append_text("%s #%d %s | %s | Tables %d/%d | Blood %d | Low %d | Dmg %d | Deck %d\n" % [
			marker,
			index + 1,
			row.get("outcome", "unknown"),
			row.get("grade", "Table Stakes"),
			row.get("cleared_tables", 0),
			row.get("total_tables", 0),
			row.get("blood", 0),
			row.get("lowest_blood", 0),
			row.get("damage_taken_total", 0),
			row.get("deck_size", 0)
		])
		var delta_label := String(row.get("delta_label", ""))
		if not delta_label.is_empty():
			run_history_label.append_text("   Change: %s\n" % delta_label)
	_sync_run_panel_visibility()


func _refresh_run_inspector_label(force_show: bool = false) -> void:
	if run_inspector_panel == null or run_inspector_label == null:
		return

	if force_show:
		run_inspector_requested = true
	run_inspector_label.clear()
	if run_manager == null:
		run_inspector_panel.visible = false
		if run_inspector_filter_row != null:
			run_inspector_filter_row.visible = false
		_sync_run_panel_visibility()
		return
	if not force_show and not run_inspector_requested:
		run_inspector_panel.visible = false
		if run_inspector_filter_row != null:
			run_inspector_filter_row.visible = false
		_sync_run_panel_visibility()
		return

	last_run_inspection_report = run_manager.call("get_run_inspection_report", 5)
	run_inspector_panel.visible = true
	if run_inspector_filter_row != null:
		run_inspector_filter_row.visible = true
	_refresh_run_inspector_filter_buttons()
	run_inspector_label.append_text("Run/Deck Inspector\n")
	run_inspector_label.append_text("%s | Table: %s | Blood %d/%d\n" % [
		last_run_inspection_report.get("summary", "Inspection ready."),
		last_run_inspection_report.get("current_table", "Table"),
		last_run_inspection_report.get("blood", 0),
		last_run_inspection_report.get("max_blood", 0)
	])

	var deck: Dictionary = last_run_inspection_report.get("deck", {})
	var deck_profile: Dictionary = deck.get("profile", {})
	run_inspector_label.append_text("Deck: %d cards | Avg cost %.2f | %s\n" % [
		deck.get("size", 0),
		deck.get("average_cost", 0.0),
		deck.get("type_summary", "None")
	])
	run_inspector_label.append_text("Deck gaps: %s\n" % deck.get("gap_summary", "No deck notes."))
	run_inspector_label.append_text("Tuning: %.1f damage/turn | %.1f guard/turn | %.1f control | Tags: %s\n" % [
		deck_profile.get("projected_damage_per_turn", 0.0),
		deck_profile.get("projected_guard_per_turn", 0.0),
		deck_profile.get("control_score", 0.0),
		deck.get("tag_summary", "None")
	])
	_append_run_inspector_card_rows(deck.get("cards", []))

	var relics: Dictionary = last_run_inspection_report.get("relics", {})
	run_inspector_label.append_text("Relics: %s\n" % relics.get("summary", "No relics claimed yet."))
	_append_run_inspector_reward_rows(last_run_inspection_report.get("recent_rewards", []))
	_append_run_inspector_pending_rows(last_run_inspection_report.get("pending_rewards", []))
	_append_run_inspector_history_rows(last_run_inspection_report.get("history_rows", []))
	_sync_run_panel_visibility()


func _refresh_run_inspector_filter_buttons() -> void:
	for button in run_inspector_filter_buttons:
		if button == null:
			continue
		var filter_id := _get_filter_id_from_button(button)
		var selected := filter_id == run_inspector_card_filter
		button.modulate = Color(1.0, 0.92, 0.48) if selected else Color.WHITE
		button.tooltip_text = "Show %s deck cards." % filter_id.capitalize()


func _get_filter_id_from_button(button: Button) -> String:
	for filter in RUN_INSPECTOR_FILTERS:
		var filter_id := String(filter.get("id", "all"))
		if button.name == "RunInspectorFilter%s" % filter_id.capitalize():
			return filter_id
	return "all"


func _append_run_inspector_card_rows(cards: Array) -> void:
	var filtered_cards: Array[Dictionary] = []
	for value in cards:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(value)
		var type_label := String(card.get("type", "Card"))
		var type_key := type_label.to_lower()
		var matches_filter := run_inspector_card_filter == "all" or type_key == run_inspector_card_filter
		if run_inspector_card_filter == "guard" and type_key == "defense":
			matches_filter = true
		if matches_filter:
			filtered_cards.append(card)

	run_inspector_label.append_text("Deck cards (%s): %d shown\n" % [
		run_inspector_card_filter.capitalize(),
		filtered_cards.size()
	])
	if filtered_cards.is_empty():
		run_inspector_label.append_text("- No cards match this filter.\n")
		return

	var limit: int = min(8, filtered_cards.size())
	for index in range(limit):
		var card: Dictionary = filtered_cards[index]
		run_inspector_label.append_text("- %s | Cost %d | %s | %s\n" % [
			card.get("name", "Card"),
			card.get("cost", 0),
			card.get("type", "Card"),
			_join_text_array(card.get("tags", []), "No tags")
		])
	if filtered_cards.size() > limit:
		run_inspector_label.append_text("- +%d more matching cards.\n" % (filtered_cards.size() - limit))


func _append_run_inspector_reward_rows(reward_rows: Array) -> void:
	run_inspector_label.append_text("Recent rewards:\n")
	if reward_rows.is_empty():
		run_inspector_label.append_text("- No reward decisions logged this run yet.\n")
		return

	var limit: int = min(4, reward_rows.size())
	for index in range(limit):
		if typeof(reward_rows[index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(reward_rows[index])
		run_inspector_label.append_text("- %s | %s\n  %s\n" % [
			row.get("kind", "Reward"),
			row.get("summary", row.get("name", "Reward")),
			row.get("deck_change", row.get("impact", ""))
		])
		var after_snapshot := String(row.get("after_deck_snapshot", ""))
		if not after_snapshot.is_empty():
			run_inspector_label.append_text("  After: %s\n" % after_snapshot)


func _append_run_inspector_pending_rows(pending_rows: Array) -> void:
	run_inspector_label.append_text("Pending/recommended rewards:\n")
	if pending_rows.is_empty():
		run_inspector_label.append_text("- No card reward offer is pending.\n")
		return

	var limit: int = min(2, pending_rows.size())
	for index in range(limit):
		if typeof(pending_rows[index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(pending_rows[index])
		run_inspector_label.append_text("- #%d %s | %s\n  %s\n" % [
			row.get("rank", index + 1),
			row.get("name", "Card"),
			row.get("explanation", "Reward option."),
			row.get("impact_summary", "Deck impact unavailable.")
		])


func _append_run_inspector_history_rows(history_rows: Array) -> void:
	run_inspector_label.append_text("Recent history:\n")
	if history_rows.is_empty():
		run_inspector_label.append_text("- No exported summaries in the active history folder.\n")
		return

	var limit: int = min(3, history_rows.size())
	for index in range(limit):
		if typeof(history_rows[index]) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(history_rows[index])
		run_inspector_label.append_text("- %s | Tables %d/%d | Blood %d | %s\n" % [
			row.get("outcome", "unknown"),
			row.get("cleared_tables", 0),
			row.get("total_tables", 0),
			row.get("blood", 0),
			row.get("delta_label", "No delta")
		])


func _get_export_route_readback_text(route_summary: Array) -> String:
	if route_summary.is_empty():
		return "route unavailable"

	var entries := PackedStringArray()
	for entry_value in route_summary:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_value)
		entries.append("%d:%s" % [
			int(entry.get("table_number", 0)),
			String(entry.get("status_label", "UPCOMING"))
		])

	if entries.is_empty():
		return "route unavailable"
	return " -> ".join(entries)


func _on_grid_unit_moved(unit_id: StringName, from_cell: Vector2i, to_cell: Vector2i) -> void:
	_push_feedback("Move: %s %s to %s." % [
		combat_grid.call("get_unit_label", unit_id),
		combat_grid.call("format_cell", from_cell),
		combat_grid.call("format_cell", to_cell)
	], FEEDBACK_MOVE_COLOR, combat_grid)
	_flash_grid_unit(unit_id, FEEDBACK_MOVE_COLOR)
	_play_unit_or_cell_burst(unit_id, to_cell, FEEDBACK_MOVE_COLOR, &"move")
	if arena_view != null and arena_view.has_method("play_move"):
		arena_view.call("play_move", unit_id, from_cell, to_cell)
	_refresh_targeting_options()


func _on_grid_cell_selected(cell: Vector2i) -> void:
	if combat_grid == null:
		return

	var occupant_id: StringName = combat_grid.call("get_occupant_at", cell)
	if _is_clickable_enemy_target(occupant_id):
		_select_enemy_target_by_id(occupant_id, combat_grid)
		return

	if _is_valid_player_move_target(cell):
		_select_move_target_cell(cell, combat_grid)


func _on_enemy_target_card_pressed(enemy_id: StringName) -> void:
	var source_button: Button = null
	for button in enemy_target_card_buttons:
		if button == null:
			continue
		if StringName(button.get_meta("enemy_id", &"")) == enemy_id:
			source_button = button
			break
	_select_enemy_target_by_id(enemy_id, source_button)


func _on_enemy_target_card_button_down(enemy_id: StringName, source_button: Button) -> void:
	if enemy_id.is_empty() or run_flow_state != RUN_FLOW_COMBAT:
		return

	_play_target_lock_vfx(enemy_id, source_button)
	if source_button != null:
		_flash_canvas_item(source_button, FEEDBACK_CARD_COLOR, 0.16)
	if combat_vfx != null and combat_vfx.has_method("play_button_sheen_on") and _is_live_canvas_item(source_button):
		combat_vfx.call("play_button_sheen_on", source_button, FEEDBACK_DAMAGE_COLOR)


func _on_enemy_target_card_hovered(enemy_id: StringName, source_button: Button) -> void:
	if enemy_id.is_empty() or run_flow_state != RUN_FLOW_COMBAT:
		return

	_play_target_lock_vfx(enemy_id, source_button)
	if source_button != null:
		_flash_canvas_item(source_button, FEEDBACK_CARD_COLOR, 0.18)


func _on_enemy_target_card_unhovered(_enemy_id: StringName) -> void:
	_sync_target_focus()


func _select_enemy_target_by_id(enemy_id: StringName, source: Node = null) -> bool:
	if target_enemy_option == null or enemy_id.is_empty():
		return false

	var option_index := _get_enemy_target_option_index(enemy_id)
	if option_index < 0:
		return false

	target_enemy_option.select(option_index)
	_sync_target_focus()
	var target: Dictionary = _get_selected_enemy_target()
	if target.is_empty():
		return false

	_record_first_play_step("target")
	_flash_grid_unit(enemy_id, FEEDBACK_CARD_COLOR)
	_play_target_lock_vfx(enemy_id, source as CanvasItem if source is CanvasItem else null)
	_push_feedback("Target selected: %s. Attack/read cards will hit this card." % target.get("name", "Enemy"), FEEDBACK_CARD_COLOR, source if source != null else target_enemy_option)
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_refresh_enemy_target_cards(combat_resolver.call("get_state") if combat_resolver != null else {})
	_refresh_compact_play_state(run_manager.call("get_state") if run_manager != null else {})
	return true


func _select_move_target_cell(cell: Vector2i, source: Node = null) -> bool:
	if movement_cell_option == null or combat_grid == null:
		return false

	var option_index := _get_move_target_option_index(cell)
	if option_index < 0:
		return false

	movement_cell_option.select(option_index)
	_sync_target_focus()
	_record_first_play_step("target")
	combat_grid.call("flash_cell", cell, FEEDBACK_MOVE_COLOR)
	_push_feedback("Move selected: %s. Movement/trap cards will use this cell." % combat_grid.call("format_cell", cell), FEEDBACK_MOVE_COLOR, source if source != null else movement_cell_option)
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_refresh_compact_play_state(run_manager.call("get_state") if run_manager != null else {})
	return true


func _get_enemy_target_option_index(enemy_id: StringName) -> int:
	if target_enemy_option == null:
		return -1
	for index in range(target_enemy_option.item_count):
		var metadata = target_enemy_option.get_item_metadata(index)
		if typeof(metadata) == TYPE_DICTIONARY and StringName(metadata.get("id", &"")) == enemy_id:
			return index
	return -1


func _get_move_target_option_index(cell: Vector2i) -> int:
	if movement_cell_option == null:
		return -1
	for index in range(movement_cell_option.item_count):
		var metadata = movement_cell_option.get_item_metadata(index)
		if typeof(metadata) == TYPE_VECTOR2I and metadata == cell:
			return index
	return -1


func _is_clickable_enemy_target(unit_id: StringName) -> bool:
	if unit_id.is_empty() or unit_id == &"player" or combat_resolver == null:
		return false
	return bool(combat_resolver.call("has_living_enemy", unit_id))


func _on_enemy_call_selected(_index: int) -> void:
	_refresh_intent_call_options()


func _resolve_reveal() -> void:
	if reveal_resolved_this_phase:
		return

	reveal_resolved_this_phase = true
	var revealed: Array = enemy_intent_system.call("reveal_intents")
	bluff_system.call("reveal", revealed)
	var bluff_state: Dictionary = bluff_system.call("get_state")
	if bool(deck_manager.call("has_committed_card")):
		var resolved_card: Resource = deck_manager.call("resolve_committed_card")
		if resolved_card != null:
			committed_card_context["bluff_state"] = bluff_state
			var resolved_context := committed_card_context.duplicate()
			if _is_movement_card(resolved_card):
				if bool(_resolve_movement_card(resolved_card, committed_card_context)):
					_apply_card_side_effects(resolved_card, committed_card_context)
			else:
				combat_resolver.call("apply_card_with_context", resolved_card, committed_card_context)
				_apply_card_side_effects(resolved_card, committed_card_context)
			_play_card_commit_vfx(resolved_card, resolved_context, bluff_state_label, false)
			committed_card_context.clear()
	_apply_enemy_grid_moves(revealed)
	combat_resolver.call("apply_revealed_intents_with_context", revealed, _build_reveal_context(bluff_state))
	_mark_recipe_step("reveal_resolve")
	_refresh_action_controls()


func _show_next_encounter_if_ready() -> void:
	var run_state: Dictionary = run_manager.call("get_state")
	if String(run_state.get("run_outcome", "running")) != "running":
		_refresh_action_controls()
		return

	if bool(run_manager.call("can_start_current_node")):
		_set_run_flow_state(RUN_FLOW_NEXT_ENCOUNTER)
		var table_number: int = min(int(run_state.get("current_node_index", 0)) + 1, int(run_state.get("current_node_count", 0)))
		var table_count: int = int(run_state.get("current_node_count", 0))
		_push_feedback("Run map: rewards clear. Marker moves to Table %d/%d - %s." % [
			table_number,
			table_count,
			run_state.get("current_node_name", "Encounter")
		], FEEDBACK_PHASE_COLOR, run_path_label)
		_record_run_ceremony("Map: marker moves to Table %d/%d - %s. Approach preview is staged." % [
			table_number,
			table_count,
			run_state.get("current_node_name", "Encounter")
		], FEEDBACK_PHASE_COLOR, run_path_label)

	_refresh_action_controls()


func _apply_relic_modifiers() -> void:
	var modifiers: Dictionary = _get_combined_combat_modifiers()
	combat_session.set("max_energy", max(1, 3 + int(modifiers.get("max_energy_bonus", 0))))
	combat_session.set("hand_target", max(1, 5 + int(modifiers.get("hand_target_bonus", 0))))
	bluff_system.set("starting_nerve", max(1, 3 + int(modifiers.get("starting_nerve_bonus", 0))))
	_record_table_setup_modifier_effects()


func _apply_starting_relic_effects() -> void:
	var modifiers: Dictionary = _get_combined_combat_modifiers()
	var starting_guard: int = int(modifiers.get("starting_guard", 0))
	if starting_guard > 0:
		combat_resolver.call("add_player_guard", starting_guard, _get_current_modifier_source())
		if _get_current_table_modifiers().has("starting_guard"):
			_record_table_rule_effect("grants %d opening Guard" % starting_guard)


func _record_table_setup_modifier_effects() -> void:
	var table_modifiers: Dictionary = _get_current_table_modifiers()
	if table_modifiers.has("max_energy_bonus"):
		var energy_bonus: int = int(table_modifiers.get("max_energy_bonus", 0))
		if energy_bonus != 0:
			_record_table_rule_effect("%s max Energy; cap is %d" % [
				_format_signed_number(energy_bonus),
				int(combat_session.get("max_energy"))
			])

	if table_modifiers.has("hand_target_bonus"):
		var hand_bonus: int = int(table_modifiers.get("hand_target_bonus", 0))
		if hand_bonus != 0:
			_record_table_rule_effect("%s opening hand size; draw target is %d" % [
				_format_signed_number(hand_bonus),
				int(combat_session.get("hand_target"))
			])

	if table_modifiers.has("starting_nerve_bonus"):
		var nerve_bonus: int = int(table_modifiers.get("starting_nerve_bonus", 0))
		if nerve_bonus != 0:
			_record_table_rule_effect("%s starting Nerve; Nerve starts at %d" % [
				_format_signed_number(nerve_bonus),
				int(bluff_system.get("starting_nerve"))
			])


func _record_table_rule_effect(effect_text: String) -> void:
	if effect_text.is_empty():
		return

	var modifier_name: String = _get_current_modifier_source()
	var message: String = "Table Rule: %s %s." % [modifier_name, effect_text]
	if not table_rule_effect_history.has(message):
		table_rule_effect_history.push_front(message)
		while table_rule_effect_history.size() > 4:
			table_rule_effect_history.pop_back()
	_push_feedback(message, FEEDBACK_PHASE_COLOR, table_rule_status_label)
	_refresh_table_rule_status(run_manager.call("get_state") if run_manager != null else {})


func _surface_latest_table_rule_effect() -> void:
	if table_rule_effect_history.is_empty():
		return

	var message: String = table_rule_effect_history[0]
	if feedback_banner_label != null:
		feedback_banner_label.text = message
		_pulse_canvas_item(feedback_banner_label, FEEDBACK_PHASE_COLOR)
	if table_rule_status_label != null:
		_pulse_canvas_item(table_rule_status_label, FEEDBACK_PHASE_COLOR)


func _get_current_table_modifiers() -> Dictionary:
	if run_manager == null:
		return {}
	return run_manager.call("get_table_modifiers")


func _get_combined_combat_modifiers() -> Dictionary:
	var combined: Dictionary = run_manager.call("get_relic_modifiers") if run_manager != null else {}
	var table_modifiers: Dictionary = run_manager.call("get_table_modifiers") if run_manager != null else {}
	for key in table_modifiers.keys():
		combined[key] = combined.get(key, 0) + table_modifiers[key]
	return combined


func _get_current_modifier_source() -> String:
	if run_manager == null:
		return "Table modifier"
	var table_modifier: Dictionary = run_manager.call("get_current_table_modifier")
	var modifier_name: String = String(table_modifier.get("name", "Table modifier"))
	if modifier_name.is_empty():
		return "Table modifier"
	return modifier_name


func _format_signed_number(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return "%d" % value


func _refresh_action_controls() -> void:
	if next_phase_button == null or combat_session == null:
		return

	var can_debug_adjust := bool(combat_session.call("can_debug_adjust"))
	var can_play := bool(combat_session.call("can_play_cards"))
	var can_bluff := bool(combat_session.call("can_bluff"))
	var can_reveal := bool(combat_session.call("can_reveal"))
	var has_committed := bool(deck_manager.call("has_committed_card")) if deck_manager != null else false
	var phase_key: String = String(combat_session.get("current_phase_key"))
	var run_state: Dictionary = run_manager.call("get_state") if run_manager != null else {}
	var waiting_for_reward := bool(run_state.get("waiting_for_reward", false))
	var run_outcome := String(run_state.get("run_outcome", "running"))
	var shell_blocks_combat := run_flow_state != RUN_FLOW_COMBAT
	var payout_blocks_combat := arena_payout_pending

	next_phase_button.disabled = shell_blocks_combat or (not payout_blocks_combat and not can_debug_adjust)
	next_phase_button.visible = run_flow_state == RUN_FLOW_COMBAT
	if run_flow_state == RUN_FLOW_START:
		next_phase_button.text = "Deal In"
	elif arena_payout_pending:
		next_phase_button.text = "Collect Payout"
	elif run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		next_phase_button.text = "Open Next Table"
	elif run_outcome == "victory":
		next_phase_button.text = "Run Complete"
	elif run_outcome == "defeat":
		next_phase_button.text = "Run Lost"
	elif waiting_for_reward:
		next_phase_button.text = "Choose Reward"
	else:
		next_phase_button.text = "Combat Over" if not can_debug_adjust else String(PHASE_ACTION_LABELS.get(phase_key, "Continue"))
	_refresh_primary_action_emphasis(shell_blocks_combat, payout_blocks_combat or can_debug_adjust, phase_key)
	reset_grid_button.disabled = payout_blocks_combat or not can_debug_adjust
	draw_button.disabled = payout_blocks_combat or not can_debug_adjust
	discard_hand_button.disabled = payout_blocks_combat or not can_debug_adjust
	reset_deck_button.disabled = payout_blocks_combat or not can_debug_adjust
	roll_intents_button.disabled = payout_blocks_combat or not can_debug_adjust
	reveal_intents_button.disabled = payout_blocks_combat or not can_reveal or reveal_resolved_this_phase
	run_playtests_button.disabled = run_manager == null
	export_summary_button.disabled = run_manager == null

	commit_first_card_button.disabled = shell_blocks_combat or payout_blocks_combat or not can_play or has_committed
	set_call_button.disabled = shell_blocks_combat or payout_blocks_combat or not can_bluff
	raise_button.disabled = shell_blocks_combat or payout_blocks_combat or not can_bluff or not has_committed
	fold_button.disabled = shell_blocks_combat or payout_blocks_combat or not can_bluff or not has_committed
	reset_bluff_button.disabled = shell_blocks_combat or payout_blocks_combat or not can_debug_adjust
	_refresh_guidance()
	if run_manager != null:
		_refresh_run_panel(run_state)
	_refresh_run_shell(run_state)
	_refresh_turn_status(run_state)
	_refresh_table_rule_status(run_state)
	var session_state: Dictionary = combat_session.call("get_state")
	_refresh_action_cue(session_state, run_state)
	_refresh_card_action_hint()
	_sync_hand_card_interaction()
	_sync_target_focus()
	_refresh_battlefield_focus()
	_refresh_compact_play_state(run_state)
	_refresh_action_guide(session_state, run_state)


func _refresh_primary_action_emphasis(shell_blocks_combat: bool, can_continue: bool, phase_key: String) -> void:
	if start_run_button != null:
		_apply_dominant_button_style(
			start_run_button,
			run_flow_state == RUN_FLOW_START,
			"Deal In to begin the first fight."
		)
		if run_flow_state == RUN_FLOW_START:
			start_run_button.text = "CLICK DEAL IN\nDraw Hand"
			start_run_button.custom_minimum_size = Vector2(300, 68)
			start_run_button.add_theme_font_size_override("font_size", 21)
	if next_encounter_button != null:
		_apply_dominant_button_style(
			next_encounter_button,
			run_flow_state == RUN_FLOW_NEXT_ENCOUNTER,
			"Open Next Table to continue the route."
		)
	if next_phase_button != null:
		var active: bool = run_flow_state == RUN_FLOW_COMBAT and can_continue and not shell_blocks_combat
		var hint: String = _get_continue_button_hint(phase_key)
		_apply_dominant_button_style(next_phase_button, active, hint)


func _apply_dominant_button_style(button: Button, active: bool, hint: String) -> void:
	if button == null:
		return

	button.tooltip_text = "Dominant next action: %s" % hint if active else "Locked: %s" % hint
	button.add_theme_font_size_override("font_size", 22 if active else 16)
	button.custom_minimum_size = Vector2(260, 54) if active else Vector2(180, 40)
	DEAD_MANS_ANTE_SKIN_SCRIPT.apply_button(button, active, button.tooltip_text)
	_ensure_button_hover_vfx(button)


func _refresh_action_guide(session_state: Dictionary, run_state: Dictionary) -> void:
	var guide := _get_action_guide_snapshot(session_state, run_state)
	var target: CanvasItem = guide.get("target", null)
	var label := String(guide.get("label", "CLICK"))
	var detail := String(guide.get("detail", ""))
	var color: Color = guide.get("color", FEEDBACK_CARD_COLOR)
	var key := "%s|%s|%s" % [label, detail, target.get_path() if target != null and target.is_inside_tree() else NodePath("")]

	guided_click_target = target
	guided_click_label = label
	guided_click_color = color

	if opening_click_prompt_label != null:
		opening_click_prompt_label.visible = run_flow_state == RUN_FLOW_START
		if opening_click_prompt_label.visible:
			opening_click_prompt_label.text = "%s: %s" % [label.to_upper(), detail.to_upper()]
			opening_click_prompt_label.add_theme_color_override("font_color", color.lerp(Color(1.0, 0.92, 0.52), 0.55))

	if combat_action_badge_label != null:
		combat_action_badge_label.visible = run_flow_state == RUN_FLOW_COMBAT
		combat_action_badge_label.text = "NEXT: %s - %s" % [label.to_upper(), detail]
		combat_action_badge_label.add_theme_color_override("font_color", color.lerp(Color(1.0, 0.92, 0.52), 0.45))

	if key != last_action_guide_key:
		last_action_guide_key = key
		_queue_guided_click_beacon()


func _get_action_guide_snapshot(session_state: Dictionary, run_state: Dictionary) -> Dictionary:
	match run_flow_state:
		RUN_FLOW_START:
			return {
				"target": start_run_button,
				"label": "CLICK",
				"detail": "Choose fighter, then Deal In",
				"color": FEEDBACK_CARD_COLOR
			}
		RUN_FLOW_REWARD:
			return {
				"target": _get_first_visible_reward_button(),
				"label": "TAKE",
				"detail": "Pick a reward",
				"color": FEEDBACK_CARD_COLOR
			}
		RUN_FLOW_NEXT_ENCOUNTER:
			return {
				"target": next_encounter_button,
				"label": "CLICK",
				"detail": "Open Next Table",
				"color": FEEDBACK_PHASE_COLOR
			}
		RUN_FLOW_RESULTS:
			return {
				"target": shell_new_run_button,
				"label": "NEW",
				"detail": "Start another run",
				"color": FEEDBACK_REVEAL_COLOR
			}

	if arena_payout_pending:
		return {
			"target": arena_payout_continue_button,
			"label": "COLLECT",
			"detail": "Arena payout",
			"color": FEEDBACK_CARD_COLOR
		}

	if bool(session_state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			return {
				"target": _get_first_visible_reward_button(),
				"label": "TAKE",
				"detail": "Choose reward",
				"color": FEEDBACK_CARD_COLOR
			}
		return {
			"target": next_phase_button,
			"label": "DONE",
			"detail": "Combat ended",
			"color": FEEDBACK_PHASE_COLOR
		}

	var phase_key := String(session_state.get("current_phase_key", "START_TURN"))
	if phase_key == "PLAYER_COMMIT":
		return _get_player_commit_action_guide()

	return {
		"target": next_phase_button,
		"label": "CLICK",
		"detail": String(next_phase_button.get("text")) if next_phase_button != null else "Continue",
		"color": FEEDBACK_PHASE_COLOR
	}


func _get_player_commit_action_guide() -> Dictionary:
	if _is_first_table_coach_active() and not first_play_coach_complete:
		if not bool(first_play_coach_steps.get("target", false)):
			return {
				"target": _get_first_live_enemy_target_card(),
				"label": "TARGET",
				"detail": "Click enemy",
				"color": FEEDBACK_DAMAGE_COLOR
			}
		if not bool(first_play_coach_steps.get("card", false)):
			return {
				"target": _get_first_playable_hand_card(),
				"label": "PLAY",
				"detail": "Glowing card",
				"color": FEEDBACK_CARD_COLOR
			}
		return {
			"target": next_phase_button,
			"label": "RESOLVE",
			"detail": "Enemy acts",
			"color": FEEDBACK_REVEAL_COLOR
		}

	var playable_card := _get_first_playable_hand_card()
	if playable_card != null:
		return {
			"target": playable_card,
			"label": "PLAY",
			"detail": "Glowing card",
			"color": FEEDBACK_CARD_COLOR
		}

	return {
		"target": next_phase_button,
		"label": "RESOLVE",
		"detail": "End turn",
		"color": FEEDBACK_REVEAL_COLOR
	}


func _refresh_battlefield_focus() -> void:
	if battlefield_focus_label == null:
		return

	if run_flow_state != RUN_FLOW_COMBAT:
		battlefield_focus_label.visible = false
		if battlefield_callout_label != null:
			battlefield_callout_label.visible = false
		if opponent_title_label != null:
			opponent_title_label.text = "Enemy Fighters"
		return

	battlefield_focus_label.visible = true
	if battlefield_callout_label != null:
		battlefield_callout_label.visible = true
	if arena_payout_pending:
		battlefield_focus_label.text = "ARENA PAYOUT READY  |  COLLECT REWARD  |  BUILD NEXT LOADOUT"
		battlefield_focus_label.tooltip_text = "The FPS wave is finished. Collect the payout first; the tactical board is hidden because there is no target decision right now."
		battlefield_focus_label.add_theme_color_override("font_color", FEEDBACK_CARD_COLOR)
		if battlefield_callout_label != null:
			battlefield_callout_label.text = "Collect payout to unlock the new hand, then slot/burn/upgrade cards for the next FPS arena."
			battlefield_callout_label.add_theme_color_override("font_color", FEEDBACK_CARD_COLOR)
		if opponent_title_label != null:
			opponent_title_label.text = "Arena Payout"
		return
	var target := _get_selected_enemy_target()
	var target_name := String(target.get("name", "Enemy")) if not target.is_empty() else "none"
	var target_role := _get_enemy_battle_role(target) if not target.is_empty() else "Enemy fighter"
	var target_intent := _get_enemy_intent_line(StringName(target.get("id", &""))) if not target.is_empty() else "no intent read"
	var target_status := _get_enemy_battle_state_text(target) if not target.is_empty() else "No target"
	var map_hint := _get_live_map_hint()
	var phase_text := String(next_phase_button.get("text")) if next_phase_button != null else "Resolve"
	battlefield_focus_label.text = "%s  |  %s  |  %s  |  %s" % [
		target_name.to_upper(),
		target_role,
		target_intent,
		phase_text.to_upper()
	]
	battlefield_focus_label.tooltip_text = "%s is an enemy %s. Your attack/read cards currently aim here. Click another enemy card to switch targets.\n%s" % [
		target_name,
		target_role,
		map_hint
	]
	var phase_key := String(combat_session.get("current_phase_key")) if combat_session != null else ""
	battlefield_focus_label.add_theme_color_override("font_color", FEEDBACK_CARD_COLOR if phase_key == "PLAYER_COMMIT" else FEEDBACK_PHASE_COLOR)
	_flash_canvas_item(battlefield_focus_label, FEEDBACK_CARD_COLOR, 0.12)
	if battlefield_callout_label != null:
		battlefield_callout_label.text = _get_battlefield_callout_text(phase_key, target_name, target_role, target_intent, target_status, map_hint)
		battlefield_callout_label.add_theme_color_override("font_color", _get_battlefield_callout_color(phase_key))

	if opponent_title_label != null:
		opponent_title_label.text = "Enemy Fighters\nTarget: %s" % target_name

	var table_title := combat_grid.find_child("TableTitle", true, false) if combat_grid != null else null
	if table_title is Label:
		(table_title as Label).text = "Crossfire - %s %s" % [target_status, target_name]


func _get_battlefield_callout_text(phase_key: String, target_name: String, target_role: String, target_intent: String, target_status: String, map_hint: String) -> String:
	if phase_key == "PLAYER_COMMIT":
		if _is_first_table_coach_active() and not bool(first_play_coach_steps.get("target", false)):
			return "Aim first: click a fighter card or pawn. Current aim: %s, the %s." % [target_name, target_role]
		if _is_first_table_coach_active() and not bool(first_play_coach_steps.get("card", false)):
			return "Play next: choose a glowing card. It will act on %s." % target_name
		return "Resolve next: press Resolve Turn and watch the arena answer."
	if phase_key == "BLUFF_WAGER":
		return "Bluff window: call, raise, or fold. Then Reveal Turn resolves the wager."
	if phase_key == "REVEAL":
		return "Reveal: enemy intent fires now. Watch HP, Guard, smoke, slash, and chips."
	if phase_key == "RESOLVE":
		return "Aftermath: read the wounds, then press Next Turn to deal the next hand."
	return "%s | %s | %s | %s" % [target_status, target_role, target_intent, map_hint]


func _get_live_map_hint() -> String:
	if combat_grid == null or not combat_grid.has_method("get_map_context"):
		return "Map: Crossfire Table"
	var map_context: Dictionary = combat_grid.call("get_map_context")
	var map_name := String(map_context.get("map_name", "Crossfire Table"))
	var player_feature := String(map_context.get("player_feature_label", ""))
	if player_feature.is_empty():
		return "Map: %s" % map_name
	return "Map: %s - you hold %s" % [map_name, player_feature]


func _get_battlefield_callout_color(phase_key: String) -> Color:
	match phase_key:
		"PLAYER_COMMIT":
			return FEEDBACK_CARD_COLOR
		"BLUFF_WAGER", "REVEAL":
			return FEEDBACK_REVEAL_COLOR
		"RESOLVE":
			return FEEDBACK_PHASE_COLOR
		_:
			return Color(1.0, 0.90, 0.56)


func _get_enemy_battle_state_text(enemy: Dictionary) -> String:
	if enemy.is_empty():
		return "No target"
	if not bool(enemy.get("alive", false)):
		return "Defeated"
	var enemy_id := StringName(enemy.get("id", &""))
	if enemy_id == _get_selected_enemy_target_id():
		return "Targeting"
	var hp_status := _get_enemy_hp_status(enemy)
	if hp_status == "FINISH":
		return "Wounded"
	return "Standing"


func _get_first_live_enemy_target_card() -> Button:
	for button in enemy_target_card_buttons:
		if button != null and button.is_inside_tree() and bool(button.get("visible")) and not bool(button.get("disabled")):
			return button
	return null


func _get_first_playable_hand_card() -> Button:
	if hand_view == null:
		return null
	for child in hand_view.get_children():
		if child is Button and bool(child.get("visible")) and not bool((child as Button).get("disabled")):
			return child as Button
	return null


func _get_first_visible_reward_button() -> Button:
	for button in card_reward_buttons:
		if button != null and button.is_inside_tree() and bool(button.get("visible")) and not bool(button.get("disabled")):
			return button
	if skip_rewards_button != null and skip_rewards_button.is_inside_tree() and bool(skip_rewards_button.get("visible")) and not bool(skip_rewards_button.get("disabled")):
		return skip_rewards_button
	return null


func _on_guide_beacon_timeout() -> void:
	_play_guided_click_beacon()


func _queue_guided_click_beacon() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(0.08).timeout.connect(_play_guided_click_beacon)


func _play_guided_click_beacon() -> void:
	if combat_vfx == null or not combat_vfx.has_method("play_click_beacon_on"):
		return
	if guided_click_target == null or not is_instance_valid(guided_click_target):
		return
	if not guided_click_target.is_inside_tree() or not bool(guided_click_target.get("visible")):
		return
	if guided_click_target is BaseButton and bool((guided_click_target as BaseButton).get("disabled")):
		return

	combat_vfx.call("play_click_beacon_on", guided_click_target, guided_click_color, guided_click_label)


func _ensure_button_hover_vfx(button: Button) -> void:
	if button == null or bool(button.get_meta("phase44_action_vfx_connected", false)):
		return

	button.mouse_entered.connect(_on_juicy_button_hovered.bind(button))
	button.button_down.connect(_on_juicy_button_pressed.bind(button))
	button.set_meta("phase44_action_vfx_connected", true)


func _on_juicy_button_hovered(button: Button) -> void:
	if button == null or not button.is_inside_tree() or bool(button.get("disabled")):
		return

	if combat_vfx != null and combat_vfx.has_method("play_button_sheen_on"):
		combat_vfx.call("play_button_sheen_on", button, FEEDBACK_CARD_COLOR)
	_flash_canvas_item(button, FEEDBACK_CARD_COLOR, 0.18)


func _on_juicy_button_pressed(button: Button) -> void:
	if button == null or not button.is_inside_tree() or bool(button.get("disabled")):
		return

	if combat_vfx != null and combat_vfx.has_method("play_button_sheen_on"):
		combat_vfx.call("play_button_sheen_on", button, FEEDBACK_REVEAL_COLOR)
	_flash_canvas_item(button, FEEDBACK_CARD_COLOR, 0.14)


func _get_continue_button_hint(phase_key: String) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "Deal In is the only live action."
	if arena_payout_pending:
		return "Collect the arena payout, then build the next hand."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Choose or skip the reward before combat continues."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Open Next Table from the approach panel."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Review results, export, or start a new run."

	match phase_key:
		"START_TURN", "DRAW", "ENEMY_INTENT_PREVIEW":
			return "Begin Turn unlocks target picking and card play."
		"PLAYER_COMMIT":
			return "Pick Target or Move, play a card, then Resolve Turn."
		"BLUFF_WAGER":
			return "Reveal Turn resolves the committed bluff."
		"REVEAL":
			return "Review Results after the reveal finishes."
		"RESOLVE", "CLEANUP":
			return "Next Turn cleans up and deals the next planning hand."
		_:
			return "Continue the combat loop."


func _refresh_action_cue(session_state: Dictionary, run_state: Dictionary) -> void:
	if action_cue_panel == null or action_cue_title_label == null or action_cue_detail_label == null or action_cue_pip_label == null:
		return

	var cue := _get_action_cue_snapshot(session_state, run_state)
	var title := String(cue.get("title", "PLAY"))
	var detail := String(cue.get("detail", "Read the table and take the next action."))
	var pip := String(cue.get("pip", "READY"))
	var color: Color = cue.get("color", FEEDBACK_PHASE_COLOR)
	var key := "%s|%s|%s" % [title, detail, pip]

	action_cue_title_label.text = title
	action_cue_detail_label.text = detail
	action_cue_pip_label.text = pip
	_style_action_cue(color)
	if key != last_action_cue_key:
		last_action_cue_key = key
		_pulse_canvas_item(action_cue_panel, color)


func _get_action_cue_snapshot(session_state: Dictionary, run_state: Dictionary) -> Dictionary:
	if run_flow_state == RUN_FLOW_START:
		return {
			"title": "DEAL IN",
			"detail": "Deal In to draw five cards and reveal the first enemy target.",
			"pip": "OPEN",
			"color": FEEDBACK_CARD_COLOR
		}
	if run_flow_state == RUN_FLOW_REWARD:
		return {
			"title": "CASH OUT",
			"detail": "Take the highlighted reward, or skip to keep the deck lean and move the marker.",
			"pip": "REWARD",
			"color": FEEDBACK_CARD_COLOR
		}
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return {
			"title": "APPROACH",
			"detail": "Read the enemy cards and table rule, then Open Next Table when the matchup feels right.",
			"pip": "NEXT",
			"color": FEEDBACK_PHASE_COLOR
		}
	if run_flow_state == RUN_FLOW_RESULTS:
		return {
			"title": "FINAL HAND",
			"detail": "Export the run summary or start a fresh run from the results ceremony.",
			"pip": "RESULTS",
			"color": _get_results_cue_color(run_state)
		}

	if bool(session_state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			return {
				"title": "PAYOUT",
				"detail": "The table is cleared. Pick a reward to keep the run moving.",
				"pip": "REWARD",
				"color": FEEDBACK_CARD_COLOR
			}
		return {
			"title": "TABLE ENDS",
			"detail": "Combat is over. Review the result and follow the run shell.",
			"pip": "DONE",
			"color": FEEDBACK_PHASE_COLOR
		}

	var phase_key := String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"START_TURN", "DRAW", "ENEMY_INTENT_PREVIEW":
			return {
				"title": "SET THE TABLE",
				"detail": "Begin Turn finishes setup and deals you straight into card play.",
				"pip": "BEGIN",
				"color": FEEDBACK_PHASE_COLOR
			}
		"PLAYER_COMMIT":
			var target_name := String(_get_selected_enemy_target().get("name", "target"))
			var energy := int(session_state.get("energy", 0))
			var detail := "Target %s, play a lit card, then Resolve Turn." % target_name
			if energy <= 0:
				detail = "Energy is spent. Resolve Turn to let the table answer."
			return {
				"title": "YOUR PLAY",
				"detail": detail,
				"pip": "PLAY",
				"color": FEEDBACK_CARD_COLOR
			}
		"BLUFF_WAGER":
			return {
				"title": "MAKE THE CALL",
				"detail": "Call the intent, raise if confident, or fold before the reveal.",
				"pip": "BLUFF",
				"color": FEEDBACK_REVEAL_COLOR
			}
		"REVEAL":
			return {
				"title": "REVEAL",
				"detail": "The committed card and enemy intent are turning over.",
				"pip": "FLIP",
				"color": FEEDBACK_REVEAL_COLOR
			}
		"RESOLVE", "CLEANUP":
			return {
				"title": "NEXT HAND",
				"detail": "Press Next Turn to clean up, draw, read, and return to planning.",
				"pip": "NEXT",
				"color": FEEDBACK_MOVE_COLOR
			}
		_:
			return {
				"title": "PLAY",
				"detail": "Read the table and take the highlighted action.",
				"pip": "READY",
				"color": FEEDBACK_PHASE_COLOR
			}


func _style_action_cue(color: Color) -> void:
	var panel_style := DEAD_MANS_ANTE_SKIN_SCRIPT.make_panel_style(
		Color(0.055, 0.050, 0.045).lerp(color, 0.11),
		color,
		"cue"
	)
	action_cue_panel.add_theme_stylebox_override("panel", panel_style)

	action_cue_title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76))
	action_cue_detail_label.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	action_cue_pip_label.add_theme_font_size_override("font_size", 15)
	action_cue_pip_label.add_theme_color_override("font_color", Color(0.08, 0.06, 0.035))

	var pip_style := DEAD_MANS_ANTE_SKIN_SCRIPT.make_action_pip_style(color)
	action_cue_pip_label.add_theme_stylebox_override("normal", pip_style)


func _get_results_cue_color(run_state: Dictionary) -> Color:
	return FEEDBACK_PHASE_COLOR if String(run_state.get("run_outcome", "running")) == "victory" else FEEDBACK_DAMAGE_COLOR


func _refresh_run_panel(state: Dictionary) -> void:
	if run_state_label == null:
		return

	var node_index := int(state.get("current_node_index", 0)) + 1
	var node_count := int(state.get("current_node_count", 0))
	var relic_names: Array = state.get("relic_names", [])
	var relic_text := "None" if relic_names.is_empty() else ", ".join(relic_names)
	var balance: Dictionary = state.get("balance_snapshot", {})
	var evaluation: Dictionary = balance.get("evaluation", {})
	var deck_profile: Dictionary = evaluation.get("deck", {})
	var encounter_profile: Dictionary = evaluation.get("encounter", {})
	var fast_run: Dictionary = balance.get("fast_run", {})
	var playtest_batch: Dictionary = balance.get("playtest_batch", {})
	_refresh_run_header(state, evaluation)
	_refresh_run_path(state)
	_refresh_debug_summary(state, evaluation, fast_run, playtest_batch)

	run_state_label.clear()
	run_state_label.append_text("Table %d/%d: %s [%s]\n" % [
		min(node_index, node_count),
		node_count,
		state.get("current_node_name", "Complete"),
		state.get("current_node_kind", "")
	])
	run_state_label.append_text("Blood: %d/%d | Deck: %d | Relics: %s\n" % [
		state.get("player_hp", 0),
		state.get("player_max_hp", 0),
		state.get("deck_size", 0),
		relic_text
	])
	run_state_label.append_text("Run: %s" % state.get("run_outcome", "running"))

	if balance_report_label != null:
		var rating := String(evaluation.get("rating", "unknown"))
		var band_label := _get_balance_band_label(rating)
		balance_report_label.modulate = _get_balance_band_color(rating)
		balance_report_label.clear()
		balance_report_label.append_text("%s | Est. %d turns | Margin %.1f\n" % [
			band_label,
			evaluation.get("projected_turns", 0),
			evaluation.get("survival_margin", 0.0)
		])
		balance_report_label.append_text("Deck %.1f dmg/turn, %.1f guard/turn vs %.1f threat\n" % [
			deck_profile.get("projected_damage_per_turn", 0.0),
			deck_profile.get("projected_guard_per_turn", 0.0),
			encounter_profile.get("expected_damage_per_turn", 0.0)
		])
		balance_report_label.append_text("Fast sim: %s, clears %d/%d, end Blood %d" % [
			fast_run.get("predicted_outcome", "unknown"),
			fast_run.get("predicted_clears", 0),
			fast_run.get("total_nodes", 0),
			fast_run.get("ending_hp", 0)
		])
		balance_report_label.append_text("\nResponse: %s" % evaluation.get("recommendation", "Read the table before committing."))

	_refresh_playtest_report(playtest_batch)

	var results: Dictionary = state.get("run_results", {})
	if run_results_label != null:
		run_results_label.clear()
		var outcome := String(state.get("run_outcome", "running"))
		if outcome == "running":
			run_results_label.visible = false
		else:
			run_results_label.visible = true
			run_results_label.append_text("%s | %s\n" % [
				results.get("title", "Run Complete"),
				results.get("grade", "Table Stakes")
			])
			run_results_label.append_text("Won %d/%d | Damage taken %d | Lowest Blood %d\n" % [
				results.get("combats_won", 0),
				results.get("total_combats", 0),
				results.get("damage_taken_total", 0),
				results.get("lowest_blood", 0)
			])
			run_results_label.append_text("Deck %d | Cards +%d | Relics +%d" % [
				results.get("deck_size", 0),
				results.get("cards_claimed", 0),
				results.get("relics_claimed", 0)
			])

	_refresh_export_readback_label()
	_refresh_run_history_label(false)
	_refresh_run_inspector_label(false)

	var card_rewards: Array = state.get("pending_card_rewards", [])
	var relic_rewards: Array = state.get("pending_relic_rewards", [])
	_refresh_reward_prompt(state, card_rewards, relic_rewards)
	_refresh_reward_impact(state, card_rewards, relic_rewards)
	for index in range(card_reward_buttons.size()):
		var button := card_reward_buttons[index]
		if index < card_rewards.size():
			var reward: Dictionary = card_rewards[index]
			button.text = _get_card_reward_button_text(reward, index)
			button.tooltip_text = _get_card_reward_tooltip_text(reward, index)
			button.disabled = false
			button.visible = true
			button.modulate = Color(1.0, 0.95, 0.72) if index == 0 else Color.WHITE
		else:
			button.text = "Card Reward"
			button.tooltip_text = "No card reward in this slot."
			button.disabled = true
			button.visible = false
			button.modulate = Color.WHITE

	for index in range(relic_reward_buttons.size()):
		var button := relic_reward_buttons[index]
		if index < relic_rewards.size():
			var reward: Dictionary = relic_rewards[index]
			button.text = "Take Relic\n%s\n%s" % [reward.get("name", "Relic"), reward.get("text", "")]
			button.disabled = false
			button.visible = true
		else:
			button.text = "Relic Reward"
			button.disabled = true
			button.visible = false

	if skip_rewards_button != null:
		skip_rewards_button.disabled = not bool(state.get("waiting_for_reward", false))
		skip_rewards_button.visible = bool(state.get("waiting_for_reward", false))
		skip_rewards_button.text = "Skip Reward - keep deck lean" if bool(state.get("waiting_for_reward", false)) else "Skip Rewards"
	_maybe_play_reward_shimmer(state, card_rewards)
	_sync_run_panel_visibility()


func _refresh_playtest_report(batch: Dictionary) -> void:
	if playtest_report_label == null:
		return

	playtest_report_label.clear()
	if batch.is_empty():
		playtest_report_label.append_text("Playtest sims: not run yet.")
		return

	playtest_report_label.append_text("5-run sims: %d wins / %d losses | Avg end Blood %.1f\n" % [
		batch.get("wins", 0),
		batch.get("losses", 0),
		batch.get("average_ending_hp", 0.0)
	])
	playtest_report_label.append_text("Worst margin %.1f | %s" % [
		batch.get("worst_margin", 0.0),
		batch.get("summary", "")
	])
	var danger_nodes: Array = batch.get("danger_nodes", [])
	if danger_nodes.is_empty():
		playtest_report_label.append_text("\nWatch: no repeated danger nodes in the current sims.")
	else:
		playtest_report_label.append_text("\nWatch: %s" % ", ".join(danger_nodes))


func _maybe_play_reward_shimmer(state: Dictionary, card_rewards: Array) -> void:
	if combat_vfx == null or not combat_vfx.has_method("play_reward_shimmer_on"):
		return
	if run_flow_state != RUN_FLOW_REWARD or not bool(state.get("waiting_for_reward", false)) or card_rewards.is_empty():
		last_reward_shimmer_key = ""
		return
	if card_reward_buttons.is_empty() or card_reward_buttons[0] == null:
		return

	var first_reward: Dictionary = card_rewards[0] if typeof(card_rewards[0]) == TYPE_DICTIONARY else {}
	var key := "%s|%s|%s" % [
		state.get("current_node_index", 0),
		first_reward.get("id", first_reward.get("name", "reward")),
		state.get("deck_size", 0)
	]
	if key == last_reward_shimmer_key:
		return
	last_reward_shimmer_key = key
	call_deferred("_play_reward_shimmer_deferred", 0)


func _play_reward_shimmer_deferred(button_index: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if combat_vfx == null or not combat_vfx.has_method("play_reward_shimmer_on"):
		return
	if button_index < 0 or button_index >= card_reward_buttons.size():
		return

	var button := card_reward_buttons[button_index]
	if button == null or not _is_live_canvas_item(button) or not bool(button.get("visible")) or bool(button.get("disabled")):
		return
	combat_vfx.call("play_reward_shimmer_on", button)


func _refresh_debug_summary(state: Dictionary, evaluation: Dictionary, fast_run: Dictionary, playtest_batch: Dictionary) -> void:
	if debug_summary_label == null:
		return

	debug_summary_label.clear()
	debug_summary_label.append_text("Run index %d/%d | Flow %s | Outcome %s\n" % [
		min(int(state.get("current_node_index", 0)) + 1, int(state.get("current_node_count", 0))),
		state.get("current_node_count", 0),
		run_flow_state,
		state.get("run_outcome", "running")
	])
	debug_summary_label.append_text("Balance %s | margin %.1f | fast %s %d/%d\n" % [
		evaluation.get("rating", "unknown"),
		evaluation.get("survival_margin", 0.0),
		fast_run.get("predicted_outcome", "unknown"),
		fast_run.get("predicted_clears", 0),
		fast_run.get("total_nodes", 0)
	])
	debug_summary_label.append_text("Playtest %dW/%dL | avg Blood %.1f" % [
		playtest_batch.get("wins", 0),
		playtest_batch.get("losses", 0),
		playtest_batch.get("average_ending_hp", 0.0)
	])


func _set_run_flow_state(new_state: String) -> void:
	if run_flow_state == new_state:
		return
	run_flow_state = new_state


func _sync_run_flow_from_state(state: Dictionary) -> void:
	var run_outcome := String(state.get("run_outcome", "running"))
	if run_outcome != "running":
		_set_run_flow_state(RUN_FLOW_RESULTS)
		_ensure_results_ceremony(state)
	elif bool(state.get("waiting_for_reward", false)):
		_set_run_flow_state(RUN_FLOW_REWARD)
	elif bool(state.get("can_start_current_node", false)) and (run_flow_state == RUN_FLOW_REWARD or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER):
		_set_run_flow_state(RUN_FLOW_NEXT_ENCOUNTER)
	elif run_flow_state != RUN_FLOW_START:
		_set_run_flow_state(RUN_FLOW_COMBAT)
	_refresh_run_shell(state)
	if phase_guidance_label != null:
		_refresh_guidance()


func _refresh_run_shell(state: Dictionary) -> void:
	if run_shell_panel == null or run_shell_title_label == null or run_shell_detail_label == null:
		return

	run_shell_panel.visible = true
	_style_run_shell_for_state()
	run_shell_title_label.text = _get_run_shell_title(state)
	run_shell_detail_label.clear()
	run_shell_detail_label.append_text(_get_run_shell_detail(state))
	_refresh_opening_steps()
	if run_continuity_label != null:
		run_continuity_label.clear()
		run_continuity_label.append_text(_get_run_continuity_text(state))
	_refresh_run_ceremony(state)
	if encounter_preview_label != null:
		encounter_preview_label.visible = _should_show_encounter_preview()
		encounter_preview_label.clear()
		encounter_preview_label.append_text(_get_encounter_preview_text(state))
	_refresh_encounter_approach(state)
	_refresh_run_finale(state)

	if start_run_button != null:
		start_run_button.visible = run_flow_state == RUN_FLOW_START
		start_run_button.disabled = run_flow_state != RUN_FLOW_START
		start_run_button.text = "DEAL IN\nDraw Class Hand"
		if run_flow_state == RUN_FLOW_START:
			start_run_button.custom_minimum_size = Vector2(300, 58)
			start_run_button.add_theme_font_size_override("font_size", 20)
	if next_encounter_button != null:
		next_encounter_button.visible = run_flow_state == RUN_FLOW_NEXT_ENCOUNTER
		next_encounter_button.disabled = run_flow_state != RUN_FLOW_NEXT_ENCOUNTER
		next_encounter_button.text = "Open Next Table"
	if shell_new_run_button != null:
		shell_new_run_button.visible = run_flow_state == RUN_FLOW_RESULTS
		shell_new_run_button.disabled = run_flow_state != RUN_FLOW_RESULTS
	if shell_export_button != null:
		shell_export_button.visible = run_flow_state == RUN_FLOW_RESULTS
		shell_export_button.disabled = run_flow_state != RUN_FLOW_RESULTS
	var optional_shell_tools_visible: bool = run_flow_state != RUN_FLOW_START
	if shell_inspect_run_button != null:
		shell_inspect_run_button.visible = optional_shell_tools_visible
		shell_inspect_run_button.disabled = run_manager == null
	if shell_view_history_button != null:
		shell_view_history_button.visible = optional_shell_tools_visible
		shell_view_history_button.disabled = run_manager == null
	var history_tools_visible: bool = run_history_requested or run_flow_state == RUN_FLOW_RESULTS
	if shell_export_history_csv_button != null:
		shell_export_history_csv_button.visible = history_tools_visible
		shell_export_history_csv_button.disabled = run_manager == null
	if shell_archive_history_button != null:
		shell_archive_history_button.visible = history_tools_visible
		shell_archive_history_button.disabled = run_manager == null
	_sync_opening_idle_animation()


func _style_run_shell_for_state() -> void:
	if not (run_shell_panel is PanelContainer):
		return

	match run_flow_state:
		RUN_FLOW_START:
			_style_play_panel(run_shell_panel, Color(0.13, 0.075, 0.040, 0.96), FEEDBACK_CARD_COLOR, "cue")
		RUN_FLOW_REWARD:
			_style_play_panel(run_shell_panel, Color(0.12, 0.072, 0.045, 0.94), FEEDBACK_CARD_COLOR, "panel")
		RUN_FLOW_NEXT_ENCOUNTER:
			_style_play_panel(run_shell_panel, Color(0.060, 0.080, 0.090, 0.94), FEEDBACK_PHASE_COLOR, "panel")
		RUN_FLOW_RESULTS:
			_style_play_panel(run_shell_panel, Color(0.075, 0.060, 0.065, 0.95), FEEDBACK_REVEAL_COLOR, "panel")
		_:
			_style_play_panel(run_shell_panel, Color(0.105, 0.085, 0.072), Color(0.64, 0.45, 0.22))


func _refresh_opening_steps() -> void:
	if opening_step_row == null:
		return

	opening_step_row.visible = run_flow_state == RUN_FLOW_START
	if not opening_step_row.visible:
		return

	var colors := [FEEDBACK_CARD_COLOR, FEEDBACK_REVEAL_COLOR, FEEDBACK_MOVE_COLOR, FEEDBACK_PHASE_COLOR]
	for index in range(opening_step_buttons.size()):
		var button := opening_step_buttons[index]
		var active := index == 0
		button.visible = true
		button.disabled = false
		button.self_modulate = Color.WHITE if active else Color(0.88, 0.90, 0.96, 0.82)
		button.add_theme_font_size_override("font_size", 13 if active else 12)
		_style_compact_button(button, true, colors[index], button.tooltip_text)


func _sync_opening_idle_animation() -> void:
	var should_play := run_flow_state == RUN_FLOW_START and start_run_button != null and start_run_button.visible and not bool(start_run_button.get("disabled"))
	if not should_play:
		if opening_idle_tween != null and opening_idle_tween.is_valid():
			opening_idle_tween.kill()
		opening_idle_tween = null
		if start_run_button != null:
			start_run_button.modulate = Color.WHITE
		return

	if opening_idle_tween != null and opening_idle_tween.is_valid():
		return

	opening_idle_tween = create_tween()
	opening_idle_tween.set_loops()
	opening_idle_tween.tween_property(start_run_button, "modulate", Color(1.0, 0.88, 0.48), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening_idle_tween.tween_property(start_run_button, "modulate", Color.WHITE, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _get_run_shell_title(state: Dictionary) -> String:
	match run_flow_state:
		RUN_FLOW_START:
			return "Opening Table: Pick Your Fighter"
		RUN_FLOW_REWARD:
			return "Post-Combat Reward"
		RUN_FLOW_NEXT_ENCOUNTER:
			return "Next Table"
		RUN_FLOW_RESULTS:
			var results: Dictionary = state.get("run_results", {})
			return String(results.get("title", "Run Results"))
		_:
			return "Current Table"


func _get_run_shell_detail(state: Dictionary) -> String:
	var node_index: int = min(int(state.get("current_node_index", 0)) + 1, int(state.get("current_node_count", 0)))
	var node_count := int(state.get("current_node_count", 0))
	match run_flow_state:
		RUN_FLOW_START:
			return "Choose a fighter deck, then Deal In. Your cards become weapons, armor, reads, traps, and FPS abilities in the arena."
		RUN_FLOW_REWARD:
			var card_rewards: Array = state.get("pending_card_rewards", [])
			var relic_rewards: Array = state.get("pending_relic_rewards", [])
			var best_card := "a card reward"
			if not card_rewards.is_empty() and typeof(card_rewards[0]) == TYPE_DICTIONARY:
				best_card = String(Dictionary(card_rewards[0]).get("name", "a card reward"))
			var relic_note := " Claim the relic after the card." if not relic_rewards.is_empty() else ""
			return "Table %d cleared. Choose %s to advance the run.%s" % [
				max(1, node_index),
				best_card,
				relic_note
			]
		RUN_FLOW_NEXT_ENCOUNTER:
			var balance: Dictionary = state.get("balance_snapshot", {})
			var evaluation: Dictionary = balance.get("evaluation", {})
			var enemies: Array = state.get("current_enemy_names", [])
			var enemy_text: String = "unknown opposition" if enemies.is_empty() else ", ".join(enemies)
			var modifier: Dictionary = state.get("table_modifier", {})
			return "Up next: %s [%s].\nBlood %d/%d | Deck %d | %s | Est. %d turns against %s.\nApproach: review enemy cards, table rule, and reward stakes before dealing in.\nTable rule: %s." % [
				state.get("current_node_name", "Encounter"),
				state.get("current_node_kind", "combat"),
				state.get("player_hp", 0),
				state.get("player_max_hp", 0),
				state.get("deck_size", 0),
				_get_balance_band_label(String(evaluation.get("rating", "unknown"))),
				evaluation.get("projected_turns", 0),
				enemy_text,
				modifier.get("name", "House Rules")
			]
		RUN_FLOW_RESULTS:
			var results: Dictionary = state.get("run_results", {})
			return "Finale ready: %s | %s.\nWon %d/%d | Blood %d/%d | Damage taken %d | Lowest Blood %d | Deck %d cards.\nExport the summary or start a fresh run." % [
				results.get("title", "Run Results"),
				results.get("grade", "Table Stakes"),
				results.get("combats_won", 0),
				results.get("total_combats", 0),
				results.get("blood", 0),
				results.get("max_blood", 0),
				results.get("damage_taken_total", 0),
				results.get("lowest_blood", 0),
				results.get("deck_size", 0)
			]
		_:
			return "Table %d/%d is live: %s.\nUse the threat summary, target selector, and next-action prompt to play the turn." % [
				node_index,
				node_count,
				state.get("current_node_name", "Encounter")
			]


func _get_run_continuity_text(state: Dictionary) -> String:
	var node_count := int(state.get("current_node_count", 0))
	var current_index: int = mini(int(state.get("current_node_index", 0)) + 1, node_count)
	match run_flow_state:
		RUN_FLOW_START:
			return "Blood %d/%d | Deck %d | First fight is ready." % [
				state.get("player_hp", 0),
				state.get("player_max_hp", 0),
				state.get("deck_size", 0)
			]
		RUN_FLOW_COMBAT:
			return "Run map: marker is on Table %d/%d, %s. Clear the table to open rewards or results." % [
				current_index,
				node_count,
				state.get("current_node_name", "Encounter")
			]
		RUN_FLOW_REWARD:
			var next_table := _get_next_table_name_after_reward(state)
			return "Run map: %s is cleared for rewards; %s is marked NEXT." % [
				state.get("last_completed_node_name", "Table"),
				next_table
			]
		RUN_FLOW_NEXT_ENCOUNTER:
			return "Run map: marker has moved to %s (%d/%d). Open Next Table to continue the same run." % [
				state.get("current_node_name", "Encounter"),
				current_index,
				node_count
			]
		RUN_FLOW_RESULTS:
			var results: Dictionary = state.get("run_results", {})
			return "Final result: %s. Finale panel explains the run; export the summary or start a fresh run." % results.get("grade", "Table Stakes")
		_:
			return "Run continuity is waiting for the next state."


func _refresh_run_ceremony(state: Dictionary) -> void:
	if run_ceremony_panel == null or run_ceremony_label == null:
		return

	var should_show: bool = _should_show_run_ceremony(state)
	run_ceremony_panel.visible = should_show
	if not should_show:
		return

	run_ceremony_label.clear()
	run_ceremony_label.append_text("Run Ceremony\n")
	run_ceremony_label.append_text("%s\n" % _get_run_ceremony_steps_text(state))
	if run_ceremony_history.is_empty():
		run_ceremony_label.append_text("Latest: ceremony waiting for the next combat result.")
		return

	run_ceremony_label.append_text("Latest: %s\n" % run_ceremony_history[0])
	if run_flow_state == RUN_FLOW_COMBAT:
		return
	run_ceremony_label.append_text("Thread:\n%s" % _get_run_ceremony_thread_text())


func _should_show_run_ceremony(state: Dictionary) -> bool:
	if String(state.get("run_outcome", "running")) != "running":
		return not run_ceremony_history.is_empty()
	if run_flow_state == RUN_FLOW_REWARD or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return true
	if run_flow_state == RUN_FLOW_COMBAT and not run_ceremony_history.is_empty():
		return true
	return false


func _get_run_ceremony_steps_text(state: Dictionary) -> String:
	var steps := PackedStringArray()
	match run_flow_state:
		RUN_FLOW_REWARD:
			steps.append("[DONE] Victory")
			steps.append("[ACTIVE] Reward")
			steps.append("[WAIT] Map Move")
			steps.append("[WAIT] Approach")
		RUN_FLOW_NEXT_ENCOUNTER:
			steps.append("[DONE] Victory")
			steps.append("[DONE] Reward")
			steps.append("[DONE] Map Move")
			steps.append("[ACTIVE] Approach")
		RUN_FLOW_RESULTS:
			var outcome: String = String(state.get("run_outcome", "running"))
			if outcome == "victory":
				steps.append("[DONE] Final Table")
				steps.append("[DONE] Boss Victory")
				steps.append("[ACTIVE] Results")
			elif outcome == "defeat":
				steps.append("[DONE] Combat")
				steps.append("[DONE] Defeat")
				steps.append("[ACTIVE] Results")
			else:
				steps.append("[DONE] Combat")
				steps.append("[ACTIVE] Results")
		_:
			if String(state.get("run_outcome", "running")) == "defeat":
				steps.append("[DONE] Combat")
				steps.append("[ACTIVE] Results")
			else:
				steps.append("[DONE] Victory")
				steps.append("[DONE] Reward")
				steps.append("[DONE] Approach")
				steps.append("[ACTIVE] Combat")
	return " -> ".join(steps)


func _get_run_ceremony_thread_text() -> String:
	var entries := PackedStringArray()
	var limit: int = min(3, run_ceremony_history.size())
	for index in range(limit):
		entries.append("- %s" % run_ceremony_history[index])
	return "\n".join(entries)


func _record_run_ceremony(message: String, color: Color = FEEDBACK_PHASE_COLOR, pulse_node: Node = null) -> void:
	if message.is_empty():
		return

	run_ceremony_history.push_front(message)
	while run_ceremony_history.size() > 6:
		run_ceremony_history.pop_back()
	if run_manager != null:
		_refresh_run_ceremony(run_manager.call("get_state"))
	if run_ceremony_panel != null:
		_pulse_canvas_item(run_ceremony_panel, color)
	_push_feedback(message, color, pulse_node if pulse_node != null else run_ceremony_panel)


func _ensure_results_ceremony(state: Dictionary) -> void:
	var outcome: String = String(state.get("run_outcome", "running"))
	if outcome == "running" or last_results_ceremony_outcome == outcome:
		return

	last_results_ceremony_outcome = outcome
	var results: Dictionary = state.get("run_results", {})
	if outcome == "victory":
		_record_run_ceremony("Boss Victory Finale: %s folded. %s results are ready." % [
			state.get("last_completed_node_name", "Final Table"),
			results.get("grade", "Run")
		], FEEDBACK_PHASE_COLOR, run_shell_panel)
	elif outcome == "defeat":
		_record_run_ceremony("Defeat Finale: the House stopped the run at %s. Results are ready." % state.get("current_node_name", "this table"), FEEDBACK_DAMAGE_COLOR, run_shell_panel)


func _refresh_run_finale(state: Dictionary) -> void:
	if run_finale_panel == null or run_finale_label == null:
		return

	var should_show: bool = run_flow_state == RUN_FLOW_RESULTS
	run_finale_panel.visible = should_show
	if not should_show:
		return

	run_finale_label.clear()
	run_finale_label.append_text(_get_run_finale_text(state))
	run_finale_label.modulate = FEEDBACK_PHASE_COLOR if String(state.get("run_outcome", "running")) == "victory" else FEEDBACK_DAMAGE_COLOR


func _get_run_finale_text(state: Dictionary) -> String:
	var results: Dictionary = state.get("run_results", {})
	var comparison: Dictionary = state.get("comparison_summary", {})
	var compare_key: String = String(comparison.get("result_key", "run_key_pending"))
	var outcome: String = String(results.get("outcome", state.get("run_outcome", "running")))
	if outcome == "victory":
		return "Boss Victory Finale\nHouse Champion folded. Prototype path cleared with %s.\nTables: %d/%d | Blood %d/%d | Lowest Blood %d | Damage Taken %d\nDeck: %d cards | Rewards: +%d cards / +%d relics\nCompare Key: %s\nNext: Export Summary to compare the run, or start a fresh run." % [
			results.get("grade", "Table Stakes"),
			results.get("combats_won", 0),
			results.get("total_combats", 0),
			results.get("blood", 0),
			results.get("max_blood", 0),
			results.get("lowest_blood", 0),
			results.get("damage_taken_total", 0),
			results.get("deck_size", 0),
			results.get("cards_claimed", 0),
			results.get("relics_claimed", 0),
			compare_key
		]

	var fallen_table: String = String(state.get("current_node_name", results.get("last_completed_node_name", "this table")))
	return "Defeat Finale\nThe House takes %s. %s.\nTables Cleared: %d/%d | Blood 0/%d | Lowest Blood %d | Damage Taken %d\nDeck: %d cards | Rewards: +%d cards / +%d relics\nCompare Key: %s\nNext: Export Summary to inspect the loss, or start a fresh run." % [
		fallen_table,
		results.get("grade", "House Win"),
		results.get("combats_won", 0),
		results.get("total_combats", 0),
		results.get("max_blood", 0),
		results.get("lowest_blood", 0),
		results.get("damage_taken_total", 0),
		results.get("deck_size", 0),
		results.get("cards_claimed", 0),
		results.get("relics_claimed", 0),
		compare_key
	]


func _should_show_encounter_preview() -> bool:
	return run_flow_state == RUN_FLOW_NEXT_ENCOUNTER or (run_flow_state == RUN_FLOW_COMBAT and debug_controls_visible)


func _get_encounter_preview_text(state: Dictionary) -> String:
	var table_name: String = String(state.get("current_node_name", "Encounter"))
	var intro: String = String(state.get("encounter_intro", "Read the table before combat starts."))
	var modifier: Dictionary = state.get("table_modifier", {})
	var modifier_name: String = String(modifier.get("name", "No table modifier"))
	var modifier_summary: String = String(modifier.get("summary", "No special rule is active."))
	var tactical_map: Dictionary = state.get("tactical_map", {})
	var map_name: String = String(tactical_map.get("name", "Crossfire Table"))
	var map_summary: String = String(tactical_map.get("summary", "Use cover, center control, and long angles."))
	var reward_stakes: String = String(state.get("reward_stakes", "Clear the table to improve the run."))
	var enemies: Array = state.get("current_enemy_names", [])
	var enemy_text: String = "unknown opposition" if enemies.is_empty() else ", ".join(enemies)
	var reward_tags: Array = state.get("reward_tag_names", [])
	var tag_text: String = "Run clear" if reward_tags.is_empty() else ", ".join(reward_tags)

	return "Encounter: %s\nEnemies: %s\nIntro: %s\nMap: %s - %s\nModifier: %s - %s\nReward stakes: %s\nReward tags: %s" % [
		table_name,
		enemy_text,
		intro,
		map_name,
		map_summary,
		modifier_name,
		modifier_summary,
		reward_stakes,
		tag_text
	]


func _refresh_encounter_approach(state: Dictionary) -> void:
	if encounter_approach_panel == null:
		return

	var should_show: bool = _should_show_encounter_approach()
	encounter_approach_panel.visible = should_show
	if not should_show:
		return

	var entry: Dictionary = _get_current_run_path_entry(state)
	var node_index: int = min(int(state.get("current_node_index", 0)) + 1, int(state.get("current_node_count", 0)))
	var node_count: int = int(state.get("current_node_count", 0))
	if approach_title_label != null:
		approach_title_label.text = "Approach Table %d/%d: %s [%s]" % [
			node_index,
			node_count,
			entry.get("name", state.get("current_node_name", "Encounter")),
			String(entry.get("kind", state.get("current_node_kind", "combat"))).capitalize()
		]

	if approach_enemy_cards_label != null:
		approach_enemy_cards_label.clear()
		approach_enemy_cards_label.append_text(_get_approach_enemy_cards_text(entry))

	if approach_rule_label != null:
		approach_rule_label.clear()
		approach_rule_label.append_text(_get_approach_rule_text(entry))

	if approach_stakes_label != null:
		approach_stakes_label.clear()
		approach_stakes_label.append_text(_get_approach_stakes_text(entry))


func _should_show_encounter_approach() -> bool:
	return run_flow_state == RUN_FLOW_NEXT_ENCOUNTER


func _get_current_run_path_entry(state: Dictionary) -> Dictionary:
	var path_entries: Array = state.get("run_path", [])
	var index: int = clampi(int(state.get("current_node_index", 0)), 0, max(0, path_entries.size() - 1))
	if index >= 0 and index < path_entries.size() and typeof(path_entries[index]) == TYPE_DICTIONARY:
		return Dictionary(path_entries[index])

	var modifier: Dictionary = state.get("table_modifier", {})
	var tactical_map: Dictionary = state.get("tactical_map", {})
	return {
		"name": String(state.get("current_node_name", "Encounter")),
		"kind": String(state.get("current_node_kind", "combat")),
		"enemy_cards": state.get("current_enemy_cards", []),
		"tactical_map_name": String(tactical_map.get("name", "Crossfire Table")),
		"tactical_map_summary": String(tactical_map.get("summary", "Use cover, center control, and long angles.")),
		"table_modifier_name": String(modifier.get("name", "House Rules")),
		"table_modifier_summary": String(modifier.get("summary", "No special rule is active.")),
		"reward_stakes": String(state.get("reward_stakes", "Clear the table to improve the run.")),
		"reward_tag_names": state.get("reward_tag_names", [])
	}


func _get_approach_enemy_cards_text(entry: Dictionary) -> String:
	var enemy_cards: Array = entry.get("enemy_cards", [])
	if enemy_cards.is_empty():
		return "Enemy Cards\n[Enemy Card] Unknown opposition\nTell: no readable tell yet.\nCounter: enter combat and read the first intent."

	var lines := PackedStringArray()
	lines.append("Enemy Cards")
	for value in enemy_cards:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = Dictionary(value)
		var behavior_tags: Array = enemy.get("behavior_tags", [])
		var intent_names: Array = enemy.get("intent_names", [])
		lines.append("[Enemy Card] %s | HP %d | %s | Aggro %d%% | Bluff %d%%" % [
			enemy.get("name", "Enemy"),
			enemy.get("max_hp", 0),
			enemy.get("role", "Enemy"),
			enemy.get("aggression", 0),
			enemy.get("bluff_chance", 0)
		])
		lines.append("Tags: %s | Intents: %s" % [
			_join_text_array(behavior_tags, "None"),
			_join_text_array(intent_names, "Unknown")
		])
		lines.append("Tell: %s" % enemy.get("tell", "No tell recorded."))
		lines.append("Counter: %s" % enemy.get("counterplay", "Read intent before committing."))
	return "\n".join(lines)


func _get_approach_rule_text(entry: Dictionary) -> String:
	return "Map: %s\n%s\nTable Rule Card: %s\nEffect: %s" % [
		entry.get("tactical_map_name", "Crossfire Table"),
		entry.get("tactical_map_summary", "Use cover, center control, and long angles."),
		entry.get("table_modifier_name", "House Rules"),
		entry.get("table_modifier_summary", "No special rule is active.")
	]


func _get_approach_stakes_text(entry: Dictionary) -> String:
	var tags: Array = entry.get("reward_tag_names", [])
	return "Reward Stakes\n%s\nFavored reward gaps: %s" % [
		entry.get("reward_stakes", "Clear the table to improve the run."),
		_join_text_array(tags, "Run clear")
	]


func _join_text_array(values: Array, fallback: String) -> String:
	var parts := PackedStringArray()
	for value in values:
		var text: String = String(value)
		if not text.is_empty():
			parts.append(text)
	if parts.is_empty():
		return fallback
	return ", ".join(parts)


func _get_next_table_name_after_reward(state: Dictionary) -> String:
	var node_count := int(state.get("current_node_count", 0))
	var next_index := int(state.get("current_node_index", 0)) + 2
	if next_index > node_count:
		return "run results"
	return "%s (Table %d/%d)" % [
		state.get("next_node_name_after_reward", "Next Table"),
		next_index,
		node_count
	]


func _refresh_run_header(state: Dictionary, evaluation: Dictionary) -> void:
	if run_header_label == null:
		return

	var node_index := int(state.get("current_node_index", 0)) + 1
	var node_count := int(state.get("current_node_count", 0))
	var clamped_index: int = min(node_index, node_count)
	var rating := String(evaluation.get("rating", "unknown"))
	run_header_label.modulate = _get_balance_band_color(rating)
	run_header_label.clear()
	run_header_label.append_text("%s | Table %d/%d | %s\n" % [
		_get_balance_band_label(rating),
		clamped_index,
		node_count,
		state.get("current_node_name", "Complete")
	])
	run_header_label.append_text("Blood %d/%d | Deck %d | Run %s" % [
		state.get("player_hp", 0),
		state.get("player_max_hp", 0),
		state.get("deck_size", 0),
		state.get("run_outcome", "running")
	])


func _refresh_run_path(state: Dictionary) -> void:
	if run_path_label == null:
		return

	run_path_label.clear()
	var path_entries: Array = state.get("run_path", [])
	if path_entries.is_empty():
		run_path_label.append_text("Run Map\nNo route loaded.")
		if run_path_preview_label != null:
			run_path_preview_label.clear()
			run_path_preview_label.append_text("Select a table once the route loads.")
		return

	var node_count: int = int(state.get("current_node_count", path_entries.size()))
	var cleared_count: int = int(state.get("combats_won", _count_path_status(path_entries, "cleared")))
	var current_index: int = clampi(int(state.get("current_node_index", 0)), 0, max(0, path_entries.size() - 1))
	var marker_moved: bool = last_run_path_current_index != -1 and last_run_path_current_index != current_index
	if selected_run_path_index < 0 or selected_run_path_index >= path_entries.size() or marker_moved:
		selected_run_path_index = current_index
	if marker_moved:
		_play_run_path_marker_transition(last_run_path_current_index, current_index, path_entries)
	last_run_path_current_index = current_index

	if run_flow_state == RUN_FLOW_START:
		selected_run_path_index = current_index
		run_path_label.append_text("Route 1/%d | Opening Table is ready\n" % node_count)
		run_path_label.append_text("Deal In now. Clear tables to reveal rewards and move the marker.")
		if run_path_buttons_row != null:
			run_path_buttons_row.visible = true
			_refresh_opening_route_buttons(path_entries, current_index)
		if run_path_preview_label != null:
			run_path_preview_label.visible = false
			run_path_preview_label.clear()
		return

	if run_path_buttons_row != null:
		run_path_buttons_row.visible = true
	if run_path_preview_label != null:
		run_path_preview_label.visible = true

	var segments := PackedStringArray()
	for value in path_entries:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(value)
		segments.append("[%s] %d. %s (%s)" % [
			entry.get("status_label", "UPCOMING"),
			entry.get("table_number", 0),
			entry.get("name", "Table"),
			String(entry.get("kind", "combat")).capitalize()
		])

	run_path_label.append_text("Run Map | %d/%d cleared\n" % [
		cleared_count,
		node_count
	])
	run_path_label.append_text(" -> ".join(segments))
	run_path_label.append_text("\n%s" % _get_run_map_caption(state))
	_refresh_run_path_buttons(path_entries)
	_refresh_run_path_preview(path_entries)


func _refresh_opening_route_buttons(path_entries: Array, current_index: int) -> void:
	for index in range(run_path_buttons.size()):
		var button: Button = run_path_buttons[index]
		if index >= path_entries.size() or typeof(path_entries[index]) != TYPE_DICTIONARY:
			button.visible = false
			button.disabled = true
			continue

		var entry: Dictionary = Dictionary(path_entries[index])
		var active := index == current_index
		button.visible = true
		button.disabled = false
		button.custom_minimum_size = Vector2(0, 54)
		button.add_theme_font_size_override("font_size", 13 if active else 12)
		button.self_modulate = Color.WHITE if active else Color(0.82, 0.86, 0.94, 0.76)
		button.text = "Table %d\n%s\n%s" % [
			entry.get("table_number", index + 1),
			entry.get("name", "Table"),
			"READY" if active else "LOCKED"
		]
		var tooltip := "Click to Deal In." if active else "Clear earlier tables to unlock this stop."
		var palette := [FEEDBACK_CARD_COLOR, FEEDBACK_MOVE_COLOR, FEEDBACK_REVEAL_COLOR, FEEDBACK_PHASE_COLOR, FEEDBACK_DAMAGE_COLOR]
		var color: Color = FEEDBACK_CARD_COLOR if active else palette[index % palette.size()]
		_style_compact_button(button, true, color, tooltip)


func _refresh_run_path_buttons(path_entries: Array) -> void:
	for index in range(run_path_buttons.size()):
		var button: Button = run_path_buttons[index]
		if index >= path_entries.size() or typeof(path_entries[index]) != TYPE_DICTIONARY:
			button.visible = false
			button.disabled = true
			continue

		var entry: Dictionary = Dictionary(path_entries[index])
		var status: String = String(entry.get("status", "upcoming"))
		var status_label: String = String(entry.get("status_label", "UPCOMING"))
		var selected: bool = index == selected_run_path_index
		var prefix: String = ">> " if status == "current" else ""
		var suffix: String = " <<" if status == "current" else ""
		if selected and status != "current":
			prefix = "* "
			suffix = " *"

		button.visible = true
		button.disabled = false
		var color := _get_run_path_button_color(status, selected)
		button.self_modulate = Color.WHITE
		_style_compact_button(button, selected or status == "current" or status == "next" or status == "reward", color, _get_run_path_button_tooltip(entry))
		button.text = "%sTable %d\n%s\n%s%s" % [
			prefix,
			entry.get("table_number", index + 1),
			entry.get("name", "Table"),
			status_label,
			suffix
		]


func _refresh_run_path_preview(path_entries: Array) -> void:
	if run_path_preview_label == null:
		return

	run_path_preview_label.clear()
	if selected_run_path_index < 0 or selected_run_path_index >= path_entries.size():
		run_path_preview_label.append_text("Select a table to preview its enemies, rule, and reward stakes.")
		return
	if typeof(path_entries[selected_run_path_index]) != TYPE_DICTIONARY:
		run_path_preview_label.append_text("Selected table preview unavailable.")
		return

	var entry: Dictionary = Dictionary(path_entries[selected_run_path_index])
	var enemies: Array = entry.get("enemy_names", [])
	var enemy_text: String = "unknown opposition" if enemies.is_empty() else ", ".join(enemies)
	var tags: Array = entry.get("reward_tag_names", [])
	var tag_text: String = "Run clear" if tags.is_empty() else ", ".join(tags)
	run_path_preview_label.append_text("Selected Table %d: %s [%s] - %s\n" % [
		entry.get("table_number", selected_run_path_index + 1),
		entry.get("name", "Table"),
		String(entry.get("kind", "combat")).capitalize(),
		entry.get("status_label", "UPCOMING")
	])
	run_path_preview_label.append_text("Enemies: %s | Rule: %s - %s\n" % [
		enemy_text,
		entry.get("table_modifier_name", "House Rules"),
		entry.get("table_modifier_summary", "No special rule is active.")
	])
	run_path_preview_label.append_text("Map: %s - %s\n" % [
		entry.get("tactical_map_name", "Crossfire Table"),
		entry.get("tactical_map_summary", "Use cover, center control, and long angles.")
	])
	run_path_preview_label.append_text("Stakes: %s | Reward tags: %s" % [
		entry.get("reward_stakes", "Clear the table to improve the run."),
		tag_text
	])
	if not last_run_path_transition_text.is_empty():
		run_path_preview_label.append_text("\n%s" % last_run_path_transition_text)


func _play_run_path_marker_transition(previous_index: int, current_index: int, path_entries: Array) -> void:
	var previous_name: String = _get_run_path_entry_name(path_entries, previous_index)
	var current_name: String = _get_run_path_entry_name(path_entries, current_index)
	last_run_path_transition_text = "Last route move: %s -> %s." % [previous_name, current_name]
	if previous_index >= 0 and previous_index < run_path_buttons.size():
		_pulse_canvas_item(run_path_buttons[previous_index], Color(0.72, 0.90, 1.0))
	if current_index >= 0 and current_index < run_path_buttons.size():
		_pulse_canvas_item(run_path_buttons[current_index], Color(1.0, 0.88, 0.36))
	if run_path_preview_label != null:
		_pulse_canvas_item(run_path_preview_label, Color(1.0, 0.88, 0.36))


func _get_run_path_entry_name(path_entries: Array, index: int) -> String:
	if index < 0 or index >= path_entries.size() or typeof(path_entries[index]) != TYPE_DICTIONARY:
		return "Table"
	var entry: Dictionary = Dictionary(path_entries[index])
	return String(entry.get("name", "Table"))


func _get_run_path_button_color(status: String, selected: bool) -> Color:
	if selected:
		return Color(1.0, 0.92, 0.48)
	match status:
		"cleared":
			return Color(0.58, 1.0, 0.68)
		"current":
			return Color(1.0, 0.82, 0.30)
		"reward":
			return Color(1.0, 0.74, 0.44)
		"next":
			return Color(0.58, 0.86, 1.0)
		"lost":
			return Color(1.0, 0.45, 0.40)
		_:
			return Color(0.80, 0.84, 0.90)


func _get_run_path_button_tooltip(entry: Dictionary) -> String:
	var enemies: Array = entry.get("enemy_names", [])
	var enemy_text: String = "unknown opposition" if enemies.is_empty() else ", ".join(enemies)
	return "%s\nEnemies: %s\nMap: %s\nRule: %s" % [
		entry.get("encounter_intro", "Read the table before combat starts."),
		enemy_text,
		entry.get("tactical_map_name", "Crossfire Table"),
		entry.get("table_modifier_name", "House Rules")
	]


func _count_path_status(path_entries: Array, status: String) -> int:
	var count := 0
	for value in path_entries:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(value)
		if String(entry.get("status", "")) == status:
			count += 1
	return count


func _get_run_map_caption(state: Dictionary) -> String:
	var node_count: int = int(state.get("current_node_count", 0))
	var current_index: int = mini(int(state.get("current_node_index", 0)) + 1, node_count)
	match run_flow_state:
		RUN_FLOW_START:
			return "Current marker: %s. %d upcoming tables are visible." % [
				state.get("current_node_name", "Opening Table"),
				max(0, node_count - 1)
			]
		RUN_FLOW_COMBAT:
			return "Marker is on Table %d/%d while %s is live." % [
				current_index,
				node_count,
				state.get("current_node_name", "Encounter")
			]
		RUN_FLOW_REWARD:
			return "Marker holds on %s for rewards; %s is marked NEXT." % [
				state.get("last_completed_node_name", "Table"),
				state.get("next_node_name_after_reward", "Next Table")
			]
		RUN_FLOW_NEXT_ENCOUNTER:
			return "Reward resolved. The marker has moved to %s; Open Next Table to enter combat." % state.get("current_node_name", "Encounter")
		RUN_FLOW_RESULTS:
			var results: Dictionary = state.get("run_results", {})
			return "Route complete: %s." % results.get("grade", "Table Stakes")
		_:
			return "Route marker is waiting for the next run state."


func _refresh_reward_prompt(state: Dictionary, card_rewards: Array, relic_rewards: Array) -> void:
	if reward_prompt_label == null:
		return

	var waiting_for_reward := bool(state.get("waiting_for_reward", false))
	reward_prompt_label.visible = waiting_for_reward
	reward_prompt_label.clear()
	if not waiting_for_reward:
		return

	reward_prompt_label.append_text("Reward choice: take one card to fill a deck gap, or skip to keep it lean.\n")
	if not card_rewards.is_empty() and typeof(card_rewards[0]) == TYPE_DICTIONARY:
		var best_card: Dictionary = card_rewards[0]
		reward_prompt_label.append_text("Best card: %s -> %s\n" % [
			best_card.get("name", "Card"),
			best_card.get("explanation", "Solid reward option.")
		])
		reward_prompt_label.append_text("Deck impact: %s" % best_card.get("impact_summary", "Impact unavailable."))
	else:
		reward_prompt_label.append_text("No card reward is pending.")

	if not relic_rewards.is_empty():
		reward_prompt_label.append_text("\nElite relic pending after the card pick.")


func _refresh_reward_impact(state: Dictionary, card_rewards: Array, relic_rewards: Array) -> void:
	if reward_impact_label == null:
		return

	var waiting_for_reward := bool(state.get("waiting_for_reward", false))
	reward_impact_label.visible = waiting_for_reward
	reward_impact_label.clear()
	if not waiting_for_reward:
		var last_decision: Dictionary = state.get("last_reward_decision", {})
		var show_last_decision := not last_decision.is_empty() and run_flow_state == RUN_FLOW_NEXT_ENCOUNTER
		reward_impact_label.visible = show_last_decision
		if show_last_decision:
			reward_impact_label.append_text("Last reward change\n")
			reward_impact_label.append_text("%s | %s\n" % [
				last_decision.get("summary", last_decision.get("name", "Reward")),
				last_decision.get("deck_change", "Deck change unavailable.")
			])
			reward_impact_label.append_text("Before: %s\n" % last_decision.get("before_deck_snapshot", "Deck snapshot unavailable."))
			reward_impact_label.append_text("After: %s" % last_decision.get("after_deck_snapshot", "Deck snapshot unavailable."))
		return

	reward_impact_label.append_text("Before/after deck impact\n")
	reward_impact_label.append_text("Current deck: %d cards | Reward stakes: %s\n" % [
		state.get("deck_size", 0),
		state.get("reward_stakes", "Improve the run.")
	])
	if not card_rewards.is_empty() and typeof(card_rewards[0]) == TYPE_DICTIONARY:
		var best_card: Dictionary = card_rewards[0]
		reward_impact_label.append_text("Best pick: %s | Score %.1f\n" % [
			best_card.get("name", "Card"),
			float(best_card.get("score", 0.0))
		])
		reward_impact_label.append_text("Impact: %s\n" % best_card.get("impact_summary", "Impact unavailable."))
		reward_impact_label.append_text("Reasons: %s" % _join_reward_reasons(best_card.get("top_reasons", [])))
	else:
		reward_impact_label.append_text("No card impact pending.")

	if not relic_rewards.is_empty():
		reward_impact_label.append_text("\nRelic pick follows the card choice.")


func _get_card_reward_button_text(reward: Dictionary, index: int) -> String:
	var rank_label: String = String(reward.get("recommendation_label", "Option %d" % (index + 1)))
	if index == 0:
		rank_label = "#1 Recommended"
	return "%s\nTake %s\n%s" % [
		rank_label,
		reward.get("name", "Card"),
		reward.get("text", "")
	]


func _get_card_reward_tooltip_text(reward: Dictionary, index: int) -> String:
	var rank_label: String = String(reward.get("recommendation_label", "Option %d" % (index + 1)))
	if index == 0:
		rank_label = "#1 Recommended"
	return "%s | Reasons: %s | Impact: %s" % [
		rank_label,
		_join_reward_reasons(reward.get("top_reasons", [])),
		reward.get("impact_summary", "Impact unavailable.")
	]


func _join_reward_reasons(reasons: Array) -> String:
	var clean_reasons: Array[String] = []
	for reason in reasons:
		var text := String(reason)
		if not text.is_empty():
			clean_reasons.append(text)
	if clean_reasons.is_empty():
		return "solid deck fit"
	return ", ".join(clean_reasons)


func _build_threat_summary(previews: Array[Dictionary]) -> String:
	if previews.is_empty():
		return "Table Read\nThreat: no active enemy previews.\nResponse: advance to read the table."

	var best_preview: Dictionary = {}
	var best_option: Dictionary = {}
	var best_score := -1
	for preview in previews:
		var options: Array = preview.get("options", [])
		var option: Dictionary = _get_top_intent_option(options)
		if option.is_empty():
			continue
		var score: int = _get_intent_threat_score(option)
		if score > best_score:
			best_score = score
			best_preview = preview
			best_option = option

	if best_option.is_empty():
		return "Threat: no weighted intent options.\nResponse: press Continue to roll a fresh read."

	return "Table Read\nThreat: %s %s %d%% %s\nResponse: %s" % [
		best_preview.get("enemy_name", "Enemy"),
		_get_threat_level(best_option),
		best_option.get("percentage", 0),
		best_option.get("intent_name", "Intent"),
		_get_threat_response(best_option)
	]


func _build_intent_icon_strip(previews: Array[Dictionary]) -> String:
	if previews.is_empty():
		return "Intent Icons | Opponent Cards\n[?] No active enemy reads."

	var lines: Array[String] = ["Intent Icons | Opponent Cards"]
	for preview in previews:
		var options: Array = preview.get("options", [])
		var top_option: Dictionary = _get_top_intent_option(options)
		if top_option.is_empty():
			lines.append("[?] %s no weighted read" % preview.get("enemy_name", "Enemy"))
			continue
		lines.append("%s %s | %s %d%% | %s" % [
			_get_intent_icon_marker(top_option),
			preview.get("enemy_name", "Enemy"),
			_get_threat_level(top_option),
			top_option.get("percentage", 0),
			_get_lane_preview_text(top_option)
		])
	return "\n".join(lines)


func _get_intent_icon_marker(option: Dictionary) -> String:
	match int(option.get("intent_type", -1)):
		0:
			return "[ATK]"
		1:
			return "[GRD]"
		2:
			return "[MOV]"
		3:
			return "[FNT]"
		4:
			return "[BUF]"
		5:
			return "[DEB]"
		6:
			return "[SUM]"
		7:
			return "[TRP]"
		_:
			return "[?]"


func _get_lane_preview_text(option: Dictionary) -> String:
	var target_lane: int = int(option.get("target_lane", -1))
	if target_lane >= 0:
		return "%s lane" % _get_lane_name(target_lane)
	return "tracking"


func _get_top_intent_option(options: Array) -> Dictionary:
	var best_option: Dictionary = {}
	var best_score := -1
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option
		var score: int = _get_intent_threat_score(option_data)
		if score > best_score:
			best_score = score
			best_option = option_data
	return best_option


func _get_intent_threat_score(option: Dictionary) -> int:
	var percentage := int(option.get("percentage", 0))
	var intent_type := int(option.get("intent_type", -1))
	var target_lane := int(option.get("target_lane", -1))
	var score := percentage
	if intent_type == INTENT_TYPE_ATTACK:
		score += 35
		if target_lane < 0:
			score += 10
	return score


func _get_threat_level(option: Dictionary) -> String:
	if option.is_empty():
		return "LOW"

	var percentage := int(option.get("percentage", 0))
	var intent_type := int(option.get("intent_type", -1))
	if intent_type == INTENT_TYPE_ATTACK and percentage >= 40:
		return "HIGH"
	if intent_type == INTENT_TYPE_ATTACK:
		return "MED"
	if percentage >= 45:
		return "SETUP"
	return "LOW"


func _get_threat_response(option: Dictionary) -> String:
	if option.is_empty():
		return "keep reading before committing."

	var intent_type := int(option.get("intent_type", -1))
	var target_lane := int(option.get("target_lane", -1))
	if intent_type != INTENT_TYPE_ATTACK:
		return "use the safer turn to attack, trap, or build Guard."
	if target_lane >= 0:
		return "leave %s, add Guard, or call it." % _get_lane_name(target_lane)
	return "Guard or call it; movement will not dodge tracking."


func _get_balance_band_label(rating: String) -> String:
	match rating:
		"danger":
			return "!!! DANGER !!!"
		"close":
			return "CLOSE - tense"
		"favorable":
			return "FAVORABLE - stable"
		_:
			return "BALANCE UNKNOWN"


func _get_balance_band_color(rating: String) -> Color:
	match rating:
		"danger":
			return Color(1.0, 0.45, 0.35)
		"close":
			return Color(1.0, 0.84, 0.35)
		"favorable":
			return Color(0.55, 1.0, 0.6)
		_:
			return Color(1.0, 1.0, 1.0)


func _refresh_targeting_options() -> void:
	if target_enemy_option == null or movement_cell_option == null or combat_resolver == null or combat_grid == null:
		return

	var selected_enemy_id: StringName = _get_selected_enemy_target_id()
	target_enemy_option.clear()
	var targets: Array = combat_resolver.call("get_alive_enemy_targets")
	for target in targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		var target_label := "Target: %s HP %d/%d" % [
			target.get("name", "Enemy"),
			target.get("hp", 0),
			target.get("max_hp", 0)
		]
		target_enemy_option.add_item(target_label)
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
		movement_cell_option.add_item("Route: %s" % combat_grid.call("format_cell", cell))
		movement_cell_option.set_item_metadata(movement_cell_option.item_count - 1, cell)
		if cell == selected_cell:
			movement_cell_option.select(movement_cell_option.item_count - 1)

	if movement_cell_option.item_count == 0:
		movement_cell_option.add_item("No legal move")
		movement_cell_option.set_item_metadata(0, Vector2i(-1, -1))
	elif movement_cell_option.selected < 0:
		movement_cell_option.select(0)
	_refresh_card_action_hint()
	_refresh_card_target_preview()
	_sync_target_focus()
	_refresh_loadout_ui()
	_refresh_enemy_target_cards(combat_resolver.call("get_state"))


func _sync_target_focus() -> void:
	if combat_grid == null or not combat_grid.has_method("set_focus_unit"):
		return

	if run_flow_state != RUN_FLOW_COMBAT or combat_session == null:
		combat_grid.call("clear_focus")
		return

	var session_state: Dictionary = combat_session.call("get_state")
	if bool(session_state.get("combat_over", false)):
		combat_grid.call("clear_focus")
		return

	var previewed_card: Resource = deck_manager.call("get_card_at", previewed_hand_index) if deck_manager != null and previewed_hand_index >= 0 else null
	if previewed_card != null:
		if _is_grid_cell_card(previewed_card):
			combat_grid.call("set_focus_cell", _get_selected_move_cell())
			return
		if int(previewed_card.get("target_type")) == 1:
			combat_grid.call("set_focus_unit", &"player")
			return
		if _is_attack_or_read_card(previewed_card):
			combat_grid.call("set_focus_unit", _get_selected_enemy_target_id())
			return

	var selected_enemy_id: StringName = _get_selected_enemy_target_id()
	if not selected_enemy_id.is_empty():
		combat_grid.call("set_focus_unit", selected_enemy_id)
	else:
		combat_grid.call("clear_focus")


func _build_card_context(card: Resource) -> Dictionary:
	var target_enemy: Dictionary = _get_selected_enemy_target()
	var target_cell: Vector2i = _get_selected_move_cell()
	var player_context: Dictionary = combat_grid.call("get_player_context")
	var map_context: Dictionary = combat_grid.call("get_map_context", target_cell) if combat_grid.has_method("get_map_context") else {}
	var target_enemy_id: StringName = StringName(target_enemy.get("id", &""))
	var target_enemy_name: String = String(target_enemy.get("name", "Enemy"))
	var context := {
		"target_enemy_id": target_enemy_id,
		"target_enemy_name": target_enemy_name,
		"target_cell": target_cell,
		"target_cell_label": combat_grid.call("format_cell", target_cell),
		"player_lane": int(player_context.get("lane", -1)),
		"map_context": map_context,
		"card_id": card.get("id")
	}
	context.merge(_get_card_upgrade_context(card), true)
	return context


func _build_reveal_context(bluff_state: Dictionary) -> Dictionary:
	var player_context: Dictionary = combat_grid.call("get_player_context")
	var resolver_state: Dictionary = combat_resolver.call("get_state")
	var map_context: Dictionary = combat_grid.call("get_map_context") if combat_grid.has_method("get_map_context") else {}
	return {
		"player_cell": player_context.get("cell", Vector2i(-1, -1)),
		"player_lane": int(player_context.get("lane", -1)),
		"unit_positions": combat_grid.call("get_unit_position_snapshot"),
		"active_trap_cells": resolver_state.get("trap_cells", []),
		"map_context": map_context,
		"bluff_state": bluff_state
	}


func _validate_card_context(card: Resource, context: Dictionary) -> bool:
	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		if target_enemy_id.is_empty() or not bool(combat_resolver.call("has_living_enemy", target_enemy_id)):
			_append_log("%s needs a living enemy target." % _get_card_name(card))
			_push_feedback("Blocked: pick a living Target enemy for %s." % _get_card_name(card), FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
			return false

	if _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		if not _is_valid_player_move_target(target_cell):
			_append_log("%s needs a legal adjacent move target." % _get_card_name(card))
			_push_feedback("Blocked: pick a legal Move cell for %s." % _get_card_name(card), FEEDBACK_DAMAGE_COLOR, hand_action_status_label)
			return false

	return true


func _resolve_movement_card(card: Resource, context: Dictionary) -> bool:
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	if not _is_valid_player_move_target(target_cell):
		_append_log("%s fizzles because the move target is no longer legal." % _get_card_name(card))
		return false

	if bool(combat_grid.call("move_unit", &"player", target_cell)):
		context["movement_resolved"] = true
		_append_log("%s moves the Gambler-Knight to %s." % [
			_get_card_name(card),
			combat_grid.call("format_cell", target_cell)
		])
		return true

	return false


func _apply_card_side_effects(card: Resource, context: Dictionary = {}) -> void:
	var card_id: StringName = StringName(card.get("id"))
	var card_name := _get_card_name(card)
	match card_id:
		&"hook_step":
			combat_resolver.call("apply_follow_up_damage", 2, "%s follow-up" % card_name, context)
			_play_unit_burst(StringName(context.get("target_enemy_id", &"")), FEEDBACK_DAMAGE_COLOR, &"blood")
		&"blood_ritual":
			bluff_system.call("gain_nerve", 2, card_name)
		&"marked_card":
			bluff_system.call("gain_nerve", 1, card_name)
		&"second_wind":
			bluff_system.call("gain_nerve", 1, card_name)
		&"shadow_step":
			combat_resolver.call("add_player_guard", 2, card_name)
	var upgrade_guard := int(context.get("upgrade_guard_bonus", 0))
	if _is_movement_card(card) and upgrade_guard > 0:
		combat_resolver.call("add_player_guard", upgrade_guard, "%s armory guard" % card_name)
	if String(context.get("upgrade_mutation", "")) == "Wager":
		bluff_system.call("gain_nerve", 1, "%s wager mutation" % card_name)


func _apply_enemy_grid_moves(revealed: Array) -> void:
	if combat_grid == null:
		return

	var moved_any := false
	for entry in revealed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_data: Dictionary = Dictionary(entry)
		var payload: Dictionary = entry_data.get("payload", {})
		if not payload.has("move"):
			continue

		var enemy_id: StringName = StringName(entry_data.get("enemy_id", &""))
		if enemy_id.is_empty() or not bool(combat_resolver.call("has_living_enemy", enemy_id)):
			continue

		var move_cells: Array = combat_grid.call("get_empty_adjacent_cells_for", enemy_id)
		if move_cells.is_empty():
			_append_log("%s tries to reposition, but the table has no open adjacent cell." % entry_data.get("enemy_name", "Enemy"))
			continue

		var destination: Vector2i = _pick_enemy_reposition_cell(enemy_id, move_cells)
		if bool(combat_grid.call("move_unit", enemy_id, destination)):
			moved_any = true
			_append_log("%s repositions to %s." % [
				entry_data.get("enemy_name", "Enemy"),
				combat_grid.call("format_cell", destination)
			])
			_play_unit_or_cell_burst(enemy_id, destination, FEEDBACK_MOVE_COLOR, &"move")

	if moved_any:
		_refresh_targeting_options()


func _pick_enemy_reposition_cell(enemy_id: StringName, move_cells: Array) -> Vector2i:
	var player_cell: Vector2i = combat_grid.call("get_unit_position", &"player")
	var origin: Vector2i = combat_grid.call("get_unit_position", enemy_id)
	var best_cell: Vector2i = move_cells[0]
	var best_score := -9999
	for value in move_cells:
		if typeof(value) != TYPE_VECTOR2I:
			continue
		var candidate: Vector2i = value
		var distance_from_player: int = abs(candidate.x - player_cell.x) + abs(candidate.y - player_cell.y)
		var forward_bias: int = origin.y - candidate.y
		var score: int = distance_from_player * 10 + forward_bias
		if score > best_score:
			best_score = score
			best_cell = candidate
	return best_cell


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
	var run_state: Dictionary = run_manager.call("get_state") if run_manager != null else {}

	if run_flow_state == RUN_FLOW_START:
		phase_guidance_label.text = "Run Start"
		phase_detail_label.text = "Press Deal In when you are ready to sit at the first table."
	elif run_flow_state == RUN_FLOW_REWARD:
		phase_guidance_label.text = "Choose Reward"
		phase_detail_label.text = "Pick a card, then claim a relic if one is pending."
	elif run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		phase_guidance_label.text = "Next Table"
		phase_detail_label.text = "Review the upcoming encounter, then deal the next table."
	elif run_flow_state == RUN_FLOW_RESULTS:
		phase_guidance_label.text = "Run Results"
		phase_detail_label.text = "Review the run, export a summary, or start a new run."
	elif bool(state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			phase_guidance_label.text = "Choose Reward"
			phase_detail_label.text = "Pick one reward to advance to the next table."
		elif String(run_state.get("run_outcome", "running")) == "victory":
			phase_guidance_label.text = "Run Complete"
			phase_detail_label.text = "The prototype path is cleared."
		else:
			phase_guidance_label.text = "Combat Complete"
			phase_detail_label.text = "Outcome: %s. Start a new run when ready." % state.get("outcome", "unknown")
	else:
		phase_guidance_label.text = String(guidance.get("title", "Turn"))
		phase_detail_label.text = String(guidance.get("detail", "Continue the combat loop."))

	if action_prompt_label != null:
		action_prompt_label.text = _get_action_prompt(state, run_state)
	if first_play_path_label != null:
		_refresh_first_play_path(state, run_state)

	_refresh_recipe_label()


func _get_action_prompt(session_state: Dictionary, run_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "Next: Deal In. Then pick Target, play a card, and Resolve Turn."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Next: choose one reward; the next table starts when rewards are clear."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Next: open the next table when you are ready to continue the run."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Next: export the run summary or start a new run."

	if bool(session_state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			return "Next: choose one reward and move to the next table."
		var run_outcome := String(run_state.get("run_outcome", "running"))
		if run_outcome == "victory":
			return "Next: review the run result or start a new run."
		if run_outcome == "defeat":
			return "Next: review the loss, export a summary, or start a new run."
		return "Next: start the next combat."

	var phase_key := String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"START_TURN":
			return "Next: begin turn; draw and intent read will auto-complete."
		"DRAW":
			return "Next: finish draw/read setup and start planning."
		"ENEMY_INTENT_PREVIEW":
			return "Next: start planning with the current target and move preview."
		"PLAYER_COMMIT":
			return "Next: pick Target or Move, click a ready card, then Resolve Turn."
		"BLUFF_WAGER":
			return "Next: call, raise, or fold; Reveal Turn resolves the plan."
		"REVEAL":
			return "Next: reveal resolves into the review step automatically."
		"RESOLVE":
			return "Next: press Next Turn to cleanup, draw, read, and return to planning."
		"CLEANUP":
			return "Next: cleanup rolls into the next planning state."
		_:
			return "Next: continue the combat loop."


func _refresh_first_play_path(session_state: Dictionary, run_state: Dictionary) -> void:
	if first_play_path_label == null:
		return

	first_play_path_label.clear()
	first_play_path_label.append_text("First Play Path | ACTIVE: %s\n" % _get_first_play_active_step(session_state, run_state))
	first_play_path_label.append_text("1 Deal In -> 2 Pick Target -> 3 Play Card -> 4 Resolve Turn")
	_refresh_first_play_coach()


func _reset_first_play_coach() -> void:
	first_play_coach_steps = {
		"open": false,
		"target": false,
		"card": false,
		"resolve": false
	}
	first_play_coach_complete = false
	if first_play_coach_panel != null:
		first_play_coach_panel.modulate = Color.WHITE
		first_play_coach_panel.visible = true
	_refresh_first_play_coach()


func _record_first_play_step(step_id: String) -> void:
	if first_play_coach_complete or not _is_first_table_coach_active():
		return
	if not first_play_coach_steps.has(step_id):
		return

	if bool(first_play_coach_steps.get(step_id, false)):
		_refresh_first_play_coach()
		return

	first_play_coach_steps[step_id] = true
	_refresh_first_play_coach()
	if first_play_coach_panel != null:
		_pulse_canvas_item(first_play_coach_panel, FEEDBACK_CARD_COLOR)
	if _is_first_play_coach_ready_to_complete():
		_complete_first_play_coach()


func _refresh_first_play_coach() -> void:
	if first_play_coach_panel == null or first_play_coach_label == null:
		return

	var should_show := _is_first_table_coach_active() and not first_play_coach_complete
	first_play_coach_panel.visible = should_show
	if not should_show:
		return

	first_play_coach_label.text = "Coach: %s -> %s -> %s -> %s" % [
		_get_first_play_coach_step_text("open", "DEAL"),
		_get_first_play_coach_step_text("target", "TARGET"),
		_get_first_play_coach_step_text("card", "CARD"),
		_get_first_play_coach_step_text("resolve", "RESOLVE")
	]
	first_play_coach_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))


func _get_first_play_coach_step_text(step_id: String, label: String) -> String:
	return "%s OK" % label if bool(first_play_coach_steps.get(step_id, false)) else label


func _is_first_play_coach_ready_to_complete() -> bool:
	return (
		bool(first_play_coach_steps.get("open", false))
		and bool(first_play_coach_steps.get("target", false))
		and bool(first_play_coach_steps.get("card", false))
		and bool(first_play_coach_steps.get("resolve", false))
	)


func _complete_first_play_coach() -> void:
	first_play_coach_complete = true
	if first_play_coach_label != null:
		first_play_coach_label.text = "Coach complete: you can read the table from here."
	if first_play_coach_panel == null:
		return

	first_play_coach_panel.visible = true
	first_play_coach_panel.modulate = Color(1.0, 0.92, 0.62)
	var tween := create_tween()
	tween.tween_interval(0.45)
	tween.tween_property(first_play_coach_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if first_play_coach_panel != null:
			first_play_coach_panel.visible = false
			first_play_coach_panel.modulate = Color.WHITE
	)


func _is_first_table_coach_active() -> bool:
	if run_flow_state == RUN_FLOW_RESULTS:
		return false
	if run_manager == null:
		return true
	var state: Dictionary = run_manager.call("get_state")
	return int(state.get("current_node_index", 0)) == 0


func _get_first_play_active_step(session_state: Dictionary, run_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "1 Deal In"
	if run_flow_state == RUN_FLOW_REWARD:
		return "Reward Choice"
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Open Next Table"
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Run Results"
	if bool(session_state.get("combat_over", false)):
		return "Reward or Results"

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"START_TURN", "DRAW", "ENEMY_INTENT_PREVIEW":
			return "Begin Turn"
		"PLAYER_COMMIT":
			return "2 Pick Target -> 3 Play Card"
		"BLUFF_WAGER", "REVEAL":
			return "4 Reveal Turn"
		"RESOLVE", "CLEANUP":
			return "4 Resolve Turn"
		_:
			return "Continue"


func _refresh_compact_play_state(run_state: Dictionary) -> void:
	if live_state_chip_row == null or combat_session == null:
		return

	var session_state: Dictionary = combat_session.call("get_state")
	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	var phase_text: String = phase_key.capitalize().replace("_", " ")
	var phase_active := run_flow_state == RUN_FLOW_COMBAT
	phase_state_chip.text = "PHASE %s" % _shorten_chip_text(phase_text, 14)
	_style_compact_button(phase_state_chip, phase_active, FEEDBACK_PHASE_COLOR, _get_turn_state_feedback(session_state, run_state))

	energy_state_chip.text = "ENERGY %d/%d" % [
		session_state.get("energy", 0),
		session_state.get("max_energy", 0)
	]
	_style_compact_button(
		energy_state_chip,
		phase_key == "PLAYER_COMMIT" and int(session_state.get("energy", 0)) > 0,
		FEEDBACK_CARD_COLOR,
		"Energy pays for card clicks during Player Commit."
	)

	target_state_chip.text = _get_target_chip_text()
	_style_compact_button(target_state_chip, phase_key == "PLAYER_COMMIT", FEEDBACK_DAMAGE_COLOR, "Attack and read cards use this enemy target.")

	move_state_chip.text = _get_move_chip_text()
	_style_compact_button(move_state_chip, phase_key == "PLAYER_COMMIT", FEEDBACK_MOVE_COLOR, "Movement and trap cards use this table cell.")

	var threat_chip: Dictionary = _get_threat_chip_snapshot()
	threat_state_chip.text = String(threat_chip.get("text", "THREAT ?"))
	_style_compact_button(
		threat_state_chip,
		phase_active,
		threat_chip.get("color", Color(0.80, 0.80, 0.82)),
		String(threat_chip.get("tooltip", "No enemy read yet."))
	)

	rule_state_chip.text = _get_rule_chip_text(run_state)
	_style_compact_button(rule_state_chip, phase_active, Color(0.78, 0.62, 0.30), _get_rule_chip_tooltip(run_state, session_state))
	_refresh_first_play_step_buttons(session_state, run_state)
	_sync_live_text_density()


func _refresh_first_play_step_buttons(session_state: Dictionary, run_state: Dictionary) -> void:
	if first_play_step_buttons.size() < 4:
		return

	var active_indices: Array[int] = _get_active_first_play_step_indices(session_state, run_state)
	var labels := ["1 Deal", "2 Target", "3 Card", "4 Resolve"]
	var tooltips := [
		"Deal into the current table.",
		"Pick the enemy target or move cell.",
		"Click a ready hand card.",
		"Resolve Turn advances the plan."
	]
	for index in range(first_play_step_buttons.size()):
		var button := first_play_step_buttons[index]
		var active := active_indices.has(index)
		button.text = labels[index]
		var tooltip_prefix := "Active step: " if active else "Step: "
		_style_compact_button(button, active, FEEDBACK_CARD_COLOR, "%s%s" % [tooltip_prefix, tooltips[index]])


func _get_active_first_play_step_indices(session_state: Dictionary, _run_state: Dictionary) -> Array[int]:
	if run_flow_state == RUN_FLOW_START:
		return [0]
	if run_flow_state == RUN_FLOW_REWARD or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER or run_flow_state == RUN_FLOW_RESULTS:
		return []
	if bool(session_state.get("combat_over", false)):
		return []

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"PLAYER_COMMIT":
			return [1, 2]
		"BLUFF_WAGER", "REVEAL", "RESOLVE", "CLEANUP":
			return [3]
		_:
			return [0]


func _sync_live_text_density() -> void:
	var compact_live := run_flow_state == RUN_FLOW_COMBAT and not debug_controls_visible
	var payout_stage := run_flow_state == RUN_FLOW_COMBAT and arena_payout_pending
	var title_plate := find_child("TitlePlaque", true, false)
	if title_plate is Control:
		(title_plate as Control).visible = not compact_live
	if run_header_label != null:
		run_header_label.visible = not compact_live and run_flow_state != RUN_FLOW_START
	var body := find_child("CombatBody", true, false)
	if body is Control:
		(body as Control).visible = run_flow_state == RUN_FLOW_COMBAT
	var deck_panel_node := find_child("DeckPanel", true, false)
	if deck_panel_node is Control:
		(deck_panel_node as Control).visible = run_flow_state == RUN_FLOW_COMBAT and not payout_stage
	var start_class_panel := find_child("StartHeroClassPanel", true, false)
	if start_class_panel is Control:
		(start_class_panel as Control).visible = run_flow_state == RUN_FLOW_START
	if pile_counts_label != null:
		pile_counts_label.visible = not compact_live
	var run_path_panel := find_child("RunPathPanel", true, false)
	if run_path_panel is Control:
		(run_path_panel as Control).visible = not compact_live and run_flow_state != RUN_FLOW_REWARD
	var route_decision_shell := run_flow_state == RUN_FLOW_REWARD or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER or run_flow_state == RUN_FLOW_RESULTS
	var compact_reward := run_flow_state == RUN_FLOW_REWARD and not debug_controls_visible
	var show_expanded_combat_detail := run_flow_state == RUN_FLOW_COMBAT and not compact_live
	for panel_name in ["TurnGuidance", "TurnStatusPanel", "TableRulePanel", "CombatFeedbackPanel"]:
		var panel := find_child(panel_name, true, false)
		if panel is Control:
			(panel as Control).visible = not route_decision_shell
	var target_controls_panel := find_child("TargetControlsPanel", true, false)
	if target_controls_panel is Control:
		(target_controls_panel as Control).visible = not compact_live
	if run_shell_panel != null:
		var show_shell_in_live := run_ceremony_panel != null and bool(run_ceremony_panel.get("visible"))
		run_shell_panel.visible = not compact_live or show_shell_in_live
	if run_shell_title_label != null:
		run_shell_title_label.visible = not compact_live
	var run_shell_actions := find_child("RunShellActions", true, false)
	if run_shell_actions is Control:
		(run_shell_actions as Control).visible = not compact_live
	if action_cue_panel != null:
		action_cue_panel.visible = not compact_live and not route_decision_shell and run_flow_state != RUN_FLOW_START
		action_cue_panel.custom_minimum_size = Vector2(0, 62) if compact_live else Vector2(0, 72)
	if combat_grid != null and combat_grid.has_method("set_compact_mode"):
		combat_grid.call("set_compact_mode", compact_live)
	_sync_compact_live_layout(compact_live)
	if toggle_debug_button != null:
		toggle_debug_button.visible = run_flow_state == RUN_FLOW_COMBAT or debug_controls_visible
	if live_state_chip_row != null:
		live_state_chip_row.visible = show_expanded_combat_detail
	if first_play_step_row != null:
		first_play_step_row.visible = run_flow_state == RUN_FLOW_COMBAT and not compact_live
	if first_play_coach_panel != null:
		first_play_coach_panel.visible = run_flow_state == RUN_FLOW_COMBAT and _is_first_table_coach_active() and not first_play_coach_complete and not compact_live
	_sync_reward_panel_priority(compact_reward)
	if run_shell_detail_label != null:
		run_shell_detail_label.visible = not compact_live and not compact_reward
	if run_continuity_label != null:
		run_continuity_label.visible = not compact_live and not compact_reward
	if encounter_preview_label != null and compact_live:
		encounter_preview_label.visible = false
	var turn_status_panel := find_child("TurnStatusPanel", true, false)
	if turn_status_panel is Control:
		(turn_status_panel as Control).visible = show_expanded_combat_detail
	var table_rule_panel := find_child("TableRulePanel", true, false)
	if table_rule_panel is Control:
		(table_rule_panel as Control).visible = show_expanded_combat_detail
	var turn_guidance_panel := find_child("TurnGuidance", true, false)
	if turn_guidance_panel is Control:
		(turn_guidance_panel as Control).visible = show_expanded_combat_detail
	var combat_feedback_panel := find_child("CombatFeedbackPanel", true, false)
	if combat_feedback_panel is Control:
		(combat_feedback_panel as Control).visible = show_expanded_combat_detail
	if phase_guidance_label != null:
		phase_guidance_label.visible = show_expanded_combat_detail
	if phase_detail_label != null:
		phase_detail_label.visible = show_expanded_combat_detail
	if action_prompt_label != null:
		action_prompt_label.visible = show_expanded_combat_detail
	if first_play_path_label != null:
		first_play_path_label.visible = show_expanded_combat_detail
	if turn_status_label != null:
		turn_status_label.visible = show_expanded_combat_detail
	if table_rule_status_label != null:
		table_rule_status_label.visible = show_expanded_combat_detail
	if enemy_status_label != null:
		enemy_status_label.visible = show_expanded_combat_detail
	if intent_icon_strip_label != null:
		intent_icon_strip_label.visible = show_expanded_combat_detail
	if threat_summary_label != null:
		threat_summary_label.visible = show_expanded_combat_detail
	var bluff_title := find_child("BluffTitle", true, false)
	if bluff_title is Control:
		(bluff_title as Control).visible = show_expanded_combat_detail
	if intent_preview_label != null:
		intent_preview_label.visible = show_expanded_combat_detail
	if bluff_state_label != null:
		bluff_state_label.visible = show_expanded_combat_detail
	if enemy_call_option != null:
		enemy_call_option.visible = show_expanded_combat_detail
	if intent_call_option != null:
		intent_call_option.visible = show_expanded_combat_detail
	if lane_call_option != null:
		lane_call_option.visible = show_expanded_combat_detail
	if commit_first_card_button != null and commit_first_card_button.get_parent() is Control:
		(commit_first_card_button.get_parent() as Control).visible = show_expanded_combat_detail
	if reset_bluff_button != null:
		reset_bluff_button.visible = show_expanded_combat_detail
	if card_action_hint_label != null:
		card_action_hint_label.visible = show_expanded_combat_detail
	if card_target_preview_label != null:
		card_target_preview_label.visible = show_expanded_combat_detail
	if shooter_economy_label != null:
		shooter_economy_label.visible = run_flow_state == RUN_FLOW_COMBAT
	if arena_payout_panel != null:
		arena_payout_panel.visible = payout_stage
	var table_row := find_child("TableRow", true, false)
	if table_row is Control:
		(table_row as Control).visible = run_flow_state == RUN_FLOW_COMBAT and not payout_stage
	if loadout_slot_row != null:
		loadout_slot_row.visible = run_flow_state == RUN_FLOW_COMBAT and not payout_stage
	if hand_action_button_row != null:
		hand_action_button_row.visible = run_flow_state == RUN_FLOW_COMBAT and not payout_stage
	if combat_feedback_label != null:
		combat_feedback_label.visible = show_expanded_combat_detail


func _sync_compact_live_layout(compact_live: bool) -> void:
	var body := find_child("CombatBody", true, false)
	if body is Control:
		(body as Control).custom_minimum_size = Vector2(0, 0)
		if body is BoxContainer:
			(body as BoxContainer).add_theme_constant_override("separation", 4 if compact_live else 8)

	var table_row := find_child("TableRow", true, false)
	if table_row is Control:
		(table_row as Control).custom_minimum_size = Vector2(0, 440) if compact_live else Vector2(0, 430)

	var opponent_panel := find_child("OpponentCardsPanel", true, false)
	if opponent_panel is Control:
		(opponent_panel as Control).custom_minimum_size = Vector2(280, 0) if compact_live else Vector2(320, 0)

	if hand_action_status_label != null:
		hand_action_status_label.custom_minimum_size = Vector2(0, 30) if compact_live else Vector2(0, 28)
		hand_action_status_label.add_theme_font_size_override("font_size", 16 if compact_live else 15)

	if hand_view != null and hand_view.has_method("set_compact_mode"):
		hand_view.call("set_compact_mode", compact_live)

	var hand_scroll := find_child("HandScroll", true, false)
	if hand_scroll is Control:
		(hand_scroll as Control).custom_minimum_size = Vector2(0, 188) if compact_live else Vector2(0, 196)


func _sync_reward_panel_priority(compact_reward: bool) -> void:
	var layout_node := find_child("Layout", true, false)
	var run_panel_node := find_child("RunPanel", true, false)
	if not (layout_node is BoxContainer) or run_panel_node == null:
		return

	var layout_box := layout_node as BoxContainer
	var run_shell_node := find_child("RunShellPanel", true, false)
	if compact_reward and run_shell_node != null and run_shell_node.get_parent() == layout_box:
		layout_box.move_child(run_panel_node, run_shell_node.get_index())
		return

	var debug_drawer_node := find_child("DebugDrawer", true, false)
	if debug_drawer_node != null and debug_drawer_node.get_parent() == layout_box:
		layout_box.move_child(run_panel_node, max(0, debug_drawer_node.get_index() - 1))


func _get_target_chip_text() -> String:
	var target: Dictionary = _get_selected_enemy_target()
	if target.is_empty():
		return "TARGET --"
	return "TARGET %s" % _shorten_chip_text(String(target.get("name", "Enemy")), 14)


func _get_move_chip_text() -> String:
	var target_cell: Vector2i = _get_selected_move_cell()
	if target_cell == Vector2i(-1, -1) or combat_grid == null:
		return "MOVE --"
	return "MOVE %s" % combat_grid.call("format_cell", target_cell)


func _get_threat_chip_snapshot() -> Dictionary:
	if current_intent_previews.is_empty():
		return {
			"text": "THREAT ?",
			"tooltip": "No enemy read yet.",
			"color": Color(0.80, 0.80, 0.82)
		}

	var best_preview: Dictionary = {}
	var best_option: Dictionary = {}
	var best_score := -1
	for preview in current_intent_previews:
		var options: Array = preview.get("options", [])
		var option: Dictionary = _get_top_intent_option(options)
		var score := _get_intent_threat_score(option)
		if score > best_score:
			best_score = score
			best_preview = preview
			best_option = option

	if best_option.is_empty():
		return {
			"text": "THREAT LOW",
			"tooltip": "No weighted enemy read.",
			"color": Color(0.55, 0.85, 0.62)
		}

	var level := _get_threat_level(best_option)
	return {
		"text": "THREAT %s" % level,
		"tooltip": "%s: %s %d%%. %s" % [
			best_preview.get("enemy_name", "Enemy"),
			best_option.get("intent_name", "Intent"),
			best_option.get("percentage", 0),
			_get_threat_response(best_option)
		],
		"color": _get_threat_chip_color(level)
	}


func _get_threat_chip_color(level: String) -> Color:
	match level:
		"HIGH":
			return Color(1.0, 0.38, 0.26)
		"MED":
			return Color(1.0, 0.70, 0.32)
		"SETUP":
			return Color(0.72, 0.58, 1.0)
		_:
			return Color(0.55, 0.85, 0.62)


func _get_rule_chip_text(run_state: Dictionary) -> String:
	var table_modifier: Dictionary = run_state.get("table_modifier", {})
	var modifier_name := String(table_modifier.get("name", "Rule"))
	if modifier_name.is_empty():
		modifier_name = "Rule"
	return "RULE %s" % _shorten_chip_text(modifier_name, 15)


func _get_rule_chip_tooltip(run_state: Dictionary, session_state: Dictionary) -> String:
	var table_modifier: Dictionary = run_state.get("table_modifier", {})
	var modifier_name := String(table_modifier.get("name", "Table Rule"))
	var modifier_summary := String(table_modifier.get("summary", "No special rule is active."))
	var active_text := _get_table_rule_active_effect_text(run_state.get("table_modifiers", {}), session_state)
	return "%s: %s Active: %s" % [modifier_name, modifier_summary, active_text]


func _shorten_chip_text(value: String, max_length: int) -> String:
	if value.length() <= max_length:
		return value
	return "%s..." % value.substr(0, max(0, max_length - 3))


func _refresh_turn_status(run_state: Dictionary) -> void:
	if turn_status_label == null or combat_session == null:
		return

	var session_state: Dictionary = combat_session.call("get_state")
	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	var phase_name: String = phase_key.capitalize().replace("_", " ")
	var turn_number: int = int(turn_manager.get("turn_number")) if turn_manager != null else 0
	var rating: String = _get_run_balance_rating(run_state)
	turn_status_label.clear()
	turn_status_label.append_text("Turn %d | %s | Energy %d/%d | Balance: %s\n" % [
		turn_number,
		phase_name,
		session_state.get("energy", 0),
		session_state.get("max_energy", 0),
		_get_balance_band_label(rating)
	])
	turn_status_label.append_text(_get_turn_state_feedback(session_state, run_state))


func _refresh_table_rule_status(run_state: Dictionary) -> void:
	if table_rule_status_label == null:
		return

	var table_modifier: Dictionary = run_state.get("table_modifier", {})
	var modifier_name: String = String(table_modifier.get("name", "No table rule"))
	var modifier_summary: String = String(table_modifier.get("summary", "No special rule is active."))
	var table_modifiers: Dictionary = run_state.get("table_modifiers", {})
	var session_state: Dictionary = combat_session.call("get_state") if combat_session != null else {}

	table_rule_status_label.clear()
	table_rule_status_label.append_text("Table Rule: %s\n" % modifier_name)
	table_rule_status_label.append_text("%s\n" % modifier_summary)
	table_rule_status_label.append_text("Active: %s" % _get_table_rule_active_effect_text(table_modifiers, session_state))
	if not table_rule_effect_history.is_empty():
		table_rule_status_label.append_text("\nTriggered: %s" % table_rule_effect_history[0])


func _get_table_rule_active_effect_text(table_modifiers: Dictionary, session_state: Dictionary) -> String:
	if table_modifiers.is_empty():
		return "no active modifier payload"

	var parts: Array[String] = []
	var current_max_energy: int = int(session_state.get("max_energy", int(combat_session.get("max_energy")) if combat_session != null else 0))
	var current_hand_target: int = int(session_state.get("hand_target", int(combat_session.get("hand_target")) if combat_session != null else 0))
	var current_starting_nerve: int = int(bluff_system.get("starting_nerve")) if bluff_system != null else 0
	if table_modifiers.has("starting_guard"):
		parts.append("%d opening Guard" % int(table_modifiers.get("starting_guard", 0)))
	if table_modifiers.has("max_energy_bonus"):
		parts.append("%s max Energy -> %d" % [
			_format_signed_number(int(table_modifiers.get("max_energy_bonus", 0))),
			current_max_energy
		])
	if table_modifiers.has("hand_target_bonus"):
		parts.append("%s hand size -> %d" % [
			_format_signed_number(int(table_modifiers.get("hand_target_bonus", 0))),
			current_hand_target
		])
	if table_modifiers.has("starting_nerve_bonus"):
		parts.append("%s starting Nerve -> %d" % [
			_format_signed_number(int(table_modifiers.get("starting_nerve_bonus", 0))),
			current_starting_nerve
		])

	if parts.is_empty():
		return "rule has no setup effect"
	return ", ".join(parts)


func _get_turn_state_feedback(session_state: Dictionary, run_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "State: Deal In is live. Combat buttons and card clicks wait until the table opens."
	if run_flow_state == RUN_FLOW_REWARD:
		return "State: rewards are live. Pick the card that closes the shown deck gap."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "State: next table preview is live. Deal the table to resume combat."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "State: run results are live. Export the summary or start a new run."

	if bool(session_state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			return "State: combat won. Rewards are the next real action."
		return "State: combat ended. Review Blood, enemy HP, and run outcome."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"START_TURN":
			return "State: ready to begin. One press draws, reads intent, and opens planning."
		"DRAW":
			return "State: drawing is automatic in the main play flow."
		"ENEMY_INTENT_PREVIEW":
			return "State: intent read is ready; planning opens next."
		"PLAYER_COMMIT":
			return "State: planning is live and cards are playable. Spend Energy, then Resolve Turn."
		"BLUFF_WAGER":
			return "State: bluff choices are live. Reveal Turn runs the payoff."
		"REVEAL":
			return "State: reveal is resolving into review."
		"RESOLVE":
			return "State: review aftermath. Next Turn cleans up and returns to planning."
		"CLEANUP":
			return "State: cleanup is automatic in the main play flow."
		_:
			return "State: continue the combat loop."


func _get_run_balance_rating(run_state: Dictionary) -> String:
	var balance: Dictionary = run_state.get("balance_snapshot", {})
	var evaluation: Dictionary = balance.get("evaluation", {})
	return String(evaluation.get("rating", "unknown"))


func _refresh_enemy_status(state: Dictionary) -> void:
	if enemy_status_label == null:
		return

	enemy_status_label.clear()
	var player: Dictionary = state.get("player", {})
	enemy_status_label.append_text("Opponent Cards | Blood %d/%d | Guard %d\n" % [
		player.get("hp", 0),
		player.get("max_hp", 0),
		player.get("guard", 0)
	])

	var enemies: Array = state.get("enemies", [])
	if enemies.is_empty():
		enemy_status_label.append_text("Enemies: none active.")
		return

	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		var enemy_id: StringName = StringName(enemy_data.get("id", &""))
		enemy_status_label.append_text("[Enemy Card] %s | HP %d/%d | Guard %d | %s\n  Threat: %s\n" % [
			enemy_data.get("name", "Enemy"),
			enemy_data.get("hp", 0),
			enemy_data.get("max_hp", 0),
			enemy_data.get("guard", 0),
			_get_enemy_hp_status(enemy_data),
			_get_enemy_read_text(enemy_id)
		])
	_refresh_enemy_target_cards(state)


func _refresh_enemy_target_cards(state: Dictionary) -> void:
	if enemy_target_cards_row == null:
		return

	for child in enemy_target_cards_row.get_children():
		child.queue_free()
	enemy_target_card_buttons.clear()

	var show_live_targets := run_flow_state == RUN_FLOW_COMBAT and not bool(state.get("combat_over", false))
	enemy_target_cards_row.visible = show_live_targets
	if not show_live_targets:
		return

	var enemies: Array = state.get("enemies", [])
	if enemies.is_empty():
		var empty_label := Label.new()
		empty_label.name = "EnemyTargetCardsEmpty"
		empty_label.text = "No targets"
		enemy_target_cards_row.add_child(empty_label)
		return

	var selected_enemy_id := _get_selected_enemy_target_id()
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		if not bool(enemy_data.get("alive", false)):
			continue

		var enemy_id := StringName(enemy_data.get("id", &""))
		var button := Button.new()
		button.name = "EnemyTargetCard%d" % enemy_target_card_buttons.size()
		button.set_meta("enemy_id", enemy_id)
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(140, 112)
		button.text = _get_enemy_target_card_text(enemy_data, enemy_id == selected_enemy_id)
		button.tooltip_text = "%s is an enemy %s. Click to make your next attack/read card aim at this combatant." % [
			enemy_data.get("name", "Enemy"),
			_get_enemy_battle_role(enemy_data)
		]
		button.pressed.connect(_on_enemy_target_card_pressed.bind(enemy_id))
		button.button_down.connect(_on_enemy_target_card_button_down.bind(enemy_id, button))
		button.mouse_entered.connect(_on_enemy_target_card_hovered.bind(enemy_id, button))
		button.mouse_exited.connect(_on_enemy_target_card_unhovered.bind(enemy_id))
		_style_enemy_target_card_button(button, enemy_data, enemy_id == selected_enemy_id)
		enemy_target_cards_row.add_child(button)
		enemy_target_card_buttons.append(button)


func _get_enemy_target_card_text(enemy: Dictionary, active: bool) -> String:
	var enemy_id := StringName(enemy.get("id", &""))
	var prefix := "CURRENT TARGET" if active else "CLICK TO AIM"
	return "%s\n%s\n%s\nHP %d/%d\nPlan: %s\n%s" % [
		prefix,
		enemy.get("name", "Enemy"),
		_get_enemy_battle_role(enemy),
		enemy.get("hp", 0),
		enemy.get("max_hp", 0),
		_get_enemy_intent_line(enemy_id),
		_get_enemy_target_reason(enemy)
	]


func _get_enemy_battle_role(enemy: Dictionary) -> String:
	var enemy_id := StringName(enemy.get("id", &""))
	match enemy_id:
		&"skulker":
			return "Knife Duelist"
		&"shieldbearer":
			return "Shield Guard"
		&"brute":
			return "Brute Enforcer"
		&"needle_eye":
			return "Backline Sniper"
		&"hexmonger":
			return "Hex Caster"
		&"grave_dealer":
			return "Elite Cardsharp"
		&"house_champion":
			return "Boss Champion"

	var role_text := String(enemy.get("role", "")).strip_edges()
	if role_text.is_empty():
		return "Enemy Fighter"
	return role_text


func _get_enemy_target_reason(enemy: Dictionary) -> String:
	var enemy_id := StringName(enemy.get("id", &""))
	match enemy_id:
		&"skulker":
			return "Fighter: quick attacker"
		&"shieldbearer":
			return "Fighter: protects allies"
		&"brute":
			return "Fighter: heavy hitter"
		&"needle_eye":
			return "Fighter: lane sniper"
		&"hexmonger":
			return "Fighter: curse caster"
		&"grave_dealer":
			return "Fighter: elite cardsharp"
		&"house_champion":
			return "Fighter: boss"

	var hp_status := _get_enemy_hp_status(enemy).to_lower()
	return "Fighter: %s target" % hp_status


func _get_enemy_intent_line(enemy_id: StringName) -> String:
	var preview: Dictionary = _get_intent_preview_for_enemy(enemy_id)
	if preview.is_empty():
		return "intent hidden"

	var options: Array = preview.get("options", [])
	var top_option: Dictionary = _get_top_intent_option(options)
	if top_option.is_empty():
		return "intent unknown"

	return "%s %d%%" % [
		top_option.get("intent_name", "Intent"),
		top_option.get("percentage", 0)
	]


func _style_enemy_target_card_button(button: Button, enemy: Dictionary, active: bool) -> void:
	var enemy_id := StringName(enemy.get("id", &""))
	var preview: Dictionary = _get_intent_preview_for_enemy(enemy_id)
	var top_option: Dictionary = _get_top_intent_option(preview.get("options", []))
	var threat_level := _get_threat_level(top_option) if not top_option.is_empty() else "LOW"
	var threat_color := _get_threat_chip_color(threat_level)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 4 if active else 2
	style.border_width_top = 4 if active else 2
	style.border_width_right = 4 if active else 2
	style.border_width_bottom = 4 if active else 2
	style.bg_color = Color(0.18, 0.10, 0.075, 0.96).lerp(threat_color, 0.12 if active else 0.06)
	style.border_color = Color(1.0, 0.82, 0.28) if active else threat_color
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate()
	hover_style.bg_color = style.bg_color.lightened(0.08)
	hover_style.border_color = Color(1.0, 0.86, 0.36)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.74) if active else Color(0.94, 0.88, 0.78))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))


func _get_enemy_hp_status(enemy: Dictionary) -> String:
	if not bool(enemy.get("alive", false)):
		return "DEFEATED"

	var hp: int = int(enemy.get("hp", 0))
	var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
	var hp_ratio: float = float(hp) / float(max_hp)
	if hp_ratio <= 0.25:
		return "FINISH"
	if hp_ratio <= 0.5:
		return "WOUNDED"
	return "HEALTHY"


func _get_enemy_read_text(enemy_id: StringName) -> String:
	var preview: Dictionary = _get_intent_preview_for_enemy(enemy_id)
	if preview.is_empty():
		return "pending"

	var options: Array = preview.get("options", [])
	var top_option: Dictionary = _get_top_intent_option(options)
	if top_option.is_empty():
		return "no weighted read"

	return "%s %d%% %s" % [
		_get_threat_level(top_option),
		top_option.get("percentage", 0),
		top_option.get("intent_name", "Intent")
	]


func _get_intent_preview_for_enemy(enemy_id: StringName) -> Dictionary:
	for preview in current_intent_previews:
		if StringName(preview.get("enemy_id", &"")) == enemy_id:
			return preview
	return {}


func _refresh_card_action_hint() -> void:
	if card_action_hint_label == null:
		return

	var session_state: Dictionary = combat_session.call("get_state") if combat_session != null else {}
	var counts: Dictionary = deck_manager.call("get_counts") if deck_manager != null else {}
	card_action_hint_label.clear()
	card_action_hint_label.append_text("Hand %d | Chips %d | Energy %d/%d | Target: %s | Move: %s\n" % [
		counts.get("hand", 0),
		shooter_chips,
		session_state.get("energy", 0),
		session_state.get("max_energy", 0),
		_get_target_affordance_text(),
		_get_move_affordance_text()
	])
	card_action_hint_label.append_text("%s\nSelected card can Slot, Burn for Chips, Hold, or Play." % _get_card_affordance_text(session_state))


func _sync_hand_card_interaction() -> void:
	if hand_view == null or deck_manager == null:
		return
	if not hand_view.has_method("set_card_playability"):
		return

	var session_state: Dictionary = combat_session.call("get_state") if combat_session != null else {}
	var entries: Array[Dictionary] = []
	for index in range(hand_view.get_child_count()):
		var card: Resource = deck_manager.call("get_card_at", index)
		entries.append(_get_card_playability_entry(card, session_state))
	hand_view.call("set_card_playability", entries)
	_refresh_hand_action_status(entries, session_state)
	_refresh_loadout_ui()


func _refresh_hand_action_status(entries: Array[Dictionary], session_state: Dictionary) -> void:
	if hand_action_status_label == null:
		return

	var global_reason := _get_global_card_lock_reason(session_state)
	if not global_reason.is_empty():
		if run_flow_state == RUN_FLOW_START:
			hand_action_status_label.text = "NEXT: click Deal In. Cards unlock after the table is dealt."
		else:
			hand_action_status_label.text = "Cards locked: %s Next: %s" % [global_reason, _get_locked_cards_next_action(global_reason)]
		hand_action_status_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.68))
		return

	var ready_count := 0
	var blocked_reasons: Dictionary = {}
	for entry in entries:
		if bool(entry.get("playable", false)):
			ready_count += 1
			continue
		var reason := String(entry.get("reason", "Card is locked."))
		blocked_reasons[reason] = int(blocked_reasons.get(reason, 0)) + 1

	if ready_count > 0:
		var target := _get_selected_enemy_target()
		var target_name := String(target.get("name", "enemy")) if not target.is_empty() else "enemy"
		var target_role := _get_enemy_battle_role(target) if not target.is_empty() else "fighter"
		if _is_first_table_coach_active() and bool(first_play_coach_steps.get("card", false)) and not bool(first_play_coach_steps.get("resolve", false)):
			hand_action_status_label.text = "NEXT: click Resolve Turn. The enemy answers after your card."
		elif _is_first_table_coach_active() and not bool(first_play_coach_steps.get("target", false)):
			hand_action_status_label.text = "NEXT: TARGET who you attack: Skulker is a Knife Duelist, Shieldbearer is a Shield Guard. Then play a glowing card."
		elif _is_first_table_coach_active() and not bool(first_play_coach_steps.get("card", false)):
			hand_action_status_label.text = "NEXT: TARGET %s (%s). Play a glowing card, or click another enemy to switch." % [
				target_name,
				target_role
			]
		else:
			hand_action_status_label.text = "NEXT: TARGET %s. Play 1 of %d glowing card%s, or click another enemy/MOVE first." % [
				target_name,
				ready_count,
				"" if ready_count == 1 else "s"
			]
		hand_action_status_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		return

	var top_reason := "Pick a target or recover Energy."
	var top_count := 0
	for reason in blocked_reasons.keys():
		var count := int(blocked_reasons[reason])
		if count > top_count:
			top_count = count
			top_reason = String(reason)
	hand_action_status_label.text = "Blocked: %s Next: %s" % [top_reason, _get_blocked_cards_next_action(top_reason)]
	hand_action_status_label.add_theme_color_override("font_color", FEEDBACK_DAMAGE_COLOR)


func _get_locked_cards_next_action(reason: String) -> String:
	if reason.contains("Deal In"):
		return "press Deal In."
	if reason.contains("Choose rewards"):
		return "pick or skip a reward."
	if reason.contains("arena payout"):
		return "press Start Next Hand."
	if reason.contains("Open Next Table"):
		return "press Open Next Table."
	if reason.contains("Press Begin Turn"):
		return "press Begin Turn."
	return "follow the lit action button."


func _get_blocked_cards_next_action(reason: String) -> String:
	if reason.contains("Target enemy"):
		return "click an enemy target card."
	if reason.contains("Move cell"):
		return "click a legal table cell."
	if reason.contains("Energy"):
		return "press Resolve Turn."
	return "click target, then a lit card."


func _get_card_playability_entry(card: Resource, session_state: Dictionary) -> Dictionary:
	var global_reason: String = _get_global_card_lock_reason(session_state)
	if not global_reason.is_empty():
		return {"playable": false, "reason": global_reason}
	if card == null:
		return {"playable": false, "reason": "No card is in this hand slot."}

	var energy: int = int(session_state.get("energy", 0))
	var cost: int = _get_card_cost(card)
	if cost > energy:
		return {"playable": false, "reason": "Needs %d Energy; you have %d." % [cost, energy]}

	var context: Dictionary = _build_card_context(card)
	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		if target_enemy_id.is_empty() or not bool(combat_resolver.call("has_living_enemy", target_enemy_id)):
			return {"playable": false, "reason": "Pick a living Target enemy first."}
	if _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		if not _is_valid_player_move_target(target_cell):
			return {"playable": false, "reason": "Pick a legal Move cell first."}

	return {"playable": true, "reason": "Ready: click to play."}


func _get_global_card_lock_reason(session_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "Deal In first."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Choose rewards before playing more cards."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Open Next Table to deal a new hand."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "The run is over until New Run."
	if arena_payout_pending:
		return "Collect the arena payout first."
	if bool(session_state.get("combat_over", false)):
		return "Combat is over."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"PLAYER_COMMIT":
			return ""
		"START_TURN", "DRAW", "ENEMY_INTENT_PREVIEW":
			return "Press Begin Turn to unlock card play."
		"BLUFF_WAGER":
			return "Bluff choices are active; hand cards are locked."
		"REVEAL":
			return "Reveal is resolving; hand cards are locked."
		"RESOLVE", "CLEANUP":
			return "Press Next Turn to draw and return to planning."
		_:
			return "Card play is locked in this state."


func _get_target_affordance_text() -> String:
	if target_enemy_option == null:
		return "none"

	var target: Dictionary = _get_selected_enemy_target()
	if target.is_empty():
		return "none"
	return "%s HP %d/%d" % [
		target.get("name", "Enemy"),
		target.get("hp", 0),
		target.get("max_hp", 0)
	]


func _get_move_affordance_text() -> String:
	if movement_cell_option == null:
		return "none"

	var target_cell: Vector2i = _get_selected_move_cell()
	if target_cell == Vector2i(-1, -1):
		return "none"
	if combat_grid == null:
		return "(%d,%d)" % [target_cell.x, target_cell.y]
	return String(combat_grid.call("format_cell", target_cell))


func _get_card_affordance_text(session_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "Cards wait: press Deal In before committing actions."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Cards wait: choose rewards before the next table."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Cards wait: open the next table to draw the new opening hand."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Cards wait: the run is over until New Run."
	if bool(session_state.get("combat_over", false)):
		return "Cards wait: combat is over."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"PLAYER_COMMIT":
			return "Cards are playable now: Step 2 pick Target/Move, Step 3 click a ready card, Step 4 Resolve Turn."
		"BLUFF_WAGER":
			return "Hand is locked while bluff choices prepare the reveal."
		"REVEAL":
			return "Hand is locked during reveal; the play area resolves into review."
		"ENEMY_INTENT_PREVIEW":
			return "Target and Move are ready; planning opens automatically."
		_:
			return "Hand is visible for planning; Begin Turn opens card play."


func _refresh_card_target_preview() -> void:
	if card_target_preview_label == null:
		return

	card_target_preview_label.clear()
	if previewed_hand_index < 0:
		card_target_preview_label.append_text("Preview: hover a card to see target, expected effect, and grid focus.")
		_sync_target_focus()
		return

	var card: Resource = deck_manager.call("get_card_at", previewed_hand_index) if deck_manager != null else null
	if card == null:
		card_target_preview_label.append_text("Preview: no card at this hand slot.")
		_sync_target_focus()
		return

	var context: Dictionary = _build_card_context(card)
	card_target_preview_label.append_text("Preview: %s | Cost %d | %s\n" % [
		_get_card_name(card),
		_get_card_cost(card),
		_get_preview_card_type_label(card)
	])
	card_target_preview_label.append_text("Target: %s\n" % _get_card_preview_target_text(card, context))
	card_target_preview_label.append_text("Expected: %s\n" % _get_card_preview_effect_text(card, context))
	card_target_preview_label.append_text("FPS Bridge: %s\n" % _get_card_fps_bridge_text(card, context))
	card_target_preview_label.append_text("Table: %s" % _get_card_table_bridge_text(card, context))
	_preview_card_grid_focus(card, context)
	_sync_target_focus()


func _get_preview_card_type_label(card: Resource) -> String:
	var labels := [
		"Attack",
		"Defense",
		"Movement",
		"Bluff",
		"Read",
		"Trap",
		"Ritual"
	]
	var card_type: int = int(card.get("card_type"))
	if card_type >= 0 and card_type < labels.size():
		return labels[card_type]
	return "Card"


func _get_card_preview_target_text(card: Resource, context: Dictionary) -> String:
	var target_type: int = int(card.get("target_type"))
	match target_type:
		1:
			return "Gambler-Knight"
		2:
			var target: Dictionary = _get_selected_enemy_target()
			if target.is_empty():
				return "No living enemy selected"
			return "%s HP %d/%d" % [
				target.get("name", "Enemy"),
				target.get("hp", 0),
				target.get("max_hp", 0)
			]
		3:
			return String(context.get("target_cell_label", "No legal move"))
		4:
			var player_lane: int = int(context.get("player_lane", -1))
			return "Current lane: %s" % _get_lane_name(player_lane)
		5:
			return "Any unit"
		_:
			return "No target"


func _get_card_preview_effect_text(card: Resource, context: Dictionary) -> String:
	var card_id: StringName = StringName(card.get("id"))
	match card_id:
		&"quick_slash":
			return "Deal 4 damage to Target."
		&"low_stab":
			return "Deal 2 damage to Target."
		&"sure_cut":
			return "Deal 6 damage to Target."
		&"center_cut":
			var center_damage: int = 7 if int(context.get("player_lane", -1)) == 1 else 4
			return "Deal %d damage; best from Center lane." % center_damage
		&"house_edge":
			return "Deal 4 damage to Target and gain 3 Guard."
		&"all_in_cut":
			return "Deal 8 damage to Target."
		&"guard_up":
			return "Gain 5 Guard."
		&"iron_vow":
			return "Gain 8 Guard."
		&"bone_guard":
			return "Gain 5 Guard."
		&"black_shield":
			return "Gain 11 Guard."
		&"sidestep":
			return "Move to %s." % context.get("target_cell_label", "selected cell")
		&"hook_step":
			return "Move to %s and set up a follow-up." % context.get("target_cell_label", "selected cell")
		&"shadow_step":
			return "Move to %s and gain 2 Guard." % context.get("target_cell_label", "selected cell")
		&"read_tell":
			return "Sharpen the read on %s." % context.get("target_enemy_name", "the selected enemy")
		&"marked_card":
			return "Deal 2 damage and gain 1 Nerve."
		&"false_opening":
			return "Bait a call; Commit, Call, or Raise to cash it in."
		&"snare_card":
			return "Arm a trap at %s." % context.get("target_cell_label", "selected cell")
		&"tripwire":
			return "Arm a trap at %s." % context.get("target_cell_label", "selected cell")
		&"blood_ritual":
			return "Gain 2 Nerve for the wager engine."
		&"second_wind":
			return "Gain 5 Guard and 1 Nerve."
		_:
			return "Resolver effect not previewed yet."


func _get_card_fps_bridge_text(card: Resource, _context: Dictionary) -> String:
	var style := _get_card_vfx_style(card)
	var mode := _get_objective_mode_for_card(card)
	var objective := _get_objective_label(mode)
	var loadout_role := _get_card_bridge_role_label(card)
	var upgrade_summary := _get_card_upgrade_summary(card)
	match style:
		&"attack":
			return "%s becomes the arena weapon; best pressure is %s. %s" % [loadout_role, objective, upgrade_summary]
		&"move":
			return "%s becomes dash/route utility; it pushes %s and escape timing. %s" % [loadout_role, objective, upgrade_summary]
		&"guard":
			return "%s becomes armor/sustain; it stabilizes %s fights. %s" % [loadout_role, objective, upgrade_summary]
		&"read":
			return "%s becomes reveal/mark utility; it opens %s picks. %s" % [loadout_role, objective, upgrade_summary]
		&"trap":
			return "%s becomes snare/choke utility; it locks %s lanes. %s" % [loadout_role, objective, upgrade_summary]
		&"ritual":
			return "%s becomes overclock/wager tech; it spikes %s payout risk. %s" % [loadout_role, objective, upgrade_summary]
		&"bluff":
			return "%s becomes wager/passive economy; it bends %s rewards. %s" % [loadout_role, objective, upgrade_summary]
		_:
			return "%s exports into the FPS loadout for %s. %s" % [loadout_role, objective, upgrade_summary]


func _get_card_table_bridge_text(card: Resource, context: Dictionary) -> String:
	var map_context: Dictionary = context.get("map_context", {})
	var player_feature: Dictionary = map_context.get("player_feature", {})
	var target_feature: Dictionary = map_context.get("target_feature", {})
	var callouts: Array[String] = []
	var player_label := String(player_feature.get("short_label", ""))
	var target_label := String(target_feature.get("short_label", ""))
	if not player_label.is_empty():
		callouts.append("from %s" % player_label)
	if not target_label.is_empty() and target_label != player_label:
		callouts.append("to %s" % target_label)
	var bonus_text := _get_card_table_bonus_text(card, player_feature, target_feature)
	if callouts.is_empty():
		callouts.append("uses the active Crossfire callout")
	if not bonus_text.is_empty():
		callouts.append(bonus_text)
	return _join_string_array(callouts, " | ")


func _get_card_bridge_role_label(card: Resource) -> String:
	match _get_card_vfx_style(card):
		&"attack":
			return "Weapon slot"
		&"move":
			return "Mobility slot"
		&"guard":
			return "Armor slot"
		&"read":
			return "Intel slot"
		&"trap":
			return "Control slot"
		&"ritual":
			return "Wager slot"
		&"bluff":
			return "Passive slot"
		_:
			return "Flex slot"


func _get_card_table_bonus_text(card: Resource, player_feature: Dictionary, target_feature: Dictionary) -> String:
	var style := _get_card_vfx_style(card)
	if style == &"attack":
		var damage_bonus := int(player_feature.get("card_damage_bonus", 0))
		if damage_bonus > 0:
			return "+%d table damage from %s" % [damage_bonus, String(player_feature.get("label", "map"))]
	if style == &"guard":
		var cover_bonus := int(player_feature.get("incoming_damage_mitigation", 0))
		if cover_bonus > 0:
			return "%d lane mitigation from %s" % [cover_bonus, String(player_feature.get("label", "cover"))]
	if style == &"trap" and not target_feature.is_empty():
		return "trap pressure lands on %s" % String(target_feature.get("label", "target cell"))
	if style == &"move" and not target_feature.is_empty():
		return "route commits to %s" % String(target_feature.get("label", "move cell"))
	return ""


func _preview_card_grid_focus(card: Resource, context: Dictionary) -> void:
	if combat_grid == null:
		return

	var source := _get_hand_card_view(previewed_hand_index)
	var source_position := _get_canvas_item_global_center(source)
	var target_position := _get_card_vfx_target_position(card, context, source)
	if combat_vfx != null and source_position != Vector2.ZERO and target_position != Vector2.ZERO and combat_vfx.has_method("play_card_preview_arc"):
		combat_vfx.call("play_card_preview_arc", source_position, target_position, _get_card_vfx_color(card))

	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		if not target_enemy_id.is_empty():
			_flash_grid_unit(target_enemy_id, FEEDBACK_CARD_COLOR)
			_preview_arena_card_intent(card, context)
	elif _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		if target_cell != Vector2i(-1, -1) and combat_grid.has_method("flash_cell"):
			combat_grid.call("flash_cell", target_cell, FEEDBACK_CARD_COLOR)
			_preview_arena_card_intent(card, context)
	elif int(card.get("target_type")) == 1:
		_flash_grid_unit(&"player", FEEDBACK_CARD_COLOR)
		_preview_arena_card_intent(card, context)


func _preview_arena_card_intent(card: Resource, context: Dictionary) -> void:
	if arena_view == null or not arena_view.has_method("preview_card_intent"):
		return
	var style := _get_card_vfx_style(card)
	var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	var target_id := target_enemy_id
	if int(card.get("target_type")) == 1 or int(card.get("card_type")) == 6:
		target_id = &"player"
	arena_view.call("preview_card_intent", style, &"player", target_id, target_cell)


func _sync_arena_units() -> void:
	if arena_view == null or combat_grid == null:
		return
	if not arena_view.has_method("reset_units"):
		return

	var resolver_state: Dictionary = {}
	if combat_resolver != null:
		resolver_state = combat_resolver.call("get_state")
	arena_view.call("reset_units", combat_grid.call("get_unit_position_snapshot"), resolver_state)


func _sync_arena_combat_state(state: Dictionary) -> void:
	if arena_view == null or combat_grid == null:
		return
	if arena_view.has_method("sync_units"):
		arena_view.call("sync_units", combat_grid.call("get_unit_position_snapshot"))
	if arena_view.has_method("sync_combat_state"):
		arena_view.call("sync_combat_state", state)


func _play_arena_card_beat(card: Resource, context: Dictionary) -> void:
	if arena_view == null or not arena_view.has_method("play_card_beat"):
		return

	var style := _get_card_vfx_style(card)
	var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	var target_id := target_enemy_id
	if int(card.get("target_type")) == 1 or int(card.get("card_type")) == 6:
		target_id = &"player"
	arena_view.call("play_card_beat", style, &"player", target_id, target_cell)


func _play_card_commit_vfx(card: Resource, context: Dictionary, source: CanvasItem, face_down: bool) -> void:
	if combat_vfx == null:
		return

	var color := _get_card_vfx_color(card)
	var target_position := _get_card_vfx_target_position(card, context, source)
	var source_position := _get_canvas_item_global_center(source)
	if source_position == Vector2.ZERO:
		source_position = _get_canvas_item_global_center(card_action_hint_label)
	if target_position == Vector2.ZERO:
		target_position = source_position + Vector2(0, -82)

	if _is_live_canvas_item(source) and combat_vfx.has_method("play_card_burst_on"):
		combat_vfx.call("play_card_burst_on", source, color)
	if source_position != Vector2.ZERO and target_position != Vector2.ZERO and combat_vfx.has_method("play_card_fly_between"):
		combat_vfx.call("play_card_fly_between", source_position, target_position, color, _get_card_name(card), face_down)

	if face_down:
		_play_smoke_vfx(source if _is_live_canvas_item(source) else bluff_state_label)
		return

	if _card_exhausts(card):
		_play_card_burn_vfx(source if _is_live_canvas_item(source) else bluff_state_label)

	_play_arena_card_beat(card, context)

	match _get_card_vfx_style(card):
		&"attack":
			if target_position != Vector2.ZERO and source_position != Vector2.ZERO and combat_vfx.has_method("play_slash_between"):
				combat_vfx.call("play_slash_between", source_position, target_position, color)
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_burst_at"):
				combat_vfx.call("play_burst_at", target_position, color, &"blood")
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_target_lock_at"):
				combat_vfx.call("play_target_lock_at", target_position, color)
		&"guard":
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_guard_pulse_at"):
				combat_vfx.call("play_guard_pulse_at", target_position, color)
		&"move":
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_burst_at"):
				combat_vfx.call("play_burst_at", target_position, color, &"move")
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_ring_at"):
				combat_vfx.call("play_ring_at", target_position, color, 30.0)
		&"read":
			_play_intent_flicker_vfx(intent_preview_label, color)
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_ring_at"):
				combat_vfx.call("play_ring_at", target_position, color, 36.0)
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_target_lock_at"):
				combat_vfx.call("play_target_lock_at", target_position, color)
		&"trap":
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_burst_at"):
				combat_vfx.call("play_burst_at", target_position, color, &"smoke")
			if target_position != Vector2.ZERO and combat_vfx.has_method("play_ring_at"):
				combat_vfx.call("play_ring_at", target_position, color, 32.0)
		&"ritual":
			_play_ritual_vfx(source if _is_live_canvas_item(source) else bluff_state_label)
			_play_chip_vfx(bluff_state_label)
		&"bluff":
			_play_chip_vfx(bluff_state_label)


func _play_unit_burst(unit_id: StringName, color: Color, style: StringName) -> void:
	if combat_vfx == null or not combat_vfx.has_method("play_burst_at"):
		return

	var center := _get_unit_vfx_position(unit_id)
	if center == Vector2.ZERO:
		return
	combat_vfx.call("play_burst_at", center, color, style)


func _play_unit_or_cell_burst(unit_id: StringName, cell: Vector2i, color: Color, style: StringName) -> void:
	if combat_vfx == null or not combat_vfx.has_method("play_burst_at"):
		return

	var center := _get_unit_vfx_position(unit_id)
	if center == Vector2.ZERO:
		center = _get_cell_vfx_position(cell)
	if center != Vector2.ZERO:
		combat_vfx.call("play_burst_at", center, color, style)


func _play_guard_vfx(unit_id: StringName) -> void:
	if combat_vfx == null or not combat_vfx.has_method("play_guard_pulse_at"):
		return

	var center := _get_unit_vfx_position(unit_id)
	if center != Vector2.ZERO:
		combat_vfx.call("play_guard_pulse_at", center, FEEDBACK_GUARD_COLOR)


func _play_target_lock_vfx(unit_id: StringName, source: CanvasItem = null) -> void:
	if combat_vfx == null:
		return

	if source == null and arena_view != null and arena_view.has_method("focus_unit"):
		arena_view.call("focus_unit", unit_id)
	if _is_live_canvas_item(source) and combat_vfx.has_method("play_target_lock_on"):
		combat_vfx.call("play_target_lock_on", source, FEEDBACK_CARD_COLOR)

	var center := _get_unit_vfx_position(unit_id)
	if center != Vector2.ZERO and combat_vfx.has_method("play_target_lock_at"):
		combat_vfx.call("play_target_lock_at", center, FEEDBACK_CARD_COLOR)
	if center != Vector2.ZERO and _is_live_canvas_item(source) and combat_vfx.has_method("play_link_between_targets"):
		combat_vfx.call("play_link_between_targets", source, center, FEEDBACK_CARD_COLOR)


func _play_chip_vfx(target: CanvasItem) -> void:
	if combat_vfx != null and combat_vfx.has_method("play_chip_burst_on") and _is_live_canvas_item(target):
		combat_vfx.call("play_chip_burst_on", target)


func _play_smoke_vfx(target: CanvasItem) -> void:
	if combat_vfx != null and combat_vfx.has_method("play_curse_smoke_on") and _is_live_canvas_item(target):
		combat_vfx.call("play_curse_smoke_on", target)


func _play_ritual_vfx(target: CanvasItem) -> void:
	if combat_vfx != null and combat_vfx.has_method("play_ritual_glow_on") and _is_live_canvas_item(target):
		combat_vfx.call("play_ritual_glow_on", target)
	else:
		_play_smoke_vfx(target)


func _play_card_burn_vfx(target: CanvasItem) -> void:
	if combat_vfx != null and combat_vfx.has_method("play_card_burn_on") and _is_live_canvas_item(target):
		combat_vfx.call("play_card_burn_on", target)


func _play_intent_flicker_vfx(target: CanvasItem, color: Color) -> void:
	if combat_vfx != null and combat_vfx.has_method("play_intent_flicker_on") and _is_live_canvas_item(target):
		combat_vfx.call("play_intent_flicker_on", target, color)


func _get_card_vfx_target_position(card: Resource, context: Dictionary, fallback: CanvasItem) -> Vector2:
	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		return _get_unit_vfx_position(target_enemy_id)

	if _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		return _get_cell_vfx_position(target_cell)

	if int(card.get("target_type")) == 1 or int(card.get("card_type")) == 6:
		return _get_unit_vfx_position(&"player")

	return _get_canvas_item_global_center(fallback)


func _get_card_vfx_style(card: Resource) -> StringName:
	match int(card.get("card_type")):
		0:
			return &"attack"
		1:
			return &"guard"
		2:
			return &"move"
		3:
			return &"bluff"
		4:
			return &"read"
		5:
			return &"trap"
		6:
			return &"ritual"
		_:
			return &"card"


func _get_card_vfx_color(card: Resource) -> Color:
	match _get_card_vfx_style(card):
		&"attack":
			return FEEDBACK_DAMAGE_COLOR
		&"guard":
			return FEEDBACK_GUARD_COLOR
		&"move":
			return FEEDBACK_MOVE_COLOR
		&"read":
			return FEEDBACK_REVEAL_COLOR
		&"trap":
			return Color(0.74, 0.40, 0.86)
		&"ritual":
			return Color(0.92, 0.24, 0.20)
		&"bluff":
			return FEEDBACK_CARD_COLOR
		_:
			return FEEDBACK_CARD_COLOR


func _card_exhausts(card: Resource) -> bool:
	if card == null:
		return false
	var tags_value: Variant = card.get("tags")
	if typeof(tags_value) != TYPE_ARRAY:
		return false
	return (tags_value as Array).has(&"exhaust")


func _get_hand_card_view(hand_index: int) -> Control:
	if hand_view == null or hand_index < 0 or hand_index >= hand_view.get_child_count():
		return null

	var child := hand_view.get_child(hand_index)
	if child is Control:
		return child as Control
	return null


func _get_unit_vfx_position(unit_id: StringName) -> Vector2:
	if unit_id.is_empty() or combat_grid == null or not combat_grid.has_method("get_unit_global_center"):
		return Vector2.ZERO
	return combat_grid.call("get_unit_global_center", unit_id)


func _get_cell_vfx_position(cell: Vector2i) -> Vector2:
	if combat_grid == null or not combat_grid.has_method("get_cell_global_center"):
		return Vector2.ZERO
	return combat_grid.call("get_cell_global_center", cell)


func _get_canvas_item_global_center(item: CanvasItem) -> Vector2:
	if not _is_live_canvas_item(item):
		return Vector2.ZERO
	if item is Control:
		var control: Control = item
		return control.get_global_rect().get_center()
	return item.get_global_transform_with_canvas().origin


func _is_live_canvas_item(item: CanvasItem) -> bool:
	return item != null and is_instance_valid(item) and item.is_inside_tree()


func _reset_feedback_state() -> void:
	feedback_history.clear()
	table_rule_effect_history.clear()
	last_combat_feedback_state.clear()
	previewed_hand_index = -1
	if feedback_banner_label != null:
		feedback_banner_label.text = "Ready"
		feedback_banner_label.modulate = Color.WHITE
	if combat_feedback_label != null:
		combat_feedback_label.clear()
		combat_feedback_label.append_text("Feedback: phase changes, card plays, damage, Guard, movement, and reveals land here.")
	if card_target_preview_label != null:
		card_target_preview_label.clear()
		card_target_preview_label.append_text("Preview: hover a card to see target, expected effect, and grid focus.")


func _show_phase_feedback(phase_key: String) -> void:
	var phase_name: String = phase_key.capitalize().replace("_", " ")
	_push_feedback("Phase: %s." % phase_name, FEEDBACK_PHASE_COLOR, turn_status_label)


func _push_feedback(message: String, color: Color = Color.WHITE, pulse_node: Node = null) -> void:
	if message.is_empty():
		return

	feedback_history.push_front(message)
	while feedback_history.size() > 6:
		feedback_history.pop_back()

	if feedback_banner_label != null:
		feedback_banner_label.text = message
		_style_feedback_banner(color)
		_pulse_canvas_item(feedback_banner_label, color)

	if combat_feedback_label != null:
		_refresh_feedback_label()

	if pulse_node != null and pulse_node is CanvasItem:
		var item: CanvasItem = pulse_node as CanvasItem
		_pulse_canvas_item(item, color)


func _refresh_feedback_label() -> void:
	if combat_feedback_label == null:
		return

	combat_feedback_label.clear()
	combat_feedback_label.append_text("Feedback Beats\n")
	for message in feedback_history:
		combat_feedback_label.append_text("- %s\n" % message)


func _style_feedback_banner(color: Color) -> void:
	if feedback_banner_label == null:
		return

	feedback_banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	feedback_banner_label.add_theme_color_override("font_shadow_color", color.darkened(0.45))
	feedback_banner_label.add_theme_constant_override("shadow_offset_x", 1)
	feedback_banner_label.add_theme_constant_override("shadow_offset_y", 1)


func _flash_canvas_item(item: CanvasItem, color: Color, duration: float = 0.2) -> void:
	if item == null or not item.is_inside_tree():
		return

	item.modulate = color
	var tween := create_tween()
	tween.tween_property(item, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pulse_canvas_item(item: CanvasItem, color: Color) -> void:
	if item == null or not item.is_inside_tree():
		return

	item.modulate = color
	if item is Control:
		var control: Control = item
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2(1.03, 1.03)
		var control_tween: Tween = create_tween()
		control_tween.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		control_tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		var item_tween: Tween = create_tween()
		item_tween.tween_property(item, "modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _emit_combat_delta_feedback(state: Dictionary) -> void:
	if last_combat_feedback_state.is_empty():
		last_combat_feedback_state = _capture_combat_feedback_state(state)
		return

	var previous_player: Dictionary = last_combat_feedback_state.get("player", {})
	var player: Dictionary = state.get("player", {})
	_emit_actor_delta_feedback(previous_player, player, &"player", String(player.get("name", "Gambler-Knight")))

	var previous_enemies: Dictionary = last_combat_feedback_state.get("enemies", {})
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		var enemy_id: StringName = StringName(enemy_data.get("id", &""))
		if not previous_enemies.has(enemy_id):
			continue
		var previous_enemy: Dictionary = previous_enemies[enemy_id]
		_emit_actor_delta_feedback(previous_enemy, enemy_data, enemy_id, String(enemy_data.get("name", "Enemy")))

	var previous_traps: int = int(last_combat_feedback_state.get("traps_armed", 0))
	var current_traps: int = int(state.get("traps_armed", 0))
	if current_traps > previous_traps:
		_push_feedback("Trap armed +%d." % (current_traps - previous_traps), FEEDBACK_CARD_COLOR, combat_feedback_label)
	elif current_traps < previous_traps:
		_push_feedback("Trap sprung: %d trap removed." % (previous_traps - current_traps), FEEDBACK_DAMAGE_COLOR, combat_feedback_label)

	var previous_outcome: String = String(last_combat_feedback_state.get("outcome", "ongoing"))
	var current_outcome: String = String(state.get("outcome", "ongoing"))
	if previous_outcome != current_outcome and current_outcome != "ongoing":
		_push_feedback("Combat %s." % current_outcome.capitalize(), FEEDBACK_PHASE_COLOR, combat_feedback_label)

	last_combat_feedback_state = _capture_combat_feedback_state(state)


func _emit_actor_delta_feedback(previous_actor: Dictionary, actor: Dictionary, unit_id: StringName, label: String) -> void:
	var previous_hp: int = int(previous_actor.get("hp", 0))
	var current_hp: int = int(actor.get("hp", 0))
	var previous_guard: int = int(previous_actor.get("guard", 0))
	var current_guard: int = int(actor.get("guard", 0))
	var hp_lost: int = previous_hp - current_hp
	var guard_delta: int = current_guard - previous_guard

	if hp_lost > 0:
		var hp_label: String = "Blood" if unit_id == &"player" else "HP"
		_push_feedback("%s -%d %s." % [label, hp_lost, hp_label], FEEDBACK_DAMAGE_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_DAMAGE_COLOR)
		_float_grid_text(unit_id, "-%d" % hp_lost, FEEDBACK_DAMAGE_COLOR)
		_play_unit_burst(unit_id, FEEDBACK_DAMAGE_COLOR, &"blood")
		if arena_view != null and arena_view.has_method("play_damage"):
			arena_view.call("play_damage", unit_id, hp_lost)
	elif guard_delta < 0:
		_push_feedback("%s Guard -%d absorbed impact." % [label, abs(guard_delta)], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)
		_float_grid_text(unit_id, "BLOCK %d" % abs(guard_delta), FEEDBACK_GUARD_COLOR)
		_play_guard_vfx(unit_id)
		if arena_view != null and arena_view.has_method("play_guard"):
			arena_view.call("play_guard", unit_id, abs(guard_delta))

	if guard_delta > 0:
		_push_feedback("%s Guard +%d." % [label, guard_delta], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)
		_float_grid_text(unit_id, "+%dG" % guard_delta, FEEDBACK_GUARD_COLOR)
		_play_guard_vfx(unit_id)
		if arena_view != null and arena_view.has_method("play_guard"):
			arena_view.call("play_guard", unit_id, guard_delta)

	if bool(previous_actor.get("alive", true)) and not bool(actor.get("alive", true)):
		_push_feedback("%s defeated." % label, FEEDBACK_DAMAGE_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_DAMAGE_COLOR)
		_float_grid_text(unit_id, "KO", FEEDBACK_DAMAGE_COLOR)
		_play_unit_burst(unit_id, Color(0.82, 0.78, 0.66), &"ash")
		if arena_view != null and arena_view.has_method("play_defeat"):
			arena_view.call("play_defeat", unit_id)


func _capture_combat_feedback_state(state: Dictionary) -> Dictionary:
	var player: Dictionary = state.get("player", {})
	var enemies_by_id: Dictionary = {}
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		var enemy_id: StringName = StringName(enemy_data.get("id", &""))
		enemies_by_id[enemy_id] = enemy_data.duplicate()

	return {
		"player": player.duplicate(),
		"enemies": enemies_by_id,
		"traps_armed": int(state.get("traps_armed", 0)),
		"outcome": String(state.get("outcome", "ongoing"))
	}


func _flash_grid_unit(unit_id: StringName, color: Color) -> void:
	if combat_grid != null and combat_grid.has_method("flash_unit"):
		combat_grid.call("flash_unit", unit_id, color)


func _float_grid_text(unit_id: StringName, message: String, color: Color) -> void:
	if combat_grid != null and combat_grid.has_method("show_floating_text_for_unit"):
		combat_grid.call("show_floating_text_for_unit", unit_id, message, color)


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


func _sync_run_panel_visibility() -> void:
	if run_panel_container == null:
		return

	var has_visible_reward := false
	for button in card_reward_buttons:
		if button != null and bool(button.get("visible")):
			has_visible_reward = true
			break
	if not has_visible_reward:
		for button in relic_reward_buttons:
			if button != null and bool(button.get("visible")):
				has_visible_reward = true
				break

	var has_player_panel := false
	has_player_panel = has_player_panel or (reward_prompt_label != null and bool(reward_prompt_label.get("visible")))
	has_player_panel = has_player_panel or (reward_impact_label != null and bool(reward_impact_label.get("visible")))
	has_player_panel = has_player_panel or has_visible_reward
	has_player_panel = has_player_panel or (skip_rewards_button != null and bool(skip_rewards_button.get("visible")))
	has_player_panel = has_player_panel or (run_results_label != null and bool(run_results_label.get("visible")))
	has_player_panel = has_player_panel or (run_export_readback_label != null and bool(run_export_readback_label.get("visible")))
	has_player_panel = has_player_panel or (run_history_label != null and bool(run_history_label.get("visible")))
	has_player_panel = has_player_panel or (run_inspector_panel != null and bool(run_inspector_panel.get("visible")))
	run_panel_container.visible = debug_controls_visible or has_player_panel


func _update_debug_visibility() -> void:
	if debug_drawer_panel != null:
		debug_drawer_panel.visible = debug_controls_visible
	if debug_controls != null:
		debug_controls.visible = debug_controls_visible
	if toggle_debug_button != null:
		toggle_debug_button.text = "Hide Debug" if debug_controls_visible else "Show Debug"
	if toggle_truth_button != null:
		toggle_truth_button.text = "Hide Truth" if debug_truth_visible else "Show Truth"
	if reset_button != null:
		reset_button.visible = debug_controls_visible
		reset_button.text = "Reset Run"
	if recipe_panel != null:
		recipe_panel.visible = debug_controls_visible
	if run_state_label != null:
		run_state_label.visible = debug_controls_visible
	if balance_report_label != null:
		balance_report_label.visible = debug_controls_visible
	if playtest_report_label != null:
		playtest_report_label.visible = debug_controls_visible
	if combat_log_column != null:
		combat_log_column.visible = debug_controls_visible

	var truth_visible := debug_controls_visible and debug_truth_visible
	if truth_title_label != null:
		truth_title_label.visible = truth_visible
	if debug_truth_label != null:
		debug_truth_label.visible = truth_visible
	_sync_live_text_density()
	_sync_run_panel_visibility()


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
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option
		var intent_label := "%d%% %s" % [
			option_data.get("percentage", 0),
			option_data.get("intent_name", "Intent")
		]
		var icon_value: Texture2D = _load_runtime_art_texture(String(option_data.get("icon_path", "")))
		if icon_value != null:
			intent_call_option.add_icon_item(icon_value, intent_label)
		else:
			intent_call_option.add_item(intent_label)
		intent_call_option.set_item_metadata(intent_call_option.item_count - 1, option_data)

	if intent_call_option.item_count > 0:
		intent_call_option.select(0)


func _get_selected_metadata(option_button: OptionButton):
	if option_button == null:
		return null
	if option_button.item_count == 0 or option_button.selected < 0:
		return null
	return option_button.get_item_metadata(option_button.selected)


func _get_card_cost(card: Resource) -> int:
	if card == null:
		return 0
	return int(card.get("cost"))


func _load_runtime_art_texture(path: String) -> Texture2D:
	if DisplayServer.get_name() == "headless" or path.is_empty():
		return null
	var texture := load(path)
	if texture is Texture2D:
		return texture
	return null


func _get_card_name(card: Resource) -> String:
	if card == null:
		return "Unknown Card"
	if card.has_method("get_display_name"):
		return String(card.call("get_display_name"))
	return String(card.get("display_name"))


func _get_lane_name(lane: int) -> String:
	match lane:
		0:
			return "Left"
		1:
			return "Center"
		2:
			return "Right"
		_:
			return "Unknown"


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
