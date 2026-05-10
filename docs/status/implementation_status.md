# Dead Man's Ante Implementation Status

Last updated: 2026-05-10

This file is the handoff ledger for future agents. Update it whenever a phase changes state.

Allowed statuses:
- `TODO`: not started
- `IN_PROGRESS`: currently being implemented
- `DONE`: implemented and verified
- `BLOCKED`: cannot proceed; include blocker and owner/action

## Current Project Facts

- Project path: `C:\Game Dev\CodexGame`
- Engine target: Godot 4.6.x
- MCP: Godot AI at `http://127.0.0.1:8000/mcp`
- Design source: `docs/design/dead_mans_ante_mega_prompt.md`
- Prototype title: Dead Man's Ante
- First class: The Gambler-Knight
- First board: shared 3x3 Control-based grid

## Phase Ledger

| Phase | Status | Acceptance Criteria | Evidence |
| --- | --- | --- | --- |
| 0 - Foundation Lock | DONE | Folders, status tracker, resource scripts, and empty test scene exist; project opens; `TestCombat.tscn` runs without script errors. | Added folder scaffold, `CardDefinition.gd`, `EnemyDefinition.gd`, `IntentDefinition.gd`, `TestCombat.tscn`; script checks for all kickoff scripts reported `SCRIPT_CHECKS: PASS`; `Godot_v4.6.2-stable_win64_console.exe --headless --path "C:\Game Dev\CodexGame" --quit` exited 0; `--scene res://scenes/combat/TestCombat.tscn --quit-after 1` exited 0. |
| 1 - Combat State Machine | DONE | Turn manager cycles through all eight phases repeatedly; phase label and combat log update; reset works. | Added `TurnManager.gd` and `TestCombatController.gd`; `tests/debug/turn_manager_phase_check.gd` reported `TURN_MANAGER_PHASE_CHECK: PASS`; MCP `scene_open` opened `res://scenes/combat/TestCombat.tscn`; MCP `editor_state` reported `current_scene: res://scenes/combat/TestCombat.tscn` and `readiness: ready`. |
| 2 - 3x3 Tactical Grid | DONE | Board cells, player token, enemy token, occupancy, selection, and invalid-move logging work. | Added `GridCellView.gd`, `CombatGrid.gd`, and `tests/debug/combat_grid_check.gd`; `PHASE2_SCRIPT_CHECKS: PASS`; `COMBAT_GRID_CHECK: PASS`; `PHASE2_BEHAVIOR_CHECKS: PASS`; headless project and `TestCombat.tscn` scene loads exited 0; MCP `scene_open` opened `res://scenes/combat/TestCombat.tscn`; MCP `editor_state` reported `project_name: Dead Man's Ante`, `current_scene: res://scenes/combat/TestCombat.tscn`, and `readiness: ready`. |
| 3 - Card Data And Deck Loop | DONE | Deck starts combat, draws 5 cards, plays cards to discard/exhaust, and shuffles discard when needed. | Added `DeckManager.gd`, `CardView.gd`, `HandView.gd`, `DeckManagerCheck.tscn`, `deck_manager_check.gd`, and 10 starter card resources under `resources/cards`; TestCombat now resets deck and draws 5 on combat reset; clicking a card plays it to discard or exhaust; `PHASE3_SCRIPT_CHECKS: PASS`; `DECK_MANAGER_CHECK: PASS`; `TURN_MANAGER_PHASE_CHECK: PASS`; `COMBAT_GRID_CHECK: PASS`; headless project and TestCombat scene loads exited 0; MCP `scene_open` opened `res://scenes/combat/TestCombat.tscn`; MCP `editor_state` reported `project_name: Dead Man's Ante`, `current_scene: res://scenes/combat/TestCombat.tscn`, and `readiness: ready`. |
| 4 - Enemy Intent Ranges | DONE | Enemy shows weighted intent preview, hidden intent resolves during reveal, and debug truth display works. | Added `EnemyIntentSystem.gd`, 9 intent resources under `resources/intents`, 3 enemy resources under `resources/enemies`, `EnemyIntentSystemCheck.tscn`, and `enemy_intent_system_check.gd`; TestCombat now shows public weighted intent previews and a toggleable debug truth panel; Enemy Intent Preview phase rolls hidden intents and Reveal phase reveals them; `PHASE4_SCRIPT_CHECKS: PASS`; `ENEMY_INTENT_SYSTEM_CHECK: PASS`; `PHASE4_BEHAVIOR_CHECKS: PASS`; `DECK_MANAGER_CHECK: PASS`; `TURN_MANAGER_PHASE_CHECK: PASS`; `COMBAT_GRID_CHECK: PASS`; headless project and TestCombat scene loads exited 0; MCP `scene_open` opened `res://scenes/combat/TestCombat.tscn`; MCP `editor_state` reported `project_name: Dead Man's Ante`, `current_scene: res://scenes/combat/TestCombat.tscn`, and `readiness: ready`. |
| 5 - Commit / Bluff / Reveal | DONE | Player can commit, call, fold, raise, wager Nerve, and see clear payoff/penalty logs. | Added `BluffSystem.gd`, `BluffSystemCheck.tscn`, and `bluff_system_check.gd`; `DeckManager.gd` now supports a committed card zone plus fold/resolve; TestCombat now has Commit First, Set Call, Raise +1, Fold, Reset Bluff, enemy/intent/lane call dropdowns, and Nerve/wager/committed-card state display; Reveal resolves the hidden intent against the Call and resolves the committed card; `ALL_GAMEPLAY_SCRIPT_CHECKS: PASS (17 scripts)`; `BLUFF_SYSTEM_CHECK: PASS`; `ENEMY_INTENT_SYSTEM_CHECK: PASS`; `DECK_MANAGER_CHECK: PASS`; `TURN_MANAGER_PHASE_CHECK: PASS`; `COMBAT_GRID_CHECK: PASS`; headless project and TestCombat scene loads exited 0. |
| 6 - Combat Resolver | DONE | Cards and revealed enemy intents affect HP, Guard, movement/trap logs, and win/loss state. | Added `CombatResolver.gd`, `CombatResolverCheck.tscn`, and `combat_resolver_check.gd`; TestCombat now shows Combat State, applies clicked/committed card effects, applies revealed enemy intent payloads, tracks player/enemy HP and Guard, logs movement/trap placeholders, and emits victory/defeat outcomes; `ALL_GAMEPLAY_SCRIPT_CHECKS: PASS (19 scripts)`; `COMBAT_RESOLVER_CHECK: PASS`; `BLUFF_SYSTEM_CHECK: PASS`; `ENEMY_INTENT_SYSTEM_CHECK: PASS`; `DECK_MANAGER_CHECK: PASS`; `TURN_MANAGER_PHASE_CHECK: PASS`; `COMBAT_GRID_CHECK: PASS`; headless project and TestCombat scene loads exited 0. |

## Completion Rules

- Mark a phase `DONE` only after running a verification step and adding evidence.
- If a phase is partially built but unverified, keep it `IN_PROGRESS`.
- Keep final art, 3D, run map, relic economy, shops, meta progression, and complex animation out of scope until Phase 5 proves the hook.
