class_name GameData
extends RefCounted

const MAX_ATTACHMENTS := 5

# The skill hits for its chain's power times this.
const SKILL_DAMAGE_MULT := 2.5
# Seconds of cooldown for a plain skill. Parts scale it (see Pipeline.skill_cooldown).
const SKILL_BASE_COOLDOWN := 6.0

const FUELS := {
	"alcohol": {"power": 1.0, "burn": 0.8, "clog": 0.0},
	"oil":     {"power": 1.2, "burn": 1.4, "clog": 0.1},
	"powder":  {"power": 1.6, "burn": 0.7, "clog": 0.4},
	"magic":   {"power": 2.0, "burn": 1.0, "clog": 0.0},
}

# heat_capacity = 30 + 20 * heat_resist (used later by the idle loop)
const MATERIALS := {
	"wood": {
		"heat_resist": 1, "weight": 1, "durability": 20, "heat_capacity": 50,
		"flammable": true, "metal": false, "insulates": true, "fragile": false,
		"dissipation": 0.5,
	},
	"copper": {
		"heat_resist": 3, "weight": 3, "durability": 60, "heat_capacity": 90,
		"flammable": false, "metal": true, "insulates": false, "fragile": false,
		"dissipation": 2.0,
	},
	"iron": {
		"heat_resist": 4, "weight": 5, "durability": 100, "heat_capacity": 110,
		"flammable": false, "metal": true, "insulates": false, "fragile": false,
		"dissipation": 1.0,
	},
	"ceramic": {
		"heat_resist": 8, "weight": 2, "durability": 25, "heat_capacity": 190,
		"flammable": false, "metal": false, "insulates": true, "fragile": true,
		"dissipation": 0.5,
	},
}
