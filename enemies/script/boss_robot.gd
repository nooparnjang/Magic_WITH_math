extends CharacterBody2D

@export var boss_name: String = "Deep in the Alley"
@export var max_hp: int = 12
@export var move_speed: float = 80.0
@export var gravity: float = 1200.0

@export var contact_damage: int = 10
@export var contact_damage_cooldown: float = 0.8

@export var activation_range: float = 520.0

# melee
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 60.0
@export var max_vertical_attack_gap: float = 80.0

# ranged
@export var shoot_cooldown: float = 1.8
@export var shoot_min_range: float = 90.0
@export var shoot_range: float = 420.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 260.0
@export var projectile_damage: int = 12

@export var blessing_reward: int = 40
@export var hit_effect_scene: PackedScene
@export var item_drop_scene: PackedScene
@export var item_drop_id: String = "engine_part"
@export var item_drop_amount: int = 1
@export var item_drop_texture: Texture2D

@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 1

@export var allowed_operators: Array[String] = ["+", "-", "*"]

var hp: int = 0
var player_ref: Node2D = null

var is_dead := false
var is_activated := false
var is_attacking := false
var is_shooting := false

var can_contact_damage := true
var can_attack := true
var can_shoot := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var collision_damage_cooldown_timer: Timer = $CollisionDamageCooldown
@onready var status_bar: Node2D = $Bossstatus

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")
	add_to_group("boss")

	player_ref = get_tree().get_first_node_in_group("player") as Node2D

	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	if collision_damage_cooldown_timer != null:
		if not collision_damage_cooldown_timer.timeout.is_connected(_on_collision_damage_cooldown_timeout):
			collision_damage_cooldown_timer.timeout.connect(_on_collision_damage_cooldown_timeout)
		collision_damage_cooldown_timer.wait_time = contact_damage_cooldown

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

	if to_player.x != 0.0:
		sprite.flip_h = to_player.x < 0.0

	# ถ้ากำลังตีหรือยิงอยู่ ให้หยุดก่อน
	if is_attacking or is_shooting:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_animation(to_player)
		return

	# ถ้าระดับความสูงต่างกันมากเกิน ไม่ให้ attack melee
	if vertical_distance > max_vertical_attack_gap:
		if horizontal_distance > shoot_range:
			velocity.x = sign(to_player.x) * move_speed
		else:
			velocity.x = 0.0
			if can_shoot:
				try_shoot_player()
	else:
		# 1) ใกล้มาก = ตีประชิด
		if horizontal_distance <= attack_range:
			velocity.x = 0.0
			if can_attack:
				try_attack_player()

		# 2) ระยะกลาง = ยิง
		elif horizontal_distance <= shoot_range and horizontal_distance >= shoot_min_range:
			velocity.x = 0.0
			if can_shoot:
				try_shoot_player()

		# 3) อยู่ระยะก้ำกึ่งใกล้เกินจะยิงแต่ยังไม่ถึงระยะตี = เดินเข้าอีกนิด
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

	if is_attacking:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("fight"):
			if sprite.animation != "fight":
				sprite.play("fight")
		return

	if is_shooting:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
			if sprite.animation != "attack":
				sprite.play("attack")
		return

	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

	if abs(velocity.x) > 5.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _play_idle() -> void:
	if sprite != null and sprite.animation != "idle":
		sprite.play("idle")

func try_attack_player() -> void:
	if is_dead or is_attacking or not can_attack:
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

	await get_tree().create_timer(0.18).timeout

	if is_dead:
		return

	if player_ref != null and is_instance_valid(player_ref):
		horizontal_distance = abs(player_ref.global_position.x - global_position.x)
		vertical_distance = abs(player_ref.global_position.y - global_position.y)

		if horizontal_distance <= attack_range and vertical_distance <= max_vertical_attack_gap:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage)

	if did_play_fight and sprite.animation == "fight":
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.15).timeout

	if is_dead:
		return

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func try_shoot_player() -> void:
	if is_dead or is_shooting or not can_shoot:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	is_shooting = true
	can_shoot = false
	velocity.x = 0.0

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
		sprite.sprite_frames.set_animation_loop("attack", false)
		sprite.play("attack")
		await get_tree().create_timer(0.15).timeout
	else:
		await get_tree().create_timer(0.1).timeout

	if is_dead:
		return

	shoot_projectile()

	if sprite != null and sprite.animation == "attack":
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.1).timeout

	is_shooting = false

	await get_tree().create_timer(shoot_cooldown).timeout
	if not is_dead:
		can_shoot = true

func shoot_projectile() -> void:
	if projectile_scene == null:
		push_warning("Boss projectile scene ยังไม่ได้ assign")
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var spawn_pos: Vector2 = global_position + Vector2(0, -20)
	if shoot_point != null:
		spawn_pos = shoot_point.global_position

	projectile.global_position = spawn_pos

	var dir: Vector2 = (player_ref.global_position - spawn_pos).normalized()

	if projectile.has_method("setup_projectile"):
		projectile.setup_projectile(dir, projectile_speed, projectile_damage, self)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	is_activated = true
	hp -= amount
	hp = max(hp, 0)

	if status_bar != null and status_bar.has_method("set_health"):
		status_bar.set_health(hp, max_hp)

	flash_hit()

	if hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_shooting = false
	can_attack = false
	can_shoot = false
	velocity = Vector2.ZERO

	remove_from_group("targetable")

	if body_collision != null:
		body_collision.disabled = true
	if hitbox_collision != null:
		hitbox_collision.disabled = true

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
	

func flash_hit() -> void:
	if sprite == null:
		return

	sprite.modulate = Color(1.8, 0.7, 0.7)
	await get_tree().create_timer(0.08).timeout

	if not is_dead:
		sprite.modulate = Color(1, 1, 1)

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
