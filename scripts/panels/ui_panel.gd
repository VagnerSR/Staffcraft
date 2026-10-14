class_name UiPanel
extends PanelContainer
# A framed box with padding and a vertical content column.
# A Theme with a 9-slice texture for "PanelContainer > panel" will restyle all of them.

var content: VBoxContainer


func _init(width := 0, title := "") -> void:
	clip_contents = true
	custom_minimum_size = Vector2(width, 0)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	content = VBoxContainer.new()
	margin.add_child(content)

	if title != "":
		var header := Label.new()
		header.text = title
		header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		header.custom_minimum_size = Vector2(width - 20, 0)
		content.add_child(header)
		content.add_child(HSeparator.new())


static func clear_box(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
