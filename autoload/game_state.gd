extends Node

signal inventory_changed
signal build_changed
signal gold_changed
signal storage_changed
signal phase_changed       # stage or max_stage changed (the map listens)
signal travel_requested    # a phase was picked on the map (the battle listens)
signal xp_changed
signal leveled_up(new_level: int)

const SLOT_UNLOCK_LEVELS := [1, 10, 20, 30, 40]
# Raise this (try 20.0) while testing so you reach level 10 in minutes.
# Set it back to 1.0 when you want the real pace.
const XP_MULTIPLIER := 1.0

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const AUTOSAVE_SECONDS := 15.0
const GRIP_SLOT_LEVEL := 10
const ARMOR_SLOTS := ["hat", "chest", "legs", "boots"]

var armor := _empty_armor()
var gold := 0

const BATTERY_SLOT_LEVEL := 20

# Set by the battle scene so the menu can show live HP and heat.
var player: Combatant = null

var level := 1
var xp := 0

var inventory: Array[Dictionary] = []

# Computed from the level, so everything that already reads
# GameState.slot_limit keeps working.
var slot_limit: int:
	get:
		return slots_for_level(level)

var build := _default_build()

var stage := 1
var wave := 1
var wave_total := 1
var storage: Array[Dictionary] = []
var max_stage := 1
var phase_progress := 0.0  # 0 to 1, how far through the current phase

func _ready() -> void:
	if not load_game():
		_give_starter_items()

	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_SECONDS
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)

	# Equipping, unequipping, reordering and level-ups all emit build_changed.
	build_changed.connect(save_game)
	
static func _default_build() -> Dictionary:
	return {
		"element": "fire",
		"tank": {"fuel": "oil", "material": "iron"},
		"battery": null,
		"grip": "wood",
		"parts": [
			{"type": "igniter", "material": "copper"},
		],
	}

func battery_unlocked() -> bool:
	return level >= BATTERY_SLOT_LEVEL

func grip_unlocked() -> bool:
	return level >= GRIP_SLOT_LEVEL


# Swaps the grip. The old one returns to the inventory, so you never lose it.
func equip_grip(item: Dictionary) -> bool:
	if not grip_unlocked():
		return false
	var index := inventory.find(item)
	if index == -1:
		return false
	inventory.remove_at(index)
	var old: String = build.get("grip", "")
	if old != "":
		inventory.append({"kind": "grip", "material": old})
	build["grip"] = item["material"]
	inventory_changed.emit()
	build_changed.emit()
	return true


func craft_grip(material: String) -> bool:
	var price := Crafting.grip_cost(material)
	if gold < price:
		return false
	gold -= price
	inventory.append({"kind": "grip", "material": material})
	gold_changed.emit()
	inventory_changed.emit()
	save_game()
	return true

# Puts a battery in the back slot. The old one (if any) returns to the inventory.
func equip_battery(item: Dictionary) -> bool:
	if not battery_unlocked():
		return false
	var index := inventory.find(item)
	if index == -1:
		return false
	inventory.remove_at(index)
	if build["battery"] != null:
		inventory.append({"kind": "battery"})
	build["battery"] = {"type": "battery"}
	inventory_changed.emit()
	build_changed.emit()
	return true


func unequip_battery() -> void:
	if build["battery"] == null:
		return
	build["battery"] = null
	inventory.append({"kind": "battery"})
	inventory_changed.emit()
	build_changed.emit()


func craft_battery() -> bool:
	if gold < Crafting.BATTERY_COST:
		return false
	gold -= Crafting.BATTERY_COST
	inventory.append({"kind": "battery"})
	gold_changed.emit()
	inventory_changed.emit()
	save_game()
	return true

func set_progress(p_wave: int, p_total: int, p_fraction: float) -> void:
	wave = p_wave
	wave_total = p_total
	phase_progress = p_fraction


func advance_stage() -> void:
	stage = mini(stage + 1, Stages.PHASES_PER_TERRAIN)  # the Forest ends at 10
	max_stage = maxi(max_stage, stage)
	phase_changed.emit()
	save_game()


# Only phases you have already reached can be visited.
func travel_to(phase: int) -> void:
	if phase < 1 or phase > max_stage:
		return
	stage = phase
	phase_changed.emit()
	travel_requested.emit()
	save_game()

func move_to_storage(item: Dictionary) -> void:
	var index := inventory.find(item)
	if index == -1:
		return
	inventory.remove_at(index)
	storage.append(item)
	inventory_changed.emit()
	storage_changed.emit()
	save_game()


func move_to_inventory(item: Dictionary) -> void:
	var index := storage.find(item)
	if index == -1:
		return
	storage.remove_at(index)
	inventory.append(item)
	inventory_changed.emit()
	storage_changed.emit()
	save_game()

func _give_starter_items() -> void:
	inventory.append({"kind": "part", "type": "nozzle", "material": "iron"})
	inventory.append({"kind": "part", "type": "airPump", "material": "iron"})
	inventory.append({"kind": "part", "type": "cooler", "material": "copper"})
	inventory.append({"kind": "part", "type": "chamber", "material": "iron"})
	inventory.append({"kind": "fuel", "fuel": "alcohol"})


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"level": level,
		"xp": xp,
		"inventory": inventory,
		"build": build,
		"stage": stage,
		"gold": gold,
		"armor": armor,
		"storage": storage,
		"max_stage": max_stage,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save: error %d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


# Returns true if a save was found and loaded.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save file is unreadable, starting fresh.")
		return false

	# JSON turns every number into a float, so convert back to int.
	level = maxi(int(data.get("level", 1)), 1)
	xp = maxi(int(data.get("xp", 0)), 0)
	gold = maxi(int(data.get("gold", 0)), 0)
	stage = clampi(int(data.get("stage", 1)), 1, Stages.PHASES_PER_TERRAIN)
	max_stage = clampi(int(data.get("max_stage", stage)), stage, Stages.PHASES_PER_TERRAIN)
	storage.clear()
	for item in data.get("storage", []):
		storage.append(item)
	armor = _empty_armor()
	var saved_armor = data.get("armor", {})
	if typeof(saved_armor) == TYPE_DICTIONARY:
		for slot_name in ARMOR_SLOTS:
			if saved_armor.get(slot_name) != null:
				armor[slot_name] = saved_armor[slot_name]

	inventory.clear()
	for item in data.get("inventory", []):
		inventory.append(item)

	var saved_build = data.get("build", null)
	if typeof(saved_build) == TYPE_DICTIONARY:
		build = saved_build
	return true


func reset_progress() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	level = 1
	max_stage = 1
	stage = 1
	xp = 0
	gold = 0
	armor = _empty_armor()
	inventory.clear()
	storage.clear()
	_give_starter_items()
	build = _default_build()
	get_tree().reload_current_scene()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit()


# Returns false if you can't afford it.
func craft_part(type: String, material: String) -> bool:
	var price := Crafting.cost(type, material)
	if gold < price:
		return false
	gold -= price
	inventory.append({"kind": "part", "type": type, "material": material})
	gold_changed.emit()
	inventory_changed.emit()
	save_game()
	return true


# Salvages an inventory item for gold.
func sell_item(item: Dictionary) -> void:
	var index := inventory.find(item)
	if index == -1:
		return
	gold += Crafting.sell_value(item)
	inventory.remove_at(index)
	gold_changed.emit()
	inventory_changed.emit()
	save_game()

# Runs when the window is closed (the OS close request).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func slots_for_level(l: int) -> int:
	var count := 0
	for unlock_level in SLOT_UNLOCK_LEVELS:
		if l >= unlock_level:
			count += 1
	return count

# Swaps two staff parts (used by drag and drop).
func swap_parts(from: int, to: int) -> void:
	var parts: Array = build["parts"]
	to = mini(to, parts.size() - 1)
	if from == to or from < 0 or from >= parts.size():
		return
	var temp = parts[from]
	parts[from] = parts[to]
	parts[to] = temp
	build_changed.emit()

func xp_to_next() -> int:
	return roundi(20.0 * pow(level, 1.5))


func max_hp() -> int:
	return 100 + 10 * (level - 1)


func weight_cap() -> int:
	return 4 + int(level / 2.0)


func overweight(weight: int) -> int:
	return maxi(weight - weight_cap(), 0)


# Each point over the weight cap makes attacks 10% slower.
func attack_interval_for(weight: int, base_interval: float) -> float:
	return base_interval * (1.0 + 0.1 * overweight(weight))


func add_xp(amount: int) -> void:
	xp += roundi(amount * XP_MULTIPLIER)
	var gained_level := false
	while xp >= xp_to_next():
		xp -= xp_to_next()  # uses the old level, then we bump it
		level += 1
		gained_level = true
		leveled_up.emit(level)
	xp_changed.emit()
	if gained_level:
		# New slots and a new weight cap change the staff's result.
		build_changed.emit()

func add_item(item: Dictionary) -> void:
	inventory.append(item)
	inventory_changed.emit()


# Moves a part from the inventory into the next free staff slot.
func equip_part(item: Dictionary) -> bool:
	if build["parts"].size() >= slot_limit:
		return false
	var index := inventory.find(item)
	if index == -1:
		return false
	inventory.remove_at(index)
	build["parts"].append({"type": item["type"], "material": item["material"]})
	inventory_changed.emit()
	build_changed.emit()
	return true


# Moves a part from the staff back to the inventory.
func unequip_part(index: int) -> void:
	var part: Dictionary = build["parts"][index]
	build["parts"].remove_at(index)
	inventory.append({"kind": "part", "type": part["type"], "material": part["material"]})
	inventory_changed.emit()
	build_changed.emit()

# Puts a fuel in the tank. The old fuel (if any) goes back to the inventory.
func equip_fuel(item: Dictionary) -> void:
	var index := inventory.find(item)
	if index == -1:
		return
	inventory.remove_at(index)
	if build["tank"] != null:
		inventory.append({"kind": "fuel", "fuel": build["tank"]["fuel"]})
	build["tank"] = {"fuel": item["fuel"], "material": "iron"}
	inventory_changed.emit()
	build_changed.emit()


func unequip_fuel() -> void:
	if build["tank"] == null:
		return
	inventory.append({"kind": "fuel", "fuel": build["tank"]["fuel"]})
	build["tank"] = null
	inventory_changed.emit()
	build_changed.emit()


# "iron chamber x2" style text for the debug label.
func inventory_text() -> String:
	if inventory.is_empty():
		return "Inventory: (empty)"
	var counts := {}
	for item in inventory:
		var key := Loot.item_name(item)
		counts[key] = counts.get(key, 0) + 1
	var lines: Array[String] = ["Inventory:"]
	for key in counts:
		lines.append("  %s x%d" % [key, counts[key]])
	return "\n".join(lines)
	
static func _empty_armor() -> Dictionary:
	return {"hat": null, "chest": null, "legs": null, "boots": null}


# Total resistances from everything worn, capped at 80%.
func armor_totals() -> Dictionary:
	var totals := {"shock": 0.0, "backfire": 0.0, "defense": 0.0}
	for slot_name in ARMOR_SLOTS:
		var piece = armor[slot_name]
		if piece == null:
			continue
		var b := Armor.bonus(piece)
		for key in totals:
			totals[key] += b[key]
	for key in totals:
		totals[key] = clampf(totals[key], 0.0, 0.8)
	return totals


# Wears a piece. The old one in that slot returns to the inventory.
func equip_armor(item: Dictionary) -> bool:
	var index := inventory.find(item)
	if index == -1:
		return false
	inventory.remove_at(index)
	var slot_name: String = item["slot"]
	if armor[slot_name] != null:
		inventory.append(armor[slot_name])
	armor[slot_name] = {"kind": "armor", "slot": slot_name, "material": item["material"]}
	inventory_changed.emit()
	build_changed.emit()
	return true


func unequip_armor(slot_name: String) -> void:
	if armor[slot_name] == null:
		return
	inventory.append(armor[slot_name])
	armor[slot_name] = null
	inventory_changed.emit()
	build_changed.emit()


func craft_armor(slot_name: String, material: String) -> bool:
	var price := Armor.cost(slot_name, material)
	if gold < price:
		return false
	gold -= price
	inventory.append({"kind": "armor", "slot": slot_name, "material": material})
	gold_changed.emit()
	inventory_changed.emit()
	save_game()
	return true
