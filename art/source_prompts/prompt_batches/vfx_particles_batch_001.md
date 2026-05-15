# VFX Particle Batch 001

Use alongside `docs/design/vfx_particles_effects.md` and `docs/design/ui_ux_asset_generation.md`.

## Shared Style Prompt

```text
Dark fantasy roguelike deckbuilder VFX sprites for "Dead Man's Ante", cursed poker-table world, gothic casino dungeon, occult cards, bone dice, blood-red chips, antique gold trim, smoky candlelight, stylized painterly 2D game art, readable transparent game effects, high contrast, premium indie card battler style, no text.
```

## Negative Prompt

```text
No modern neon casino, no sci-fi, no photorealism, no fake text, no watermark, no cluttered background, no full UI screenshot, no letters, no numbers.
```

## Particle Atlas Prompt

```text
Create a transparent PNG particle atlas for a 2D Godot card battler. Include separated sprite cells for: crimson blood droplet spark, bone-white ash fleck, black-purple curse smoke puff, antique-gold poker chip glint, blue moonlit shield shard, green poison/movement mote, and pale ghost flame. Keep each particle isolated on transparent background, readable at 16px to 64px, painterly but clean, matching Dead Man's Ante dark occult gambling art direction.
```

Recommended output: 1024x1024 transparent PNG, 4x4 or 5x5 grid.

## Slash Sprite Strip Prompt

```text
Create a transparent PNG sprite strip for a diagonal crimson attack slash in a dark fantasy card battler. 8 frames left-to-right, fast bright brass highlight at the leading edge, deep blood red trail, no character, no background, no text, clean silhouette, readable over dark velvet and stone.
```

Recommended output: 2048x256 transparent PNG.

## Ritual Circle Prompt

```text
Create a transparent PNG sprite sheet of a cursed poker-table ritual circle drawing itself in crimson and antique gold. 12 frames, occult card suits, subtle bone-white runes as abstract marks only, no readable letters, no background, no text, designed for a 2D Godot card battler.
```

Recommended output: 2048x2048 transparent PNG, 4x3 grid.

## Remotion Motion Study

Use Remotion if we want authored timing before exporting a sprite sheet:

```text
Composition: DeadMansAnteVFXStudy
Duration: 48 frames at 24fps
Size: 512x512
Transparent background
Sequences:
1. chip scatter: 0-16 frames
2. smoke curl: 12-36 frames
3. ritual circle draw: 20-48 frames
Output: transparent PNG sequence for Godot import
```
