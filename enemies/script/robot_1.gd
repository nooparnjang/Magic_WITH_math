extends CharacterBody2D

@export var move_speed := 80.0
@export var max_hp := 1
@export var contact_damage := 10
@export var attack_cooldown := 1.0
@export var attack_range := 20.0

var hp := 0
var player_ref: Node2D = null
var can_attack := true
var is_dead := false
var is_attacking := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	hp = max_hp
	add_to_group("targetable")

	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_ref == null or not is_instance_valid(player_ref):
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		move_and_slide()
		return

	var direction := player_ref.global_position - global_position
	var distance := direction.length()

	if is_attacking:
		velocity = Vector2.ZERO
	else:
		if distance > attack_range:
			velocity = direction.normalized() * move_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()
	update_animation(direction)

func update_animation(direction: Vector2) -> void:
	if sprite == null or is_dead:
		return

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	if is_attacking:
		if sprite.animation != "fight":
			sprite.play("fight")
		return

	if velocity.length() < 5:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")

func take_damage(amount: int) -> void:
	if is_dead:
		return

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

	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	if is_dead:
		return

	if player_ref != null and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) <= attack_range + 8.0:
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
		try_attack_player()
