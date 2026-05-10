# Dead Man's Ante - Mega Prompt And Build Sequence

Status: working design source of truth  
Engine: Godot 4.6.x  
Project path: `C:\Game Dev\CodexGame`  
MCP target: Godot AI via `http://127.0.0.1:8000/mcp`

## Creative North Star

Every turn should feel like staring across a cursed poker table, knowing the monster might be lying, and deciding whether to fold, call, or bet your life.

## Working Pitch

Dead Man's Ante is a dark 2D tactical roguelike deckbuilder where each combat turn plays like a poker hand. The player moves across a compact 3x3 grid, builds card combinations, reads uncertain enemy intent, commits cards before full information is revealed, and uses Call, Fold, Raise, and All-In decisions to survive cursed encounters.

The game is not "Slay the Spire but darker." The hook is poker tension: hidden information, reads, baiting, bluffing, overcommitting, folding, and calling enemy intent.

## Best Phase Sequence

This is the recommended order for building the project piece by piece.

### Phase 0 - Foundation Lock

Goal: make the project easy to grow without building the whole game yet.

Build:
- Project folder structure
- Core resource classes
- Core scene shells
- Debug-only placeholder art
- Basic test scene
- README/design docs

Do not build yet:
- Final art
- Full run map
- Many classes
- 100-card content
- Complex meta progression

Success criteria:
- The project opens cleanly in Godot.
- We can run one empty combat scene.
- We have clear places for cards, enemies, UI, and combat scripts.

### Phase 1 - Combat State Machine

Goal: make a turn advance through visible phases.

Build:
- `TurnManager`
- Phase enum
- Signals for phase changes
- Combat log
- Debug buttons for next phase/reset
- Stub phases:
  - StartTurn
  - Draw
  - EnemyIntentPreview
  - PlayerCommit
  - BluffWager
  - Reveal
  - Resolve
  - Cleanup

Success criteria:
- Press Play and step through a full turn loop.
- The UI clearly shows the current phase.
- The log records phase transitions.

### Phase 2 - 3x3 Tactical Grid

Goal: prove the spatial combat surface.

Build:
- 3x3 grid scene
- Grid cells
- Occupancy rules
- Player token
- Enemy token
- Movement validation
- Hover/selection highlights

Success criteria:
- Player and enemy occupy valid grid cells.
- Player can move by a simple debug command or starter movement card.
- Invalid movement is rejected and logged.

### Phase 3 - Card Data And Deck Loop

Goal: make cards data-driven and playable.

Build:
- `CardDefinition` resource
- `DeckManager`
- Draw pile, hand, discard, exhaust
- Hand UI
- Basic CardView
- 10 starter cards

Success criteria:
- Combat starts with a deck.
- Draw 5 cards.
- Play a card and move it to discard/exhaust.
- Shuffle discard into draw pile when needed.

### Phase 4 - Targeting And Resolution

Goal: cards affect the grid and units.

Build:
- Targeting types:
  - Self
  - Enemy
  - Grid cell
  - Lane
  - Any unit
- `CombatResolver`
- Action queue
- Damage
- Guard
- Movement
- Trap placement

Success criteria:
- At least one attack, one defense, one movement, and one trap card work.
- Resolution order is readable in the combat log.

### Phase 5 - Enemy Intent Ranges

Goal: replace exact enemy intent with readable uncertainty.

Build:
- `EnemyDefinition`
- `IntentDefinition`
- `EnemyIntentSystem`
- Hidden chosen intent
- Public weighted preview
- Debug panel showing hidden truth
- Enemy behaviors for 3 sample enemies

Success criteria:
- Enemy displays "likely / possible / rare" intent options.
- The hidden intent resolves during Reveal.
- Debug mode can show the exact selected intent for testing.

### Phase 6 - Commit / Bluff / Reveal

Goal: implement the killer mechanic.

Build:
- Commit one card face-down or semi-hidden
- Call enemy lane/action
- Fold committed card for partial refund
- Raise by spending Nerve
- Wager payoff and penalty
- Reveal timing

Success criteria:
- Player can make a risky prediction.
- Correct calls feel rewarding.
- Wrong calls hurt but do not feel random.
- The combat log explains the result.

### Phase 7 - Prototype Content Slice

Goal: turn systems into a tiny real game.

Build:
- 1 class: Gambler-Knight
- 20 cards
- 5 enemies
- 1 elite
- 1 boss
- 5 relics
- 1 test run path

Success criteria:
- A 15-minute run is playable from start to finish.
- There is a real win/loss condition.
- A player can describe what kind of deck they built.

### Phase 8 - Rewards, Relics, And Run Map

Goal: make the roguelike loop real.

Build:
- Combat rewards
- Card reward screen
- Relic reward screen
- Rest/shop/event placeholders
- Linear or branching map
- Difficulty scaling

Success criteria:
- After combat, choose rewards.
- Move to the next node.
- Reach a boss after several encounters.

### Phase 9 - UX And Feel

Goal: make the prototype understandable and watchable.

Build:
- Better phase banners
- Better intent display
- Preview possible outcomes
- Hover tooltips
- Faster animation queue
- Screen shake/sound placeholders
- Tutorial tips

Success criteria:
- A new player can understand the basic loop within 3 minutes.
- Hidden information feels fair, not arbitrary.
- Turns are fast enough to stay tense.

### Phase 10 - Steam Demo Path

Goal: expand only after the hook is proven.

Build:
- 2 playable classes
- 60-90 cards
- 20-30 enemies
- 3 bosses
- 30-45 minute run
- Tutorial
- Strong store-page trailer moments

Success criteria:
- Demo has replayability.
- Trailer can communicate the hook in 10 seconds.
- The game has a strong visual and mechanical identity.

## Immediate Next Implementation Tasks

1. Create the Godot folder structure.
2. Create `CardDefinition.gd`.
3. Create `EnemyDefinition.gd`.
4. Create `IntentDefinition.gd`.
5. Create a `TestCombat.tscn` with placeholder UI.
6. Implement `TurnManager.gd`.
7. Add a combat log.
8. Add a 3x3 grid.
9. Add a player token and one enemy token.
10. Add a debug button to step through turn phases.

## Mega Prompt

```text
You are a senior Godot 4 game director, systems designer, technical architect, and roguelike deckbuilder expert.

I am building a commercially viable indie game in Godot 4. This is a dark tactical roguelike deckbuilder inspired by the design strengths of Slay the Spire, Balatro, Monster Train, Dicey Dungeons, Inscryption, Wildfrost, Into the Breach, Backpack Hero, and tactical grid RPGs.

Do not clone any one game. Create a distinct game with its own identity.

The game must combine:
- Roguelike deckbuilding
- Tactical grid combat
- Poker-style bluffing, reading, folding, calling, and betting
- Enemy intent telegraphs
- High-skill decision-making
- Replayable runs
- Data-driven card/enemy/relic design
- A realistic Godot 4 implementation plan

The goal is to design a game that is fun, readable, streamable, expandable, and commercially viable for a small indie team.

Core creative direction:
The game is a dark tactical card battler where the player enters cursed encounters and fights enemies using cards that can attack, move, summon, mutate, trap, shield, manipulate intent, or alter the battlefield.

The unique hook:
Combat is not just about playing the best card. It is about reading enemy intentions, bluffing enemy reactions, committing resources, baiting attacks, and deciding when to fold a plan before it collapses.

I want the game to feel like:
- Slay the Spire strategic deckbuilding
- Balatro's poker-hand tension and combo escalation
- Into the Breach's tactical forecasting
- Inscryption's dark table atmosphere
- Backpack Hero's spatial loadout decisions
- A fighting game's mind games, but turn-based

Create a full game design and technical blueprint.

Required output sections:

1. High Concept
Give me a clear one-paragraph pitch for the game.
Include:
- Genre
- Player fantasy
- Core loop
- Unique hook
- Why it would be fun to watch on YouTube/Twitch

2. Core Design Pillars
Define 5 to 7 design pillars.
Examples:
- Every turn should feel like a hand of poker
- Enemies should be readable but not fully solved
- Cards should create positional consequences
- Strong players should win through reads, not just math
- Runs should generate stories

For each pillar, explain how it affects actual gameplay decisions.

3. The Killer Mechanic
Design the main mechanic that separates this game from Slay the Spire and Balatro.

Explore at least 3 possible versions:
A. Poker Hand Combat
B. Bluff / Call / Fold System
C. Hidden Enemy Intent System
D. Grid Placement Card System
E. Betting Health, Armor, Energy, or Cards

Then choose the best version and explain why.

The system should include:
- What the player sees
- What is hidden
- What can be predicted
- How bluffing works
- How enemies respond
- How skilled players exploit patterns
- How new players avoid feeling lost

4. Core Combat Loop
Design the exact turn structure.

Include:
- Start of turn
- Draw phase
- Read phase
- Commit phase
- Bluff phase
- Reveal phase
- Resolution phase
- Enemy reaction phase
- Cleanup phase

Also include:
- What the player can do each turn
- How cards are played
- How movement works
- How attacks work
- How enemy telegraphs work
- How the battlefield changes
- How risk/reward decisions happen

5. Tactical Grid System
Design the battlefield.

Should it be:
- 3x3?
- 4x4?
- 5x5?
- Lane-based?
- Player side vs enemy side?
- Shared battlefield?

Recommend the best grid size for a first version.

Include:
- Movement rules
- Attack ranges
- Line of sight
- Cover
- Hazards
- Traps
- Summons
- Terrain modifiers
- Enemy positioning
- Card placement rules

Keep the first version realistic for Godot.

6. Poker-Inspired Systems
Design poker-like mechanics without making it a literal poker clone.

Include systems such as:
- Pairs
- Three-of-a-kind
- Straights
- Flush-like suit synergies
- High-card emergency plays
- Bluff cards
- Tell-reading
- Enemy call behavior
- Raising the stakes
- Folding a card/turn/position
- Burning cards
- Discard manipulation
- Pot-building
- All-in mechanics

Explain how these translate into a dark tactical card battler.

7. Card System
Design the card architecture.

Cards should include:
- Attacks
- Movement
- Defense
- Rituals
- Summons
- Traps
- Mutations
- Reads
- Bluffs
- Reactions
- Battlefield modifiers

For each card type, define:
- Purpose
- Example cards
- Targeting rules
- Energy/resource cost
- Upgrade path
- Synergies
- Counterplay
- UI requirements

Create 30 starter cards:
- 10 attack cards
- 5 defense cards
- 5 movement cards
- 5 bluff/read cards
- 5 tactical/grid cards

Each card should include:
- Name
- Cost
- Type
- Effect
- Upgrade
- Rarity
- Design note

8. Resource Systems
Design the main resources.

Consider:
- Energy
- Cards
- Position
- Health
- Guard
- Nerve
- Momentum
- Threat
- Wager
- Blood
- Focus
- Suspicion
- Ante

Recommend 3 to 5 resources only. Avoid overdesign.

Explain:
- What each resource does
- How it is gained
- How it is spent
- How it creates difficult choices
- How it supports bluffing

9. Enemy Design
Design enemy behavior around poker-like reads.

Enemies should have:
- Intent ranges, not always exact intents
- Personality types
- Bluff tendencies
- Aggression levels
- Call/fold behavior
- Punish patterns
- Tells
- False tells
- Escalation over time

Create 12 enemy archetypes:
- Basic attacker
- Shield enemy
- Trickster
- Summoner
- Sniper
- Brute
- Gambler
- Mimic
- Hex caster
- Trap setter
- Boss lieutenant
- Final boss prototype

For each enemy:
- Role
- HP
- Behavior
- Intent style
- Bluff/read interaction
- Counterplay
- Visual identity

10. Boss Design
Design 3 bosses.

Each boss should force different mastery:
- Boss 1 teaches reading intent
- Boss 2 teaches bluffing and commitment
- Boss 3 tests deck synergy, positioning, and risk management

For each boss include:
- Name
- Theme
- Phases
- Signature mechanics
- How it bluffs
- How the player counters it
- What makes it memorable
- Streamer moment potential

11. Run Structure
Design the roguelike run.

Include:
- Map structure
- Encounters
- Elites
- Shops
- Rest sites
- Events
- Cursed bargains
- Bosses
- Deck rewards
- Relics/artifacts
- Meta unlocks, if any

Recommend a first prototype run length.

Also design:
- What happens after each combat
- How rewards are selected
- How difficulty scales
- How the player builds identity during a run

12. Relics / Artifacts
Design 25 relics.

They should support:
- Poker combos
- Bluffing
- Grid manipulation
- Card draw/discard
- Risk/reward
- Enemy intent reading
- Boss counterplay
- Build-defining strategies

For each relic:
- Name
- Rarity
- Effect
- Build it supports
- Potential balance risk

13. Character Classes
Design 3 playable classes for the first version.

Each class should have:
- Different deck identity
- Different bluff style
- Different grid style
- Different resource interaction
- Different difficulty level

Example directions:
- The Duelist: reads and counters
- The Cultist: sacrifices cards/health for power
- The Tactician: controls grid and enemy intent
- The Gambler: pushes risk and reward
- The Beast: mutates and snowballs

For each class:
- Fantasy
- Starting deck
- Starting relic
- Core mechanic
- Strengths
- Weaknesses
- Skill ceiling

14. High Skill Gap Design
Explain how the game rewards mastery.

Include:
- Reading enemy patterns
- Bluff timing
- Card counting
- Deck thinning
- Positioning
- Risk management
- Knowing when to fold
- Manipulating enemy AI
- Planning multiple turns ahead
- Building around probabilities

Give examples of:
- A beginner play
- An intermediate play
- An expert play
using the same combat situation.

15. Anti-Frustration Design
Because bluffing and hidden info can feel unfair, design safeguards.

Include:
- How much information should be shown
- How to avoid random-feeling losses
- How to teach enemy tells
- How to preview possible outcomes
- How to communicate risk
- How to make failure feel earned
- How to give players recovery tools

16. Godot 4 Technical Architecture
Design the Godot project architecture.

Include:
- Scene structure
- Autoload singletons
- Data-driven card definitions
- Resource files
- JSON or .tres content pipeline
- Combat state machine
- Turn manager
- Deck manager
- Hand UI
- Grid manager
- Enemy AI manager
- Intent system
- Animation/event queue
- Save system
- Run generation system
- Reward system
- Debug tools

Use realistic Godot 4 patterns.

Recommend whether cards should be:
- Control nodes
- Node2D objects
- Hybrid UI rendered to texture
- Data resources with visual scenes

Explain the choice.

17. Suggested File/Folder Structure
Create a clean Godot folder structure.

Include folders for:
- scenes
- scripts
- resources
- cards
- enemies
- relics
- UI
- combat
- maps
- events
- saves
- art
- audio
- tests/debug

18. Data Models
Create example data structures for:
- CardDefinition
- EnemyDefinition
- RelicDefinition
- CombatEncounter
- RunNode
- StatusEffect
- IntentDefinition
- PlayerClass

Use GDScript-style pseudo-code or JSON-style examples.

19. Core Systems Implementation Plan
Break development into milestones.

Milestone 1: Paper prototype
Milestone 2: Godot combat prototype
Milestone 3: Card hand + deck system
Milestone 4: Grid + enemy intent
Milestone 5: Bluff/read/fold system
Milestone 6: Rewards + relics
Milestone 7: Run map
Milestone 8: First boss
Milestone 9: UX polish
Milestone 10: Steam demo

For each milestone include:
- Goal
- Features
- What not to build yet
- Success criteria

20. First 30-Day Development Plan
Give me a realistic 30-day plan for one developer using Godot and AI coding tools.

Break it into weeks:
- Week 1
- Week 2
- Week 3
- Week 4

Each week should include:
- Main goal
- Systems to build
- Testable outcome
- Common mistakes
- Codex/Cursor prompts to use

21. Codex/Cursor Task Prompts
Give me 20 highly specific prompts I can feed into Codex/Cursor.

They should cover:
- Godot project setup
- Card data resources
- Turn manager
- Deck/hand/discard
- Drag-and-drop cards
- Grid targeting
- Enemy intent system
- Bluff/call/fold logic
- Combat resolver
- Animation queue
- Relic modifiers
- Reward screen
- Run map
- Save/load
- Debug panel
- Balance simulator
- Unit tests
- UI polish

Each prompt should be written as if I am giving it directly to Codex.

22. Prototype Scope
Define the smallest playable prototype.

It should include:
- 1 class
- 20 cards
- 5 enemies
- 1 elite
- 1 boss
- 3 relics
- 1 grid
- 1 run path
- 15-minute run loop

Also define what to cut:
- No multiplayer
- No procedural mystery
- No huge meta progression
- No 3D
- No complex animations
- No advanced economy

23. Steam Demo Scope
Define a realistic Steam Next Fest-style demo.

Include:
- Content target
- Run length
- Number of classes
- Number of cards
- Number of enemies
- Number of bosses
- Art level
- UI polish
- Tutorial
- Replayability target

24. Monetization and Market Positioning
Suggest:
- Steam price range
- Demo strategy
- Early Access or full launch
- Trailer hook
- Capsule art direction
- Store page positioning
- Tags
- Player promise

Do not overpromise.

25. Risks and Fixes
List the top 15 risks.

Examples:
- Too much randomness
- Bluffing feels unfair
- Grid slows combat
- Cards are hard to read
- Too many systems
- Weak visual identity
- Poor balance
- Slow turns
- Bad tutorial
- No emotional hook

For each risk, give a practical fix.

26. Final Recommendation
At the end, give me:
- The best version of this game to build
- The exact first prototype to create
- The first 5 systems to implement
- The first 5 things to avoid
- A concise creative north star

Be opinionated. Prioritize fun, commercial viability, Godot feasibility, and a high skill ceiling.
```

## Genre Take

The best version is not just "cards on a grid."

The best version is:

> A tactical deckbuilder where each turn is a poker hand and each enemy is trying to read you back.

Working title ideas:

```text
Dead Man's Ante
Cursed Hand
The Last Table
Wagerbound
Blood Ante
House of Ruin
The Devil Calls
```

Clean pitch:

> A dark tactical roguelike deckbuilder where you fight monsters by building poker-like card combinations, bluffing enemy intent, and wagering your position, health, and deck to survive cursed grid battles.

The reason this is stronger than a normal deckbuilder is that it creates human drama:

```text
Do I commit this combo now?
Is the enemy baiting me?
Can I afford to hold this card?
Do I fold and lose tempo?
Do I call the enemy's bluff?
Do I go all-in before the boss transforms?
```

## Killer Mechanic To Build First

Build the game around Commit / Bluff / Reveal.

Each turn has two layers:

```text
Visible layer:
Enemy shows possible intents, not exact intent.

Hidden layer:
You commit cards face-down or semi-hidden into lanes/grid slots before the full enemy action is revealed.
```

Example:

```text
Enemy intent shown:
60% chance: heavy attack left lane
25% chance: guard center
15% chance: feint and strike weakest unit
```

The player commits:

```text
Face-up card:
Move right.

Face-down card:
Counterstrike.

Wager:
Spend 2 Nerve to double counter damage if the enemy attacks.
```

Then reveal:

```text
Enemy was feinting.
Your counter misses.
But your movement saved you.
You lost Nerve but kept tempo.
```

That is where the game becomes skillful.

## Poker Translation

Do not make poker hands just "pair = damage." That is too shallow.

Use poker as a decision language:

| Poker concept | Game translation |
| --- | --- |
| Pair | Two cards of same school create a bonus |
| Three-of-kind | Strong combo but requires hand management |
| Straight | Sequence of costs or positions creates chain effects |
| Flush | Same suit/school empowers a ritual |
| High card | Weak but reliable emergency action |
| Bluff | Commit a card that changes enemy targeting |
| Call | Predict enemy action and punish it |
| Fold | Cancel a committed card to regain partial resources |
| Raise | Wager health, guard, or nerve for stronger payoff |
| All-in | Spend your remaining hand for a huge effect |
| Tell | Enemy has behavioral hints |
| False tell | Elite/boss can fake a pattern |

## First Prototype Version

```text
Title prototype:
Dead Man's Ante

Format:
2D tactical roguelike deckbuilder in Godot 4

Battlefield:
3x3 shared grid

Player:
One hero token on the grid

Enemies:
1-3 enemy tokens

Turn:
Draw 5 cards
Enemy shows uncertain intent
Player plays up to 3 cards
Player may commit 1 card face-down
Player may wager Nerve
Reveal enemy action
Resolve cards and attacks
```

First playable content:

```text
1 class: The Gambler-Knight
20 cards
5 enemies
1 elite
1 boss
5 relics
1 map path
15-minute run
```

## First Class

### The Gambler-Knight

Fantasy:

```text
A cursed duelist who survives by reading monsters, baiting attacks, and wagering his own blood against fate.
```

Core resources:

```text
Energy: play cards
Guard: block damage
Nerve: wager resource
Blood: health and emergency power
```

Core mechanic:

```text
Call: If you correctly predict an enemy attack lane, trigger bonus damage or defense.

Fold: Cancel one committed card and regain 1 Energy, but lose Nerve.

Raise: Spend Nerve to increase the payoff of a card before reveal.

All-In: Spend all remaining Nerve for a massive effect, but become exposed if wrong.
```

## First Combat Grid

Use 3x3, not 5x5.

Why:

```text
Easy to read.
Fast turns.
Good for Steam Deck and possible mobile later.
Enough space for positioning.
Not overwhelming for card targeting.
Easier AI.
Easier UI.
```

Basic layout:

```text
[ ][ ][ ]
[ ][ ][ ]
[ ][ ][ ]
```

Player and enemies share the same grid.

This creates tactical drama:

```text
Do I step into danger for a better attack?
Do I bait the brute into the trap?
Do I block the lane or dodge?
Do I hold center control?
```

## First Enemy Intent System

Do not show exact intent like Slay the Spire.

Show intent ranges:

```text
Brute:
Likely: Smash nearest target
Possible: Guard
Rare: Roar and gain Rage
```

After the player learns the enemy:

```text
Brute tell:
If Brute clenches weapon, Smash chance rises.
If Brute lowers head, Roar chance rises.
```

Bosses can fake tells.

That gives bluffing without making the game feel random.

## Target Fun Moment

The best moment should feel like this:

```text
The boss appears to be attacking left.
You suspect a feint.
You fold your left-lane counter.
You move center.
You commit a face-down punish card.
The boss reveals the feint.
You call it correctly.
Your trap triggers.
The boss is stunned.
Chat goes wild.
```

## Starter Implementation Prompt

```text
You are a senior Godot 4 engineer helping me build a 2D tactical roguelike deckbuilder prototype called Dead Man's Ante.

The game combines card combat, a 3x3 tactical grid, enemy intent prediction, and a poker-inspired Commit / Bluff / Reveal system.

Build the project architecture only. Do not create final art. Use placeholder UI and simple colored shapes.

Requirements:
- Godot 4.x
- GDScript
- Data-driven cards using Resource classes
- Data-driven enemies using Resource classes
- 3x3 grid combat board
- Player token and enemy tokens
- Deck, draw pile, hand, discard pile
- Turn manager with phases:
  1. StartTurn
  2. Draw
  3. EnemyIntentPreview
  4. PlayerCommit
  5. BluffWager
  6. Reveal
  7. Resolve
  8. Cleanup
- Card types:
  Attack
  Defense
  Movement
  Bluff
  Read
  Trap
  Ritual
- Basic drag-and-drop hand UI
- Cards can target grid cells, enemies, or self
- Enemy intents are probability-weighted, not always exact
- Player can Call, Fold, or Raise during the commit phase
- Combat log shows every resolved action
- Debug panel shows hidden enemy intent for testing
- Modular enough to add relics later

Create:
1. Folder structure
2. Core scenes
3. Core scripts
4. Resource definitions
5. Example 10 cards
6. Example 3 enemies
7. One playable test combat
8. Clear comments explaining where to expand

Prioritize clean architecture over visuals.
Do not overbuild.
Make sure the first prototype can be played in one test scene.
```

## First 10 Codex Tasks

```text
1. Create CardDefinition.gd as a Godot Resource with cost, type, rarity, targeting, tags, effects, upgrade data, and display text.

2. Create EnemyDefinition.gd as a Resource with HP, intent list, behavior tags, tells, bluff chance, and reward data.

3. Build a TurnManager.gd with explicit turn phases and signals for phase transitions.

4. Build DeckManager.gd with draw pile, hand, discard pile, exhaust pile, shuffle behavior, and debug draw controls.

5. Build CombatGrid.gd for a 3x3 grid with cell occupancy, valid movement, valid targeting, and hover highlights.

6. Build CardView.tscn and HandView.gd for card rendering, drag-and-drop, hover zoom, and target selection.

7. Build EnemyIntentSystem.gd where enemies choose hidden intents but display probability-weighted possible intents.

8. Build BluffSystem.gd with Call, Fold, Raise, and Wager actions.

9. Build CombatResolver.gd that queues actions and resolves them in readable order with a combat log.

10. Build a TestCombat scene with one player, three sample enemies, ten cards, and a complete win/loss condition.
```

## Things To Avoid In The First Version

Do not start with:

```text
Procedural mystery generation
Huge class system
100 cards
Complex meta progression
Networked multiplayer
3D board
Overly abstract poker math
```

Start with:

```text
One room.
One class.
One deck.
Three enemies.
A 3x3 grid.
Enemy intent uncertainty.
Call / Fold / Raise.
One boss.
```

That is enough to prove whether the hook works.

## Source Links From Prompt

- Godot UI docs: https://docs.godotengine.org/en/stable/tutorials/ui/index.html
- Balatro sales article: https://www.theverge.com/2025/1/21/24348727/balatro-5-million-copies-the-game-awards

