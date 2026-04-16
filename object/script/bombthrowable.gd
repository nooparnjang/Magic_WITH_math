extends RigidBody2D

@export var damage: int = 3
@export var throw_force: float = 700.0
@export var upward_force: float = -180.0
@export var explode_delay: float = 0.12
@export var auto_explode_after_hit := true
@export var target_group: String = "targetable"
@export var hit_effect_scene: PackedScene
@export var effect_scale: float = 3.0

var exploded := false
var armed := false
var explode_requested := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explode_delay_timer: Timer = $ExplodeDelay
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if explode_delay_timer != null:
		explode_delay_timer.wait_time = explode_delay
		explode_delay_timer.one_shot = true
		if not explode_delay_timer.timeout.is_connected(_explode_now):
			explode_delay_timer.timeout.connect(_explode_now)

	if life_timer != null:
		life_timer.one_shot = true
		if not life_timer.timeout.is_connected(_on_life_timer_timeout):
			life_timer.timeout.connect(_on_life_timer_timeout)
		life_timer.start()

func throw_to_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	armed = true
	linear_velocity = Vector2.ZERO
	apply_impulse(direction.normalized() * throw_force + Vector2(0, upward_force))

	if direction.x != 0.0 and sprite != null:
		sprite.flip_h = direction.x < 0.0

func throw_to_position(from_pos: Vector2, target_pos: Vector2) -> void:
	global_position = from_pos

	var dir := (target_pos - from_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	throw_to_direction(dir)

func _on_body_entered(body: Node) -> void:
	if exploded or explode_requested:
		return

	if not armed:
		return

	if body.is_in_group("player"):
		return

	if auto_explode_after_hit:
		explode_requested = true
		call_deferred("start_explode")

func start_explode() -> void:
	if exploded:
		return

	exploded = true
	armed = false

	# อย่าเปลี่ยน physics state รุนแรงตอน callback ชน
	set_deferred("freeze", true)
	set_deferred("contact_monitor", false)

	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	if collision_layer != 0:
		set_deferred("collision_layer", 0)
	if collision_mask != 0:
		set_deferred("collision_mask", 0)

	if explode_delay_timer != null:
		explode_delay_timer.start()
	else:
		call_deferred("_explode_now")

func _explode_now() -> void:
	if not is_inside_tree():
		return

	damage_targets()
	spawn_effect()
	queue_free()

func damage_targets() -> void:
	if explosion_area == null:
		return

	# รอให้ overlap list อัปเดตทันก่อน ถ้าเรียกจาก deferred/timer มักโอเคแล้ว
	var bodies := explosion_area.get_overlapping_bodies()

	for body in bodies:
		if not is_instance_valid(body):
			continue

		if body.is_in_group("player"):
			continue

		if body.is_in_group(target_group) and body.has_method("take_damage"):
			body.take_damage(damage)

func spawn_effect() -> void:
	if hit_effect_scene == null:
		return

	var effect = hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)

	if effect is Node2D:
		effect.global_position = global_position
		effect.z_index = 100
		effect.scale = Vector2.ONE * effect_scale

	var effect_sprite = effect.get_node_or_null("AnimatedSprite2D")
	if effect_sprite == null:
		push_error("Effect ไม่มี AnimatedSprite2D")
		return

	var anim_name := "default"

	if effect_sprite.sprite_frames == null:
		push_error("Effect AnimatedSprite2D ไม่มี sprite_frames")
		return

	if not effect_sprite.sprite_frames.has_animation(anim_name):
		push_error("ไม่มี animation: " + anim_name)
		return

	effect_sprite.sprite_frames.set_animation_loop(anim_name, false)
	effect_sprite.play(anim_name)

func _on_life_timer_timeout() -> void:
	if not exploded and not explode_requested:
		explode_requested = true
		call_deferred("start_explode")
