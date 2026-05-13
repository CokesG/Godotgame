# Dead Man's Ante - VFX, Particles, And Effects Guide

Status: prototype VFX plan and Phase 44 responsiveness pass wired
Last updated: 2026-05-12
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

Current procedural effects:

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
| `play_intent_flicker_on` | Intent reveal/call uncertainty feedback |

Card views also have local hover feedback in `res://scripts/ui/CardView.gd`, and grid cells pulse their active target state in `res://scripts/grid/GridCellView.gd`.

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

No additional art is required for the current prototype pass. The existing card, board, enemy, icon, and relic PNGs are enough.

Recommended next art when we want polish:

- One transparent particle atlas with blood droplet, ash fleck, chip glint, smoke puff, shield shard, and ghost flame sprites.
- One slash sprite strip with 6 to 8 frames.
- One ritual circle sprite or mask.
- One card burn/dissolve mask.
- Optional transparent Remotion-rendered sprite sheet for premium chip scatter, smoke curl, and ritual-circle draw timing.

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
