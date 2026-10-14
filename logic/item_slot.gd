class_name ItemSlot
extends Button

signal swap_requested(from_index: int, to_index: int)
signal right_clicked

const SLOT_SIZE := 46

var kind := ""  # "inventory", "staff" or "tank"
var index := -1
var item: Dictionary = {}  # empty means an empty slot


func _init() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	add_theme_font_size_override("font_size", 10)
	gui_input.connect(_on_gui_input)
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and not item.is_empty() and not disabled:
		right_clicked.emit()


# empty_text: what an empty square shows. dim: draw it grayed out.
func setup(p_kind: String, p_index: int, p_item: Dictionary, empty_text := "",
		is_locked := false, dim := false) -> void:
	kind = p_kind
	index = p_index
	item = p_item
	disabled = is_locked

	var color := Color(0.16, 0.16, 0.18)
	if item.is_empty():
		text = empty_text
	else:
		color = Loot.item_color(item)
		text = Loot.short_name(item)
		if item["kind"] == "part" or item["kind"] == "armor":
			text += "\n" + item["material"]
		tooltip_text = Loot.item_tooltip(item)
		if dim:
			tooltip_text += "\n(not contributing in this order)"
			modulate = Color(0.55, 0.55, 0.55)
	_apply_style(color)


func _apply_style(color: Color) -> void:
	var filled := not item.is_empty()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.set_border_width_all(2)
	box.border_color = color.lightened(0.35) if filled else Color(1, 1, 1, 0.15)

	var hover: StyleBoxFlat = box.duplicate()
	hover.bg_color = color.lightened(0.15)

	add_theme_stylebox_override("normal", box)
	add_theme_stylebox_override("disabled", box)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)

	# Dark text on light squares, light text on dark ones.
	var font_color := Color.BLACK if color.get_luminance() > 0.6 else Color.WHITE
	if not filled:
		font_color = Color(1, 1, 1, 0.4)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		add_theme_color_override(state, font_color)


# --- Drag and drop (reordering staff parts) ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	if kind != "staff" or item.is_empty():
		return null
	var preview := Label.new()
	preview.text = Loot.short_name(item)
	set_drag_preview(preview)
	return {"from": index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return kind == "staff" and not disabled \
		and typeof(data) == TYPE_DICTIONARY and data.has("from")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	swap_requested.emit(data["from"], index)
