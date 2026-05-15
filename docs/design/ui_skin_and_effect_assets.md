# Dead Man's Ante - UI Skin And Effect Asset Plan

Status: Phase 81 opening class showcase wired
Last updated: 2026-05-15

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

## Phase 48 Opening Screen Onboarding

The opening screen now uses one player-facing verb: `Deal In`.

Keep this language consistent across the start button, first-play path, card-lock tooltips, run map copy, tests, and handoff notes. Avoid restoring `Open Opening Table`; it read like debug/control language and made the first click harder to understand.

Current opening screen structure:

- Branded title plaque.
- `Opening Table` shell with a centered `Deal In` button.
- Four interactive step chips: `1 DEAL IN`, `2 TARGET`, `3 CARD`, `4 RESOLVE`.
- Compact continuity text: Blood, Deck, and first-fight readiness.
- Visible colorful route chips for all five tables, with Table 1 marked `READY` and future tables marked `LOCKED`.
- Hidden report-style approach/encounter/debug panels until combat or later route states need them.

Interaction rules:

- Pressing `Deal In`, the Table 1 route chip, or the first opening step starts combat.
- Pressing later opening steps before combat gives feedback instead of doing nothing.
- Hovering route chips gives lightweight feedback.
- The old `ActionCuePanel` still owns cue data for compact/reward states, but it stays hidden on the opening screen so it does not duplicate the hero action.

No custom 3D models are needed for this opening pass. The 3D consequence layer starts after `Deal In`; the start screen should use the current table backdrop, color, route motion, button pulse, and short actionable copy to feel alive.

## Phase 81 Opening Class Showcase

The opening screen now sells the FPS/card fusion before the first click. It should read as a pre-fight identity pick, not a settings form.

Runtime pieces:

- `StartHeroClassPanel` shows three selectable fighter buttons before `Deal In`.
- The selected fighter drives the opening run deck and bridge `hero_class` payload.
- The spotlight image uses existing generated card art as temporary class identity art:
  - `card_quick_slash.png` for Gambler-Knight / Duelist
  - `card_marked_card.png` for Hex Sharpshooter / Controller
  - `card_blood_ritual.png` for Blood Wager / Berserker
- The hidden `StartHeroClassOption` remains as compatibility plumbing for tests and selector sync, but players should use the visual fighter cards.
- Opening copy now says that cards become weapons, armor, reads, traps, and FPS abilities in the arena.

Asset note for future agents: we do not yet have true hero portrait PNGs or class key art. Do not treat the current card-art spotlight as final character art. The next asset upgrade should generate or paint dedicated transparent/portrait crops for each fighter class, then keep the same selection flow.

## Phase 49 Action-Guide VFX

The prototype now has an explicit action-guide layer for the first loop. This is the answer to "what do I click right now?"

Runtime pieces:

- `CombatVFX.play_click_beacon_on(target, color, label)` draws pulsing rings and a floating action badge over the current click target.
- `OpeningClickPrompt` reinforces the first `CLICK DEAL IN` action.
- `NextActionBadge` sits next to the live combat action button and says the current next action.
- `HandActionStatus` now switches through concrete `NEXT:` instructions:
  - click an enemy `TARGET`
  - play a glowing card
  - click `Resolve Turn`
- The action guide target advances from `Deal In` to enemy target cards to playable hand cards to `Resolve Turn`.

Keep this system state-driven. Future agents should update `_get_action_guide_snapshot()` and `_get_player_commit_action_guide()` when adding new phases, mechanics, or alternate first-loop paths. Do not add loose one-off labels that can disagree with the guide.

Next polish should add audio ticks and stronger card-ready animation, not more explanatory copy.

## Phase 50 Battlefield Target Readability

Live combat now treats target identity as part of the battlefield, not just a card border.

Current live target surfaces:

- `BattlefieldFocus` says `YOU -> TARGET` above the arena.
- `OpponentTargetTitle` names the current target and tells the player they can click another enemy to switch.
- The `CombatGrid` title mirrors the same `YOU -> target` language.
- The targeted grid cell labels itself `TARGET`.
- The active enemy card says `YOUR TARGET`; inactive enemy cards say `SWITCH TARGET`.

Future target changes should update all of these surfaces together. If a card uses a non-enemy target, the guide should explicitly switch language to `MOVE`, `SELF`, or `TRAP` instead of leaving the player guessing.

## Phase 51 Enemy Role And Battlefield Language

The enemy cards now need to read like combatants, not debug nouns. `Skulker` is an enemy fighter archetype: a `Knife Duelist` / trickster. `Shieldbearer` is an enemy fighter archetype: a `Shield Guard` / protector. They are not heroes, abstract cards, or board coordinates.

Runtime target surfaces should answer:

- who am I attacking?
- what kind of fighter are they?
- what are they likely to do next?
- why might I target them?

Current live combat copy follows that contract:

- `BattlefieldFocus` uses `DUELING: enemy | role | intent | next action`.
- Enemy target cards say `ATTACKING` for the active target and `CLICK TO TARGET` for other enemies.
- Target cards include role, HP, likely intent, and a short reason such as `Why: fast trickster` or `Why: guards allies`.
- `HandActionStatus` keeps literal onboarding verbs: `TARGET`, `glowing card`, and `Resolve Turn`.

Future agents should preserve this battle-fiction layer when adding 3D models, particles, or more enemies. A fancy arena still fails if the enemy card does not quickly say what the thing is and why the player should care.

## Phase 52 Arena Spectacle Direction

The 3D consequence layer should become a staged card arena, not a separate action game. The card game remains the rules engine; the arena is the visible consequence layer.

Godot capabilities this pass leans on:

- `SubViewportContainer` keeps the 3D arena embedded behind the 2D card/table UI.
- Scripted `Tween` beats drive lunges, target pulses, camera bumps, card impacts, and quick readable motion.
- Lightweight 3D meshes are enough for early role silhouettes before final models exist.
- Future particle work should graduate from procedural mesh bursts to `GPUParticles3D` emitters for smoke, sparks, slash trails, and chip scatter once the timing feels right.

Runtime spectacle added in this direction:

- `Arena3DView` now builds lane strips, table chips, candle glows, and a persistent target spotlight.
- Target selection moves a gold attack ring under the chosen enemy and fires a short target beam.
- Attack cards add a beam plus lunge, impact burst, unit shake, and camera pulse.
- Enemy silhouettes differ by role: Skulker/duelist is slimmer, Shieldbearer/guard is blockier, Brute is heavier, Needle-Eye is narrow.

Next spectacle pass should make the chosen enemy card and 3D pawn act as one object: hover enemy card highlights pawn, hover pawn highlights card, and card play draws a visible arc from the hand into the arena impact.

## Phase 53 Hand-To-Arena Unity

Cards and pawns should feel physically linked. The player should not have to mentally translate `card -> target card -> grid cell -> 3D pawn`; hovering or playing should draw that relationship on screen.

Runtime pieces now in place:

- `CombatVFX.play_card_fly_between()` travels on a curved arc instead of a straight line.
- `CombatVFX.play_card_preview_arc()` draws a short hover-preview arc from a hand card to the current target.
- `CombatVFX.play_link_between_targets()` draws a pulse from an enemy target card to its pawn.
- `Arena3DView.preview_card_intent()` pre-lights the target pawn or destination for hovered cards.
- `Arena3DView.focus_unit()` makes the selected pawn breathe under the target spotlight.

Design rule: every attack/read/move card hover should create a visible path into the battlefield before the click. Every target-card hover should link the card and pawn. This is the quickest way to make the game feel like an arena card game rather than separate UI panels.

## Phase 54 Generated VFX Sprite Strips

The first generated PNG sprite strips are now in `art/game/vfx/generated/` and wired into `CombatVFX.gd`:

- `vfx_slash_strip.png`
- `vfx_smoke_strip.png`
- `vfx_chip_scatter_strip.png`
- `vfx_ritual_glow_strip.png`

These are transparent horizontal strips. The runtime animates them with `AtlasTexture` regions, then keeps procedural particles as secondary sparks. This gives each effect a clearer authored silhouette without losing quick Godot-native tuning.

The second generated strip pass added:

1. `vfx_guard_shield_strip.png`
2. `vfx_blood_hit_strip.png`
3. `vfx_death_ash_strip.png`
4. `vfx_card_burn_strip.png`

Guard, blood, ash, and exhaust-tagged card play now use generated sprite strips layered over procedural particles. Future polish should focus on timing and sound pairing rather than adding more effect categories immediately.

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
art/game/vfx/generated/vfx_slash_strip.png
art/game/vfx/generated/vfx_smoke_strip.png
art/game/vfx/generated/vfx_chip_scatter_strip.png
art/game/vfx/generated/vfx_ritual_glow_strip.png
art/game/vfx/generated/vfx_guard_shield_strip.png
art/game/vfx/generated/vfx_blood_hit_strip.png
art/game/vfx/generated/vfx_death_ash_strip.png
art/game/vfx/generated/vfx_card_burn_strip.png
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
