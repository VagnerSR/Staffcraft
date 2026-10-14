class_name Stages
extends RefCounted

const TERRAIN_NAME := "Forest"
const PHASES_PER_TERRAIN := 10


# Phases 1 to 10 of the Forest, generated from the phase number.
# A new terrain later is one more function like this.
static func get_stage(number: int) -> Dictionary:
	number = clampi(number, 1, PHASES_PER_TERRAIN)
	var mult := 1.0 + 0.4 * (number - 1)

	var ids: Array = ["slime"]
	if number >= 2:
		ids.append("goblin")
	if number >= 4:
		ids.append("golem")

	var wave_count := 2 + int(number / 4.0)  # 2 to 4 normal waves
	var waves: Array = []
	for w in wave_count:
		var wave: Array = []
		for i in (2 + w):
			wave.append(ids[(w + i) % ids.size()])
		waves.append(wave)
	waves.append(["slime_king"])  # every phase ends with a boss
	return {"name": "%s %d" % [TERRAIN_NAME, number], "mult": mult, "waves": waves}
