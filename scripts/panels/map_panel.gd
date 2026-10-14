class_name MapPanel
extends UiPanel

const WIDTH := 340
const NODE_SIZE := 44
# Top-left corner of each phase's button on the map.
const NODE_POS := [
	Vector2(20, 320), Vector2(100, 300), Vector2(180, 330), Vector2(250, 270), Vector2(190, 210),
	Vector2(110, 230), Vector2(30, 170), Vector2(90, 100), Vector2(170, 130), Vector2(230, 50),
]

var field: Control
var buttons: Array[Button] = []
var info: Label


func _init() -> void:
	super(WIDTH, "Map: " + Stages.TERRAIN_NAME)


func _ready() -> void:
	# The field is the map's canvas. Later, a TextureRect or TileMapLayer goes behind the buttons.
	field = Control.new()
	field.custom_minimum_size = Vector2(300, 380)
	content.add_child(field)

	var path := Line2D.new()
	path.width = 4.0
	path.default_color = Color(1, 1, 1, 0.25)
	for pos in NODE_POS:
		path.add_point(pos + Vector2.ONE * NODE_SIZE / 2.0)
	field.add_child(path)

	for i in Stages.PHASES_PER_TERRAIN:
		var b := Button.new()
		b.text = str(i + 1)
		b.position = NODE_POS[i]
		b.size = Vector2(NODE_SIZE, NODE_SIZE)
		b.pressed.connect(GameState.travel_to.bind(i + 1))
		field.add_child(b)
		buttons.append(b)

	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info)

	GameState.phase_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in buttons.size():
		var phase := i + 1
		var b := buttons[i]
		b.disabled = phase > GameState.max_stage
		if phase == GameState.stage:
			b.modulate = Color.GOLD
		elif phase < GameState.max_stage:
			b.modulate = Color.LIGHT_GREEN
		else:
			b.modulate = Color.WHITE
	var mult: float = Stages.get_stage(GameState.stage)["mult"]
	info.text = "Phase %d of %d, enemy strength x%.1f\nClick a reached phase to travel there." % [
		GameState.stage, Stages.PHASES_PER_TERRAIN, mult
	]
