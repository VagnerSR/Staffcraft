class_name TestCases
extends RefCounted


static func _p(type: String, material: String = "iron") -> Dictionary:
	return {"type": type, "material": material}


static func get_cases() -> Dictionary:
	var t := {"fuel": "oil", "material": "iron"}
	var bat := {"type": "battery"}

	return {
		"1. Spark only": {
			"build": {"tank": null, "parts": [_p("igniter")]},
			"expect": {"mode": "spark", "power": 4, "instability": 0, "capacity": 100, "shock": 0},
		},
		"2. Flamethrower": {
			"build": {"tank": t, "parts": [_p("chamber"), _p("igniter")]},
			"expect": {"mode": "flamethrower", "power": 12, "capacity": 50},
		},
		"3. Fireball": {
			"build": {"tank": t, "parts": [_p("igniter"), _p("chamber")]},
			"expect": {"mode": "fireball", "power": 18, "instability": 10, "capacity": 100},
		},
		"4. Vaporized fireball": {
			"build": {"tank": t, "parts": [_p("vaporizer"), _p("igniter"), _p("chamber")]},
			"expect": {"mode": "fireball", "power": 27, "heat": 8, "instability": 10, "capacity": 100},
		},
		"5. Shaped burst": {
			"build": {"tank": t, "parts": [_p("vaporizer"), _p("airPump"), _p("igniter"), _p("chamber"), _p("nozzle")]},
			"expect": {"mode": "shaped burst", "power": 42, "instability": 10, "capacity": 100},
		},
		"6. Stacked chambers (risky)": {
			"build": {"tank": t, "parts": [_p("igniter"), _p("chamber"), _p("chamber"), _p("chamber"), _p("nozzle")]},
			"expect": {"mode": "shaped burst", "power": 42, "instability": 40, "capacity": 100},
		},
		"7. Bad order (nozzle first)": {
			"build": {"tank": t, "parts": [_p("nozzle"), _p("igniter"), _p("chamber")]},
			"expect": {"mode": "fireball", "power": 18, "capacity": 67},
		},
		"8. Cooled fireball": {
			"build": {"tank": t, "parts": [_p("airPump"), _p("igniter"), _p("chamber"), _p("cooler")]},
			"expect": {"mode": "fireball", "power": 23, "heat": 9, "instability": 0, "capacity": 100},
		},
		"9. Coil, no battery (dead)": {
			"build": {"tank": t, "parts": [_p("igniter"), _p("chamber"), _p("coil")]},
			"expect": {"mode": "fireball", "power": 18, "capacity": 67, "shock": 0},
		},
		"10. Preheat coil, wood grip": {
			"build": {"tank": t, "battery": bat, "grip": "wood", "parts": [_p("coil"), _p("igniter"), _p("chamber")]},
			"expect": {"mode": "fireball", "power": 23, "shock": 2, "heat": 9, "instability": 10, "capacity": 100},
		},
		"11. Arc flame, iron grip": {
			"build": {"tank": t, "battery": bat, "grip": "iron", "parts": [_p("chamber"), _p("igniter"), _p("coil")]},
			"expect": {"mode": "arc flame", "power": 14, "shock": 20, "capacity": 67},
		},
		"12. Magnetic fireball": {
			"build": {"tank": t, "battery": bat, "grip": "wood", "parts": [_p("igniter"), _p("chamber"), _p("coil")]},
			"expect": {"mode": "magnetic fireball", "power": 23, "shock": 2, "instability": 0, "capacity": 100},
		},
		"13. Plasma lance": {
			"build": {"tank": t, "battery": bat, "grip": "ceramic", "parts": [_p("vaporizer"), _p("igniter"), _p("chamber"), _p("coil"), _p("nozzle")]},
			"expect": {"mode": "plasma lance", "power": 42, "shock": 2, "heat": 8, "instability": 0, "capacity": 100},
		},
		"14. Wood igniter on a hot build (too weak)": {
			"build": {"tank": t, "parts": [_p("airPump", "iron"), _p("igniter", "wood")]},
			"expect": {"mode": "flamethrower", "instability": 20, "capacity": 100},
		},
		"15. Ceramic is not metal": {
			"build": {"tank": t, "parts": [_p("igniter", "ceramic"), _p("chamber", "ceramic")]},
			"expect": {"mode": "fireball", "crit_bonus": 0.0},
		},
		"16. All iron gets the full metal bonus": {
			"build": {"tank": t, "parts": [_p("igniter"), _p("chamber")]},
			"expect": {"crit_bonus": 0.25},
		},
	}
