extends CharacterBody2D

@export var move_speed := 120.0
@export var gravity := 1200.0
@export var max_hp := 1
@export var contact_damage := 10
@export var attack_cooldown := 1.0
@export var attack_range := 20.0
@export var chase_range := 220.0

@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 2

@export var allowed_operators: Array[String] = ["+", "-", "*", "/"]

var hp := 0
var player_ref: Node2D = null
var can_attack := true
var is_dead := false
var is_attacking := false
var is_activated := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")

	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	player_ref = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	if player_ref == null or not is_instance_valid(player_ref):
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0

		update_animation(Vector2.ZERO)
		move_and_slide()
		return

	var to_player := player_ref.global_position - global_position
	var horizontal_distance = abs(to_player.x)
	var vertical_distance = abs(to_player.y)

	# เปิดโหมดไล่เมื่อ player เข้าใกล้พอ
	if not is_activated:
		if horizontal_distance <= chase_range and vertical_distance <= 80.0:
			is_activated = true

	if is_attacking:
		velocity.x = 0.0
	elif is_activated:
		if horizontal_distance > attack_range:
			var dir_x = sign(to_player.x)
			velocity.x = dir_x * move_speed
		else:
			velocity.x = 0.0
			try_attack_player()
	else:
		velocity.x = 0.0

	# ใช้ gravity อย่างเดียวกับแกน Y
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	update_animation(to_player)

func update_animation(direction: Vector2) -> void:
	if sprite == null or is_dead:
		return

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	if is_attacking:
		if sprite.animation != "fight":
			sprite.play("fight")
		return

	if abs(velocity.x) < 5.0:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")

func take_damage(amount: int) -> void:
	if is_dead:
		return

	# ถ้าโดนตี ให้ตื่นทันที
	is_activated = true

	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	if hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	can_attack = false
	velocity = Vector2.ZERO

	remove_from_group("targetable")

	if body_collision:
		body_collision.disabled = true
	if hitbox_collision:
		hitbox_collision.disabled = true

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		await sprite.animation_finished

	queue_free()

func set_player(player: Node2D) -> void:
	player_ref = player

func try_attack_player() -> void:
	if is_dead or is_attacking or not can_attack:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var horizontal_distance = abs(player_ref.global_position.x - global_position.x)
	var vertical_distance = abs(player_ref.global_position.y - global_position.y)

	if horizontal_distance > attack_range + 8.0:
		return

	# กันตีข้ามชั้น/คนละระดับมากเกินไป
	if vertical_distance > 80.0:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0.0

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("fight"):
		sprite.play("fight")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	if is_dead:
		return

	if player_ref != null and is_instance_valid(player_ref):
		horizontal_distance = abs(player_ref.global_position.x - global_position.x)
		vertical_distance = abs(player_ref.global_position.y - global_position.y)

		if horizontal_distance <= attack_range + 8.0 and vertical_distance <= 80.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage)

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		if player_ref == null:
			player_ref = body as Node2D

		is_activated = true
		try_attack_player()
