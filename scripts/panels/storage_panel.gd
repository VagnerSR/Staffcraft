class_name StoragePanel
extends UiPanel

const WIDTH := 340
const COLUMNS := 6
const MIN_CELLS := 48

var grid: GridContainer


func _init() -> void:
	super(WIDTH, "Storage (click an item to move it to the inventory)")


func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	GameState.storage_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	clear_box(grid)
	var items := GameState.storage
	var cells := maxi(MIN_CELLS, ceili(items.size() / float(COLUMNS)) * COLUMNS)
	for i in cells:
		var slot := ItemSlot.new()
		if i < items.size():
			var item: Dictionary = items[i]
			slot.setup("storage", i, item)
			slot.pressed.connect(GameState.move_to_inventory.bind(item))
		else:
			slot.setup("storage", i, {}, "", true)
		grid.add_child(slot)
