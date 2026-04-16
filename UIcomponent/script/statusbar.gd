extends Node2D

@onready var health_bar: TextureProgressBar = $VBoxContainer/healthbar
@onready var stamina_bar: TextureProgressBar = $VBoxContainer/staminabar

@export var base_position := Vector2(-12, -63)
@export var max_x_offset := 10.0
@export var follow_lerp_speed := 10.0
@export var return_lerp_speed := 6.0

@export var left_facing_x_offset := 20.0

var player_ref: CharacterBody2D = null
var player_sprite: AnimatedSprite2D = null

func _ready() -> void:
	position = base_position
	player_ref = get_parent() as CharacterBody2D

	if player_ref != null:
		player_sprite = player_ref.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _process(delta: float) -> void:
	if player_ref == null:
		return

	var vx: float = player_ref.velocity.x
	var facing_left: bool = false

	if player_sprite != null:
		facing_left = player_sprite.flip_h

	var current_base_x: float = base_position.x
	if facing_left:
		current_base_x += left_facing_x_offset

	var target_x: float = current_base_x

	if abs(vx) > 1.0:
		var move_ratio: float = clamp(abs(vx) / max(player_ref.speed, 1.0), 0.0, 1.0)
		var dir: float = sign(vx)

		target_x = current_base_x + dir * max_x_offset * move_ratio
		position.x = lerp(position.x, target_x, follow_lerp_speed * delta)
	else:
		position.x = lerp(position.x, current_base_x, return_lerp_speed * delta)

	position.y = base_position.y

func setup(max_hp: float, hp: float, max_stamina: float, stamina: float) -> void:
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp

	stamina_bar.min_value = 0
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

func set_health(hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = clamp(hp, 0.0, max_hp)

func set_stamina(stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = clamp(stamina, 0.0, max_stamina)
