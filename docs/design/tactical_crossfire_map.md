# Tactical Crossfire Map

Status: Phase 61 implementation note
Last updated: 2026-05-15

## Goal

The current combat board stays 3x3 because readability is the hook. The new map layer makes that small board feel tactical: each cell now has a battlefield identity, a visual marker, and a light rules payload.

## Crossfire Table

`Crossfire Table` is the first authored map. It translates the Valorant/Hearthstone/Overwatch direction into Dead Man's Ante terms:

- Hearthstone clarity: the player still sees one compact board, card hand, target cards, and a clean resolve button.
- Tactical shooter tension: lanes have cover, center pressure, flanks, and a long angle.
- Hero-combat roles: duelists want flank/angle cells, guards like cover, and reads/traps care about lane control.

## Cell Plan

```text
SMK | CHK | ANG
FLK | POT | COV
COV | YOU | ANG
```

- `SMK` Smoke Cover: light enemy-side cover and trickster rotate space.
- `CHK` Choke Rail: direct center backline pressure.
- `ANG` Long Angle: sightline cells for damage pressure.
- `FLK` Flank Step: movement, trap, and bait route.
- `POT` Center Pot: objective cell, grants +1 card damage.
- `COV` Cover: reduces incoming lane damage. Back Cover and Hard Cover reduce by 2.
- `YOU` Deal Spot: safe starting cell, one step from the objective.

## Runtime Wiring

Primary files:

- `res://scripts/grid/TacticalMapDefinition.gd`
- `res://scripts/grid/CombatGrid.gd`
- `res://scripts/grid/GridCellView.gd`
- `res://scripts/arena/Arena3DView.gd`
- `res://scripts/combat/CombatResolver.gd`
- `res://scripts/run/RunManager.gd`
- `res://scripts/fps/FPSPrototype.gd`

The map is data-first. `CombatGrid` shows the labels and exposes `get_map_context()`. `Arena3DView` renders cover blocks, the center pot ring, angle markers, flank markers, and choke posts. `CombatResolver` reads the same map context for small tactical modifiers.

The FPS branch reads the same map data through `FPSPrototype.get_map_summary()` and `get_map_regions()`. It renders region markers and wall labels in the live arena so the shooter blockout says the same thing as the card board: Smoke Lane, Ante Mid, Long Rail, Center Pot, cover, flank, and angle.

The FPS branch now has five objective modes layered onto the same map:

- `Hold Pot`: hold the Center Pot long enough to bank objective score.
- `Extract`: touch the Center Pot, then reach the player-side extract lane alive.
- `Duel`: kill the marked target, currently `Needle Eye`, before the wave ends.
- `Defend`: keep enemies off the Center Pot and preserve the table core.
- `Boss Gate`: break the `Gate Champion` while surviving Crossfire pressure.

The objective mode is carried in the arena bridge payload as `objective_mode`, and the FPS arena returns `objective_label`, `objective_completed`, `objective_failed`, `objective_events`, and `objective_score` with the payout result.

The dev hub and map viewer make the shared map easy to test without playing the whole loop:

- `res://scenes/ui/MainMenu.tscn` opens to Full Game Experience, Card / Loadout Table, the five FPS objective shortcuts, Shooter Arena, Tactical Map Viewer, and debug checks.
- `res://scenes/ui/TacticalMapViewer.tscn` shows all nine Crossfire cells and their rule details.
- FPS arena reward selection now returns to the card table with a result payload, so Crossfire stats can pay out into the next hand.

## Current Rules

- `card_damage_bonus`: adds damage after action-beat scaling, only when a card would already hit.
- `incoming_damage_mitigation`: reduces incoming lane damage after call mitigation.

The map is intentionally not a second rules engine. It nudges decisions instead of replacing card text, enemy intent, or the action beat.

## Next Map Work

Good follow-up maps should change one tactical axis at a time:

1. `Split Pot`: two objective cells, weaker cover.
2. `Smoke House`: stronger cover, more trap synergy.
3. `Long Hall`: right lane damage map with sniper pressure.
4. `Guard Room`: more cover and protector enemies.

Keep every map readable inside the 1152x648 combat viewport before adding larger arenas.
