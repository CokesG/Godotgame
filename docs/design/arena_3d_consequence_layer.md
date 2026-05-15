# Arena 3D Consequence Layer

Last updated: 2026-05-14

## Intent

Dead Man's Ante should not feel like a flat card UI with math hidden behind text. The card game is the command layer; the arena is the consequence layer.

The player still makes readable deckbuilder decisions:
- pick a target or move cell
- play or commit a card
- resolve the turn
- read enemy intent
- take rewards

The 3D arena shows what those decisions do:
- pawns occupy the same 3x3 tactical cells as `CombatGrid`
- movement cards and enemy reposition intents animate across the table
- attack cards trigger lunges, hit shakes, slash bursts, and health changes
- guard cards trigger blue guard rings and guard bars
- defeats shrink/fall away with smoke
- target selection pulses the in-world unit

This is intentionally a prototype-friendly bridge, not a final combat art pipeline.

## Current Implementation

Primary files:
- `res://scripts/arena/Arena3DView.gd`
- `res://scripts/combat/TestCombatController.gd`
- `res://scripts/grid/CombatGrid.gd`
- `res://scripts/grid/GridCellView.gd`

`Arena3DView.gd` extends `SubViewportContainer` and builds its own runtime 3D scene:
- `SubViewport`
- `WorldEnvironment`
- `Camera3D`
- lights
- cursed table mesh
- 3x3 cell marker planes
- simple capsule pawns
- `Label3D` nameplates
- mesh-based health and guard bars
- lightweight mesh particle bursts

The current view is embedded behind the existing 2D `CombatGrid` inside `TableBoardPanel`. The 2D grid remains clickable and authoritative. The arena reads the grid/resolver state and visualizes it.

Phase 47 readability note:
- The visible 2D board is now the command surface: cells show `YOU`, enemy names, or `MOVE` instead of developer coordinates like `0,0`.
- Normal compact combat hides the old state-chip row so the board and hand fit in the 1152x648 QA viewport.
- The 3D layer should carry consequence, motion, health, guard, particles, and hit reactions. It should not duplicate labels that the command grid already shows.
- Keep `display/window/size/viewport_width=1152` and `display/window/size/viewport_height=648` unless the visual QA harness is intentionally updated with a new baseline.

Important API surface on `Arena3DView`:
- `configure_map(map_data)`
- `reset_units(position_snapshot, combat_state)`
- `sync_units(position_snapshot)`
- `sync_combat_state(combat_state)`
- `play_card_beat(style, source_id, target_id, target_cell)`
- `play_move(unit_id, from_cell, to_cell)`
- `play_damage(unit_id, amount)`
- `play_guard(unit_id, amount)`
- `play_defeat(unit_id)`
- `focus_unit(unit_id)`

## Wiring

`TestCombatController.gd` owns the bridge:
- creates `Arena3DView` behind `CombatGrid`
- calls `reset_units` after grid/combat reset
- calls `sync_combat_state` from resolver state changes
- calls `play_move` from `CombatGrid.unit_moved`
- calls `play_card_beat` from card VFX resolution
- calls `play_damage`, `play_guard`, and `play_defeat` from combat delta feedback
- calls `focus_unit` when selecting or hovering enemy targets

This keeps combat rules in the existing resolver/grid/card systems. The arena should not become a second source of gameplay truth.

## Design Direction

The long-term fantasy is a cursed tabletop fighter:
- cards are not just effects; they are instructions to an avatar
- the 3x3 board is a small arena on the table
- calls/bluffs/read mechanics influence what the fighters commit to
- enemy intent and PvP mind games can become simultaneous hidden commitments

Recommended next milestone:
1. Add an animation event queue so card resolution waits for arena beats instead of firing everything at once.
2. Replace capsule pawns with 2D billboards or placeholder rigged models only after the board/cell alignment stays readable.
3. Add attack arcs, guard shields, trap markers, and hit reactions per card school.
4. Add a readable health/guard strip near each pawn instead of relying on UI text.
5. Add sound hooks for card play, step, slash, block, trap, wager, reveal, and defeat.

PvP should wait until the single-player sequence is readable. The likely PvP model is simultaneous card commitment, not twitch fighting:
- both players commit cards/targets/stance
- reveal resolves into arena beats
- position, guard, wounds, and tells carry forward

## Caveats

The arena is currently a visual layer. It should not:
- decide legal movement
- decide damage
- decide targeting
- decide victory/defeat
- mutate card/deck/resolver state

The 2D grid is still the source of truth. The arena follows it.

## Phase 61 Tactical Map Layer

`Arena3DView` now renders the data from `TacticalMapDefinition.gd`:

- low cover blocks on cover cells
- a glowing ring on Center Pot
- sightline markers on Long Rail cells
- flank/choke markers for route readability

These markers are visual affordances for the same 3x3 cells the player clicks. They should help the player read cover, objective pressure, and angles at a glance without turning the arena into separate geometry with its own collision rules.

Headless runs hide the arena to keep tests stable. Rendered visual QA still captures the arena in normal windowed runs.
