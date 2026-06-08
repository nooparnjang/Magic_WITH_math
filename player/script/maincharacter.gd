extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -750.0
@export var gravity := 1200.0
@export var math_ui: Control
@export var camera_rig: Node2D
@export var game_over_ui: Control

@export var max_hp := 100.0
@export var hp := 100.0

@export var max_stamina := 100.0
@export var stamina := 100.0
@export var stamina_drain_per_second := 14.0
@export var stamina_recover_per_second := 24.0
@export var min_stamina_to_focus := 5.0

@export var damage_invincibility_time := 0.5

@export var health_regen_per_second := 10.0
@export var health_regen_delay := 4.0

@onready var item_selector: Node = $Items/ItemSelector
@onready var item_use_controller: Node = $Items/ItemUseController
@onready var player_bubble: Node = $BubbleAnchor/DialogBubble

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var target_radius: Area2D = $TargetRadius
@onready var status_bars: Node2D = $Statusbar

var targets_in_range: Array[Node2D] = []
var current_target: Node2D = null
var current_target_index := -1

var is_answering := false
var is_switching_target := false
var is_cast_releasing := false
var is_dead := false
var can_take_damage := true

var is_interacting := false

var time_since_last_damage := 0.0

var pending_damage_target: Node2D = null
var pending_damage_amount: int = 0


func _ready() -> void:
	add_to_group("player")
	if player_bubble != null:
		
		if player_bubble.has_method("hide_bubble"):
			player_bubble.hide_bubble()
		else:
			player_bubble.hide()

	if target_radius != null:
		if not target_radius.body_entered.is_connected(_on_target_radius_body_entered):
			target_radius.body_entered.connect(_on_target_radius_body_entered)

		if not target_radius.body_exited.is_connected(_on_target_radius_body_exited):
			target_radius.body_exited.connect(_on_target_radius_body_exited)

	if status_bars != null and status_bars.has_method("setup"):
		status_bars.setup(max_hp, hp, max_stamina, stamina)

	if sprite != null:
		if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
			sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if is_interacting:
		return

	if item_selector == null:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			item_selector.cycle_selected_item(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			item_selector.cycle_selected_item(1)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()
		return

	time_since_last_damage += delta

	update_stamina(delta)
	update_health_regen(delta)

	if is_interacting:
		_process_locked_movement(delta)

		if is_on_floor() and sprite.animation != "idle":
			sprite.play("idle")

		return

	if is_cast_releasing:
		_process_locked_movement(delta)

		if sprite.sprite_frames.has_animation("release"):
			if sprite.animation != "release":
				sprite.play("release")

		return

	if _is_in_focus_mode():
		_process_locked_movement(delta)

		if _should_play_charge_animation():
			if sprite.sprite_frames.has_animation("charge"):
				if sprite.animation != "charge":
					sprite.play("charge")

		if Input.is_action_just_pressed("ui_closemath"):
			cancel_math_mode()
			return

		if Input.is_action_just_pressed("target_select") and not is_switching_target:
			_handle_target_select_pressed()

		if Input.is_action_just_pressed("ui_accept"):
			_handle_accept_pressed()
			return

		return

	_process_normal_movement(delta)

	if Input.is_action_just_pressed("target_select") and not is_switching_target:
		_handle_target_select_pressed()


func set_status_bars_visible(value: bool) -> void:
	if status_bars == null:
		return

	status_bars.visible = value
	
func get_dialog_bubble() -> Node:
	return player_bubble


func hide_player_bubble() -> void:
	if player_bubble == null:
		return

	if player_bubble.has_method("hide_bubble"):
		player_bubble.hide_bubble()
	else:
		player_bubble.hide()

func _process_locked_movement(delta: float) -> void:
	velocity.x = 0.0

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func _process_normal_movement(delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")

	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if not is_on_floor():
		if sprite.animation != "jump":
			sprite.play("jump")
	elif direction == 0:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")

		sprite.flip_h = direction < 0


func _handle_target_select_pressed() -> void:
	if item_selector == null:
		cycle_target()
		return

	var selected_item_id: String = item_selector.get_selected_item_id()

	if selected_item_id != "":
		if item_use_controller != null and item_use_controller.has_method("use_selected_item"):
			item_use_controller.use_selected_item()
	else:
		cycle_target()


func _handle_accept_pressed() -> void:
	if item_use_controller != null:
		if item_use_controller.has_method("is_item_targeting_active"):
			if item_use_controller.is_item_targeting_active():
				item_use_controller.confirm_item_use()
				return


func _is_in_focus_mode() -> bool:
	var item_targeting := false

	if item_use_controller != null and item_use_controller.has_method("is_item_targeting_active"):
		item_targeting = item_use_controller.is_item_targeting_active()

	return is_answering or is_switching_target or item_targeting


func _should_play_charge_animation() -> bool:
	if is_answering:
		return true

	if item_use_controller != null and item_use_controller.has_method("is_item_targeting_active"):
		if item_use_controller.is_item_targeting_active():
			return true

	return false


func start_cast_release(target: Node2D = null, damage_amount: int = 1) -> void:
	print("start_cast_release called")

	pending_damage_target = target
	pending_damage_amount = damage_amount

	if not sprite.sprite_frames.has_animation("release"):
		print("NO RELEASE ANIMATION")

		if pending_damage_target != null and is_instance_valid(pending_damage_target):
			if pending_damage_target.has_method("take_damage"):
				pending_damage_target.take_damage(pending_damage_amount)

		pending_damage_target = null
		pending_damage_amount = 0
		finish_answering()
		return

	is_answering = false
	is_cast_releasing = true
	sprite.play("release")
	print("playing release")


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_cast_releasing and sprite.animation == "release":
		if pending_damage_target != null and is_instance_valid(pending_damage_target):
			if pending_damage_target.has_method("take_damage"):
				pending_damage_target.take_damage(pending_damage_amount)

		pending_damage_target = null
		pending_damage_amount = 0

		is_cast_releasing = false
		finish_answering()


func update_stamina(delta: float) -> void:
	if is_dead:
		return

	var is_math_focusing: bool = is_answering and current_target != null and is_instance_valid(current_target)
	var is_item_focusing: bool = false

	if item_use_controller != null and item_use_controller.has_method("has_focus_target"):
		is_item_focusing = item_use_controller.has_focus_target()

	if is_math_focusing or is_item_focusing:
		stamina -= stamina_drain_per_second * delta
		stamina = max(stamina, 0.0)

		if stamina <= 0.0:
			cancel_math_mode()
	else:
		stamina += stamina_recover_per_second * delta
		stamina = min(stamina, max_stamina)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)


func update_health_regen(delta: float) -> void:
	if is_dead:
		return

	if hp >= max_hp:
		return

	if time_since_last_damage < health_regen_delay:
		return

	hp += health_regen_per_second * delta
	hp = min(hp, max_hp)

	if status_bars != null and status_bars.has_method("set_health"):
		status_bars.set_health(hp, max_hp)


func _on_target_radius_body_entered(body: Node2D) -> void:
	if is_interacting:
		return

	if body.is_in_group("targetable"):
		if not targets_in_range.has(body):
			targets_in_range.append(body)
			print("targetable entered:", body.name)

		if body.has_method("activate"):
			body.activate(self)


func _on_target_radius_body_exited(body: Node2D) -> void:
	if targets_in_range.has(body):
		var removed_index: int = targets_in_range.find(body)
		targets_in_range.erase(body)

		if removed_index <= current_target_index:
			current_target_index -= 1

	if item_use_controller != null and item_use_controller.has_method("on_target_exited"):
		item_use_controller.on_target_exited(body)

	if is_cast_releasing and body == current_target:
		return

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

		if not is_dead and is_on_floor():
			sprite.play("idle")


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
	if is_dead:
		return

	if is_interacting:
		return

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

	if item_use_controller != null and item_use_controller.has_method("cancel_item_use"):
		item_use_controller.cancel_item_use()

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
	is_cast_releasing = false

	if sprite.sprite_frames.has_animation("charge"):
		sprite.play("charge")

	math_ui.open_question(current_target, self)
	is_switching_target = false


func cancel_math_mode() -> void:
	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	if item_use_controller != null and item_use_controller.has_method("cancel_item_use"):
		item_use_controller.cancel_item_use()

	current_target = null
	current_target_index = -1
	is_answering = false
	is_switching_target = false
	is_cast_releasing = false
	pending_damage_target = null
	pending_damage_amount = 0

	if sprite.animation == "charge" or sprite.animation == "release":
		if is_on_floor():
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

	if not is_dead and is_on_floor():
		sprite.play("idle")


func on_item_use_finished() -> void:
	if not is_dead and is_on_floor():
		sprite.play("idle")


func take_damage(amount: float) -> void:
	if is_dead:
		return

	if not can_take_damage:
		return

	can_take_damage = false

	hp -= amount
	hp = max(hp, 0.0)

	time_since_last_damage = 0.0

	print("player took damage:", amount, "hp left:", hp)

	if status_bars != null and status_bars.has_method("set_health"):
		status_bars.set_health(hp, max_hp)

	if hp <= 0.0:
		die()
		return

	await get_tree().create_timer(damage_invincibility_time).timeout

	if not is_dead:
		can_take_damage = true


func heal(amount: float) -> void:
	if is_dead:
		return

	hp += amount
	hp = min(hp, max_hp)

	if status_bars != null and status_bars.has_method("set_health"):
		status_bars.set_health(hp, max_hp)


func restore_stamina(amount: float) -> void:
	if is_dead:
		return

	stamina += amount
	stamina = min(stamina, max_stamina)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)


func consume_stamina(amount: float) -> void:
	if is_dead:
		return

	stamina -= amount
	stamina = max(stamina, 0.0)

	if status_bars != null and status_bars.has_method("set_stamina"):
		status_bars.set_stamina(stamina, max_stamina)

	if stamina <= 0.0:
		cancel_math_mode()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	can_take_damage = false

	cancel_math_mode()

	if item_use_controller != null and item_use_controller.has_method("cancel_item_use"):
		item_use_controller.cancel_item_use()

	if is_on_floor():
		sprite.play("idle")

	print("player dead")

	if game_over_ui != null:
		if game_over_ui.has_method("show_game_over"):
			game_over_ui.show_game_over()
		else:
			game_over_ui.visible = true
			game_over_ui.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true


func begin_interaction() -> void:
	if is_dead:
		return

	is_interacting = true
	cancel_math_mode()
	set_status_bars_visible(false)


func end_interaction() -> void:
	is_interacting = false

	if not is_dead:
		set_status_bars_visible(true)


func get_targets_in_range() -> Array[Node2D]:
	cleanup_targets()
	return targets_in_range


func get_stamina() -> float:
	return stamina


func is_player_dead() -> bool:
	return is_dead


func is_player_interacting() -> bool:
	return is_interacting
