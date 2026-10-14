class_name Pipeline
extends RefCounted

# Build format (a Dictionary, same shape as the JS version):
# {
#   "element": "fire",                      # optional, defaults to "fire"
#   "tank":    {"fuel": "oil", "material": "iron"} or null,
#   "battery": {"type": "battery"} or null,
#   "grip":    "wood",                      # optional
#   "parts":   [{"type": "igniter", "material": "iron"}, ...]
# }


static func evaluate(build: Dictionary, slot_limit: int = GameData.MAX_ATTACHMENTS) -> Dictionary:
	var element: String = build.get("element", "fire")
	if element != "fire":
		push_error("Element not supported yet: " + element)
		return {}

	var all_parts: Array = build.get("parts", [])
	var count := mini(mini(slot_limit, GameData.MAX_ATTACHMENTS), all_parts.size())
	var parts: Array = all_parts.slice(0, count)

	var tank = build.get("tank", null)
	var fuel_data = null
	if tank != null:
		fuel_data = GameData.FUELS.get(tank["fuel"], null)
		if fuel_data == null:
			push_error("Unknown fuel: " + str(tank["fuel"]))
			return {}

	var flow := FlowState.new()
	flow.fuel = fuel_data != null
	flow.fuel_type = tank["fuel"] if tank != null else ""
	flow.battery = build.get("battery", null) != null
	flow.power = 10.0 * float(fuel_data["power"]) if flow.fuel else 10.0

	var notes: Array[String] = []
	var chain: Array[String] = []
	var used: Array[bool] = []  # lets the UI gray out dead parts
	var contributing := 0
	var weight := 0
	var metal := 0

	for part in parts:
		var type: String = part["type"]
		var mat_name: String = part["material"]
		if not GameData.MATERIALS.has(mat_name):
			push_error("Unknown material: " + mat_name)
			return {}
		if not Parts.exists(type):
			push_error("Unknown part: " + type)
			return {}

		var mat: Dictionary = GameData.MATERIALS[mat_name]
		weight += mat["weight"]
		if mat["metal"]:
			metal += 1

		# The chain is cut off after the nozzle: nothing downstream does anything.
		var ended := flow.nozzle
		var ok := false
		if not ended:
			ok = Parts.apply(type, flow)
		used.append(ok)

		if ok:
			contributing += 1
			chain.append(type)
			# Weak materials in hot parts raise instability.
			if type == "chamber" or type == "igniter":
				var need := flow.heat * 0.3
				if mat["heat_resist"] < need:
					flow.instability += 20
					notes.append("%s %s is too weak for this heat" % [mat_name, type])
		elif ended:
			notes.append("%s is after the nozzle and does nothing" % type)
		else:
			notes.append("%s is not contributing" % type)

	# Name the result
	var mode: String
	if not flow.ignited:
		mode = "fizzle"
	elif not flow.fuel:
		mode = "spark"
	elif flow.held:
		if flow.magnetic:
			mode = "plasma lance" if flow.nozzle else "magnetic fireball"
		else:
			mode = "shaped burst" if flow.nozzle else "fireball"
	elif flow.arc:
		mode = "arc jet" if flow.nozzle else "arc flame"
	else:
		mode = "focused jet" if flow.nozzle else "flamethrower"

	# Metal bonus scales with the % of metal parts (ceramic and wood don't count).
		# The grip counts toward the metal ratio too: a wood grip dilutes the bonus,
	# an iron grip adds to it.
	var grip_name: String = build.get("grip", "")
	var grip_known := grip_name != "" and GameData.MATERIALS.has(grip_name)
	var metal_count := metal
	var total_pieces := parts.size()
	if grip_known:
		total_pieces += 1
		if GameData.MATERIALS[grip_name]["metal"]:
			metal_count += 1
	var metal_ratio := float(metal_count) / total_pieces if total_pieces > 0 else 0.0
	var crit_bonus := snappedf(metal_ratio * 0.25, 0.01)

	var grip_ok: bool = grip_known and GameData.MATERIALS[grip_name]["insulates"]
	var shock := roundi(flow.shock * (0.1 if grip_ok else 1.0))
	if flow.shock > 0.0 and not grip_ok:
		notes.append("current reaches the mage: use an insulating grip")

	return {
		"mode": mode,
		"shock": shock,
		"chain": " > ".join(chain),
		"used": used,
		"power": roundi(flow.power),
		"heat": roundi(flow.heat),
		"instability": roundi(flow.instability),
		"capacity": roundi(float(contributing) / parts.size() * 100.0) if parts.size() > 0 else 0,
		"weight": weight,
		"crit_bonus": crit_bonus,
		"log": notes,
		"has_skill": flow.held,
	}
	
	# The basic attack: the same build, cut off at the first working chamber.
static func evaluate_basic(build: Dictionary, slot_limit: int = GameData.MAX_ATTACHMENTS) -> Dictionary:
	var full := evaluate(build, slot_limit)
	if full.is_empty():
		return full
	var parts: Array = build["parts"]
	var cut := parts.size()
	for i in full["used"].size():
		if parts[i]["type"] == "chamber" and full["used"][i]:
			cut = i
			break
	var basic := build.duplicate()
	basic["parts"] = parts.slice(0, cut)
	return evaluate(basic, slot_limit)


# 0 means "no skill". The engine's heat number (10 = neutral) scales the recharge.
static func skill_cooldown(result: Dictionary) -> float:
	if not result["has_skill"]:
		return 0.0
	return GameData.SKILL_BASE_COOLDOWN * result["heat"] / 10.0
