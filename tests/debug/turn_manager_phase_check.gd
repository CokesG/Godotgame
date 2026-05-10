extends SceneTree


func _initialize() -> void:
	var turn_manager_script: Script = load("res://scripts/combat/TurnManager.gd")
	var turn_manager: Node = turn_manager_script.new()
	turn_manager.auto_start = false
	root.add_child(turn_manager)

	var observed_phases: Array[String] = []
	var observed_turns: Array[int] = []

	turn_manager.phase_changed.connect(func(_phase: int) -> void:
		observed_phases.append(turn_manager.get_current_phase_display())
	)
	turn_manager.turn_started.connect(func(turn_number: int) -> void:
		observed_turns.append(turn_number)
	)

	turn_manager.reset_combat()
	for index in range(16):
		turn_manager.advance_phase()

	var expected_sequence := [
		"Start Turn",
		"Draw",
		"Enemy Intent Preview",
		"Player Commit",
		"Bluff Wager",
		"Reveal",
		"Resolve",
		"Cleanup",
		"Start Turn",
		"Draw",
		"Enemy Intent Preview",
		"Player Commit",
		"Bluff Wager",
		"Reveal",
		"Resolve",
		"Cleanup",
		"Start Turn"
	]

	if observed_phases != expected_sequence:
		push_error("Unexpected phase sequence: %s" % [observed_phases])
		quit(1)
		return

	if observed_turns != [1, 2, 3]:
		push_error("Unexpected turn starts: %s" % [observed_turns])
		quit(1)
		return

	print("TURN_MANAGER_PHASE_CHECK: PASS")
	quit(0)
