class_name MiddlePanel
extends UiPanel

signal option_pressed(option: String)

const WIDTH := 520
const COLUMNS := 7
const MIN_CELLS := 21  # 7 x 3

# Placeholder roster. Only the Artificer exists so far.
const CHARACTERS := [
	{"name": "Artificer", "short": "ART", "color": Color(0.25, 0.30, 0.80), "unlocked": true},
	{"name": "Smith", "short": "SMI", "color": Color(0.55, 0.45, 0.35), "unlocked": false},
	{"name": "Alchemist", "short": "ALC", "color": Color(0.30, 0.65, 0.45), "unlocked": false},
]

var selected := 0
var salvage_mode := false
var reset_armed := false
var message := ""
var skill_name := ""

var gold_label: Label
var level_label: Label
var xp_bar: ProgressBar
var armor_box: VBoxContainer
var skill_label: Label
var skill_bar: ProgressBar
var hero_rect: ColorRect
var hero_name: Label
var char_row: HBoxContainer
var gear_row: HBoxContainer
var staff_row: HBoxContainer
var result_label: Label
var inv_header: Label
var inv_grid: GridContainer
var reset_button: Button


func _init() -> void:
	super(WIDTH)


func _ready() -> void:
	_build_top_bar()
	content.add_child(HSeparator.new())
	_build_equipment()
	content.add_child(HSeparator.new())
	_build_inventory()
	_build_options()

	GameState.build_changed.connect(_refresh_equipment)
	GameState.inventory_changed.connect(_refresh_inventory)
	_refresh_characters()
	_refresh_equipment()
	_refresh_inventory()
	set_salvage_mode(false)
	_update_top()


# --- Building the layout ---

func _small_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	return label


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	content.add_child(bar)

	gold_label = Label.new()
	gold_label.custom_minimum_size = Vector2(100, 0)
	gold_label.modulate = Color.GOLD
	bar.add_child(gold_label)

	level_label = Label.new()
	bar.add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.custom_minimum_size = Vector2(0, 14)
	xp_bar.show_percentage = false
	xp_bar.modulate = Color.SKY_BLUE
	bar.add_child(xp_bar)

	var close := Button.new()
	close.text = "X"
	close.pressed.connect(_quit)
	bar.add_child(close)


func _build_equipment() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)

	# Left: armor, then the skill and its cooldown.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(86, 0)
	row.add_child(left)
	left.add_child(_small_label("Armor"))
	armor_box = VBoxContainer.new()
	armor_box.add_theme_constant_override("separation", 6)
	left.add_child(armor_box)
	skill_label = _small_label("Skill: none")
	left.add_child(skill_label)
	skill_bar = ProgressBar.new()
	skill_bar.custom_minimum_size = Vector2(0, 10)
	skill_bar.show_percentage = false
	skill_bar.modulate = Color.ORANGE
	left.add_child(skill_bar)

	# Middle: the selected character, and the team below.
	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(110, 0)
	row.add_child(center)
	hero_rect = ColorRect.new()
	hero_rect.custom_minimum_size = Vector2(100, 120)
	center.add_child(hero_rect)
	hero_name = _small_label("")
	hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(hero_name)
	char_row = HBoxContainer.new()
	char_row.add_theme_constant_override("separation", 4)
	center.add_child(char_row)

	# Right: the staff build, then what the engine says about it.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(_small_label("Tank, battery, grip  /  staff (tank to tip)"))
	gear_row = HBoxContainer.new()
	gear_row.add_theme_constant_override("separation", 4)
	right.add_child(gear_row)
	staff_row = HBoxContainer.new()
	staff_row.add_theme_constant_override("separation", 4)
	right.add_child(staff_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 60)
	right.add_child(scroll)
	result_label = _small_label("")
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(result_label)


func _build_inventory() -> void:
	inv_header = Label.new()
	inv_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_header.custom_minimum_size = Vector2(WIDTH - 20, 0)
	content.add_child(inv_header)

	# Three rows are always visible. More items scroll.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 3 * ItemSlot.SLOT_SIZE + 2 * 6 + 4)
	content.add_child(scroll)

	inv_grid = GridContainer.new()
	inv_grid.columns = COLUMNS
	inv_grid.add_theme_constant_override("h_separation", 6)
	inv_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(inv_grid)


func _build_options() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)

	_add_option(row, "Storage", "storage")
	_add_option(row, "Workbench", "workbench")
	_add_option(row, "Map", "map")

	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(_on_reset_pressed)
	row.add_child(reset_button)


func _add_option(row: HBoxContainer, label: String, option: String) -> void:
	var b := Button.new()
	b.text = label
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func(): option_pressed.emit(option))
	row.add_child(b)


# --- Live values ---

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_update_top()
		_update_skill()


func _update_top() -> void:
	gold_label.text = "Gold %d" % GameState.gold
	level_label.text = "Lv %d   %d / %d XP" % [GameState.level, GameState.xp, GameState.xp_to_next()]
	xp_bar.max_value = GameState.xp_to_next()
	xp_bar.value = GameState.xp
	hero_name.text = "%s  Lv %d" % [CHARACTERS[selected]["name"], GameState.level]


func _update_skill() -> void:
	var p := GameState.player
	if p == null or not p.has_skill():
		skill_label.text = "Skill: none"
		skill_bar.value = 0.0
		return
	var state := "READY" if p.skill_ready() else "%.1fs" % p.skill_timer
	skill_label.text = "%s\n%s" % [skill_name.capitalize(), state]
	skill_bar.max_value = p.skill_cooldown
	skill_bar.value = p.skill_cooldown - p.skill_timer


func set_salvage_mode(on: bool) -> void:
	salvage_mode = on
	if on:
		inv_header.text = "Inventory: SALVAGE MODE (click an item to sell it)"
		inv_header.modulate = Color.ORANGE
	else:
		inv_header.text = "Inventory (click: equip, right-click: storage)"
		inv_header.modulate = Color.WHITE


# --- Refreshing ---

func _refresh_characters() -> void:
	clear_box(char_row)
	for i in CHARACTERS.size():
		var c: Dictionary = CHARACTERS[i]
		var b := Button.new()
		b.text = c["short"]
		b.custom_minimum_size = Vector2(32, 32)
		b.add_theme_font_size_override("font_size", 10)
		b.disabled = not c["unlocked"]
		b.tooltip_text = c["name"] if c["unlocked"] else "%s: not recruited yet" % c["name"]
		if i == selected:
			b.modulate = Color.GOLD
		b.pressed.connect(_select_character.bind(i))
		char_row.add_child(b)
	hero_rect.color = CHARACTERS[selected]["color"]


func _select_character(i: int) -> void:
	selected = i
	_refresh_characters()


func _refresh_equipment() -> void:
	var result := Pipeline.evaluate(GameState.build, GameState.slot_limit)
	if result.is_empty():
		return
	clear_box(gear_row)
	clear_box(staff_row)
	clear_box(armor_box)

	# Gear row: tank, battery, grip.
	var tank = GameState.build["tank"]
	var tank_slot := ItemSlot.new()
	tank_slot.setup("tank", 0, {"kind": "fuel", "fuel": tank["fuel"]} if tank != null else {}, "TANK")
	tank_slot.pressed.connect(GameState.unequip_fuel)
	gear_row.add_child(tank_slot)

	var battery = GameState.build["battery"]
	var battery_slot := ItemSlot.new()
	if not GameState.battery_unlocked():
		battery_slot.setup("battery", 0, {}, "Lv%d" % GameState.BATTERY_SLOT_LEVEL, true)
		battery_slot.tooltip_text = "Battery slot unlocks at level %d" % GameState.BATTERY_SLOT_LEVEL
	else:
		battery_slot.setup("battery", 0, {"kind": "battery"} if battery != null else {}, "BAT")
		battery_slot.pressed.connect(GameState.unequip_battery)
	gear_row.add_child(battery_slot)

	var grip_name: String = GameState.build.get("grip", "")
	var grip_slot := ItemSlot.new()
	var grip_item := {"kind": "grip", "material": grip_name} if grip_name != "" else {}
	grip_slot.setup("grip", 0, grip_item, "GRIP", not GameState.grip_unlocked())
	if not GameState.grip_unlocked():
		grip_slot.tooltip_text += "\nSwapping grips unlocks at level %d" % GameState.GRIP_SLOT_LEVEL
	gear_row.add_child(grip_slot)

	# Staff row: the five ordered slots.
	var parts: Array = GameState.build["parts"]
	var used: Array = result["used"]
	for i in GameData.MAX_ATTACHMENTS:
		var slot := ItemSlot.new()
		if i >= GameState.slot_limit:
			var unlock_level: int = GameState.SLOT_UNLOCK_LEVELS[i]
			slot.setup("staff", i, {}, "Lv%d" % unlock_level, true)
			slot.tooltip_text = "Unlocks at level %d" % unlock_level
		elif i >= parts.size():
			slot.setup("staff", i, {}, str(i + 1))
		else:
			var part: Dictionary = parts[i]
			var item := {"kind": "part", "type": part["type"], "material": part["material"]}
			var contributes: bool = i < used.size() and used[i]
			slot.setup("staff", i, item, "", false, not contributes)
			slot.pressed.connect(GameState.unequip_part.bind(i))
		slot.swap_requested.connect(GameState.swap_parts)
		staff_row.add_child(slot)

	# Armor column: hat, chest, legs, boots. Click a piece to take it off.
	for slot_name in GameState.ARMOR_SLOTS:
		var piece = GameState.armor[slot_name]
		var square := ItemSlot.new()
		square.setup("armor", 0, piece if piece != null else {}, slot_name.to_upper())
		if piece != null:
			square.pressed.connect(GameState.unequip_armor.bind(slot_name))
		armor_box.add_child(square)

	skill_name = result["mode"] if result["has_skill"] else ""
	_refresh_result(result)
	message = ""


func _refresh_result(result: Dictionary) -> void:
	var lines: Array[String] = []
	var basic := Pipeline.evaluate_basic(GameState.build, GameState.slot_limit)
	var basic_dmg: int = 1 if basic["mode"] == "fizzle" else basic["power"]
	lines.append("Basic attack: %d damage" % basic_dmg)
	if result["has_skill"]:
		lines.append("Skill: %s, %d damage, %.1fs cooldown" % [
			result["mode"],
			roundi(result["power"] * GameData.SKILL_DAMAGE_MULT),
			Pipeline.skill_cooldown(result),
		])
	else:
		lines.append("Skill: none (needs a chamber after a working igniter, with fuel)")
	lines.append("Instability: %d%%" % result["instability"])
	lines.append("Shock: %d" % result["shock"])
	var res := GameState.armor_totals()
	lines.append("Armor: shock -%d%%, backfire -%d%%, damage taken -%d%%" % [
		roundi(res["shock"] * 100.0), roundi(res["backfire"] * 100.0), roundi(res["defense"] * 100.0)
	])
	lines.append("Capacity: %d%%" % result["capacity"])
	lines.append("Weight: %d / %d" % [result["weight"], GameState.weight_cap()])
	var over := GameState.overweight(result["weight"])
	if over > 0:
		lines.append("OVERWEIGHT: attacks %d%% slower" % (over * 10))
	lines.append("Crit bonus: +%d%%" % roundi(result["crit_bonus"] * 100.0))
	if result["chain"] != "":
		lines.append("\nChain: %s" % result["chain"])
	if not result["log"].is_empty():
		lines.append("\nNotes:")
		for note in result["log"]:
			lines.append("- %s" % note)
	if message != "":
		lines.append("\n" + message)
	result_label.text = "\n".join(lines)


func _refresh_inventory() -> void:
	clear_box(inv_grid)
	var items := GameState.inventory
	# Always show at least 7 x 3 cells, growing a full row at a time.
	var cells := maxi(MIN_CELLS, ceili(items.size() / float(COLUMNS)) * COLUMNS)
	for i in cells:
		var slot := ItemSlot.new()
		if i < items.size():
			var item: Dictionary = items[i]
			slot.setup("inventory", i, item)
			slot.tooltip_text += "\nRight-click: send to storage"
			if salvage_mode:
				slot.tooltip_text += "\nClick: salvage for %d gold" % Crafting.sell_value(item)
			slot.pressed.connect(_on_item_pressed.bind(item))
			slot.right_clicked.connect(GameState.move_to_storage.bind(item))
		else:
			slot.setup("inventory", i, {}, "", true)
		inv_grid.add_child(slot)


# --- Actions ---

func _on_item_pressed(item: Dictionary) -> void:
	if salvage_mode:
		GameState.sell_item(item)
		return
	match item["kind"]:
		"part":
			if not GameState.equip_part(item):
				message = "No free slot. Remove a part first."
				_refresh_message_only()
		"fuel":
			GameState.equip_fuel(item)
		"battery":
			if not GameState.equip_battery(item):
				message = "Battery slot unlocks at level %d." % GameState.BATTERY_SLOT_LEVEL
				_refresh_message_only()
		"grip":
			if not GameState.equip_grip(item):
				message = "Grip swapping unlocks at level %d." % GameState.GRIP_SLOT_LEVEL
				_refresh_message_only()
		"armor":
			GameState.equip_armor(item)


func _refresh_message_only() -> void:
	# Equipping failed, so nothing changed: just redraw the result text.
	_refresh_result(Pipeline.evaluate(GameState.build, GameState.slot_limit))


# Two clicks, so you can't wipe your save by accident.
func _on_reset_pressed() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "Sure?"
		return
	GameState.reset_progress()


func _quit() -> void:
	GameState.save_game()
	get_tree().quit()
