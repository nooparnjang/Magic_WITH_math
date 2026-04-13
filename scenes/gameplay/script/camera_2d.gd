extends Node2D

@export var default_target: Node2D
@export var follow_speed := 4.0

var current_target: Node2D
var is_focusing := false
var is_locked_focus := false

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	current_target = default_target
	camera.make_current()

func _process(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		if default_target != null and is_instance_valid(default_target):
			current_target = default_target
		else:
			return

	global_position = global_position.lerp(
		current_target.global_position,
		follow_speed * delta
	)

func focus_on(temp_target: Node2D, duration: float = 1.0) -> void:
	if temp_target == null or not is_instance_valid(temp_target):
		return

	if is_locked_focus:
		return

	if is_focusing:
		return

	await _focus_routine(temp_target, duration)

func _focus_routine(temp_target: Node2D, duration: float) -> void:
	is_focusing = true
	current_target = temp_target

	await get_tree().create_timer(duration).timeout

	if not is_locked_focus:
		if default_target != null and is_instance_valid(default_target):
			current_target = default_target

	is_focusing = false

func lock_focus(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	is_locked_focus = true
	current_target = target

func unlock_focus() -> void:
	is_locked_focus = false

	if default_target != null and is_instance_valid(default_target):
		current_target = default_target
