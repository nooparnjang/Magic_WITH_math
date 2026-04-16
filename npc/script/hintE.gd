extends Node2D

@export var float_speed := 3.0
@export var float_amount := 3.0

@onready var visual: Control = $visual

var _float_time := 0.0
var _base_visual_position := Vector2.ZERO

func _ready() -> void:
	hide()
	await get_tree().process_frame
	_base_visual_position = visual.position

func _process(delta: float) -> void:
	if not visible:
		return

	_float_time += delta
	var offset_y := sin(_float_time * float_speed) * float_amount
	visual.position = _base_visual_position + Vector2(0, offset_y)

func show_hint() -> void:
	show()
	_float_time = 0.0
	visual.position = _base_visual_position

func hide_hint() -> void:
	hide()
	_float_time = 0.0
	visual.position = _base_visual_position
