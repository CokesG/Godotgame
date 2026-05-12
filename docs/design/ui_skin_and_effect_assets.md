# Dead Man's Ante - UI Skin And Effect Asset Plan

Status: Phase 40 first Godot skin pass wired
Last updated: 2026-05-12

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

## Additional Art Needed Next

The current prototype does not need more static card/board/enemy art before it can become playable and fun. The highest-value next assets are small reusable effect sprites:

```text
1. transparent particle atlas: blood, ash, chip glint, smoke puff, shield shard, poison mote, ghost flame
2. 6-8 frame slash sprite strip
3. ritual circle draw sprite sheet
4. card burn/dissolve mask
5. face-down commit/reveal card back flash
```

Use image generation for those source sprites. Use Remotion only when authored timing matters, such as chip scatter, smoke curl loops, ritual-circle draw timing, and reveal snap studies. Export Remotion results as transparent PNG sequences or sprite sheets, then import them into Godot.
