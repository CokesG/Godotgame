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
const RUN_FLOW_RESULTS := "results"
const FEEDBACK_DAMAGE_COLOR := Color(1.0, 0.36, 0.28)
const FEEDBACK_GUARD_COLOR := Color(0.38, 0.78, 1.0)
const FEEDBACK_CARD_COLOR := Color(1.0, 0.78, 0.36)
const FEEDBACK_PHASE_COLOR := Color(0.72, 0.90, 1.0)
const FEEDBACK_REVEAL_COLOR := Color(0.90, 0.68, 1.0)
const FEEDBACK_MOVE_COLOR := Color(0.52, 1.0, 0.62)
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
var run_manager: Node
var deck_manager: Node
var enemy_intent_system: Node
var hand_view: HBoxContainer
var pile_counts_label: Label
var resource_state_label: Label
var run_header_label: RichTextLabel
var run_shell_panel: PanelContainer
var run_shell_title_label: Label
var run_shell_detail_label: RichTextLabel
var start_run_button: Button
var shell_new_run_button: Button
var shell_export_button: Button
var turn_status_label: RichTextLabel
var feedback_banner_label: Label
var combat_feedback_label: RichTextLabel
var action_prompt_label: Label
var phase_guidance_label: Label
var phase_detail_label: Label
var recipe_panel: PanelContainer
var recipe_label: RichTextLabel
var run_state_label: RichTextLabel
var balance_report_label: RichTextLabel
var run_results_label: RichTextLabel
var playtest_report_label: RichTextLabel
var reward_prompt_label: RichTextLabel
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
var debug_controls_visible: bool = false
var debug_truth_visible: bool = false
var current_intent_previews: Array[Dictionary] = []
var reveal_resolved_this_phase: bool = false
var run_flow_state: String = RUN_FLOW_START
var recipe_progress: Dictionary = {}
var pending_card_context: Dictionary = {}
var committed_card_context: Dictionary = {}
var feedback_history: Array[String] = []
var last_combat_feedback_state: Dictionary = {}


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

	var run_shell_actions := HBoxContainer.new()
	run_shell_actions.name = "RunShellActions"
	run_shell_actions.add_theme_constant_override("separation", 8)
	run_shell_layout.add_child(run_shell_actions)

	start_run_button = Button.new()
	start_run_button.name = "StartRunButton"
	start_run_button.text = "Start Run"
	start_run_button.pressed.connect(_on_start_run_pressed)
	run_shell_actions.add_child(start_run_button)

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
		reward_button.custom_minimum_size = Vector2(0, 108)
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
	if run_flow_state == RUN_FLOW_RESULTS:
		_append_log("Run is complete. Start a new run to play again.")
		return
	if not bool(combat_session.call("can_debug_adjust")):
		_append_log("Combat is over. Reset to start a new loop.")
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
	_push_feedback("Run started: Opening Table is live.", FEEDBACK_PHASE_COLOR, run_shell_panel)
	_refresh_action_controls()


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
	_refresh_card_action_hint()


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
			intent_preview_label.append_text("%s %s %d%% %s\n" % [
				marker,
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
		run_manager.call("mark_combat_victory", combat_resolver.call("get_state"))
	else:
		run_manager.call("mark_combat_defeat")
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


func _on_movement_cell_selected(_index: int) -> void:
	_refresh_card_action_hint()


func _on_run_state_changed(state: Dictionary) -> void:
	_sync_run_flow_from_state(state)
	_refresh_run_panel(state)


func _on_card_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_card_reward", index))
	if not claimed_path.is_empty():
		_start_next_encounter_if_ready()


func _on_relic_reward_pressed(index: int) -> void:
	var claimed_path: String = String(run_manager.call("claim_relic_reward", index))
	if not claimed_path.is_empty():
		_start_next_encounter_if_ready()


func _on_skip_rewards_pressed() -> void:
	run_manager.call("skip_rewards")
	_start_next_encounter_if_ready()


func _on_run_playtests_pressed() -> void:
	var batch: Dictionary = run_manager.call("get_playtest_batch")
	_refresh_playtest_report(batch)
	_append_log("Playtest sims: %s" % batch.get("summary", "No summary."))


func _on_export_summary_pressed() -> void:
	var path: String = String(run_manager.call("export_run_summary"))
	if path.is_empty():
		_append_log("Run summary export failed.")
	else:
		_append_log("Run summary exported to %s." % path)


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


func _start_next_encounter_if_ready() -> void:
	var run_state: Dictionary = run_manager.call("get_state")
	if String(run_state.get("run_outcome", "running")) != "running":
		_refresh_action_controls()
		return

	if bool(run_manager.call("can_start_current_node")):
		_set_run_flow_state(RUN_FLOW_COMBAT)
		_reset_playable_combat()


func _apply_relic_modifiers() -> void:
	var modifiers: Dictionary = run_manager.call("get_relic_modifiers")
	combat_session.set("max_energy", 3 + int(modifiers.get("max_energy_bonus", 0)))
	combat_session.set("hand_target", 5 + int(modifiers.get("hand_target_bonus", 0)))
	bluff_system.set("starting_nerve", 3 + int(modifiers.get("starting_nerve_bonus", 0)))


func _apply_starting_relic_effects() -> void:
	var modifiers: Dictionary = run_manager.call("get_relic_modifiers")
	var starting_guard := int(modifiers.get("starting_guard", 0))
	if starting_guard > 0:
		combat_resolver.call("add_player_guard", starting_guard, "Relic guard")


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
	var shell_blocks_combat := run_flow_state == RUN_FLOW_START or run_flow_state == RUN_FLOW_RESULTS

	next_phase_button.disabled = shell_blocks_combat or not can_debug_adjust
	if run_flow_state == RUN_FLOW_START:
		next_phase_button.text = "Start Run"
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

	var card_rewards: Array = state.get("pending_card_rewards", [])
	var relic_rewards: Array = state.get("pending_relic_rewards", [])
	_refresh_reward_prompt(state, card_rewards, relic_rewards)
	for index in range(card_reward_buttons.size()):
		var button := card_reward_buttons[index]
		if index < card_rewards.size():
			var reward: Dictionary = card_rewards[index]
			button.text = "%s\n%s\nWhy: %s" % [
				reward.get("name", "Card"),
				reward.get("text", ""),
				reward.get("explanation", "Solid reward option.")
			]
			button.disabled = false
			button.visible = true
		else:
			button.text = "Card Reward"
			button.disabled = true
			button.visible = false

	for index in range(relic_reward_buttons.size()):
		var button := relic_reward_buttons[index]
		if index < relic_rewards.size():
			var reward: Dictionary = relic_rewards[index]
			button.text = "%s\n%s" % [reward.get("name", "Relic"), reward.get("text", "")]
			button.disabled = false
			button.visible = true
		else:
			button.text = "Relic Reward"
			button.disabled = true
			button.visible = false

	if skip_rewards_button != null:
		skip_rewards_button.disabled = not bool(state.get("waiting_for_reward", false))
		skip_rewards_button.visible = bool(state.get("waiting_for_reward", false))


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
	elif bool(state.get("waiting_for_reward", false)):
		_set_run_flow_state(RUN_FLOW_REWARD)
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

	if start_run_button != null:
		start_run_button.visible = run_flow_state == RUN_FLOW_START
		start_run_button.disabled = run_flow_state != RUN_FLOW_START
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
			return "The Gambler-Knight enters a five-table prototype run.\nStart when ready: Opening Table begins at %d/%d Blood with a %d-card deck." % [
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
		RUN_FLOW_RESULTS:
			var results: Dictionary = state.get("run_results", {})
			return "%s | Won %d/%d | Blood %d/%d\nDamage taken %d | Lowest Blood %d | Deck %d cards" % [
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


func _refresh_reward_prompt(state: Dictionary, card_rewards: Array, relic_rewards: Array) -> void:
	if reward_prompt_label == null:
		return

	var waiting_for_reward := bool(state.get("waiting_for_reward", false))
	reward_prompt_label.visible = waiting_for_reward
	reward_prompt_label.clear()
	if not waiting_for_reward:
		return

	reward_prompt_label.append_text("Reward choice: top picks are sorted by current deck gap and table tags.\n")
	if not card_rewards.is_empty() and typeof(card_rewards[0]) == TYPE_DICTIONARY:
		var best_card: Dictionary = card_rewards[0]
		reward_prompt_label.append_text("Best card: %s -> %s" % [
			best_card.get("name", "Card"),
			best_card.get("explanation", "Solid reward option.")
		])
	else:
		reward_prompt_label.append_text("No card reward is pending.")

	if not relic_rewards.is_empty():
		reward_prompt_label.append_text("\nElite relic pending after the card pick.")


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
			return "Next: refill Energy and draw up."
		"DRAW":
			return "Next: read enemy intent odds."
		"ENEMY_INTENT_PREVIEW":
			return "Next: choose a target and commit your plan."
		"PLAYER_COMMIT":
			return "Next: spend Energy on damage, Guard, movement, or a face-down commit."
		"BLUFF_WAGER":
			return "Next: call the biggest threat, raise if confident, or fold."
		"REVEAL":
			return "Next: reveal resolves attacks, calls, traps, and committed cards."
		"RESOLVE":
			return "Next: check Blood, enemy HP, and the log."
		"CLEANUP":
			return "Next: discard leftovers and start the next turn."
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


func _get_turn_state_feedback(session_state: Dictionary, run_state: Dictionary) -> String:
	if run_flow_state == RUN_FLOW_START:
		return "State: Start Run is live. Combat buttons and card clicks wait until the table opens."
	if run_flow_state == RUN_FLOW_REWARD:
		return "State: rewards are live. Pick the card that closes the shown deck gap."
	if run_flow_state == RUN_FLOW_RESULTS:
		return "State: run results are live. Export the summary or start a new run."

	if bool(session_state.get("combat_over", false)):
		if bool(run_state.get("waiting_for_reward", false)):
			return "State: combat won. Rewards are the next real action."
		return "State: combat ended. Review Blood, enemy HP, and run outcome."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"START_TURN":
			return "State: reset the turn economy, then draw back up."
		"DRAW":
			return "State: fill the hand before reading enemy intent."
		"ENEMY_INTENT_PREVIEW":
			return "State: read top threats, then choose a target and move before committing."
		"PLAYER_COMMIT":
			return "State: cards are playable now. Watch Energy, Target, and Move before clicking."
		"BLUFF_WAGER":
			return "State: bluff choices are live. Call, raise, or fold before reveal."
		"REVEAL":
			return "State: reveal is live. Damage, Guard, movement, traps, and calls resolve here."
		"RESOLVE":
			return "State: resolve aftermath. Check Blood, Guard, enemy HP, and threat outcome."
		"CLEANUP":
			return "State: cleanup discards leftovers and prepares the next turn."
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
	if run_flow_state == RUN_FLOW_RESULTS:
		return "Cards wait: the run is over until New Run."
	if bool(session_state.get("combat_over", false)):
		return "Cards wait: combat is over."

	var phase_key: String = String(session_state.get("current_phase_key", "START_TURN"))
	match phase_key:
		"PLAYER_COMMIT":
			return "Cards are playable now: attack/read use Target, movement uses Move, Guard/self cards ignore target."
		"BLUFF_WAGER":
			return "Hand is locked while bluff choices resolve the committed plan."
		"REVEAL":
			return "Hand is locked during reveal; watch the play area resolve."
		"ENEMY_INTENT_PREVIEW":
			return "Pick Target and Move now so card clicks make sense on commit."
		_:
			return "Hand is visible for planning; card clicks unlock on Player Commit."


func _reset_feedback_state() -> void:
	feedback_history.clear()
	last_combat_feedback_state.clear()
	if feedback_banner_label != null:
		feedback_banner_label.text = "Ready"
		feedback_banner_label.modulate = Color.WHITE
	if combat_feedback_label != null:
		combat_feedback_label.clear()
		combat_feedback_label.append_text("Feedback: phase changes, card plays, damage, Guard, movement, and reveals land here.")


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
	elif guard_delta < 0:
		_push_feedback("%s Guard -%d absorbed impact." % [label, abs(guard_delta)], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)

	if guard_delta > 0:
		_push_feedback("%s Guard +%d." % [label, guard_delta], FEEDBACK_GUARD_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_GUARD_COLOR)

	if bool(previous_actor.get("alive", true)) and not bool(actor.get("alive", true)):
		_push_feedback("%s defeated." % label, FEEDBACK_DAMAGE_COLOR, enemy_status_label)
		_flash_grid_unit(unit_id, FEEDBACK_DAMAGE_COLOR)


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
