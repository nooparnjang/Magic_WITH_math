extends Node2D

@export var default_target: Node2D
@export var follow_speed := 4.0

var current_target: Node2D
var is_focusing := false

func _ready() -> void:
	current_target = default_target
	$Camera2D.make_current()

func _process(delta: float) -> void:
	if current_target == null:
		return
	
	global_position = global_position.lerp(
		current_target.global_position,
		follow_speed * delta
	)

func focus_on(temp_target: Node2D, duration: float = 1.0) -> void:
	if temp_target == null:
		return
	if is_focusing:
		return
	
	_focus_routine(temp_target, duration)

func _focus_routine(temp_target: Node2D, duration: float) -> void:
	is_focusing = true
	current_target = temp_target
	
	await get_tree().create_timer(duration).timeout
	
	current_target = default_target
	is_focusing = false
