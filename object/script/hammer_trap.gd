extends Node2D

@export var damage := 20.0

# ปรับความเร็วค้อนจาก Inspector
# 1.0 = ปกติ
# 2.0 = เร็วขึ้น 2 เท่า
# 0.5 = ช้าลงครึ่งหนึ่ง
@export var animation_speed_scale := 1.0

# frame ที่ค้อนถือว่า "ฟาดโดน"
@export var active_hit_frames: Array[int] = [2,3,4,5]

@export var damage_once_per_swing := true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var collision_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var damaged_bodies: Array[Node] = []


func _ready() -> void:
	damage_area.monitoring = true

	if not damage_area.body_entered.is_connected(_on_damage_area_body_entered):
		damage_area.body_entered.connect(_on_damage_area_body_entered)

	# ปิด hitbox ก่อน ค่อยเปิดตอน frame ค้อนลง
	set_hitbox_active(false)

	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	animated_sprite.speed_scale = animation_speed_scale
	animated_sprite.play("default")


func _process(_delta: float) -> void:
	# เผื่อปรับค่าจาก Inspector ตอนรันเกม จะอัปเดตทันที
	if animated_sprite != null:
		animated_sprite.speed_scale = animation_speed_scale


func _on_frame_changed() -> void:
	var is_active_frame := active_hit_frames.has(animated_sprite.frame)

	set_hitbox_active(is_active_frame)

	if is_active_frame:
		check_overlapping_bodies()


func set_hitbox_active(value: bool) -> void:
	collision_shape.disabled = not value


func check_overlapping_bodies() -> void:
	for body in damage_area.get_overlapping_bodies():
		apply_damage(body)


func _on_damage_area_body_entered(body: Node) -> void:
	if collision_shape.disabled:
		return

	apply_damage(body)


func apply_damage(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if not body.has_method("take_damage"):
		return

	if damage_once_per_swing and damaged_bodies.has(body):
		return

	damaged_bodies.append(body)
	body.take_damage(damage)


func _on_animation_finished() -> void:
	damaged_bodies.clear()
	animated_sprite.play("default")
