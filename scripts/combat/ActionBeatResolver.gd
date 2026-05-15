class_name ActionBeatResolver
extends RefCounted

const RESULT_MISS := "miss"
const RESULT_GRAZE := "graze"
const RESULT_HIT := "hit"
const RESULT_PERFECT := "perfect"

const BEAT_PROFILES := {
	&"attack": {
		"window": 0.82,
		"perfect_start": 0.46,
		"perfect_end": 0.58,
		"hit_start": 0.28,
		"hit_end": 0.74,
		"verb": "strike",
		"perfect_multiplier": 1.35,
		"hit_multiplier": 1.0,
		"graze_multiplier": 0.55
	},
	&"guard": {
		"window": 0.72,
		"perfect_start": 0.38,
		"perfect_end": 0.52,
		"hit_start": 0.22,
		"hit_end": 0.78,
		"verb": "parry",
		"perfect_multiplier": 1.25,
		"hit_multiplier": 1.0,
		"graze_multiplier": 0.70
	},
	&"move": {
		"window": 0.66,
		"perfect_start": 0.34,
		"perfect_end": 0.50,
		"hit_start": 0.18,
		"hit_end": 0.78,
		"verb": "dodge",
		"perfect_multiplier": 1.20,
		"hit_multiplier": 1.0,
		"graze_multiplier": 0.75
	},
	&"read": {
		"window": 0.90,
		"perfect_start": 0.42,
		"perfect_end": 0.62,
		"hit_start": 0.24,
		"hit_end": 0.80,
		"verb": "read",
		"perfect_multiplier": 1.30,
		"hit_multiplier": 1.0,
		"graze_multiplier": 0.65
	}
}


static func get_profile(style: StringName) -> Dictionary:
	if BEAT_PROFILES.has(style):
		return BEAT_PROFILES[style].duplicate()
	return BEAT_PROFILES[&"attack"].duplicate()


static func make_beat(style: StringName, source_id: StringName, target_id: StringName, card_name: String = "") -> Dictionary:
	var profile: Dictionary = get_profile(style)
	return {
		"style": style,
		"source_id": source_id,
		"target_id": target_id,
		"card_name": card_name,
		"window": float(profile.get("window", 0.8)),
		"verb": String(profile.get("verb", "act")),
		"profile": profile
	}


static func resolve_timing(beat: Dictionary, elapsed_seconds: float) -> Dictionary:
	var profile: Dictionary = beat.get("profile", get_profile(StringName(beat.get("style", &"attack"))))
	var raw_window: float = float(beat.get("window", profile.get("window", 0.8)))
	var window: float = raw_window if raw_window > 0.01 else 0.01
	var raw_ratio: float = elapsed_seconds / window
	var ratio: float = clampf(raw_ratio, 0.0, 1.25)
	var result: String = _grade_ratio(ratio, profile)
	var multiplier: float = _get_result_multiplier(result, profile)
	return {
		"result": result,
		"ratio": ratio,
		"multiplier": multiplier,
		"label": _get_result_label(result),
		"message": _build_result_message(beat, result)
	}


static func resolve_ratio(style: StringName, ratio: float) -> Dictionary:
	var beat: Dictionary = make_beat(style, &"player", &"target", "")
	return resolve_timing(beat, float(beat.get("window", 0.8)) * ratio)


static func resolve_aim(style: StringName, distance: float, perfect_radius: float, hit_radius: float, graze_radius: float) -> Dictionary:
	var profile: Dictionary = get_profile(style)
	var result: String = RESULT_MISS
	if distance <= perfect_radius:
		result = RESULT_PERFECT
	elif distance <= hit_radius:
		result = RESULT_HIT
	elif distance <= graze_radius:
		result = RESULT_GRAZE
	var multiplier: float = _get_result_multiplier(result, profile)
	return {
		"result": result,
		"distance": distance,
		"multiplier": multiplier,
		"label": _get_result_label(result),
		"message": "Arena aim: %s." % _get_result_label(result)
	}


static func _grade_ratio(ratio: float, profile: Dictionary) -> String:
	if ratio < 0.0 or ratio > 1.0:
		return RESULT_MISS
	if ratio >= float(profile.get("perfect_start", 0.45)) and ratio <= float(profile.get("perfect_end", 0.58)):
		return RESULT_PERFECT
	if ratio >= float(profile.get("hit_start", 0.25)) and ratio <= float(profile.get("hit_end", 0.75)):
		return RESULT_HIT
	if ratio <= 1.0:
		return RESULT_GRAZE
	return RESULT_MISS


static func _get_result_multiplier(result: String, profile: Dictionary) -> float:
	match result:
		RESULT_PERFECT:
			return float(profile.get("perfect_multiplier", 1.25))
		RESULT_HIT:
			return float(profile.get("hit_multiplier", 1.0))
		RESULT_GRAZE:
			return float(profile.get("graze_multiplier", 0.6))
		_:
			return 0.0


static func _get_result_label(result: String) -> String:
	match result:
		RESULT_PERFECT:
			return "PERFECT"
		RESULT_HIT:
			return "HIT"
		RESULT_GRAZE:
			return "GRAZE"
		_:
			return "MISS"


static func _build_result_message(beat: Dictionary, result: String) -> String:
	var verb: String = String(beat.get("verb", "act"))
	var card_name: String = String(beat.get("card_name", ""))
	var subject: String = card_name if not card_name.is_empty() else verb.capitalize()
	return "%s timing: %s." % [subject, _get_result_label(result)]
