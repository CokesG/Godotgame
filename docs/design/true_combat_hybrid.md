# Dead Man's Ante - True Combat Hybrid

Status: direction and first aim/skill contract
Last updated: 2026-05-15

## Direction

The action layer should support both third-person hero combat and eventual FPS/shooter combat.

Cards decide what the player is allowed to attempt. The arena decides what that attempt looks like. Player execution decides how cleanly it lands.

```text
card choice -> target/read/bluff context -> aim/movement/ability execution -> arena animation -> resolver outcome
```

## Competitive Vision

Think `Hearthstone` clarity plus `Valorant` economy/round tension plus `Overwatch`/`Marvel Rivals` hero-combat energy, filtered through a cursed poker table.

- Cards are the tactical kit: attacks, blocks, movement, traps, reads, rituals, weapon stances, reloads, and ult-like risk plays.
- The arena is the skill layer: aim, movement, cover, spacing, dodges, parries, ability shots, and target priority.
- Poker/read mechanics are the mind game: predicting enemy intent changes openings, cooldown pressure, and counter windows.
- FPS can be the core combat camera: pistol duels, cursed rifles, shotgun-table rules, scoped tells, recoil wagers, sound cues, and card-driven utility.

## Shooter-Economy Translation

Cards should eventually behave like a competitive shooter economy and ability kit:

- Weapon cards: buy/equip pistols, rifles, shotguns, knives, cursed sidearms, or temporary ammo types.
- Ability cards: smoke, reveal, dash, guard wall, trap, heal, curse, silence, mark, shield, and ultimate-like rituals.
- Economy cards: earn chips, wager chips, deny enemy economy, reroll shop, overbuy for power with risk.
- Team cards: buff ally reload/armor, heal, share vision, set crossfire trap, revive/rally.
- Debuff cards: blind, slow, expose, bleed, curse recoil, disable guard, jam reload.
- Sound layer: every card family should have readable combat audio, like shooter utility. Smoke whoosh, reveal sting, chip-buy clack, rifle omen, guard shimmer, curse hiss.

Round concept:

```text
draw/buy phase -> choose loadout cards -> live shooter/arena round -> cards become abilities/equipment -> kills/objective/economy feed next draw
```

Current FPS ability contract:

- `Sidestep`, `Hook Step`, and other movement cards become a dash.
- `Guard Up`, `Iron Vow`, and other guard cards become shield armor.
- `Read Tell` and read cards reveal enemy outlines/marks.
- `Snare Card` and trap cards create a snare field.
- Ability HUD labels read from the live bindings instead of hardcoded `Q/E/C/V`.
- The Escape settings panel now groups tuning into Aim, Reticle, and Controls tabs.
- Controls can be rebound with keyboard keys, mouse buttons, controller buttons, and controller trigger axes.
- Movement, combat, system, and ability controls have per-action reset buttons plus a reset-all-controls button.
- Duplicate inputs are rejected during rebinding with an inline conflict warning. Escape remains fixed so the player can always reopen settings or cancel a rebind.

For the board-flow/UI contract, see `docs/design/board_flow_shooter_fusion.md`. That document is the source of truth for how the existing card-board interface should evolve around the movement/combat work happening in the other implementation thread.

## Why Third-Person First For The Prototype

- The game already has visible fighters and a card-table arena.
- The player needs to see their body, enemy tells, cards, chips, and target state at once.
- Melee, dodge, block, trap, guard-break, and flank reads map cleanly to the current card types.
- Third-person proves the card-to-ability contract before we add camera capture, recoil, networked aiming, and shooter feel.

## Public References

Good candidates to study:

- GDQuest Godot 4 third-person shooter controller: `https://github.com/gdquest-demos/godot-4-3d-third-person-controller`
  - MIT licensed.
  - Strong reference for a plug-and-play Godot 4 third-person controller and camera.
  - Best candidate if we want an open-source controller base.
- Selgesel Godot 4 third-person controller: `https://github.com/selgesel/godot4-third-person-controller`
  - Useful general movement/camera reference.
- Catprisbrey Souls-like Godot 4 controller: `https://github.com/catprisbrey/Third-Person-Controller--SoulsLIke-Godot4`
  - Useful melee/combo reference, but treat as inspiration until license and Godot-version fit are checked in detail.
- Paid templates like Brokencircuit TPS or MoTaiGik TPCC may be useful for comparison, but do not import paid/closed code into this repo.

## First Implementation Contract

`res://scripts/combat/ActionBeatResolver.gd` is the first rules bridge.

It grades spatial execution, not a sweet-spot timing minigame:

- `perfect`: aim/position is centered.
- `hit`: aim/position is solid.
- `graze`: edge contact or weak angle.
- `miss`: aim/position fails.

Initial beat styles:

- `attack`: aimed strike/shot.
- `guard`: block/parry placement.
- `move`: dodge/position choice.
- `read`: tell-reading focus.

Next wiring step:

1. When a card is played, create an action beat from card type.
2. Show an arena target ring and reticle/aim prompt.
3. Let aim/position resolve the beat.
4. Pass the multiplier/result into `CombatResolver`.
5. Play stronger VFX/SFX for `perfect`, reduced feedback for `graze`, and enemy counter feedback for `miss`.

## Tactical Map Contract

`Crossfire Table` is the first combat map. It keeps the board at 3x3, but each cell now carries a tactical identity:

- cover cells reduce incoming lane damage
- Center Pot rewards objective control with +1 card damage
- Long Rail cells create damage-angle pressure
- flank/choke cells make movement and enemy roles easier to read

This is how the prototype borrows shooter map thinking without losing card-game clarity. The map should make positioning feel authored and tactical, while `CombatGrid`, card targeting, and `CombatResolver` remain the source of gameplay truth.

## Design Rule

The deck is the moveset. Poker tells shape risk. The arena is where the player performs the decision.
