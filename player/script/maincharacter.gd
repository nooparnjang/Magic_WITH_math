extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -750.0
@export var gravity := 1200.0
@export var math_ui: Control
@export var camera_rig: Node2D

@export var max_hp := 100.0
@export var hp := 100.0

@export var max_stamina := 100.0
@export var stamina := 100.0
@export var stamina_drain_per_second := 18.0
@export var stamina_recover_per_second := 24.0
@export var min_stamina_to_focus := 5.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var target_radius: Area2D = $TargetRadius
@onready var status_bars: Node2D = $Statusbar

var targets_in_range: Array[Node2D] = []
var current_target: Node2D = null
var current_target_index := -1
var is_answering := false
var is_switching_target := false
var is_cast_releasing := false

func _ready() -> void:
	add_to_group("player")

	if not target_radius.body_entered.is_connected(_on_target_radius_body_entered):
		target_radius.body_entered.connect(_on_target_radius_body_entered)

	if not target_radius.body_exited.is_connected(_on_target_radius_body_exited):
		target_radius.body_exited.connect(_on_target_radius_body_exited)

	if status_bars != null and status_bars.has_method("setup"):
		status_bars.setup(max_hp, hp, max_stamina, stamina)

	if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta: float) -> void:
	update_stamina(delta)

	# กำลังปล่อยเวทหลังตอบถูก
	if is_cast_releasing:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()
		return

	# กำลังตอบโจทย์ / กำลังสลับเป้า
	if is_answering or is_switching_target:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()

		if Input.is_action_just_pressed("ui_closemath"):
			cancel_math_mode()
			return

		if Input.is_action_just_pressed("target_select") and not is_switching_target:
			cycle_target()

		return

	var direction: float = Input.get_axis("ui_left", "ui_right")

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

	if Input.is_action_just_pressed("target_select") and not is_switching_target:
		cycle_target()

func start_cast_release() -> void:
	if not sprite.sprite_frames.has_animation("casting"):
		finish_answering()
		return

	is_answering = false
	is_cast_releasing = true
	sprite.play("casting")
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if is_cast_releasing and sprite.animation == "casting":
		is_cast_releasing = false
		finish_answering()




func update_stamina(delta: float) -> void:
	var is_focusing_target: bool = is_answering and current_target != null and is_instance_valid(current_target)

	if is_focusing_target:
		stamina -= stamina_drain_per_second * delta
		stamina = max(stamina, 0.0)

		if stamina <= 0.0:
			cancel_math_mode()
	else:
		stamina += stamina_recover_per_second * delta
		stamina = min(stamina, max_stamina)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)

func _on_target_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("targetable"):
		if not targets_in_range.has(body):
			targets_in_range.append(body)
			print("targetable entered:", body.name)

func _on_target_radius_body_exited(body: Node2D) -> void:
	if targets_in_range.has(body):
		var removed_index: int = targets_in_range.find(body)
		targets_in_range.erase(body)

		if removed_index <= current_target_index:
			current_target_index -= 1

	if current_target == body:
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

		current_target = null
		current_target_index = -1
		is_answering = false
		is_switching_target = false
		is_cast_releasing = false

		if math_ui != null and math_ui.has_method("close_ui_silent"):
			math_ui.close_ui_silent()
		elif math_ui != null and math_ui.has_method("close_ui"):
			math_ui.close_ui()

		if camera_rig != null and camera_rig.has_method("unlock_focus"):
			camera_rig.unlock_focus()

func cleanup_targets() -> void:
	var valid_targets: Array[Node2D] = []

	for target in targets_in_range:
		if is_instance_valid(target):
			valid_targets.append(target)

	targets_in_range = valid_targets

	if current_target_index >= targets_in_range.size():
		current_target_index = -1

func cycle_target() -> void:
	_cycle_target_async()

func _cycle_target_async() -> void:
	if is_switching_target:
		return

	if stamina < min_stamina_to_focus:
		print("stamina ไม่พอสำหรับ focus")
		return

	is_switching_target = true
	cleanup_targets()

	if targets_in_range.is_empty():
		print("ไม่มี target ในระยะ")
		is_switching_target = false
		return

	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	current_target_index += 1
	if current_target_index >= targets_in_range.size():
		current_target_index = 0

	current_target = targets_in_range[current_target_index]

	if current_target == null or not is_instance_valid(current_target):
		is_switching_target = false
		return

	if current_target.has_method("set_selected"):
		current_target.set_selected(true)

	if math_ui == null:
		push_error("math_ui ยังไม่ได้ assign")
		is_switching_target = false
		return

	if camera_rig != null and camera_rig.has_method("lock_focus"):
		camera_rig.lock_focus(current_target)

	is_answering = true
	math_ui.open_question(current_target, self)
	is_switching_target = false

func cancel_math_mode() -> void:
	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	current_target = null
	current_target_index = -1
	is_answering = false
	is_switching_target = false
	is_cast_releasing = false

	if sprite.animation == "casting":
		sprite.play("idle")

	if math_ui != null and math_ui.has_method("close_ui_silent"):
		math_ui.close_ui_silent()
	elif math_ui != null and math_ui.has_method("close_ui"):
		math_ui.close_ui()

	if camera_rig != null and camera_rig.has_method("unlock_focus"):
		camera_rig.unlock_focus()

func finish_answering() -> void:
	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	current_target = null
	current_target_index = -1
	is_answering = false
	is_switching_target = false
	is_cast_releasing = false

	if camera_rig != null and camera_rig.has_method("unlock_focus"):
		camera_rig.unlock_focus()

func take_damage(amount: float) -> void:
	hp -= amount
	hp = max(hp, 0.0)

	if status_bars != null and status_bars.has_method("set_health"):
		status_bars.set_health(hp, max_hp)

	if hp <= 0.0:
		die()

func heal(amount: float) -> void:
	hp += amount
	hp = min(hp, max_hp)

	if status_bars != null and status_bars.has_method("set_health"):
		status_bars.set_health(hp, max_hp)

func restore_stamina(amount: float) -> void:
	stamina += amount
	stamina = min(stamina, max_stamina)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)

func consume_stamina(amount: float) -> void:
	stamina -= amount
	stamina = max(stamina, 0.0)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)

	if stamina <= 0.0:
		cancel_math_mode()

func die() -> void:
	print("player dead")
