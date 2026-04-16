extends Node2D

@export var float_amplitude: float = 4.0
@export var float_speed: float = 3.0

var base_y: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	base_y = position.y

func _process(delta: float) -> void:
	time_passed += delta
	position.y = base_y + sin(time_passed * float_speed) * float_amplitude
