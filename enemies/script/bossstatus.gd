extends Node2D

@export var base_position := Vector2(-28, -72)
@export var max_x_offset := 8.0
@export var follow_lerp_speed := 10.0
@export var return_lerp_speed := 6.0
@export var auto_hide_when_full := false

@onready var health_bar: TextureProgressBar = $VBoxContainer/healthbar

var boss_ref: CharacterBody2D = null
var max_hp_value: float = 1.0
var current_hp_value: float = 1.0

func _ready() -> void:
	position = base_position
	boss_ref = get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	if boss_ref == null or not is_instance_valid(boss_ref):
		return

	var vx: float = boss_ref.velocity.x
	var target_x: float = base_position.x

	if abs(vx) > 1.0:
		var speed_ref := 1.0
		if "move_speed" in boss_ref:
			speed_ref = max(float(boss_ref.move_speed), 1.0)

		var move_ratio: float = clamp(abs(vx) / speed_ref, 0.0, 1.0)
		var dir: float = sign(vx)
		target_x = base_position.x + dir * max_x_offset * move_ratio

	var lerp_speed := follow_lerp_speed if abs(vx) > 1.0 else return_lerp_speed
	position.x = lerp(position.x, target_x, lerp_speed * delta)
	position.y = lerp(position.y, base_position.y, return_lerp_speed * delta)

	if auto_hide_when_full and current_hp_value >= max_hp_value:
		visible = false
	else:
		visible = true

func setup(max_hp: float, current_hp: float) -> void:
	max_hp_value = max(max_hp, 1.0)
	current_hp_value = clamp(current_hp, 0.0, max_hp_value)

	if health_bar != null:
		health_bar.max_value = max_hp_value
		health_bar.value = current_hp_value

	if auto_hide_when_full and current_hp_value >= max_hp_value:
		visible = false
	else:
		visible = true

func set_health(current_hp: float, max_hp: float = -1.0) -> void:
	if max_hp > 0.0:
		max_hp_value = max(max_hp, 1.0)

	current_hp_value = clamp(current_hp, 0.0, max_hp_value)

	if health_bar != null:
		health_bar.max_value = max_hp_value
		health_bar.value = current_hp_value

	if auto_hide_when_full and current_hp_value >= max_hp_value:
		visible = false
	else:
		visible = true
