extends Node

const ENEMY_PATHS := [
	"res://resources/enemies/brute.tres",
	"res://resources/enemies/skulker.tres",
	"res://resources/enemies/shieldbearer.tres"
]


func _ready() -> void:
	var intent_system_script: Script = load("res://scripts/enemies/EnemyIntentSystem.gd")
	var intent_system: Node = intent_system_script.new()
	add_child(intent_system)

	intent_system.call("configure_enemies", ENEMY_PATHS)
	intent_system.call("set_seed", 42)
	intent_system.call("roll_intents")

	var previews: Array = intent_system.call("get_public_previews")
	if previews.size() != 3:
		_fail("Expected 3 enemy previews, got %d." % previews.size())
		return

	for preview in previews:
		var options: Array = preview.get("options", [])
		if options.size() != 3:
			_fail("%s expected 3 public intent options." % preview.get("enemy_name", "Enemy"))
			return
		for option in options:
			if int(option.get("percentage", 0)) <= 0:
				_fail("%s has an option without a visible percentage." % preview.get("enemy_name", "Enemy"))
				return
			if String(option.get("summary", "")).is_empty():
				_fail("%s has an empty public summary." % preview.get("enemy_name", "Enemy"))
				return

	var truth: Array = intent_system.call("get_debug_truth")
	if truth.size() != 3:
		_fail("Expected 3 debug truth entries, got %d." % truth.size())
		return

	for entry in truth:
		if String(entry.get("intent_name", "None")) == "None":
			_fail("%s has no hidden intent selected." % entry.get("enemy_name", "Enemy"))
			return
		if String(entry.get("hidden_text", "")).is_empty():
			_fail("%s has no hidden text." % entry.get("enemy_name", "Enemy"))
			return

	var revealed: Array = intent_system.call("reveal_intents")
	if revealed.size() != 3:
		_fail("Expected 3 revealed intents, got %d." % revealed.size())
		return

	print("ENEMY_INTENT_SYSTEM_CHECK: PASS")
	intent_system.queue_free()
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
