class_name Armor
extends RefCounted

const SLOTS := ["hat", "chest", "legs", "boots"]

# What share of a full set's stats each piece gives (adds up to 1.0).
const SLOT_SHARE := {"hat": 0.20, "chest": 0.40, "legs": 0.25, "boots": 0.15}

# Full-set values. Negative means the material makes it worse.
const MATERIALS := {
	"cloth":   {"shock": 0.20, "backfire": 0.10, "defense": 0.05, "cost": 15},
	"leather": {"shock": 0.10, "backfire": 0.30, "defense": 0.15, "cost": 30},
	"rubber":  {"shock": 0.60, "backfire": 0.10, "defense": 0.05, "cost": 45},
	"plate":   {"shock": -0.20, "backfire": 0.30, "defense": 0.40, "cost": 70},
}

const COLORS := {
	"cloth": Color(0.70, 0.65, 0.80),
	"leather": Color(0.50, 0.33, 0.20),
	"rubber": Color(0.20, 0.45, 0.40),
	"plate": Color(0.60, 0.65, 0.70),
}

const SHORT := {"hat": "HAT", "chest": "CHEST", "legs": "LEGS", "boots": "BOOTS"}


static func bonus(item: Dictionary) -> Dictionary:
	var share: float = SLOT_SHARE[item["slot"]]
	var mat: Dictionary = MATERIALS[item["material"]]
	return {
		"shock": mat["shock"] * share,
		"backfire": mat["backfire"] * share,
		"defense": mat["defense"] * share,
	}


# A full set costs about 4x the material's base cost.
static func cost(slot: String, material: String) -> int:
	return roundi(MATERIALS[material]["cost"] * SLOT_SHARE[slot] * 4.0)
