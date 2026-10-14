class_name Parts
extends RefCounted

# Each part reads/changes the flow and returns true if it contributed.

static func apply(type: String, flow: FlowState) -> bool:
	match type:
		"igniter": return _igniter(flow)
		"chamber": return _chamber(flow)
		"vaporizer": return _vaporizer(flow)
		"airPump": return _air_pump(flow)
		"nozzle": return _nozzle(flow)
		"coil": return _coil(flow)
		"cooler": return _cooler(flow)
	push_error("Unknown part: " + type)
	return false


static func exists(type: String) -> bool:
	return type in ["igniter", "chamber", "vaporizer", "airPump", "nozzle", "coil", "cooler"]


static func _igniter(flow: FlowState) -> bool:
	if flow.ignited:
		return false  # a second igniter is redundant
	flow.ignited = true
	if not flow.fuel:
		flow.power *= 0.4  # no fuel = weak spark only
	return true


static func _chamber(flow: FlowState) -> bool:
	if not flow.ignited or not flow.fuel:
		return false  # before ignition: unused (flamethrower)
	if flow.held:  # stacked chambers: bigger blast, riskier
		flow.stacks += 1
		flow.power *= 1.4
		flow.instability += 15
		return true
	flow.held = true
	flow.power *= 1.5
	flow.instability += 10
	return true


static func _vaporizer(flow: FlowState) -> bool:
	if not flow.fuel or flow.ignited or flow.vapor:
		return false  # must act before ignition
	flow.vapor = true
	flow.power *= 1.5
	flow.heat *= 0.8  # efficient burn runs cooler
	return true


static func _air_pump(flow: FlowState) -> bool:
	if not flow.fuel or flow.air:
		return false
	flow.air = true
	flow.power *= 1.3
	flow.heat *= 1.3
	if flow.held:
		flow.instability += 10  # pumping into a held chamber is risky
	return true


static func _nozzle(flow: FlowState) -> bool:
	if not flow.ignited or flow.nozzle:
		return false
	flow.nozzle = true  # the nozzle ends the chain
	flow.power *= 1.2 if flow.held else 1.1
	return true


static func _coil(flow: FlowState) -> bool:
	if not flow.battery:
		return false  # no battery = dead weight
	flow.shock += 20
	if not flow.ignited:  # before ignition: induction preheat
		flow.power *= 1.25
		flow.heat *= 0.9
		return true
	if flow.held:  # around a held flame: magnetic bottle
		flow.magnetic = true
		flow.power *= 1.3
		flow.instability = maxf(0.0, flow.instability - 20.0)
		return true
	flow.arc = true  # on a free flame: arcs through it
	flow.power *= 1.2
	return true


static func _cooler(flow: FlowState) -> bool:
	flow.heat *= 0.7
	flow.instability = maxf(0.0, flow.instability - 10.0)
	return true
