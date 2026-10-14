class_name Crafting
extends RefCounted

# Parts the Artificer can craft. Coils are left out until batteries exist.
const RECIPES := ["igniter", "chamber", "vaporizer", "airPump", "nozzle", "cooler", "coil"]
const MATERIALS := ["wood", "copper", "iron", "ceramic"]
const GRIP_BASE_COST := 30

const BASE_COST := {
	"igniter": 20, "chamber": 40, "vaporizer": 50,
	"airPump": 40, "nozzle": 30, "cooler": 25, "coil": 60,
}

const MATERIAL_COST_MULT := {
	"wood": 0.5, "copper": 1.0, "iron": 1.5, "ceramic": 2.0,
}

const FUEL_VALUE := {"alcohol": 5, "oil": 8, "powder": 15, "magic": 40}

# Salvaging a part returns this fraction of its crafting cost.
const SELL_FRACTION := 0.4
const BATTERY_COST := 80

static func cost(type: String, material: String) -> int:
	return roundi(BASE_COST[type] * MATERIAL_COST_MULT[material])

static func grip_cost(material: String) -> int:
	return roundi(GRIP_BASE_COST * MATERIAL_COST_MULT[material])

static func sell_value(item: Dictionary) -> int:
	match item["kind"]:
		"part":
			var price := cost(item["type"], item["material"])
			return maxi(roundi(price * SELL_FRACTION), 1)
		"battery":
			return roundi(BATTERY_COST * SELL_FRACTION)
		"grip":
			return maxi(roundi(grip_cost(item["material"]) * SELL_FRACTION), 1)
		"armor":
			return maxi(roundi(Armor.cost(item["slot"], item["material"]) * SELL_FRACTION), 1)
	return FUEL_VALUE.get(item["fuel"], 1)
