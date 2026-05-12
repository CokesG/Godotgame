# Dead Man's Ante - UI/UX And Asset Generation Guide

Status: visual direction and asset-production guide
Last updated: 2026-05-12
Engine target: Godot 4.6.x
Design source: `docs/design/dead_mans_ante_mega_prompt.md`

## Purpose

This document turns the visual concept for Dead Man's Ante into a reusable UI/UX and image-generation workflow. Use it when creating or delegating art for cards, enemies, UI, board tiles, props, relics, backgrounds, motion studies, and eventual marketing images.

The goal is not just attractive art. Every generated asset must help the prototype read clearly at card size, thumbnail size, and 960x540 gameplay scale.

## Visual North Star

Every battle should look like a cursed poker hand played on a ritual table. The player should immediately understand:

- The board is tactical.
- The cards are dangerous tools.
- The enemies have tells.
- The wager can escalate.
- The whole room belongs to the House.

## Core Game Fantasy

Dead Man's Ante is a dark tactical roguelike deckbuilder set in a cursed poker-table fantasy world where warriors, gamblers, monsters, and occult dealers fight through tactical card battles.

Every battle feels like a cursed poker hand. The player reads enemy tells, bluffs, calls, folds, raises the stakes, and survives by outsmarting monsters on a small tactical grid.

## Style Lock

Use this direction across all generated assets:

- Dark fantasy plus occult gambling.
- Gothic casino dungeon, not modern casino.
- Poker table meets ritual altar.
- Stylized 2D game art, painterly but readable.
- Sharp silhouettes and controlled details.
- Dramatic smoky candlelight.
- Tactical board-game clarity.
- Premium indie card-game presentation.
- Clean enough for Godot 2D UI and small icons.

Avoid:

- Modern casino neon.
- Realistic AAA rendering.
- Sci-fi or cyberpunk elements.
- Cluttered backgrounds.
- Tiny unreadable symbols.
- Overly complex armor.
- Generic medieval fantasy.
- Cute cartoon style.
- Photorealism.
- Baked-in text, fake letters, or generated UI copy.

## Palette

Use a dark, readable palette with warm accents:

| Role | Color Direction | Suggested Hex |
| --- | --- | --- |
| Deep background | blackened purple | `#171020` |
| Table surface | dark velvet crimson | `#351223` |
| Danger and blood | deep crimson | `#8f1e2a` |
| Premium trim | antique gold | `#c0954b` |
| Bones and readable marks | bone white | `#e3d7bd` |
| Fog and disabled UI | smoky gray | `#5d5962` |
| Occult contrast | dark emerald | `#1d4e42` |
| Night contrast | muted blue moonlight | `#536e8d` |
| Active glow | candle orange | `#d77a34` |

Do not let the game become a one-color purple interface. Use antique gold, bone, candle orange, emerald, and moon-blue accents to create clear gameplay hierarchy.

## Master Art Prompt

```text
Create art assets for a dark tactical roguelike deckbuilder called "Dead Man's Ante."

Theme:
A cursed poker-table fantasy world where warriors, gamblers, monsters, and occult dealers fight through tactical card battles. The tone is dark, stylish, readable, and premium indie - part gothic casino, part cursed dungeon, part tactical fantasy board game.

Core visual identity:
- Dark fantasy + occult gambling
- Cursed cards, bone dice, blood-red chips, tarnished gold coins
- Smoky tavern/casino lighting
- Gothic stone, velvet cloth, brass trim, old wood, candlelight
- Poker table meets ritual altar
- Tactical board-game readability
- High contrast silhouettes
- Stylized, not realistic
- Clean enough for game UI and small icons

Art style:
Stylized 2D game art, painterly but readable, dark fantasy card-game illustration, sharp silhouettes, controlled details, dramatic lighting, premium indie game aesthetic, suitable for Godot 2D UI.

Color palette:
Blackened purple, deep crimson, antique gold, bone white, smoky gray, dark emerald, muted blue moonlight, candle-orange highlights.

Main game fantasy:
Every battle feels like a cursed poker hand. The player reads enemy tells, bluffs, calls, folds, raises the stakes, and survives by outsmarting monsters on a small tactical grid.

Key motifs:
- Playing cards
- Poker chips
- Dice
- Tarot symbols
- Cursed hands
- Blood wagers
- Broken crowns
- Candlelit tables
- Monster tells
- Face-down cards
- Ritual circles
- Grid tiles
- Dealer masks
- Chains, contracts, seals, wax stamps

Asset requirements:
- Clean silhouettes
- Game-ready readability
- Not over-detailed
- No tiny fragile details
- Consistent style across assets
- Suitable for 2D Godot game
- Strong icons and UI clarity
- Works at card-size and thumbnail-size
```

## One-Line Style Prompt

```text
Dark fantasy roguelike deckbuilder art, cursed poker-table world, gothic casino dungeon, occult cards, bone dice, blood-red chips, antique gold trim, smoky candlelight, stylized painterly 2D game art, sharp silhouettes, readable UI-focused design, premium indie aesthetic, tactical board-game clarity, black purple crimson bone white palette.
```

## Negative Prompt

Append this to image-generation requests when the tool supports negative prompting:

```text
No modern neon casino, no sci-fi, no cyberpunk, no photorealism, no realistic AAA render, no cute cartoon style, no generic medieval fantasy, no cluttered background, no tiny unreadable symbols, no excessive armor complexity, no fake text, no illegible letters, no watermark, no logo, no UI copy baked into the image.
```

## Image Generation Rules

- Generate art without text whenever possible. Titles, costs, rules text, numbers, and labels should be rendered in Godot.
- Prefer transparent PNGs for enemies, characters, icons, props, card frames, and UI pieces.
- Prefer full-bleed PNG or WebP for backgrounds.
- Prefer SVG only for simple flat icons that need to scale perfectly.
- Keep shapes readable at 96 px high for enemies and 64 px square for icons.
- Do a thumbnail pass before approving an asset. If the silhouette collapses, regenerate.
- Use the same base prompt across a batch so the set feels unified.
- For sprites, ask for front-facing or three-quarter view on a transparent background.
- For cards, separate central illustration from card frame when possible.
- For UI, create reusable pieces instead of one giant baked screenshot.

## UI/UX Direction

Design the UI like a cursed poker table mixed with a tactical combat board.

Use:

- Dark velvet panels.
- Brass frames.
- Ornate card slots.
- Glowing enemy intent icons.
- Face-down card backs.
- Wager meters.
- Readable health, guard, nerve, and blood bars.
- Clear 3x3 tactical grid highlights.
- Bone-white text areas with dark backing when readability demands it.
- Candle-orange active states.
- Antique-gold premium trim.
- Crimson danger states.
- Emerald read/bluff states.
- Moon-blue preview states.

Do not use generated art as the only source of UX clarity. Godot controls should still own:

- Hover states.
- Focus states.
- Disabled states.
- Selected states.
- Tooltips.
- Numbers and labels.
- Dynamic bars.
- Button text.
- Runtime card rules text.

## Card Design

Card assets should support this layout:

- Ornate dark fantasy border.
- Clear cost gem in the top-left corner.
- Readable title band.
- Icon-based type marker.
- Large central illustration.
- Short text area controlled by Godot.
- Rarity trim.
- Subtle poker and tarot symbolism.
- Distinct, memorable card back.

Card frame art should not include generated words. Create frame variants for common, uncommon, rare, boss, curse, and relic-linked cards.

Recommended source sizes:

| Asset | Source Size | Runtime Use |
| --- | --- | --- |
| Full card mockup | 1024 x 1536 | Style reference only |
| Card illustration | 768 x 512 or 1024 x 768 | Cropped into card body |
| Card frame | 512 x 768 or 1024 x 1536 | Nine-slice or TextureRect |
| Card back | 512 x 768 or 1024 x 1536 | Deck, discard, committed cards |
| Cost/type icons | 512 x 512 | Scaled down in UI |

## Enemy Design

Enemies should feel like monsters from a cursed casino dungeon.

Each enemy needs:

- Strong readable silhouette.
- One obvious behavioral tell in posture, face, or hands.
- Gothic gambler details.
- Cards, chips, dice, bone, masks, contracts, or coin motifs.
- A sprite-friendly pose on a transparent background.
- Visual separation from UI panels and board tiles.

Current prototype enemies to generate first:

| Resource | Display Name | Suggested Export |
| --- | --- | --- |
| `resources/enemies/brute.tres` | Brute | `art/game/enemies/enemy_brute.png` |
| `resources/enemies/skulker.tres` | Skulker | `art/game/enemies/enemy_skulker.png` |
| `resources/enemies/shieldbearer.tres` | Shieldbearer | `art/game/enemies/enemy_shieldbearer.png` |
| `resources/enemies/needle_eye.tres` | Needle-Eye | `art/game/enemies/enemy_needle_eye.png` |
| `resources/enemies/hexmonger.tres` | Hexmonger | `art/game/enemies/enemy_hexmonger.png` |
| `resources/enemies/grave_dealer.tres` | Grave Dealer | `art/game/enemies/enemy_grave_dealer.png` |
| `resources/enemies/house_champion.tres` | House Champion | `art/game/enemies/enemy_house_champion.png` |

## Board And Environment Design

The battlefield is a small 3x3 tactical grid placed on a cursed table or dungeon floor. Tiles may be velvet, stone, bone, brass, cracked glass, or ritual-marked.

Board priorities:

- The 3x3 structure must be obvious at a glance.
- Occupied cells must remain readable.
- Hazards and traps must not obscure units.
- Movement, target, preview, and danger highlights must work on top of the art.
- The board should read from top-down or slight isometric view.

First board exports:

| Asset | Suggested Export | Notes |
| --- | --- | --- |
| Base combat board | `art/game/board/board_cursed_table_3x3.png` | Full 3x3 board reference |
| Normal tile | `art/game/board/tile_velvet_normal.png` | Reusable tile |
| Hazard tile | `art/game/board/tile_blood_hazard.png` | Danger state |
| Trap tile | `art/game/board/tile_card_trap.png` | Player-placed trap |
| Selected highlight | `art/game/board/highlight_selected.png` | Transparent overlay |
| Intent danger highlight | `art/game/board/highlight_intent_danger.png` | Transparent overlay |

## Asset Folder Plan

When generated art starts landing in the project, use this structure:

```text
art/
  source_prompts/
    ui_ux_asset_generation.md
    prompt_batches/
  generated_raw/
    cards/
    enemies/
    ui/
    board/
    backgrounds/
  game/
    cards/
      illustrations/
      frames/
      backs/
    enemies/
    characters/
    relics/
    ui/
      panels/
      bars/
      buttons/
      meters/
    icons/
      card_types/
      intents/
      resources/
      status/
    board/
      tiles/
      highlights/
    backgrounds/
    fx/
  remotion/
    motion_refs/
    renders/
    sprite_sheets/
```

Keep raw generations separate from game-ready exports. Raw files can be messy; `art/game` should only contain approved assets named for import.

## File Naming Rules

Use lowercase snake_case:

```text
card_quick_slash.png
card_frame_common.png
card_back_dead_mans_ante.png
enemy_skeletal_cardsharp_idle.png
enemy_brute.png
ui_wager_meter_frame.png
icon_intent_attack.png
tile_velvet_normal.png
board_cursed_table_3x3.png
```

Use suffixes when needed:

```text
_idle
_attack
_hurt
_defeat
_normal
_hover
_pressed
_disabled
_selected
_preview
_danger
```

## First Asset Batch

Generate these before making every card illustration. They establish the game's visual language.

| Priority | Asset | Suggested Export |
| --- | --- | --- |
| 1 | Cursed 3x3 combat board | `art/game/board/board_cursed_table_3x3.png` |
| 2 | Card back | `art/game/cards/backs/card_back_dead_mans_ante.png` |
| 3 | Common card frame | `art/game/cards/frames/card_frame_common.png` |
| 4 | Rare card frame | `art/game/cards/frames/card_frame_rare.png` |
| 5 | Wager meter frame | `art/game/ui/meters/ui_wager_meter_frame.png` |
| 6 | Health bar frame/fill | `art/game/ui/bars/ui_health_bar_frame.png`, `ui_health_bar_fill.png` |
| 7 | Guard bar frame/fill | `art/game/ui/bars/ui_guard_bar_frame.png`, `ui_guard_bar_fill.png` |
| 8 | Nerve icon | `art/game/icons/resources/icon_nerve.png` |
| 9 | Blood icon | `art/game/icons/resources/icon_blood.png` |
| 10 | Intent icons | `art/game/icons/intents/icon_intent_attack.png`, `icon_intent_guard.png`, `icon_intent_feint.png`, `icon_intent_hex.png` |

## Second Asset Batch

Generate the current prototype enemies:

```text
enemy_brute.png
enemy_skulker.png
enemy_shieldbearer.png
enemy_needle_eye.png
enemy_hexmonger.png
enemy_grave_dealer.png
enemy_house_champion.png
```

Enemy prompt template:

```text
Create a stylized 2D enemy concept for "Dead Man's Ante": [ENEMY NAME], [ROLE AND BEHAVIOR]. Cursed casino-dungeon monster, strong readable silhouette, obvious behavioral tell in posture, gothic gambler details, cards/chips/dice/bone motifs, smoky candlelight, crimson antique-gold black-purple palette, transparent background, game-ready enemy sprite concept, readable at small size.
```

Examples:

```text
Create a stylized 2D enemy concept for "Dead Man's Ante": Brute, a heavy debt collector who telegraphs huge lane attacks by dragging a hooked club across poker chips. Cursed casino-dungeon monster, strong readable silhouette, obvious behavioral tell in posture, gothic gambler details, cards/chips/dice/bone motifs, smoky candlelight, crimson antique-gold black-purple palette, transparent background, game-ready enemy sprite concept, readable at small size.
```

```text
Create a stylized 2D enemy concept for "Dead Man's Ante": House Champion, a final boss duelist with a broken crown, royal poker cloak, and false tells hidden behind a dealer mask. Cursed casino-dungeon monster, strong readable silhouette, obvious behavioral tell in posture, gothic gambler details, cards/chips/dice/bone motifs, smoky candlelight, crimson antique-gold black-purple palette, transparent background, game-ready boss sprite concept, readable at small size.
```

## Third Asset Batch

Generate card illustrations for the existing 20 card resources:

| Resource | Display Name | Suggested Export |
| --- | --- | --- |
| `quick_slash.tres` | Quick Slash | `art/game/cards/illustrations/card_quick_slash.png` |
| `low_stab.tres` | Low Stab | `art/game/cards/illustrations/card_low_stab.png` |
| `center_cut.tres` | Center Cut | `art/game/cards/illustrations/card_center_cut.png` |
| `sure_cut.tres` | Sure Cut | `art/game/cards/illustrations/card_sure_cut.png` |
| `all_in_cut.tres` | All-In Cut | `art/game/cards/illustrations/card_all_in_cut.png` |
| `guard_up.tres` | Guard Up | `art/game/cards/illustrations/card_guard_up.png` |
| `bone_guard.tres` | Bone Guard | `art/game/cards/illustrations/card_bone_guard.png` |
| `black_shield.tres` | Black Shield | `art/game/cards/illustrations/card_black_shield.png` |
| `sidestep.tres` | Sidestep | `art/game/cards/illustrations/card_sidestep.png` |
| `hook_step.tres` | Hook Step | `art/game/cards/illustrations/card_hook_step.png` |
| `shadow_step.tres` | Shadow Step | `art/game/cards/illustrations/card_shadow_step.png` |
| `read_tell.tres` | Read Tell | `art/game/cards/illustrations/card_read_tell.png` |
| `marked_card.tres` | Marked Card | `art/game/cards/illustrations/card_marked_card.png` |
| `false_opening.tres` | False Opening | `art/game/cards/illustrations/card_false_opening.png` |
| `house_edge.tres` | House Edge | `art/game/cards/illustrations/card_house_edge.png` |
| `second_wind.tres` | Second Wind | `art/game/cards/illustrations/card_second_wind.png` |
| `iron_vow.tres` | Iron Vow | `art/game/cards/illustrations/card_iron_vow.png` |
| `snare_card.tres` | Snare Card | `art/game/cards/illustrations/card_snare_card.png` |
| `tripwire.tres` | Tripwire | `art/game/cards/illustrations/card_tripwire.png` |
| `blood_ritual.tres` | Blood Ritual | `art/game/cards/illustrations/card_blood_ritual.png` |

Card prompt template:

```text
Create a dark fantasy tactical deckbuilder card illustration for "Dead Man's Ante": [CARD NAME], [CLEAR ACTION OR SYMBOL]. Gothic casino dungeon theme, occult gambling symbols, dramatic candlelight, sharp readable silhouette, dark crimson and antique gold palette, premium indie game card art, clear central figure/action, no text, no numbers, no UI labels, clean space for title/cost/text UI.
```

## Fourth Asset Batch

Generate relic icons for the current relic resources:

| Resource | Display Name | Suggested Export |
| --- | --- | --- |
| `bone_chips.tres` | Bone Chips | `art/game/relics/relic_bone_chips.png` |
| `cracked_lens.tres` | Cracked Lens | `art/game/relics/relic_cracked_lens.png` |
| `loaded_dice.tres` | Loaded Dice | `art/game/relics/relic_loaded_dice.png` |
| `marked_deck.tres` | Marked Deck | `art/game/relics/relic_marked_deck.png` |
| `scarlet_ante.tres` | Scarlet Ante | `art/game/relics/relic_scarlet_ante.png` |

Relic prompt template:

```text
Create a readable 2D relic icon for "Dead Man's Ante": [RELIC NAME], a cursed gambling artifact. Dark fantasy poker-table style, antique gold trim, bone, blood-red chips, occult markings, sharp silhouette, transparent background, premium indie game icon, readable at 64 pixels, no text.
```

## UI Asset Prompt

```text
Design UI assets for a dark tactical roguelike deckbuilder: cursed poker table interface, velvet panels, brass trim, ornate card slots, glowing enemy intent icons, wager meter, health/guard/nerve bars, face-down card backs, tactical 3x3 grid highlights, readable Godot 2D game UI, dark fantasy premium indie style, no text, no labels, transparent background where appropriate.
```

## Environment And Board Prompt

```text
Create a 2D tactical combat board for a dark fantasy roguelike deckbuilder: 3x3 grid on a cursed poker table/ritual altar, velvet cloth, brass edging, bone dice, blood-red chips, candlelight, gothic stone floor hints, readable tactical tiles, slight isometric view, clean game-ready board asset, no text, no labels.
```

## Character Prompt

```text
Create a stylized 2D character concept for "Dead Man's Ante": [CHARACTER NAME], a dark fantasy gambler-duelist with readable clothing layers and iconic accessories like cards, chips, dagger, gloves, cloak, lantern, belt pouches, and ritual markings. Strong silhouette, premium indie card-game style, smoky candlelight, blackened purple, crimson, antique gold, bone white, transparent background, game-ready sprite concept.
```

## Motion And Remotion Notes

Remotion is not required for static PNG creation, but it is useful once the visual language is locked.

Use Remotion later for:

- Card flip motion studies.
- Face-down commit reveal animations.
- Wager meter escalation loops.
- Intent icon pulsing references.
- Trailer-ready UI shots.
- PNG sequences that can be packed into sprite sheets.

Suggested Remotion outputs:

```text
art/remotion/renders/card_flip_reveal/
art/remotion/renders/wager_meter_raise/
art/remotion/sprite_sheets/card_flip_reveal_spritesheet.png
```

Keep Remotion animations short and readable. The actual game should still use Godot for runtime UI state, input, and gameplay timing.

## Godot Import Defaults

Recommended defaults once PNGs are imported:

- UI frames: use TextureRect, NinePatchRect, or StyleBoxTexture depending on stretch behavior.
- Card illustrations: TextureRect inside CardView.
- Card frames: TextureRect overlay or StyleBoxTexture.
- Enemies: Sprite2D or TextureRect depending on whether combat remains Control-based.
- Icons: TextureRect or Button icon.
- Bars: Godot ProgressBar/TextureProgressBar with generated frame/fill textures.
- Board tiles: TextureRect per cell or TileMapLayer if the board becomes map-like later.

Use nearest-neighbor only if the final art becomes pixel art. For painterly 2D assets, use filtered textures with mipmaps disabled for crisp UI.

## Acceptance Checklist

Approve an asset only if:

- It reads clearly at gameplay size.
- It reads clearly at thumbnail size.
- It has no baked text unless it is abstract texture.
- Its silhouette is strong against dark UI.
- It matches the palette.
- It avoids modern neon and sci-fi shapes.
- It can be cropped without losing the main action.
- It supports Godot overlays for highlights, numbers, labels, and bars.
- It belongs to Dead Man's Ante specifically, not generic fantasy.

## First Practical Next Step

Start with three style anchor generations:

```text
1. board_cursed_table_3x3.png
2. card_back_dead_mans_ante.png
3. enemy_brute.png
```

If those three feel unified, continue into card frames, UI meters, intent icons, and the remaining current enemies. If they do not feel unified, regenerate before producing the full card set.
