class_name Enemies
extends RefCounted

# size: the square's side in pixels. Drops are rolled independently.
const DATA := {
	"slime": {
		"name": "Slime", "hp": 80, "damage": 4, "interval": 1.2, "xp": 10, "gold": 5,
		"color": Color(0.85, 0.2, 0.2), "size": 32,
		"drops": [
			{"item": {"kind": "fuel", "fuel": "alcohol"}, "chance": 0.40},
			{"item": {"kind": "part", "type": "chamber", "material": "copper"}, "chance": 0.25},
			{"item": {"kind": "part", "type": "vaporizer", "material": "iron"}, "chance": 0.15},
			{"item": {"kind": "part", "type": "cooler", "material": "ceramic"}, "chance": 0.10},
			{"item": {"kind": "armor", "slot": "hat", "material": "cloth"}, "chance": 0.10},
		],
	},
	"goblin": {
		"name": "Goblin", "hp": 50, "damage": 6, "interval": 0.9, "xp": 12, "gold": 7,
		"color": Color(0.3, 0.7, 0.3), "size": 28,
		"drops": [
			{"item": {"kind": "fuel", "fuel": "oil"}, "chance": 0.30},
			{"item": {"kind": "part", "type": "airPump", "material": "copper"}, "chance": 0.20},
			{"item": {"kind": "part", "type": "nozzle", "material": "copper"}, "chance": 0.20},
			{"item": {"kind": "part", "type": "coil", "material": "copper"}, "chance": 0.15},
			{"item": {"kind": "armor", "slot": "chest", "material": "leather"}, "chance": 0.12},
		],
	},
	"golem": {
		"name": "Golem", "hp": 200, "damage": 9, "interval": 2.0, "xp": 30, "gold": 9,
		"color": Color(0.5, 0.45, 0.4), "size": 36,
		"drops": [
			{"item": {"kind": "part", "type": "chamber", "material": "iron"}, "chance": 0.30},
			{"item": {"kind": "part", "type": "igniter", "material": "ceramic"}, "chance": 0.15},
			{"item": {"kind": "fuel", "fuel": "powder"}, "chance": 0.15},
			{"item": {"kind": "battery"}, "chance": 0.10},
			{"item": {"kind": "grip", "material": "ceramic"}, "chance": 0.10},
			{"item": {"kind": "armor", "slot": "legs", "material": "plate"}, "chance": 0.12},
			{"item": {"kind": "armor", "slot": "boots", "material": "rubber"}, "chance": 0.12},
		],
	},
	"slime_king": {
		"name": "Slime King", "hp": 400, "damage": 8, "interval": 1.5, "xp": 80, "gold": 11,
		"color": Color(0.6, 0.1, 0.5), "size": 40, "boss": true,
		"drops": [
			{"item": {"kind": "part", "type": "chamber", "material": "ceramic"}, "chance": 0.80},
			{"item": {"kind": "part", "type": "vaporizer", "material": "copper"}, "chance": 0.60},
			{"item": {"kind": "part", "type": "cooler", "material": "iron"}, "chance": 0.60},
			{"item": {"kind": "fuel", "fuel": "powder"}, "chance": 0.50},
			{"item": {"kind": "grip", "material": "iron"}, "chance": 0.40},
			{"item": {"kind": "armor", "slot": "chest", "material": "rubber"}, "chance": 0.50},
		],
	},
}


# A copy of the enemy with its stats scaled by the stage multiplier.
static func scaled(id: String, mult: float) -> Dictionary:
	var e: Dictionary = DATA[id].duplicate(true)
	e["hp"] = roundi(e["hp"] * mult)
	e["damage"] = maxi(roundi(e["damage"] * mult), 1)
	e["xp"] = roundi(e["xp"] * mult)
	e["gold"] = roundi(e["gold"] * mult)
	return e
