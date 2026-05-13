# Dead Man's Ante - UI Skin And Effect Asset Plan

Status: Phase 45 first VFX source asset pass wired
Last updated: 2026-05-13

## What Is Wired Now

The prototype combat screen now uses a committed UI skin layer instead of plain debug panels:

- Root table backdrop from the cursed 3x3 board art.
- Title plaque for the game name.
- Texture-backed brass button states.
- Velvet/brass panel frames for run shell, action cue, table, enemy, reward, and debug panels.
- Ornate hand rail for the hand/deck strip.
- Ornate card frame style for `CardView`.
- Existing procedural Godot VFX remains responsible for card play bursts, slash lines, guard pulses, chip bursts, curse smoke, intent flicker, and damage numbers.

Runtime styling lives in `res://scripts/ui/DeadMansAnteSkin.gd`.

## Added UI Assets

```text
art/game/ui/skin/ui_table_backdrop.png
art/game/ui/skin/ui_header_plaque.png
art/game/ui/skin/ui_cue_plaque.png
art/game/ui/skin/ui_panel_velvet_frame.png
art/game/ui/skin/ui_hand_rail.png
art/game/ui/skin/ui_card_frame_common.png
art/game/ui/skin/ui_button_brass_normal.png
art/game/ui/skin/ui_button_brass_hover.png
art/game/ui/skin/ui_button_brass_pressed.png
art/game/ui/skin/ui_button_brass_disabled.png
art/game/ui/skin/ui_chip_pip.png
art/game/ui/skin/ui_divider_gold.png
```

These are derived from the existing generated style-anchor sheets so they match the current art direction.

## Added VFX Source Assets

```text
art/game/vfx/vfx_particle_atlas.svg
art/game/vfx/vfx_slash_strip.svg
art/game/vfx/vfx_ritual_circle.svg
art/game/vfx/vfx_card_burn_mask.svg
```

These are lightweight source assets for the next polish pass. Runtime VFX still uses procedural Godot nodes, but `CombatVFX.gd` now registers the asset paths so tests and future import work have one place to look.

## Additional Art Needed Next

The current prototype does not need more static card/board/enemy art before it can become playable and fun. The highest-value next asset work is to convert the new source sprites into imported texture regions or animated strips:

```text
1. slice the transparent particle atlas into reusable particle textures
2. wire the slash strip into an AnimatedSprite2D or texture-region slash effect
3. animate the ritual circle draw timing
4. use the burn mask for exhaust/discard dissolve
5. add a face-down commit/reveal card back flash
```

Use image generation for those source sprites. Use Remotion only when authored timing matters, such as chip scatter, smoke curl loops, ritual-circle draw timing, and reveal snap studies. Export Remotion results as transparent PNG sequences or sprite sheets, then import them into Godot.
