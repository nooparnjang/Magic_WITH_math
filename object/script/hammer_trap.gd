extends Node2D


@export_group("Damage")
@export var damage := 20.0
@export var damage_once_per_swing := true


@export_group("Animation")
# 1.0 = ความเร็วปกติ
# 2.0 = เร็วขึ้น 2 เท่า
# 0.5 = ช้าลงครึ่งหนึ่ง
@export var animation_speed_scale := 1.0

# Frame ที่ค้อนสามารถสร้างความเสียหายได้
@export var active_hit_frames: Array[int] = [2, 3, 4, 5]


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var collision_shape: CollisionShape2D = (
	$DamageArea/CollisionShape2D
)


var damaged_bodies: Array[Node] = []
var is_hitbox_active := false


func _ready() -> void:
	if animated_sprite == null:
		push_error("Hammer: ไม่พบ AnimatedSprite2D")
		return

	if damage_area == null:
		push_error("Hammer: ไม่พบ DamageArea")
		return

	if collision_shape == null:
		push_error("Hammer: ไม่พบ CollisionShape2D")
		return

	damage_area.monitoring = true

	if not damage_area.body_entered.is_connected(
		_on_damage_area_body_entered
	):
		damage_area.body_entered.connect(
			_on_damage_area_body_entered
		)

	if not animated_sprite.frame_changed.is_connected(
		_on_frame_changed
	):
		animated_sprite.frame_changed.connect(
			_on_frame_changed
		)

	# ใช้กับ Animation ที่ไม่ได้เปิด Loop
	if not animated_sprite.animation_finished.is_connected(
		_on_animation_finished
	):
		animated_sprite.animation_finished.connect(
			_on_animation_finished
		)

	# ใช้กับ Animation ที่เปิด Loop
	if not animated_sprite.animation_looped.is_connected(
		_on_animation_looped
	):
		animated_sprite.animation_looped.connect(
			_on_animation_looped
		)

	set_hitbox_active(false)

	animated_sprite.speed_scale = animation_speed_scale
	animated_sprite.play("default")


func _process(_delta: float) -> void:
	if animated_sprite == null:
		return

	# รองรับการปรับความเร็วจาก Inspector ตอนรันเกม
	animated_sprite.speed_scale = animation_speed_scale


func _on_frame_changed() -> void:
	if animated_sprite == null:
		return

	var current_frame := animated_sprite.frame
	var should_activate := active_hit_frames.has(current_frame)

	set_hitbox_active(should_activate)

	if should_activate:
		check_overlapping_bodies()


func set_hitbox_active(value: bool) -> void:
	if collision_shape == null:
		return

	is_hitbox_active = value

	# ปลอดภัยกว่าการเปลี่ยน CollisionShape ทันที
	collision_shape.set_deferred("disabled", not value)


func check_overlapping_bodies() -> void:
	if damage_area == null:
		return

	if not is_hitbox_active:
		return

	for body in damage_area.get_overlapping_bodies():
		apply_damage(body)


func _on_damage_area_body_entered(body: Node) -> void:
	if not is_hitbox_active:
		return

	apply_damage(body)


func apply_damage(body: Node) -> void:
	if body == null:
		return

	if not is_instance_valid(body):
		return

	if not body.is_in_group("player"):
		return

	if not body.has_method("take_damage"):
		return

	if damage_once_per_swing and damaged_bodies.has(body):
		return

	if damage_once_per_swing:
		damaged_bodies.append(body)

	body.take_damage(damage)


func _on_animation_looped() -> void:
	# ถูกเรียกเมื่อ Animation ที่เปิด Loop เล่นครบรอบ
	reset_swing()


func _on_animation_finished() -> void:
	# รองรับกรณี Animation ไม่ได้เปิด Loop
	reset_swing()

	if not animated_sprite.sprite_frames.get_animation_loop(
		animated_sprite.animation
	):
		animated_sprite.play("default")


func reset_swing() -> void:
	damaged_bodies.clear()
	set_hitbox_active(false)
