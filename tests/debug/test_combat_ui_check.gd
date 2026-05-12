extends Node


func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/combat/TestCombat.tscn")
	if packed_scene == null:
		_fail("Could not load TestCombat scene.")
		return

	var combat_scene: Node = packed_scene.instantiate()
	add_child(combat_scene)
	await get_tree().process_frame

	var guidance := combat_scene.find_child("TurnGuidance", true, false)
	if guidance == null:
		_fail("Expected TurnGuidance panel.")
		return

	var recipe_panel := combat_scene.find_child("RecipePanel", true, false)
	if recipe_panel == null:
		_fail("Expected RecipePanel.")
		return
	if bool(recipe_panel.get("visible")):
		_fail("RecipePanel should start inside the hidden debug drawer flow.")
		return

	var run_header := combat_scene.find_child("RunHeader", true, false)
	if run_header == null:
		_fail("Expected RunHeader for Phase 14 run readability.")
		return

	var run_shell_panel := combat_scene.find_child("RunShellPanel", true, false)
	if run_shell_panel == null:
		_fail("Expected RunShellPanel for Phase 15 run flow.")
		return

	var start_run_button := combat_scene.find_child("StartRunButton", true, false)
	if start_run_button == null:
		_fail("Expected StartRunButton for Phase 15 run start.")
		return

	var shell_export_button := combat_scene.find_child("ShellExportButton", true, false)
	if shell_export_button == null:
		_fail("Expected ShellExportButton for Phase 15 run results export.")
		return

	var run_continuity := combat_scene.find_child("RunContinuity", true, false)
	if run_continuity == null:
		_fail("Expected RunContinuity for Phase 21 run continuity.")
		return

	var next_encounter_button := combat_scene.find_child("NextEncounterButton", true, false)
	if next_encounter_button == null:
		_fail("Expected NextEncounterButton for Phase 21 next-table flow.")
		return

	var encounter_preview := combat_scene.find_child("EncounterPreview", true, false)
	if encounter_preview == null:
		_fail("Expected EncounterPreview for Phase 22 encounter pacing.")
		return

	var approach_panel := combat_scene.find_child("EncounterApproachPanel", true, false)
	if approach_panel == null:
		_fail("Expected EncounterApproachPanel for Phase 27 approach-table polish.")
		return

	var approach_enemy_cards := combat_scene.find_child("ApproachEnemyCards", true, false)
	if approach_enemy_cards == null:
		_fail("Expected ApproachEnemyCards for Phase 27 enemy-card previews.")
		return

	var approach_rule := combat_scene.find_child("ApproachTableRule", true, false)
	if approach_rule == null:
		_fail("Expected ApproachTableRule for Phase 27 table-rule framing.")
		return

	var approach_stakes := combat_scene.find_child("ApproachStakes", true, false)
	if approach_stakes == null:
		_fail("Expected ApproachStakes for Phase 27 reward-stakes framing.")
		return

	var action_prompt := combat_scene.find_child("ActionPrompt", true, false)
	if action_prompt == null:
		_fail("Expected ActionPrompt for Phase 14 next-action clarity.")
		return

	var turn_status := combat_scene.find_child("TurnStatus", true, false)
	if turn_status == null:
		_fail("Expected TurnStatus for Phase 17 turn-state readability.")
		return

	var table_rule_status := combat_scene.find_child("TableRuleStatus", true, false)
	if table_rule_status == null:
		_fail("Expected TableRuleStatus for Phase 23 table modifier readability.")
		return

	var feedback_banner := combat_scene.find_child("FeedbackBanner", true, false)
	if feedback_banner == null:
		_fail("Expected FeedbackBanner for Phase 18 combat feel.")
		return

	var combat_feedback := combat_scene.find_child("CombatFeedback", true, false)
	if combat_feedback == null:
		_fail("Expected CombatFeedback feed for Phase 18 combat feel.")
		return

	var run_panel := combat_scene.find_child("RunPanel", true, false)
	if run_panel == null:
		_fail("Expected RunPanel for the Phase 11 prototype path.")
		return

	var run_path := combat_scene.find_child("RunPath", true, false)
	if run_path == null:
		_fail("Expected RunPath for Phase 25 run-map presentation.")
		return

	var run_path_panel := combat_scene.find_child("RunPathPanel", true, false)
	if run_path_panel == null:
		_fail("Expected RunPathPanel for Phase 25 run-map presentation.")
		return

	var run_path_buttons := combat_scene.find_child("RunPathButtons", true, false)
	if run_path_buttons == null:
		_fail("Expected RunPathButtons for Phase 26 interactive map selection.")
		return

	var run_path_preview := combat_scene.find_child("RunPathPreview", true, false)
	if run_path_preview == null:
		_fail("Expected RunPathPreview for Phase 26 selected-table preview.")
		return

	var reward_prompt := combat_scene.find_child("RewardPrompt", true, false)
	if reward_prompt == null:
		_fail("Expected RewardPrompt for Phase 14 reward readability.")
		return

	var reward_impact := combat_scene.find_child("RewardImpact", true, false)
	if reward_impact == null:
		_fail("Expected RewardImpact for Phase 24 reward screen polish.")
		return

	var balance_report := combat_scene.find_child("BalanceReport", true, false)
	if balance_report == null:
		_fail("Expected BalanceReport for Phase 12 tuning.")
		return
	if bool(balance_report.get("visible")):
		_fail("BalanceReport should start hidden in the debug drawer.")
		return

	var run_results := combat_scene.find_child("RunResults", true, false)
	if run_results == null:
		_fail("Expected RunResults for Phase 12 outcomes.")
		return

	var playtest_report := combat_scene.find_child("PlaytestReport", true, false)
	if playtest_report == null:
		_fail("Expected PlaytestReport for Phase 13 run comparisons.")
		return
	if bool(playtest_report.get("visible")):
		_fail("PlaytestReport should start hidden in the debug drawer.")
		return

	var debug_drawer := combat_scene.find_child("DebugDrawer", true, false)
	if debug_drawer == null:
		_fail("Expected DebugDrawer for Phase 16 diagnostics.")
		return

	if bool(debug_drawer.get("visible")):
		_fail("DebugDrawer should start hidden.")
		return

	var debug_summary := combat_scene.find_child("DebugSummary", true, false)
	if debug_summary == null:
		_fail("Expected DebugSummary for Phase 16 diagnostics.")
		return

	var run_playtests_button := combat_scene.find_child("RunPlaytestsButton", true, false)
	if run_playtests_button == null:
		_fail("Expected RunPlaytestsButton for Phase 13 simulation.")
		return

	var export_summary_button := combat_scene.find_child("ExportSummaryButton", true, false)
	if export_summary_button == null:
		_fail("Expected ExportSummaryButton for Phase 13 run exports.")
		return

	var target_enemy_option := combat_scene.find_child("TargetEnemyOption", true, false)
	if target_enemy_option == null:
		_fail("Expected TargetEnemyOption.")
		return

	var movement_cell_option := combat_scene.find_child("MovementCellOption", true, false)
	if movement_cell_option == null:
		_fail("Expected MovementCellOption.")
		return

	var threat_summary := combat_scene.find_child("ThreatSummary", true, false)
	if threat_summary == null:
		_fail("Expected ThreatSummary for Phase 14 intent readability.")
		return

	var enemy_status := combat_scene.find_child("EnemyStatus", true, false)
	if enemy_status == null:
		_fail("Expected EnemyStatus for Phase 17 enemy readability.")
		return

	var card_action_hint := combat_scene.find_child("CardActionHint", true, false)
	if card_action_hint == null:
		_fail("Expected CardActionHint for Phase 17 card affordances.")
		return

	var intent_icon_strip := combat_scene.find_child("IntentIconStrip", true, false)
	if intent_icon_strip == null:
		_fail("Expected IntentIconStrip for Phase 19 intent presentation.")
		return

	var card_target_preview := combat_scene.find_child("CardTargetPreview", true, false)
	if card_target_preview == null:
		_fail("Expected CardTargetPreview for Phase 19 card preview.")
		return

	var continue_button := combat_scene.find_child("ContinueButton", true, false)
	if continue_button == null:
		_fail("Expected ContinueButton.")
		return

	if String(continue_button.get("text")) == "Next Phase":
		_fail("ContinueButton should use playable wording, not raw debug wording.")
		return

	var debug_controls := combat_scene.find_child("DebugControls", true, false)
	if debug_controls == null:
		_fail("Expected DebugControls container.")
		return

	if bool(debug_controls.get("visible")):
		_fail("DebugControls should start hidden.")
		return

	var debug_truth := combat_scene.find_child("DebugTruth", true, false)
	if debug_truth == null:
		_fail("Expected DebugTruth panel.")
		return

	if bool(debug_truth.get("visible")):
		_fail("DebugTruth should start hidden.")
		return

	print("TEST_COMBAT_UI_CHECK: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
