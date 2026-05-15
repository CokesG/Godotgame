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
	assert_true(player.has_method("get_horizontal_speed_ratio"), "FPSPlayer should expose movement spread tuning.")
	assert_true(weapon.has_method("try_fire"), "FPSWeapon should expose fire attempts.")
	assert_true(weapon.has_method("try_reload"), "FPSWeapon should expose reload attempts.")
	assert_true(drone.has_method("take_damage"), "FPSDrone should expose damage intake.")
	assert_true(drone.has_method("is_critical_hit"), "FPSDrone should expose crit zones.")
	assert_true(prototype.has_method("spawn_tracer"), "FPSPrototype should expose shot tracers.")
	assert_true(prototype.has_method("get_living_enemies"), "FPSPrototype should expose encounter state.")
	assert_true(prototype.has_method("get_map_summary"), "FPSPrototype should expose Crossfire map summary.")
	assert_true(prototype.has_method("get_map_regions"), "FPSPrototype should expose authored tactical map regions.")
	assert_true(prototype.has_method("get_ability_state"), "FPSPrototype should expose bridged FPS ability state.")
	assert_true(prototype.has_method("get_arena_result_preview"), "FPSPrototype should expose arena result payout previews.")
	assert_true(player.has_method("dash_forward"), "FPSPlayer should expose card-driven dash.")
	assert_true(player.has_method("add_armor"), "FPSPlayer should expose card-driven armor gain.")
	assert_true(drone.has_method("reveal_for"), "FPSDrone should expose read-card reveal.")
	assert_true(drone.has_method("apply_snare"), "FPSDrone should expose trap-card snare.")


func test_fps_pivot_uses_existing_visual_assets() -> void:
	var fps_asset_paths := [
		"res://art/game/enemies/enemy_skulker.png",
		"res://art/game/enemies/enemy_brute.png",
		"res://art/game/enemies/enemy_needle_eye.png",
		"res://art/game/enemies/enemy_hexmonger.png"
	]
	for asset_path in fps_asset_paths:
		assert_true(FileAccess.file_exists(String(asset_path)), "%s should be available for FPS enemy billboards." % asset_path)


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


func test_fps_settings_crosshair_and_ability_contracts() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	assert_true(prototype.has_method("toggle_settings_menu"), "FPSPrototype should expose the Escape settings overlay.")
	assert_true(prototype.has_method("is_gameplay_paused"), "FPSPrototype should expose settings/reward pause state.")
	assert_true(prototype.has_method("_apply_encoded_binding"), "FPSPrototype settings should support persisted keybind rebinding.")
	assert_true(prototype.has_method("_get_action_binding_text"), "FPSPrototype settings should show readable binding text.")
	assert_true(prototype.has_method("_reset_action_binding"), "FPSPrototype settings should allow per-action default resets.")
	assert_true(prototype.has_method("_find_binding_conflict"), "FPSPrototype settings should detect duplicate keybinds.")
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
		"loadout": [{"slot": "ability_1", "id": "sidestep", "ability": {"kind": "dash", "cooldown": 6.0}}],
		"economy": {"chips": 0, "armor": 0, "ammo": 24}
	})
	var ability_state: Array = prototype.call("get_ability_state")
	assert_eq(ability_state.size(), 1, "FPSPrototype should expose active Q/E ability state.")
	assert_true(bool((ability_state[0] as Dictionary).get("ready", false)), "Slotted abilities should start ready.")


func test_fps_weapon_overclock_and_enemy_archetypes() -> void:
	var weapon_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSWeapon.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var weapon: Node = weapon_script.new()
	weapon.call("apply_temporary_overclock", 4.0, 0.78, 1.2)
	assert_true(float(weapon.get("overclock_timer")) > 0.0, "Weapon overclock should arm a timed fire-rate/damage modifier.")
	weapon.set("magazine_size", 12)
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
	deck.call("configure_deck", ["res://resources/cards/quick_slash.tres"])
	deck.call("reset_deck")
	deck.call("draw_cards", 1)
	var slotted: Resource = deck.call("slot_card_at", 0)
	assert_true(slotted is Resource, "Slotting should remove and return a hand card.")
	var counts: Dictionary = deck.call("get_counts")
	assert_eq(int(counts.get("hand", -1)), 0, "Slotted card should leave hand.")
	assert_eq(int(counts.get("loadout", -1)), 1, "Slotted card should enter the loadout pile.")
	assert_eq(int(counts.get("discard", -1)), 0, "Slotted card should not look like a normal discard.")


func test_combat_controller_exports_shooter_loadout_payload() -> void:
	var controller_script: GDScript = ResourceLoader.load("res://scripts/combat/TestCombatController.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var controller: Control = controller_script.new()
	var quick_slash: Resource = load("res://resources/cards/quick_slash.tres")
	var sidestep: Resource = load("res://resources/cards/sidestep.tres")
	controller.set("shooter_chips", 4)
	controller.set("loadout_slots", {"weapon": quick_slash, "ability_1": sidestep})
	var payload: Dictionary = controller.call("_build_combat_bridge_payload")
	assert_eq(String(payload.get("weapon_card", "")), "quick_slash", "Weapon slot should become the shooter weapon card.")
	var loadout: Array = payload.get("loadout", [])
	assert_eq(loadout.size(), 2, "Bridge payload should include structured slot records.")
	var weapon: Dictionary = loadout[0]
	assert_true(weapon.has("weapon") or (loadout[1] as Dictionary).has("weapon"), "Attack cards should export a weapon profile.")
	var economy: Dictionary = payload.get("economy", {})
	assert_true(int(economy.get("ammo", 0)) > 12, "Attack cards should increase arena ammo.")


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
	bridge.call("set_payload", payload)
	assert_true(bool(bridge.call("has_pending_payload")), "Bridge should report a pending arena payload.")
	var taken: Dictionary = bridge.call("take_payload")
	assert_eq(String(taken.get("weapon_card", "")), "quick_slash", "Bridge should hand the same weapon card to FPS.")
	assert_false(bool(bridge.call("has_pending_payload")), "Taking the payload should clear the pending handoff.")
	bridge.call("set_result", {"source": "fps_arena", "chips_awarded": 7, "cards_to_draw": 5})
	assert_true(bool(bridge.call("has_pending_result")), "Bridge should report a pending arena result.")
	var result: Dictionary = bridge.call("take_result")
	assert_eq(int(result.get("chips_awarded", 0)), 7, "Bridge should hand the same FPS result back to the card table.")
	assert_false(bool(bridge.call("has_pending_result")), "Taking the result should clear the pending return payload.")


func test_fps_prototype_consumes_bridge_payload_as_active_loadout() -> void:
	var prototype_script: GDScript = ResourceLoader.load("res://scripts/fps/FPSPrototype.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var prototype: Node = prototype_script.new()
	prototype.call("apply_arena_bridge_payload", {
		"weapon_card": "quick_slash",
		"ability_cards": ["sidestep"],
		"loadout": [
			{"slot": "weapon", "id": "quick_slash", "weapon": {"name": "Ace Cutter Revolver", "damage": 28, "magazine": 6, "fire_rate": 3.2}},
			{"slot": "ability_1", "id": "sidestep", "ability": {"kind": "dash", "charges": 1}}
		],
		"economy": {"chips": 5, "armor": 7, "ammo": 36},
		"reads": {"target_enemy": &"skulker", "threat": "Cut Purse 45%"}
	})
	var summary: Dictionary = prototype.call("get_active_loadout_summary")
	assert_eq(String(summary.get("weapon", "")), "Ace Cutter Revolver", "FPS should expose the bridge weapon as active.")
	assert_eq(int(summary.get("abilities", 0)), 1, "FPS should expose bridged ability count.")
	assert_eq(int(summary.get("armor", 0)), 7, "FPS should expose bridged armor.")
	assert_eq(int(summary.get("ammo", 0)), 36, "FPS should expose bridged ammo.")
	prototype.set("kills", 3)
	prototype.set("shots_fired", 6)
	prototype.set("shots_hit", 4)
	prototype.set("damage_taken", 10)
	var result_preview: Dictionary = prototype.call("get_arena_result_preview", 0)
	assert_eq(String(result_preview.get("source", "")), "fps_arena", "FPS payout previews should identify the arena source.")
	assert_eq(String((result_preview.get("selected_reward", {}) as Dictionary).get("label", "")), "Damage Payout", "FPS payout previews should include the selected reward.")
	assert_true(int(result_preview.get("chips_awarded", 0)) >= 10, "FPS payout previews should calculate a useful chip award.")


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
