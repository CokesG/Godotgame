class_name TacticalMapDefinition
extends RefCounted

const MAP_CROSSFIRE_TABLE := "crossfire_table"
const EMPTY_CELL := Vector2i(-1, -1)


static func get_default_map() -> Dictionary:
	return get_map(MAP_CROSSFIRE_TABLE)


static func get_map(map_id: String = MAP_CROSSFIRE_TABLE) -> Dictionary:
	match map_id:
		MAP_CROSSFIRE_TABLE:
			return _build_crossfire_table()
		_:
			return _build_crossfire_table()


static func get_cell_feature(map_data: Dictionary, cell: Vector2i) -> Dictionary:
	var cells_value: Variant = map_data.get("cells", {})
	if typeof(cells_value) != TYPE_DICTIONARY:
		return {}

	var feature_value: Variant = Dictionary(cells_value).get(cell_key(cell), {})
	if typeof(feature_value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(feature_value).duplicate(true)


static func build_context(map_data: Dictionary, player_cell: Vector2i, target_cell: Vector2i = EMPTY_CELL) -> Dictionary:
	var player_feature := get_cell_feature(map_data, player_cell)
	var target_feature := get_cell_feature(map_data, target_cell)
	return {
		"map_id": String(map_data.get("id", MAP_CROSSFIRE_TABLE)),
		"map_name": String(map_data.get("name", "Crossfire Table")),
		"summary": String(map_data.get("summary", "")),
		"player_cell": player_cell,
		"player_feature": player_feature,
		"player_feature_label": String(player_feature.get("label", "")),
		"player_lane_name": String(player_feature.get("lane_name", "")),
		"target_cell": target_cell,
		"target_feature": target_feature,
		"target_feature_label": String(target_feature.get("label", ""))
	}


static func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func get_feature_summary(map_data: Dictionary) -> String:
	var name := String(map_data.get("name", "Crossfire Table"))
	var rules := String(map_data.get("rules_summary", "Use cover, center control, and long angles."))
	return "%s: %s" % [name, rules]


static func _build_crossfire_table() -> Dictionary:
	return {
		"id": MAP_CROSSFIRE_TABLE,
		"name": "Crossfire Table",
		"summary": "A compact arena map with left cover, center objective pressure, and a right-side long angle.",
		"rules_summary": "Cover reduces incoming lane damage. Center Pot adds +1 card damage. Long Rail adds +1 card damage from the far angle.",
		"lanes": [
			{"lane": 0, "name": "Smoke Lane", "role": "flank and cover", "note": "Safer rotates and bait plays live here."},
			{"lane": 1, "name": "Ante Mid", "role": "objective", "note": "Center control turns card pressure into damage."},
			{"lane": 2, "name": "Long Rail", "role": "sightline", "note": "A risky damage lane with cleaner attack angles."}
		],
		"cells": {
			"0,0": _feature("Smoke Cover", "SMK", "cover", "Smoke Lane", "Enemy-side smoke cover. Good for trickster rotates.", [&"cover", &"flank"], Color(0.16, 0.28, 0.33, 0.46), Color(0.52, 0.82, 0.92), {"incoming_damage_mitigation": 1}),
			"1,0": _feature("Choke Rail", "CHK", "choke", "Ante Mid", "Enemy backline choke. Pressure here is direct and readable.", [&"choke"], Color(0.26, 0.18, 0.10, 0.40), Color(0.86, 0.52, 0.20), {}),
			"2,0": _feature("Long Angle", "ANG", "angle", "Long Rail", "Enemy long angle. Snipers and guards like this lane.", [&"angle", &"sightline"], Color(0.30, 0.20, 0.10, 0.42), Color(1.0, 0.76, 0.28), {}),
			"0,1": _feature("Flank Step", "FLK", "flank", "Smoke Lane", "A rotate cell for dodges, traps, and baiting lane attacks.", [&"flank", &"movement"], Color(0.13, 0.27, 0.19, 0.38), Color(0.54, 0.92, 0.58), {}),
			"1,1": _feature("Center Pot", "POT", "objective", "Ante Mid", "The objective cell. Standing here adds +1 card damage.", [&"objective", &"center"], Color(0.30, 0.20, 0.07, 0.48), Color(1.0, 0.80, 0.24), {"card_damage_bonus": 1}),
			"2,1": _feature("Hard Cover", "COV", "cover", "Long Rail", "A guard-favored cover cell. It reduces incoming lane damage by 2.", [&"cover", &"guard"], Color(0.15, 0.22, 0.30, 0.48), Color(0.58, 0.78, 1.0), {"incoming_damage_mitigation": 2}),
			"0,2": _feature("Back Cover", "COV", "cover", "Smoke Lane", "Player-side cover. Use it to call attacks without bleeding out.", [&"cover"], Color(0.13, 0.22, 0.28, 0.50), Color(0.50, 0.76, 0.94), {"incoming_damage_mitigation": 2}),
			"1,2": _feature("Deal Spot", "YOU", "start", "Ante Mid", "The default start. Safe, readable, and one step from the pot.", [&"start"], Color(0.12, 0.17, 0.25, 0.38), Color(0.52, 0.66, 1.0), {}),
			"2,2": _feature("Long Rail", "ANG", "angle", "Long Rail", "Player-side long angle. Standing here adds +1 card damage.", [&"angle", &"sightline"], Color(0.26, 0.18, 0.10, 0.46), Color(1.0, 0.72, 0.24), {"card_damage_bonus": 1})
		}
	}


static func _feature(label: String, short_label: String, feature_type: String, lane_name: String, note: String, tags: Array, color: Color, border_color: Color, bonuses: Dictionary) -> Dictionary:
	var data := {
		"label": label,
		"short_label": short_label,
		"type": feature_type,
		"lane_name": lane_name,
		"note": note,
		"tags": tags.duplicate(),
		"color": color,
		"border_color": border_color
	}
	for key in bonuses.keys():
		data[key] = bonuses[key]
	return data
