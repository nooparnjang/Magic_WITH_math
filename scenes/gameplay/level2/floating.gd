extends Node2D

@export var float_enabled: bool = true

# ระยะลอยขึ้นลง หน่วยเป็น pixel
@export var float_height: float = 6.0

# ความเร็วลอย ยิ่งเยอะยิ่งเร็ว
@export var float_speed: float = 1.4

# ทำให้แต่ละอันลอยไม่พร้อมกัน ถ้ามีหลายคริสตัล
@export var random_start_phase: bool = true

var base_position: Vector2
var time_passed: float = 0.0


func _ready() -> void:
	base_position = position

	if random_start_phase:
		time_passed = randf() * TAU


func _process(delta: float) -> void:
	if not float_enabled:
		position = base_position
		return

	time_passed += delta * float_speed

	var y_offset := sin(time_passed) * float_height
	position = base_position + Vector2(0.0, y_offset)
