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

Current playable loop:

```text
card/loadout prep -> FPS arena fight -> reward/payout screen -> next hand
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
- Aim down sights defaults to right mouse / left trigger and has separate ADS FOV, ADS sensitivity scale, and toggle/hold settings.
- Right-stick look now has sensitivity, deadzone, and response-curve settings.
- The default shooter weapon is now an automatic carbine profile with ADS-aware spread, a longer spray pattern, visible sights/magazine/reload motion, reload progress HUD, and player-level recoil that nudges aim instead of only shaking the viewmodel.
- Enemy drones now expose readable status labels, attack tell rings/labels, delayed melee strikes, and projectile VFX; card ability slots show cooldown progress and pulse when fired.
- Settings include one-click `Default FPS`, `Tactical`, `Controller`, and `Left-Handed` presets.
- The FPS HUD includes a lower card-power rail so weapon, chip/armor/ammo economy, and the first four slotted ability cards stay visible during live combat.
- Card-power HUD slots now include cooldown bars and pulse when a slotted card ability fires, so the card layer feels active during the shooter fight.
- The HUD should stay compact: a slim top strip for health/ammo/wave/objective, a small bottom card rail for weapon/economy/abilities, and no large duplicate text blocks during live aiming. `res://tests/debug/FPSVisualQACheck.tscn` measures this contract and captures live/reward screenshots under `user://fps_visual_qa`.
- Objective world labels should behave like tactical markers, not full-screen banners. Keep objective words small, close to the prop, and let the arena geometry/crosshair stay readable.
- Player identity is now separate from card loadout. Starter class profiles include `Gambler-Knight`, `Hex Sharpshooter`, and `Blood Wager`; classes grant passives such as entry armor or ability cooldown scaling while cards still define the round-specific powers.
- The card prep table exposes this player identity through a class selector before `Enter Arena`, and arena results report hero/class/passive/ability-use data so post-round rewards can eventually branch by class mastery.
- Crossfire now has five live FPS objective modes: `Hold Pot`, `Extract`, `Duel`, `Defend`, and `Boss Gate`. Slotted card style recommends the objective when entering from the card table: movement leans Extract, guard leans Defend, reads/traps lean Duel, ritual leans Boss Gate, and default kits hold the pot.
- The prep table now makes that objective choice visible and actionable: the objective plan label previews the next arena win condition, hand cards show FPS badges/reasons, selected cards explain "why this loadout", and `Recommend Loadout` auto-slots an affordable kit toward the current hand's strongest objective.
- FPS enemies now carry visible combat roles, status tags, attack windup rings, shield plates for guards, and incoming projectiles for ranged shots instead of invisible instant hits.
- The FPS arena now has authored staging pieces: energy rails, spawn portals, an objective chip pot, cover silhouettes, wall signage, short-lived impact decals, and framed HUD panels so the battlefield reads as a competitive table-ritual combat space before custom art arrives.
- The dev hub includes shortcuts for raw FPS sandbox, seeded FPS loadout, card prep, all five objective modes, seeded return payout, and seeded defeat return so this loop can be tested without replaying the whole run.
- FPS reward selection now builds an arena result with map name, objective mode/label/completion, wave, kills, hit rate, damage, selected reward, objective score, wounds, chips awarded, and next-hand draw count, then returns to `TestCombat` through `ArenaBridge`.
- `TestCombat` consumes pending arena results on load, restores the pre-FPS run/deck/loadout snapshot, shows `ArenaPayoutPanel`, applies chip and non-chip payout effects, blocks normal card actions until `Start Next Hand`, and leaves the player on the next prep hand.
- `ArenaBridge`, `DeckManager`, and `RunManager` expose snapshot/restore hooks so the table can preserve exact deck piles, loadout piles, run node, rewards, relics, Blood, carryover payouts, and defeat state across the arena scene swap.
- Current non-chip payout effects are practical prototype hooks: objective-authored damage rewards boost the next bridged weapon, armor rewards carry armor into the next arena, and ammo rewards carry reserve ammo into the next arena. Those carryovers also bias the next table recommendation, so reward choice immediately affects loadout planning.
- FPS death returns a defeat result instead of only restarting; the card run can mark that as a lost table/run.

For the board-flow/UI contract, see `docs/design/board_flow_shooter_fusion.md`. That document is the source of truth for how the existing card-board interface should evolve around the movement/combat work happening in the other implementation thread.

## Why Third-Person First For The Prototype

- The game already has visible fighters and a card-table arena.
- The player needs to see their body, enemy tells, cards, chips, and target state at once.
- Melee, dodge, block, trap, guard-break, and flank reads map cleanly to the current card types.
- Third-person proves the card-to-ability contract before we productionize camera capture, networked aiming, and deeper shooter feel.

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
