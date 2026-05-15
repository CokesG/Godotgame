# Dead Man's Ante - VFX, Particles, And Effects Guide

Status: generated PNG sprite strips wired
Last updated: 2026-05-14
Companion art guide: `docs/design/ui_ux_asset_generation.md`

## Goal

Dead Man's Ante should feel like a cursed poker hand resolving on a ritual table. The first VFX pass should make choices readable and tactile, not cinematic.

The current priority is reusable Godot feedback:

- Card hover lift, scale, tilt, and glow.
- Target tile pulse and active focus.
- Card play burst.
- Attack slash and blood sparks.
- Guard pulse.
- Bluff chip burst.
- Curse smoke.
- Intent reveal flicker.
- Damage and guard number popups.
- Enemy defeat ash.

This is enough for the prototype to feel alive without requiring a large bespoke animation pipeline.

## Current Implementation

The first reusable VFX layer is `res://scripts/vfx/CombatVFX.gd`.

It is wired into `res://scripts/combat/TestCombatController.gd` as a full-screen overlay named `CombatVFX`.

Current hybrid effects:

| Effect | Runtime Use |
| --- | --- |
| `play_card_burst_on` | Card play/commit impact at the source card |
| `play_card_fly_between` | A transient card ghost travels from hand/source to target |
| `play_slash_between` | Attack/read card travel line toward the target |
| `play_burst_at` | Blood, ash, guard, movement, chip, and smoke particles |
| `play_ring_at` | Reveal, guard, and card impact rings |
| `play_guard_pulse_at` | Guard gain or guard impact feedback |
| `play_target_lock_on` / `play_target_lock_at` | Enemy target hover, target selection, and attack impact lock-on |
| `play_reward_shimmer_on` | Recommended reward card shimmer |
| `play_button_sheen_on` | Dominant action button hover/press sheen |
| `play_chip_burst_on` | Raise/call/bluff wager feedback |
| `play_curse_smoke_on` | Face-down commit, fold, trap, curse, ritual feedback |
| `play_ritual_glow_on` | Ritual-card glow and occult table pulse |
| `play_intent_flicker_on` | Intent reveal/call uncertainty feedback |

Card views also have local hover feedback in `res://scripts/ui/CardView.gd`, and grid cells pulse their active target state in `res://scripts/grid/GridCellView.gd`.

## Generated PNG Sprite Strips

Phase 54 adds transparent PNG sprite strips under `res://art/game/vfx/generated/`:

```text
vfx_slash_strip.png          6 frames, 192x96 each
vfx_smoke_strip.png          6 frames, 128x128 each
vfx_chip_scatter_strip.png   6 frames, 128x128 each
vfx_ritual_glow_strip.png    6 frames, 128x128 each
vfx_guard_shield_strip.png   6 frames, 128x128 each
vfx_blood_hit_strip.png      6 frames, 128x128 each
vfx_death_ash_strip.png      6 frames, 128x128 each
vfx_card_burn_strip.png      6 frames, 128x128 each
```

`CombatVFX.gd` loads these through `SPRITE_STRIPS` and animates them with `AtlasTexture` frame regions. The existing procedural particles remain as secondary sparks, so the sprite strips carry the readable shape while the particles keep the hit feeling lively.

Use this pattern for future sprite strips:

- horizontal strip
- transparent PNG
- no text
- 6 to 8 frames for fast combat beats
- one visual idea per strip
- keep frame sizes power-of-two friendly when possible

## VFX Showcase Scene

`res://scenes/debug/VFXShowcase.tscn` is the review table for combat effects. It creates dummy cards and dummy targets, attaches `CombatVFX`, and loops the current core beats:

- card arc
- slash
- blood hit
- guard shield
- chip scatter
- curse smoke
- ritual glow
- card burn
- death ash
- target-card-to-pawn link

Use this scene before tuning combat timing. It is faster than playing through a full hand and makes scale/timing regressions obvious.

## First SFX Layer

Phase 57 adds generated WAV one-shots under `res://audio/sfx/generated/`:

```text
sfx_card_flick.wav
sfx_chip_clack.wav
sfx_slash_hit.wav
sfx_guard_shimmer.wav
sfx_smoke_whoosh.wav
sfx_ritual_hum.wav
sfx_card_burn.wav
sfx_ash_fall.wav
```

`CombatVFX.gd` owns a small `AudioStreamPlayer` pool and loads these WAVs directly into `AudioStreamWAV` so the generated files work without waiting for editor import metadata. The sound layer is intentionally short and dry; it should reinforce click response and impact timing without becoming music.

Current sound mapping:

- card fly/burst -> card flick
- chip burst -> chip clack
- slash/blood -> slash hit
- guard pulse -> guard shimmer
- smoke -> smoke whoosh
- ritual -> ritual hum
- card burn -> burn crackle
- ash/death -> ash fall

## Style Lock

Use the existing art direction:

- Dark fantasy plus occult gambling.
- Gothic casino dungeon, not modern casino.
- Cursed cards, blood-red chips, bone dice, brass trim, candlelight.
- Painterly, readable, high contrast.
- Effects should be sharp at gameplay scale.

Core effect palette:

| VFX Family | Color Direction |
| --- | --- |
| Blood / damage | deep crimson with hot red sparks |
| Guard / shield | moon-blue with pale barrier highlights |
| Bluff / wager | antique gold chip glitter |
| Curse / trap | black-purple smoke |
| Ritual | crimson smoke with gold accents |
| Movement | green table-edge glint |
| Death | bone-white ash |
| Reveal / read | violet flicker |

## Godot Effect Library

Build the library in this order:

1. `vfx_card_hover_glow`
2. `vfx_card_play_burst`
3. `vfx_attack_slash_red`
4. `vfx_blood_hit`
5. `vfx_guard_shield`
6. `vfx_nerve_wager_gold`
7. `vfx_curse_smoke`
8. `vfx_intent_reveal_flicker`
9. `vfx_trap_trigger`
10. `vfx_ritual_circle`
11. `vfx_enemy_death_ash`
12. `vfx_card_burn_exhaust`

The first pass uses procedural Godot nodes so it is easy to tune timing. Later passes can swap particle rectangles for a small sprite atlas.

## Additional Art Needed

No additional art is required for the current prototype pass. The existing card, board, enemy, icon, relic PNGs, and Phase 45 SVG source sprites are enough.

Phase 45 added these source assets:

- `res://art/game/vfx/vfx_particle_atlas.svg`
- `res://art/game/vfx/vfx_slash_strip.svg`
- `res://art/game/vfx/vfx_ritual_circle.svg`
- `res://art/game/vfx/vfx_card_burn_mask.svg`

Recommended next art wiring when we want polish:

- Import the particle atlas as texture regions for blood, ash, shield shard, poison mote, and ghost flame particles.
- Promote the current sprite-strip helper into a reusable VFX timing table if more than eight strips are added.
- Optional transparent Remotion-rendered sprite sheet for premium chip scatter, smoke curl, ritual-circle draw timing, and card burn timing.

Keep these assets text-free and style-matched to `art/generated_raw/style_anchor_batch_001.png`.

## Card Resolution Timing

Use this rhythm for most cards:

```text
Player picks target
-> card hover/focus confirms intent
-> card play burst at hand
-> card line/flip/commit feedback
-> target VFX
-> damage/guard number popup
-> target flash or pulse
-> card goes to discard or reveal state
```

Big effects can add a short hit pause later, but the prototype should stay quick.

## Effect Profiles

Card data can eventually expose this profile:

```gdscript
{
	"id": "quick_slash",
	"vfx_id": "attack_slash_red",
	"sfx_id": "card_slash_light",
	"screen_shake": "small",
	"hit_pause": 0.05,
	"target_flash": true,
	"particle": "blood_hit"
}
```

For now, `TestCombatController.gd` maps card type to a reusable VFX style:

- Attack -> slash plus blood impact.
- Defense -> guard pulse.
- Movement -> green movement burst.
- Bluff -> gold chip burst.
- Read -> violet intent flicker.
- Trap -> curse smoke.
- Ritual -> smoke plus chip/glow feedback.

## Remotion Use

Use Remotion only when the effect benefits from authored timing before import into Godot.

Best Remotion candidates:

- Transparent chip scatter sprite sheet.
- Ritual circle drawing itself over 12 to 24 frames.
- Smoke curl loop.
- Card burn/dissolve study.
- Reveal snap timing reference.

Render as transparent PNG sequences or sprite sheets, then import into Godot as `AnimatedSprite2D` or texture strips.

## Image Generation Use

Use image generation for particle atlas and VFX source art, not for baked UI screenshots.

Prompt anchor:

```text
Dark fantasy roguelike deckbuilder VFX sprites for "Dead Man's Ante", cursed poker-table world, gothic casino dungeon, occult cards, bone dice, blood-red chips, antique gold trim, smoky candlelight, stylized painterly 2D game art, readable transparent game effects, high contrast, no text.
```

Negative prompt:

```text
No modern neon casino, no sci-fi, no photorealism, no fake text, no watermark, no cluttered background, no full UI screenshot.
```

## First Prototype Checklist

- Card hover/lift and immediate press flash exist.
- Card drag/drop can be layered later.
- Card play to center has burst and travel feedback.
- Tile highlight, target-card press lock-on, and focus pulse exist.
- Attack slash exists.
- Damage number exists.
- Enemy hit flash exists.
- Guard pulse exists.
- Card discard movement is still future work after the hand-to-target travel beat.
- Intent reveal flicker exists.

## Live Battlefield Guidance

The battle screen should teach from inside the arena, not from distant debug panels.

- The arena owns the next-action callout: target, play a glowing card, resolve, then read aftermath.
- Enemy cards must describe fighters, not abstract names. Example: `Skulker` is shown as `Knife Duelist`; `Shieldbearer` is shown as `Shield Guard`.
- Empty cells should avoid coordinate labels in normal play. Use `MOVE`, `HERE`, `YOU`, and enemy/fighter names instead.
- The side enemy cards are target selectors; the board is the fight. Keep the board visually larger than the side panel.
- Resolve should have a pre-beat before the phase advances: pulse the battlefield callout, lock the target, ring the target pawn, then let card/enemy VFX and SFX answer.

Current implementation notes:

- `BattlefieldCallout` is layered over `TableStage` so guidance appears on the battlefield itself.
- `BattlefieldFocus` summarizes current target, role, likely intent, and next action.
- `EnemyTargetCards` use `CURRENT TARGET` / `CLICK TO AIM` copy and fighter-role descriptions.
- `HandView` keeps a fanned, physical hand pose even in compact combat.
