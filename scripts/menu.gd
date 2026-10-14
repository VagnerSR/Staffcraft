class_name GameMenu
extends Control

signal layout_changed

var row: HBoxContainer
var storage: StoragePanel
var middle: MiddlePanel
var map: MapPanel
var bench: WorkbenchPanel



func _ready() -> void:
	row = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # with storage closed, the rest stays centered
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	storage = StoragePanel.new()
	storage.visible = false
	row.add_child(storage)

	middle = MiddlePanel.new()
	middle.option_pressed.connect(_on_option)
	row.add_child(middle)

	map = MapPanel.new()
	row.add_child(map)

	bench = WorkbenchPanel.new()
	bench.visible = false
	bench.salvage_toggled.connect(middle.set_salvage_mode)
	row.add_child(bench)


func _on_option(option: String) -> void:
	match option:
		"storage":
			storage.visible = not storage.visible
		"workbench":
			_show_right("map" if bench.visible else "workbench")
		"map":
			_show_right("map")
	layout_changed.emit()


# The map and the workbench share the same spot.
func _show_right(which: String) -> void:
	map.visible = which == "map"
	bench.visible = which == "workbench"
	if which != "workbench":
		bench.reset_salvage()  # leaving the workbench turns salvage mode off
