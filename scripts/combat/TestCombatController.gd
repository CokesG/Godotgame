extends Control

const COMBAT_GRID_SCRIPT := preload("res://scripts/grid/CombatGrid.gd")
const BLUFF_SYSTEM_SCRIPT := preload("res://scripts/combat/BluffSystem.gd")
const COMBAT_RESOLVER_SCRIPT := preload("res://scripts/combat/CombatResolver.gd")
const COMBAT_SESSION_SCRIPT := preload("res://scripts/combat/CombatSession.gd")
const DECK_MANAGER_SCRIPT := preload("res://scripts/cards/DeckManager.gd")
const ENEMY_INTENT_SYSTEM_SCRIPT := preload("res://scripts/enemies/EnemyIntentSystem.gd")
const HAND_VIEW_SCRIPT := preload("res://scripts/ui/HandView.gd")
const RUN_MANAGER_SCRIPT := preload("res://scripts/run/RunManager.gd")
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
const PHASE_ACTION_LABELS := {
	"START_TURN": "Begin Turn",
	"DRAW": "Begin Turn",
	"ENEMY_INTENT_PREVIEW": "Begin Turn",
	"PLAYER_COMMIT": "Resolve Turn",
	"BLUFF_WAGER": "Reveal Turn",
	"REVEAL": "Review Results",
	"RESOLVE": "Next Turn",
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
var run_manager: Node
var deck_manager: Node
var enemy_intent_system: Node
var hand_view: HBoxContainer
var pile_counts_label: Label
var resource_state_label: Label
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
var turn_status_label: RichTextLabel
var feedback_banner_label: Label
var combat_feedback_label: RichTextLabel
var action_prompt_label: Label
var phase_guidance_label: Label
var phase_detail_label: Label
var table_rule_status_label: RichTextLabel
var recipe_panel: PanelContainer
var recipe_label: RichTextLabel
var run_state_label: RichTextLabel
var balance_report_label: RichTextLabel
var run_results_label: RichTextLabel
var run_export_readback_label: RichTextLabel
var playtest_report_label: RichTextLabel
var reward_prompt_label: RichTextLabel
var reward_impact_label: RichTextLabel
var run_path_buttons: Array[Button] = []
var card_reward_buttons: Array[Button] = []
var relic_reward_buttons: Array[Button] = []
var skip_rewards_button: Button
var combat_state_label: RichTextLabel
var bluff_state_label: RichTextLabel
var enemy_call_option: OptionButton
var intent_call_option: OptionButton
var lane_call_option: OptionButton
var target_enemy_option: OptionButton
var movement_cell_option: OptionButton
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
var debug_controls_visible: bool = false
var debug_truth_visible: bool = false
var current_intent_previews: Array[Dictionary] = []
var reveal_resolved_this_phase: bool = false
var run_flow_state: String = RUN_FLOW_START
var recipe_progress: Dictionary = {}
var pending_card_context: Dictionary = {}
var committed_card_context: Dictionary = {}
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


func _ready() -> void:
	_build_ui()
	_connect_turn_manager()
	log_label.clear()
	_reset_run_slice()


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
	title.name = "ScreenTitle"
	title.text = "Dead Man's Ante - Prototype Run"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "ScreenSubtitle"
	subtitle.text = "Read the table, survive five fights, and tune the run from what actually happens."
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
	run_shell_actions.add_theme_constant_override("separation", 8)
	run_shell_layout.add_child(run_shell_actions)

	start_run_button = Button.new()
	start_run_button.name = "StartRunButton"
	start_run_button.text = "Start Run"
	start_run_button.pressed.connect(_on_start_run_pressed)
	run_shell_actions.add_child(start_run_button)

	next_encounter_button = Button.new()
	next_encounter_button.name = "NextEncounterButton"
	next_encounter_button.text = "Deal Next Table"
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

	action_prompt_label = Label.new()
	action_prompt_label.name = "ActionPrompt"
	action_prompt_label.text = "Next: start the run."
	action_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_prompt_label.add_theme_font_size_override("font_size", 16)
	guidance_layout.add_child(action_prompt_label)

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
	run_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(run_panel)

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
		reward_button.custom_minimum_size = Vector2(0, 136)
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
	target_enemy_option.item_selected.connect(_on_target_enemy_selected)
	intent_column.add_child(target_enemy_option)

	movement_cell_option = OptionButton.new()
	movement_cell_option.name = "MovementCellOption"
	movement_cell_option.item_selected.connect(_on_movement_cell_selected)
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

	card_action_hint_label = RichTextLabel.new()
	card_action_hint_label.name = "CardActionHint"
	card_action_hint_label.bbcode_enabled = false
	card_action_hint_label.fit_content = true
	card_action_hint_label.scroll_active = false
	card_action_hint_label.custom_minimum_size = Vector2(0, 64)
	deck_panel.add_child(card_action_hint_label)

	card_target_preview_label = RichTextLabel.new()
	card_target_preview_label.name = "CardTargetPreview"
	card_target_preview_label.bbcode_enabled = false
	card_target_preview_label.fit_content = true
	card_target_preview_label.scroll_active = false
	card_target_preview_label.custom_minimum_size = Vector2(0, 72)
	deck_panel.add_child(card_target_preview_label)

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
	_set_run_flow_state(RUN_FLOW_COMBAT)
	_append_log("Run started: Opening Table is live.")
	_push_feedback("Run map: Opening Table is live.", FEEDBACK_PHASE_COLOR, run_path_label)
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
	_push_feedback("Run map: moving to Table %d/%d - %s." % [
		table_number,
		table_count,
		node_name
	], FEEDBACK_PHASE_COLOR, run_path_label)
	_push_feedback("Approach: %s dealt into combat. Read enemies, table rule, then begin turn." % node_name, FEEDBACK_PHASE_COLOR, run_shell_panel)
	_surface_latest_table_rule_effect()


func _on_reset_grid_pressed() -> void:
	combat_grid.call("reset_grid", run_manager.call("get_current_enemy_spawns"))


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
	_push_feedback("Card: %s played." % _get_card_name(card), FEEDBACK_CARD_COLOR, card_action_hint_label)
	if _is_movement_card(card):
		if bool(_resolve_movement_card(card, pending_card_context)):
			_apply_card_side_effects(card)
	else:
		combat_resolver.call("apply_card_with_context", card, pending_card_context)
		_apply_card_side_effects(card)
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
	context["committed"] = true
	if not _validate_card_context(card, context):
		return

	if not bool(combat_session.call("spend_energy", cost, "Commit %s" % card_name)):
		return

	var committed: Resource = deck_manager.call("commit_card_at", 0)
	if committed != null:
		committed_card_context = context.duplicate()
		bluff_system.call("set_committed_card", committed)
		_mark_recipe_step("play_or_commit")
		_push_feedback("Committed: %s face-down." % _get_card_name(committed), FEEDBACK_CARD_COLOR, bluff_state_label)
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


func _on_raise_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Raise is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("raise_wager", 1)):
		_mark_recipe_step("bluff_choice")
		_push_feedback("Raise: wager increased.", FEEDBACK_REVEAL_COLOR, bluff_state_label)


func _on_fold_pressed() -> void:
	if not bool(combat_session.call("can_bluff")):
		_append_log("Fold is only available during Bluff Wager.")
		return
	if bool(bluff_system.call("fold")):
		deck_manager.call("fold_committed_card")
		committed_card_context.clear()
		_mark_recipe_step("bluff_choice")
		_push_feedback("Fold: committed card moved to discard.", FEEDBACK_REVEAL_COLOR, bluff_state_label)


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
	run_ceremony_history.clear()
	selected_run_path_index = -1
	last_run_path_current_index = -1
	last_run_path_transition_text = ""
	last_results_ceremony_outcome = ""
	last_export_path = ""
	last_export_readback.clear()
	run_manager.call("reset_run")
	_reset_playable_combat()


func _reset_playable_combat() -> void:
	_reset_recipe_progress()
	_reset_feedback_state()
	pending_card_context.clear()
	committed_card_context.clear()
	_apply_relic_modifiers()
	combat_session.call("reset_session")
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


func _reset_deck_and_draw_opening_hand() -> void:
	deck_manager.call("configure_deck", run_manager.call("get_deck_paths"))
	deck_manager.call("reset_deck")
	deck_manager.call("draw_cards", int(combat_session.get("hand_target")))


func _reset_enemy_intents() -> void:
	enemy_intent_system.call("configure_enemies", run_manager.call("get_current_enemy_paths"))
	enemy_intent_system.call("roll_intents")


func _reset_combat_state() -> void:
	combat_resolver.call("reset_combat", run_manager.call("get_current_enemy_paths"), int(run_manager.call("get_player_hp")))


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
	for preview in previews:
		var options: Array = preview.get("options", [])
		var top_option: Dictionary = _get_top_intent_option(options)
		intent_preview_label.append_text("%s | Top threat: %s %d%%\n" % [
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
	_refresh_card_action_hint()
	_refresh_card_target_preview()


func _on_movement_cell_selected(_index: int) -> void:
	_refresh_card_action_hint()
	_refresh_card_target_preview()


func _on_card_previewed(hand_index: int) -> void:
	previewed_hand_index = hand_index
	if hand_view != null and hand_view.has_method("set_previewed_index"):
		hand_view.call("set_previewed_index", hand_index)
	_refresh_card_target_preview()


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
	selected_run_path_index = index
	if run_manager == null:
		return
	_refresh_run_path(run_manager.call("get_state"))


func _on_card_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_card_reward", index))
	if not claimed_path.is_empty():
		_record_run_ceremony("Reward: card added to the deck. The map marker can advance when rewards are clear.", FEEDBACK_CARD_COLOR, reward_prompt_label)
		_show_next_encounter_if_ready()


func _on_relic_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_relic_reward", index))
	if not claimed_path.is_empty():
		_record_run_ceremony("Reward: relic claimed. The route is ready to continue when rewards are clear.", FEEDBACK_CARD_COLOR, reward_prompt_label)
		_show_next_encounter_if_ready()


func _on_skip_rewards_pressed() -> void:
	run_manager.call("skip_rewards")
	_record_run_ceremony("Reward: skipped to keep the deck lean. The route marker advances.", FEEDBACK_CARD_COLOR, reward_prompt_label)
	_show_next_encounter_if_ready()


func _on_run_playtests_pressed() -> void:
	var batch: Dictionary = run_manager.call("get_playtest_batch")
	_refresh_playtest_report(batch)
	_append_log("Playtest sims: %s" % batch.get("summary", "No summary."))


func _on_export_summary_pressed() -> void:
	var path: String = String(run_manager.call("export_run_summary"))
	if path.is_empty():
		_append_log("Run summary export failed.")
		last_export_path = ""
		last_export_readback = {"ok": false, "error": "export returned no path"}
		_refresh_export_readback_label()
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
	_refresh_targeting_options()


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
			if _is_movement_card(resolved_card):
				if bool(_resolve_movement_card(resolved_card, committed_card_context)):
					_apply_card_side_effects(resolved_card)
			else:
				combat_resolver.call("apply_card_with_context", resolved_card, committed_card_context)
				_apply_card_side_effects(resolved_card)
			committed_card_context.clear()
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

	next_phase_button.disabled = shell_blocks_combat or not can_debug_adjust
	if run_flow_state == RUN_FLOW_START:
		next_phase_button.text = "Start Run"
	elif run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		next_phase_button.text = "Deal Next Table"
	elif run_outcome == "victory":
		next_phase_button.text = "Run Complete"
	elif run_outcome == "defeat":
		next_phase_button.text = "Run Lost"
	elif waiting_for_reward:
		next_phase_button.text = "Choose Reward"
	else:
		next_phase_button.text = "Combat Over" if not can_debug_adjust else String(PHASE_ACTION_LABELS.get(phase_key, "Continue"))
	reset_grid_button.disabled = not can_debug_adjust
	draw_button.disabled = not can_debug_adjust
	discard_hand_button.disabled = not can_debug_adjust
	reset_deck_button.disabled = not can_debug_adjust
	roll_intents_button.disabled = not can_debug_adjust
	reveal_intents_button.disabled = not can_reveal or reveal_resolved_this_phase
	run_playtests_button.disabled = run_manager == null
	export_summary_button.disabled = run_manager == null

	commit_first_card_button.disabled = shell_blocks_combat or not can_play or has_committed
	set_call_button.disabled = shell_blocks_combat or not can_bluff
	raise_button.disabled = shell_blocks_combat or not can_bluff or not has_committed
	fold_button.disabled = shell_blocks_combat or not can_bluff or not has_committed
	reset_bluff_button.disabled = shell_blocks_combat or not can_debug_adjust
	_refresh_guidance()
	if run_manager != null:
		_refresh_run_panel(run_state)
	_refresh_run_shell(run_state)
	_refresh_turn_status(run_state)
	_refresh_table_rule_status(run_state)
	_refresh_card_action_hint()


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

	var card_rewards: Array = state.get("pending_card_rewards", [])
	var relic_rewards: Array = state.get("pending_relic_rewards", [])
	_refresh_reward_prompt(state, card_rewards, relic_rewards)
	_refresh_reward_impact(state, card_rewards, relic_rewards)
	for index in range(card_reward_buttons.size()):
		var button := card_reward_buttons[index]
		if index < card_rewards.size():
			var reward: Dictionary = card_rewards[index]
			button.text = _get_card_reward_button_text(reward, index)
			button.disabled = false
			button.visible = true
			button.modulate = Color(1.0, 0.95, 0.72) if index == 0 else Color.WHITE
		else:
			button.text = "Card Reward"
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
	run_shell_title_label.text = _get_run_shell_title(state)
	run_shell_detail_label.clear()
	run_shell_detail_label.append_text(_get_run_shell_detail(state))
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
	if next_encounter_button != null:
		next_encounter_button.visible = run_flow_state == RUN_FLOW_NEXT_ENCOUNTER
		next_encounter_button.disabled = run_flow_state != RUN_FLOW_NEXT_ENCOUNTER
	if shell_new_run_button != null:
		shell_new_run_button.visible = run_flow_state == RUN_FLOW_RESULTS
		shell_new_run_button.disabled = run_flow_state != RUN_FLOW_RESULTS
	if shell_export_button != null:
		shell_export_button.visible = run_flow_state == RUN_FLOW_RESULTS
		shell_export_button.disabled = run_flow_state != RUN_FLOW_RESULTS


func _get_run_shell_title(state: Dictionary) -> String:
	match run_flow_state:
		RUN_FLOW_START:
			return "Run Start"
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
			return "The Gambler-Knight enters a five-table prototype run.\nStart when ready: %s begins at %d/%d Blood with a %d-card deck." % [
				state.get("current_node_name", "Opening Table"),
				state.get("player_hp", 0),
				state.get("player_max_hp", 0),
				state.get("deck_size", 0)
			]
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
			return "Run map: Opening Table is the current stop; %d upcoming tables are visible." % max(0, node_count - 1)
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
			return "Run map: marker has moved to %s (%d/%d). Deal Next Table to continue the same run." % [
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
	run_ceremony_label.append_text("Thread: %s" % _get_run_ceremony_thread_text())


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
		entries.append(run_ceremony_history[index])
	return " | ".join(entries)


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
	return run_flow_state == RUN_FLOW_START or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER or run_flow_state == RUN_FLOW_COMBAT


func _get_encounter_preview_text(state: Dictionary) -> String:
	var table_name: String = String(state.get("current_node_name", "Encounter"))
	var intro: String = String(state.get("encounter_intro", "Read the table before combat starts."))
	var modifier: Dictionary = state.get("table_modifier", {})
	var modifier_name: String = String(modifier.get("name", "No table modifier"))
	var modifier_summary: String = String(modifier.get("summary", "No special rule is active."))
	var reward_stakes: String = String(state.get("reward_stakes", "Clear the table to improve the run."))
	var enemies: Array = state.get("current_enemy_names", [])
	var enemy_text: String = "unknown opposition" if enemies.is_empty() else ", ".join(enemies)
	var reward_tags: Array = state.get("reward_tag_names", [])
	var tag_text: String = "Run clear" if reward_tags.is_empty() else ", ".join(reward_tags)

	return "Encounter: %s\nEnemies: %s\nIntro: %s\nModifier: %s - %s\nReward stakes: %s\nReward tags: %s" % [
		table_name,
		enemy_text,
		intro,
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
	return run_flow_state == RUN_FLOW_START or run_flow_state == RUN_FLOW_NEXT_ENCOUNTER


func _get_current_run_path_entry(state: Dictionary) -> Dictionary:
	var path_entries: Array = state.get("run_path", [])
	var index: int = clampi(int(state.get("current_node_index", 0)), 0, max(0, path_entries.size() - 1))
	if index >= 0 and index < path_entries.size() and typeof(path_entries[index]) == TYPE_DICTIONARY:
		return Dictionary(path_entries[index])

	var modifier: Dictionary = state.get("table_modifier", {})
	return {
		"name": String(state.get("current_node_name", "Encounter")),
		"kind": String(state.get("current_node_kind", "combat")),
		"enemy_cards": state.get("current_enemy_cards", []),
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
	return "Table Rule Card: %s\nEffect: %s" % [
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
		button.self_modulate = _get_run_path_button_color(status, selected)
		button.text = "%sTable %d\n%s\n%s%s" % [
			prefix,
			entry.get("table_number", index + 1),
			entry.get("name", "Table"),
			status_label,
			suffix
		]
		button.tooltip_text = _get_run_path_button_tooltip(entry)


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
	return "%s\nEnemies: %s\nRule: %s" % [
		entry.get("encounter_intro", "Read the table before combat starts."),
		enemy_text,
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
			return "Reward resolved. The marker has moved to %s; Deal Next Table to enter combat." % state.get("current_node_name", "Encounter")
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
	return "%s\nTake %s\n%s\nReasons: %s\nImpact: %s" % [
		rank_label,
		reward.get("name", "Card"),
		reward.get("text", ""),
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
		return "Threat: no active enemy previews.\nResponse: advance to read the table."

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

	return "Threat: %s %s %d%% %s\nResponse: %s" % [
		best_preview.get("enemy_name", "Enemy"),
		_get_threat_level(best_option),
		best_option.get("percentage", 0),
		best_option.get("intent_name", "Intent"),
		_get_threat_response(best_option)
	]


func _build_intent_icon_strip(previews: Array[Dictionary]) -> String:
	if previews.is_empty():
		return "Intent Icons\n[?] No active enemy reads."

	var lines: Array[String] = ["Intent Icons"]
	for preview in previews:
		var options: Array = preview.get("options", [])
		var top_option: Dictionary = _get_top_intent_option(options)
		if top_option.is_empty():
			lines.append("[?] %s no weighted read" % preview.get("enemy_name", "Enemy"))
			continue
		lines.append("%s %s %d%% %s" % [
			_get_intent_icon_marker(top_option),
			preview.get("enemy_name", "Enemy"),
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
	_refresh_card_action_hint()
	_refresh_card_target_preview()


func _build_card_context(card: Resource) -> Dictionary:
	var target_enemy: Dictionary = _get_selected_enemy_target()
	var target_cell: Vector2i = _get_selected_move_cell()
	var player_context: Dictionary = combat_grid.call("get_player_context")
	var target_enemy_id: StringName = StringName(target_enemy.get("id", &""))
	var target_enemy_name: String = String(target_enemy.get("name", "Enemy"))
	return {
		"target_enemy_id": target_enemy_id,
		"target_enemy_name": target_enemy_name,
		"target_cell": target_cell,
		"target_cell_label": combat_grid.call("format_cell", target_cell),
		"player_lane": int(player_context.get("lane", -1)),
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


func _resolve_movement_card(card: Resource, context: Dictionary) -> bool:
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	if not _is_valid_player_move_target(target_cell):
		_append_log("%s fizzles because the move target is no longer legal." % _get_card_name(card))
		return false

	if bool(combat_grid.call("move_unit", &"player", target_cell)):
		_append_log("%s moves the Gambler-Knight to %s." % [
			_get_card_name(card),
			combat_grid.call("format_cell", target_cell)
		])
		return true

	return false


func _apply_card_side_effects(card: Resource) -> void:
	var card_id: StringName = StringName(card.get("id"))
	var card_name := _get_card_name(card)
	match card_id:
		&"blood_ritual":
			bluff_system.call("gain_nerve", 2, card_name)
		&"marked_card":
			bluff_system.call("gain_nerve", 1, card_name)
		&"second_wind":
			bluff_system.call("gain_nerve", 1, card_name)
		&"shadow_step":
			combat_resolver.call("add_player_guard", 2, card_name)


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
		phase_detail_label.text = "Press Start Run when you are ready to sit at the first table."
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

	_refresh_recipe_label()


func _get_action_prompt(session_state: Dictionary, run_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "Next: press Start Run to begin the five-table path."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Next: choose one reward; the next table starts when rewards are clear."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Next: deal the next table when you are ready to continue the run."
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
			return "Next: play cards, then Resolve Turn."
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
		return "State: Start Run is live. Combat buttons and card clicks wait until the table opens."
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
	enemy_status_label.append_text("Blood %d/%d | Guard %d\n" % [
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
		enemy_status_label.append_text("%s HP %d/%d | Guard %d | %s | Threat %s\n" % [
			enemy_data.get("name", "Enemy"),
			enemy_data.get("hp", 0),
			enemy_data.get("max_hp", 0),
			enemy_data.get("guard", 0),
			_get_enemy_hp_status(enemy_data),
			_get_enemy_read_text(enemy_id)
		])


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
	card_action_hint_label.append_text("Hand %d | Energy %d/%d | Target: %s | Move: %s\n" % [
		counts.get("hand", 0),
		session_state.get("energy", 0),
		session_state.get("max_energy", 0),
		_get_target_affordance_text(),
		_get_move_affordance_text()
	])
	card_action_hint_label.append_text(_get_card_affordance_text(session_state))


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
		return "Cards wait: press Start Run before committing actions."
	if run_flow_state == RUN_FLOW_REWARD:
		return "Cards wait: choose rewards before the next table."
	if run_flow_state == RUN_FLOW_NEXT_ENCOUNTER:
		return "Cards wait: deal the next table to draw the new opening hand."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Cards wait: the run is over until New Run."
	if bool(session_state.get("combat_over", false)):
		return "Cards wait: combat is over."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"PLAYER_COMMIT":
			return "Cards are playable now: attack/read use Target, movement uses Move, then Resolve Turn."
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
		return

	var card: Resource = deck_manager.call("get_card_at", previewed_hand_index) if deck_manager != null else null
	if card == null:
		card_target_preview_label.append_text("Preview: no card at this hand slot.")
		return

	var context: Dictionary = _build_card_context(card)
	card_target_preview_label.append_text("Preview: %s | Cost %d | %s\n" % [
		_get_card_name(card),
		_get_card_cost(card),
		_get_preview_card_type_label(card)
	])
	card_target_preview_label.append_text("Target: %s\n" % _get_card_preview_target_text(card, context))
	card_target_preview_label.append_text("Expected: %s" % _get_card_preview_effect_text(card, context))
	_preview_card_grid_focus(card, context)


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


func _preview_card_grid_focus(card: Resource, context: Dictionary) -> void:
	if combat_grid == null:
		return

	if _is_attack_or_read_card(card):
		var target_enemy_id: StringName = StringName(context.get("target_enemy_id", &""))
		if not target_enemy_id.is_empty():
			_flash_grid_unit(target_enemy_id, FEEDBACK_CARD_COLOR)
	elif _is_grid_cell_card(card):
		var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
		if target_cell != Vector2i(-1, -1) and combat_grid.has_method("flash_cell"):
			combat_grid.call("flash_cell", target_cell, FEEDBACK_CARD_COLOR)
	elif int(card.get("target_type")) == 1:
		_flash_grid_unit(&"player", FEEDBACK_CARD_COLOR)


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
	elif guard_delta < 0:
		_push_feedback("%s Guard -%d absorbed impact." % [label, abs(guard_delta)], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)
		_float_grid_text(unit_id, "BLOCK %d" % abs(guard_delta), FEEDBACK_GUARD_COLOR)

	if guard_delta > 0:
		_push_feedback("%s Guard +%d." % [label, guard_delta], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)
		_float_grid_text(unit_id, "+%dG" % guard_delta, FEEDBACK_GUARD_COLOR)

	if bool(previous_actor.get("alive", true)) and not bool(actor.get("alive", true)):
		_push_feedback("%s defeated." % label, FEEDBACK_DAMAGE_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_DAMAGE_COLOR)
		_float_grid_text(unit_id, "KO", FEEDBACK_DAMAGE_COLOR)


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
