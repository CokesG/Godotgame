@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const DEBUG_SCENES := [
	"res://tests/debug/Phase42PresentationLockCheck.tscn",
	"res://tests/debug/Phase43FirstLoopJuiceCheck.tscn",
	"res://tests/debug/Phase44ResponsivenessGuidanceCheck.tscn",
	"res://tests/debug/Phase45GameplayMechanicsCheck.tscn",
	"res://tests/debug/Phase45VisualQACheck.tscn"
]

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func suite_name() -> String:
	return "dead_mans_ante"


func test_main_scene_and_phase45_resources_load() -> void:
	var main_scene := load("res://scenes/combat/TestCombat.tscn")
	assert_true(main_scene is PackedScene, "TestCombat should load as a PackedScene.")
	for scene_path in DEBUG_SCENES:
		assert_true(load(scene_path) is PackedScene, "%s should load as a PackedScene." % scene_path)


func test_phase45_vfx_source_assets_exist() -> void:
	var asset_paths := [
		"res://art/game/vfx/vfx_particle_atlas.svg",
		"res://art/game/vfx/vfx_slash_strip.svg",
		"res://art/game/vfx/vfx_ritual_circle.svg",
		"res://art/game/vfx/vfx_card_burn_mask.svg"
	]
	assert_eq(asset_paths.size(), 4, "Phase 45 should register the four source VFX assets.")
	for asset_path in asset_paths:
		assert_true(FileAccess.file_exists(String(asset_path)), "%s should exist." % asset_path)


func test_resolver_rage_suspicion_and_bait_mechanics() -> void:
	var resolver: Node = load("res://scripts/combat/CombatResolver.gd").new()
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_name": "Rage Roar",
		"payload": {"rage": 1}
	}], {})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 1,
		"payload": {"damage": 8}
	}], {"player_lane": 1})
	var rage_hp := int(resolver.call("get_state").get("player", {}).get("hp", -1))
	assert_eq(rage_hp, 20, "Rage should add +2 damage, got HP %d." % rage_hp)

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"shieldbearer",
		"enemy_name": "Shieldbearer",
		"intent_name": "Taunting Knock",
		"payload": {"suspicion": 1}
	}], {})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 1,
		"payload": {"damage": 8}
	}], {
		"player_lane": 1,
		"bluff_state": {
			"last_call_correct": true,
			"last_called_enemy_id": &"brute",
			"last_called_intent_id": &"brute_smash",
			"last_resolved_wager": 1
		}
	})
	assert_eq(int(resolver.call("get_state").get("player", {}).get("hp", -1)), 24, "Suspicion should tax call mitigation.")

	var false_opening: Resource = load("res://resources/cards/false_opening.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", false_opening, {"player_lane": 1})
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"shieldbearer",
		"enemy_name": "Shieldbearer",
		"intent_id": &"shieldbearer_bash",
		"intent_name": "Shield Bash",
		"target_lane": 0,
		"payload": {"damage": 5}
	}], {"player_lane": 0})
	assert_eq(int(resolver.call("get_state").get("player", {}).get("hp", -1)), 30, "False Opening should redirect the attack lane.")
