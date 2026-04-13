extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -750.0
@export var gravity := 1200.0
@export var math_ui: Control

@onready var sprite = $AnimatedSprite2D
@onready var target_radius: Area2D = $TargetRadius

var targets_in_range: Array[Node2D] = []
var current_target: Node2D = null
var current_target_index := -1
var is_answering := false

func _ready() -> void:
	add_to_group("player")

	if not target_radius.body_entered.is_connected(_on_target_radius_body_entered):
		target_radius.body_entered.connect(_on_target_radius_body_entered)

	if not target_radius.body_exited.is_connected(_on_target_radius_body_exited):
		target_radius.body_exited.connect(_on_target_radius_body_exited)

func _physics_process(delta):
	if is_answering:
		velocity.x = 0

		if not is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()

		if Input.is_action_just_pressed("target_select"):
			cycle_target()
		return

	var direction = Input.get_axis("ui_left", "ui_right")

	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if not is_on_floor():
		sprite.play("jump")
	elif direction == 0:
		sprite.play("idle")
	else:
		sprite.play("walk")
		sprite.flip_h = direction < 0

	if Input.is_action_just_pressed("target_select"):
		cycle_target()

func _on_target_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("targetable"):
		if not targets_in_range.has(body):
			targets_in_range.append(body)

func _on_target_radius_body_exited(body: Node2D) -> void:
	if targets_in_range.has(body):
		var removed_index := targets_in_range.find(body)
		targets_in_range.erase(body)

		if removed_index <= current_target_index:
			current_target_index -= 1

	if current_target == body:
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

		current_target = null
		current_target_index = -1

		if math_ui != null and math_ui.has_method("close_ui"):
			math_ui.close_ui()

		is_answering = false

func cleanup_targets() -> void:
	var valid_targets: Array[Node2D] = []

	for target in targets_in_range:
		if is_instance_valid(target):
			valid_targets.append(target)

	targets_in_range = valid_targets

	if current_target_index >= targets_in_range.size():
		current_target_index = -1

func cycle_target() -> void:
	cleanup_targets()

	if targets_in_range.is_empty():
		print("ไม่มี target ในระยะ")
		return

	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	current_target_index += 1
	if current_target_index >= targets_in_range.size():
		current_target_index = 0

	current_target = targets_in_range[current_target_index]

	if current_target != null and current_target.has_method("set_selected"):
		current_target.set_selected(true)

	is_answering = true

	if math_ui == null:
		push_error("math_ui ยังไม่ได้ assign")
		return

	math_ui.open_question(current_target, self)

func finish_answering() -> void:
	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	current_target = null
	current_target_index = -1
	is_answering = false
