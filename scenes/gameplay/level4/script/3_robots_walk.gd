extends CharacterBody2D

@export var move_speed: float = 120.0
@export var gravity: float = 1200.0
@export var activation_distance: float = 500.0
@export var max_hp: int = 1

@export var hit_effect_scene: PackedScene

# Drag your Player node here in the Inspector
@export var player_path: NodePath

var hp: int
var activated := false
var dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_node_or_null(player_path)

func _ready():
	hp = max_hp

func _physics_process(delta):
	if dead:
		return

	# Activate when player gets close
	if !activated and player:
		if global_position.distance_to(player.global_position) <= activation_distance:
			activated = true

	# Always walk right after activation
	if activated:
		velocity.x = move_speed
	else:
		velocity.x = 0

	# Gravity
	if !is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	update_animation()

func update_animation():
	if sprite == null:
		return

	sprite.flip_h = false

	if activated:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func take_damage(amount: int):
	if dead:
		return

	hp -= amount
	flash_hit()

	if hp <= 0:
		die()

func die():
	dead = true

	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

	queue_free()

func flash_hit():
	if sprite == null:
		return

	sprite.modulate = Color(1.8, 0.7, 0.7)
	await get_tree().create_timer(0.08).timeout

	if !dead:
		sprite.modulate = Color.WHITE
