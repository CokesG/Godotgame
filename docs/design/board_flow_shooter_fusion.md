# Dead Man's Ante - Board Flow / Shooter Fusion

Status: UI/flow contract for the shooter-combat branch
Last updated: 2026-05-15

## North Star

Dead Man's Ante should become a competitive shooter/combat game where the card system is the tactical economy, loadout, ability, and risk layer.

The board game flow should not feel like a separate card minigame. It should feel like the planning/buy/read phase of a cursed arena shooter.

```text
draw hand -> buy/equip/slot cards -> enter live combat -> cards become weapons/abilities/modifiers -> combat result pays economy/RPG growth -> new random hand
```

Reference feel:

- `Valorant`: buy phase, economy pressure, utility decisions, sound-readable abilities.
- `Overwatch` / `Marvel Rivals`: hero silhouettes, ability combos, team buffs/debuffs, readable spectacle.
- `Hearthstone`: clean cards, obvious costs, target clarity, hand/deck drama.
- `Dead Man's Ante`: poker risk, cursed table, chips, blood, tells, random hands, bluffing, wagering.

## What The Board Is Now

The board is the command table before and around a fight.

It answers:

- What hand did I draw?
- What can I afford?
- What am I equipping or holding?
- What abilities/weapons are armed for the live combat window?
- What enemy/team reads do I have?
- What risk am I wagering?
- What do I carry into the next round?

It should not ask the player to solve abstract coordinates. The 3x3 table can remain as a readable tactical lane/zone abstraction, but the actual combat fantasy is a real arena.

## Core Loop

### 1. Draw / Deal

The player draws a random hand from the run deck. This is the tactical constraint.

UI:

- Big hand at bottom.
- Cards grouped by purpose: Weapon, Ability, Utility, Economy, Read, Ritual.
- Each card says `Equip`, `Cast`, `Hold`, `Wager`, or `Burn`, not just `Play`.
- The next required click is always lit.

Purpose:

- Random hands create adaptation.
- Deckbuilding matters because it changes what tools can appear.
- Bad hands are not dead turns because cards can be burned for chips, ammo, armor, reload speed, or minor utility.

### 2. Buy / Slot

Cards can be spent into a limited combat kit for the round.

Suggested slots:

| Slot | Examples | Notes |
| --- | --- | --- |
| Weapon | Cursed pistol, rifle, shotgun, knife | Sets core combat feel for the round |
| Ability 1 | Smoke, dash, guard wall, reveal | Fast utility |
| Ability 2 | Trap, curse, mark, heal | Tactical utility |
| Passive | Armor, reload buff, lifesteal, recoil control | RPG/build expression |
| Wager | Raise, all-in, blood ritual | Risk/reward modifier |

Cards not slotted can be:

- held for later if rules allow,
- burned for chips/ammo/armor,
- discarded,
- committed face-down as a bluff/read trap.

### 3. Read / Wager

Enemy/team information is shown like shooter intel, not only card intent.

Examples:

- Enemy likely rushes left lane.
- Shield Guard will anchor objective.
- Duelist has dash available.
- Sniper has high-ground angle.
- Opponent economy is low, expect cheap utility.

Player decisions:

- Spend a Read card to reveal.
- Spend chips to buy counter-utility.
- Wager Blood/chips to empower a risky play.
- Bluff by committing a card that changes visible threat.

### 4. Live Combat

The other agent's movement/combat layer owns this.

Board UI should collapse into a combat HUD:

- equipped weapon,
- live ammo/chips/armor/Blood,
- ability cooldown cards,
- active buffs/debuffs,
- current objective,
- quick hand strip if mid-combat draws are enabled.

Cards become real combat actions:

- Weapon card equips a shooter weapon.
- Smoke card creates a real smoke volume.
- Trap card places a real trap.
- Mark card highlights/weakens a target.
- Guard card creates a barrier or parry stance.
- Ritual card channels a high-risk ultimate.

### 5. Payout / RPG Growth

After the fight:

- kills/objective/time/card efficiency pay chips,
- wounds reduce Blood,
- cards used may exhaust, upgrade, mutate, or gain XP,
- player chooses reward: new card, weapon mod, relic, perk, or economy bonus.

## Card Purposes

Every card needs one or more clear purposes.

| Card Class | Shooter Meaning | Board Meaning |
| --- | --- | --- |
| Weapon | Equip/buy weapon or ammo type | Commit main combat style |
| Ability | Active skill in combat | Spend hand resource for utility |
| Economy | Chips, buy discounts, refunds | Controls future power |
| Read | Reveal enemy plan/position | Reduces uncertainty |
| Movement | Dash, blink, vault, reposition | Changes combat options |
| Defense | Armor, shield, parry, barrier | Survive burst or hold space |
| Debuff | Blind, slow, mark, jam, curse | Weakens enemy skill layer |
| Team | Heal, buff, revive, share vision | Supports co-op/team identity |
| Ritual | Ultimate/high-risk power | Wager Blood/cards/chips |

Bad card states should still have purpose:

- Burn for +chips.
- Burn for ammo.
- Convert into armor.
- Cycle for a new draw at economy cost.
- Commit as bluff.
- Save as a passive charge.

## Economy

Use chips as the shooter economy currency.

Sources:

- round win,
- kill/assist/objective,
- risky wager,
- burning cards,
- relic/perk bonuses.

Sinks:

- buy weapons,
- buy armor,
- slot abilities,
- upgrade cards,
- reroll hand/shop,
- revive/repair,
- raise wager.

UI should show economy like a buy phase:

```text
CHIPS 7 | BLOOD 24 | ARMOR 2 | AMMO 18 | HAND 5 | DECK 14
```

## RPG Progression

RPG depth should live in persistent build identity:

- hero archetype,
- weapon mastery,
- card upgrades,
- relics/perks,
- class passives,
- enemy faction counters,
- team role identity.

Example upgrade paths:

- `Quick Slash` -> `Quick Draw`: pistol quickshot with lower spread.
- `Guard Up` -> `Loaded Guard`: armor plus reload stability.
- `Read Tell` -> `Deadeye Tell`: reveal enemy outline for 1.5s.
- `Smoke Curse` -> `Marked Smoke`: enemies exiting smoke are revealed.

## UI Redesign

### First Screen

Replace the static run panel feeling with a tactical prep table.

Layout:

- Top: route/table/opponent/economy strip.
- Center: 3D arena preview with enemy silhouettes and objective.
- Bottom: large card hand.
- Right: current loadout slots.
- Left or overlay: next action and enemy read.

Primary button copy:

- `Deal Hand`
- `Slot Loadout`
- `Enter Arena`
- `Resolve Payout`

### Prep / Buy Screen

The player drags or clicks cards into slots.

Required visible areas:

- Hand: random options.
- Loadout: what will exist in combat.
- Economy: can I afford this?
- Enemy Read: what am I countering?
- Burn/Cycle: what do dead cards become?

### Combat HUD

When live combat begins, cards compress into ability icons.

HUD:

- weapon reticle/ammo,
- ability cards as cooldown tiles,
- economy and Blood small,
- status effects,
- objective,
- quick read/wager prompt if relevant.

### Payout Screen

Show cause and effect:

- cards used,
- damage/healing/utility impact,
- chips gained/spent,
- Blood lost,
- cards upgraded/exhausted,
- rewards.

## Data Contract For Combat Agent

The movement/combat implementation should expose a simple bridge.

Board sends:

```gdscript
{
	"weapon_card": "cursed_revolver",
	"ability_cards": ["smoke_veil", "guard_wall"],
	"passive_cards": ["loaded_dice"],
	"wager_cards": ["blood_ritual"],
	"economy": {"chips": 7, "armor": 2, "ammo": 18},
	"reads": {"enemy_plan": "left_rush", "confidence": 0.65}
}
```

Combat returns:

```gdscript
{
	"outcome": "win",
	"kills": 2,
	"assists": 1,
	"objective_score": 80,
	"damage_dealt": 116,
	"damage_taken": 12,
	"cards_used": ["cursed_revolver", "smoke_veil"],
	"chips_delta": 4,
	"blood_delta": -12,
	"upgrade_events": ["smoke_veil_xp_plus"]
}
```

## Immediate Implementation Path

1. Rename the existing `Energy` concept toward `Chips` or `Focus` depending on whether it is buy economy or per-turn action budget.
2. Add visible loadout slots beside the hand: Weapon, Ability 1, Ability 2, Passive, Wager.
3. Let cards be assigned to slots before combat instead of only played directly.
4. Add `Burn` as a universal fallback so every drawn card has value.
5. Convert card type labels into shooter roles: Weapon, Ability, Utility, Economy, Read, Defense, Ritual.
6. Collapse the board into a combat HUD once the other movement/combat scene takes over.
7. Build the bridge data contract between board UI and combat scene.

## Design Rule

Cards are not the fight. Cards are the economy, equipment, abilities, reads, and wagers that shape the fight.
