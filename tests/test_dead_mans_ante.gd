@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const DEBUG_SCENES := [
	"res://tests/debug/DevHubCheck.tscn",
	"res://tests/debug/Phase42PresentationLockCheck.tscn",
	"res://tests/debug/Phase43FirstLoopJuiceCheck.tscn",
	"res://tests/debug/Phase44ResponsivenessGuidanceCheck.tscn",
	"res://tests/debug/Phase45GameplayMechanicsCheck.tscn",
	"res://tests/debug/Phase45VisualQACheck.tscn",
	"res://tests/debug/FPSPrototypeCheck.tscn",
	"res://tests/debug/FPSWaveLoopCheck.tscn",
	"res://tests/debug/FPSVisualQACheck.tscn",
	"res://tests/debug/Phase56VFXShowcaseCheck.tscn",
	"res://tests/debug/Phase61TacticalMapCheck.tscn",
	"res://tests/debug/Phase69ArenaReturnCheck.tscn"
]

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func suite_name() -> String:
	return "dead_mans_ante"


func test_main_scene_and_phase45_resources_load() -> void:
	assert_true(load("res://scenes/ui/MainMenu.tscn") is PackedScene, "MainMenu should load as the project launch hub.")
	assert_true(load("res://scenes/ui/TacticalMapViewer.tscn") is PackedScene, "TacticalMapViewer should load as a direct map inspection scene.")
	var main_scene := load("res://scenes/combat/TestCombat.tscn")
	assert_true(main_scene is PackedScene, "TestCombat should load as a PackedScene.")
	for scene_path in DEBUG_SCENES:
		assert_true(load(scene_path) is PackedScene, "%s should load as a PackedScene." % scene_path)


func test_main_menu_promotes_fast_arena_entry() -> void:
	var menu_script: GDScript = ResourceLoader.load("res://scripts/ui/MainMenu.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var menu: Control = menu_script.new()
	menu.call("_build_ui")
	var quick_arena := menu.find_child("QuickArenaButton", true, false) as Button
	var deal_in := menu.find_child("DealInButton", true, false) as Button
	var practice := menu.find_child("DevToolsButton", true, false) as Button
	var status := menu.find_child("LaunchStatus", true, false) as Label
	assert_true(quick_arena != null, "Main menu should expose a fast shooter-first Enter Arena button.")
	assert_true(deal_in != null, "Main menu should still expose card-kit prep.")
	assert_true(quick_arena.get_index() < deal_in.get_index(), "Fast arena entry should be the first primary action.")
	assert_true(String(quick_arena.text).contains("ENTER ARENA"), "Fast arena CTA should be explicit.")
	assert_eq(String(practice.text), "Practice Lab", "Prototype shortcuts should stay out of the main path.")
	assert_true(String(status.text).contains("jumps straight into the shooter"), "Main menu status should explain the fast path.")


func test_phase45_vfx_source_assets_exist() -> void:
	var asset_paths := [
		"res://art/game/vfx/vfx_particle_atlas.svg",
		"res://art/game/vfx/vfx_slash_strip.svg",
		"res://art/game/vfx/vfx_ritual_circle.svg",
		"res://art/game/vfx/vfx_card_burn_mask.svg",
		"res://art/game/vfx/generated/vfx_slash_strip.png",
		"res://art/game/vfx/generated/vfx_smoke_strip.png",
		"res://art/game/vfx/generated/vfx_chip_scatter_strip.png",
		"res://art/game/vfx/generated/vfx_ritual_glow_strip.png",
		"res://art/game/vfx/generated/vfx_guard_shield_strip.png",
		"res://art/game/vfx/generated/vfx_blood_hit_strip.png",
		"res://art/game/vfx/generated/vfx_death_ash_strip.png",
		"res://art/game/vfx/generated/vfx_card_burn_strip.png",
		"res://audio/sfx/generated/sfx_card_flick.wav",
		"res://audio/sfx/generated/sfx_chip_clack.wav",
		"res://audio/sfx/generated/sfx_slash_hit.wav",
		"res://audio/sfx/generated/sfx_guard_shimmer.wav",
		"res://audio/sfx/generated/sfx_smoke_whoosh.wav",
		"res://audio/sfx/generated/sfx_ritual_hum.wav",
		"res://audio/sfx/generated/sfx_card_burn.wav",
		"res://audio/sfx/generated/sfx_ash_fall.wav"
	]
	assert_eq(asset_paths.size(), 20, "VFX should register source SVGs, PNG sprite strips, and generated SFX.")
	for asset_path in asset_paths:
		assert_true(FileAccess.file_exists(String(asset_path)), "%s should exist." % asset_path)


func test_arena_3d_consequence_layer_loads() -> void:
	var arena_script := ResourceLoader.load("res://scripts/arena/Arena3DView.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_true(arena_script is GDScript, "Arena3DView should load as a GDScript consequence layer.")
	var arena: Control = arena_script.new()
	assert_true(arena.has_method("focus_unit"), "Arena3DView should expose target-focus spectacle.")
	assert_true(arena.has_method("preview_card_intent"), "Arena3DView should preview hovered card intent in the arena.")
	assert_true(arena.has_method("play_card_beat"), "Arena3DView should expose card-driven arena beats.")
	assert_true(arena.has_method("play_damage"), "Arena3DView should expose damage spectacle.")
	assert_true(arena.has_method("configure_map"), "Arena3DView should render tactical map data.")


func test_crossfire_tactical_map_rules_load() -> void:
	var map_script: GDScript = ResourceLoader.load("res://scripts/grid/TacticalMapDefinition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_true(map_script is GDScript, "TacticalMapDefinition should load.")
	var map_data: Dictionary = map_script.get_default_map()
	assert_eq(String(map_data.get("name", "")), "Crossfire Table", "Default tactical map should be Crossfire Table.")
	var center: Dictionary = map_script.get_cell_feature(map_data, Vector2i(1, 1))
	assert_eq(String(center.get("short_label", "")), "POT", "Center cell should be the Ante Pot.")
	assert_eq(int(center.get("card_damage_bonus", 0)), 1, "Center Pot should add +1 card damage.")
	var cover: Dictionary = map_script.get_cell_feature(map_data, Vector2i(0, 2))
	assert_eq(int(cover.get("incoming_damage_mitigation", 0)), 2, "Back Cover should mitigate incoming lane damage.")


func test_fps_pivot_scene_and_contracts_load() -> void:
	assert_true(load("res://scenes/fps/FPSPrototype.tscn") is PackedScene, "FPSPrototype should load as the shooter arena scene.")
	var player_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPlayer.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var weapon_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSWeapon.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var drone_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSDrone.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_true(player_script is GDScript, "FPSPlayer should load.")
	assert_true(weapon_script is GDScript, "FPSWeapon should load.")
	assert_true(drone_script is GDScript, "FPSDrone should load.")
	assert_true(prototype_script is GDScript, "FPSPrototype should load.")

	var player: Node = player_script.new()
	var weapon: Node = weapon_script.new()
	var drone: Node = drone_script.new()
	var prototype: Node = prototype_script.new()
	assert_true(player.has_method("add_camera_impulse"), "FPSPlayer should expose camera recoil impulses.")
	assert_true(player.has_method("apply_weapon_recoil"), "FPSPlayer should expose persistent weapon recoil for AR spray control.")
	assert_true(player.has_method("get_horizontal_speed_ratio"), "FPSPlayer should expose movement spread tuning.")
	assert_true(weapon.has_method("try_fire"), "FPSWeapon should expose fire attempts.")
	assert_true(weapon.has_method("try_reload"), "FPSWeapon should expose reload attempts.")
	assert_eq(String(weapon.get("weapon_name")), "Ante Carbine AR", "FPSWeapon should default to the automatic carbine test profile.")
	var weapon_source := FileAccess.get_file_as_string("res://scripts/fps/FPSWeapon.gd")
	assert_true(weapon_source.contains("apply_weapon_recoil"), "FPSWeapon should route shot recoil through the player aim-kick hook.")
	assert_true(weapon_source.contains("EjectedCasing"), "FPSWeapon should spawn visible casing ejection for shot feedback.")
	assert_true(bool(weapon.get("infinite_test_ammo")), "The FPS test weapon should default to infinite ammo while combat feel is being tuned.")
	assert_true(drone.has_method("take_damage"), "FPSDrone should expose damage intake.")
	assert_true(drone.has_method("is_critical_hit"), "FPSDrone should expose crit zones.")
	assert_true(prototype.has_method("spawn_tracer"), "FPSPrototype should expose shot tracers.")
	assert_true(prototype.has_method("spawn_enemy_tell"), "FPSPrototype should expose readable enemy attack tells.")
	assert_true(prototype.has_method("spawn_enemy_projectile"), "FPSPrototype should expose incoming enemy projectiles.")
	assert_true(prototype.has_method("_build_spawn_portals"), "FPSPrototype should stage enemy spawn portals in the arena.")
	assert_true(prototype.has_method("_build_objective_props"), "FPSPrototype should stage objective props in the arena.")
	assert_true(prototype.has_method("_spawn_impact_decal"), "FPSPrototype should leave temporary impact decals.")
	assert_true(prototype.has_method("get_living_enemies"), "FPSPrototype should expose encounter state.")
	assert_true(prototype.has_method("get_map_summary"), "FPSPrototype should expose Crossfire map summary.")
	assert_true(prototype.has_method("get_map_regions"), "FPSPrototype should expose authored tactical map regions.")
	assert_true(prototype.has_method("get_objective_modes"), "FPSPrototype should expose testable objective modes.")
	assert_true(prototype.has_method("get_objective_state"), "FPSPrototype should expose active objective progress.")
	assert_true(prototype.has_method("get_ability_state"), "FPSPrototype should expose bridged FPS ability state.")
	assert_true(prototype.has_method("get_active_hero_profile"), "FPSPrototype should expose the active player class profile.")
	assert_true(prototype.has_method("get_arena_result_preview"), "FPSPrototype should expose arena result payout previews.")
	assert_true(player.has_method("dash_forward"), "FPSPlayer should expose card-driven dash.")
	assert_true(player.has_method("add_armor"), "FPSPlayer should expose card-driven armor gain.")
	assert_true(drone.has_method("reveal_for"), "FPSDrone should expose read-card reveal.")
	assert_true(drone.has_method("apply_snare"), "FPSDrone should expose trap-card snare.")
	assert_true(drone.has_method("_show_attack_tell"), "FPSDrone should expose windup tells for combat readability.")
	assert_true(drone.has_method("_get_status_text"), "FPSDrone should expose readable status text for tells and debuffs.")


func test_fps_pivot_uses_existing_visual_assets() -> void:
	var fps_asset_paths := [
		"res://art/game/enemies/enemy_skulker.png",
		"res://art/game/enemies/enemy_brute.png",
		"res://art/game/enemies/enemy_needle_eye.png",
		"res://art/game/enemies/enemy_hexmonger.png",
		"res://art/game/classes/hero_gambler_knight_keyart.png",
		"res://art/game/classes/hero_gambler_knight_portrait.png",
		"res://art/game/classes/hero_hex_sharpshooter_keyart.png",
		"res://art/game/classes/hero_hex_sharpshooter_portrait.png",
		"res://art/game/classes/hero_blood_wager_keyart.png",
		"res://art/game/classes/hero_blood_wager_portrait.png"
	]
	for asset_path in fps_asset_paths:
		assert_true(FileAccess.file_exists(String(asset_path)), "%s should be available for FPS/class presentation." % asset_path)


func test_fps_player_mouse_look_changes_yaw_and_pitch() -> void:
	var player_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPlayer.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var player: Node3D = player_script.new()
	var start_yaw := player.rotation.y
	player.call("_apply_mouse_look", Vector2(120.0, -60.0))
	assert_ne(player.rotation.y, start_yaw, "Horizontal mouse motion should rotate the FPS body.")
	assert_true(float(player.get("pitch")) > 0.0, "Vertical mouse motion should update FPS camera pitch.")
	player.call("apply_aim_settings", {"mouse_sensitivity": 0.002, "ads_sensitivity_scale": 0.5, "ads_fov": 52.0, "fov": 78.0})
	player.call("set_ads_state", true)
	var ads_yaw := player.rotation.y
	player.call("_apply_mouse_look", Vector2(100.0, 0.0))
	var ads_delta := absf(player.rotation.y - ads_yaw)
	player.call("set_ads_state", false)
	var hip_yaw := player.rotation.y
	player.call("_apply_mouse_look", Vector2(100.0, 0.0))
	var hip_delta := absf(player.rotation.y - hip_yaw)
	assert_true(ads_delta < hip_delta, "ADS sensitivity should scale mouse look down from hip-fire.")
	assert_true(is_equal_approx(float(player.call("_get_target_fov", false, 0.0, true)), 52.0), "ADS FOV should be a functional camera target.")
	var pre_pad_yaw := player.rotation.y
	player.call("apply_aim_settings", {"gamepad_look_sensitivity": 3.0, "gamepad_deadzone": 0.10, "gamepad_response_curve": 1.0})
	player.call("_apply_gamepad_look_vector", Vector2(0.60, -0.30), 0.20)
	assert_ne(player.rotation.y, pre_pad_yaw, "Right-stick look should rotate the FPS body.")
	assert_true(float(player.call("_shape_gamepad_look", Vector2(0.05, 0.0)).length()) == 0.0, "Gamepad look should respect the configured deadzone.")


func test_fps_settings_crosshair_and_ability_contracts() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	assert_true(prototype.has_method("toggle_settings_menu"), "FPSPrototype should expose the Escape settings overlay.")
	assert_true(prototype.has_method("is_gameplay_paused"), "FPSPrototype should expose settings/reward pause state.")
	assert_true(prototype.has_method("_apply_encoded_binding"), "FPSPrototype settings should support persisted keybind rebinding.")
	assert_true(prototype.has_method("_get_action_binding_text"), "FPSPrototype settings should show readable binding text.")
	assert_true(prototype.has_method("_reset_action_binding"), "FPSPrototype settings should allow per-action default resets.")
	assert_true(prototype.has_method("_find_binding_conflict"), "FPSPrototype settings should detect duplicate keybinds.")
	assert_true(prototype.has_method("_apply_settings_preset"), "FPSPrototype settings should expose input preset application.")
	assert_true(prototype.has_method("_refresh_card_combat_hud"), "FPSPrototype should expose card-powered HUD refresh.")
	assert_true(prototype.has_method("_get_ability_cooldown_ratio"), "FPSPrototype should expose card HUD cooldown progress.")
	assert_true(prototype.has_method("_get_ability_glyph"), "FPSPrototype should expose compact card-power icon glyphs.")
	assert_true(prototype.has_method("_get_class_accent_color"), "FPSPrototype should expose class accent color for HUD/VFX frames.")
	assert_true(prototype.has_method("_get_reward_input_index"), "FPSPrototype payout should expose keyboard reward selection.")
	assert_true(prototype.has_method("_get_reward_navigation_delta"), "FPSPrototype payout should expose keyboard focus navigation.")
	assert_true(prototype.has_method("_get_reward_focus_text"), "FPSPrototype payout should expose selected-card explanation copy.")
	prototype.call("toggle_settings_menu")
	assert_true(bool(prototype.call("is_gameplay_paused")), "Escape settings overlay should pause FPS gameplay input.")
	prototype.call("toggle_settings_menu")
	assert_false(bool(prototype.call("is_gameplay_paused")), "Closing settings should resume FPS gameplay input.")
	prototype.call("_ensure_input_actions")
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_reload")).contains("R"), "R should be bound to reload by default.")
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_ads")).contains("Mouse Right"), "Right mouse should aim down sights by default.")
	prototype.call("_apply_encoded_binding", &"fps_ability_4", "key:%d" % KEY_Y)
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_ability_4")).contains("Y"), "Ability keybinds should update through the settings rebinder.")
	prototype.call("_apply_encoded_binding", &"fps_ability_4", "joy_button:%d" % JOY_BUTTON_Y)
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_ability_4")).contains("Pad Y"), "Ability keybinds should support gamepad button bindings.")
	prototype.call("_reset_action_binding", &"fps_ability_4")
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_ability_4")).contains("V"), "Ability keybind reset should restore keyboard defaults.")
	prototype.call("_apply_settings_preset", "left_handed")
	assert_true(String(prototype.call("_get_action_binding_text", &"fps_move_forward")).contains("Up"), "Left-handed preset should move movement onto arrow keys.")
	prototype.call("_apply_settings_preset", "default_fps")
	prototype.set("crosshair_settings", {
		"color": Color(1.0, 0.25, 0.78, 0.5),
		"gap": 4.0,
		"length": 10.0,
		"thickness": 3.0,
		"dot_size": 2.0,
		"opacity": 0.8,
		"outline": true,
		"outline_opacity": 0.6,
		"dynamic_gap": false
	})
	var crosshair_color: Color = prototype.call("_get_crosshair_color")
	assert_true(is_equal_approx(crosshair_color.a, 0.8), "Crosshair opacity should be controlled separately from color.")
	prototype.call("apply_arena_bridge_payload", {
		"hero_class": "hex_sharpshooter",
		"loadout": [{"slot": "ability_1", "id": "sidestep", "ability": {"kind": "dash", "cooldown": 6.0}}],
		"economy": {"chips": 0, "armor": 0, "ammo": 24}
	})
	var hero_profile: Dictionary = prototype.call("get_active_hero_profile")
	assert_eq(String(hero_profile.get("name", "")), "Hex Sharpshooter", "FPS should support player class profiles separate from card loadout.")
	assert_eq(String(prototype.call("_get_ability_glyph", "snare_field")), "X", "Trap powers should render with a compact icon glyph in the card HUD.")
	var hex_reveal_color: Color = prototype.call("_get_ability_color", "reveal_target")
	assert_true(hex_reveal_color.b > 0.70, "Hex class should tint read/trap ability frames toward its blue class accent.")
	var ability_state: Array = prototype.call("get_ability_state")
	assert_eq(ability_state.size(), 1, "FPSPrototype should expose active Q/E ability state.")
	assert_true(bool((ability_state[0] as Dictionary).get("ready", false)), "Slotted abilities should start ready.")
	var cooldowns: Array[float] = [3.0]
	prototype.set("ability_cooldowns", cooldowns)
	var cooldown_ratio := float(prototype.call("_get_ability_cooldown_ratio", 0))
	var expected_cooldown_ratio := 1.0 - 3.0 / (6.0 * float(hero_profile.get("cooldown_scalar", 1.0)))
	assert_true(is_equal_approx(cooldown_ratio, expected_cooldown_ratio), "Card HUD cooldown progress should track hero-adjusted remaining ability cooldown; got %.3f." % cooldown_ratio)
	var reward_options: Array[Dictionary] = [{"label": "A", "kind": "damage", "amount": 2, "chip_bonus": 3}, {"label": "B", "kind": "armor", "amount": 8, "chip_bonus": 2}, {"label": "C", "kind": "ammo", "amount": 24, "chip_bonus": 2}]
	prototype.set("reward_options", reward_options)
	prototype.call("_set_active_reward_index", 2)
	var reward_key := InputEventKey.new()
	reward_key.pressed = true
	reward_key.physical_keycode = KEY_2
	assert_eq(int(prototype.call("_get_reward_input_index", reward_key)), 1, "Payout keyboard shortcuts should select the matching reward card.")
	var reward_right := InputEventKey.new()
	reward_right.pressed = true
	reward_right.physical_keycode = KEY_RIGHT
	assert_eq(int(prototype.call("_get_reward_navigation_delta", reward_right)), 1, "Payout arrows should move reward focus without firing gameplay actions.")
	assert_true(String(prototype.call("_get_reward_focus_text", reward_options[0])).contains("damage"), "Focused reward copy should explain how the payout affects the next arena.")
	var reward_enter := InputEventKey.new()
	reward_enter.pressed = true
	reward_enter.physical_keycode = KEY_ENTER
	var enter_index := int(prototype.call("_get_reward_input_index", reward_enter))
	assert_eq(enter_index, 2, "Enter should confirm the focused payout card; got %d." % enter_index)


func test_fps_weapon_overclock_and_enemy_archetypes() -> void:
	var weapon_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSWeapon.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var weapon: Node = weapon_script.new()
	weapon.call("_build_viewmodel")
	assert_true((weapon.call("_get_recoil_pattern_value") as Vector2).y > 0.0, "The first AR should expose a deterministic recoil pattern.")
	assert_true(float(weapon.call("_get_hipfire_spread_multiplier")) > 2.0, "Hip-fire should be much looser than ADS for the first AR.")
	var feel_snapshot: Dictionary = weapon.call("get_feel_tuning_snapshot")
	assert_true(float(feel_snapshot.get("hipfire_spread_multiplier", 0.0)) >= 3.0, "The AR tuning snapshot should preserve close-range hipfire spread separation.")
	assert_true((feel_snapshot.get("ads_position", Vector3.ZERO) as Vector3).z > (feel_snapshot.get("base_position", Vector3.ZERO) as Vector3).z, "ADS should pull the weapon toward the sights instead of leaving hipfire framing.")
	var rig_snapshot: Dictionary = weapon.call("get_viewmodel_rig_snapshot")
	assert_true(bool(rig_snapshot.get("has_rig_root", false)), "FPSWeapon should build a named first-person rig root for authored viewmodel animation.")
	assert_true(bool(rig_snapshot.get("has_animation_player", false)), "FPSWeapon should own an AnimationPlayer for authored fire/reload/ADS clips.")
	assert_true((rig_snapshot.get("animations", []) as Array).has("fire"), "FPSWeapon rig should include an authored fire animation.")
	assert_true((rig_snapshot.get("animations", []) as Array).has("reload"), "FPSWeapon rig should include an authored reload animation.")
	assert_true((rig_snapshot.get("animations", []) as Array).has("ads_in"), "FPSWeapon rig should include an authored ADS-in animation.")
	weapon.call("apply_temporary_overclock", 4.0, 0.78, 1.2)
	assert_true(float(weapon.get("overclock_timer")) > 0.0, "Weapon overclock should arm a timed fire-rate/damage modifier.")
	weapon.set("magazine_size", 12)
	weapon.set("ammo", 3)
	weapon.set("reserve", 0)
	assert_true(bool(weapon.call("try_reload")), "Infinite test ammo should allow reloads even when reserve is empty.")
	weapon.call("_finish_reload")
	assert_eq(int(weapon.get("ammo")), 12, "Infinite test ammo should still refill the magazine during reload UX checks.")
	assert_true(int(weapon.get("reserve")) >= 999, "Infinite test ammo should keep reserve stocked for repeated FPS testing.")
	weapon.set("infinite_test_ammo", false)
	weapon.set("ammo", 3)
	weapon.set("reserve", 20)
	assert_true(bool(weapon.call("try_reload")), "FPSWeapon should begin reloading when the magazine is not full and reserve ammo exists.")
	weapon.call("_finish_reload")
	assert_eq(int(weapon.get("ammo")), 12, "Reload should move reserve ammo into the magazine.")
	assert_eq(int(weapon.get("reserve")), 11, "Reload should spend the reserve ammo that filled the magazine.")
	assert_false(bool(weapon.get("reloading")), "Reload should clear the reloading flag when complete.")
	var drone_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSDrone.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var drone: Node = drone_script.new()
	drone.call("configure", {"name": "Needle Eye", "archetype": "ranged", "ranged_attack_range": 11.5}, Node3D.new(), Node.new())
	assert_eq(String(drone.get("archetype")), "ranged", "FPS enemies should support ranged archetypes.")
	assert_true(drone.has_method("apply_bait"), "FPS enemies should support bait/debuff ability hooks.")
	assert_true(String(drone.call("_get_archetype_label")).contains("RANGED"), "FPS enemy labels should explain combat role, not abstract names.")


func test_action_guide_vfx_loads() -> void:
	var vfx_script: GDScript = ResourceLoader.load("res://scripts/vfx/CombatVFX.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var vfx: Control = vfx_script.new()
	assert_true(vfx.has_method("play_click_beacon_on"), "CombatVFX should expose the action-guide click beacon.")
	assert_true(vfx.has_method("play_card_preview_arc"), "CombatVFX should expose hover preview arcs from hand to arena.")
	assert_true(vfx.has_method("play_link_between_targets"), "CombatVFX should expose target-card to pawn linking.")
	assert_true(vfx.has_method("play_ritual_glow_on"), "CombatVFX should expose the generated ritual glow sprite strip.")
	assert_true(vfx.has_method("play_card_burn_on"), "CombatVFX should expose the generated card burn sprite strip.")
	assert_true(vfx.has_method("get_sfx_asset_paths"), "CombatVFX should expose generated SFX asset paths.")


func test_action_beat_resolver_grades_aim_skill() -> void:
	var beat_script: GDScript = ResourceLoader.load("res://scripts/combat/ActionBeatResolver.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_true(beat_script is GDScript, "ActionBeatResolver should load as the card-to-action skill contract.")
	var attack_perfect: Dictionary = beat_script.resolve_aim(&"attack", 12.0, 42.0, 96.0, 164.0)
	var attack_hit: Dictionary = beat_script.resolve_aim(&"attack", 72.0, 42.0, 96.0, 164.0)
	var attack_graze: Dictionary = beat_script.resolve_aim(&"attack", 132.0, 42.0, 96.0, 164.0)
	var attack_miss: Dictionary = beat_script.resolve_aim(&"attack", 220.0, 42.0, 96.0, 164.0)
	assert_eq(String(attack_perfect.get("result", "")), "perfect", "Attack beat should grade centered aim as perfect.")
	assert_eq(String(attack_hit.get("result", "")), "hit", "Attack beat should grade solid aim as hit.")
	assert_eq(String(attack_graze.get("result", "")), "graze", "Attack beat should grade edge aim as graze.")
	assert_eq(String(attack_miss.get("result", "")), "miss", "Attack beat should miss outside the aim radius.")
	assert_true(float(attack_perfect.get("multiplier", 0.0)) > float(attack_hit.get("multiplier", 0.0)), "Perfect should beat normal hit.")


func test_action_skill_multiplier_changes_card_damage() -> void:
	var resolver_script: GDScript = ResourceLoader.load("res://scripts/combat/CombatResolver.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var resolver: Node = resolver_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker",
		"action_beat_result": "perfect",
		"action_multiplier": 1.35,
		"action_beat_label": "PERFECT"
	})
	var perfect_hp := _get_enemy_hp(resolver, &"skulker")
	assert_true(perfect_hp < 10, "Perfect Quick Slash should deal more than base damage; got Skulker HP %d." % perfect_hp)

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker",
		"action_beat_result": "miss",
		"action_multiplier": 0.0,
		"action_beat_label": "MISS"
	})
	var miss_hp := _get_enemy_hp(resolver, &"skulker")
	assert_eq(miss_hp, 14, "Missed Quick Slash should not damage Skulker.")


func test_armory_upgrade_context_changes_card_damage_and_guard() -> void:
	var resolver_script: GDScript = ResourceLoader.load("res://scripts/combat/CombatResolver.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var resolver: Node = resolver_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	var guard_up: Resource = load("res://resources/cards/guard_up.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker",
		"upgrade_damage_bonus": 2
	})
	assert_eq(_get_enemy_hp(resolver, &"skulker"), 8, "Armory damage bonus should make Quick Slash hit harder.")
	resolver.call("apply_card_with_context", guard_up, {"upgrade_guard_bonus": 3})
	var player_state: Dictionary = resolver.call("get_state").get("player", {})
	assert_eq(int(player_state.get("guard", 0)), 8, "Armory guard bonus should add to guard cards.")


func test_deck_manager_can_burn_cards_for_economy_flow() -> void:
	var deck_script: GDScript = ResourceLoader.load("res://scripts/cards/DeckManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var deck: Node = deck_script.new()
	deck.call("configure_deck", ["res://resources/cards/quick_slash.tres"])
	deck.call("reset_deck")
	deck.call("draw_cards", 1)
	var burned: Resource = deck.call("burn_card_at", 0)
	assert_true(burned is Resource, "Burning should remove and return a hand card.")
	var counts: Dictionary = deck.call("get_counts")
	assert_eq(int(counts.get("hand", -1)), 0, "Burned card should leave hand.")
	assert_eq(int(counts.get("exhaust", -1)), 1, "Burned card should enter exhaust as spent economy fuel.")


func test_deck_manager_can_slot_cards_into_loadout_flow() -> void:
	var deck_script: GDScript = ResourceLoader.load("res://scripts/cards/DeckManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var deck: Node = deck_script.new()
	deck.call("configure_deck", ["res://resources/cards/quick_slash.tres", "res://resources/cards/sidestep.tres"])
	deck.call("reset_deck")
	deck.call("draw_cards", 2)
	var slotted: Resource = deck.call("slot_card_at", 0)
	assert_true(slotted is Resource, "Slotting should remove and return a hand card.")
	var counts: Dictionary = deck.call("get_counts")
	assert_eq(int(counts.get("hand", -1)), 1, "Slotted card should leave hand.")
	assert_eq(int(counts.get("loadout", -1)), 1, "Slotted card should enter the loadout pile.")
	assert_eq(int(counts.get("discard", -1)), 0, "Slotted card should not look like a normal discard.")
	var replacement: Resource = deck.call("replace_loadout_card_at", 0, slotted)
	assert_true(replacement is Resource, "Replacing should remove and return another hand card.")
	counts = deck.call("get_counts")
	assert_eq(int(counts.get("hand", -1)), 1, "Replacing should return the old loadout card to hand.")
	assert_eq(int(counts.get("loadout", -1)), 1, "Replacing should keep one active loadout card.")
	var snapshot: Dictionary = deck.call("get_snapshot")
	assert_eq((snapshot.get("loadout_pile_paths", []) as Array).size(), 1, "Deck snapshots should preserve slotted loadout cards.")
	var resolved: Array = deck.call("resolve_loadout_pile")
	assert_eq(resolved.size(), 1, "Resolving loadout should return the slotted cards.")
	counts = deck.call("get_counts")
	assert_eq(int(counts.get("loadout", -1)), 0, "Resolved loadout cards should leave the loadout pile.")
	var restored_deck: Node = deck_script.new()
	restored_deck.call("restore_snapshot", snapshot)
	var restored_counts: Dictionary = restored_deck.call("get_counts")
	assert_eq(int(restored_counts.get("loadout", -1)), 1, "Deck restore should recover the loadout pile.")


func test_run_manager_can_snapshot_restore_and_mark_arena_defeat() -> void:
	var run_script: GDScript = ResourceLoader.load("res://scripts/run/RunManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var run_manager: Node = run_script.new()
	run_manager.call("reset_run", "hex_sharpshooter")
	var class_state: Dictionary = run_manager.call("get_state")
	assert_eq(String(class_state.get("hero_class", "")), "hex_sharpshooter", "Run reset should preserve the selected hero class.")
	var hex_deck: Array = run_manager.call("get_deck_paths")
	assert_eq(hex_deck.size(), 10, "Class starter decks should keep the first-run deck size stable.")
	assert_true(hex_deck.has("res://resources/cards/marked_card.tres"), "Hex Sharpshooter should start with a read-focused card.")
	assert_true(hex_deck.has("res://resources/cards/tripwire.tres"), "Hex Sharpshooter should start with a trap-focused card.")
	var snapshot: Dictionary = run_manager.call("get_snapshot")
	run_manager.call("apply_arena_defeat", {"damage_taken": 99})
	var defeat_state: Dictionary = run_manager.call("get_state")
	assert_eq(String(defeat_state.get("run_outcome", "")), "defeat", "Arena defeat should mark the run as lost.")
	run_manager.call("restore_snapshot", snapshot)
	var restored_state: Dictionary = run_manager.call("get_state")
	assert_eq(String(restored_state.get("run_outcome", "")), "running", "Run restore should recover the pre-arena outcome.")
	assert_eq(String(restored_state.get("hero_class", "")), "hex_sharpshooter", "Run restore should recover the selected hero class.")
	assert_eq(int(restored_state.get("player_hp", -1)), 30, "Run restore should recover player Blood.")


func test_opening_fighter_copy_explains_class_identity() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	controller.set("selected_hero_class_id", "gambler_knight")
	assert_true(String(controller.call("_get_opening_prompt_text")).contains("DEAL IN"), "Opening prompt should point to Deal In without needing a debug click badge.")
	var gambler_entry: Dictionary = controller.call("_get_hero_class_entry", "gambler_knight")
	var hex_entry: Dictionary = controller.call("_get_hero_class_entry", "hex_sharpshooter")
	var blood_entry: Dictionary = controller.call("_get_hero_class_entry", "blood_wager")
	assert_true(String(gambler_entry.get("portrait", "")).contains("portrait"), "Gambler-Knight should use portrait art in the opening selector.")
	assert_true(String(controller.call("_get_class_passive_text", gambler_entry)).contains("armor"), "Gambler-Knight copy should explain the armor/cooldown passive.")
	assert_true(String(controller.call("_get_class_card_short_text", hex_entry)).contains("traps"), "Hex Sharpshooter copy should explain control deck identity.")
	assert_true(String(controller.call("_get_class_card_short_text", blood_entry)).contains("Blood"), "Blood Wager copy should explain risky blood identity.")


func test_combat_controller_exports_shooter_loadout_payload() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	var sidestep: Resource = load("res://resources/cards/sidestep.tres")
	controller.set("shooter_chips", 4)
	controller.set("arena_carryover_armor", 6)
	controller.set("arena_carryover_ammo", 9)
	controller.set("arena_weapon_damage_bonus", 2)
	controller.set("selected_hero_class_id", "blood_wager")
	controller.set("active_reward_mods", [{"label": "Runner Edge", "kind": "damage", "bias_modes": ["extract", "duel"], "rarity": "Uncommon"}])
	controller.set("card_upgrade_mods", {"quick_slash": {"level": 2, "mutation": "Deadeye", "spent_xp": 11}})
	controller.set("arena_card_xp_pool", 7)
	controller.set("arena_wounds_total", 1)
	controller.set("loadout_slots", {"weapon": quick_slash, "ability_1": sidestep})
	var payload: Dictionary = controller.call("_build_combat_bridge_payload")
	assert_eq(String(payload.get("weapon_card", "")), "quick_slash", "Weapon slot should become the shooter weapon card.")
	assert_eq(String(payload.get("hero_class", "")), "blood_wager", "Bridge payload should include the selected hero class.")
	var loadout: Array = payload.get("loadout", [])
	assert_eq(loadout.size(), 2, "Bridge payload should include structured slot records.")
	var weapon: Dictionary = loadout[0]
	assert_true(weapon.has("weapon") or (loadout[1] as Dictionary).has("weapon"), "Attack cards should export a weapon profile.")
	var economy: Dictionary = payload.get("economy", {})
	assert_true(int(economy.get("ammo", 0)) > 20, "Attack cards and carryover should increase arena ammo.")
	assert_eq(int(economy.get("armor", 0)), 4, "Wounds should reduce carryover armor before the next arena.")
	var bonuses: Dictionary = payload.get("payout_bonuses", {})
	assert_eq(int(bonuses.get("weapon_damage", 0)), 2, "Arena damage payout should be visible in the payload.")
	assert_eq((payload.get("reward_mods", []) as Array).size(), 1, "Bridge payload should carry earned arena reward mods.")
	assert_eq((payload.get("card_upgrades", {}) as Dictionary).size(), 1, "Bridge payload should carry bought card upgrades.")
	assert_eq(int((payload.get("progression", {}) as Dictionary).get("card_xp_pool", 0)), 7, "Bridge payload should carry card XP progression.")
	assert_eq(int(((payload.get("progression", {}) as Dictionary).get("wound_penalties", {}) as Dictionary).get("draw_penalty", 0)), 1, "Bridge payload should expose wound draw penalties.")
	assert_eq(String(payload.get("objective_mode", "")), "extract", "Movement-heavy loadouts should recommend the Extract FPS objective.")
	var weapon_payload: Dictionary = (loadout[0] as Dictionary).get("weapon", {}) if (loadout[0] as Dictionary).has("weapon") else (loadout[1] as Dictionary).get("weapon", {})
	assert_true(int(weapon_payload.get("damage", 0)) >= 34, "Arena payout and armory upgrades should boost the next weapon profile.")
	assert_eq(String((weapon_payload.get("upgrade", {}) as Dictionary).get("mutation", "")), "Deadeye", "Weapon payload should expose the selected card mutation.")


func test_combat_controller_buys_armory_upgrades_and_mutations() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	controller.set("arena_card_xp_pool", 24)
	var upgraded: Dictionary = controller.call("_apply_card_upgrade_purchase", quick_slash, false)
	assert_true(bool(upgraded.get("ok", false)), "Card XP should buy a selected card upgrade.")
	var mutated: Dictionary = controller.call("_apply_card_upgrade_purchase", quick_slash, true)
	assert_true(bool(mutated.get("ok", false)), "Card XP should buy a card mutation.")
	var upgrades: Dictionary = controller.get("card_upgrade_mods")
	assert_eq(int((upgrades.get("quick_slash", {}) as Dictionary).get("level", 0)), 1, "Armory upgrade should persist by card id.")
	assert_eq(String((upgrades.get("quick_slash", {}) as Dictionary).get("mutation", "")), "Deadeye", "Attack cards should mutate into Deadeye.")
	var weapon_payload: Dictionary = controller.call("_get_shooter_card_payload", quick_slash, "weapon")
	assert_true(int((weapon_payload.get("weapon", {}) as Dictionary).get("damage", 0)) > 28, "Mutated weapon cards should export stronger FPS weapon damage.")
	var context: Dictionary = controller.call("_get_card_upgrade_context", quick_slash)
	assert_true(int(context.get("upgrade_damage_bonus", 0)) >= 3, "Card table context should carry upgrade damage.")


func test_combat_controller_recommends_objective_aware_loadout_cards() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var deck_script: GDScript = ResourceLoader.load("res://scripts/cards/DeckManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var deck: Node = deck_script.new()
	deck.call("restore_snapshot", {
		"hand_paths": [
			"res://resources/cards/quick_slash.tres",
			"res://resources/cards/sidestep.tres",
			"res://resources/cards/guard_up.tres"
		]
	})
	controller.set("deck_manager", deck)
	controller.set("shooter_chips", 4)
	var sidestep: Resource = load("res://resources/cards/sidestep.tres")
	var recommendation: Dictionary = controller.call("_get_card_objective_recommendation", sidestep, "extract")
	assert_true(String(recommendation.get("badge", "")).contains("EXTRACT"), "Movement cards should show Extract recommendation badges.")
	assert_eq(String(controller.call("_get_recommended_objective_for_current_hand")), "extract", "A hand with movement should recommend the Extract arena objective.")
	controller.call("_on_recommend_loadout_pressed")
	var slots: Dictionary = controller.get("loadout_slots")
	assert_true(slots.has("weapon"), "Recommend Loadout should slot an affordable weapon when one exists.")
	assert_true(slots.has("ability_1"), "Recommend Loadout should slot the objective card as an ability.")
	assert_eq(String(controller.call("_get_loadout_objective_mode")), "extract", "Auto-slotted movement should drive the FPS objective.")
	controller.set("selected_hero_class_id", "hex_sharpshooter")
	var return_state: Dictionary = controller.call("_build_arena_return_state")
	assert_eq(String(return_state.get("selected_hero_class_id", "")), "hex_sharpshooter", "Arena return state should preserve selected hero class.")


func test_combat_controller_can_attach_and_replace_loadout_slot_cards() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var deck_script: GDScript = ResourceLoader.load("res://scripts/cards/DeckManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var deck: Node = deck_script.new()
	deck.call("restore_snapshot", {
		"hand_paths": [
			"res://resources/cards/quick_slash.tres",
			"res://resources/cards/low_stab.tres",
			"res://resources/cards/sidestep.tres"
		]
	})
	controller.set("deck_manager", deck)
	controller.set("shooter_chips", 4)
	controller.set("run_flow_state", "combat")
	controller.set("debug_controls_visible", false)
	controller.set("arena_payout_pending", false)

	var first: Dictionary = controller.call("_slot_hand_card_at", 0, "weapon")
	assert_true(bool(first.get("ok", false)), "Manual slot click should attach the selected attack card to Gun.")
	var replaced: Dictionary = controller.call("_slot_hand_card_at", 0, "weapon")
	assert_true(bool(replaced.get("ok", false)), "Clicking a filled slot with another valid card should replace it.")
	assert_true(replaced.get("replaced_card", null) is Resource, "Replacing should report the card returned to hand.")
	var ability: Dictionary = controller.call("_slot_hand_card_at", 0, "ability_1")
	assert_true(bool(ability.get("ok", false)), "Manual slot click should attach a movement card to Q ability.")
	var slots: Dictionary = controller.get("loadout_slots")
	assert_true(slots.has("weapon") and slots.has("ability_1"), "Manual attachment should build the FPS kit fields.")
	assert_eq(int(deck.call("get_counts").get("loadout", -1)), 2, "Replacing should not leave stale cards in the loadout pile.")


func test_compact_fps_loadout_screen_keeps_counts_and_hand_scroll_stable() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var hand_view_script: GDScript = ResourceLoader.load("res://scripts/ui/HandView.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	var sidestep: Resource = load("res://resources/cards/sidestep.tres")
	var focus := Label.new()
	var next_badge := Label.new()
	controller.set("run_flow_state", "combat")
	controller.set("debug_controls_visible", false)
	controller.set("arena_payout_pending", false)
	controller.set("battlefield_focus_label", focus)
	controller.set("combat_action_badge_label", next_badge)
	controller.set("loadout_slots", {"weapon": quick_slash, "ability_1": sidestep})
	controller.call("_refresh_loadout_ui")
	assert_true(String(focus.text).contains("KIT 2/5"), "Compact FPS loadout header should use the live slotted-card count.")
	assert_eq(String(next_badge.text), "NEXT: ENTER FPS", "Once a kit has cards, the compact next action should point to Enter FPS.")

	var hand_scroll := ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	var hand_view: HBoxContainer = hand_view_script.new()
	hand_scroll.add_child(hand_view)
	controller.add_child(hand_scroll)
	controller.set("hand_view", hand_view)
	hand_scroll.scroll_horizontal = 240
	var compact_hand: Array = []
	compact_hand.append(quick_slash)
	controller.call("_apply_hand_cards", compact_hand)
	assert_eq(hand_scroll.scroll_horizontal, 0, "Changing/removing hand cards should reset the compact hand scroll so cards do not appear cut off.")

	var slot_grid := GridContainer.new()
	slot_grid.size = Vector2(620, 100)
	controller.set("loadout_slot_row", slot_grid)
	var action_grid := GridContainer.new()
	action_grid.size = Vector2(720, 100)
	controller.set("hand_action_button_row", action_grid)
	controller.call("_refresh_loadout_responsive_layout")
	assert_eq(slot_grid.columns, 2, "Loadout slots should wrap before they overflow narrow screens.")
	assert_eq(action_grid.columns, 2, "Loadout action buttons should wrap on tablet-width panels.")

	var playability: Dictionary = controller.call("_get_card_playability_entry", quick_slash, {})
	assert_true(bool(playability.get("playable", false)), "Compact kit build should allow card selection even when the tactical play phase is locked.")


func test_arena_payout_records_reward_mods_and_progression() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var run_script: GDScript = ResourceLoader.load("res://scripts/run/RunManager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var run_manager: Node = run_script.new()
	run_manager.call("reset_run")
	controller.set("run_manager", run_manager)
	var effects: Array = controller.call("_apply_arena_payout_effects", {
		"source": "fps_arena",
		"cleared": true,
		"kills": 3,
		"objective_mode": "extract",
		"objective_label": "Extract",
		"objective_completed": true,
		"objective_score": 94,
		"ability_uses": {"dash": 1, "guard": 1},
		"wounds_taken": 1,
		"selected_reward": {
			"label": "Runner Edge",
			"kind": "damage",
			"amount": 2,
			"chip_bonus": 4,
			"rarity": "Uncommon",
			"bias_modes": ["extract", "duel"],
			"summary": "Dash-heavy clears turn into sharper opening weapon pressure."
		}
	})
	var mods: Array = controller.get("active_reward_mods")
	assert_eq(mods.size(), 1, "Arena payout should create a persistent reward mod.")
	assert_eq(String((mods[0] as Dictionary).get("label", "")), "Runner Edge", "Reward mod should preserve the authored reward label.")
	var artifacts: Array = controller.call("_get_reward_artifact_snapshots")
	assert_eq(artifacts.size(), 1, "Arena reward mods should surface as inspectable artifacts.")
	assert_eq(String((artifacts[0] as Dictionary).get("icon", "")), "DMG", "Damage rewards should render with a readable artifact icon.")
	assert_eq(String((artifacts[0] as Dictionary).get("rarity", "")), "Uncommon", "Artifact cards should preserve rarity for their frame styling.")
	assert_true(String(controller.call("_get_reward_artifact_detail_text", 0)).contains("Runner Edge"), "Artifact inspection copy should name the selected reward.")
	assert_true(int(controller.get("arena_card_xp_pool")) >= 9, "Arena payout should bank Card XP from kills, objectives, and ability use.")
	assert_eq(int(controller.get("arena_wounds_total")), 1, "Arena payout should track wounds from the FPS result.")
	assert_true(String("\n".join(effects)).contains("Mod acquired"), "Payout effects should announce the new mod.")
	assert_true(String("\n".join(effects)).contains("Wound burden"), "Payout effects should explain wound tax, draw, and armor pressure.")
	assert_true(int(controller.call("_get_payout_objective_bias_score", "extract")) > 0, "Reward mods should bias future objective recommendations.")
	var run_state: Dictionary = run_manager.call("get_state")
	assert_false((run_state.get("reward_history", []) as Array).is_empty(), "Arena reward mods should be written to run reward history.")


func test_arena_reward_artifacts_accept_plain_bias_arrays() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var artifact_row := HBoxContainer.new()
	var artifact_detail := RichTextLabel.new()
	controller.set("reward_artifact_row", artifact_row)
	controller.set("reward_artifact_detail_label", artifact_detail)
	controller.set("active_reward_mods", [{
		"label": "Runner Edge",
		"kind": "damage",
		"amount": 2,
		"rarity": "Uncommon",
		"bias_modes": ["extract", "duel"],
		"summary": "Plain Array bias modes should still render."
	}])
	controller.call("_refresh_reward_artifact_cards")
	var artifacts: Array = controller.call("_get_reward_artifact_snapshots")
	assert_eq(artifacts.size(), 1, "Reward artifacts should build from plain Dictionary arrays.")
	assert_true(String(artifact_detail.text).contains("EXTRACT"), "Reward artifact detail should render converted bias modes.")
	assert_true(artifact_row.get_child_count() > 0, "Reward artifact buttons should render without typed-array assignment errors.")


func test_arena_bridge_stores_and_hands_payload_to_fps() -> void:
	var bridge_script: GDScript = ResourceLoader.load("res://scripts/combat/ArenaBridge.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_true(bridge_script is GDScript, "ArenaBridge autoload script should load.")
	var bridge: Node = bridge_script.new()
	var payload := {
		"weapon_card": "quick_slash",
		"loadout": [{"slot": "weapon", "id": "quick_slash", "weapon": {"name": "Ace Cutter Revolver", "damage": 28, "magazine": 6, "fire_rate": 3.2}}],
		"economy": {"chips": 3, "armor": 4, "ammo": 30},
		"reads": {"target_enemy": &"skulker", "threat": "Cut Purse 45%"}
	}
	bridge.call("set_payload", payload, "res://scenes/combat/TestCombat.tscn", {"shooter_chips": 9})
	assert_true(bool(bridge.call("has_pending_payload")), "Bridge should report a pending arena payload.")
	assert_true(bool(bridge.call("has_pending_return_state")), "Bridge should carry card-table return state with the payload.")
	var taken: Dictionary = bridge.call("take_payload")
	assert_eq(String(taken.get("weapon_card", "")), "quick_slash", "Bridge should hand the same weapon card to FPS.")
	assert_false(bool(bridge.call("has_pending_payload")), "Taking the payload should clear the pending handoff.")
	var return_state: Dictionary = bridge.call("take_return_state")
	assert_eq(int(return_state.get("shooter_chips", 0)), 9, "Bridge should hand return state back to the card table.")
	assert_false(bool(bridge.call("has_pending_return_state")), "Taking return state should clear the pending return state.")
	bridge.call("set_result", {"source": "fps_arena", "chips_awarded": 7, "cards_to_draw": 5})
	assert_true(bool(bridge.call("has_pending_result")), "Bridge should report a pending arena result.")
	var result: Dictionary = bridge.call("take_result")
	assert_eq(int(result.get("chips_awarded", 0)), 7, "Bridge should hand the same FPS result back to the card table.")
	assert_false(bool(bridge.call("has_pending_result")), "Taking the result should clear the pending return payload.")


func test_arena_bridge_clears_stale_dev_tool_handoffs() -> void:
	var bridge_script: GDScript = ResourceLoader.load("res://scripts/combat/ArenaBridge.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var bridge: Node = bridge_script.new()

	bridge.call("set_payload", {"weapon_card": "quick_slash"}, "res://scenes/combat/TestCombat.tscn", {"shooter_chips": 9})
	bridge.call("set_result", {"source": "dev_hub", "chips_awarded": 1})
	assert_false(bool(bridge.call("has_pending_payload")), "Dev-tool results should clear stale FPS payloads.")
	assert_false(bool(bridge.call("has_pending_return_state")), "Dev-tool results should not restore an old card-table snapshot.")

	bridge.call("set_result", {"source": "dev_hub", "chips_awarded": 2})
	bridge.call("set_payload", {"weapon_card": "low_stab"}, "res://scenes/combat/TestCombat.tscn")
	assert_true(bool(bridge.call("has_pending_payload")), "New FPS payload should still be available.")
	assert_false(bool(bridge.call("has_pending_result")), "New FPS payload should clear stale dev-tool results.")
	assert_false(bool(bridge.call("has_pending_return_state")), "Payloads without return snapshots should clear stale return state.")

	bridge.call("set_payload", {"weapon_card": "quick_slash"}, "res://scenes/combat/TestCombat.tscn", {"shooter_chips": 12})
	bridge.call("take_payload")
	bridge.call("set_result", {"source": "fps_arena", "chips_awarded": 4})
	assert_true(bool(bridge.call("has_pending_return_state")), "FPS arena results should preserve the card-table return snapshot.")


func test_fps_prototype_consumes_bridge_payload_as_active_loadout() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	prototype.call("apply_arena_bridge_payload", {
		"weapon_card": "quick_slash",
		"ability_cards": ["sidestep"],
		"objective_mode": "extract",
		"loadout": [
			{"slot": "weapon", "id": "quick_slash", "weapon": {"name": "Ace Cutter Revolver", "damage": 28, "magazine": 6, "fire_rate": 3.2}},
			{"slot": "ability_1", "id": "sidestep", "ability": {"kind": "dash", "charges": 1}}
		],
		"economy": {"chips": 5, "armor": 7, "ammo": 36},
		"reward_mods": [{"label": "Runner Edge"}],
		"card_upgrades": {"quick_slash": {"level": 1, "mutation": "Deadeye"}},
		"progression": {"card_xp_pool": 9, "wounds_total": 1, "wound_penalties": {"draw_penalty": 1, "armor_penalty": 2, "chip_tax": 1}},
		"reads": {"target_enemy": &"skulker", "threat": "Cut Purse 45%"}
	})
	var summary: Dictionary = prototype.call("get_active_loadout_summary")
	assert_eq(String(summary.get("weapon", "")), "Ace Cutter Revolver", "FPS should expose the bridge weapon as active.")
	assert_eq(int(summary.get("abilities", 0)), 1, "FPS should expose bridged ability count.")
	assert_eq(int(summary.get("armor", 0)), 9, "FPS should expose bridged armor plus the default hero class armor.")
	assert_eq(int(summary.get("ammo", 0)), 36, "FPS should expose bridged ammo.")
	assert_eq(int(summary.get("reward_mods", 0)), 1, "FPS loadout summary should expose carried arena reward mods.")
	assert_eq(int(summary.get("card_upgrades", 0)), 1, "FPS loadout summary should expose card upgrade count.")
	assert_eq(int(summary.get("card_xp_pool", 0)), 9, "FPS loadout summary should expose card XP progression.")
	assert_eq(int(summary.get("wounds_total", 0)), 1, "FPS loadout summary should expose wound totals.")
	assert_eq(String(summary.get("objective_mode", "")), "extract", "FPS loadout summary should include the selected objective mode.")
	var objective_state: Dictionary = prototype.call("get_objective_state")
	assert_eq(String(objective_state.get("mode", "")), "extract", "FPS should apply the objective mode from the bridge payload.")
	assert_true(float(objective_state.get("extract_time_limit", 0.0)) > 0.0, "Extract objective should expose its timed escape window.")
	var objective_modes: Array = prototype.call("get_objective_modes")
	assert_true(objective_modes.has("hold_pot") and objective_modes.has("boss_gate"), "FPS should expose Hold Pot through Boss Gate objective tests.")
	prototype.set("kills", 3)
	prototype.set("shots_fired", 6)
	prototype.set("shots_hit", 4)
	prototype.set("damage_taken", 10)
	prototype.set("objective_completed", true)
	var result_preview: Dictionary = prototype.call("get_arena_result_preview", 0)
	assert_eq(String(result_preview.get("source", "")), "fps_arena", "FPS payout previews should identify the arena source.")
	assert_eq(String(result_preview.get("hero", "")), "Gambler-Knight", "FPS payout previews should include hero class reporting.")
	assert_true(result_preview.has("ability_uses"), "FPS payout previews should include ability-use reporting.")
	assert_eq(String(result_preview.get("outcome", "")), "win", "FPS payout previews should include a win outcome.")
	assert_eq(String(result_preview.get("objective_mode", "")), "extract", "FPS payout previews should carry the objective mode.")
	assert_true(bool(result_preview.get("objective_completed", false)), "FPS payout previews should carry objective completion.")
	assert_true(int(result_preview.get("objective_score", 0)) > 0, "FPS payout previews should include objective scoring.")
	assert_eq(String((result_preview.get("selected_reward", {}) as Dictionary).get("label", "")), "Runner Edge", "FPS payout previews should include objective-authored rewards.")
	assert_eq(String((result_preview.get("selected_reward", {}) as Dictionary).get("kind", "")), "damage", "Extract's first payout should still feed future weapon damage decisions.")
	assert_eq(String((result_preview.get("selected_reward", {}) as Dictionary).get("rarity", "")), "Uncommon", "FPS payout previews should expose reward mod rarity.")
	assert_false(((result_preview.get("selected_reward", {}) as Dictionary).get("bias_modes", []) as Array).is_empty(), "FPS payout previews should expose reward mod objective bias.")
	assert_true(int(result_preview.get("chips_awarded", 0)) >= 10, "FPS payout previews should calculate a useful chip award.")


func test_fps_wave_defs_scale_and_rotate_objectives() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	prototype.call("apply_arena_bridge_payload", {"objective_mode": "hold_pot"})
	prototype.set("wave_index", 1)
	prototype.call("_set_objective_mode", "hold_pot")
	var first_wave_defs: Array = prototype.call("_get_objective_enemy_defs")
	prototype.set("wave_index", 4)
	prototype.call("_set_objective_mode", "defend")
	var later_wave_defs: Array = prototype.call("_get_objective_enemy_defs")
	assert_true(first_wave_defs.size() >= 6, "FPS waves should start with enough enemies to avoid instant clears.")
	assert_true(later_wave_defs.size() > first_wave_defs.size(), "Later FPS waves should scale longer than wave one.")
	assert_eq(String(prototype.call("_get_wave_objective_mode", 2)), "extract", "FPS wave two should rotate away from the starting objective.")
	assert_eq(String(prototype.call("_get_wave_objective_mode", 5)), "boss_gate", "FPS objective rotation should eventually reach the boss gate.")


func test_fps_wave_reward_continues_arena_loop() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	prototype.call("apply_arena_bridge_payload", {
		"objective_mode": "hold_pot",
		"loadout": [
			{"slot": "weapon", "id": "quick_slash", "weapon": {"name": "Loop Revolver", "damage": 20, "magazine": 6, "fire_rate": 3.0}}
		],
		"economy": {"chips": 5, "armor": 2, "ammo": 30},
		"progression": {"card_xp_pool": 0, "wounds_total": 0}
	})
	prototype.set("wave_index", 1)
	prototype.set("kills", 6)
	prototype.set("current_wave_kills", 6)
	prototype.set("shots_fired", 10)
	prototype.set("shots_hit", 7)
	prototype.set("objective_completed", true)
	var reward := {
		"label": "Center Cut",
		"kind": "damage",
		"amount": 3,
		"chip_bonus": 2,
		"rarity": "Uncommon",
		"bias_modes": ["hold_pot", "duel"],
		"summary": "Test reward."
	}
	var result: Dictionary = prototype.call("_build_arena_result", reward, true)
	prototype.call("_continue_after_wave_reward", reward, result)
	var summary: Dictionary = prototype.call("get_active_loadout_summary")
	var weapon_profile: Dictionary = prototype.get("active_weapon_profile")
	assert_eq(int(prototype.get("wave_index")), 2, "Reward selection should advance to wave two without leaving the arena.")
	assert_eq(String(prototype.get("objective_mode")), "extract", "Continuing after a reward should rotate the next objective.")
	assert_false(bool(prototype.get("rewards_pending")), "Reward selection should close the pending reward state.")
	assert_false(bool(prototype.get("reward_return_in_progress")), "Reward selection should finish its in-arena transition.")
	assert_eq(int(summary.get("reward_mods", 0)), 1, "In-arena rewards should stay on the active loadout.")
	assert_true(int(summary.get("chips", 0)) > 5, "In-arena rewards should bank wave chips into the active economy.")
	assert_eq(int(weapon_profile.get("damage", 0)), 23, "Damage rewards should immediately update the current kit.")
	assert_true(int(summary.get("card_xp_pool", 0)) > 0, "In-arena rewards should preserve progression momentum.")


func test_tactical_map_changes_damage_and_cover() -> void:
	var map_script: GDScript = ResourceLoader.load("res://scripts/grid/TacticalMapDefinition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var map_data: Dictionary = map_script.get_default_map()
	var resolver_script: GDScript = ResourceLoader.load("res://scripts/combat/CombatResolver.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var resolver: Node = resolver_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_card_with_context", quick_slash, {
		"target_enemy_id": &"skulker",
		"target_enemy_name": "Skulker",
		"map_context": map_script.build_context(map_data, Vector2i(1, 1))
	})
	assert_eq(_get_enemy_hp(resolver, &"skulker"), 9, "Center Pot should make Quick Slash deal 5 damage.")

	resolver.call("reset_combat", ENEMY_PATHS)
	resolver.call("apply_revealed_intents_with_context", [{
		"enemy_id": &"brute",
		"enemy_name": "Brute",
		"intent_id": &"brute_smash",
		"intent_name": "Skull Smash",
		"target_lane": 0,
		"payload": {"damage": 8}
	}], {
		"player_lane": 0,
		"map_context": map_script.build_context(map_data, Vector2i(0, 2))
	})
	assert_eq(int(resolver.call("get_state").get("player", {}).get("hp", -1)), 24, "Back Cover should reduce the lane hit by 2.")


func test_main_flow_uses_card_table_not_tactical_board_identity() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var identity_text := String(controller.call("_get_arena_prep_identity_text"))
	assert_true(identity_text.contains("THE HAND IS THE RUN"), "Main flow should explain that cards are the primary game layer.")
	assert_true(identity_text.contains("gun, Q ability, E ability, passive, and risk"), "Card table identity should map the original card game into the FPS kit.")
	assert_false(identity_text.contains("POT MID"), "Main table identity should not ask the player to parse tactical cell callouts.")
	controller.set("run_flow_state", "combat")
	controller.set("debug_controls_visible", false)
	controller.set("arena_payout_pending", false)
	assert_true(bool(controller.call("_should_show_player_card_table")), "Normal combat flow should show the card kit table.")
	assert_false(bool(controller.call("_should_show_debug_tactical_board")), "Normal combat flow should hide the tactical board.")
	controller.set("debug_controls_visible", true)
	assert_false(bool(controller.call("_should_show_player_card_table")), "Opening debug should replace the kit table.")
	assert_true(bool(controller.call("_should_show_debug_tactical_board")), "Tactical board should only return as a debug surface.")

	var map_script: GDScript = ResourceLoader.load("res://scripts/grid/TacticalMapDefinition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var map_data: Dictionary = map_script.get_default_map()
	var grid_script: GDScript = ResourceLoader.load("res://scripts/grid/CombatGrid.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var grid: Control = grid_script.new()
	grid.set("map_data", map_data)
	grid.call("_ready")
	var table_title := grid.find_child("TableTitle", true, false)
	assert_true(table_title is Label and String((table_title as Label).text).contains("Debug Tactical Grid"), "Tactical grid should be clearly marked as debug support.")
	grid.queue_free()

	var cell_script: GDScript = ResourceLoader.load("res://scripts/grid/GridCellView.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var cell: Button = cell_script.new()
	cell.call("configure", Vector2i(1, 1))
	cell.call("configure_map_feature", map_script.get_cell_feature(map_data, Vector2i(1, 1)))
	assert_true(String(cell.text).contains("POT"), "Debug grid cells can still expose the underlying tactical map data.")
	cell.free()


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


func _get_enemy_hp(resolver: Node, enemy_id: StringName) -> int:
	var state: Dictionary = resolver.call("get_state")
	var enemies: Array = state.get("enemies", [])
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy
		if StringName(enemy_data.get("id", &"")) == enemy_id:
			return int(enemy_data.get("hp", -1))
	return -1
