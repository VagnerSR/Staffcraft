extends Control

const WIDTH := 1216
const BATTLE_H := 180
const MENU_H := 600
const SCREEN_MARGIN := 0.97  # use at most this much of the screen

var design_w := WIDTH

var layout: VBoxContainer
var battle: BattleScene
var menu: GameMenu

var menu_open := false
var ui_scale := 1.0
var shifted_by := 0  # how far the window slid up to fit the menu on screen

var dragging := false
var drag_offset := Vector2i.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	# Everything is laid out at a fixed design size, then scaled to the window.
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	# Art hook: put a theme at res://ui/theme.tres and every panel picks it up.
	if ResourceLoader.exists("res://ui/theme.tres"):
		theme = load("res://ui/theme.tres")

	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	# Battle on top, menu below it.
	battle = load("res://scenes/battle.tscn").instantiate() as BattleScene
	battle.custom_minimum_size = Vector2(WIDTH, BATTLE_H)
	battle.menu_toggled.connect(_toggle_menu)
	layout.add_child(battle)

	menu = GameMenu.new()
	menu.custom_minimum_size = Vector2(WIDTH, MENU_H)
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.visible = false
	menu.layout_changed.connect(_fit_window.call_deferred)
	layout.add_child(menu)

	_dock_top_center()


# The scale that makes battle + menu fit the usable screen (never above 1).
# Sizes the window to the battle (plus the menu when open) and scales it to fit the screen.
# The width is whatever the open panels actually need, never less than WIDTH.
func _fit_window() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	design_w = WIDTH
	if menu_open:
		design_w = maxi(WIDTH, ceili(menu.row.get_combined_minimum_size().x))
	var design_h := BATTLE_H + (MENU_H if menu_open else 0)

	var fit_w := screen.size.x * SCREEN_MARGIN / design_w
	var fit_h := screen.size.y * SCREEN_MARGIN / (BATTLE_H + MENU_H)
	ui_scale = minf(1.0, minf(fit_w, fit_h))

	win.content_scale_size = Vector2i(design_w, design_h)
	win.size = Vector2i(roundi(design_w * ui_scale), roundi(design_h * ui_scale))

	# Keep the whole window on screen.
	win.position.x = clampi(win.position.x, screen.position.x, maxi(screen.end.x - win.size.x, screen.position.x))
	var overflow := win.position.y + win.size.y - screen.end.y
	if overflow > 0:
		win.position.y -= overflow
		shifted_by += overflow


func _dock_top_center() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)
	_fit_window()
	win.position = Vector2i(
		screen.position.x + int((screen.size.x - win.size.x) / 2.0),
		screen.position.y + 40
	)


func _toggle_menu() -> void:
	var win := get_window()
	menu_open = not menu_open
	menu.visible = menu_open
	if menu_open:
		shifted_by = 0
		_fit_window.call_deferred()
	else:
		_fit_window()
		win.position.y += shifted_by
		shifted_by = 0
	battle.set_menu_open(menu_open)


# Borderless windows have no title bar, so drag the battle strip to move it.
# Pressing a button doesn't start a drag.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var over_button := get_viewport().gui_get_hovered_control() is BaseButton
		if event.pressed and not over_button and battle.get_global_rect().has_point(event.position):
			dragging = true
			shifted_by = 0  # you placed the window yourself, so don't undo that on close
			drag_offset = DisplayServer.mouse_get_position() - get_window().position
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		get_window().position = DisplayServer.mouse_get_position() - drag_offset
