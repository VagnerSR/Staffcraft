class_name Loot
extends RefCounted

const SHORT := {
	"igniter": "IGN", "chamber": "CHA", "vaporizer": "VAP", "airPump": "AIR",
	"nozzle": "NOZ", "coil": "COIL", "cooler": "COOL",
	"alcohol": "ALC", "oil": "OIL", "powder": "PWD", "magic": "MAG",
}

const MATERIAL_COLORS := {
	"wood": Color(0.55, 0.38, 0.22),
	"copper": Color(0.80, 0.45, 0.25),
	"iron": Color(0.45, 0.50, 0.55),
	"ceramic": Color(0.88, 0.85, 0.78),
}

const FUEL_COLORS := {
	"alcohol": Color(0.45, 0.70, 0.90),
	"oil": Color(0.30, 0.25, 0.15),
	"powder": Color(0.55, 0.20, 0.20),
	"magic": Color(0.60, 0.30, 0.90),
}

const PART_INFO := {
	"igniter": "Starts the flame. Only the first one counts.",
	"chamber": "Holds the flame under pressure. Needs fire and fuel before it.",
	"vaporizer": "More power, cooler burn. Must come before the igniter.",
	"airPump": "More power and more heat. Needs fuel. One only.",
	"nozzle": "Focuses the flame. Ends the chain: parts after it do nothing.",
	"coil": "Needs a battery. Its effect depends on its position.",
	"cooler": "Lowers heat and instability. Works anywhere.",
}


static func short_name(item: Dictionary) -> String:
	match item["kind"]:
		"part":
			return SHORT.get(item["type"], "?")
		"fuel":
			return SHORT.get(item["fuel"], "?")
		"battery":
			return "BAT"
		"grip":
			return "GRIP"
		"armor":
			return Armor.SHORT[item["slot"]]
	return "?"


static func item_color(item: Dictionary) -> Color:
	match item["kind"]:
		"part":
			return MATERIAL_COLORS.get(item["material"], Color.GRAY)
		"fuel":
			return FUEL_COLORS.get(item["fuel"], Color.GRAY)
		"battery":
			return Color(0.85, 0.75, 0.2)
		"grip":
			return MATERIAL_COLORS.get(item["material"], Color.GRAY)
		"armor":
			return Armor.COLORS.get(item["material"], Color.GRAY)
	return Color.GRAY


static func item_tooltip(item: Dictionary) -> String:
	match item["kind"]:
		"part":
			var mat: Dictionary = GameData.MATERIALS[item["material"]]
			return "%s\n%s\nWeight %d, heat resist %d%s" % [
				item_name(item), PART_INFO.get(item["type"], ""),
				mat["weight"], mat["heat_resist"],
				", insulates" if mat["insulates"] else "",
			]
		"fuel":
			var fuel: Dictionary = GameData.FUELS[item["fuel"]]
			return "%s\nTank fuel, power x%.1f" % [item_name(item), fuel["power"]]
		"grip":
			var gm: Dictionary = GameData.MATERIALS[item["material"]]
			if gm["insulates"]:
				return "%s\nInsulates: coil shock is cut to 10%%.\nDoes not count as metal for the crit bonus." % item_name(item)
			return "%s\nConducts current: you take full coil shock.\nCounts as metal for the crit bonus." % item_name(item)
		"battery":
			return "Battery\nPowers coils. Without one, every coil is dead weight.\nCoils add shock: use an insulating grip."
		"armor":
			var b := Armor.bonus(item)
			return "%s\nShock resist %+d%%\nBackfire resist %+d%%\nDefense %+d%%" % [
				item_name(item), roundi(b["shock"] * 100.0),
				roundi(b["backfire"] * 100.0), roundi(b["defense"] * 100.0),
			]
	return item_name(item)

static func item_name(item: Dictionary) -> String:
	match item["kind"]:
		"part":
			return "%s %s" % [item["material"], item["type"]]
		"fuel":
			return "%s (fuel)" % item["fuel"]
		"battery":
			return "battery"
		"grip":
			return "%s grip" % item["material"]
		"armor":
			return "%s %s" % [item["material"], item["slot"]]
	return "unknown item"


# Each entry in the table is rolled independently:
# [{"item": {...}, "chance": 0.25}, ...]
static func roll(drop_table: Array) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for entry in drop_table:
		if randf() < entry["chance"]:
			drops.append(entry["item"].duplicate())
	return drops
