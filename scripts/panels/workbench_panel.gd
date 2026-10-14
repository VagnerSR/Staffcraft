class_name WorkbenchPanel
extends UiPanel

signal salvage_toggled(is_on: bool)

const WIDTH := 340

var craft_type: OptionButton
var craft_material: OptionButton
var craft_info: Label
var craft_button: Button
var battery_button: Button
var grip_button: Button
var armor_slot: OptionButton
var armor_material: OptionButton
var armor_button: Button
var salvage_check: CheckButton


func _init() -> void:
	super(WIDTH, "Workbench")


func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	salvage_check = CheckButton.new()
	salvage_check.text = "Salvage mode"
	salvage_check.tooltip_text = "While on, clicking an inventory item sells it for gold."
	salvage_check.toggled.connect(func(on): salvage_toggled.emit(on))
	box.add_child(salvage_check)
	box.add_child(HSeparator.new())

	craft_type = OptionButton.new()
	for part_type in Crafting.RECIPES:
		craft_type.add_item(part_type)
	craft_type.item_selected.connect(func(_i): _update_craft_preview())
	box.add_child(craft_type)

	craft_material = OptionButton.new()
	for mat_name in Crafting.MATERIALS:
		craft_material.add_item(mat_name)
	craft_material.selected = 1  # copper
	craft_material.item_selected.connect(func(_i): _update_craft_preview())
	box.add_child(craft_material)

	craft_info = Label.new()
	craft_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(craft_info)

	craft_button = Button.new()
	craft_button.pressed.connect(func():
		GameState.craft_part(
			craft_type.get_item_text(craft_type.selected),
			craft_material.get_item_text(craft_material.selected)))
	box.add_child(craft_button)

	battery_button = Button.new()
	battery_button.text = "Craft battery for %d gold" % Crafting.BATTERY_COST
	battery_button.pressed.connect(GameState.craft_battery)
	box.add_child(battery_button)

	grip_button = Button.new()
	grip_button.pressed.connect(func():
		GameState.craft_grip(craft_material.get_item_text(craft_material.selected)))
	box.add_child(grip_button)

	box.add_child(HSeparator.new())

	armor_slot = OptionButton.new()
	for slot_name in GameState.ARMOR_SLOTS:
		armor_slot.add_item(slot_name)
	armor_slot.item_selected.connect(func(_i): _update_craft_preview())
	box.add_child(armor_slot)

	armor_material = OptionButton.new()
	for armor_mat in Armor.MATERIALS:
		armor_material.add_item(armor_mat)
	armor_material.item_selected.connect(func(_i): _update_craft_preview())
	box.add_child(armor_material)

	armor_button = Button.new()
	armor_button.pressed.connect(func():
		GameState.craft_armor(
			armor_slot.get_item_text(armor_slot.selected),
			armor_material.get_item_text(armor_material.selected)))
	box.add_child(armor_button)

	GameState.gold_changed.connect(_update_craft_preview)
	_update_craft_preview()


func reset_salvage() -> void:
	salvage_check.button_pressed = false


func _update_craft_preview() -> void:
	var part_type: String = craft_type.get_item_text(craft_type.selected)
	var mat_name: String = craft_material.get_item_text(craft_material.selected)

	var price := Crafting.cost(part_type, mat_name)
	craft_info.text = Loot.item_tooltip({"kind": "part", "type": part_type, "material": mat_name})
	craft_button.text = "Craft for %d gold" % price
	craft_button.disabled = GameState.gold < price

	battery_button.disabled = GameState.gold < Crafting.BATTERY_COST

	var grip_price := Crafting.grip_cost(mat_name)
	grip_button.text = "Craft %s grip for %d gold" % [mat_name, grip_price]
	grip_button.disabled = GameState.gold < grip_price

	var a_slot: String = armor_slot.get_item_text(armor_slot.selected)
	var a_mat: String = armor_material.get_item_text(armor_material.selected)
	var a_price := Armor.cost(a_slot, a_mat)
	armor_button.text = "Craft %s %s for %d gold" % [a_mat, a_slot, a_price]
	armor_button.disabled = GameState.gold < a_price
