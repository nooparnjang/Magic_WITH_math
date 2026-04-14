extends Node2D

@export var float_distance: float = 35.0
@export var duration: float = 1

@onready var label: Label = $Label

func _ready() -> void:
	modulate = Color(1, 1, 1, 1)
	z_index = 999

func show_at(world_pos: Vector2, amount: int) -> void:
	global_position = world_pos
	label.text = "+%d BLESSINGS" % amount

	var end_pos := global_position + Vector2(0, -float_distance)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", end_pos, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)

	await tween.finished
	queue_free()
