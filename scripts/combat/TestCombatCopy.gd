class_name TestCombatCopy
extends RefCounted

const PHASE_ACTION_LABELS := {
	"START_TURN": "Begin Turn",
	"DRAW": "Begin Turn",
	"ENEMY_INTENT_PREVIEW": "Begin Turn",
	"PLAYER_COMMIT": "Resolve Turn",
	"BLUFF_WAGER": "Reveal Turn",
	"REVEAL": "Review Results",
	"RESOLVE": "Next Turn",
	"CLEANUP": "Next Turn"
}

const PHASE_GUIDANCE := {
	"START_TURN": {
		"title": "Start Turn",
		"detail": "Energy refreshes. Continue to fill the hand."
	},
	"DRAW": {
		"title": "Draw",
		"detail": "The hand fills toward five cards automatically."
	},
	"ENEMY_INTENT_PREVIEW": {
		"title": "Read",
		"detail": "Compare enemy odds and tells before committing."
	},
	"PLAYER_COMMIT": {
		"title": "Commit",
		"detail": "Choose targets, click cards to play them, or commit the first card face-down."
	},
	"BLUFF_WAGER": {
		"title": "Bluff",
		"detail": "Set a call, raise if confident, or fold the committed card."
	},
	"REVEAL": {
		"title": "Reveal",
		"detail": "Enemy intent and committed cards resolve once this phase begins."
	},
	"RESOLVE": {
		"title": "Resolve",
		"detail": "Review HP, Guard, traps, and the combat log."
	},
	"CLEANUP": {
		"title": "Cleanup",
		"detail": "Leftover hand cards are discarded before the next turn."
	}
}

const RECIPE_STEPS := [
	{
		"id": "read_intents",
		"label": "Read one enemy intent preview"
	},
	{
		"id": "play_or_commit",
		"label": "Play a card or commit one face-down"
	},
	{
		"id": "bluff_choice",
		"label": "Set a call, raise, or fold"
	},
	{
		"id": "reveal_resolve",
		"label": "Resolve the reveal"
	},
	{
		"id": "cleanup",
		"label": "Clean up and start the next turn"
	}
]

const RUN_INSPECTOR_FILTERS := [
	{"id": "all", "label": "All"},
	{"id": "attack", "label": "Attack"},
	{"id": "guard", "label": "Guard"},
	{"id": "movement", "label": "Move"},
	{"id": "read", "label": "Read"},
	{"id": "trap", "label": "Trap"},
	{"id": "ritual", "label": "Ritual"}
]
