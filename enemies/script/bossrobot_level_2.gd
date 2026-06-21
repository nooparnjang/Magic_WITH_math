extends CharacterBody2D

@export var boss_name: String = "Factory Overload Guardian"

@export var max_hp: int = 18
@export var move_speed: float = 155.0
@export var gravity: float = 1200.0

@export var contact_damage: int = 4
@export var contact_damage_cooldown: float = 0.45

@export var activation_range: float = 540.0

var facing_dir: int = 1


# -------------------------
# Melee
# -------------------------
@export var attack_cooldown: float = 0.35
@export var attack_range: float = 58.0
@export var max_vertical_attack_gap: float = 80.0

# จังหวะที่ดาเมจออกหลังเริ่ม animation fight
@export var attack_damage_delay: float = 0.14


# -------------------------
# Reward / Drop
# -------------------------
@export var blessing_reward: int = 60
@export var hit_effect_scene: PackedScene
@export var item_drop_scene: PackedScene
@export var item_drop_id: String = "A2 key"
@export var item_drop_amount: int = 1
@export var item_drop_texture: Texture2D


# -------------------------
# Math Question Pattern
# -------------------------
@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 1

@export var allowed_operators: Array[String] = ["+", "-", "*"]


# -------------------------
# Phase 2
# -------------------------
@export var phase_2_hp_ratio: float = 0.5
@export var phase_2_speed_multiplier: float = 1.25
@export var phase_2_attack_cooldown_multiplier: float = 0.75


# -------------------------
# Overload Shock
# -------------------------
@export var overload_damage: int = 8
@export var overload_trigger_range: float = 145.0
@export var overload_cooldown: float = 4.5
@export var overload_warning_time: float = 0.75
@export var overload_active_time: float = 0.22
@export var overload_damage_once_per_cast: bool = true

@export var overload_warning_pulse_enabled: bool = true
@export var overload_warning_pulse_speed: float = 12.0
@export var overload_warning_pulse_amount: float = 0.12


# -------------------------
# Cooldown Label
# -------------------------
@export var show_overload_cooldown_label: bool = true
@export var overload_ready_text: String = "!"
@export var overload_shock_text: String = "SHOCK"
@export var overload_cooldown_label_offset: Vector2 = Vector2(0, -105)


var hp: int = 0
var player_ref: Node2D = null

var is_dead := false
var is_activated := false

var is_attacking := false
var is_overloading := false

var can_contact_damage := true
var can_attack := true
var can_overload := true

var is_phase_2 := false

var original_move_speed: float = 0.0
var original_attack_cooldown: float = 0.0

var overload_hit_bodies: Array[Node] = []
var overload_cooldown_left: float = 0.0
var overload_warning_time_count: float = 0.0
var overload_warning_base_scale: Vector2 = Vector2.ONE


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

@onready var collision_damage_cooldown_timer: Timer = $CollisionDamageCooldown
@onready var status_bar: Node2D = $Bossstatus

@onready var overload_area: Area2D = $OverloadArea
@onready var overload_collision: CollisionShape2D = $OverloadArea/CollisionShape2D

# แนะนำให้ OverloadWarning เป็น Polygon2D
@onready var overload_warning: Node2D = $OverloadWarning

# OverloadBurst ต้องเป็น AnimatedSprite2D และมี animation ชื่อ burst
@onready var overload_burst_sprite: AnimatedSprite2D = $OverloadBurst

@onready var overload_cooldown_label: Label = $OverloadCooldownLabel


func _ready() -> void:
	hp = max_hp

	original_move_speed = move_speed
	original_attack_cooldown = attack_cooldown

	add_to_group("targetable")
	add_to_group("boss")

	player_ref = get_tree().get_first_node_in_group("player") as Node2D

	if hitbox != null:
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

	if overload_area != null:
		if not overload_area.body_entered.is_connected(_on_overload_area_body_entered):
			overload_area.body_entered.connect(_on_overload_area_body_entered)

	if collision_damage_cooldown_timer != null:
		if not collision_damage_cooldown_timer.timeout.is_connected(_on_collision_damage_cooldown_timeout):
			collision_damage_cooldown_timer.timeout.connect(_on_collision_damage_cooldown_timeout)

		collision_damage_cooldown_timer.wait_time = contact_damage_cooldown

	if overload_collision != null:
		overload_collision.disabled = true

	if overload_warning != null:
		overload_warning.visible = false
		overload_warning_base_scale = overload_warning.scale

	if overload_burst_sprite != null:
		overload_burst_sprite.visible = false

	if overload_cooldown_label != null:
		overload_cooldown_label.visible = false
		overload_cooldown_label.position = overload_cooldown_label_offset
		overload_cooldown_label.text = ""
		overload_cooldown_label.z_index = 999

	if status_bar != null and status_bar.has_method("setup"):
		status_bar.setup(max_hp, hp)


func activate(player: Node2D) -> void:
	if is_dead:
		return

	player_ref = player
	is_activated = true


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return

	update_overload_cooldown_label(delta)
	update_overload_warning_visual(delta)

	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node2D

	if player_ref == null or not is_instance_valid(player_ref):
		velocity.x = 0.0
		_apply_gravity(delta)
		_play_idle()
		move_and_slide()
		return

	var to_player: Vector2 = player_ref.global_position - global_position
	var horizontal_distance: float = abs(to_player.x)
	var vertical_distance: float = abs(to_player.y)

	if to_player.length() <= activation_range:
		is_activated = true

	if not is_activated:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_animation(to_player)
		return

	if abs(to_player.x) > 1.0:
		facing_dir = -1 if to_player.x < 0.0 else 1
		update_facing()

	if is_attacking or is_overloading:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_animation(to_player)
		return

	# Phase 2: ถ้าผู้เล่นเข้าใกล้และ Overload พร้อมใช้ จะชาร์จช็อค
	if is_phase_2 and can_overload and horizontal_distance <= overload_trigger_range:
		try_overload_attack()
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_animation(to_player)
		return

	# ไม่มีระบบยิงแล้ว:
	# ถ้าอยู่ในระยะตีและความสูงใกล้กัน = ตี
	# ถ้ายังไม่ถึงระยะ = วิ่งไล่
	if vertical_distance <= max_vertical_attack_gap and horizontal_distance <= attack_range:
		velocity.x = 0.0

		if can_attack:
			try_attack_player()
	else:
		velocity.x = sign(to_player.x) * move_speed

	_apply_gravity(delta)
	move_and_slide()
	_update_animation(to_player)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


func _update_animation(direction: Vector2) -> void:
	if sprite == null or is_dead:
		return

	if is_overloading:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("overload"):
			if sprite.animation != "overload":
				sprite.play("overload")
		else:
			if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
				if sprite.animation != "idle":
					sprite.play("idle")
		return

	if is_attacking:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("fight"):
			if sprite.animation != "fight":
				sprite.play("fight")
		return

	if abs(direction.x) > 1.0:
		facing_dir = -1 if direction.x < 0.0 else 1
		update_facing()

	if abs(velocity.x) > 5.0:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("walk"):
			if sprite.animation != "walk":
				sprite.play("walk")
	else:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
			if sprite.animation != "idle":
				sprite.play("idle")


func _play_idle() -> void:
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		if sprite.animation != "idle":
			sprite.play("idle")


func update_facing() -> void:
	if sprite != null:
		sprite.flip_h = facing_dir < 0


# -------------------------
# Melee Attack
# -------------------------
func try_attack_player() -> void:
	if is_dead or is_attacking or is_overloading or not can_attack:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var horizontal_distance: float = abs(player_ref.global_position.x - global_position.x)
	var vertical_distance: float = abs(player_ref.global_position.y - global_position.y)

	if horizontal_distance > attack_range:
		return

	if vertical_distance > max_vertical_attack_gap:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0.0

	var did_play_fight := false

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("fight"):
		sprite.sprite_frames.set_animation_loop("fight", false)
		sprite.play("fight")
		did_play_fight = true

	await get_tree().create_timer(attack_damage_delay).timeout

	if is_dead:
		return

	if player_ref != null and is_instance_valid(player_ref):
		horizontal_distance = abs(player_ref.global_position.x - global_position.x)
		vertical_distance = abs(player_ref.global_position.y - global_position.y)

		if horizontal_distance <= attack_range and vertical_distance <= max_vertical_attack_gap:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage)

	if did_play_fight and sprite != null and sprite.animation == "fight":
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.12).timeout

	if is_dead:
		return

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	if not is_dead:
		can_attack = true


# -------------------------
# Overload Shock
# -------------------------
func try_overload_attack() -> void:
	if is_dead or is_attacking or is_overloading or not can_overload:
		return

	is_overloading = true
	can_overload = false
	velocity.x = 0.0

	overload_hit_bodies.clear()

	play_boss_overload_charge()
	show_overload_warning()

	await get_tree().create_timer(overload_warning_time).timeout

	if is_dead:
		cleanup_overload_visuals()
		return

	hide_overload_warning()
	play_overload_burst_sprite()

	if overload_collision != null:
		overload_collision.disabled = false

	await get_tree().create_timer(overload_active_time).timeout

	if overload_collision != null:
		overload_collision.disabled = true

	await wait_for_overload_burst_end()

	cleanup_overload_visuals()

	if is_dead:
		return

	is_overloading = false
	overload_cooldown_left = overload_cooldown

	await get_tree().create_timer(overload_cooldown).timeout

	if not is_dead:
		can_overload = true
		overload_cooldown_left = 0.0


func play_boss_overload_charge() -> void:
	if sprite == null:
		return

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("overload"):
		sprite.sprite_frames.set_animation_loop("overload", true)
		sprite.play("overload")
	else:
		sprite.modulate = Color(1.1, 1.4, 1.8)


func show_overload_warning() -> void:
	if overload_warning == null:
		return

	overload_warning.visible = true
	overload_warning_time_count = 0.0
	overload_warning.scale = overload_warning_base_scale
	overload_warning.modulate = Color(0.4, 0.9, 1.0, 0.55)


func hide_overload_warning() -> void:
	if overload_warning == null:
		return

	overload_warning.visible = false
	overload_warning.scale = overload_warning_base_scale


func update_overload_warning_visual(delta: float) -> void:
	if overload_warning == null:
		return

	if not overload_warning.visible:
		return

	if not overload_warning_pulse_enabled:
		return

	overload_warning_time_count += delta

	var pulse: float = 1.0 + sin(overload_warning_time_count * overload_warning_pulse_speed) * overload_warning_pulse_amount
	overload_warning.scale = overload_warning_base_scale * pulse

	var alpha_pulse: float = 0.45 + absf(sin(overload_warning_time_count * overload_warning_pulse_speed)) * 0.35
	overload_warning.modulate = Color(0.4, 0.9, 1.0, alpha_pulse)


func play_overload_burst_sprite() -> void:
	if overload_burst_sprite == null:
		return

	overload_burst_sprite.visible = true
	overload_burst_sprite.frame = 0

	if overload_burst_sprite.sprite_frames != null and overload_burst_sprite.sprite_frames.has_animation("burst"):
		overload_burst_sprite.sprite_frames.set_animation_loop("burst", false)
		overload_burst_sprite.play("burst")
	else:
		push_warning("OverloadBurst ไม่มี animation ชื่อ burst")


func wait_for_overload_burst_end() -> void:
	if overload_burst_sprite == null:
		return

	if overload_burst_sprite.sprite_frames == null:
		return

	if not overload_burst_sprite.sprite_frames.has_animation("burst"):
		return

	if overload_burst_sprite.animation == "burst":
		await overload_burst_sprite.animation_finished


func cleanup_overload_visuals() -> void:
	hide_overload_warning()

	if overload_burst_sprite != null:
		overload_burst_sprite.stop()
		overload_burst_sprite.visible = false

	if overload_collision != null:
		overload_collision.disabled = true

	if sprite != null:
		if is_phase_2:
			sprite.modulate = Color(1.35, 0.85, 0.85)
		else:
			sprite.modulate = Color(1, 1, 1)


func _on_overload_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if not is_overloading:
		return

	if not body.is_in_group("player"):
		return

	if overload_damage_once_per_cast:
		if body in overload_hit_bodies:
			return

		overload_hit_bodies.append(body)

	if body.has_method("take_damage"):
		body.take_damage(overload_damage)


# -------------------------
# Cooldown Label
# -------------------------
func update_overload_cooldown_label(delta: float) -> void:
	if overload_cooldown_label == null:
		return

	if not show_overload_cooldown_label:
		overload_cooldown_label.visible = false
		return

	if is_dead:
		overload_cooldown_label.visible = false
		return

	if not is_phase_2:
		overload_cooldown_label.visible = false
		return

	overload_cooldown_label.visible = true

	if is_overloading:
		overload_cooldown_label.text = overload_shock_text
		overload_cooldown_label.modulate = Color(0.4, 0.9, 1.0)
		overload_cooldown_label.scale = Vector2.ONE
		return

	if can_overload:
		overload_cooldown_label.text = overload_ready_text
		overload_cooldown_label.modulate = Color(1.0, 0.25, 0.25)

		var pulse: float = 1.0 + sin(float(Time.get_ticks_msec()) / 100.0) * 0.12
		overload_cooldown_label.scale = Vector2.ONE * pulse
		return

	overload_cooldown_label.scale = Vector2.ONE

	if overload_cooldown_left > 0.0:
		overload_cooldown_left = max(overload_cooldown_left - delta, 0.0)

		var shown_number: int = int(ceil(overload_cooldown_left))
		overload_cooldown_label.text = str(shown_number)
		overload_cooldown_label.modulate = Color(0.4, 0.9, 1.0)
	else:
		overload_cooldown_label.text = overload_ready_text
		overload_cooldown_label.modulate = Color(1.0, 0.25, 0.25)


# -------------------------
# Phase 2
# -------------------------
func enter_phase_2() -> void:
	if is_phase_2:
		return

	is_phase_2 = true

	move_speed = original_move_speed * phase_2_speed_multiplier
	attack_cooldown = original_attack_cooldown * phase_2_attack_cooldown_multiplier

	can_overload = true
	overload_cooldown_left = 0.0

	if sprite != null:
		sprite.modulate = Color(1.35, 0.85, 0.85)

	if overload_cooldown_label != null:
		overload_cooldown_label.visible = true
		overload_cooldown_label.text = overload_ready_text

	print("Boss Level 2 entered Phase 2: Speed Melee Mode")


# -------------------------
# Damage / Death
# -------------------------
func take_damage(amount: int) -> void:
	if is_dead:
		return

	is_activated = true

	hp -= amount
	hp = max(hp, 0)

	if status_bar != null and status_bar.has_method("set_health"):
		status_bar.set_health(hp, max_hp)

	if not is_phase_2 and hp <= int(float(max_hp) * phase_2_hp_ratio):
		enter_phase_2()

	flash_hit()

	if hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true

	is_attacking = false
	is_overloading = false

	can_attack = false
	can_overload = false

	velocity = Vector2.ZERO

	cleanup_overload_visuals()

	remove_from_group("targetable")

	if body_collision != null:
		body_collision.disabled = true

	if hitbox_collision != null:
		hitbox_collision.disabled = true

	if overload_cooldown_label != null:
		overload_cooldown_label.visible = false

	if status_bar != null:
		status_bar.visible = false

	if blessing_reward > 0:
		BlessingManager.add_blessings(blessing_reward)

	try_drop_item()
	spawn_effect()

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		await sprite.animation_finished

	queue_free()


func flash_hit() -> void:
	if sprite == null:
		return

	var old_modulate: Color = sprite.modulate

	if is_phase_2:
		sprite.modulate = Color(1.8, 0.55, 0.55)
	else:
		sprite.modulate = Color(1.8, 0.7, 0.7)

	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	if is_phase_2:
		sprite.modulate = Color(1.35, 0.85, 0.85)
	else:
		sprite.modulate = old_modulate


# -------------------------
# Drop / Effect
# -------------------------
func try_drop_item() -> void:
	if item_drop_scene == null:
		return

	if item_drop_id.is_empty():
		return

	var item = item_drop_scene.instantiate()
	get_tree().current_scene.add_child(item)

	item.global_position = global_position + Vector2(0, -8)

	if item is Node2D:
		item.z_index = 999

	if item.has_method("setup_item"):
		item.setup_item(item_drop_id, item_drop_amount, item_drop_texture)

	if item.has_method("initialize_spawn"):
		item.initialize_spawn()


func spawn_effect() -> void:
	if hit_effect_scene == null:
		return

	var effect = hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)

	effect.global_position = global_position
	effect.z_index = 100

	var effect_sprite = effect.get_node_or_null("AnimatedSprite2D")

	if effect_sprite == null:
		push_error("Effect ไม่มี AnimatedSprite2D")
		return

	var anim_name := "default"

	if not effect_sprite.sprite_frames.has_animation(anim_name):
		push_error("ไม่มี animation: " + anim_name)
		return

	effect_sprite.sprite_frames.set_animation_loop(anim_name, false)
	effect_sprite.play(anim_name)


# -------------------------
# Contact Damage
# -------------------------
func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player") and can_contact_damage:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)

		can_contact_damage = false

		if collision_damage_cooldown_timer != null:
			collision_damage_cooldown_timer.start()


func _on_collision_damage_cooldown_timeout() -> void:
	can_contact_damage = true
