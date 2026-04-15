extends CharacterBody2D

@export var move_speed := 120.0
@export var gravity := 1200.0
@export var max_hp := 1
@export var contact_damage := 10
@export var attack_cooldown := 1.0
@export var attack_range := 60.0
@export var max_vertical_attack_gap := 80.0

@export var blessing_reward: int = 10
@export var hit_effect_scene: PackedScene
@export var floating_text_scene: PackedScene

@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 2

@export var allowed_operators: Array[String] = ["+", "-", "*", "/"]

@export_enum("none", "blessings", "item", "both")
var drop_type := 1

@export var item_drop_scene: PackedScene
@export var item_drop_count: int = 1
@export var randomize_drop := false
@export_range(0.0, 1.0, 0.01) var blessing_drop_chance := 1.0
@export_range(0.0, 1.0, 0.01) var item_drop_chance := 1.0

# ข้อมูลไอเทมที่ดรอป
@export var item_drop_id: String = "coin"
@export var item_drop_amount: int = 1
@export var item_drop_texture: Texture2D

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
		velocity.x = 0.0
		_apply_gravity(delta)
		update_animation(Vector2.ZERO)
		move_and_slide()
		return

	var to_player: Vector2 = player_ref.global_position - global_position
	var horizontal_distance: float = abs(to_player.x)
	var vertical_distance: float = abs(to_player.y)

	if is_attacking:
		velocity.x = 0.0
	elif is_activated:
		if vertical_distance > max_vertical_attack_gap:
			velocity.x = 0.0
		elif horizontal_distance > attack_range:
			velocity.x = sign(to_player.x) * move_speed
		else:
			velocity.x = 0.0
			try_attack_player()
	else:
		velocity.x = 0.0

	_apply_gravity(delta)
	move_and_slide()
	update_animation(to_player)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

func update_animation(direction: Vector2) -> void:
	if sprite == null or is_dead:
		return

	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

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

	is_activated = true
	hp -= amount
	print(name, "โดนดาเมจ", amount, "เหลือ", hp)

	flash_hit()

	if hp <= 0:
		die()

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
	else:
		print("ไม่มีอนิเมชัน fight")

	await get_tree().create_timer(0.18).timeout

	if is_dead:
		return

	if player_ref != null and is_instance_valid(player_ref):
		horizontal_distance = abs(player_ref.global_position.x - global_position.x)
		vertical_distance = abs(player_ref.global_position.y - global_position.y)

		if horizontal_distance <= attack_range and vertical_distance <= max_vertical_attack_gap:
			if player_ref.has_method("take_damage"):
				print("enemy dealt damage:", contact_damage)
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

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	can_attack = false
	velocity = Vector2.ZERO

	remove_from_group("targetable")

	if body_collision != null:
		body_collision.disabled = true
	if hitbox_collision != null:
		hitbox_collision.disabled = true

	handle_drops()
	spawn_effect()

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		await sprite.animation_finished

	queue_free()

func handle_drops() -> void:
	match drop_type:
		0:
			pass
		1:
			try_drop_blessing()
		2:
			try_drop_item()
		3:
			try_drop_blessing()
			try_drop_item()

func try_drop_blessing() -> void:
	if randomize_drop and randf() > blessing_drop_chance:
		return

	if blessing_reward <= 0:
		return

	give_blessing()
	show_blessing_popup()

func try_drop_item() -> void:
	if item_drop_scene == null:
		return

	if item_drop_id.is_empty():
		return

	if randomize_drop and randf() > item_drop_chance:
		return

	for i in range(item_drop_count):
		var item = item_drop_scene.instantiate()
		get_tree().current_scene.add_child(item)

		item.global_position = global_position + Vector2(
			randf_range(-12.0, 12.0),
			randf_range(-8.0, 8.0)
		)

		if item is Node2D:
			item.z_index = 999

		if item.has_method("setup_item"):
			item.setup_item(item_drop_id, item_drop_amount, item_drop_texture)

		if item.has_method("initialize_spawn"):
			item.initialize_spawn()

func give_blessing() -> void:
	BlessingManager.add_blessings(blessing_reward)

func show_blessing_popup() -> void:
	if floating_text_scene == null:
		return

	var popup = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(popup)

	if popup.has_method("show_at"):
		popup.show_at(global_position + Vector2(-40, -98), blessing_reward)

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

func set_player(player: Node2D) -> void:
	player_ref = player

func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		if player_ref == null:
			player_ref = body as Node2D

		is_activated = true
		try_attack_player()
