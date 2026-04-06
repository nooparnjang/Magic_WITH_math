extends Node2D

@export var target: Node2D
@export var follow_speed := 4

func _ready():
	$Camera2D.make_current()

func _process(delta):
	if target == null:
		return
	
	global_position = global_position.lerp(target.global_position, follow_speed * delta)
