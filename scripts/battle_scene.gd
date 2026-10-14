class_name BattleScene
extends Control

signal menu_toggled

const INFO_W := 240.0

@onready var info_panel: Panel = $InfoPanel
@onready var arena: Control = $Arena
@onready var open_button: Button = $InfoPanel/OpenButton
@onready var terrain_label: Label = $InfoPanel/TerrainLabel
@onready var phase_label: Label = $InfoPanel/PhaseLabel
@onready var phase_bar: ProgressBar = $InfoPanel/PhaseProgress


func _ready() -> void:
	phase_bar.custom_minimum_size = Vector2(0, 24)
	phase_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	info_panel.offset_right = INFO_W
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.offset_left = INFO_W
	open_button.pressed.connect(func(): menu_toggled.emit())


func set_menu_open(is_open: bool) -> void:
	open_button.text = "Close menu" if is_open else "Open menu"


func _process(_delta: float) -> void:
	terrain_label.text = "Terrain: %s" % Stages.TERRAIN_NAME
	phase_label.text = "Phase: %d" % GameState.stage
	phase_bar.value = GameState.phase_progress * 100.0
